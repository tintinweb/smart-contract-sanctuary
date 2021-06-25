/**
 *Submitted for verification at Etherscan.io on 2021-06-24
*/

pragma solidity ^0.4.24;

contract SimpleMultiSig {

// EIP712 Precomputed hashes:
// keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)")
bytes32 constant EIP712DOMAINTYPE_HASH = 0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472;

// keccak256("Simple MultiSig")
bytes32 constant NAME_HASH = 0xb7a0bfa1b79f2443f4d73ebb9259cddbcd510b18be6fc4da7d1aa7b1786e73e6;

// keccak256("1")
bytes32 constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

// keccak256("MultiSigTransaction(address destination,uint256 value,bytes data,uint256 nonce,address executor,uint256 gasLimit)")
bytes32 constant TXTYPE_HASH = 0x3ee892349ae4bbe61dce18f95115b5dc02daf49204cc602458cd4c1f540d56d7;

bytes32 constant SALT = 0x251543af6a222378665a76fe38dbceae4871a070b7fdaf5c6c30cf758dc33cc0;

  uint public nonce;                 // (only) mutable state
  uint public threshold;             // immutable state
  mapping (address => bool) isOwner; // immutable state
  address[] public ownersArr;        // immutable state

  bytes32 DOMAIN_SEPARATOR;          // hash for EIP712, computed from contract address

  function owners() public view returns (address[]) {
    return ownersArr;
  }

  // Note that owners_ must be strictly increasing, in order to prevent duplicates
  function setOwners_(uint threshold_, address[] owners_) private {
    require(owners_.length <= 20 && threshold_ <= owners_.length && threshold_ > 0);

    // remove old owners from map
    for (uint i = 0; i < ownersArr.length; i++) {
      isOwner[ownersArr[i]] = false;
    }

    // add new owners to map
    address lastAdd = address(0);
    for (i = 0; i < owners_.length; i++) {
      require(owners_[i] > lastAdd);
      isOwner[owners_[i]] = true;
      lastAdd = owners_[i];
    }

    // set owners array and threshold
    ownersArr = owners_;
    threshold = threshold_;
  }

  constructor(uint threshold_, address[] owners_, uint chainId) public {
    setOwners_(threshold_, owners_);

    DOMAIN_SEPARATOR = keccak256(abi.encode(EIP712DOMAINTYPE_HASH,
                                            NAME_HASH,
                                            VERSION_HASH,
                                            chainId,
                                            this,
                                            SALT));
  }

  // Requires a quorum of owners to call from this contract using execute
  function setOwners(uint threshold_, address[] owners_) external {
    require(msg.sender == address(this));
    setOwners_(threshold_, owners_);
  }

  // Note that address recovered from signatures must be strictly increasing, in order to prevent duplicates
  function execute(uint8[] sigV, bytes32[] sigR, bytes32[] sigS, address destination, uint value, bytes data, address executor, uint gasLimit) public {
    require(sigR.length == threshold);
    require(sigR.length == sigS.length && sigR.length == sigV.length);
    require(executor == msg.sender || executor == address(0));

    // EIP712 scheme: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md
    bytes32 txInputHash = keccak256(abi.encode(TXTYPE_HASH, destination, value, keccak256(data), nonce, executor, gasLimit));
    bytes32 totalHash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, txInputHash));

    address lastAdd = address(0); // cannot have address(0) as an owner
    for (uint i = 0; i < threshold; i++) {
      address recovered = ecrecover(totalHash, sigV[i], sigR[i], sigS[i]);
      require(recovered > lastAdd && isOwner[recovered]);
      lastAdd = recovered;
    }

    // If we make it here all signatures are accounted for.
    // The address.call() syntax is no longer recommended, see:
    // https://github.com/ethereum/solidity/issues/2884
    nonce = nonce + 1;
    bool success = false;
    assembly { success := call(gasLimit, destination, value, add(data, 0x20), mload(data), 0, 0) }
    require(success);
  }

  function () payable external {}
}