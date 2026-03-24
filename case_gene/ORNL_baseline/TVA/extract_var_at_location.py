#!/usr/bin/env python3
import argparse
import sys
from typing import Tuple, Optional, List

import numpy as np
import xarray as xr


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Extract variable at nearest grid cell to a given lat/lon from a NetCDF file."
    )
    parser.add_argument(
        "--file",
        required=True,
        help="Path to NetCDF file",
    )
    parser.add_argument(
        "--var",
        default="solutionp_vr",
        help="Variable name to extract (default: solutionp_vr)",
    )
    parser.add_argument(
        "--lat",
        type=float,
        required=True,
        help="Target latitude in degrees (-90..90)",
    )
    parser.add_argument(
        "--lon",
        type=float,
        required=True,
        help="Target longitude in degrees (-180..180 or 0..360)",
    )
    parser.add_argument(
        "--time-index",
        type=int,
        default=0,
        help="Time index to select if time dimension exists (default: 0)",
    )
    parser.add_argument(
        "--depth-index",
        type=int,
        default=None,
        help="Depth/vertical index to select if variable is vertically resolved (default: print full profile)",
    )
    return parser.parse_args()


def find_lat_lon_vars(ds: xr.Dataset) -> Tuple[str, str]:
    """
    Heuristically find latitude and longitude variable names.
    Supports common ELM/ELM restart structures.
    """
    candidate_lat = ["lat", "LATIXY", "lsmlat"]
    candidate_lon = ["lon", "LONGXY", "lsmlon"]

    # Try by standard_name attribute first
    for var_name, var in ds.variables.items():
        std = var.attrs.get("standard_name", "").lower()
        if std == "latitude":
            lat_name = var_name
            # find lon with standard_name
            lon_name = None
            for var_name2, var2 in ds.variables.items():
                if var2.attrs.get("standard_name", "").lower() == "longitude":
                    lon_name = var_name2
                    break
            if lon_name:
                return lat_name, lon_name

    # Try common names
    lat_name = next((n for n in candidate_lat if n in ds.variables), None)
    lon_name = next((n for n in candidate_lon if n in ds.variables), None)
    if lat_name and lon_name:
        return lat_name, lon_name

    # Fallback: look for variables with units and plausible ranges
    def is_lat(v: xr.DataArray) -> bool:
        try:
            data = v.values
            mn = np.nanmin(data)
            mx = np.nanmax(data)
            return np.isfinite([mn, mx]).all() and -90.1 <= mn <= 90.1 and -90.1 <= mx <= 90.1
        except Exception:
            return False

    def is_lon(v: xr.DataArray) -> bool:
        try:
            data = v.values
            mn = np.nanmin(data)
            mx = np.nanmax(data)
            in_180 = -180.1 <= mn <= 180.1 and -180.1 <= mx <= 180.1
            in_360 = 0.0 <= mn <= 360.1 and 0.0 <= mx <= 360.1
            return np.isfinite([mn, mx]).all() and (in_180 or in_360)
        except Exception:
            return False

    candidates_lat = [n for n, v in ds.variables.items() if ds[n].ndim >= 1 and is_lat(ds[n])]
    candidates_lon = [n for n, v in ds.variables.items() if ds[n].ndim >= 1 and is_lon(ds[n])]

    if candidates_lat and candidates_lon:
        # Choose the pair with matching dims if possible
        for la in candidates_lat:
            for lo in candidates_lon:
                if ds[la].dims == ds[lo].dims:
                    return la, lo
        return candidates_lat[0], candidates_lon[0]

    raise ValueError("Could not identify latitude/longitude variables in the dataset.")


def normalize_target_lon(target_lon: float, lon_vals: np.ndarray) -> float:
    """
    Convert target lon to match dataset lon convention (0..360 vs -180..180).
    """
    lon_min = np.nanmin(lon_vals)
    lon_max = np.nanmax(lon_vals)
    if lon_min >= 0.0 and lon_max > 180.0:
        # Dataset uses 0..360
        if target_lon < 0.0:
            return target_lon % 360.0
        return target_lon
    # Dataset uses -180..180 or similar
    if target_lon > 180.0:
        return ((target_lon + 180.0) % 360.0) - 180.0
    return target_lon


def haversine_deg(lat1: np.ndarray, lon1: np.ndarray, lat2_deg: float, lon2_deg: float) -> np.ndarray:
    """
    Great-circle distance (km) between (lat1, lon1) arrays and scalar (lat2, lon2). Inputs in degrees.
    """
    R = 6371.0  # km
    lat1r = np.radians(lat1)
    lon1r = np.radians(lon1)
    lat2r = np.radians(lat2_deg)
    lon2r = np.radians(lon2_deg)
    dlat = lat2r - lat1r
    dlon = lon2r - lon1r
    a = np.sin(dlat / 2.0) ** 2 + np.cos(lat1r) * np.cos(lat2r) * np.sin(dlon / 2.0) ** 2
    c = 2.0 * np.arcsin(np.sqrt(a))
    return R * c


