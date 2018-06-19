pragma solidity ^0.4.15;

library IntervalLib {
  struct Interval {
    uint begin;
    uint end;
    bytes32 data;
  }
}