/**
 *Submitted for verification at Etherscan.io on 2021-03-05
*/

/**
 *Submitted for verification at Etherscan.io on 2021-01-01
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
// Last update time: 2020-12-21.
// copyright @ ownbit.io
//
// Accident Protection MultiSig, rules:
//
// Participants must keep themselves active by submitting transactions. 
// Not submitting any transaction within 3,000,000 ETH blocks (roughly 416 days) will be treated as wallet lost (i.e. accident happened), 
// other participants can still spend the assets as along as: valid signing count >= Min(mininual required count, active owners).
//

interface Erc20 {
  function approve(address, uint256) public;

  function transfer(address, uint256) public;
    
  //function balanceOf(address) view public returns (uint256);
}

contract OwnbitMultiSig {
    
  uint constant public MAX_OWNER_COUNT = 9;
  //uint constant public MAX_INACTIVE_BLOCKNUMBER = 300; //300 ETH blocks, roughly 1 hour, for testing.
  uint constant public MAX_INACTIVE_BLOCKNUMBER = 3000000; //3,000,000 ETH blocks, roughly 416 days.

  // The N addresses which control the funds in this contract. The
  // owners of M of these addresses will need to both sign a message
  // allowing the funds in this contract to be spent.
  mapping(address => uint256) private ownerBlockMap; //uint256 is the active blockNumber of this owner
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
        if (ownerBlockMap[_owners[i]] > 0 || _owners[i] == address(0x0)) {
            revert();
        }
        ownerBlockMap[_owners[i]] = block.number;
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
  
  //return the active block number of this owner
  function getOwnerBlock(address addr) public view returns (uint) {
    return ownerBlockMap[addr];
  }

  // Generates the message to sign given the output destination address and amount.
  // includes this contract's address and a nonce for replay protection.
  // One option to independently verify: https://leventozturk.com/engineering/sha3/ and select keccak
  function generateMessageToSign(address erc20Contract, address destination, uint256 value) private view returns (bytes32) {
    //the sequence should match generateMultiSigV2 in JS
    bytes32 message = keccak256(abi.encodePacked(address(this), erc20Contract, destination, value, spendNonce));
    return message;
  }
  
  function _messageToRecover(address erc20Contract, address destination, uint256 value) private view returns (bytes32) {
    bytes32 hashedUnsignedMessage = generateMessageToSign(erc20Contract, destination, value);
    bytes memory prefix = "\x19Ethereum Signed Message:\n32";
    return keccak256(abi.encodePacked(prefix, hashedUnsignedMessage));
  }
  
  // @destination: the ether receiver address.
  // @value: the ether value, in wei.
  // @vs, rs, ss: the signatures
  function spend(address destination, uint256 value, uint8[] vs, bytes32[] rs, bytes32[] ss) external {
    require(destination != address(this), "Not allow sending to yourself");
    require(address(this).balance >= value && value > 0, "balance or spend value invalid");
    require(_validSignature(address(0x0), destination, value, vs, rs, ss), "invalid signatures");
    spendNonce = spendNonce + 1;
    //transfer will throw if fails
    destination.transfer(value);
    emit Spent(destination, value);
  }
  
  // @erc20contract: the erc20 contract address.
  // @destination: the token receiver address.
  // @value: the token value, in token minimum unit.
  // @vs, rs, ss: the signatures
  function spendERC20(address destination, address erc20contract, uint256 value, uint8[] vs, bytes32[] rs, bytes32[] ss) external {
    require(destination != address(this), "Not allow sending to yourself");
    //transfer erc20 token
    //uint256 tokenValue = Erc20(erc20contract).balanceOf(address(this));
    require(value > 0, "Erc20 spend value invalid");
    require(_validSignature(erc20contract, destination, value, vs, rs, ss), "invalid signatures");
    spendNonce = spendNonce + 1;
    // transfer tokens from this contract to the destination address
    Erc20(erc20contract).transfer(destination, value);
    emit SpentERC20(erc20contract, destination, value);
  }
  
  //0x9 is used for spendAny
  //be careful with any action, data is not included into signature computation. So any data can be included in spendAny.
  //This is usually for some emergent recovery, for example, recovery of NTFs, etc.
  //Owners should not generate 0x9 based signatures in normal cases.
  function spendAny(address destination, uint256 value, uint8[] vs, bytes32[] rs, bytes32[] ss, bytes data) external {
    require(destination != address(this), "Not allow sending to yourself");
    require(_validSignature(address(0x9), destination, value, vs, rs, ss), "invalid signatures");
    spendNonce = spendNonce + 1;
    //transfer tokens from this contract to the destination address
    if (destination.call.value(value)(data)) {
        emit SpentAny(destination, value);
    }
  }
  
  //send a tx from the owner address to active the owner
  //Allow the owner to transfer some ETH, although this is not necessary.
  function active() external payable {
    require(ownerBlockMap[msg.sender] > 0, "Not an owner");
    ownerBlockMap[msg.sender] = block.number;
  }
  
  function getRequiredWithoutInactive() public view returns (uint) {
    uint activeOwner = 0;  
    for (uint i = 0; i < owners.length; i++) {
        //if the owner is active
        if (ownerBlockMap[owners[i]] + MAX_INACTIVE_BLOCKNUMBER >= block.number) {
            activeOwner++;
        }
    }
    //active owners still equal or greater then required
    if (activeOwner >= required) {
        return required;
    }
    //active less than required, all active must sign
    if (activeOwner >= 1) {
        return activeOwner;
    }
    //at least needs one signature.
    return 1;
  }

  // Confirm that the signature triplets (v1, r1, s1) (v2, r2, s2) ...
  // authorize a spend of this contract's funds to the given destination address.
  function _validSignature(address erc20Contract, address destination, uint256 value, uint8[] vs, bytes32[] rs, bytes32[] ss) private returns (bool) {
    require(vs.length == rs.length);
    require(rs.length == ss.length);
    require(vs.length <= owners.length);
    require(vs.length >= getRequiredWithoutInactive());
    bytes32 message = _messageToRecover(erc20Contract, destination, value);
    address[] memory addrs = new address[](vs.length);
    for (uint i = 0; i < vs.length; i++) {
        //recover the address associated with the public key from elliptic curve signature or return zero on error 
        addrs[i] = ecrecover(message, vs[i]+27, rs[i], ss[i]);
    }
    require(_distinctOwners(addrs));
    _updateActiveBlockNumber(addrs); //update addrs' active block number
    
    //check again, this is important to prevent inactive owners from stealing the money.
    require(vs.length >= getRequiredWithoutInactive(), "Active owners updated after the call, please call active() before calling spend.");
    
    return true;
  }
  
  // Confirm the addresses as distinct owners of this contract.
  function _distinctOwners(address[] addrs) private view returns (bool) {
    if (addrs.length > owners.length) {
        return false;
    }
    for (uint i = 0; i < addrs.length; i++) {
        //> 0 means one of the owner
        if (ownerBlockMap[addrs[i]] == 0) {
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
  
  //update the active block number for those owners
  function _updateActiveBlockNumber(address[] addrs) private {
    for (uint i = 0; i < addrs.length; i++) {
        //only update block number for owners
        if (ownerBlockMap[addrs[i]] > 0) {
            ownerBlockMap[addrs[i]] = block.number;
        }
    }
  }
  
}