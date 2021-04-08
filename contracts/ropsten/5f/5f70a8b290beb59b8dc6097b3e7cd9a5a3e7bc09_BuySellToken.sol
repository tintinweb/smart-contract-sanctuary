/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

pragma solidity ^0.4.19;

interface IERC20Token {
    function balanceOf(address owner) public returns (uint256);
    function transfer(address to, uint256 amount) public returns (bool);
    function transferFrom(address sender, address recepient, uint256 amt) public returns (bool);
    function decimals() public returns (uint256);
}

contract BuySellToken {
    IERC20Token public tokenContract;  // token address to sell and purchase
    uint256 public price;              // the price


    function BuySellToken(IERC20Token _tokenContract, uint256 _price) public {
        tokenContract = _tokenContract;
        price = _price;
    }

    function purchase(uint256 amt) public payable {
        require(msg.value == (amt * price)); // chk ether in user tx

        uint256 tkn = amt *
            (uint256(10) ** tokenContract.decimals()); // calculating decimal

        require(tokenContract.balanceOf(this) >= tkn); // chking sc balance of token

        require(tokenContract.transfer(msg.sender, tkn)); // transfering token to user
    }

    function sell(uint256 amt) public {
        require(address(this).balance >= amt * price); // checking eth balance in smart contract
        uint256 tkn = amt *
            (uint256(10) ** tokenContract.decimals()); // decimal calculating
            
        require(tokenContract.balanceOf(msg.sender) >= tkn); // cheking token balance of user

        require(tokenContract.transferFrom(msg.sender, address(this), tkn)); // getting token from user required approve
        
        msg.sender.transfer(amt * price); // transfering eth to user
    }
}