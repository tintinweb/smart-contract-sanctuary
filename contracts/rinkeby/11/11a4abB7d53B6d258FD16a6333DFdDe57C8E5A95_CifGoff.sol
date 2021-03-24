/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;



// File: CifGoff.sol

/// @title CIF E-Sports Trophy Contract
/// @author Matthias Nadler, University of Basel
/// @notice Implements flexible quorum off chain multisig transactions
///         according to EIP712.
///         Based on https://github.com/christianlundkvist/simple-multisig
contract CifGoff {

    //---- EIP712 Precomputed hashes.

    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)")
    bytes32 private constant EIP712DOMAINTYPE_HASH = 0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472;

    // keccak256("Cif Goffernance")
    bytes32 private constant NAME_HASH = 0xf3b29457cc38aeccbb2a28fa197b6f9932a3834d7ed979ac7af4a185eaca5346;

    // keccak256("1")
    bytes32 private constant VERSION_HASH = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;

    // keccak256("MultiSigTransaction(address destination,uint256 value,bytes data,uint256 nonce,address executor,uint256 gasLimit)")
    bytes32 private constant TXTYPE_HASH = 0x3ee892349ae4bbe61dce18f95115b5dc02daf49204cc602458cd4c1f540d56d7;

    bytes32 private constant SALT = 0xc1f00000000000000000c1f000000000000000000c1f00000000000000000c1f;

    // Hash for EIP712, computed in constructor from contract address
    bytes32 public DOMAIN_SEPARATOR;

    //---- State variables
    uint256 public nonce;
    uint256 public quorum;
    uint256 public threshold;
    mapping(address => bool) public isOwner;
    address[] public ownersArr;

    //---- Events
    event Execution();
    event OwnerAddition(address indexed newOwner);
    event OwnerRemoval(address indexed oldOwner);
    event QuorumChange(uint256 indexed oldQuorum, uint256 indexed newQuorum);

    //---- Constructor

    /// @dev Note that owners_ must be strictly increasing, in order to prevent duplicates
    constructor(uint256 quorum_, address[] memory owners_, uint256 chainId) {
        require(owners_.length <= 10, "Maximum of 10 owners");
        require(quorum <= 100, "Quorum must be between 0 and 100");
        quorum = quorum_;

        address lastAdd = address(0);
        for (uint256 i = 0; i < owners_.length; i++) {
            require(owners_[i] > lastAdd, "Gov: owners not in increasing order");
            isOwner[owners_[i]] = true;
            lastAdd = owners_[i];
        }
        ownersArr = owners_;
        _updateThreshold();

        DOMAIN_SEPARATOR = keccak256(abi.encode(
                EIP712DOMAINTYPE_HASH,
                NAME_HASH,
                VERSION_HASH,
                chainId,
                address(this),
                SALT
            ));
    }

    //--- Contract Functions

    /// @dev Note that address recovered from signatures must be strictly increasing, in order to prevent duplicates
    function execute(
        uint8[] memory sigV,
        bytes32[] memory sigR,
        bytes32[] memory sigS,
        address destination,
        uint256 value,
        bytes memory data,
        address executor,
        uint256 gasLimit
    ) public returns (bytes memory){
        require(sigR.length >= threshold, "Gov: not enough signatures");
        require(sigR.length == sigS.length && sigR.length == sigV.length, "Gov: incomplete signatures");
        require(executor == msg.sender || executor == address(0), "Gov: invalid executor");

        // EIP712 scheme: https://github.com/ethereum/EIPs/blob/master/EIPS/eip-712.md
        bytes32 txInputHash = keccak256(abi.encode(TXTYPE_HASH, destination, value, keccak256(data), nonce, executor, gasLimit));
        bytes32 totalHash = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, txInputHash));

        address lastAdd = address(0); // cannot have address(0) as an owner
        for (uint i = 0; i < threshold; i++) {
            address recovered = ecrecover(totalHash, sigV[i], sigR[i], sigS[i]);
            require(recovered > lastAdd && isOwner[recovered], "Gov: invalid signature");
            lastAdd = recovered;
        }

        // If we make it here all signatures are accounted for.
        nonce = nonce + 1;
        (bool success, bytes memory returnData) = destination.call{value : value, gas : gasLimit}(data);
        if (!success) {
            // Revert with propagated error message
            assembly {
                let ptr := mload(0x40)
                let size := returndatasize()
                returndatacopy(ptr, 0, size)
                revert(ptr, size)
            }
        }
        emit Execution();
        return returnData;
    }

    /// @dev Always rounds up to the next full number of owners
    function _updateThreshold() internal {
        threshold = (ownersArr.length * quorum + 99) / 100;
    }


    function addOwner(address newOwner_) public {
        require(msg.sender == address(this), "Gov: requires multisig tx");
        require(newOwner_ != address(0), "Gov: new owner is the zero address");
        require(!isOwner[newOwner_], "Gov: owner already exists");
        isOwner[newOwner_] = true;
        ownersArr.push(newOwner_);
        _updateThreshold();
        emit OwnerAddition(newOwner_);
    }

    function removeOwner(address oldOwner_) public {
        require(msg.sender == address(this), "Gov: requires multisig tx");
        require(isOwner[oldOwner_], "Gov: owner does not exists");
        isOwner[oldOwner_] = false;
        for (uint256 i = 0; i < ownersArr.length - 1; i++) {
            if (ownersArr[i] == oldOwner_) {
                ownersArr[i] = ownersArr[ownersArr.length - 1];
                break;
            }
        }
        ownersArr.pop();
        _updateThreshold();
        emit OwnerRemoval(oldOwner_);
    }

    function changeQuorum(uint256 newQuorum_) public {
        require(msg.sender == address(this), "Gov: requires multisig tx");
        require(newQuorum_ <= 100, "Gov: new quorum must be between 0 and 100");
        uint256 oldQuorum = quorum;
        quorum = newQuorum_;
        _updateThreshold();
        emit QuorumChange(oldQuorum, newQuorum_);
    }

    receive() external payable {}

}