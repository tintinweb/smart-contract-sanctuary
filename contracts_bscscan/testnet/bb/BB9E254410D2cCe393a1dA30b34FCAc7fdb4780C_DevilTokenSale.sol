// SPDX-License-Identifier: MIT
pragma solidity ^0.7.0;

import './DevilToken.sol';
import './DevilBNB.sol';

contract DevilTokenSale {
    // address of admin
    address payable public  admin;
    // define the instance of DevToken
    DevilBNB public DevilBNBToken;
    Devil public DevilToken;
    // token price variable
    uint256 public tokenprice;
    // count of token sold vaariable
    uint256 public totalsold; 
     
    event Sell(address sender,uint256 totalvalue); 
   
    // constructor 
    constructor(address _DevilBNBAddress,address _DevilAddress,uint256 _tokenValue){
        admin  = msg.sender;
        tokenprice = _tokenValue;
        DevilBNBToken  = DevilBNB(_DevilBNBAddress);
        DevilToken  = Devil(_DevilAddress);
    }
   
    // buyTokens function
    function buyTokens(uint256 _amount) public {
    // check if the contract has the tokens or not
    require(DevilBNBToken.balanceOf(msg.sender) >= _amount,'Low balance of DevilBNB tokens');
    // transfer the token to the user
    DevilBNBToken.transfer(address(this),_amount);
    DevilToken.transfer(msg.sender,_amount*tokenprice);
    emit Sell(msg.sender,_amount*tokenprice);
    }

    // end sale
    function endsale() public{
    // check if admin has clicked the function
    require(msg.sender == admin , ' you are not the admin');
    // transfer all the remaining tokens to admin
    DevilBNBToken.transfer(msg.sender,DevilBNBToken.balanceOf(address(this)));
    // transfer all the etherum to admin and self selfdestruct the contract
    selfdestruct(admin);
    }
}