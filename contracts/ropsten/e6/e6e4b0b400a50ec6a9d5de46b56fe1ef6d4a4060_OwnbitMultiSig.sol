/**
 *Submitted for verification at Etherscan.io on 2021-08-24
*/

pragma solidity ^0.4.26;

// This is the ETH/ERC20 multisig contract for Ownbit.
//
// For 2-of-3 multisig, to authorize a spend, two signtures must be provided by 2 of the 3 owners.
// To generate the message to be signed, provide the destination address and
// spend amount (in wei) to the generateMessageToSign method.
// The signatures must be provided as the (v, r, s) hex-encoded coordinates.
// The S coordinate must be 0x00 or 0x01 corresponding to 0x1b and 0x1c, respectively.
//
// WARNING: The generated message is only valid until the next spend is executed.
//          after that, a new message will need to be calculated.
//
//
// INFO: This contract is ERC20 compatible.
// This contract can both receive ETH and ERC20 tokens.
// Notice that NFT (ERC721/ERC1155) is not supported. But can be transferred out throught spendAny.
// Last update time: 2020-12-12.

interface Erc20 {
  function approve(address, uint256) public;

  function transfer(address, uint256) public;
    
  //function balanceOf(address) view public returns (uint256);
}

contract OwnbitMultiSig {
    
  uint constant public MAX_OWNER_COUNT = 9;

  // The N addresses which control the funds in this contract. The
  // owners of M of these addresses will need to both sign a message
  // allowing the funds in this contract to be spent.
  mapping(address => bool) private isOwner;
  address[] private owners;
  uint private required;

  // The contract nonce is not accessible to the contract so we
  // implement a nonce-like variable for replay protection.
  uint256 private spendNonce = 0;
  
  // An event sent when funds are received.
  event Funded(address from, uint value);
  
  // An event sent when a spend is triggered to the given address.
  event Spent(address to, uint transfer);
  
  // An event sent when a spendERC20 is triggered to the given address.
  event SpentERC20(address erc20contract, address to, uint transfer);
  
  // An event sent when an spendAny is executed.
  event SpentAny(address to, uint transfer);

  modifier validRequirement(uint ownerCount, uint _required) {
    require (ownerCount <= MAX_OWNER_COUNT
            && _required <= ownerCount
            && _required >= 1);
    _;
  }
  
  /// @dev Contract constructor sets initial owners and required number of confirmations.
  /// @param _owners List of initial owners.
  /// @param _required Number of required confirmations.
  constructor(address[] _owners, uint _required) public validRequirement(_owners.length, _required) {
    for (uint i = 0; i < _owners.length; i++) {
        //onwer should be distinct, and non-zero
        if (isOwner[_owners[i]] || _owners[i] == address(0x0)) {
            revert();
        }
        isOwner[_owners[i]] = true;
    }
    owners = _owners;
    required = _required;
  }


  // The fallback function for this contract.
  function() public payable {
    if (msg.value > 0) {
        emit Funded(msg.sender, msg.value);
    }
  }
  
  // @dev Returns list of owners.
  // @return List of owner addresses.
  function getOwners() public view returns (address[]) {
    return owners;
  }
    
  function getSpendNonce() public view returns (uint256) {
    return spendNonce;
  }
    
  function getRequired() public view returns (uint) {
    return required;
  }


  // @destination: the ether receiver address.
  // @value: the ether value, in wei.
  // @vs, rs, ss: the signatures
  function spend(address destination, uint256 value, uint8[] vs, bytes32[] rs, bytes32[] ss, bytes32[] hashes) external {
    require(destination != address(this), "Not allow sending to yourself");
    require(address(this).balance >= value && value > 0, "balance or spend value invalid");
    require( _validSignature(vs, rs, ss,hashes), "invalid signatures");
    spendNonce = spendNonce + 1;
    //transfer will throw if fails
    destination.transfer(value);
    emit Spent(destination, value);
  }
  
  // @erc20contract: the erc20 contract address.
  // @destination: the token receiver address.
  // @value: the token value, in token minimum unit.
  // @vs, rs, ss: the signatures
  function spendERC20(address destination, address erc20contract, uint256 value, uint8[] vs, bytes32[] rs, bytes32[] ss,bytes32[] hashes) external {
    require(destination != address(this), "Not allow sending to yourself");
    //transfer erc20 token
    //uint256 tokenValue = Erc20(erc20contract).balanceOf(address(this));
    require(value > 0, "Erc20 spend value invalid");
    require(_validSignature(   vs, rs, ss,hashes), "invalid signatures");
    spendNonce = spendNonce + 1;
    // transfer tokens from this contract to the destination address
    Erc20(erc20contract).transfer(destination, value);
    emit SpentERC20(erc20contract, destination, value);
  }
  
  //0x9 is used for spendAny
  //be careful with any action, data is not included into signature computation. So any data can be included in spendAny.
  //This is usually for some emergent recovery, for example, recovery of NTFs, etc.
  //Owners should not generate 0x9 based signatures in normal cases.
  function spendAny(address destination, uint256 value, uint8[] vs, bytes32[] rs, bytes32[] ss, bytes data, bytes32[] hashes) external {
    require(destination != address(this), "Not allow sending to yourself");
    require(_validSignature(  vs, rs, ss,hashes), "invalid signatures");
    spendNonce = spendNonce + 1;
    //transfer tokens from this contract to the destination address
    if (destination.call.value(value)(data)) {
        emit SpentAny(destination, value);
    }
  }

  // Confirm that the signature triplets (v1, r1, s1) (v2, r2, s2) ...
  // authorize a spend of this contract's funds to the given destination address.
  function _validSignature(uint8[] vs, bytes32[] rs, bytes32[] ss,bytes32[] hashes) private view returns (bool) {
    require(vs.length == rs.length);
    require(rs.length == ss.length);
    require(hashes.length == rs.length);
    require(vs.length <= owners.length);
    require(vs.length >= required);
    address[] memory addrs = new address[](vs.length);
    for (uint i = 0; i < vs.length; i++) {
        //recover the address associated with the public key from elliptic curve signature or return zero on error 
        addrs[i] = ecrecover(hashes[i], vs[i], rs[i], ss[i]);
    }
    require(_distinctOwners(addrs));
    return true;
  }
  
  // Confirm that the signature triplets (v1, r1, s1) (v2, r2, s2) ...
  // authorize a spend of this contract's funds to the given destination address.
  function testValidSignature(uint8[] vs, bytes32[] rs, bytes32[] ss,bytes32[] hashes) public view returns (address[]) {
    require(vs.length == rs.length);
    require(rs.length == ss.length);
    require(hashes.length == rs.length);
    require(vs.length <= owners.length);
    require(vs.length >= required);
    address[] memory addrs = new address[](vs.length);
    for (uint i = 0; i < vs.length; i++) {
        //recover the address associated with the public key from elliptic curve signature or return zero on error 
        addrs[i] = ecrecover(hashes[i], vs[i], rs[i], ss[i]);
    }
    require(_distinctOwners(addrs));
    return addrs;
  }
  
  // Confirm the addresses as distinct owners of this contract.
  function _distinctOwners(address[] addrs) private view returns (bool) {
    if (addrs.length > owners.length) {
        return false;
    }
    for (uint i = 0; i < addrs.length; i++) {
        if (!isOwner[addrs[i]]) {
            return false;
        }
        //address should be distinct
        for (uint j = 0; j < i; j++) {
            if (addrs[i] == addrs[j]) {
                return false;
            }
        }
    }
    return true;
  }
  
}