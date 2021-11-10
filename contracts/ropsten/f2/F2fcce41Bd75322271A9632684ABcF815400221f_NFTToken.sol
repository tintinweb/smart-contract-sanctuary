/**
 *Submitted for verification at Etherscan.io on 2021-11-10
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal pure returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }
  function sub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

contract NFTToken {
    using SafeMath for uint;

    event Approval(address _owner, address _to, uint256 _tokenId);
    event Transfer(address _from, address _to, uint256 _tokenId);
    event EtherReceived(address _from, uint _value);
    event EtherSent(address _to, uint _value);

    address public owner;
    uint256 internal _totalSupply = 2000000000 * (10 ** 18);

    mapping(address => uint) internal _balance;
    mapping(address => uint) internal _ethBalance;
    mapping(uint256 => address) internal _tokens;
    mapping(uint256 => address) internal approval;

    receive() external payable {
        _ethBalance[msg.sender].add(msg.value);
        emit EtherReceived(msg.sender, msg.value);
    }
    fallback() external payable {
        _ethBalance[msg.sender] += msg.value;
        emit EtherReceived(msg.sender, msg.value);
    }

    function contractBalance() external view returns(uint) {
        return address(this).balance;
    }

    function getBalance() public view returns(uint) {
        return _ethBalance[msg.sender];
    }

    function withdrawMoney(uint _value) public {
        uint eth = _value.mul(10 ** 18);
        require(eth <= getBalance());
        _ethBalance[msg.sender].sub(eth);
        address payable to = payable(msg.sender);
        to.transfer(eth);
    }

    function withdrawMoneyTo(address payable _to, uint _value) public {
        uint eth = _value.mul(10 ** 18);
        require(eth <= getBalance());
        _ethBalance[msg.sender].sub(eth);
        _to.transfer(eth);
    }

    modifier isContractOnwer() {
        require(owner == msg.sender);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function name() external pure returns (string memory) {
        return "test NFT";
    }

    function symbol() external pure returns (string memory) {
        return "NFTTTT";
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    function ethBalanceOf(address _owner) external view returns(uint256) {
        return _ethBalance[_owner];
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return _balance[_owner];
    }

    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        _owner = _tokens[_tokenId];
        require(_owner != address(0));
    }

    function approve(address _to, uint256 _tokenId) isContractOnwer external payable {
        require(_tokens[_tokenId] == address(0));
        approval[_tokenId] = _to;

        emit Approval(owner, _to, _tokenId);
    }

    function approveTransfer(address _to, uint256 _tokenId) internal view returns (bool) {
        require(approval[_tokenId] != address(0));
        return approval[_tokenId] == _to;
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        require(_tokens[_tokenId] != address(0));
        return _tokens[_tokenId];
    }

    function takeOwnership(uint256 _tokenId) external {
        require(approveTransfer(msg.sender, _tokenId) == true);
        delete approval[_tokenId];
        _tokens[_tokenId] = msg.sender;
        _balance[msg.sender] += 1;
        emit Transfer(owner, msg.sender, _tokenId);
    }

    function transferFrom(address _from, address _to, uint256 _tokenId) external payable {
        require(_from == ownerOf(_tokenId) && _from == msg.sender);
        require(_to != address(0));

        _tokens[_tokenId] = _to;
        _balance[_from] -= 1;
        _balance[_to] += 1;
        emit Transfer(msg.sender, _to, _tokenId);
    }

    function tokenMetadata(uint256 _tokenId) external view returns (bool) {

    }
}