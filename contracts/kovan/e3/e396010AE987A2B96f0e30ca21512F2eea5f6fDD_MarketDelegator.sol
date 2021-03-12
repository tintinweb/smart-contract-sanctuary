/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

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

// File: contracts/interface/DelegatorInterface.sol

pragma solidity 0.6.12;

contract DelegationStorage {
    /**
     * @notice Implementation address for this contract
     */
    address public implementation;
}

abstract contract DelegatorInterface is DelegationStorage {
    /**
     * @notice Emitted when implementation is changed
     */
    event NewImplementation(
        address oldImplementation,
        address newImplementation
    );

    /**
     * @notice Called by the admin to update the implementation of the delegator
     * @param implementation_ The address of the new implementation for delegation
     * @param allowResign Flag to indicate whether to call _resignImplementation on the old implementation
     * @param becomeImplementationData The encoded bytes data to be passed to _becomeImplementation
     */
    function _setImplementation(
        address implementation_,
        bool allowResign,
        bytes memory becomeImplementationData
    ) public virtual;
}

abstract contract DelegateInterface is DelegationStorage {
    /**
     * @notice Called by the delegator on a delegate to initialize it for duty
     * @dev Should revert if any issues arise which make it unfit for delegation
     * @param data The encoded bytes data for any initialization
     */
    function _becomeImplementation(bytes memory data) public virtual;

    /**
     * @notice Called by the delegator on a delegate to forfeit its responsibility
     */
    function _resignImplementation() public virtual;
}

// File: contracts/MarketDelegator.sol

pragma solidity 0.6.12;



