pragma solidity >=0.7.0 <0.8.0;

import "./Owner.sol";

contract Test is Owner{

    uint256 number;

    function store(uint256 num) public isOwner{
        number = num;
    }

    function retrieve() public view returns (uint256){
        return number;
    }
}