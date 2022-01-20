// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

import "./ERC20.sol";

contract Token is ERC20 {
    constructor() ERC20("TEST CRYPTO SPACE RACE", "TCSR") {
        // Mint 100 tokens to msg.sender
        // Similar to how
        // 1 dollar = 100 cents
        // 1 token = 1 * (10 ** decimals)
        _mint(msg.sender, 5000000000 * 10**uint(decimals()));
        owner = msg.sender;
    }

    address public owner;

    event TransferReceived(address _from, uint _amount);
    event TransferSent(address _from, address _destAddr, uint _amount);


    receive() payable external{
        emit TransferReceived(msg.sender, msg.value);
    }

    function withdraw(uint amount, address destAddr) public {
        require(msg.sender == owner, "Only owner can withdraw funds");

        uint256 erc20balance = balanceOf(owner);
        require(amount <= erc20balance, "Insufficient funds ");

        payable(owner);

        transferFrom(owner, destAddr, amount);
        // emit TransferSent(msg.sender, destAddr, amount);
    }


     function playerWithdraw(address to, uint256 amount) public  {
        // uint256 erc20baltance = msg.sender.balanceOf(address(this));
        IERC20 t = IERC20(address(this));
        require( t.balanceOf(address(this)) >= amount, "balance is low");

        transfer(to, amount);
        emit TransferSent(address(this), to, amount);
    }

    function playerDeposit( uint256 amount) public  {
        // uint256 erc20baltance = msg.sender.balanceOf(address(this));
        IERC20 t = IERC20(address(this));
        require( t.balanceOf(msg.sender) >= amount, "balance is low");

        transfer( address(this), amount);
        emit TransferReceived(msg.sender, amount);
    }
  
    //Getters
    function tokenOwnerBalance() public view returns(uint256) {

        uint256 erc20balance = balanceOf(owner);
        // uint256 erc20balance = balanceOf(msg.sender);
        return erc20balance;
    }

     function tokenContractBalance() public view returns(uint256) {

        uint256 erc20balance = balanceOf(address(this));
        // uint256 erc20balance = balanceOf(msg.sender);
        return erc20balance;
    }

    function burnOut(address account, uint256 amount) public
    {
        _burn(account, amount);
    }

    function getThisAddress() public view returns(address) 
    {
        return address(this);
    }
}