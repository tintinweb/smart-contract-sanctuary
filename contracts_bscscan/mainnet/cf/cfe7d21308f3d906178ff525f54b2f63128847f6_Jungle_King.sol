pragma solidity 0.8.10;

// SPDX-License-Identifier: MIT

import "./SafeMath.sol";
import "./BEP20.sol";
import "./Ownable.sol";
import "./Token.sol";

contract Jungle_King is BEP20, Ownable {
    using SafeMath for uint256;
    
    bool public isSellEnabled = false;

    uint256 public toenPrice = 1722222;
    address public teamAddress = 0x771A24B71E630Bc515d87fC6c4Db05133eFF0044;

    constructor() BEP20("Jungle King", "KING") {
        _mint(teamAddress, 5e27);
        addWallet(teamAddress);
        transferOwnership(teamAddress);
    }
    
    // Function to buy token
    function buyToken() public payable {
        require(isSellEnabled, "Sell not enabled yet..");
        uint256 value = msg.value;
        uint256 tokenAmount = value.mul(toenPrice);
        Token(address(this)).transferFrom(teamAddress, msg.sender, tokenAmount);
    }
    
    // Function to enable token trading..
    function enabledTrading() public onlyOwner {
        require(!isTradingEnabled, "Trading alredy enabled..");
        isTradingEnabled = true;
    }
    
    // Function to enable token sell..
    function enableTokenSell() public onlyOwner {
        require(!isSellEnabled, "Sell alredy enabled..");
        isSellEnabled = true;
    }
    
    // Function to disable token sell..
    function disableTokenSell() public onlyOwner {
        require(isSellEnabled, "Sell alredy disabled..");
        isSellEnabled = false;
    }
    
    // Function to add wallet so the wallet can transfer token befor trading enabled..
    function addWalletToTransferTokenBeforeTradingIsEnabled(address account) public onlyOwner {
        addWallet(account);
    }
    
    // Function to transfer BNB from this..
    function transferBNB(address payable recipient, uint256 amount) public onlyOwner {
        recipient.transfer(amount);
    }
    
    // Function to burn token, only owner can call this function..
    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount);
    }
    
    // Function to set new owner address..
    function setTeamAddress(address _teamAddress) public onlyOwner {
        teamAddress = _teamAddress;
    }
    
    // function to allow admin to transfer *any* BEP20 tokens from this contract
    function transferAnyBEP20Tokens(address tokenAddress, address recipient, uint256 amount) public onlyOwner {
        require(amount > 0, "BEP20: amount must be greater than 0");
        require(recipient != address(0), "BEP20: recipient is the zero address");
        Token(tokenAddress).transfer(recipient, amount);
    }
    
    // to receive BNB and call the buyToken function..
    receive() external payable {
        buyToken();
    }
}