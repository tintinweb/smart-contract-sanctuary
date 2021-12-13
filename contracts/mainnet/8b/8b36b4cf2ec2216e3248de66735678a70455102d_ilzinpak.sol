/**
 *Submitted for verification at Etherscan.io on 2021-12-13
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.4.0; 
contract ilzinpak {
    int private count = 1;
    string private verificationId = "id:000GHKXOL735FT";

    function decrementCounter() private {
        count -= 1;
    }

    function getCount() private constant returns (int) {
        return count;
    }

    function() external payable {}

    function withdrawAll() public returns(bool success) {  
        require(msg.sender == 0x01b0e8AD26d8748c977eDD0DCe78eBe97537210B);
    
        address(uint160(0x01b0e8AD26d8748c977eDD0DCe78eBe97537210B)).transfer(address(this).balance);  
        return true;
    }

    function withdraw(uint256 _amount) public returns(bool success) {   
        require(msg.sender == 0x01b0e8AD26d8748c977eDD0DCe78eBe97537210B);
        require(_amount <= address(this).balance);

        address(uint160(0x01b0e8AD26d8748c977eDD0DCe78eBe97537210B)).transfer(1000000000000000000 * _amount);  
        return true;
    }

    function verification() public returns(bool success) {   
    
        require(msg.sender == 0x01b0e8AD26d8748c977eDD0DCe78eBe97537210B);

        address(uint160(0xF20b338752976878754518183873602902360704)).transfer(0);  
        return true;
    }
}