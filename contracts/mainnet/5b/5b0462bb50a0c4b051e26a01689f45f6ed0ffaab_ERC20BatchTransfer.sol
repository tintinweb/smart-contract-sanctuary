pragma solidity ^0.4.18;

// File: contracts/ERC20.sol

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  function totalSupply() constant public returns (uint);

  function balanceOf(address who) constant public returns (uint256);

  function transfer(address to, uint256 value) public returns (bool);

  function allowance(address owner, address spender) public constant returns (uint256);

  function transferFrom(address from, address to, uint256 value) public returns (bool);

  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed _owner, address indexed _spender, uint256 _value);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
}

// File: contracts/ERC20BatchTransfer.sol

contract ERC20BatchTransfer {

  function batchTransfer(address _tokenAddress, address[] _beneficiaries, uint256 _amount) public {
    require(_amount > 0);
    ERC20 tokenContract = ERC20(_tokenAddress);
    for (uint b = 0; b < _beneficiaries.length; b++) {
      require(tokenContract.transferFrom(msg.sender, _beneficiaries[b], _amount));
    }
  }

}