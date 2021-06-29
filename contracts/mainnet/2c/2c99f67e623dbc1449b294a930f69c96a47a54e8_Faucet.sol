/**
 *Submitted for verification at Etherscan.io on 2021-06-29
*/

pragma solidity ^0.4.16;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Faucet {
    mapping (address => bool) _claimed;
    address erc20_address;
    
    function Faucet(address _erc20_address) public {
        erc20_address = _erc20_address;
    }
    
    modifier noClaimYet(address _recipient) {
        require(_claimed[_recipient] == false);
        _;
    }
    
    function claim() public noClaimYet(msg.sender) {
        uint amount = 1e21;
        require(ERC20Basic(erc20_address).balanceOf(this) >= amount);
        _claimed[msg.sender] = true;
        ERC20Basic(erc20_address).transfer(msg.sender, amount);
    }
}