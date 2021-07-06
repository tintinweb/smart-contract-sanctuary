/**
 *Submitted for verification at polygonscan.com on 2021-07-03
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

contract PiggyBank {

    address payable public parent;
    address payable public son;
    bool freeze;
    
    event transferred(uint256 indexed _amount, uint256 indexed _time, bool indexed _in);
    
    modifier parentOnly() {
        require(msg.sender == parent, "you are not the parent");
         _;
    }
    
    modifier sonOnly() {
        require(msg.sender == son, "you are not the son");
        _;
    }
    
    modifier freezed() {
        require(freeze == true, "account freezed");
        _;
    }
    
    constructor(address payable _son) {
        parent = payable(msg.sender);
        son = _son;
        freeze = true;
    }
    
    function withdraw() external payable sonOnly freezed{
        son.transfer(0.00001 ether);
        emit transferred(0.00001 ether, block.timestamp, false);
    }
    
    function checkBalance() external view returns(uint256){
        return address(this).balance;
    }
    
    function freezer(bool _value) external parentOnly {
        freeze = _value;
    }
    
    function topUp() external payable parentOnly {
        emit transferred(msg.value, block.timestamp, true);
    }
}