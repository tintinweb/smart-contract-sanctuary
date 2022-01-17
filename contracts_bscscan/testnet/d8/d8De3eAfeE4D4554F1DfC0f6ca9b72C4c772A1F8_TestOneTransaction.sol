pragma solidity ^0.8.0;
contract TestOneTransaction {
    uint256[] public a = [54,645,42,542,4395,340,23,434];
    uint256 public b;
    function removeElement(uint256 _a) external{
        a[_a] = a[a.length-1];
        a.pop();
    }
    function getElement(uint256 _a) external{
        b = a[_a];
    }
}