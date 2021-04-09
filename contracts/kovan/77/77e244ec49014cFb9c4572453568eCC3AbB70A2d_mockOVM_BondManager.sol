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

/* Contract Imports */
import { Ownable } from "./Lib_Ownable.sol";

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

    /*******************************************
     * Contract Variables: Internal Accounting *
     *******************************************/

    mapping (bytes32 => address) private addresses;


    /********************
     * Public Functions *
     ********************/

    function setAddress(
        string memory _name,
        address _address
    )
        public
        onlyOwner
    {
        emit AddressSet(_name, _address);
        addresses[_getNameHash(_name)] = _address;
    }

    function getAddress(
        string memory _name
    )
        public
        view
        returns (address)
    {
        return addresses[_getNameHash(_name)];
    }


    /**********************
     * Internal Functions *
     **********************/

    function _getNameHash(
        string memory _name
    )
        internal
        pure
        returns (
            bytes32 _hash
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

    /*******************************************
     * Contract Variables: Contract References *
     *******************************************/

    Lib_AddressManager public libAddressManager;


    /***************
     * Constructor *
     ***************/

    /**
     * @param _libAddressManager Address of the Lib_AddressManager.
     */
    constructor(
        address _libAddressManager
    )  {
        libAddressManager = Lib_AddressManager(_libAddressManager);
    }


    /********************
     * Public Functions *
     ********************/

    function resolve(
        string memory _name
    )
        public
        view
        returns (
            address _contract
        )
    {
        return libAddressManager.getAddress(_name);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title Ownable
 * @dev Adapted from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol
 */
abstract contract Ownable {

    /*************
     * Variables *
     *************/

    address public owner;


    /**********
     * Events *
     **********/

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );


    /***************
     * Constructor *
     ***************/

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }


    /**********************
     * Function Modifiers *
     **********************/

    modifier onlyOwner() {
        require(
            owner == msg.sender,
            "Ownable: caller is not the owner"
        );
        _;
    }


    /********************
     * Public Functions *
     ********************/

    function renounceOwnership()
        public
        virtual
        onlyOwner
    {
        emit OwnershipTransferred(owner, address(0));
        owner = address(0);
    }

    function transferOwnership(address _newOwner)
        public
        virtual
        onlyOwner
    {
        require(
            _newOwner != address(0),
            "Ownable: new owner cannot be the zero address"
        );

        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
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
    "bytecodeHash": "none",
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