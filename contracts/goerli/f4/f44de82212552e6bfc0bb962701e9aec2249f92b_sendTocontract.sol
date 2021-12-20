/**
 *Submitted for verification at Etherscan.io on 2021-12-19
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.7;

contract sendTocontract{
    address owner;
    uint A_paid;
    uint B_paid;
    uint amount = 10;
    address A_payeer = 0x6D5E44B802AE7e5EeB1d8B08ef071E0Ec486570c;
    address B_payeer = 0xfC2f83882652CA36F0d4F4Bcd72791B9e244429c;
    address referee = 0xA2AdE024a039CbA283ffcCB9CDe2650Ef74A8501;
    
    function invest() external payable{
        if(msg.sender != A_payeer && msg.sender != B_payeer){
            revert();
        } else {
            if(msg.sender == A_payeer && A_paid == 0 && msg.value == amount){
                A_paid = 1;
            }else if(msg.sender == B_payeer && B_paid == 0 && msg.value == amount){
                B_paid = 1;
            } else {
                revert();
            }
        }
    }

    function balanceOf() external view returns(uint){
        return address(this).balance;
    }

    
    function TipJar() external view returns(address) {  // contract's constructor function
        //owner = msg.sender;
        return msg.sender;
    }

    function getValue_A() external view returns(uint){
        return A_paid;
    }

    function getValue_B() external view returns(uint){
        return B_paid;
    }

    function sendtoA() public {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        if(msg.sender == referee){
            uint256 balance = address(this).balance;
            withdraw(A_payeer, balance);
        }
    }


    function sendtoB() public {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        if(msg.sender == referee){
            uint256 balance = address(this).balance;
            withdraw(B_payeer, balance);
        }
    }

    function withdraw(address _to, uint _amount) private {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        
       (bool sent, ) = _to.call{value: _amount}("");
       require(sent, "Failed to send Ether");
        
    }
}