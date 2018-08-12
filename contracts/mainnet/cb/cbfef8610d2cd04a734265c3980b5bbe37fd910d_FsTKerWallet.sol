pragma solidity ^0.4.24;

contract ERC {
  function balanceOf (address) public view returns (uint256);
  function allowance (address, address) public view returns (uint256);
  function transfer (address, uint256) public returns (bool);
  function transferFrom (address, address, uint256) public returns (bool);
  function transferAndCall(address, uint256, bytes) public payable returns (bool);
  function approve (address, uint256) public returns (bool);
}

contract FsTKerWallet {

  string constant public walletVersion = "v1.0.0";

  ERC public FST;

  address public owner;
  bytes32 public secretHash;
  uint256 public sn;

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  constructor (ERC _FST, bytes32 _secretHash, uint256 _sn) public {
    FST = _FST;
    secretHash = _secretHash;
    sn = _sn;
  }

  function getFSTBalance () public view returns (uint256) {
    return FST.balanceOf(address(this));
  }

  function getETHBalance () public view returns (uint256) {
    return address(this).balance;
  }

  function getERCBalance (ERC erc) public view returns (uint256) {
    return erc.balanceOf(address(this));
  }

  function transferETH (address _to, uint256 _value) onlyOwner public returns (bool) {
    _to.transfer(_value);
    return true;
  }

  function transferMoreETH (address _to, uint256 _value) onlyOwner payable public returns (bool) {
    _to.transfer(_value);
    return true;
  }

  function transferFST (address _to, uint256 _value) onlyOwner public returns (bool) {
    return FST.transfer(_to, _value);
  }

  function transferERC (ERC erc, address _to, uint256 _value) onlyOwner public returns (bool) {
    return erc.transfer(_to, _value);
  }

  function transferFromFST (address _from, address _to, uint256 _value) onlyOwner public returns (bool) {
    return FST.transferFrom(_from, _to, _value);
  }

  function transferFromERC (ERC erc, address _from, address _to, uint256 _value) onlyOwner public returns (bool) {
    return erc.transferFrom(_from, _to, _value);
  }

  function transferAndCallFST (address _to, uint256 _value, bytes _data) onlyOwner payable public returns (bool) {
    require(FST.transferAndCall.value(msg.value)(_to, _value, _data));
    return true;
  }

  function transferAndCallERC (ERC erc, address _to, uint256 _value, bytes _data) onlyOwner payable public returns (bool) {
    require(erc.transferAndCall.value(msg.value)(_to, _value, _data));
    return true;
  }

  function approveFST (address _spender, uint256 _value) onlyOwner public returns (bool) {
    return FST.approve(_spender, _value);
  }

  function approveERC (ERC erc, address _spender, uint256 _value) onlyOwner public returns (bool) {
    return erc.approve(_spender, _value);
  }

  function recoverAndSetSecretHash (string _secret, bytes32 _newSecretHash) public returns (bool) {
    require(_newSecretHash != bytes32(0));
    require(keccak256(abi.encodePacked(_secret)) == secretHash);
    owner = msg.sender;
    secretHash = _newSecretHash;
    return true;
  }

  function setFST (ERC _FST) onlyOwner public returns (bool) {
    require(address(_FST) != address(this) && address(_FST) != address(0x0));
    FST = _FST;
    return true;
  }

  function callContract(address to, bytes data) onlyOwner public payable returns (bool) {
    require(to.call.value(msg.value)(data));
    return true;
  }

  function () external payable {}

}