contract MarketDelegator is IShardsMarket, DelegatorInterface {
    constructor(
        address _WETH,
        address _factory,
        address _governance,
        address _router,
        address _dev,
        address _tokenBar,
        address _shardsFactory,
        address _regulator,
        address _buyoutProposals,
        address implementation_,
        bytes memory becomeImplementationData
    ) public {
        governance = msg.sender;

        delegateTo(
            implementation_,
            abi.encodeWithSignature(
                "initialize(address,address,address,address,address,address,address,address,address)",
                _WETH,
                _factory,
                _governance,
                _router,
                _dev,
                _tokenBar,
                _shardsFactory,
                _regulator,
                _buyoutProposals
            )
        );
        _setImplementation(implementation_, false, becomeImplementationData);
        governance = _governance;
    }

    function _setImplementation(
        address implementation_,
        bool allowResign,
        bytes memory becomeImplementationData
    ) public override {
        require(
            msg.sender == governance,
            "_setImplementation: Caller must be admin"
        );

        if (allowResign) {
            delegateToImplementation(
                abi.encodeWithSignature("_resignImplementation()")
            );
        }

        address oldImplementation = implementation;
        implementation = implementation_;

        delegateToImplementation(
            abi.encodeWithSignature(
                "_becomeImplementation(bytes)",
                becomeImplementationData
            )
        );

        emit NewImplementation(oldImplementation, implementation);
    }

    function createShard(
        address nft,
        uint256 _tokenId,
        string memory shardName,
        string memory shardSymbol,
        uint256 minWantTokenAmount,
        address wantToken
    ) external override returns (uint256 shardPoolId) {
        bytes memory data =
            delegateToImplementation(
                abi.encodeWithSignature(
                    "createShard(address,uint256,string,string,uint256,address)",
                    nft,
                    _tokenId,
                    shardName,
                    shardSymbol,
                    minWantTokenAmount,
                    wantToken
                )
            );
        return abi.decode(data, (uint256));
    }

    function stake(uint256 _shardPoolId, uint256 amount) external override {
        delegateToImplementation(
            abi.encodeWithSignature(
                "stake(uint256,uint256)",
                _shardPoolId,
                amount
            )
        );
    }

    function stakeETH(uint256 _shardPoolId) external payable override {
        delegateToImplementation(
            abi.encodeWithSignature("stakeETH(uint256)", _shardPoolId)
        );
    }

    function redeem(uint256 _shardPoolId, uint256 amount) external override {
        delegateToImplementation(
            abi.encodeWithSignature(
                "redeem(uint256,uint256)",
                _shardPoolId,
                amount
            )
        );
    }

    function redeemETH(uint256 _shardPoolId, uint256 amount) external override {
        delegateToImplementation(
            abi.encodeWithSignature(
                "redeemETH(uint256,uint256)",
                _shardPoolId,
                amount
            )
        );
    }

    function settle(uint256 _shardPoolId) external override {
        delegateToImplementation(
            abi.encodeWithSignature("settle(uint256)", _shardPoolId)
        );
    }

    function redeemInSubscriptionFailed(uint256 _shardPoolId)
        external
        override
    {
        delegateToImplementation(
            abi.encodeWithSignature(
                "redeemInSubscriptionFailed(uint256)",
                _shardPoolId
            )
        );
    }

    function usersWithdrawShardToken(uint256 _shardPoolId) external override {
        delegateToImplementation(
            abi.encodeWithSignature(
                "usersWithdrawShardToken(uint256)",
                _shardPoolId
            )
        );
    }

    function creatorWithdrawWantToken(uint256 _shardPoolId) external override {
        delegateToImplementation(
            abi.encodeWithSignature(
                "creatorWithdrawWantToken(uint256)",
                _shardPoolId
            )
        );
    }

    function applyForBuyout(uint256 _shardPoolId, uint256 wantTokenAmount)
        external
        override
        returns (uint256 proposalId)
    {
        bytes memory data =
            delegateToImplementation(
                abi.encodeWithSignature(
                    "applyForBuyout(uint256,uint256)",
                    _shardPoolId,
                    wantTokenAmount
                )
            );
        return abi.decode(data, (uint256));
    }

    function applyForBuyoutETH(uint256 _shardPoolId)
        external
        payable
        override
        returns (uint256 proposalId)
    {
        bytes memory data =
            delegateToImplementation(
                abi.encodeWithSignature(
                    "applyForBuyoutETH(uint256)",
                    _shardPoolId
                )
            );
        return abi.decode(data, (uint256));
    }

    function vote(uint256 _shardPoolId, bool isAgree) external override {
        delegateToImplementation(
            abi.encodeWithSignature("vote(uint256,bool)", _shardPoolId, isAgree)
        );
    }

    function voteResultConfirm(uint256 _shardPoolId)
        external
        override
        returns (bool result)
    {
        bytes memory data =
            delegateToImplementation(
                abi.encodeWithSignature(
                    "voteResultConfirm(uint256)",
                    _shardPoolId
                )
            );
        return abi.decode(data, (bool));
    }

    function exchangeForWantToken(uint256 _shardPoolId, uint256 shardAmount)
        external
        override
        returns (uint256 wantTokenAmount)
    {
        bytes memory data =
            delegateToImplementation(
                abi.encodeWithSignature(
                    "exchangeForWantToken(uint256,uint256)",
                    _shardPoolId,
                    shardAmount
                )
            );
        return abi.decode(data, (uint256));
    }

    function redeemForBuyoutFailed(uint256 _proposalId)
        external
        override
        returns (uint256 shardTokenAmount, uint256 wantTokenAmount)
    {
        bytes memory data =
            delegateToImplementation(
                abi.encodeWithSignature(
                    "redeemForBuyoutFailed(uint256)",
                    _proposalId
                )
            );
        return abi.decode(data, (uint256, uint256));
    }

    function getPrice(uint256 _shardPoolId)
        public
        view
        override
        returns (uint256 currentPrice)
    {
        bytes memory data =
            delegateToViewImplementation(
                abi.encodeWithSignature("getPrice(uint256)", _shardPoolId)
            );
        return abi.decode(data, (uint256));
    }

    //admin
    function setDeadlineForStake(uint256 _deadlineForStake) external override {
        delegateToImplementation(
            abi.encodeWithSignature(
                "setDeadlineForStake(uint256)",
                _deadlineForStake
            )
        );
    }

    function setDeadlineForRedeem(uint256 _deadlineForRedeem)
        external
        override
    {
        delegateToImplementation(
            abi.encodeWithSignature(
                "setDeadlineForRedeem(uint256)",
                _deadlineForRedeem
            )
        );
    }

    function setShardsCreatorProportion(uint256 _shardsCreatorProportion)
        external
        override
    {
        delegateToImplementation(
            abi.encodeWithSignature(
                "setShardsCreatorProportion(uint256)",
                _shardsCreatorProportion
            )
        );
    }

    function setPlatformProportion(uint256 _platformProportion)
        external
        override
    {
        delegateToImplementation(
            abi.encodeWithSignature(
                "setPlatformProportion(uint256)",
                _platformProportion
            )
        );
    }

    function setTotalSupply(uint256 _totalSupply) external override {
        delegateToImplementation(
            abi.encodeWithSignature("setTotalSupply(uint256)", _totalSupply)
        );
    }

    function setDev(address _dev) external override {
        delegateToImplementation(
            abi.encodeWithSignature("setDev(address)", _dev)
        );
    }

    function setProfitProportionForDev(uint256 _profitProportionForDev)
        external
        override
    {
        delegateToImplementation(
            abi.encodeWithSignature(
                "setProfitProportionForDev(uint256)",
                _profitProportionForDev
            )
        );
    }

    function setGovernance(address _governance) external override {
        delegateToImplementation(
            abi.encodeWithSignature("setGovernance(address)", _governance)
        );
    }

    function setTokenBar(address _tokenBar) external override {
        delegateToImplementation(
            abi.encodeWithSignature("setTokenBar(address)", _tokenBar)
        );
    }

    function setShardsFarm(address _shardsFarm) external override {
        delegateToImplementation(
            abi.encodeWithSignature("setShardsFarm(address)", _shardsFarm)
        );
    }

    function setRegulator(address _regulator) external override {
        delegateToImplementation(
            abi.encodeWithSignature("setRegulator(address)", _regulator)
        );
    }

    function shardAudit(uint256 _shardPoolIds, bool isPassed)
        external
        override
    {
        delegateToImplementation(
            abi.encodeWithSignature(
                "shardAudit(uint256,bool)",
                _shardPoolIds,
                isPassed
            )
        );
    }

    function getAllPools()
        external
        view
        override
        returns (uint256[] memory _pools)
    {
        bytes memory data =
            delegateToViewImplementation(
                abi.encodeWithSignature("getAllPools()")
            );
        return abi.decode(data, (uint256[]));
    }

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external override returns (bytes4) {
        _operator;
        _from;
        _tokenId;
        _data;
        return 0x150b7a02;
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

    /**
     * @notice Delegates execution to the implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToImplementation(bytes memory data)
        public
        returns (bytes memory)
    {
        return delegateTo(implementation, data);
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
     *  There are an additional 2 prefix uints from the wrapper returndata, which we ignore since we make an extra hop.
     * @param data The raw data to delegatecall
     * @return The returned bytes from the delegatecall
     */
    function delegateToViewImplementation(bytes memory data)
        public
        view
        returns (bytes memory)
    {
        (bool success, bytes memory returnData) =
            address(this).staticcall(
                abi.encodeWithSignature("delegateToImplementation(bytes)", data)
            );
        assembly {
            if eq(success, 0) {
                revert(add(returnData, 0x20), returndatasize())
            }
        }
        return abi.decode(returnData, (bytes));
    }

    /**
     * @notice Delegates execution to an implementation contract
     * @dev It returns to the external caller whatever the implementation returns or forwards reverts
    //  */
    fallback() external payable {
        if (msg.value > 0) return;
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