pragma solidity ^0.5.0;

import './b.sol';

contract a {

    using b for uint256;

    uint256 public storedData;

    function set(uint256 data, uint256 bbb)  public   {
        storedData = data.add(bbb);
    }

    function get() public view returns (uint256) {
        return storedData;
    }
}