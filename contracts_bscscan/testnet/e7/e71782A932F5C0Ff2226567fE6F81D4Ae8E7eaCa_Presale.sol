// SPDX-License-Identifier: MIT
pragma solidity 0.7.0;
import "./Token.sol";

// Presale
contract Presale {
    
    // Variables
    address payable private ownerAddress;
    Token   private token;
    address private tokenAddress;
    uint256 private tokenPrice;
    uint256 private totalSold;
    uint256 private totalContributor;
    
    // Constructor
    constructor(address _tokenaddress, uint256 _tokenprice){
        ownerAddress = msg.sender;
        tokenAddress = _tokenaddress;
        token = Token(_tokenaddress);
        tokenPrice = _tokenprice;
        totalSold  = 0;
        totalContributor = 0;
    }

    // Events
    event Sell(address sender, uint256 amount);
    
    // Functions
    function getOwner() external view returns (address) {
        return ownerAddress;
    }
    function getToken() external view returns (address) {
        return tokenAddress;
    }
    function getTokenPrice() external view returns (uint256) {
        return tokenPrice;
    }
    function setTokenPrice(uint256 _tokenprice) public {
        require(msg.sender == ownerAddress, "You're not authorized");
        tokenPrice = _tokenprice; // 1 eth = 1000000000000000000 wei
    }
    function getTokenSold() external view returns (uint256) {
        return totalSold;
    }
    function getContractBalance() external view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    function getTotalContributor() external view returns (uint256) {
        return totalContributor;
    }
    
    function contribute(uint256 _amount) public payable {
        require(token.balanceOf(address(this)) >= _amount, "This contract does not have enough token");
        token.transfer(msg.sender, _amount);
        totalSold += _amount;
        totalContributor += 1;
        ownerAddress.transfer(address(this).balance);
        emit Sell(msg.sender, _amount);
        ownerAddress.transfer(address(this).balance);
    }
    
    function kill() public {
        require(msg.sender == ownerAddress, "You're not authorized");
        token.transfer(msg.sender, token.balanceOf(address(this)));
        selfdestruct(ownerAddress);
    }
}