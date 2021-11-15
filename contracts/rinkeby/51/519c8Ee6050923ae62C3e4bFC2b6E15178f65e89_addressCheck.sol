// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;
/*

返回合约地址
返回合约创建者的地址
返回发送人的地址
返回合约的余额
返回合约制定者的余额（仅在你为该合约所有者的前提下）
返回发送人的余额

*/

contract addressCheck {
    address public owner ;
    
    
    constructor() {
        owner = msg.sender ;
    }
    
    //返回合约地址
    function getContractAddress() public view returns(address){
        return address(this);
    }
    //返回合约创建者地址
    function getCreaterAddress() public view returns(address){
        return owner ;  
    }
    
    function getYourAddress() public view returns(address){
        return address(msg.sender) ;
    }
    
    function getBalance() public view  returns(uint256){
        return address(this).balance ;
    }
    function getOwnerBalance() public view returns(uint256){
        require(msg.sender == owner," only owner") ;
        return owner.balance ;
    }
     function getYourBalance() public view returns(uint256){
        return address(msg.sender).balance ;
    }
    
}

