pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20Mono is IERC20 {
    function mintReward(address user, uint256 amount) external;
}

pragma solidity ^0.8.0;

import "./IERC20Mono.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract MonoStaking is ERC1155Holder, Ownable {
    using SafeMath for uint256;
    //using EnumerableMap for EnumerableSet.UintSet;

    // contracts that we interact with
    IERC1155 public LPTokensContract;
    IERC20Mono public MonoTokenContract;

    //structures that we will need

    struct LPWeight {
        uint256 _weight;
        uint256 _lastUpdate;
    }

    struct LPPromo {
        bool _isPromoted;
        uint256 _lastUpdate;
    }

    struct PeriodInfo {
        mapping(uint256 => uint256) _computedWeights;
        uint256 _decayFactor;
        mapping(uint256 => uint256) _totalSupplies;
        bool _resolved;
        // in this sum we hold (weight / totalsupply) * decay ^ n for each lp
        mapping(uint256 => uint256) _globalWeightsSupplyRelationshipSum;
    }

    struct Placement {
        uint256 amount;
        uint256 tokenId;
        uint256 blockNumber;
        bool resolved;
    }

    struct User {
        mapping(uint256 => Placement[]) placements;
        mapping(uint256 => uint256) LPStakes;
        uint256 rewardBalance;
        mapping(uint256 => mapping(uint256 => uint256)) totalCurrentPeriodStakes; // see withdraw functions. We need this to see if we need to keep the continuity of past stakes
    }

    //global config state variables

    // globalSumFactor decimals
    uint32 public constant GLOBAL_SUM_FACTOR_DECIMALS = 1000000;

    //token precision
    uint256 public TOKEN_DECIMALS = 10**18;

    // decay factor decimals
    uint32 public constant DECAY_FACTOR_DECIMALS = 1000;

    //weights decimals
    uint32 public constant WEIGHT_DECIMALS = 1000;

    //reward is distributed once every REWARD_CYCLE_BLOCKS
    uint16 public constant REWARD_CYCLE_BLOCKS = 10;

    // the global decay factor times DECAY_FACTOR_DECIMALS
    uint16 public constant REWARD_DECAY_FACTOR = 999;

    // starting reward (reward given for the first block)
    uint16 public constant INITIAL_REWARD = 42000;

    // we save the current decay factor
    uint32 public currentRewardDecayFactor = 1000;

    //we add here every lp token encountered by the contract
    uint256[] _LPCollection;

    // we save the currentPeriodTotalSupplyDelta for each lp
    mapping(uint256 => uint256) public _currentPeriodTotalSupplyDelta;

    // we save information about each period in the below mapping
    mapping(uint256 => PeriodInfo) public _periodInfo;

    // the block in which the contract was deployed
    uint256 public _deployBlock;

    // save the last computed period info
    uint256 public _lastComputedPeriod = 0;

    // in this sum we hold (weight / totalsupply) * decay ^ n for each lp
    mapping(uint256 => uint256) public _globalSumPreviousPeriod;

    // current lp weights
    mapping(uint256 => LPWeight) public _LPWeights;
    // current active lp
    mapping(uint256 => LPPromo) public _LPPromos;

    //mapping from users to placements
    mapping(address => User) public users;

    constructor() {
        _deployBlock = block.number;
    }

    function computePeriodInfo(uint256 blockNumber) public {
        //we leave this public if any good good samaritan wants to pay for the computations
        uint256 nextPeriod = getNextRewardPeriod(blockNumber);
        if (nextPeriod >= 2 && _periodInfo[nextPeriod - 2]._resolved == false) {
            if (_lastComputedPeriod == 0) {
                // we check if we're not resolving the first block

                for (uint16 i = 0; i < _LPCollection.length; i++) {
                    _periodInfo[nextPeriod - 2]._totalSupplies[
                        _LPCollection[i]
                    ] = _currentPeriodTotalSupplyDelta[_LPCollection[i]];

                    if (_LPWeights[_LPCollection[i]]._weight > 0) {
                        _periodInfo[nextPeriod - 2]._computedWeights[
                            _LPCollection[i]
                        ] = _LPWeights[_LPCollection[i]]._weight;
                    }

                    if (
                        _periodInfo[nextPeriod - 2]._totalSupplies[
                            _LPCollection[i]
                        ] != 0
                    ) {
                        _globalSumPreviousPeriod[_LPCollection[i]] =
                            ((GLOBAL_SUM_FACTOR_DECIMALS *
                                (((_LPWeights[_LPCollection[i]]._weight *
                                    TOKEN_DECIMALS) /
                                    _periodInfo[nextPeriod - 2]._totalSupplies[
                                        _LPCollection[i]
                                    ]) / WEIGHT_DECIMALS)) *
                                currentRewardDecayFactor) /
                            DECAY_FACTOR_DECIMALS; // we calculate the new (weight / totalsupply) * decay ^ n for each lp
                    }

                    _periodInfo[nextPeriod - 2]
                        ._globalWeightsSupplyRelationshipSum[
                        _LPCollection[i]
                    ] = _globalSumPreviousPeriod[_LPCollection[i]];

                    _currentPeriodTotalSupplyDelta[_LPCollection[i]] = 0; // reset the daily delta for total supplies
                }
            } else {
                if (!_periodInfo[nextPeriod - 3]._resolved) {
                    computePeriodInfo(blockNumber - REWARD_CYCLE_BLOCKS); // if we have inactive periods
                }

                _periodInfo[nextPeriod - 2]._decayFactor =
                    (_periodInfo[nextPeriod - 3]._decayFactor *
                        REWARD_DECAY_FACTOR) /
                    DECAY_FACTOR_DECIMALS;

                for (uint16 i = 0; i < _LPCollection.length; i++) {
                    _periodInfo[nextPeriod - 2]._totalSupplies[
                        _LPCollection[i]
                    ] =
                        _currentPeriodTotalSupplyDelta[_LPCollection[i]] + //this can overflow when delta < 0
                        _periodInfo[nextPeriod - 3]._totalSupplies[
                            _LPCollection[i]
                        ]; // we add the total supply available at the end of each period in order to later calculate a weighted average

                    if (_LPWeights[_LPCollection[i]]._weight > 0) {
                        _periodInfo[nextPeriod - 2]._computedWeights[
                            _LPCollection[i]
                        ] = _LPWeights[_LPCollection[i]]._weight;
                    }

                    if (
                        _periodInfo[nextPeriod - 2]._totalSupplies[
                            _LPCollection[i]
                        ] != 0
                    ) {
                        _globalSumPreviousPeriod[_LPCollection[i]] +=
                            (((GLOBAL_SUM_FACTOR_DECIMALS *
                                ((_LPWeights[_LPCollection[i]]._weight *
                                    TOKEN_DECIMALS) /
                                    _periodInfo[nextPeriod - 2]._totalSupplies[
                                        _LPCollection[i]
                                    ])) / WEIGHT_DECIMALS) *
                                _periodInfo[nextPeriod - 2]._decayFactor) /
                            DECAY_FACTOR_DECIMALS; // we calculate the new (weight / totalsupply) * decay ^ n for each lp
                    }

                    _currentPeriodTotalSupplyDelta[_LPCollection[i]] = 0; // reset the daily delta for total supplies

                    _periodInfo[nextPeriod - 2]
                        ._globalWeightsSupplyRelationshipSum[
                        _LPCollection[i]
                    ] = _globalSumPreviousPeriod[_LPCollection[i]];
                }
            }

            _periodInfo[nextPeriod - 2]._resolved = true;
            _lastComputedPeriod += 1;

            // we set the decay factor for the current period
            currentRewardDecayFactor =
                (currentRewardDecayFactor * REWARD_DECAY_FACTOR) /
                DECAY_FACTOR_DECIMALS;
        }
    }

    function getUserPlacement(
        address user,
        uint256 tokenId,
        uint256 index
    ) external view returns (Placement memory placement) {
        placement = users[user].placements[tokenId][index];
    }

    function stakeLP(uint256 tokenId, uint256 amount) external {
        computePeriodInfo(block.number); // first we make sure that the last period's info was computed

        LPTokensContract.safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            amount,
            ""
        );

        _currentPeriodTotalSupplyDelta[tokenId] += amount; //we add to the delta of totalsupplies

        users[msg.sender].LPStakes[tokenId] = users[msg.sender].LPStakes[
            tokenId
        ]
            .add(amount);

        users[msg.sender].totalCurrentPeriodStakes[
            getNextRewardPeriod(block.number) - 1
        ][tokenId] = users[msg.sender].totalCurrentPeriodStakes[
            getNextRewardPeriod(block.number) - 1
        ][tokenId]
            .add(amount);

        stakeLPFromUserBalances(tokenId, amount, block.number);
    }

    function stakeLPFromUserBalances(
        uint256 tokenId,
        uint256 amount,
        uint256 blockNumber
    ) private {
        Placement memory newPlacement;
        newPlacement.tokenId = tokenId;
        newPlacement.amount = amount;
        newPlacement.blockNumber = blockNumber;

        users[msg.sender].placements[tokenId].push(newPlacement);
    }

    // this won't be accurate until the computePeriodInfo is called in the currentPeriod
    // a more sophisticated getter can also simulate the entire computePeriodInfo recursion, but this is a seriously time-consuming improvement
    function getRewardAvailable(address user)
        external
        view
        returns (uint256 rewardBalance)
    {
        rewardBalance = users[user].rewardBalance;

        for (uint16 j = 0; j < _LPCollection.length; j++) {
            uint256 i = users[user].placements[_LPCollection[j]].length - 1;
            uint256 tokenStake = users[user].LPStakes[_LPCollection[j]];

            if (getNextRewardPeriod(block.number) > 1) {
                uint256 placementEndPeriod =
                    getNextRewardPeriod(block.number) - 2;

                while (!users[user].placements[_LPCollection[j]][i].resolved) {
                    uint256 placementStartPeriod =
                        getNextRewardPeriod(
                            users[user].placements[_LPCollection[j]][i]
                                .blockNumber
                        );

                    if (
                        placementStartPeriod <= placementEndPeriod &&
                        placementEndPeriod <= _lastComputedPeriod //we skip the placement segments rewards that don't have computed period info :(
                    ) {
                        uint256 segmentFactorSum =
                            _periodInfo[placementEndPeriod]
                                ._globalWeightsSupplyRelationshipSum[
                                _LPCollection[j]
                            ] -
                                _periodInfo[placementStartPeriod - 1]
                                    ._globalWeightsSupplyRelationshipSum[
                                    _LPCollection[j]
                                ]; //  O(1) COMPLEXITY for calculating reward

                        uint256 computedReward =
                            (tokenStake * INITIAL_REWARD * segmentFactorSum) /
                                GLOBAL_SUM_FACTOR_DECIMALS; // the formula

                        rewardBalance += computedReward;
                    }

                    tokenStake -= users[user].placements[_LPCollection[j]][i]
                        .amount;
                    placementEndPeriod = placementStartPeriod - 1;
                    if (i > 0) i--;
                }
            }
        }
    }

    function withdrawLP(uint256 tokenId, uint256 amount) external {
        computePeriodInfo(block.number); // first we make sure that the last period's info was computed
        resolvePlacements(msg.sender, tokenId);
        require(
            amount <= users[msg.sender].LPStakes[tokenId],
            "not enough LP tokens with the specified id"
        );

        users[msg.sender].LPStakes[tokenId] = users[msg.sender].LPStakes[
            tokenId
        ]
            .sub(amount);

        placeRemainingLP(tokenId, amount);

        _currentPeriodTotalSupplyDelta[tokenId] -= amount; //we subtract from the delta of totalsupplies.. can overflow, but it's all under control

        LPTokensContract.safeTransferFrom(
            address(this),
            msg.sender,
            tokenId,
            amount,
            ""
        );
    }

    function withdrawReward(uint256 amount) external {
        computePeriodInfo(block.number);

        for (uint16 i = 0; i < _LPCollection.length; i++) {
            if (users[msg.sender].LPStakes[_LPCollection[i]] > 0) {
                //of no stakes are active, there's no reason to try and resolve them or place any remaining balances
                resolvePlacements(msg.sender, _LPCollection[i]);
                placeRemainingLP(_LPCollection[i], 0); // we have withdrawn 0 LP in the current function
            }
        }

        require(
            users[msg.sender].rewardBalance >= amount,
            "can't withdraw more than the yielded reward"
        );

        users[msg.sender].rewardBalance = users[msg.sender].rewardBalance.sub(
            amount
        );
        MonoTokenContract.mintReward(msg.sender, amount);
    }

    // given the nature of the data flow, only the last sequence of consecutive placements can be unresolved
    // we cannot have a sequence as follows: p_n.resolved -> p_(n+k).unresolved -> p_(n+k+i).resolved
    function resolvePlacements(address user, uint256 tokenId) private {
        uint256 i = users[user].placements[tokenId].length - 1;
        uint256 tokenStake = users[user].LPStakes[tokenId];

        if (getNextRewardPeriod(block.number) > 1) {
            uint256 placementEndPeriod = getNextRewardPeriod(block.number) - 2;

            while (!users[user].placements[tokenId][i].resolved) {
                uint256 placementStartPeriod =
                    getNextRewardPeriod(
                        users[user].placements[tokenId][i].blockNumber
                    );

                if (placementStartPeriod <= placementEndPeriod) {
                    uint256 segmentFactorSum =
                        _periodInfo[placementEndPeriod]
                            ._globalWeightsSupplyRelationshipSum[tokenId] -
                            _periodInfo[placementStartPeriod - 1]
                                ._globalWeightsSupplyRelationshipSum[tokenId]; //  O(1) COMPLEXITY for calculating reward

                    uint256 computedReward =
                        (tokenStake * INITIAL_REWARD * segmentFactorSum) /
                            GLOBAL_SUM_FACTOR_DECIMALS; // the formula

                    users[user].rewardBalance += computedReward;
                }

                tokenStake -= users[user].placements[tokenId][i].amount;
                placementEndPeriod = placementStartPeriod - 1;
                users[user].placements[tokenId][i].resolved = true;
                if (i > 0) i--;
            }
        } else {
            // we need to treat the resolves from period 0 differently
            while (!users[user].placements[tokenId][i].resolved) {
                users[user].placements[tokenId][i].resolved = true;
            }
        }
    }

    // this function receives the amount withdrawn in the current atomic call
    function placeRemainingLP(uint256 tokenId, uint256 amount) private {
        if (
            amount <=
            users[msg.sender].totalCurrentPeriodStakes[
                getNextRewardPeriod(block.number) - 1
            ][tokenId]
        ) {
            stakeLPFromUserBalances(
                tokenId,
                users[msg.sender].totalCurrentPeriodStakes[
                    getNextRewardPeriod(block.number) - 1
                ][tokenId] - amount,
                block.number
            );

            stakeLPFromUserBalances(
                tokenId,
                users[msg.sender].LPStakes[tokenId] -
                    users[msg.sender].totalCurrentPeriodStakes[
                        getNextRewardPeriod(block.number) - 1
                    ][tokenId],
                block.number - REWARD_CYCLE_BLOCKS
            );
        } else {
            stakeLPFromUserBalances(
                tokenId,
                users[msg.sender].LPStakes[tokenId],
                block.number - REWARD_CYCLE_BLOCKS
            );
        }
    }

    function setERC1155Contract(address stakingContractAddress)
        external
        onlyOwner()
    {
        LPTokensContract = IERC1155(stakingContractAddress);
    }

    function setERC20RewardContract(address monoTokenContractAddress)
        external
        onlyOwner()
    {
        MonoTokenContract = IERC20Mono(monoTokenContractAddress);
    }

    function setWeight(uint256 tokenId, uint256 weight) public onlyOwner() {
        LPWeight memory lpw;
        lpw._weight = weight;
        lpw._lastUpdate = block.number;
        _LPWeights[tokenId] = lpw;
        normalizeWeights();
        computePeriodInfo(block.number);
    }

    function getWeight(uint256 tokenId)
        public
        view
        returns (LPWeight memory weight)
    {
        weight = _LPWeights[tokenId];
    }

    function setPromo(uint256 tokenId) external onlyOwner() {
        LPPromo memory lpp;
        lpp._isPromoted = true;
        lpp._lastUpdate = block.number;

        if (_LPPromos[tokenId]._lastUpdate == 0) _LPCollection.push(tokenId);

        _LPPromos[tokenId] = lpp;
    }

    function removeFromPromo(uint256 tokenId) external onlyOwner() {
        LPPromo memory lpp;
        lpp._isPromoted = false;
        lpp._lastUpdate = block.number;
        _LPPromos[tokenId] = lpp;
        setWeight(tokenId, 0);
    }

    function getNextRewardBlock(uint256 queriedBlock)
        private
        pure
        returns (uint256)
    {
        return ((queriedBlock / REWARD_CYCLE_BLOCKS) + 1) * REWARD_CYCLE_BLOCKS;
    }

    function getNextRewardPeriod(uint256 queriedBlock)
        private
        view
        returns (uint256)
    {
        return ((queriedBlock - _deployBlock) / REWARD_CYCLE_BLOCKS) + 1;
    }

    function normalizeWeights() private {
        uint256 weightsSum = 0;
        for (uint16 i = 0; i < _LPCollection.length; i++) {
            weightsSum += _LPWeights[_LPCollection[i]]._weight;
        }
        for (uint16 i = 0; i < _LPCollection.length; i++) {
            _LPWeights[_LPCollection[i]]._weight =
                (_LPWeights[_LPCollection[i]]._weight * WEIGHT_DECIMALS) /
                weightsSum;
        }

        require(
            weightsSum > 0,
            "There needs to be at least one token with weight in the contract. If the 0 weights are intended, a pause functionality should be implemented"
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    constructor () {
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

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId
            || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./EnumerableSet.sol";

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    using EnumerableSet for EnumerableSet.Bytes32Set;

    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct Map {
        // Storage of keys
        EnumerableSet.Bytes32Set _keys;

        mapping (bytes32 => bytes32) _values;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        map._values[key] = value;
        return map._keys.add(key);
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        delete map._values[key];
        return map._keys.remove(key);
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._keys.contains(key);
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._keys.length();
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        bytes32 key = map._keys.at(index);
        return (key, map._values[key]);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        bytes32 value = map._values[key];
        if (value == bytes32(0)) {
            return (_contains(map, key), bytes32(0));
        } else {
            return (true, value);
        }
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), "EnumerableMap: nonexistent key");
        return value;
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        bytes32 value = map._values[key];
        require(value != 0 || _contains(map, key), errorMessage);
        return value;
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {},
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