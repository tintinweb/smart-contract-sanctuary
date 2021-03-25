/**
 *Submitted for verification at Etherscan.io on 2021-03-24
*/

// File: contracts/interface/MarketInterfaces.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

contract ShardsMarketAdminStorage {
    /**
     * @notice Administrator for this contract
     */
    address public admin;
    /**
     * @notice Governance for this contract which has the right to adjust the parameters of market
     */
    address public governance;

    /**
     * @notice Active brains of ShardsMarket
     */
    address public implementation;
}

contract IShardsMarketStorge is ShardsMarketAdminStorage {
    address public shardsFactory;

    address public factory;

    address public router;

    address public dev;

    address public platformFund;

    address public shardsFarm;

    address public buyoutProposals;

    address public regulator;

    address public shardAdditionProposal;

    address public WETH;
    //The totalSupply of shard in the market
    uint256 public totalSupply = 10000000000000000000000;
    //Stake Time limit: 60*60*24*5
    uint256 public deadlineForStake = 432000;
    //Redeem Time limit:60*60*24*7
    uint256 public deadlineForRedeem = 604800;
    //The Proportion of the shardsCreator's shards
    uint256 public shardsCreatorProportion = 5;
    //The Proportion of the platform's shards
    uint256 public platformProportion = 5;
    //The Proportion for dev of the market profit,the rest of profit is given to platformFund
    uint256 public profitProportionForDev = 20;
    //max
    uint256 internal constant max = 100;
    //shardPool count
    uint256 public shardPoolIdCount;
    // all of the shardpoolId
    uint256[] internal allPools;
    // Info of each pool.
    mapping(uint256 => shardPool) public poolInfo;
    //shardPool struct
    struct shardPool {
        address creator; //shard  creator
        ShardsState state; //shard state
        uint256 createTime;
        uint256 deadlineForStake;
        uint256 deadlineForRedeem;
        uint256 balanceOfWantToken; // all the stake amount of the wantToken in this pool
        uint256 minWantTokenAmount; //Minimum subscription required by the creator
        bool isCreatorWithDraw; //Does the creator withdraw wantToken
        address wantToken; // token address Requested by the creator for others to stake
        uint256 openingPrice;
    }
    //shard of each pool
    mapping(uint256 => shard) public shardInfo;
    //shard struct
    struct shard {
        string shardName;
        string shardSymbol;
        address shardToken;
        uint256 totalShardSupply;
        uint256 shardForCreator;
        uint256 shardForPlatform;
        uint256 shardForStakers;
        uint256 burnAmount;
    }
    //user info of each pool
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    struct UserInfo {
        uint256 amount;
        bool isWithdrawShard;
    }

    enum ShardsState {
        Live,
        Listed,
        ApplyForBuyout,
        Buyout,
        SubscriptionFailed,
        Pending,
        AuditFailed,
        ApplyForAddition
    }

    struct Token721 {
        address contractAddress;
        uint256 tokenId;
    }
    struct Token1155 {
        address contractAddress;
        uint256 tokenId;
        uint256 amount;
    }
    //nfts of shard creator stakes in each pool
    mapping(uint256 => Token721[]) internal Token721s;
    mapping(uint256 => Token1155[]) internal Token1155s;
}

