pragma solidity >=0.6.0 <=0.6.8;

//SPDX-License-Identifier: MIT

import "ERC20.sol";

contract Owner {

    address payable public owner;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
    }

    function changeOwner(address payable newOwner) public onlyOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }
}


contract FoxInvSplit is Owner {
    using SafeMath for uint256;
    
    uint per1;
    address payable inv2;
    uint per2;
    
    function setInvestitors(address payable investitor2, uint percentual2) public onlyOwner {
        uint maxPer =  10000;
        per1 = maxPer.sub(percentual2);
        inv2 = investitor2;
        per2 = percentual2;
    }
        
    function getInvestitors() public view returns (address, uint, address, uint) {
        return (owner, per1, inv2, per2);
    }
    
    
    receive() external payable {
        if(per2 == 0){
            owner.transfer(msg.value);
        }else{
            owner.transfer(msg.value.mul(per1).div(10000));
            inv2.transfer(msg.value.mul(per2).div(10000));
        }
    }
        
        
    function withdrawETH() external onlyOwner {
        owner.transfer(address(this).balance);
    }
    
    function withdrawERC20(address tokenAddress, uint decimal, uint amount) external onlyOwner {
        ERC20 token = ERC20(tokenAddress);
        token.transfer(owner, amount*10**decimal);
    }
    
}