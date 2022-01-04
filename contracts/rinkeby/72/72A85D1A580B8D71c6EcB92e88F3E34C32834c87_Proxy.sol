/**
 *Submitted for verification at Etherscan.io on 2022-01-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// Ownable contract
contract Ownable {
    address public owner;

    constructor(){
        owner = msg.sender;
    }

    modifier onlyOwner(){
        if(msg.sender == owner)
        _;
    }

    function transferOwnerShip(address newOwner) public onlyOwner{
        if(newOwner != address(0)) owner = newOwner;
    }
}

contract Proxy is Ownable{
    address payable implementation = payable(0xB89341c21949Ee4B20bAC0f035102C7eB3B8C2E2);
    uint256 version = 1;

    uint256 public test1; 
    uint256 public test2; 
    uint256 public result; 

    fallback() payable external{
        (bool sucess,bytes memory _result) = implementation.delegatecall(msg.data);
    }

    function changeImplementation(address payable _newImpementation , uint256 _newVersion) public onlyOwner {
        require(_newVersion > version,"New V > than previous");
        implementation = _newImpementation;
    }

    uint256[50] private _gap;
}