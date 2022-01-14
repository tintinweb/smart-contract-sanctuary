/**
 *Submitted for verification at FtmScan.com on 2022-01-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

library Quicksort {
  function sort(uint256[] memory data, bool descending)
    public
    pure
    returns (uint256[] memory)
  {
    quickSort(data, descending, int256(0), int256(data.length - 1));
    return data;
  }

  function quickSort(
    uint256[] memory arr,
    bool descending,
    int256 left,
    int256 right
  ) internal pure {
    int256 i = left;
    int256 j = right;
    if (i == j) return;
    uint256 pivot = arr[uint256(left + (right - left) / 2)];
    while (i <= j) {
      if (descending) {
        while (arr[uint256(i)] > pivot) i++;
        while (pivot > arr[uint256(j)]) j--;
      } else {
        while (arr[uint256(i)] < pivot) i++;
        while (pivot < arr[uint256(j)]) j--;
      }
      if (i <= j) {
        (arr[uint256(i)], arr[uint256(j)]) = (arr[uint256(j)], arr[uint256(i)]);
        i++;
        j--;
      }
    }
    if (left < j) quickSort(arr, descending, left, j);
    if (i < right) quickSort(arr, descending, i, right);
  }
}