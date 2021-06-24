/**
 *Submitted for verification at Etherscan.io on 2021-06-23
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

contract button {
    uint256 public buttonCount = 0;
    address public addr;
    
    uint256 public openingTime = 0;
    address payable wallet;
    
    // constructor(address payable _wallet){
    //     wallet = _wallet;
    // }
    event Received(address,uint);
    receive() external payable {}
    struct Button{
        int trigger;
    }
    function addButton()
    public
    payable
    returns(address)
    {
        if ((openingTime >= block.timestamp) || (openingTime == 0)) {
            openingTime = block.timestamp + 5;
            buttonCount += 1;
            addr = msg.sender;
            //wallet.transfer(msg.value);
            return (addr);
        }
        else{
            payable(addr).transfer(1000000000000000000);
            return (addr);
        }
        
    }
    
    
    
    
}