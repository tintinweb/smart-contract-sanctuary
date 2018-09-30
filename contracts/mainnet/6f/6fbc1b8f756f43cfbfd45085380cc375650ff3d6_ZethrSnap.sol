/*
  Zethr | https://zethr.io
  (c) Copyright 2018 | All Rights Reserved
  This smart contract was developed by the Zethr Dev Team and its source code remains property of the Zethr Project.
*/

pragma solidity ^0.4.24;

// File: contracts/Libraries/SafeMath.sol

library SafeMath {
  function mul(uint a, uint b) internal pure returns (uint) {
    if (a == 0) {
      return 0;
    }
    uint c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint a, uint b) internal pure returns (uint) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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

// File: contracts/Bankroll/ZethrSnap.sol

contract ZethrInterface {
  function transfer(address _from, uint _amount) public;

  function myFrontEndTokens() public view returns (uint);
}

contract ZethrMultiSigWalletInterface {
  mapping(address => bool) public isOwner;
}

contract ZethrSnap {

  struct SnapEntry {
    uint blockNumber;
    uint profit;
  }

  struct Sig {
    bytes32 r;
    bytes32 s;
    uint8 v;
  }

  // Reference to the Zethr multi sig wallet for authentication
  ZethrMultiSigWalletInterface public multiSigWallet;

  // Reference to Zethr token contract
  ZethrInterface zethr;

  // The server&#39;s public address (used to confirm valid claims)
  address signer;

  // Mapping of user address => snap.id => claimStatus
  mapping(address => mapping(uint => bool)) public claimedMap;

  // Array of all snaps
  SnapEntry[] public snaps;

  // Used to pause the contract in an emergency
  bool public paused;

  // The number of tokens in this contract allocated to snaps
  uint public allocatedTokens;

  constructor(address _multiSigWalletAddress, address _zethrAddress, address _signer)
  public
  {
    multiSigWallet = ZethrMultiSigWalletInterface(_multiSigWalletAddress);
    zethr = ZethrInterface(_zethrAddress);
    signer = _signer;
    paused = false;
  }

  /**
   * @dev Needs to accept ETH dividends from Zethr token contract
   */
  function()
  public payable
  {}

  /**
   * @dev Paused claims in an emergency
   * @param _paused The new pause state
   */
  function ownerSetPaused(bool _paused)
  public
  ownerOnly
  {
    paused = _paused;
  }

  /**
   * @dev Updates the multi sig wallet reference
   * @param _multiSigWalletAddress The new multi sig wallet address
   */
  function walletSetWallet(address _multiSigWalletAddress)
  public
  walletOnly
  {
    multiSigWallet = ZethrMultiSigWalletInterface(_multiSigWalletAddress);
  }

  /**
   * @dev Withdraws dividends to multi sig wallet
   */
  function withdraw()
  public
  {
    (address(multiSigWallet)).transfer(address(this).balance);
  }

  /**
   * @dev Updates the signer address
   */
  function walletSetSigner(address _signer)
  public walletOnly
  {
    signer = _signer;
  }

  /**
   * @dev Withdraws tokens (for migrating to a new contract)
   */
  function walletWithdrawTokens(uint _amount)
  public walletOnly
  {
    zethr.transfer(address(multiSigWallet), _amount);
  }

  /**
   * @return Total number of snaps stored
   */
  function getSnapsLength()
  public view
  returns (uint)
  {
    return snaps.length;
  }

  /**
   * @dev Creates a new snap
   * @param _blockNumber The block number the server should use to calculate ownership
   * @param _profitToShare The amount of profit to divide between all holders
   */
  function walletCreateSnap(uint _blockNumber, uint _profitToShare)
  public
  walletOnly
  {
    uint index = snaps.length;
    snaps.length++;

    snaps[index].blockNumber = _blockNumber;
    snaps[index].profit = _profitToShare;

    // Make sure we have enough free tokens to create this snap
    uint balance = zethr.myFrontEndTokens();
    balance = balance - allocatedTokens;
    require(balance >= _profitToShare);

    // Update allocation token count
    allocatedTokens = allocatedTokens + _profitToShare;
  }

  /**
   * @dev Retrieves snap details
   * @param _snapId The ID of the snap to get details of
   */
  function getSnap(uint _snapId)
  public view
  returns (uint blockNumber, uint profit, bool claimed)
  {
    SnapEntry storage entry = snaps[_snapId];
    return (entry.blockNumber, entry.profit, claimedMap[msg.sender][_snapId]);
  }

  /**
   * @dev Process a claim
   * @param _snapId ID of the snap this claim is for
   * @param _payTo Address to send the proceeds to
   * @param _amount The amount of profit claiming
   * @param _signatureBytes Signature of the server approving this claim
   */
  function claim(uint _snapId, address _payTo, uint _amount, bytes _signatureBytes)
  public
  {
    // Check pause state
    require(!paused);

    // Prevent multiple calls
    require(claimedMap[msg.sender][_snapId] == false);
    claimedMap[msg.sender][_snapId] = true;

    // Confirm that the server has approved this claim
    // Note: the player cannot modify the _amount arbitrarily because it will invalidate the signature
    Sig memory sig = toSig(_signatureBytes);
    bytes32 hash = keccak256(abi.encodePacked("SNAP", _snapId, msg.sender, _amount));
    address recoveredSigner = ecrecover(hash, sig.v, sig.r, sig.s);
    require(signer == recoveredSigner);

    // Reduce allocated tokens by claim amount
    require(_amount <= allocatedTokens);
    allocatedTokens = allocatedTokens - _amount;

    // Send tokens
    zethr.transfer(_payTo, _amount);
  }

  /**
   * @dev The contract accepts ZTH tokens in order to pay out claims
   */
  function tokenFallback(address /*_from*/, uint /*_amountOfTokens*/, bytes /*_data*/)
  public view
  returns (bool)
  {
    require(msg.sender == address(zethr), "Tokens must be ZTH");
    return true;
  }

  /**
   * @dev Extract a Sig struct from given bytes
   */
  function toSig(bytes b)
  internal pure
  returns (Sig memory sig)
  {
    sig.r = bytes32(toUint(b, 0));
    sig.s = bytes32(toUint(b, 32));
    sig.v = uint8(b[64]);
  }

  /**
   * @dev Extracts a uint from bytes
   */
  function toUint(bytes _bytes, uint _start)
  internal pure
  returns (uint256)
  {
    require(_bytes.length >= (_start + 32));
    uint256 tempUint;

    assembly {
      tempUint := mload(add(add(_bytes, 0x20), _start))
    }

    return tempUint;
  }

  // Only the multi sig wallet can call this method
  modifier walletOnly()
  {
    require(msg.sender == address(multiSigWallet));
    _;
  }

  // Only an owner can call this method (multi sig is always an owner)
  modifier ownerOnly()
  {
    require(msg.sender == address(multiSigWallet) || multiSigWallet.isOwner(msg.sender));
    _;
  }
}