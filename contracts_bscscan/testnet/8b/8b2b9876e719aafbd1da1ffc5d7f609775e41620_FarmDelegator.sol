/**
 *Submitted for verification at BscScan.com on 2021-11-11
*/

// File: contracts/FarmStorage.sol

pragma solidity 0.6.12;

contract FarmAdminStorage {
    address public admin;

    address public implementation;
}

contract FarmStorageV1 is FarmAdminStorage {
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardDistributeTokenDebt; //user Debt for 2 month（continuous Mining）
        uint256 rewardLockDistributeTokenDebt; //user Debt for 10 mon th(concentrated Mining)
        uint256 rewardUsdtDebt; //user Debt for 10 mon th(concentrated Mining)
        uint256 lockPending;
        uint256 lastRewardBlock;

        bool flag; // lp token refund flag,gToken convert flag
        uint256 claimedAmount;
    }

    // Info of each pool.
    struct PoolInfo {
        address lpToken; // Address of LP token contract.
        uint256 allocPoint; // How many allocation points assigned to this pool. MDXs to distribute per block.
        uint256 lastRewardBlock; // Last block number that distributeTokens distribution occurs.
        uint256 accDistributeTokenPerShare; //PerShare for continuous Mining
        uint256 accLockDistributeTokenPerShare; //PerShare for concentrated Mining
        uint256 accUsdtPerShare;
        uint256 totalAmount; // Total amount of current pool deposit.
        uint256 lastAccLockDistributeTokenPerShare; //last year PerShare for concentrated Mining (corculate pengding distributeToken)

        uint256 convertRate; // The gToken convet rate.
        uint256 totalOrigDep; // The total amount deposit before migrage.
        bool hasMigrate; // Identification to determine whether have migrated.

    }

    mapping(uint256 => mapping(address => uint256)) public redepositAmount;
    uint256 public startBlockOfDistributeToken;

    address public distributeToken;

    uint256 public distributeTokenPerBlockConcentratedMining; // concentrated Mining per block distributeToken
    uint256 public distributeTokenPerBlockContinuousMining; // continuous Mining per block distributeToken

    address public usdt;
    uint256 public usdtPerBlock;
    uint256 public usdtStartBlock;
    uint256 public usdtEndBlock;
    uint256 public cycle;
    // Info of each pool.
    PoolInfo[] public poolInfo;
    // Info of each user that stakes LP tokens.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocPoint = 0;
    // The block number when distributeToken mining starts.

    // How many blocks are halved
    uint256 public halvingPeriod0;
    uint256 public halvingPeriod1;

    mapping(address => uint256) public pidOfLP;

    address public router;
    address public factory;
    address public farmTwoPool;
    address public weth;
//    The address of migrator
    address public migrator;
    uint256 constant defaultScale = 1e18;

//  reward
    uint256 public totalReward;
    uint256 public issuedReward;
    uint256 public endBlock;

    address public tool;
    address public owner;
}

// File: contracts/FarmDelegator.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;


contract FarmDelegator is FarmStorageV1 {
    /**
     * @notice Emitted when pendingComptrollerImplementation is accepted, which means comptroller implementation is updated
     */
    event NewImplementation(
        address oldImplementation,
        address newImplementation
    );

    event NewAdmin(address oldAdmin, address newAdmin);

    constructor(
        address _distributeToken,
        address _usdt,
        uint256 _block0,
        uint256 _block1,
        uint256 _distributeTokenPerBlock0,
        uint256 _distributeTokenPerBlock1,
        uint256 _startBlock,
        uint256 _cycle,
        uint256 _totalReward,
        address _implementation
    ) public {
        admin = msg.sender;

        delegateTo(
            _implementation,
            abi.encodeWithSignature(
                "initialize(address,address,uint256,uint256,uint256,uint256,uint256,uint256,uint256)",
                _distributeToken,
                _usdt,
                _block0,
                _block1,
                _distributeTokenPerBlock0,
                _distributeTokenPerBlock1,
                _startBlock,
                _cycle,
                _totalReward
            )
        );
        _setImplementation(_implementation);
    }

    function _setImplementation(address implementation_) public {
        require(
            msg.sender == admin,
            "_setImplementation: Caller must be admin"
        );

        address oldImplementation = implementation;
        implementation = implementation_;

        emit NewImplementation(oldImplementation, implementation);
    }

    function _setAdmin(address newAdmin) public {
        require(msg.sender == admin, "UNAUTHORIZED");

        address oldAdmin = admin;

        admin = newAdmin;

        emit NewAdmin(oldAdmin, newAdmin);
    }

    function delegateTo(address callee, bytes memory data)
        internal
        returns (bytes memory)
    {
        (bool success, bytes memory returnData) = callee.delegatecall(data);
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return returnData;
    }

    receive() external payable {}

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
    //  */
    fallback() external payable {
        // delegate all other functions to current implementation
        (bool success, ) = implementation.delegatecall(msg.data);
        assembly {
            let free_mem_ptr := mload(0x40)
            returndatacopy(free_mem_ptr, 0, returndatasize())
            switch success
            case 0 {
                revert(free_mem_ptr, returndatasize())
            }
            default {
                return(free_mem_ptr, returndatasize())
            }
        }
    }
}