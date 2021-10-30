/**
 *Submitted for verification at Etherscan.io on 2021-10-29
*/

// File: contracts/interfaces/IGan.sol

pragma solidity >=0.6.0;

interface IGan {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function burn(uint256 value) external;

    function mint(address to, uint256 value) external;

    function initialize(string memory _name, string memory _symbol) external;

    function getPriorVotes(address account, uint256 blockNumber)
        external
        view
        returns (uint256);
}

// File: contracts/FarmStorage.sol

pragma solidity ^0.6.0;

contract FarmAdminStorage {
    address public admin;

    address public implementation;
}

contract FarmStorageV1 is FarmAdminStorage {
    // Info of each user.
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has provided.
        uint256 rewardGanDebt; //user Debt for 2 month（continuous Mining）
        uint256 rewardLockGanDebt; //user Debt for 10 mon th(concentrated Mining)
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
        uint256 lastRewardBlock; // Last block number that Gans distribution occurs.
        uint256 accGanPerShare; //PerShare for continuous Mining
        uint256 accLockGanPerShare; //PerShare for concentrated Mining
        uint256 accUsdtPerShare;
        uint256 totalAmount; // Total amount of current pool deposit.
        uint256 lastAccLockGanPerShare; //last year PerShare for concentrated Mining (corculate pengding gan)

        uint256 convertRate; // The gToken convet rate.
        uint256 totalOrigDep; // The total amount deposit before migrage.
        bool hasMigrate; // Identification to determine whether have migrated.

    }

    mapping(uint256 => mapping(address => uint256)) public redepositAmount;
    uint256 public startBlockOfGan;

    address public gandalf;

    uint256 public ganPerBlockConcentratedMining; // concentrated Mining per block gan
    uint256 public ganPerBlockContinuousMining; // continuous Mining per block gan

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
    // The block number when gandalf mining starts.

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
    bool public switchBar;

//  reward 
    uint256 public totalReward;
    uint256 public issuedReward;
    uint256 public endBlock;
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
        address _Gan,
        address _usdt,
        uint256 _block0,
        uint256 _block1,
        uint256 _ganPerBlock0,
        uint256 _ganPerBlock1,
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
                _Gan,
                _usdt,
                _block0,
                _block1,
                _ganPerBlock0,
                _ganPerBlock1,
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