def find_nearest_index(
    ds: xr.Dataset, lat_name: str, lon_name: str, target_lat: float, target_lon: float
) -> Tuple[Tuple[int, ...], Tuple[str, ...], Tuple[float, float], float]:
    """
    Returns:
      - index tuple for selection (length 1 for unstructured, length 2 for 2D grid)
      - grid dimension names corresponding to the indices
      - actual grid (lat, lon) at the nearest cell
      - distance in km
    """
    lat_da = ds[lat_name]
    lon_da = ds[lon_name]
    lat_vals = lat_da.values
    lon_vals = lon_da.values

    # Normalize target lon to dataset convention
    target_lon_norm = normalize_target_lon(target_lon, lon_vals)

    if lat_da.dims == lon_da.dims and len(lat_da.dims) == 1:
        # Unstructured grid, e.g., dim ('ncol',)
        dim_name = lat_da.dims[0]
        distances = haversine_deg(lat_vals, lon_vals, target_lat, target_lon_norm)
        idx = int(np.nanargmin(distances))
        nearest_lat = float(lat_vals[idx])
        nearest_lon = float(lon_vals[idx])
        distance_km = float(distances[idx])
        return (idx,), (dim_name,), (nearest_lat, nearest_lon), distance_km

    if lat_da.dims == lon_da.dims and len(lat_da.dims) == 2:
        # Structured grid, e.g., dims ('lat','lon') or ('lsmlat','lsmlon')
        dim_y, dim_x = lat_da.dims
        distances = haversine_deg(lat_vals, lon_vals, target_lat, target_lon_norm)
        flat_idx = int(np.nanargmin(distances))
        iy, ix = np.unravel_index(flat_idx, lat_vals.shape)
        nearest_lat = float(lat_vals[iy, ix])
        nearest_lon = float(lon_vals[iy, ix])
        distance_km = float(distances[iy, ix])
        return (iy, ix), (dim_y, dim_x), (nearest_lat, nearest_lon), distance_km

    # Mixed shapes (less common) – flatten both and return a flat index for the first dim if present
    distances = haversine_deg(lat_vals, lon_vals, target_lat, target_lon_norm)
    flat_idx = int(np.nanargmin(distances))
    if lat_vals.ndim == 1:
        dim_name = lat_da.dims[0]
        idx = (flat_idx,)
        nearest_lat = float(lat_vals[flat_idx])
        nearest_lon = float(lon_vals[flat_idx])
        distance_km = float(distances[flat_idx])
        return idx, (dim_name,), (nearest_lat, nearest_lon), distance_km
    else:
        iy, ix = np.unravel_index(flat_idx, lat_vals.shape)
        nearest_lat = float(lat_vals[iy, ix])
        nearest_lon = float(lon_vals[iy, ix])
        distance_km = float(distances[iy, ix])
        dim_y = lat_da.dims[0] if len(lat_da.dims) > 0 else "y"
        dim_x = lat_da.dims[1] if len(lat_da.dims) > 1 else "x"
        return (iy, ix), (dim_y, dim_x), (nearest_lat, nearest_lon), distance_km


def find_lat_lon_for_variable(ds: xr.Dataset, var: xr.DataArray) -> Tuple[str, str]:
    """
    Prefer lat/lon variables whose single spatial dimension matches the target variable.
    Handles common ELM restart conventions:
      - 'column'  -> 'cols1d_lat', 'cols1d_lon'
      - 'gridcell'-> 'grid1d_lat', 'grid1d_lon'
      - 'landunit'-> 'land1d_lat', 'land1d_lon'
      - 'pft'     -> 'pfts1d_lat', 'pfts1d_lon'
      - 'topounit'-> 'topo1d_lat', 'topo1d_lon'
    Falls back to generic search if none match.
    """
    dim_to_latlon = {
        "column": ("cols1d_lat", "cols1d_lon"),
        "gridcell": ("grid1d_lat", "grid1d_lon"),
        "landunit": ("land1d_lat", "land1d_lon"),
        "pft": ("pfts1d_lat", "pfts1d_lon"),
        "topounit": ("topo1d_lat", "topo1d_lon"),
    }
    for dim_name, (lat_name, lon_name) in dim_to_latlon.items():
        if dim_name in var.dims:
            if lat_name in ds.variables and lon_name in ds.variables:
                return lat_name, lon_name
    # Fallback to generic heuristic
    return find_lat_lon_vars(ds)


