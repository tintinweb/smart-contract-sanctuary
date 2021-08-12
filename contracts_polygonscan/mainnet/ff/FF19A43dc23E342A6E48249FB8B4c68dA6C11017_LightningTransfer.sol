/**
 *Submitted for verification at polygonscan.com on 2021-08-12
*/

pragma solidity ^0.5.11;

contract Ownable {
    address public owner;

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
}

contract IToken {
    function balanceOf(address) public view returns (uint256);
    function transfer(address, uint256) public returns (uint256); 
}

contract LightningTransfer is Ownable {
    function getBalance(address tokenAddress) public view returns(uint256) {
        IToken token = IToken(tokenAddress);
        return token.balanceOf(address(this));
    }
    
    function send(address tokenAddress, address[] memory addresses, uint256[] memory values) public onlyOwner {
        IToken token = IToken(tokenAddress);
        for (uint256 i = 0; i < addresses.length; i++) {
            token.transfer(addresses[i], values[i]);
        }
    }
     
    // Each transaction need 41353 * gas price =>
    // Ex: with gas price = 10 gwei, want to have 100 transactions => we need to transfer
    // value = 10.000.000.000 (10 gwei) * 41353 (gas for 1 transaction) * 100

    function sendEthereum(uint256 value, address payable [] memory addresses) public onlyOwner {
        for (uint256 i = 0; i < addresses.length; i++) {
            addresses[i].transfer(value);
        }
    }

    function () external payable {}
}