abstract contract IShardsMarket is IShardsMarketStorge {
    event ShardCreated(
        uint256 shardPoolId,
        address indexed creator,
        string shardName,
        string shardSymbol,
        uint256 minWantTokenAmount,
        uint256 createTime,
        uint256 totalSupply,
        address wantToken
    );
    event Stake(address indexed sender, uint256 shardPoolId, uint256 amount);
    event Redeem(address indexed sender, uint256 shardPoolId, uint256 amount);
    event SettleSuccess(
        uint256 indexed shardPoolId,
        uint256 platformAmount,
        uint256 shardForStakers,
        uint256 balanceOfWantToken,
        uint256 fee,
        address shardToken
    );
    event SettleFail(uint256 indexed shardPoolId);
    event ApplyForBuyout(
        address indexed sender,
        uint256 indexed proposalId,
        uint256 indexed _shardPoolId,
        uint256 shardAmount,
        uint256 wantTokenAmount,
        uint256 voteDeadline,
        uint256 buyoutTimes,
        uint256 price,
        uint256 blockHeight
    );
    event Vote(
        address indexed sender,
        uint256 indexed proposalId,
        uint256 indexed _shardPoolId,
        bool isAgree,
        uint256 voteAmount
    );
    event VoteResultConfirm(
        uint256 indexed proposalId,
        uint256 indexed _shardPoolId,
        bool isPassed
    );

    // user operation
    function createShard(
        Token721[] calldata Token721s,
        Token1155[] calldata Token1155s,
        string memory shardName,
        string memory shardSymbol,
        uint256 minWantTokenAmount,
        address wantToken
    ) external virtual returns (uint256 shardPoolId);

    function stakeETH(uint256 _shardPoolId) external payable virtual;

    function stake(uint256 _shardPoolId, uint256 amount) external virtual;

    function redeem(uint256 _shardPoolId, uint256 amount) external virtual;

    function redeemETH(uint256 _shardPoolId, uint256 amount) external virtual;

    function settle(uint256 _shardPoolId) external virtual;

    function redeemInSubscriptionFailed(uint256 _shardPoolId) external virtual;

    function usersWithdrawShardToken(uint256 _shardPoolId) external virtual;

    function creatorWithdrawWantToken(uint256 _shardPoolId) external virtual;

    function applyForBuyout(uint256 _shardPoolId, uint256 wantTokenAmount)
        external
        virtual
        returns (uint256 proposalId);

    function applyForBuyoutETH(uint256 _shardPoolId)
        external
        payable
        virtual
        returns (uint256 proposalId);

    function vote(uint256 _shardPoolId, bool isAgree) external virtual;

    function voteResultConfirm(uint256 _shardPoolId)
        external
        virtual
        returns (bool result);

    function exchangeForWantToken(uint256 _shardPoolId, uint256 shardAmount)
        external
        virtual
        returns (uint256 wantTokenAmount);

    function redeemForBuyoutFailed(uint256 _proposalId)
        external
        virtual
        returns (uint256 shardTokenAmount, uint256 wantTokenAmount);

    //governance operation
    function setShardsCreatorProportion(uint256 _shardsCreatorProportion)
        external
        virtual;

    function setPlatformProportion(uint256 _platformProportion)
        external
        virtual;

    function setTotalSupply(uint256 _totalSupply) external virtual;

    function setDeadlineForRedeem(uint256 _deadlineForRedeem) external virtual;

    function setDeadlineForStake(uint256 _deadlineForStake) external virtual;

    function setProfitProportionForDev(uint256 _profitProportionForDev)
        external
        virtual;

    function setShardsFarm(address _shardsFarm) external virtual;

    function setRegulator(address _regulator) external virtual;

    function setFactory(address _factory) external virtual;

    function setShardsFactory(address _shardsFactory) external virtual;

    function setRouter(address _router) external virtual;

    //admin operation
    function setPlatformFund(address _platformFund) external virtual;

    function setDev(address _dev) external virtual;

    //function shardAudit(uint256 _shardPoolId, bool isPassed) external virtual;

    //view function
    function getPrice(uint256 _shardPoolId)
        public
        view
        virtual
        returns (uint256 currentPrice);

    function getAllPools()
        external
        view
        virtual
        returns (uint256[] memory _pools);

    function getTokens(uint256 shardPoolId)
        external
        view
        virtual
        returns (Token721[] memory _token721s, Token1155[] memory _token1155s);
}

// File: contracts/ShardsMarketDelegator.sol

pragma solidity 0.6.12;


contract ShardsMarketDelegator is IShardsMarketStorge {
    /**
     * @notice Emitted when pendingComptrollerImplementation is accepted, which means comptroller implementation is updated
     */
    event NewImplementation(
        address oldImplementation,
        address newImplementation
    );

    event NewAdmin(address oldAdmin, address newAdmin);
    event NewGovernance(address oldGovernance, address newGovernance);

    constructor(
        address _WETH,
        address _factory,
        address _governance,
        address _router,
        address _dev,
        address _platformFund,
        address _shardsFactory,
        address _regulator,
        address _buyoutProposals,
        address implementation_
    ) public {
        admin = msg.sender;
        governance = msg.sender;
        _setImplementation(implementation_);
        delegateTo(
            implementation_,
            abi.encodeWithSignature(
                "initialize(address,address,address,address,address,address,address,address,address)",
                _WETH,
                _factory,
                _governance,
                _router,
                _dev,
                _platformFund,
                _shardsFactory,
                _regulator,
                _buyoutProposals
            )
        );
    }

    function _setImplementation(address implementation_) public {
        require(
            msg.sender == governance,
            "_setImplementation: Caller must be governance"
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

    function _setGovernance(address newGovernance) public {
        require(msg.sender == governance, "UNAUTHORIZED");

        address oldGovernance = governance;

        governance = newGovernance;

        emit NewGovernance(oldGovernance, newGovernance);
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