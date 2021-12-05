// SPDX-License-Identifier: MIT

// https://github.com/paxosglobal/simple-multisig

pragma solidity ^0.8.4;

contract MultiSig {

  // EIP712 Precomputed hashes:
  // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
  bytes32 private constant EIP712DOMAINTYPE_HASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

  // keccak256("MultiSig")
  bytes32 private constant NAME_HASH = 0xd90d81238fec68b58412fea0ed72a6621ecd31c74022809053834bb75fa1820f;

  // keccak256("1")
  bytes32 private constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

  // keccak256("MultiSigTransaction(address destination,uint256 value,bytes data,uint256 nonce,address executor,uint256 gasLimit)")
  bytes32 private constant TXTYPE_HASH = 0x3ee892349ae4bbe61dce18f95115b5dc02daf49204cc602458cd4c1f540d56d7;

  uint public nonce;                 // mutable state
  uint public threshold;             // mutable state
  mapping (address => bool) private isOwner; // mutable state
  address[] public ownersArr;        // mutable state

  // solhint-disable-next-line var-name-mixedcase
  bytes32 private immutable DOMAIN_SEPARATOR;          // hash for EIP712, computed from contract address

  function owners() external view returns (address[] memory) {
    return ownersArr;
  }

  // Note that owners_ must be strictly increasing, in order to prevent duplicates
  function setOwners_(uint threshold_, address[] memory owners_) private {
    require(owners_.length <= 20 && threshold_ <= owners_.length && threshold_ > 0, "Invalid threshold");

    // remove old owners from map
    for (uint i = 0; i < ownersArr.length; i++) {
      isOwner[ownersArr[i]] = false;
    }

    // add new owners to map
    address lastAdd = address(0);
    for (uint i = 0; i < owners_.length; i++) {
      require(owners_[i] > lastAdd, "Addresses added must be sequential");
      isOwner[owners_[i]] = true;
      lastAdd = owners_[i];
    }

    // set owners array and threshold
    ownersArr = owners_;
    threshold = threshold_;
  }

  constructor(uint threshold_, address[] memory owners_) {
    setOwners_(threshold_, owners_);

    DOMAIN_SEPARATOR = keccak256(abi.encode(EIP712DOMAINTYPE_HASH,
                                            NAME_HASH,
                                            VERSION_HASH,
                                            block.chainid,
                                            this));
  }

  // Requires a quorum of owners to call from this contract using execute
  function setOwners(uint threshold_, address[] memory owners_) external {
    require(msg.sender == address(this), "Can only be called by multisig");
    setOwners_(threshold_, owners_);
  }

  // Note that address recovered from signatures must be strictly increasing, in order to prevent duplicates
  function execute(
      uint8[] memory sigV,
      bytes32[] memory sigR,
      bytes32[] memory sigS,
      address destination,
      uint256 value,
      bytes memory data,
      address executor,
      uint256 gasLimit
  ) external {
    require(sigR.length == threshold, "Threshold requirement not met");
    require(sigR.length == sigS.length && sigR.length == sigV.length, "Sig length mismatch");
    require(executor == msg.sender || executor == address(0), "Invalid executor address");

    // EIP712 scheme: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md
    bytes32 txInputHash = keccak256(abi.encode(TXTYPE_HASH, destination, value, keccak256(data), nonce, executor, gasLimit));
    bytes32 totalHash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, txInputHash));

    address lastAdd = address(0); // cannot have address(0) as an owner
    for (uint i = 0; i < threshold; i++) {
      address recovered = ecrecover(totalHash, sigV[i], sigR[i], sigS[i]);
      require(recovered > lastAdd && isOwner[recovered], "Invalid recovered address");
      lastAdd = recovered;
    }

    // If we make it here all signatures are accounted for.
    nonce = nonce + 1;
    bool success = false;
    // solhint-disable-next-line avoid-low-level-calls
    (success,) = destination.call{value: value, gas: gasLimit}(data);
    // https://ethereum.stackexchange.com/a/86983/75264
    // https://ethereum.stackexchange.com/a/111143/75264
    if (success == false) {
      // solhint-disable-next-line no-inline-assembly
      assembly {
        let ptr := mload(0x40)
        let size := returndatasize()
        returndatacopy(ptr, 0, size)
        revert(ptr, size)
      }
    }
  }

  receive() external payable {}
}