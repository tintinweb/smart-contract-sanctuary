/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

// File: contracts/interface/IERC20.sol

pragma solidity >=0.6.0 <0.8.0;

interface IERC20 {
    function symbol() external returns (string memory _symbol);
}

// File: openzeppelin-solidity/contracts/token/ERC721/IERC721Receiver.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// File: contracts/interface/MarketInterfaces.sol

pragma solidity 0.6.12;


contract IShardsMarketStorge {
    address public shardsFactory;
    address public router;
    address public governance;

    address public factory;

    address public dev;

    address public tokenBar;

    address public shardsFarm;

    address public buyoutProposals;

    //The totalSupply of shard in the market
    uint256 public totalSupply = 10000000000000000000000;

    address public WETH;

    //Stake Time limit: 60*60*24*5
    uint256 public deadlineForStake = 432000;
    //Redeem Time limit:60*60*24*7
    uint256 public deadlineForRedeem = 604800;
    //The Proportion of the shardsCreator's shards
    uint256 public shardsCreatorProportion = 5;
    //The Proportion of the platform's shards
    uint256 public platformProportion = 5;

    //The Proportion of shards ownership  to buyout
    uint256 public buyoutProportion = 15;
    //max
    uint256 internal constant max = 100;
    // n times higher than the market price to buyout
    uint256 public buyoutTimes = 1;
    //shardPool count
    uint256 public shardPoolIdCount;
    // all of the shardpoolId
    uint256[] internal allPools;
    // Info of each pool.
    mapping(uint256 => shardPool) public poolInfo;
    //shardPool
    struct shardPool {
        address creator; //shard  creator
        uint256 tokenId; //tokenID of nft
        ShardsState state; //shard state
        uint256 createTime;
        uint256 deadlineForStake;
        uint256 deadlineForRedeem;
        uint256 balanceOfWantToken; // all the stake amount of the wantToken in this pool
        uint256 minWantTokenAmount; //Minimum subscription required by the creator
        address nft; //nft address
        bool isCreatorWithDraw; //Does the creator withdraw wantToken
        address wantToken; // token address Requested by the creator for others to stake
        uint256 openingPrice;
    }

    mapping(uint256 => shard) public shardInfo;
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

    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    struct UserInfo {
        uint256 amount;
        bool isWithdrawShard;
    }


    uint256 public profitProportionForDev = 20;

    address public regulator;

    address public shardAdditionProposal;

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
}

