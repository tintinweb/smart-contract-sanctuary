// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

interface ERC20 {
    function transfer(address, uint256) external returns (bool);
    function transferFrom(address, address, uint256) external returns (bool);
}

/// All the errors which may be encountered on the bond manager
library Errors {
    string constant ERC20_ERR = "BondManager: Could not post bond";
    string constant ALREADY_FINALIZED = "BondManager: Fraud proof for this pre-state root has already been finalized";
    string constant SLASHED = "BondManager: Cannot finalize withdrawal, you probably got slashed";
    string constant WRONG_STATE = "BondManager: Wrong bond state for proposer";
    string constant CANNOT_CLAIM = "BondManager: Cannot claim yet. Dispute must be finalized first";

    string constant WITHDRAWAL_PENDING = "BondManager: Withdrawal already pending";
    string constant TOO_EARLY = "BondManager: Too early to finalize your withdrawal";

    string constant ONLY_TRANSITIONER = "BondManager: Only the transitioner for this pre-state root may call this function";
    string constant ONLY_FRAUD_VERIFIER = "BondManager: Only the fraud verifier may call this function";
    string constant ONLY_STATE_COMMITMENT_CHAIN = "BondManager: Only the state commitment chain may call this function";
    string constant WAIT_FOR_DISPUTES = "BondManager: Wait for other potential disputes";
}

/**
 * @title iOVM_BondManager
 */
interface iOVM_BondManager {

    /*******************
     * Data Structures *
     *******************/

    /// The lifecycle of a proposer's bond
    enum State {
        // Before depositing or after getting slashed, a user is uncollateralized
        NOT_COLLATERALIZED,
        // After depositing, a user is collateralized
        COLLATERALIZED,
        // After a user has initiated a withdrawal
        WITHDRAWING
    }

    /// A bond posted by a proposer
    struct Bond {
        // The user's state
        State state;
        // The timestamp at which a proposer issued their withdrawal request
        uint32 withdrawalTimestamp;
        // The time when the first disputed was initiated for this bond
        uint256 firstDisputeAt;
        // The earliest observed state root for this bond which has had fraud
        bytes32 earliestDisputedStateRoot;
        // The state root's timestamp
        uint256 earliestTimestamp;
    }

    // Per pre-state root, store the number of state provisions that were made
    // and how many of these calls were made by each user. Payouts will then be
    // claimed by users proportionally for that dispute.
    struct Rewards {
        // Flag to check if rewards for a fraud proof are claimable
        bool canClaim;
        // Total number of `recordGasSpent` calls made
        uint256 total;
        // The gas spent by each user to provide witness data. The sum of all
        // values inside this map MUST be equal to the value of `total`
        mapping(address => uint256) gasSpent;
    }


    /********************
     * Public Functions *
     ********************/

    function recordGasSpent(
        bytes32 _preStateRoot,
        bytes32 _txHash,
        address _who,
        uint256 _gasSpent
    ) external;

    function finalize(
        bytes32 _preStateRoot,
        address _publisher,
        uint256 _timestamp
    ) external;

    function deposit() external;

    function startWithdrawal() external;

    function finalizeWithdrawal() external;

    function claim(
        address _who
    ) external;

    function isCollateralized(
        address _who
    ) external view returns (bool);

    function getGasSpent(
        bytes32 _preStateRoot,
        address _who
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* External Imports */
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Lib_AddressManager
 */
contract Lib_AddressManager is Ownable {

    /**********
     * Events *
     **********/

    event AddressSet(
        string _name,
        address _newAddress
    );


    /*************
     * Variables *
     *************/

    mapping (bytes32 => address) private addresses;


    /********************
     * Public Functions *
     ********************/

    /**
     * Changes the address associated with a particular name.
     * @param _name String name to associate an address with.
     * @param _address Address to associate with the name.
     */
    function setAddress(
        string memory _name,
        address _address
    )
        external
        onlyOwner
    {
        addresses[_getNameHash(_name)] = _address;

        emit AddressSet(
            _name,
            _address
        );
    }

    /**
     * Retrieves the address associated with a given name.
     * @param _name Name to retrieve an address for.
     * @return Address associated with the given name.
     */
    function getAddress(
        string memory _name
    )
        external
        view
        returns (
            address
        )
    {
        return addresses[_getNameHash(_name)];
    }


    /**********************
     * Internal Functions *
     **********************/

    /**
     * Computes the hash of a name.
     * @param _name Name to compute a hash for.
     * @return Hash of the given name.
     */
    function _getNameHash(
        string memory _name
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        return keccak256(abi.encodePacked(_name));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Library Imports */
import { Lib_AddressManager } from "./Lib_AddressManager.sol";

/**
 * @title Lib_AddressResolver
 */
abstract contract Lib_AddressResolver {

    /*************
     * Variables *
     *************/

    Lib_AddressManager public libAddressManager;


    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Lib_AddressManager.
     */
    constructor(
        address _libAddressManager
    ) {
        libAddressManager = Lib_AddressManager(_libAddressManager);
    }


    /********************
     * Public Functions *
     ********************/

    /**
     * Resolves the address associated with a given name.
     * @param _name Name to resolve an address for.
     * @return Address associated with the given name.
     */
    function resolve(
        string memory _name
    )
        public
        view
        returns (
            address
        )
    {
        return libAddressManager.getAddress(_name);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/* Interface Imports */
import { iOVM_BondManager } from "../../iOVM/verification/iOVM_BondManager.sol";

/* Contract Imports */
import { Lib_AddressResolver } from "../../libraries/resolver/Lib_AddressResolver.sol";

/**
 * @title mockOVM_BondManager
 */
contract mockOVM_BondManager is iOVM_BondManager, Lib_AddressResolver {
    constructor(
        address _libAddressManager
    )
        Lib_AddressResolver(_libAddressManager)
    {}

    function recordGasSpent(
        bytes32 _preStateRoot,
        bytes32 _txHash,
        address _who,
        uint256 _gasSpent
    )
        override
        public
    {}

    function finalize(
        bytes32 _preStateRoot,
        address _publisher,
        uint256 _timestamp
    )
        override
        public
    {}

    function deposit()
        override
        public
    {}

    function startWithdrawal()
        override
        public
    {}

    function finalizeWithdrawal()
        override
        public
    {}

    function claim(
        address _who
    )
        override
        public
    {}

    function isCollateralized(
        address _who
    )
        override
        public
        view
        returns (
            bool
        )
    {
        // Only authenticate sequencer to submit state root batches.
        return _who == resolve("OVM_Proposer");
    }

    function getGasSpent(
        bytes32, // _preStateRoot,
        address // _who
    )
        override
        public
        pure
        returns (
            uint256
        )
    {
        return 0;
    }
}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}