def select_variable_at_index(
    ds: xr.Dataset,
    var_name: str,
    index: Tuple[int, ...],
    grid_dims: Tuple[str, ...],
    time_index: int,
    depth_index: Optional[int],
) -> xr.DataArray:
    if var_name not in ds.variables:
        raise KeyError(f"Variable '{var_name}' not found in dataset.")
    var = ds[var_name]

    # Build selection dict
    sel = {}
    if "time" in var.dims and var.sizes.get("time", 1) > 0:
        sel["time"] = time_index

    # Apply grid indices
    for dim_name, idx in zip(grid_dims, index):
        if dim_name in var.dims:
            sel[dim_name] = idx
        else:
            # Try to find a grid-like dim in the variable that matches dataset size for that dim
            # e.g., lat/lon provided as ('lsmlat','lsmlon') but variable uses ('lat','lon')
            pass

    # If variable has exactly one "grid column" dimension like 'ncol'
    if len(grid_dims) == 1 and grid_dims[0] not in var.dims:
        # Search for a likely column dimension present in variable dims
        col_dim_candidates = [d for d in var.dims if d.lower() in ("ncol", "gridcell", "column")]
        if col_dim_candidates:
            sel[col_dim_candidates[0]] = index[0]

    # Handle vertical dimension if requested or print full profile
    vertical_dim_candidates: List[str] = [d for d in var.dims if d.lower() in ("nlevsoi", "levsoi", "depth", "lev")]
    if depth_index is not None and vertical_dim_candidates:
        sel[vertical_dim_candidates[0]] = depth_index

    return var.isel(sel)


def try_get_depths(
    ds: xr.Dataset, index: Tuple[int, ...], grid_dims: Tuple[str, ...]
) -> Optional[np.ndarray]:
    """
    Try extracting soil depth coordinates for vertical profiles (e.g., 'zsoi').
    """
    for depth_name in ("zsoi", "depth", "levsoi", "zsoi_bedrock"):
        if depth_name in ds.variables:
            depth_da = ds[depth_name]
            sel = {}
            for dim_name, idx in zip(grid_dims, index):
                if dim_name in depth_da.dims:
                    sel[dim_name] = idx
            try:
                extracted = depth_da.isel(sel)
                # Reduce time if present
                if "time" in extracted.dims and extracted.sizes.get("time", 1) > 0:
                    extracted = extracted.isel(time=0)
                depth_vals = np.asarray(extracted)
                # Ensure 1D vertical
                if depth_vals.ndim >= 1:
                    return np.squeeze(depth_vals)
            except Exception:
                continue
    return None


def main() -> None:
    args = parse_args()

    try:
        ds = xr.open_dataset(args.file)
    except Exception as exc:
        print(f"ERROR: Failed to open dataset: {exc}", file=sys.stderr)
        sys.exit(2)

    # Ensure variable exists first so we can choose matching lat/lon if possible
    if args.var not in ds.variables:
        print(f"ERROR: Variable '{args.var}' not found in dataset.", file=sys.stderr)
        sys.exit(3)
    target_var = ds[args.var]

    try:
        lat_name, lon_name = find_lat_lon_for_variable(ds, target_var)
    except Exception as exc:
        print(f"ERROR: Could not locate lat/lon variables: {exc}", file=sys.stderr)
        sys.exit(3)

    idx, grid_dims, (grid_lat, grid_lon), dist_km = find_nearest_index(
        ds, lat_name, lon_name, args.lat, args.lon
    )

    print(f"Located nearest grid cell to ({args.lat:.6f}, {args.lon:.6f}):")
    print(f"- Grid lat/lon: ({grid_lat:.6f}, {grid_lon:.6f})")
    print(f"- Distance: {dist_km:.3f} km")
    print(f"- Grid dims: {grid_dims}  Index: {idx}")

    try:
        data_sel = select_variable_at_index(
            ds,
            args.var,
            idx,
            grid_dims,
            time_index=args.time_index,
            depth_index=args.depth_index,
        )
    except Exception as exc:
        print(f"ERROR: Failed to select variable '{args.var}': {exc}", file=sys.stderr)
        sys.exit(4)

    data_np = np.asarray(data_sel)
    var_units = data_sel.attrs.get("units", "unknown")

    if args.depth_index is None and data_np.ndim >= 1 and data_sel.sizes:
        # Likely a vertical profile present; try to print neatly with depths if available
        depths = try_get_depths(ds, idx, grid_dims)
        print(f"\nValues for '{args.var}' (units: {var_units}) at nearest cell:")
        if depths is not None and depths.shape == data_np.shape:
            print("Depth  Value")
            for d, v in zip(depths, data_np):
                print(f"{float(d):8.4f}  {float(v):.6g}")
        else:
            print("Index  Value")
            for ii, v in enumerate(np.ravel(data_np)):
                print(f"{ii:5d}  {float(v):.6g}")
    else:
        # Scalar after selections
        try:
            scalar_value = float(np.squeeze(data_np))
        except Exception:
            scalar_value = np.squeeze(data_np)
        print(f"\n{args.var} (units: {var_units}) = {scalar_value}")
    

if __name__ == "__main__":
    main()