abstract contract IShardsMarket is IShardsMarketStorge, IERC721Receiver {
    event ShardCreated(
        uint256 shardPoolId,
        address indexed creator,
        address nft,
        uint256 _tokenId,
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

    function createShard(
        address nft,
        uint256 _tokenId,
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

    function setShardsCreatorProportion(uint256 _shardsCreatorProportion)
        external
        virtual;

    function setPlatformProportion(uint256 _platformProportion)
        external
        virtual;

    //    function setBuyoutProportion(uint256 _buyoutProportion) external virtual;

    //    function setBuyoutTimes(uint256 _buyoutTimes) external virtual;

    //     function setVoteLenth(uint256 _voteLenth) external virtual;

    //     function setPassNeeded(uint256 _passNeeded) external virtual;

    function setTotalSupply(uint256 _totalSupply) external virtual;

    function setDeadlineForRedeem(uint256 _deadlineForRedeem) external virtual;

    function setDeadlineForStake(uint256 _deadlineForStake) external virtual;

    function setDev(address _dev) external virtual;

    function setProfitProportionForDev(uint256 _profitProportionForDev)
        external
        virtual;

    function setGovernance(address _governance) external virtual;

    function setTokenBar(address _tokenBar) external virtual;

    function setShardsFarm(address _shardsFarm) external virtual;

    function setRegulator(address _regulator) external virtual;

    function shardAudit(uint256 _shardPoolId, bool isPassed) external virtual {}

    function getPrice(uint256 _shardPoolId)
        public
        view
        virtual
        returns (uint256 currentPrice)
    {}

    function getAllPools()
        external
        view
        virtual
        returns (uint256[] memory _pools)
    {}

    // function getProposalsForExactPool(uint256 _shardPoolId)
    //     external
    //     view
    //     virtual
    //     returns (uint256[] memory _proposalsHistory)
    // {}
}

// File: contracts/MarketRegulator.sol

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;



contract MarketRegulator {
    constructor() public {
        governance = msg.sender;
    }

    event BlacklistAdd(
        uint256 indexed _shardPoolId,
        address nft,
        uint256 tokenId
    );
    event BlacklistRemove(
        uint256 indexed _shardPoolId,
        address nft,
        uint256 tokenId
    );

    address public governance;
    address public market;

    mapping(address => uint256) internal whiteListIndexForWantToken; // savedIndex = realIndex + 1
    struct whiteListToken {
        address token;
        string symbol;
    }
    whiteListToken[] internal wantTokenWhiteList;

    mapping(uint256 => uint256) internal blacklistIndexForShardPool;
    uint256[] internal shardPoolBlacklist;

    function setWhiteListForWantToken(address wantToken, bool isListed)
        external
    {
        require(msg.sender == governance, "UNAUTHORIZED");
        require(wantToken != address(0), "INVALID INPUT");
        uint256 index = whiteListIndexForWantToken[wantToken];
        require(
            (index > 0 && !isListed) || (index == 0 && isListed),
            "AlREADY SET"
        );

        if (index > 0 && !isListed) {
            if (index < wantTokenWhiteList.length) {
                whiteListIndexForWantToken[
                    wantTokenWhiteList[wantTokenWhiteList.length - 1].token
                ] = index;
                wantTokenWhiteList[index - 1] = wantTokenWhiteList[
                    wantTokenWhiteList.length - 1
                ];
            }
            whiteListIndexForWantToken[wantToken] = 0;
            wantTokenWhiteList.pop();
        }
        if (index == 0 && isListed) {
            string memory tokenSymbol = IERC20(wantToken).symbol();
            wantTokenWhiteList.push(
                whiteListToken({token: wantToken, symbol: tokenSymbol})
            );
            whiteListIndexForWantToken[wantToken] = wantTokenWhiteList.length;
        }
    }

    function setBlacklistForShardPool(uint256 _shardPoolId, bool isListed)
        external
    {
        require(msg.sender == governance, "UNAUTHORIZED");
        require(
            _shardPoolId <= IShardsMarket(market).shardPoolIdCount(),
            "NOT EXIST"
        );

        uint256 index = blacklistIndexForShardPool[_shardPoolId];
        require(
            (index > 0 && !isListed) || (index == 0 && isListed),
            "AlREADY SET"
        );
        (, uint256 tokenId, , , , , , , address nft, , , ) =
            IShardsMarket(market).poolInfo(_shardPoolId);

        if (index > 0 && !isListed) {
            if (index < shardPoolBlacklist.length) {
                blacklistIndexForShardPool[
                    shardPoolBlacklist[shardPoolBlacklist.length - 1]
                ] = index;
                shardPoolBlacklist[index - 1] = shardPoolBlacklist[
                    shardPoolBlacklist.length - 1
                ];
            }
            blacklistIndexForShardPool[_shardPoolId] = 0;
            shardPoolBlacklist.pop();
            emit BlacklistRemove(_shardPoolId, nft, tokenId);
        }
        if (index == 0 && isListed) {
            shardPoolBlacklist.push(_shardPoolId);
            blacklistIndexForShardPool[_shardPoolId] = shardPoolBlacklist
                .length;
            emit BlacklistAdd(_shardPoolId, nft, tokenId);
        }
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "UNAUTHORIZED");
        governance = _governance;
    }

    function getWantTokenWhiteList()
        external
        view
        returns (whiteListToken[] memory _wantTokenWhiteList)
    {
        _wantTokenWhiteList = wantTokenWhiteList;
    }

    function getBlacklistPools()
        external
        view
        returns (uint256[] memory _blacklistPools)
    {
        _blacklistPools = shardPoolBlacklist;
    }

    function IsInWhiteList(address wantToken)
        external
        view
        returns (bool inTheList)
    {
        uint256 index = whiteListIndexForWantToken[wantToken];
        if (index == 0) inTheList = false;
        else inTheList = true;
    }

    function IsInBlackList(uint256 _shardPoolId)
        external
        view
        returns (bool inTheList)
    {
        uint256 index = blacklistIndexForShardPool[_shardPoolId];
        if (index == 0) inTheList = false;
        else inTheList = true;
    }

    function setMarket(address _market) external {
        require(msg.sender == governance, "UNAUTHORIZED");
        market = _market;
    }
}