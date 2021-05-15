/**
 *Submitted for verification at Etherscan.io on 2021-05-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
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
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface ServiceInterface {
    function claimingFeeNumerator() external view returns(uint256);

    function claimingFeeDenominator() external view returns(uint256);

    function doesNodeExist(address entity, uint128 nodeId) external view returns (bool);

    function getNodeId(address entity, uint128 nodeId) external view returns (bytes memory);

    function getReward(address entity, uint128 nodeId) external view returns (uint256);

    function getRewardByBlock(address entity, uint128 nodeId, uint256 blockNumber) external view returns (uint256);

    function getTraunch(address entity) external view returns (uint256);

    function isEntityActive(address entity) external view returns (bool);

    function claim(uint128 nodeId, uint256 blockNumber, bool toStrongPool) external payable;
}

interface ServiceInterfaceV10 {
    function traunch(address) external view returns(uint256);

    function claimingFeeNumerator() external view returns(uint256);

    function claimingFeeDenominator() external view returns(uint256);

    function doesNodeExist(address entity, uint128 nodeId) external view returns (bool);

    function getNodeId(address entity, uint128 nodeId) external view returns (bytes memory);

    function getReward(address entity, uint128 nodeId) external view returns (uint256);

    function getRewardByBlock(address entity, uint128 nodeId, uint256 blockNumber) external view returns (uint256);

    function isEntityActive(address entity) external view returns (bool);

    function claim(uint128 nodeId, uint256 blockNumber, bool toStrongPool) external payable;
}

interface IERC1155Preset {
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

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    /**
     * @dev Creates `amount` new tokens for `to`, of token type `id`.
     *
     * See {ERC1155-_mint}.
     *
     * Requirements:
     *
     * - the caller must have the `MINTER_ROLE`.
     */
    function mint(address to, uint256 id, uint256 amount, bytes memory data) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] variant of {mint}.
     */
    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) external;

    function getOwnerIdByIndex(address owner, uint256 index) external view returns (uint256);

    function getOwnerIdIndex(address owner, uint256 id) external view returns (uint256);
}

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

interface StrongNFTBonusInterface {
    function getBonus(address _entity, uint128 _nodeId, uint256 _fromBlock, uint256 _toBlock) external view returns (uint256);
}

interface StrongNFTClaimerInterface {
    function tokenNameAddressClaimed(string memory, address) external view returns(bool);
}

interface StrongPoolInterface {
    function mineFor(address miner, uint256 amount) external;
}

interface VoteInterface {
    function getPriorProposalVotes(address account, uint256 blockNumber) external view returns (uint96);

    function updateVotes(
        address voter,
        uint256 rawAmount,
        bool adding
    ) external;
}

library Counters {
    using SafeMath for uint256;

    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

library rewards {

    using SafeMath for uint256;

    function blocks(uint256 lastClaimedOnBlock, uint256 newRewardBlock, uint256 blockNumber) internal pure returns (uint256[2] memory) {
        if (lastClaimedOnBlock >= blockNumber) return [uint256(0), uint256(0)];

        if (blockNumber <= newRewardBlock || newRewardBlock == 0) {
            return [blockNumber.sub(lastClaimedOnBlock), uint256(0)];
        }
        else if (lastClaimedOnBlock >= newRewardBlock) {
            return [uint256(0), blockNumber.sub(lastClaimedOnBlock)];
        }
        else {
            return [newRewardBlock.sub(lastClaimedOnBlock), blockNumber.sub(newRewardBlock)];
        }
    }

}

contract ServiceV9 {
    event Requested(address indexed miner);
    event Claimed(address indexed miner, uint256 reward);

    using SafeMath for uint256;
    bool public initDone;
    address public admin;
    address public pendingAdmin;
    address public superAdmin;
    address public pendingSuperAdmin;
    address public serviceAdmin;
    address public parameterAdmin;
    address payable public feeCollector;

    IERC20 public strongToken;
    StrongPoolInterface public strongPool;

    uint256 public rewardPerBlockNumerator;
    uint256 public rewardPerBlockDenominator;

    uint256 public naasRewardPerBlockNumerator;
    uint256 public naasRewardPerBlockDenominator;

    uint256 public claimingFeeNumerator;
    uint256 public claimingFeeDenominator;

    uint256 public requestingFeeInWei;

    uint256 public strongFeeInWei;

    uint256 public recurringFeeInWei;
    uint256 public recurringNaaSFeeInWei;
    uint256 public recurringPaymentCycleInBlocks;

    uint256 public rewardBalance;

    mapping(address => uint256) public entityBlockLastClaimedOn;

    address[] public entities;
    mapping(address => uint256) public entityIndex;
    mapping(address => bool) public entityActive;
    mapping(address => bool) public requestPending;
    mapping(address => bool) public entityIsNaaS;
    mapping(address => uint256) public paidOnBlock;
    uint256 public activeEntities;

    string public desciption;

    uint256 public claimingFeeInWei;

    uint256 public naasRequestingFeeInWei;

    uint256 public naasStrongFeeInWei;

    bool public removedTokens;

    mapping(address => uint256) public traunch;

    uint256 public currentTraunch;

    mapping(bytes => bool) public entityNodeIsActive;
    mapping(bytes => bool) public entityNodeIsBYON;
    mapping(bytes => uint256) public entityNodeTraunch;
    mapping(bytes => uint256) public entityNodePaidOnBlock;
    mapping(bytes => uint256) public entityNodeClaimedOnBlock;
    mapping(address => uint128) public entityNodeCount;

    event Paid(address indexed entity, uint128 nodeId, bool isBYON, bool isRenewal, uint256 upToBlockNumber);
    event Migrated(address indexed from, address indexed to, uint128 fromNodeId, uint128 toNodeId, bool isBYON);

    function init(
        address strongTokenAddress,
        address strongPoolAddress,
        address adminAddress,
        address superAdminAddress,
        uint256 rewardPerBlockNumeratorValue,
        uint256 rewardPerBlockDenominatorValue,
        uint256 naasRewardPerBlockNumeratorValue,
        uint256 naasRewardPerBlockDenominatorValue,
        uint256 requestingFeeInWeiValue,
        uint256 strongFeeInWeiValue,
        uint256 recurringFeeInWeiValue,
        uint256 recurringNaaSFeeInWeiValue,
        uint256 recurringPaymentCycleInBlocksValue,
        uint256 claimingFeeNumeratorValue,
        uint256 claimingFeeDenominatorValue,
        string memory desc
    ) public {
        require(!initDone, 'init done');
        strongToken = IERC20(strongTokenAddress);
        strongPool = StrongPoolInterface(strongPoolAddress);
        admin = adminAddress;
        superAdmin = superAdminAddress;
        rewardPerBlockNumerator = rewardPerBlockNumeratorValue;
        rewardPerBlockDenominator = rewardPerBlockDenominatorValue;
        naasRewardPerBlockNumerator = naasRewardPerBlockNumeratorValue;
        naasRewardPerBlockDenominator = naasRewardPerBlockDenominatorValue;
        requestingFeeInWei = requestingFeeInWeiValue;
        strongFeeInWei = strongFeeInWeiValue;
        recurringFeeInWei = recurringFeeInWeiValue;
        recurringNaaSFeeInWei = recurringNaaSFeeInWeiValue;
        claimingFeeNumerator = claimingFeeNumeratorValue;
        claimingFeeDenominator = claimingFeeDenominatorValue;
        recurringPaymentCycleInBlocks = recurringPaymentCycleInBlocksValue;
        desciption = desc;
        initDone = true;
    }

    // ADMIN
    // *************************************************************************************

    function updateServiceAdmin(address newServiceAdmin) public {
        require(msg.sender == superAdmin);
        serviceAdmin = newServiceAdmin;
    }

    function updateParameterAdmin(address newParameterAdmin) public {
        require(newParameterAdmin != address(0), 'zero');
        require(msg.sender == superAdmin);
        parameterAdmin = newParameterAdmin;
    }

    function updateFeeCollector(address payable newFeeCollector) public {
        require(newFeeCollector != address(0), 'zero');
        require(msg.sender == superAdmin);
        feeCollector = newFeeCollector;
    }

    function setPendingAdmin(address newPendingAdmin) public {
        require(msg.sender == admin, 'not admin');
        pendingAdmin = newPendingAdmin;
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin && msg.sender != address(0), 'not pendingAdmin');
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function setPendingSuperAdmin(address newPendingSuperAdmin) public {
        require(msg.sender == superAdmin, 'not superAdmin');
        pendingSuperAdmin = newPendingSuperAdmin;
    }

    function acceptSuperAdmin() public {
        require(msg.sender == pendingSuperAdmin && msg.sender != address(0), 'not pendingSuperAdmin');
        superAdmin = pendingSuperAdmin;
        pendingSuperAdmin = address(0);
    }

    // ENTITIES
    // *************************************************************************************

    function getEntities() public view returns (address[] memory) {
        return entities;
    }

    function isEntityActive(address entity) public view returns (bool) {
        return entityActive[entity];
    }

    // TRAUNCH
    // *************************************************************************************

    function updateCurrentTraunch(uint256 value) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
        currentTraunch = value;
    }

    function getTraunch(address entity) public view returns (uint256) {
        return traunch[entity];
    }

    // REWARD
    // *************************************************************************************

    function updateRewardPerBlock(uint256 numerator, uint256 denominator) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
        require(denominator != 0, 'invalid value');
        rewardPerBlockNumerator = numerator;
        rewardPerBlockDenominator = denominator;
    }

    function updateNaaSRewardPerBlock(uint256 numerator, uint256 denominator) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
        require(denominator != 0, 'invalid value');
        naasRewardPerBlockNumerator = numerator;
        naasRewardPerBlockDenominator = denominator;
    }

    function deposit(uint256 amount) public {
        require(msg.sender == superAdmin, 'not an admin');
        require(amount > 0, 'zero');
        strongToken.transferFrom(msg.sender, address(this), amount);
        rewardBalance = rewardBalance.add(amount);
    }

    function withdraw(address destination, uint256 amount) public {
        require(msg.sender == superAdmin, 'not an admin');
        require(amount > 0, 'zero');
        require(rewardBalance >= amount, 'not enough');
        strongToken.transfer(destination, amount);
        rewardBalance = rewardBalance.sub(amount);
    }

    function removeTokens() public {
        require(!removedTokens, 'already removed');
        require(msg.sender == superAdmin, 'not an admin');
        // removing 2500 STRONG tokens sent in this tx: 0xe27640beda32a5e49aad3b6692790b9d380ed25da0cf8dca7fd5f3258efa600a
        strongToken.transfer(superAdmin, 2500000000000000000000);
        removedTokens = true;
    }

    // FEES
    // *************************************************************************************

    function updateRequestingFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
        requestingFeeInWei = feeInWei;
    }

    function updateStrongFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
        strongFeeInWei = feeInWei;
    }

    function updateNaasRequestingFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
        naasRequestingFeeInWei = feeInWei;
    }

    function updateNaasStrongFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
        naasStrongFeeInWei = feeInWei;
    }

    function updateClaimingFee(uint256 numerator, uint256 denominator) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
        require(denominator != 0, 'invalid value');
        claimingFeeNumerator = numerator;
        claimingFeeDenominator = denominator;
    }

    function updateRecurringFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
        recurringFeeInWei = feeInWei;
    }

    function updateRecurringNaaSFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
        recurringNaaSFeeInWei = feeInWei;
    }

    function updateRecurringPaymentCycleInBlocks(uint256 blocks) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, 'not an admin');
        require(blocks > 0, 'zero');
        recurringPaymentCycleInBlocks = blocks;
    }

    // CORE
    // *************************************************************************************

    function requestAccess(bool isNaaS) public payable {
        uint256 rFee;
        uint256 sFee;

        if (hasLegacyNode(msg.sender)) {
            migrateLegacyNode(msg.sender);
        }

        uint128 nodeId = entityNodeCount[msg.sender] + 1;
        bytes memory id = getNodeId(msg.sender, nodeId);

        if (isNaaS) {
            rFee = naasRequestingFeeInWei;
            sFee = naasStrongFeeInWei;
            activeEntities = activeEntities.add(1);
        } else {
            rFee = requestingFeeInWei;
            sFee = strongFeeInWei;
            entityNodeIsBYON[id] = true;
        }

        require(msg.value == rFee, 'invalid fee');

        entityNodePaidOnBlock[id] = block.number;
        entityNodeTraunch[id] = currentTraunch;
        entityNodeClaimedOnBlock[id] = block.number;
        entityNodeCount[msg.sender] = entityNodeCount[msg.sender] + 1;

        feeCollector.transfer(msg.value);
        strongToken.transferFrom(msg.sender, address(this), sFee);
        strongToken.transfer(feeCollector, sFee);

        emit Paid(msg.sender, nodeId, entityNodeIsBYON[id], false, entityNodePaidOnBlock[id].add(recurringPaymentCycleInBlocks));
    }

    function setEntityActiveStatus(address entity, bool status) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin, 'not admin');
        uint256 index = entityIndex[entity];
        require(entities[index] == entity, 'invalid entity');
        require(entityActive[entity] != status, 'already set');
        entityActive[entity] = status;
        if (status) {
            activeEntities = activeEntities.add(1);
            entityBlockLastClaimedOn[entity] = block.number;
        } else {
            activeEntities = activeEntities.sub(1);
            entityBlockLastClaimedOn[entity] = 0;
        }
    }

    function setTraunch(address entity, uint256 value) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin, 'not admin');

        traunch[entity] = value;
    }

    function payFee(uint128 nodeId) public payable {
        address sender = msg.sender == address(this) ? tx.origin : msg.sender;
        bytes memory id = getNodeId(sender, nodeId);

        if (hasLegacyNode(sender)) {
            migrateLegacyNode(sender);
        }

        require(doesNodeExist(sender, nodeId), 'doesnt exist');

        if (entityNodeIsBYON[id]) {
            require(msg.value == recurringFeeInWei, 'invalid fee');
        } else {
            require(msg.value == recurringNaaSFeeInWei, 'invalid fee');
        }

        feeCollector.transfer(msg.value);
        entityNodePaidOnBlock[id] = entityNodePaidOnBlock[id].add(recurringPaymentCycleInBlocks);

        emit Paid(sender, nodeId, entityNodeIsBYON[id], true, entityNodePaidOnBlock[id]);
    }

    function getReward(address entity, uint128 nodeId) public view returns (uint256) {
        return getRewardByBlock(entity, nodeId, block.number);
    }

    function getRewardByBlock(address entity, uint128 nodeId, uint256 blockNumber) public view returns (uint256) {
        bytes memory id = getNodeId(entity, nodeId);

        if (hasLegacyNode(entity)) {
            return getRewardByBlockLegacy(entity, blockNumber);
        }

        uint256 blockLastClaimedOn = entityNodeClaimedOnBlock[id] != 0 ? entityNodeClaimedOnBlock[id] : entityNodePaidOnBlock[id];

        if (blockNumber > block.number) return 0;
        if (blockLastClaimedOn == 0) return 0;
        if (blockNumber < blockLastClaimedOn) return 0;
        if (activeEntities == 0) return 0;
        if (entityNodeIsBYON[id] && !entityNodeIsActive[id]) return 0;

        uint256 blockResult = blockNumber.sub(blockLastClaimedOn);
        uint256 rewardNumerator;
        uint256 rewardDenominator;

        if (entityNodeIsBYON[id]) {
            rewardNumerator = rewardPerBlockNumerator;
            rewardDenominator = rewardPerBlockDenominator;
        } else {
            rewardNumerator = naasRewardPerBlockNumerator;
            rewardDenominator = naasRewardPerBlockDenominator;
        }

        uint256 rewardPerBlockResult = blockResult.mul(rewardNumerator).div(rewardDenominator);

        return rewardPerBlockResult;
    }

    function getRewardByBlockLegacy(address entity, uint256 blockNumber) public view returns (uint256) {
        if (blockNumber > block.number) return 0;
        if (entityBlockLastClaimedOn[entity] == 0) return 0;
        if (blockNumber < entityBlockLastClaimedOn[entity]) return 0;
        if (activeEntities == 0) return 0;
        uint256 blockResult = blockNumber.sub(entityBlockLastClaimedOn[entity]);
        uint256 rewardNumerator;
        uint256 rewardDenominator;
        if (entityIsNaaS[entity]) {
            rewardNumerator = naasRewardPerBlockNumerator;
            rewardDenominator = naasRewardPerBlockDenominator;
        } else {
            rewardNumerator = rewardPerBlockNumerator;
            rewardDenominator = rewardPerBlockDenominator;
        }
        uint256 rewardPerBlockResult = blockResult.mul(rewardNumerator).div(rewardDenominator);

        return rewardPerBlockResult;
    }

    function claim(uint128 nodeId, uint256 blockNumber, bool toStrongPool) public payable {
        address sender = msg.sender == address(this) ? tx.origin : msg.sender;
        bytes memory id = getNodeId(sender, nodeId);

        if (hasLegacyNode(sender)) {
            migrateLegacyNode(sender);
        }

        uint256 blockLastClaimedOn = entityNodeClaimedOnBlock[id] != 0 ? entityNodeClaimedOnBlock[id] : entityNodePaidOnBlock[id];
        uint256 blockLastPaidOn = entityNodePaidOnBlock[id];

        require(blockLastClaimedOn != 0, 'never claimed');
        require(blockNumber <= block.number, 'invalid block');
        require(blockNumber > blockLastClaimedOn, 'too soon');
        require(!entityNodeIsBYON[id] || entityNodeIsActive[id], 'not active');

        if (
            (!entityNodeIsBYON[id] && recurringNaaSFeeInWei != 0) || (entityNodeIsBYON[id] && recurringFeeInWei != 0)
        ) {
            require(blockNumber < blockLastPaidOn.add(recurringPaymentCycleInBlocks), 'pay fee');
        }

        uint256 reward = getRewardByBlock(sender, nodeId, blockNumber);
        require(reward > 0, 'no reward');

        uint256 fee = reward.mul(claimingFeeNumerator).div(claimingFeeDenominator);
        require(msg.value >= fee, 'invalid fee');

        feeCollector.transfer(msg.value);

        if (toStrongPool) {
            strongToken.approve(address(strongPool), reward);
            strongPool.mineFor(sender, reward);
        } else {
            strongToken.transfer(sender, reward);
        }

        rewardBalance = rewardBalance.sub(reward);
        entityNodeClaimedOnBlock[id] = blockNumber;
        emit Claimed(sender, reward);
    }

    function getRewardAll(address entity, uint256 blockNumber) public view returns (uint256) {
        uint256 rewardsAll = 0;

        for (uint128 i = 1; i <= entityNodeCount[entity]; i++) {
            rewardsAll = rewardsAll.add(getRewardByBlock(entity, i, blockNumber > 0 ? blockNumber : block.number));
        }

        return rewardsAll;
    }

    function doesNodeExist(address entity, uint128 nodeId) public view returns (bool) {
        bytes memory id = getNodeId(entity, nodeId);
        return entityNodePaidOnBlock[id] > 0;
    }

    function getNodeId(address entity, uint128 nodeId) public view returns (bytes memory) {
        uint128 id = nodeId != 0 ? nodeId : entityNodeCount[entity] + 1;
        return abi.encodePacked(entity, id);
    }

    function getNodePaidOn(address entity, uint128 nodeId) public view returns (uint256) {
        bytes memory id = getNodeId(entity, nodeId);
        return entityNodePaidOnBlock[id];
    }

    function getNodeFee(address entity, uint128 nodeId) public view returns (uint256) {
        bytes memory id = getNodeId(entity, nodeId);
        return entityNodeIsBYON[id] ? recurringFeeInWei : recurringNaaSFeeInWei;
    }

    function isNodeActive(address entity, uint128 nodeId) public view returns (bool) {
        bytes memory id = getNodeId(entity, nodeId);
        return entityNodeIsActive[id] || !entityNodeIsBYON[id];
    }

    function isNodeBYON(address entity, uint128 nodeId) public view returns (bool) {
        bytes memory id = getNodeId(entity, nodeId);
        return entityNodeIsBYON[id];
    }

    function hasLegacyNode(address entity) public view returns (bool) {
        return entityActive[entity] && entityNodeCount[entity] == 0;
    }

    function approveBYONNode(address entity, uint128 nodeId) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin, 'not admin');

        bytes memory id = getNodeId(entity, nodeId);
        entityNodeIsActive[id] = true;
        entityNodeClaimedOnBlock[id] = block.number;
        activeEntities = activeEntities.add(1);
    }

    function suspendBYONNode(address entity, uint128 nodeId) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin, 'not admin');

        bytes memory id = getNodeId(entity, nodeId);
        entityNodeIsActive[id] = false;
        activeEntities = activeEntities.sub(1);
    }

    function setNodeIsActive(address entity, uint128 nodeId, bool isActive) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin, 'not admin');
        bytes memory id = getNodeId(entity, nodeId);

        if (isActive && !entityNodeIsActive[id]) {
            activeEntities = activeEntities.add(1);
            entityNodeClaimedOnBlock[id] = block.number;
        }

        if (!isActive && entityNodeIsActive[id]) {
            activeEntities = activeEntities.sub(1);
        }

        entityNodeIsActive[id] = isActive;
    }

    function setNodeIsNaaS(address entity, uint128 nodeId, bool isNaaS) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin, 'not admin');
        bytes memory id = getNodeId(entity, nodeId);

        entityNodeIsBYON[id] = !isNaaS;
    }

    function migrateLegacyNode(address entity) private {
        bytes memory id = getNodeId(entity, 1);
        entityNodeClaimedOnBlock[id] = entityBlockLastClaimedOn[entity];
        entityNodePaidOnBlock[id] = paidOnBlock[entity];
        entityNodeTraunch[id] = traunch[entity];
        entityNodeIsBYON[id] = !entityIsNaaS[entity];
        if (entityNodeIsBYON[id]) {
            entityNodeIsActive[id] = true;
        }
        entityNodeCount[msg.sender] = 1;
    }

    function migrateNode(uint128 nodeId, address to) public {
        if (hasLegacyNode(msg.sender)) {
            migrateLegacyNode(msg.sender);
        }

        if (hasLegacyNode(to)) {
            migrateLegacyNode(to);
        }

        require(doesNodeExist(msg.sender, nodeId), 'doesnt exist');

        uint128 toNodeId = entityNodeCount[to] + 1;
        bytes memory fromId = getNodeId(msg.sender, nodeId);
        bytes memory toId = getNodeId(to, toNodeId);

        // move node to another address
        entityNodeIsActive[toId] = entityNodeIsActive[fromId];
        entityNodeIsBYON[toId] = entityNodeIsBYON[fromId];
        entityNodePaidOnBlock[toId] = entityNodePaidOnBlock[fromId];
        entityNodeClaimedOnBlock[toId] = entityNodeClaimedOnBlock[fromId];
        entityNodeTraunch[toId] = entityNodeTraunch[fromId];
        entityNodeCount[to] = entityNodeCount[to] + 1;

        // deactivate node
        entityNodeIsActive[fromId] = false;
        entityNodePaidOnBlock[fromId] = 0;
        entityNodeClaimedOnBlock[fromId] = 0;
        entityNodeCount[msg.sender] = entityNodeCount[msg.sender] - 1;

        emit Migrated(msg.sender, to, nodeId, toNodeId, entityNodeIsBYON[fromId]);
    }

    function claimAll(uint256 blockNumber, bool toStrongPool) public payable {
        for (uint16 i = 1; i <= entityNodeCount[msg.sender]; i++) {
            uint256 reward = getRewardByBlock(msg.sender, i, blockNumber);
            uint256 fee = reward.mul(claimingFeeNumerator).div(claimingFeeDenominator);
            this.claim{ value: fee }(i, blockNumber, toStrongPool);
        }
    }

    function payAll() public payable {
        for (uint16 i = 1; i <= entityNodeCount[msg.sender]; i++) {
            bytes memory id = getNodeId(msg.sender, i);
            uint256 fee = entityNodeIsBYON[id] ? recurringFeeInWei : recurringNaaSFeeInWei;
            this.payFee{ value: fee }(i);
        }
    }
}

contract ServiceV10 {
    event Requested(address indexed miner);
    event Claimed(address indexed miner, uint256 reward);

    using SafeMath for uint256;
    bool public initDone;
    address public admin;
    address public pendingAdmin;
    address public superAdmin;
    address public pendingSuperAdmin;
    address public serviceAdmin;
    address public parameterAdmin;
    address payable public feeCollector;

    IERC20 public strongToken;
    StrongPoolInterface public strongPool;

    uint256 public rewardPerBlockNumerator;
    uint256 public rewardPerBlockDenominator;

    uint256 public naasRewardPerBlockNumerator;
    uint256 public naasRewardPerBlockDenominator;

    uint256 public claimingFeeNumerator;
    uint256 public claimingFeeDenominator;

    uint256 public requestingFeeInWei;

    uint256 public strongFeeInWei;

    uint256 public recurringFeeInWei;
    uint256 public recurringNaaSFeeInWei;
    uint256 public recurringPaymentCycleInBlocks;

    uint256 public rewardBalance;

    mapping(address => uint256) public entityBlockLastClaimedOn;

    address[] public entities;
    mapping(address => uint256) public entityIndex;
    mapping(address => bool) public entityActive;
    mapping(address => bool) public requestPending;
    mapping(address => bool) public entityIsNaaS;
    mapping(address => uint256) public paidOnBlock;
    uint256 public activeEntities;

    string public desciption;

    uint256 public claimingFeeInWei;

    uint256 public naasRequestingFeeInWei;

    uint256 public naasStrongFeeInWei;

    bool public removedTokens;

    mapping(address => uint256) public traunch;

    uint256 public currentTraunch;

    mapping(bytes => bool) public entityNodeIsActive;
    mapping(bytes => bool) public entityNodeIsBYON;
    mapping(bytes => uint256) public entityNodeTraunch;
    mapping(bytes => uint256) public entityNodePaidOnBlock;
    mapping(bytes => uint256) public entityNodeClaimedOnBlock;
    mapping(address => uint128) public entityNodeCount;

    event Paid(address indexed entity, uint128 nodeId, bool isBYON, bool isRenewal, uint256 upToBlockNumber);
    event Migrated(address indexed from, address indexed to, uint128 fromNodeId, uint128 toNodeId, bool isBYON);

    uint256 public rewardPerBlockNumeratorNew;
    uint256 public rewardPerBlockDenominatorNew;
    uint256 public naasRewardPerBlockNumeratorNew;
    uint256 public naasRewardPerBlockDenominatorNew;
    uint256 public rewardPerBlockNewEffectiveBlock;

    StrongNFTBonusInterface public strongNFTBonus;

    function init(
        address strongTokenAddress,
        address strongPoolAddress,
        address adminAddress,
        address superAdminAddress,
        uint256 rewardPerBlockNumeratorValue,
        uint256 rewardPerBlockDenominatorValue,
        uint256 naasRewardPerBlockNumeratorValue,
        uint256 naasRewardPerBlockDenominatorValue,
        uint256 requestingFeeInWeiValue,
        uint256 strongFeeInWeiValue,
        uint256 recurringFeeInWeiValue,
        uint256 recurringNaaSFeeInWeiValue,
        uint256 recurringPaymentCycleInBlocksValue,
        uint256 claimingFeeNumeratorValue,
        uint256 claimingFeeDenominatorValue,
        string memory desc
    ) public {
        require(!initDone, "init done");
        strongToken = IERC20(strongTokenAddress);
        strongPool = StrongPoolInterface(strongPoolAddress);
        admin = adminAddress;
        superAdmin = superAdminAddress;
        rewardPerBlockNumerator = rewardPerBlockNumeratorValue;
        rewardPerBlockDenominator = rewardPerBlockDenominatorValue;
        naasRewardPerBlockNumerator = naasRewardPerBlockNumeratorValue;
        naasRewardPerBlockDenominator = naasRewardPerBlockDenominatorValue;
        requestingFeeInWei = requestingFeeInWeiValue;
        strongFeeInWei = strongFeeInWeiValue;
        recurringFeeInWei = recurringFeeInWeiValue;
        recurringNaaSFeeInWei = recurringNaaSFeeInWeiValue;
        claimingFeeNumerator = claimingFeeNumeratorValue;
        claimingFeeDenominator = claimingFeeDenominatorValue;
        recurringPaymentCycleInBlocks = recurringPaymentCycleInBlocksValue;
        desciption = desc;
        initDone = true;
    }

    // ADMIN
    // *************************************************************************************

    function updateServiceAdmin(address newServiceAdmin) public {
        require(msg.sender == superAdmin);
        serviceAdmin = newServiceAdmin;
    }

    function updateParameterAdmin(address newParameterAdmin) public {
        require(newParameterAdmin != address(0), "zero");
        require(msg.sender == superAdmin);
        parameterAdmin = newParameterAdmin;
    }

    function updateFeeCollector(address payable newFeeCollector) public {
        require(newFeeCollector != address(0), "zero");
        require(msg.sender == superAdmin);
        feeCollector = newFeeCollector;
    }

    function setPendingAdmin(address newPendingAdmin) public {
        require(msg.sender == admin, "not admin");
        pendingAdmin = newPendingAdmin;
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin && msg.sender != address(0), "not pendingAdmin");
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function setPendingSuperAdmin(address newPendingSuperAdmin) public {
        require(msg.sender == superAdmin, "not superAdmin");
        pendingSuperAdmin = newPendingSuperAdmin;
    }

    function acceptSuperAdmin() public {
        require(msg.sender == pendingSuperAdmin && msg.sender != address(0), "not pendingSuperAdmin");
        superAdmin = pendingSuperAdmin;
        pendingSuperAdmin = address(0);
    }

    // ENTITIES
    // *************************************************************************************

    function getEntities() public view returns (address[] memory) {
        return entities;
    }

    function isEntityActive(address entity) public view returns (bool) {
        return entityActive[entity];
    }

    // TRAUNCH
    // *************************************************************************************

    function updateCurrentTraunch(uint256 value) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");
        currentTraunch = value;
    }

    // REWARD
    // *************************************************************************************

    function updateRewardPerBlock(uint256 numerator, uint256 denominator) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");
        require(denominator != 0, "invalid value");
        rewardPerBlockNumerator = numerator;
        rewardPerBlockDenominator = denominator;
    }

    function updateNaaSRewardPerBlock(uint256 numerator, uint256 denominator) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");
        require(denominator != 0, "invalid value");
        naasRewardPerBlockNumerator = numerator;
        naasRewardPerBlockDenominator = denominator;
    }

    function updateRewardPerBlockNew(
        uint256 numerator,
        uint256 denominator,
        uint256 numeratorNass,
        uint256 denominatorNass,
        uint256 effectiveBlock
    ) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");

        rewardPerBlockNumeratorNew = numerator;
        rewardPerBlockDenominatorNew = denominator;
        naasRewardPerBlockNumeratorNew = numeratorNass;
        naasRewardPerBlockDenominatorNew = denominatorNass;
        rewardPerBlockNewEffectiveBlock = effectiveBlock != 0 ? effectiveBlock : block.number;
    }

    function deposit(uint256 amount) public {
        require(msg.sender == superAdmin, "not admin");
        require(amount > 0, "zero");
        strongToken.transferFrom(msg.sender, address(this), amount);
        rewardBalance = rewardBalance.add(amount);
    }

    function withdraw(address destination, uint256 amount) public {
        require(msg.sender == superAdmin, "not admin");
        require(amount > 0, "zero");
        require(rewardBalance >= amount, "not enough");
        strongToken.transfer(destination, amount);
        rewardBalance = rewardBalance.sub(amount);
    }

    // FEES
    // *************************************************************************************

    function updateRequestingFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");
        requestingFeeInWei = feeInWei;
    }

    function updateStrongFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");
        strongFeeInWei = feeInWei;
    }

    function updateNaasRequestingFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");
        naasRequestingFeeInWei = feeInWei;
    }

    function updateNaasStrongFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");
        naasStrongFeeInWei = feeInWei;
    }

    function updateClaimingFee(uint256 numerator, uint256 denominator) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");
        require(denominator != 0, "invalid value");
        claimingFeeNumerator = numerator;
        claimingFeeDenominator = denominator;
    }

    function updateRecurringFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");
        recurringFeeInWei = feeInWei;
    }

    function updateRecurringNaaSFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");
        recurringNaaSFeeInWei = feeInWei;
    }

    function updateRecurringPaymentCycleInBlocks(uint256 blocks) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");
        require(blocks > 0, "zero");
        recurringPaymentCycleInBlocks = blocks;
    }

    // CORE
    // *************************************************************************************

    function requestAccess(bool isNaaS) public payable {
        uint256 rFee;
        uint256 sFee;

        if (hasLegacyNode(msg.sender)) {
            migrateLegacyNode(msg.sender);
        }

        uint128 nodeId = entityNodeCount[msg.sender] + 1;
        bytes memory id = getNodeId(msg.sender, nodeId);

        if (isNaaS) {
            rFee = naasRequestingFeeInWei;
            sFee = naasStrongFeeInWei;
            activeEntities = activeEntities.add(1);
        } else {
            rFee = requestingFeeInWei;
            sFee = strongFeeInWei;
            entityNodeIsBYON[id] = true;
        }

        require(msg.value == rFee, "invalid fee");

        entityNodePaidOnBlock[id] = block.number;
        entityNodeTraunch[id] = currentTraunch;
        entityNodeClaimedOnBlock[id] = block.number;
        entityNodeCount[msg.sender] = entityNodeCount[msg.sender] + 1;

        feeCollector.transfer(msg.value);
        strongToken.transferFrom(msg.sender, address(this), sFee);
        strongToken.transfer(feeCollector, sFee);

        emit Paid(msg.sender, nodeId, entityNodeIsBYON[id], false, entityNodePaidOnBlock[id].add(recurringPaymentCycleInBlocks));
    }

    function setEntityActiveStatus(address entity, bool status) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");
        uint256 index = entityIndex[entity];
        require(entities[index] == entity, "invalid entity");
        require(entityActive[entity] != status, "already set");
        entityActive[entity] = status;
        if (status) {
            activeEntities = activeEntities.add(1);
            entityBlockLastClaimedOn[entity] = block.number;
        } else {
            activeEntities = activeEntities.sub(1);
            entityBlockLastClaimedOn[entity] = 0;
        }
    }

    function payFee(uint128 nodeId) public payable {
        address sender = msg.sender == address(this) ? tx.origin : msg.sender;
        bytes memory id = getNodeId(sender, nodeId);
        uint256 blockLastPaidOn = entityNodePaidOnBlock[id];

        if (hasLegacyNode(sender)) {
            migrateLegacyNode(sender);
        }

        bool isExpired = block.number > blockLastPaidOn.add(recurringPaymentCycleInBlocks).add(recurringPaymentCycleInBlocks);

        require(doesNodeExist(sender, nodeId), "doesnt exist");
        require(isExpired == false || msg.sender == address(this), "too late");

        if (isExpired) {
            return;
        }

        if (entityNodeIsBYON[id]) {
            require(msg.value == recurringFeeInWei, "invalid fee");
        } else {
            require(msg.value == recurringNaaSFeeInWei, "invalid fee");
        }

        feeCollector.transfer(msg.value);
        entityNodePaidOnBlock[id] = entityNodePaidOnBlock[id].add(recurringPaymentCycleInBlocks);

        emit Paid(sender, nodeId, entityNodeIsBYON[id], true, entityNodePaidOnBlock[id]);
    }

    function getReward(address entity, uint128 nodeId) public view returns (uint256) {
        return getRewardByBlock(entity, nodeId, block.number);
    }

    function getRewardByBlock(address entity, uint128 nodeId, uint256 blockNumber) public view returns (uint256) {
        bytes memory id = getNodeId(entity, nodeId);

        if (hasLegacyNode(entity)) {
            return getRewardByBlockLegacy(entity, blockNumber);
        }

        uint256 blockLastClaimedOn = entityNodeClaimedOnBlock[id] != 0 ? entityNodeClaimedOnBlock[id] : entityNodePaidOnBlock[id];

        if (blockNumber > block.number) return 0;
        if (blockLastClaimedOn == 0) return 0;
        if (blockNumber < blockLastClaimedOn) return 0;
        if (activeEntities == 0) return 0;
        if (entityNodeIsBYON[id] && !entityNodeIsActive[id]) return 0;

        uint256 rewardNumerator = entityNodeIsBYON[id] ? rewardPerBlockNumerator : naasRewardPerBlockNumerator;
        uint256 rewardDenominator = entityNodeIsBYON[id] ? rewardPerBlockDenominator : naasRewardPerBlockDenominator;
        uint256 newRewardNumerator = entityNodeIsBYON[id] ? rewardPerBlockNumeratorNew : naasRewardPerBlockNumeratorNew;
        uint256 newRewardDenominator = entityNodeIsBYON[id] ? rewardPerBlockDenominatorNew : naasRewardPerBlockDenominatorNew;

        uint256 bonus = address(strongNFTBonus) != address(0)
        ? strongNFTBonus.getBonus(entity, nodeId, blockLastClaimedOn, blockNumber)
        : 0;

        uint256[2] memory rewardBlocks = rewards.blocks(blockLastClaimedOn, rewardPerBlockNewEffectiveBlock, blockNumber);
        uint256 rewardOld = rewardDenominator > 0 ? rewardBlocks[0].mul(rewardNumerator).div(rewardDenominator) : 0;
        uint256 rewardNew = newRewardDenominator > 0 ? rewardBlocks[1].mul(newRewardNumerator).div(newRewardDenominator) : 0;

        return rewardOld.add(rewardNew).add(bonus);
    }

    function getRewardByBlockLegacy(address entity, uint256 blockNumber) public view returns (uint256) {
        if (blockNumber > block.number) return 0;
        if (entityBlockLastClaimedOn[entity] == 0) return 0;
        if (blockNumber < entityBlockLastClaimedOn[entity]) return 0;
        if (activeEntities == 0) return 0;
        uint256 blockResult = blockNumber.sub(entityBlockLastClaimedOn[entity]);
        uint256 rewardNumerator;
        uint256 rewardDenominator;
        if (entityIsNaaS[entity]) {
            rewardNumerator = naasRewardPerBlockNumerator;
            rewardDenominator = naasRewardPerBlockDenominator;
        } else {
            rewardNumerator = rewardPerBlockNumerator;
            rewardDenominator = rewardPerBlockDenominator;
        }
        uint256 rewardPerBlockResult = blockResult.mul(rewardNumerator).div(rewardDenominator);

        return rewardPerBlockResult;
    }

    function claim(uint128 nodeId, uint256 blockNumber, bool toStrongPool) public payable {
        address sender = msg.sender == address(this) || msg.sender == address(strongNFTBonus) ? tx.origin : msg.sender;
        bytes memory id = getNodeId(sender, nodeId);

        if (hasLegacyNode(sender)) {
            migrateLegacyNode(sender);
        }

        uint256 blockLastClaimedOn = entityNodeClaimedOnBlock[id] != 0 ? entityNodeClaimedOnBlock[id] : entityNodePaidOnBlock[id];
        uint256 blockLastPaidOn = entityNodePaidOnBlock[id];

        require(blockLastClaimedOn != 0, "never claimed");
        require(blockNumber <= block.number, "invalid block");
        require(blockNumber > blockLastClaimedOn, "too soon");
        require(!entityNodeIsBYON[id] || entityNodeIsActive[id], "not active");

        if (
            (!entityNodeIsBYON[id] && recurringNaaSFeeInWei != 0) || (entityNodeIsBYON[id] && recurringFeeInWei != 0)
        ) {
            require(blockNumber < blockLastPaidOn.add(recurringPaymentCycleInBlocks), "pay fee");
        }

        uint256 reward = getRewardByBlock(sender, nodeId, blockNumber);
        require(reward > 0, "no reward");

        uint256 fee = reward.mul(claimingFeeNumerator).div(claimingFeeDenominator);
        require(msg.value >= fee, "invalid fee");

        feeCollector.transfer(msg.value);

        if (toStrongPool) {
            strongToken.approve(address(strongPool), reward);
            strongPool.mineFor(sender, reward);
        } else {
            strongToken.transfer(sender, reward);
        }

        rewardBalance = rewardBalance.sub(reward);
        entityNodeClaimedOnBlock[id] = blockNumber;
        emit Claimed(sender, reward);
    }

    function getRewardAll(address entity, uint256 blockNumber) public view returns (uint256) {
        uint256 rewardsAll = 0;

        for (uint128 i = 1; i <= entityNodeCount[entity]; i++) {
            rewardsAll = rewardsAll.add(getRewardByBlock(entity, i, blockNumber > 0 ? blockNumber : block.number));
        }

        return rewardsAll;
    }

    function doesNodeExist(address entity, uint128 nodeId) public view returns (bool) {
        bytes memory id = getNodeId(entity, nodeId);
        return entityNodePaidOnBlock[id] > 0;
    }

    function getNodeId(address entity, uint128 nodeId) public view returns (bytes memory) {
        uint128 id = nodeId != 0 ? nodeId : entityNodeCount[entity] + 1;
        return abi.encodePacked(entity, id);
    }

    function getNodePaidOn(address entity, uint128 nodeId) public view returns (uint256) {
        bytes memory id = getNodeId(entity, nodeId);
        return entityNodePaidOnBlock[id];
    }

    function getNodeFee(address entity, uint128 nodeId) public view returns (uint256) {
        bytes memory id = getNodeId(entity, nodeId);
        return entityNodeIsBYON[id] ? recurringFeeInWei : recurringNaaSFeeInWei;
    }

    function isNodeActive(address entity, uint128 nodeId) public view returns (bool) {
        bytes memory id = getNodeId(entity, nodeId);
        return entityNodeIsActive[id] || !entityNodeIsBYON[id];
    }

    function isNodeBYON(address entity, uint128 nodeId) public view returns (bool) {
        bytes memory id = getNodeId(entity, nodeId);
        return entityNodeIsBYON[id];
    }

    function hasLegacyNode(address entity) public view returns (bool) {
        return entityActive[entity] && entityNodeCount[entity] == 0;
    }

    function approveBYONNode(address entity, uint128 nodeId) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");

        bytes memory id = getNodeId(entity, nodeId);
        entityNodeIsActive[id] = true;
        entityNodeClaimedOnBlock[id] = block.number;
        activeEntities = activeEntities.add(1);
    }

    function suspendBYONNode(address entity, uint128 nodeId) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");

        bytes memory id = getNodeId(entity, nodeId);
        entityNodeIsActive[id] = false;
        activeEntities = activeEntities.sub(1);
    }

    function setNodeIsActive(address entity, uint128 nodeId, bool isActive) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");
        bytes memory id = getNodeId(entity, nodeId);

        if (isActive && !entityNodeIsActive[id]) {
            activeEntities = activeEntities.add(1);
            entityNodeClaimedOnBlock[id] = block.number;
        }

        if (!isActive && entityNodeIsActive[id]) {
            activeEntities = activeEntities.sub(1);
        }

        entityNodeIsActive[id] = isActive;
    }

    function setNodeIsNaaS(address entity, uint128 nodeId, bool isNaaS) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");
        bytes memory id = getNodeId(entity, nodeId);

        entityNodeIsBYON[id] = !isNaaS;
    }

    function migrateLegacyNode(address entity) private {
        bytes memory id = getNodeId(entity, 1);
        entityNodeClaimedOnBlock[id] = entityBlockLastClaimedOn[entity];
        entityNodePaidOnBlock[id] = paidOnBlock[entity];
        entityNodeTraunch[id] = traunch[entity];
        entityNodeIsBYON[id] = !entityIsNaaS[entity];
        if (entityNodeIsBYON[id]) {
            entityNodeIsActive[id] = true;
        }
        entityNodeCount[msg.sender] = 1;
    }

    function migrateNode(uint128 nodeId, address to) public {
        if (hasLegacyNode(msg.sender)) {
            migrateLegacyNode(msg.sender);
        }

        if (hasLegacyNode(to)) {
            migrateLegacyNode(to);
        }

        require(doesNodeExist(msg.sender, nodeId), "doesnt exist");

        uint128 toNodeId = entityNodeCount[to] + 1;
        bytes memory fromId = getNodeId(msg.sender, nodeId);
        bytes memory toId = getNodeId(to, toNodeId);

        // move node to another address
        entityNodeIsActive[toId] = entityNodeIsActive[fromId];
        entityNodeIsBYON[toId] = entityNodeIsBYON[fromId];
        entityNodePaidOnBlock[toId] = entityNodePaidOnBlock[fromId];
        entityNodeClaimedOnBlock[toId] = entityNodeClaimedOnBlock[fromId];
        entityNodeTraunch[toId] = entityNodeTraunch[fromId];
        entityNodeCount[to] = entityNodeCount[to] + 1;

        // deactivate node
        entityNodeIsActive[fromId] = false;
        entityNodePaidOnBlock[fromId] = 0;
        entityNodeClaimedOnBlock[fromId] = 0;
        entityNodeCount[msg.sender] = entityNodeCount[msg.sender] - 1;

        emit Migrated(msg.sender, to, nodeId, toNodeId, entityNodeIsBYON[fromId]);
    }

    function claimAll(uint256 blockNumber, bool toStrongPool) public payable {
        for (uint16 i = 1; i <= entityNodeCount[msg.sender]; i++) {
            uint256 reward = getRewardByBlock(msg.sender, i, blockNumber);
            uint256 fee = reward.mul(claimingFeeNumerator).div(claimingFeeDenominator);
            this.claim{value : fee}(i, blockNumber, toStrongPool);
        }
    }

    function payAll() public payable {
        for (uint16 i = 1; i <= entityNodeCount[msg.sender]; i++) {
            bytes memory id = getNodeId(msg.sender, i);
            uint256 fee = entityNodeIsBYON[id] ? recurringFeeInWei : recurringNaaSFeeInWei;
            this.payFee{value : fee}(i);
        }
    }

    function addNFTBonusContract(address _contract) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");

        strongNFTBonus = StrongNFTBonusInterface(_contract);
    }
}

contract ServiceV11 {
    event Requested(address indexed miner);
    event Claimed(address indexed miner, uint256 reward);

    using SafeMath for uint256;
    bool public initDone;
    address public admin;
    address public pendingAdmin;
    address public superAdmin;
    address public pendingSuperAdmin;
    address public serviceAdmin;
    address public parameterAdmin;
    address payable public feeCollector;

    IERC20 public strongToken;
    StrongPoolInterface public strongPool;

    uint256 public rewardPerBlockNumerator;
    uint256 public rewardPerBlockDenominator;

    uint256 public naasRewardPerBlockNumerator;
    uint256 public naasRewardPerBlockDenominator;

    uint256 public claimingFeeNumerator;
    uint256 public claimingFeeDenominator;

    uint256 public requestingFeeInWei;

    uint256 public strongFeeInWei;

    uint256 public recurringFeeInWei;
    uint256 public recurringNaaSFeeInWei;
    uint256 public recurringPaymentCycleInBlocks;

    uint256 public rewardBalance;

    mapping(address => uint256) public entityBlockLastClaimedOn;

    address[] public entities;
    mapping(address => uint256) public entityIndex;
    mapping(address => bool) public entityActive;
    mapping(address => bool) public requestPending;
    mapping(address => bool) public entityIsNaaS;
    mapping(address => uint256) public paidOnBlock;
    uint256 public activeEntities;

    string public desciption;

    uint256 public claimingFeeInWei;

    uint256 public naasRequestingFeeInWei;

    uint256 public naasStrongFeeInWei;

    bool public removedTokens;

    mapping(address => uint256) public traunch;

    uint256 public currentTraunch;

    mapping(bytes => bool) public entityNodeIsActive;
    mapping(bytes => bool) public entityNodeIsBYON;
    mapping(bytes => uint256) public entityNodeTraunch;
    mapping(bytes => uint256) public entityNodePaidOnBlock;
    mapping(bytes => uint256) public entityNodeClaimedOnBlock;
    mapping(address => uint128) public entityNodeCount;

    event Paid(address indexed entity, uint128 nodeId, bool isBYON, bool isRenewal, uint256 upToBlockNumber);
    event Migrated(address indexed from, address indexed to, uint128 fromNodeId, uint128 toNodeId, bool isBYON);

    uint256 public rewardPerBlockNumeratorNew;
    uint256 public rewardPerBlockDenominatorNew;
    uint256 public naasRewardPerBlockNumeratorNew;
    uint256 public naasRewardPerBlockDenominatorNew;
    uint256 public rewardPerBlockNewEffectiveBlock;

    StrongNFTBonusInterface public strongNFTBonus;

    uint256 public gracePeriodInBlocks;

    function init(
        address strongTokenAddress,
        address strongPoolAddress,
        address adminAddress,
        address superAdminAddress,
        uint256 rewardPerBlockNumeratorValue,
        uint256 rewardPerBlockDenominatorValue,
        uint256 naasRewardPerBlockNumeratorValue,
        uint256 naasRewardPerBlockDenominatorValue,
        uint256 requestingFeeInWeiValue,
        uint256 strongFeeInWeiValue,
        uint256 recurringFeeInWeiValue,
        uint256 recurringNaaSFeeInWeiValue,
        uint256 recurringPaymentCycleInBlocksValue,
        uint256 claimingFeeNumeratorValue,
        uint256 claimingFeeDenominatorValue,
        string memory desc
    ) public {
        require(!initDone, "init done");
        strongToken = IERC20(strongTokenAddress);
        strongPool = StrongPoolInterface(strongPoolAddress);
        admin = adminAddress;
        superAdmin = superAdminAddress;
        rewardPerBlockNumerator = rewardPerBlockNumeratorValue;
        rewardPerBlockDenominator = rewardPerBlockDenominatorValue;
        naasRewardPerBlockNumerator = naasRewardPerBlockNumeratorValue;
        naasRewardPerBlockDenominator = naasRewardPerBlockDenominatorValue;
        requestingFeeInWei = requestingFeeInWeiValue;
        strongFeeInWei = strongFeeInWeiValue;
        recurringFeeInWei = recurringFeeInWeiValue;
        recurringNaaSFeeInWei = recurringNaaSFeeInWeiValue;
        claimingFeeNumerator = claimingFeeNumeratorValue;
        claimingFeeDenominator = claimingFeeDenominatorValue;
        recurringPaymentCycleInBlocks = recurringPaymentCycleInBlocksValue;
        desciption = desc;
        initDone = true;
    }

    // ADMIN
    // *************************************************************************************

    function updateServiceAdmin(address newServiceAdmin) public {
        require(msg.sender == superAdmin);
        serviceAdmin = newServiceAdmin;
    }

    function updateParameterAdmin(address newParameterAdmin) public {
        require(newParameterAdmin != address(0), "zero");
        require(msg.sender == superAdmin);
        parameterAdmin = newParameterAdmin;
    }

    function updateFeeCollector(address payable newFeeCollector) public {
        require(newFeeCollector != address(0), "zero");
        require(msg.sender == superAdmin);
        feeCollector = newFeeCollector;
    }

    function setPendingAdmin(address newPendingAdmin) public {
        require(msg.sender == admin, "not admin");
        pendingAdmin = newPendingAdmin;
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin && msg.sender != address(0), "not pendingAdmin");
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function setPendingSuperAdmin(address newPendingSuperAdmin) public {
        require(msg.sender == superAdmin, "not superAdmin");
        pendingSuperAdmin = newPendingSuperAdmin;
    }

    function acceptSuperAdmin() public {
        require(msg.sender == pendingSuperAdmin && msg.sender != address(0), "not pendingSuperAdmin");
        superAdmin = pendingSuperAdmin;
        pendingSuperAdmin = address(0);
    }

    // ENTITIES
    // *************************************************************************************

    function isEntityActive(address entity) public view returns (bool) {
        return entityActive[entity] || (doesNodeExist(entity, 1) && !hasNodeExpired(entity, 1));
    }

    // REWARD
    // *************************************************************************************

    function updateRewardPerBlock(uint256 numerator, uint256 denominator) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");
        require(denominator != 0, "invalid value");
        rewardPerBlockNumerator = numerator;
        rewardPerBlockDenominator = denominator;
    }

    function updateNaaSRewardPerBlock(uint256 numerator, uint256 denominator) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");
        require(denominator != 0, "invalid value");
        naasRewardPerBlockNumerator = numerator;
        naasRewardPerBlockDenominator = denominator;
    }

    function updateRewardPerBlockNew(
        uint256 numerator,
        uint256 denominator,
        uint256 numeratorNass,
        uint256 denominatorNass,
        uint256 effectiveBlock
    ) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");

        rewardPerBlockNumeratorNew = numerator;
        rewardPerBlockDenominatorNew = denominator;
        naasRewardPerBlockNumeratorNew = numeratorNass;
        naasRewardPerBlockDenominatorNew = denominatorNass;
        rewardPerBlockNewEffectiveBlock = effectiveBlock != 0 ? effectiveBlock : block.number;
    }

    function deposit(uint256 amount) public {
        require(msg.sender == superAdmin, "not admin");
        require(amount > 0, "zero");
        strongToken.transferFrom(msg.sender, address(this), amount);
        rewardBalance = rewardBalance.add(amount);
    }

    function withdraw(address destination, uint256 amount) public {
        require(msg.sender == superAdmin, "not admin");
        require(amount > 0, "zero");
        require(rewardBalance >= amount, "not enough");
        strongToken.transfer(destination, amount);
        rewardBalance = rewardBalance.sub(amount);
    }

    // FEES
    // *************************************************************************************

    function updateRequestingFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");
        requestingFeeInWei = feeInWei;
    }

    function updateStrongFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");
        strongFeeInWei = feeInWei;
    }

    function updateNaasRequestingFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");
        naasRequestingFeeInWei = feeInWei;
    }

    function updateNaasStrongFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");
        naasStrongFeeInWei = feeInWei;
    }

    function updateClaimingFee(uint256 numerator, uint256 denominator) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");
        require(denominator != 0, "invalid value");
        claimingFeeNumerator = numerator;
        claimingFeeDenominator = denominator;
    }

    function updateRecurringFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");
        recurringFeeInWei = feeInWei;
    }

    function updateRecurringNaaSFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");
        recurringNaaSFeeInWei = feeInWei;
    }

    function updateRecurringPaymentCycleInBlocks(uint256 blocks) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");
        require(blocks > 0, "zero");
        recurringPaymentCycleInBlocks = blocks;
    }

    function updateGracePeriodInBlocks(uint256 blocks) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");
        require(blocks > 0, "zero");
        gracePeriodInBlocks = blocks;
    }

    // CORE
    // *************************************************************************************

    function requestAccess(bool isNaaS) public payable {
        uint256 rFee;
        uint256 sFee;

        if (hasLegacyNode(msg.sender)) {
            migrateLegacyNode(msg.sender);
        }

        uint128 nodeId = entityNodeCount[msg.sender] + 1;
        bytes memory id = getNodeId(msg.sender, nodeId);

        if (isNaaS) {
            rFee = naasRequestingFeeInWei;
            sFee = naasStrongFeeInWei;
            activeEntities = activeEntities.add(1);
        } else {
            rFee = requestingFeeInWei;
            sFee = strongFeeInWei;
            entityNodeIsBYON[id] = true;
        }

        require(msg.value == rFee, "invalid fee");

        entityNodePaidOnBlock[id] = block.number;
        entityNodeClaimedOnBlock[id] = block.number;
        entityNodeCount[msg.sender] = entityNodeCount[msg.sender] + 1;

        feeCollector.transfer(msg.value);
        strongToken.transferFrom(msg.sender, address(this), sFee);
        strongToken.transfer(feeCollector, sFee);

        emit Paid(msg.sender, nodeId, entityNodeIsBYON[id], false, entityNodePaidOnBlock[id].add(recurringPaymentCycleInBlocks));
    }

    function setEntityActiveStatus(address entity, bool status) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");
        uint256 index = entityIndex[entity];
        require(entities[index] == entity, "invalid entity");
        require(entityActive[entity] != status, "already set");
        entityActive[entity] = status;
        if (status) {
            activeEntities = activeEntities.add(1);
            entityBlockLastClaimedOn[entity] = block.number;
        } else {
            activeEntities = activeEntities.sub(1);
            entityBlockLastClaimedOn[entity] = 0;
        }
    }

    function payFee(uint128 nodeId) public payable {
        address sender = msg.sender == address(this) ? tx.origin : msg.sender;
        bytes memory id = getNodeId(sender, nodeId);

        if (hasLegacyNode(sender)) {
            migrateLegacyNode(sender);
        }

        bool isExpired = hasNodeExpired(msg.sender, nodeId);

        require(doesNodeExist(sender, nodeId), "doesnt exist");
        require(isExpired == false || msg.sender == address(this), "too late");

        if (isExpired) {
            return;
        }

        if (entityNodeIsBYON[id]) {
            require(msg.value == recurringFeeInWei, "invalid fee");
        } else {
            require(msg.value == recurringNaaSFeeInWei, "invalid fee");
        }

        feeCollector.transfer(msg.value);
        entityNodePaidOnBlock[id] = entityNodePaidOnBlock[id].add(recurringPaymentCycleInBlocks);

        emit Paid(sender, nodeId, entityNodeIsBYON[id], true, entityNodePaidOnBlock[id]);
    }

    function getReward(address entity, uint128 nodeId) public view returns (uint256) {
        return getRewardByBlock(entity, nodeId, block.number);
    }

    function getRewardByBlock(address entity, uint128 nodeId, uint256 blockNumber) public view returns (uint256) {
        bytes memory id = getNodeId(entity, nodeId);

        if (hasLegacyNode(entity)) {
            return getRewardByBlockLegacy(entity, blockNumber);
        }

        uint256 blockLastClaimedOn = entityNodeClaimedOnBlock[id] != 0 ? entityNodeClaimedOnBlock[id] : entityNodePaidOnBlock[id];

        if (blockNumber > block.number) return 0;
        if (blockLastClaimedOn == 0) return 0;
        if (blockNumber < blockLastClaimedOn) return 0;
        if (activeEntities == 0) return 0;
        if (entityNodeIsBYON[id] && !entityNodeIsActive[id]) return 0;

        uint256 rewardNumerator = entityNodeIsBYON[id] ? rewardPerBlockNumerator : naasRewardPerBlockNumerator;
        uint256 rewardDenominator = entityNodeIsBYON[id] ? rewardPerBlockDenominator : naasRewardPerBlockDenominator;
        uint256 newRewardNumerator = entityNodeIsBYON[id] ? rewardPerBlockNumeratorNew : naasRewardPerBlockNumeratorNew;
        uint256 newRewardDenominator = entityNodeIsBYON[id] ? rewardPerBlockDenominatorNew : naasRewardPerBlockDenominatorNew;

        uint256 bonus = address(strongNFTBonus) != address(0)
        ? strongNFTBonus.getBonus(entity, nodeId, blockLastClaimedOn, blockNumber)
        : 0;

        uint256[2] memory rewardBlocks = rewards.blocks(blockLastClaimedOn, rewardPerBlockNewEffectiveBlock, blockNumber);
        uint256 rewardOld = rewardDenominator > 0 ? rewardBlocks[0].mul(rewardNumerator).div(rewardDenominator) : 0;
        uint256 rewardNew = newRewardDenominator > 0 ? rewardBlocks[1].mul(newRewardNumerator).div(newRewardDenominator) : 0;

        return rewardOld.add(rewardNew).add(bonus);
    }

    function getRewardByBlockLegacy(address entity, uint256 blockNumber) public view returns (uint256) {
        if (blockNumber > block.number) return 0;
        if (entityBlockLastClaimedOn[entity] == 0) return 0;
        if (blockNumber < entityBlockLastClaimedOn[entity]) return 0;
        if (activeEntities == 0) return 0;
        uint256 blockResult = blockNumber.sub(entityBlockLastClaimedOn[entity]);
        uint256 rewardNumerator;
        uint256 rewardDenominator;
        if (entityIsNaaS[entity]) {
            rewardNumerator = naasRewardPerBlockNumerator;
            rewardDenominator = naasRewardPerBlockDenominator;
        } else {
            rewardNumerator = rewardPerBlockNumerator;
            rewardDenominator = rewardPerBlockDenominator;
        }
        uint256 rewardPerBlockResult = blockResult.mul(rewardNumerator).div(rewardDenominator);

        return rewardPerBlockResult;
    }

    function claim(uint128 nodeId, uint256 blockNumber, bool toStrongPool) public payable {
        address sender = msg.sender == address(this) || msg.sender == address(strongNFTBonus) ? tx.origin : msg.sender;
        bytes memory id = getNodeId(sender, nodeId);

        if (hasLegacyNode(sender)) {
            migrateLegacyNode(sender);
        }

        uint256 blockLastClaimedOn = entityNodeClaimedOnBlock[id] != 0 ? entityNodeClaimedOnBlock[id] : entityNodePaidOnBlock[id];
        uint256 blockLastPaidOn = entityNodePaidOnBlock[id];

        require(blockLastClaimedOn != 0, "never claimed");
        require(blockNumber <= block.number, "invalid block");
        require(blockNumber > blockLastClaimedOn, "too soon");
        require(!entityNodeIsBYON[id] || entityNodeIsActive[id], "not active");

        if (
            (!entityNodeIsBYON[id] && recurringNaaSFeeInWei != 0) || (entityNodeIsBYON[id] && recurringFeeInWei != 0)
        ) {
            require(blockNumber < blockLastPaidOn.add(recurringPaymentCycleInBlocks), "pay fee");
        }

        uint256 reward = getRewardByBlock(sender, nodeId, blockNumber);
        require(reward > 0, "no reward");

        uint256 fee = reward.mul(claimingFeeNumerator).div(claimingFeeDenominator);
        require(msg.value >= fee, "invalid fee");

        feeCollector.transfer(msg.value);

        if (toStrongPool) {
            strongToken.approve(address(strongPool), reward);
            strongPool.mineFor(sender, reward);
        } else {
            strongToken.transfer(sender, reward);
        }

        rewardBalance = rewardBalance.sub(reward);
        entityNodeClaimedOnBlock[id] = blockNumber;
        emit Claimed(sender, reward);
    }

    function getRewardAll(address entity, uint256 blockNumber) public view returns (uint256) {
        uint256 rewardsAll = 0;

        for (uint128 i = 1; i <= entityNodeCount[entity]; i++) {
            rewardsAll = rewardsAll.add(getRewardByBlock(entity, i, blockNumber > 0 ? blockNumber : block.number));
        }

        return rewardsAll;
    }

    function doesNodeExist(address entity, uint128 nodeId) public view returns (bool) {
        bytes memory id = getNodeId(entity, nodeId);
        return entityNodePaidOnBlock[id] > 0;
    }

    function hasNodeExpired(address entity, uint128 nodeId) public view returns (bool) {
        bytes memory id = getNodeId(entity, nodeId);
        uint256 blockLastPaidOn = entityNodePaidOnBlock[id];
        return block.number > blockLastPaidOn.add(recurringPaymentCycleInBlocks).add(gracePeriodInBlocks);
    }

    function getNodeId(address entity, uint128 nodeId) public view returns (bytes memory) {
        uint128 id = nodeId != 0 ? nodeId : entityNodeCount[entity] + 1;
        return abi.encodePacked(entity, id);
    }

    function getNodePaidOn(address entity, uint128 nodeId) public view returns (uint256) {
        bytes memory id = getNodeId(entity, nodeId);
        return entityNodePaidOnBlock[id];
    }

    function getNodeFee(address entity, uint128 nodeId) public view returns (uint256) {
        bytes memory id = getNodeId(entity, nodeId);
        return entityNodeIsBYON[id] ? recurringFeeInWei : recurringNaaSFeeInWei;
    }

    function isNodeActive(address entity, uint128 nodeId) public view returns (bool) {
        bytes memory id = getNodeId(entity, nodeId);
        return entityNodeIsActive[id] || !entityNodeIsBYON[id];
    }

    function isNodeBYON(address entity, uint128 nodeId) public view returns (bool) {
        bytes memory id = getNodeId(entity, nodeId);
        return entityNodeIsBYON[id];
    }

    function hasLegacyNode(address entity) public view returns (bool) {
        return entityActive[entity] && entityNodeCount[entity] == 0;
    }

    function approveBYONNode(address entity, uint128 nodeId) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");

        bytes memory id = getNodeId(entity, nodeId);
        entityNodeIsActive[id] = true;
        entityNodeClaimedOnBlock[id] = block.number;
        activeEntities = activeEntities.add(1);
    }

    function suspendBYONNode(address entity, uint128 nodeId) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");

        bytes memory id = getNodeId(entity, nodeId);
        entityNodeIsActive[id] = false;
        activeEntities = activeEntities.sub(1);
    }

    function setNodeIsActive(address entity, uint128 nodeId, bool isActive) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");
        bytes memory id = getNodeId(entity, nodeId);

        if (isActive && !entityNodeIsActive[id]) {
            activeEntities = activeEntities.add(1);
            entityNodeClaimedOnBlock[id] = block.number;
        }

        if (!isActive && entityNodeIsActive[id]) {
            activeEntities = activeEntities.sub(1);
        }

        entityNodeIsActive[id] = isActive;
    }

    function setNodeIsNaaS(address entity, uint128 nodeId, bool isNaaS) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");
        bytes memory id = getNodeId(entity, nodeId);

        entityNodeIsBYON[id] = !isNaaS;
    }

    function migrateLegacyNode(address entity) private {
        bytes memory id = getNodeId(entity, 1);
        entityNodeClaimedOnBlock[id] = entityBlockLastClaimedOn[entity];
        entityNodePaidOnBlock[id] = paidOnBlock[entity];
        entityNodeIsBYON[id] = !entityIsNaaS[entity];
        if (entityNodeIsBYON[id]) {
            entityNodeIsActive[id] = true;
        }
        entityNodeCount[msg.sender] = 1;
    }

    function migrateNode(uint128 nodeId, address to) public {
        if (hasLegacyNode(msg.sender)) {
            migrateLegacyNode(msg.sender);
        }

        if (hasLegacyNode(to)) {
            migrateLegacyNode(to);
        }

        require(doesNodeExist(msg.sender, nodeId), "doesnt exist");

        uint128 toNodeId = entityNodeCount[to] + 1;
        bytes memory fromId = getNodeId(msg.sender, nodeId);
        bytes memory toId = getNodeId(to, toNodeId);

        // move node to another address
        entityNodeIsActive[toId] = entityNodeIsActive[fromId];
        entityNodeIsBYON[toId] = entityNodeIsBYON[fromId];
        entityNodePaidOnBlock[toId] = entityNodePaidOnBlock[fromId];
        entityNodeClaimedOnBlock[toId] = entityNodeClaimedOnBlock[fromId];
        entityNodeCount[to] = entityNodeCount[to] + 1;

        // deactivate node
        entityNodeIsActive[fromId] = false;
        entityNodePaidOnBlock[fromId] = 0;
        entityNodeClaimedOnBlock[fromId] = 0;
        entityNodeCount[msg.sender] = entityNodeCount[msg.sender] - 1;

        emit Migrated(msg.sender, to, nodeId, toNodeId, entityNodeIsBYON[fromId]);
    }

    function claimAll(uint256 blockNumber, bool toStrongPool) public payable {
        for (uint16 i = 1; i <= entityNodeCount[msg.sender]; i++) {
            uint256 reward = getRewardByBlock(msg.sender, i, blockNumber);
            uint256 fee = reward.mul(claimingFeeNumerator).div(claimingFeeDenominator);
            this.claim{value : fee}(i, blockNumber, toStrongPool);
        }
    }

    function payAll() public payable {
        for (uint16 i = 1; i <= entityNodeCount[msg.sender]; i++) {
            bytes memory id = getNodeId(msg.sender, i);
            uint256 fee = entityNodeIsBYON[id] ? recurringFeeInWei : recurringNaaSFeeInWei;
            this.payFee{value : fee}(i);
        }
    }

    function addNFTBonusContract(address _contract) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");

        strongNFTBonus = StrongNFTBonusInterface(_contract);
    }
}

contract ServiceV12 {
    event Requested(address indexed miner);
    event Claimed(address indexed miner, uint256 reward);

    using SafeMath for uint256;
    bool public initDone;
    address public admin;
    address public pendingAdmin;
    address public superAdmin;
    address public pendingSuperAdmin;
    address public serviceAdmin;
    address public parameterAdmin;
    address payable public feeCollector;

    IERC20 public strongToken;
    StrongPoolInterface public strongPool;

    uint256 public rewardPerBlockNumerator;
    uint256 public rewardPerBlockDenominator;

    uint256 public naasRewardPerBlockNumerator;
    uint256 public naasRewardPerBlockDenominator;

    uint256 public claimingFeeNumerator;
    uint256 public claimingFeeDenominator;

    uint256 public requestingFeeInWei;

    uint256 public strongFeeInWei;

    uint256 public recurringFeeInWei;
    uint256 public recurringNaaSFeeInWei;
    uint256 public recurringPaymentCycleInBlocks;

    uint256 public rewardBalance;

    mapping(address => uint256) public entityBlockLastClaimedOn;

    address[] public entities;
    mapping(address => uint256) public entityIndex;
    mapping(address => bool) public entityActive;
    mapping(address => bool) public requestPending;
    mapping(address => bool) public entityIsNaaS;
    mapping(address => uint256) public paidOnBlock;
    uint256 public activeEntities;

    string public desciption;

    uint256 public claimingFeeInWei;

    uint256 public naasRequestingFeeInWei;

    uint256 public naasStrongFeeInWei;

    bool public removedTokens;

    mapping(address => uint256) public traunch;

    uint256 public currentTraunch;

    mapping(bytes => bool) public entityNodeIsActive;
    mapping(bytes => bool) public entityNodeIsBYON;
    mapping(bytes => uint256) public entityNodeTraunch;
    mapping(bytes => uint256) public entityNodePaidOnBlock;
    mapping(bytes => uint256) public entityNodeClaimedOnBlock;
    mapping(address => uint128) public entityNodeCount;

    event Paid(address indexed entity, uint128 nodeId, bool isBYON, bool isRenewal, uint256 upToBlockNumber);
    event Migrated(address indexed from, address indexed to, uint128 fromNodeId, uint128 toNodeId, bool isBYON);

    uint256 public rewardPerBlockNumeratorNew;
    uint256 public rewardPerBlockDenominatorNew;
    uint256 public naasRewardPerBlockNumeratorNew;
    uint256 public naasRewardPerBlockDenominatorNew;
    uint256 public rewardPerBlockNewEffectiveBlock;

    StrongNFTBonusInterface public strongNFTBonus;

    uint256 public gracePeriodInBlocks;

    function init(
        address strongTokenAddress,
        address strongPoolAddress,
        address adminAddress,
        address superAdminAddress,
        uint256 rewardPerBlockNumeratorValue,
        uint256 rewardPerBlockDenominatorValue,
        uint256 naasRewardPerBlockNumeratorValue,
        uint256 naasRewardPerBlockDenominatorValue,
        uint256 requestingFeeInWeiValue,
        uint256 strongFeeInWeiValue,
        uint256 recurringFeeInWeiValue,
        uint256 recurringNaaSFeeInWeiValue,
        uint256 recurringPaymentCycleInBlocksValue,
        uint256 claimingFeeNumeratorValue,
        uint256 claimingFeeDenominatorValue,
        string memory desc
    ) public {
        require(!initDone, "init done");
        strongToken = IERC20(strongTokenAddress);
        strongPool = StrongPoolInterface(strongPoolAddress);
        admin = adminAddress;
        superAdmin = superAdminAddress;
        rewardPerBlockNumerator = rewardPerBlockNumeratorValue;
        rewardPerBlockDenominator = rewardPerBlockDenominatorValue;
        naasRewardPerBlockNumerator = naasRewardPerBlockNumeratorValue;
        naasRewardPerBlockDenominator = naasRewardPerBlockDenominatorValue;
        requestingFeeInWei = requestingFeeInWeiValue;
        strongFeeInWei = strongFeeInWeiValue;
        recurringFeeInWei = recurringFeeInWeiValue;
        recurringNaaSFeeInWei = recurringNaaSFeeInWeiValue;
        claimingFeeNumerator = claimingFeeNumeratorValue;
        claimingFeeDenominator = claimingFeeDenominatorValue;
        recurringPaymentCycleInBlocks = recurringPaymentCycleInBlocksValue;
        desciption = desc;
        initDone = true;
    }

    function updateServiceAdmin(address newServiceAdmin) public {
        require(msg.sender == superAdmin);
        serviceAdmin = newServiceAdmin;
    }

    function updateParameterAdmin(address newParameterAdmin) public {
        require(newParameterAdmin != address(0));
        require(msg.sender == superAdmin);
        parameterAdmin = newParameterAdmin;
    }

    function updateFeeCollector(address payable newFeeCollector) public {
        require(newFeeCollector != address(0));
        require(msg.sender == superAdmin);
        feeCollector = newFeeCollector;
    }

    function setPendingAdmin(address newPendingAdmin) public {
        require(msg.sender == admin);
        pendingAdmin = newPendingAdmin;
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin && msg.sender != address(0), "not pendingAdmin");
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function setPendingSuperAdmin(address newPendingSuperAdmin) public {
        require(msg.sender == superAdmin, "not superAdmin");
        pendingSuperAdmin = newPendingSuperAdmin;
    }

    function acceptSuperAdmin() public {
        require(msg.sender == pendingSuperAdmin && msg.sender != address(0), "not pendingSuperAdmin");
        superAdmin = pendingSuperAdmin;
        pendingSuperAdmin = address(0);
    }

    function isEntityActive(address entity) public view returns (bool) {
        return entityActive[entity] || (doesNodeExist(entity, 1) && !hasNodeExpired(entity, 1));
    }

    function updateRewardPerBlock(uint256 numerator, uint256 denominator) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
        require(denominator != 0);
        rewardPerBlockNumerator = numerator;
        rewardPerBlockDenominator = denominator;
    }

    function updateNaaSRewardPerBlock(uint256 numerator, uint256 denominator) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
        require(denominator != 0);
        naasRewardPerBlockNumerator = numerator;
        naasRewardPerBlockDenominator = denominator;
    }

    function updateRewardPerBlockNew(
        uint256 numerator,
        uint256 denominator,
        uint256 numeratorNass,
        uint256 denominatorNass,
        uint256 effectiveBlock
    ) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);

        rewardPerBlockNumeratorNew = numerator;
        rewardPerBlockDenominatorNew = denominator;
        naasRewardPerBlockNumeratorNew = numeratorNass;
        naasRewardPerBlockDenominatorNew = denominatorNass;
        rewardPerBlockNewEffectiveBlock = effectiveBlock != 0 ? effectiveBlock : block.number;
    }

    function deposit(uint256 amount) public {
        require(msg.sender == superAdmin);
        require(amount > 0);
        strongToken.transferFrom(msg.sender, address(this), amount);
        rewardBalance = rewardBalance.add(amount);
    }

    function withdraw(address destination, uint256 amount) public {
        require(msg.sender == superAdmin);
        require(amount > 0);
        require(rewardBalance >= amount, "not enough");
        strongToken.transfer(destination, amount);
        rewardBalance = rewardBalance.sub(amount);
    }

    function updateRequestingFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
        requestingFeeInWei = feeInWei;
    }

    function updateStrongFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
        strongFeeInWei = feeInWei;
    }

    function updateNaasRequestingFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
        naasRequestingFeeInWei = feeInWei;
    }

    function updateNaasStrongFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
        naasStrongFeeInWei = feeInWei;
    }

    function updateClaimingFee(uint256 numerator, uint256 denominator) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
        require(denominator != 0);
        claimingFeeNumerator = numerator;
        claimingFeeDenominator = denominator;
    }

    function updateRecurringFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
        recurringFeeInWei = feeInWei;
    }

    function updateRecurringNaaSFee(uint256 feeInWei) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
        recurringNaaSFeeInWei = feeInWei;
    }

    function updateRecurringPaymentCycleInBlocks(uint256 blocks) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
        require(blocks > 0);
        recurringPaymentCycleInBlocks = blocks;
    }

    function updateGracePeriodInBlocks(uint256 blocks) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin);
        require(blocks > 0);
        gracePeriodInBlocks = blocks;
    }

    function requestAccess(bool isNaaS) public payable {
        uint256 rFee;
        uint256 sFee;

        if (hasLegacyNode(msg.sender)) {
            migrateLegacyNode(msg.sender);
        }

        uint128 nodeId = entityNodeCount[msg.sender] + 1;
        bytes memory id = getNodeId(msg.sender, nodeId);

        if (isNaaS) {
            rFee = naasRequestingFeeInWei;
            sFee = naasStrongFeeInWei;
            activeEntities = activeEntities.add(1);
        } else {
            rFee = requestingFeeInWei;
            sFee = strongFeeInWei;
            entityNodeIsBYON[id] = true;
        }

        require(msg.value == rFee, "invalid fee");

        entityNodePaidOnBlock[id] = block.number;
        entityNodeClaimedOnBlock[id] = block.number;
        entityNodeCount[msg.sender] = entityNodeCount[msg.sender] + 1;

        feeCollector.transfer(msg.value);
        strongToken.transferFrom(msg.sender, address(this), sFee);
        strongToken.transfer(feeCollector, sFee);

        emit Paid(msg.sender, nodeId, entityNodeIsBYON[id], false, entityNodePaidOnBlock[id].add(recurringPaymentCycleInBlocks));
    }

    function setEntityActiveStatus(address entity, bool status) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin);
        uint256 index = entityIndex[entity];
        require(entities[index] == entity, "invalid entity");
        require(entityActive[entity] != status, "already set");
        entityActive[entity] = status;
        if (status) {
            activeEntities = activeEntities.add(1);
            entityBlockLastClaimedOn[entity] = block.number;
        } else {
            activeEntities = activeEntities.sub(1);
            entityBlockLastClaimedOn[entity] = 0;
        }
    }

    function payFee(uint128 nodeId) public payable {
        address sender = msg.sender == address(this) ? tx.origin : msg.sender;
        bytes memory id = getNodeId(sender, nodeId);

        if (hasLegacyNode(sender)) {
            migrateLegacyNode(sender);
        }

        bool isExpired = hasNodeExpired(sender, nodeId);

        require(doesNodeExist(sender, nodeId), "doesnt exist");
        require(isExpired == false || msg.sender == address(this), "too late");

        if (isExpired) {
            return;
        }

        if (entityNodeIsBYON[id]) {
            require(msg.value == recurringFeeInWei, "invalid fee");
        } else {
            require(msg.value == recurringNaaSFeeInWei, "invalid fee");
        }

        feeCollector.transfer(msg.value);
        entityNodePaidOnBlock[id] = entityNodePaidOnBlock[id].add(recurringPaymentCycleInBlocks);

        emit Paid(sender, nodeId, entityNodeIsBYON[id], true, entityNodePaidOnBlock[id]);
    }

    function getReward(address entity, uint128 nodeId) public view returns (uint256) {
        return getRewardByBlock(entity, nodeId, block.number);
    }

    function getRewardByBlock(address entity, uint128 nodeId, uint256 blockNumber) public view returns (uint256) {
        bytes memory id = getNodeId(entity, nodeId);

        if (hasLegacyNode(entity)) {
            return getRewardByBlockLegacy(entity, blockNumber);
        }

        uint256 blockLastClaimedOn = entityNodeClaimedOnBlock[id] != 0 ? entityNodeClaimedOnBlock[id] : entityNodePaidOnBlock[id];

        if (blockNumber > block.number) return 0;
        if (blockLastClaimedOn == 0) return 0;
        if (blockNumber < blockLastClaimedOn) return 0;
        if (activeEntities == 0) return 0;
        if (entityNodeIsBYON[id] && !entityNodeIsActive[id]) return 0;

        uint256 rewardNumerator = entityNodeIsBYON[id] ? rewardPerBlockNumerator : naasRewardPerBlockNumerator;
        uint256 rewardDenominator = entityNodeIsBYON[id] ? rewardPerBlockDenominator : naasRewardPerBlockDenominator;
        uint256 newRewardNumerator = entityNodeIsBYON[id] ? rewardPerBlockNumeratorNew : naasRewardPerBlockNumeratorNew;
        uint256 newRewardDenominator = entityNodeIsBYON[id] ? rewardPerBlockDenominatorNew : naasRewardPerBlockDenominatorNew;

        uint256 bonus = address(strongNFTBonus) != address(0)
        ? strongNFTBonus.getBonus(entity, nodeId, blockLastClaimedOn, blockNumber)
        : 0;

        uint256[2] memory rewardBlocks = rewards.blocks(blockLastClaimedOn, rewardPerBlockNewEffectiveBlock, blockNumber);
        uint256 rewardOld = rewardDenominator > 0 ? rewardBlocks[0].mul(rewardNumerator).div(rewardDenominator) : 0;
        uint256 rewardNew = newRewardDenominator > 0 ? rewardBlocks[1].mul(newRewardNumerator).div(newRewardDenominator) : 0;

        return rewardOld.add(rewardNew).add(bonus);
    }

    function getRewardByBlockLegacy(address entity, uint256 blockNumber) public view returns (uint256) {
        if (blockNumber > block.number) return 0;
        if (entityBlockLastClaimedOn[entity] == 0) return 0;
        if (blockNumber < entityBlockLastClaimedOn[entity]) return 0;
        if (activeEntities == 0) return 0;
        uint256 blockResult = blockNumber.sub(entityBlockLastClaimedOn[entity]);
        uint256 rewardNumerator;
        uint256 rewardDenominator;
        if (entityIsNaaS[entity]) {
            rewardNumerator = naasRewardPerBlockNumerator;
            rewardDenominator = naasRewardPerBlockDenominator;
        } else {
            rewardNumerator = rewardPerBlockNumerator;
            rewardDenominator = rewardPerBlockDenominator;
        }
        uint256 rewardPerBlockResult = blockResult.mul(rewardNumerator).div(rewardDenominator);

        return rewardPerBlockResult;
    }

    function claim(uint128 nodeId, uint256 blockNumber, bool toStrongPool) public payable {
        address sender = msg.sender == address(this) || msg.sender == address(strongNFTBonus) ? tx.origin : msg.sender;
        bytes memory id = getNodeId(sender, nodeId);

        if (hasLegacyNode(sender)) {
            migrateLegacyNode(sender);
        }

        uint256 blockLastClaimedOn = entityNodeClaimedOnBlock[id] != 0 ? entityNodeClaimedOnBlock[id] : entityNodePaidOnBlock[id];
        uint256 blockLastPaidOn = entityNodePaidOnBlock[id];

        require(blockLastClaimedOn != 0, "never claimed");
        require(blockNumber <= block.number, "invalid block");
        require(blockNumber > blockLastClaimedOn, "too soon");
        require(!entityNodeIsBYON[id] || entityNodeIsActive[id], "not active");

        if (
            (!entityNodeIsBYON[id] && recurringNaaSFeeInWei != 0) || (entityNodeIsBYON[id] && recurringFeeInWei != 0)
        ) {
            require(blockNumber < blockLastPaidOn.add(recurringPaymentCycleInBlocks), "pay fee");
        }

        uint256 reward = getRewardByBlock(sender, nodeId, blockNumber);
        require(reward > 0, "no reward");

        uint256 fee = reward.mul(claimingFeeNumerator).div(claimingFeeDenominator);
        require(msg.value >= fee, "invalid fee");

        feeCollector.transfer(msg.value);

        if (toStrongPool) {
            strongToken.approve(address(strongPool), reward);
            strongPool.mineFor(sender, reward);
        } else {
            strongToken.transfer(sender, reward);
        }

        rewardBalance = rewardBalance.sub(reward);
        entityNodeClaimedOnBlock[id] = blockNumber;
        emit Claimed(sender, reward);
    }

    function getRewardAll(address entity, uint256 blockNumber) public view returns (uint256) {
        uint256 rewardsAll = 0;

        for (uint128 i = 1; i <= entityNodeCount[entity]; i++) {
            rewardsAll = rewardsAll.add(getRewardByBlock(entity, i, blockNumber > 0 ? blockNumber : block.number));
        }

        return rewardsAll;
    }

    function doesNodeExist(address entity, uint128 nodeId) public view returns (bool) {
        bytes memory id = getNodeId(entity, nodeId);
        return entityNodePaidOnBlock[id] > 0;
    }

    function hasNodeExpired(address entity, uint128 nodeId) public view returns (bool) {
        bytes memory id = getNodeId(entity, nodeId);
        uint256 blockLastPaidOn = entityNodePaidOnBlock[id];
        return block.number > blockLastPaidOn.add(recurringPaymentCycleInBlocks).add(gracePeriodInBlocks);
    }

    function getNodeId(address entity, uint128 nodeId) public view returns (bytes memory) {
        uint128 id = nodeId != 0 ? nodeId : entityNodeCount[entity] + 1;
        return abi.encodePacked(entity, id);
    }

    function getNodePaidOn(address entity, uint128 nodeId) public view returns (uint256) {
        bytes memory id = getNodeId(entity, nodeId);
        return entityNodePaidOnBlock[id];
    }

    function getNodeFee(address entity, uint128 nodeId) public view returns (uint256) {
        bytes memory id = getNodeId(entity, nodeId);
        return entityNodeIsBYON[id] ? recurringFeeInWei : recurringNaaSFeeInWei;
    }

    function isNodeActive(address entity, uint128 nodeId) public view returns (bool) {
        bytes memory id = getNodeId(entity, nodeId);
        return entityNodeIsActive[id] || !entityNodeIsBYON[id];
    }

    function isNodeBYON(address entity, uint128 nodeId) public view returns (bool) {
        bytes memory id = getNodeId(entity, nodeId);
        return entityNodeIsBYON[id];
    }

    function hasLegacyNode(address entity) public view returns (bool) {
        return entityActive[entity] && entityNodeCount[entity] == 0;
    }

    function approveBYONNode(address entity, uint128 nodeId) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin);

        bytes memory id = getNodeId(entity, nodeId);
        entityNodeIsActive[id] = true;
        entityNodeClaimedOnBlock[id] = block.number;
        activeEntities = activeEntities.add(1);
    }

    function suspendBYONNode(address entity, uint128 nodeId) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin);

        bytes memory id = getNodeId(entity, nodeId);
        entityNodeIsActive[id] = false;
        activeEntities = activeEntities.sub(1);
    }

    function setNodeIsActive(address entity, uint128 nodeId, bool isActive) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin);
        bytes memory id = getNodeId(entity, nodeId);

        if (isActive && !entityNodeIsActive[id]) {
            activeEntities = activeEntities.add(1);
            entityNodeClaimedOnBlock[id] = block.number;
        }

        if (!isActive && entityNodeIsActive[id]) {
            activeEntities = activeEntities.sub(1);
        }

        entityNodeIsActive[id] = isActive;
    }

    function setNodeIsNaaS(address entity, uint128 nodeId, bool isNaaS) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin);
        bytes memory id = getNodeId(entity, nodeId);

        entityNodeIsBYON[id] = !isNaaS;
    }

    function migrateLegacyNode(address entity) private {
        bytes memory id = getNodeId(entity, 1);
        entityNodeClaimedOnBlock[id] = entityBlockLastClaimedOn[entity];
        entityNodePaidOnBlock[id] = paidOnBlock[entity];
        entityNodeIsBYON[id] = !entityIsNaaS[entity];
        if (entityNodeIsBYON[id]) {
            entityNodeIsActive[id] = true;
        }
        entityNodeCount[msg.sender] = 1;
    }

    function migrateNode(uint128 nodeId, address to) public {
        if (hasLegacyNode(msg.sender)) {
            migrateLegacyNode(msg.sender);
        }

        if (hasLegacyNode(to)) {
            migrateLegacyNode(to);
        }

        require(doesNodeExist(msg.sender, nodeId), "doesnt exist");

        uint128 toNodeId = entityNodeCount[to] + 1;
        bytes memory fromId = getNodeId(msg.sender, nodeId);
        bytes memory toId = getNodeId(to, toNodeId);

        // move node to another address
        entityNodeIsActive[toId] = entityNodeIsActive[fromId];
        entityNodeIsBYON[toId] = entityNodeIsBYON[fromId];
        entityNodePaidOnBlock[toId] = entityNodePaidOnBlock[fromId];
        entityNodeClaimedOnBlock[toId] = entityNodeClaimedOnBlock[fromId];
        entityNodeCount[to] = entityNodeCount[to] + 1;

        // deactivate node
        entityNodeIsActive[fromId] = false;
        entityNodePaidOnBlock[fromId] = 0;
        entityNodeClaimedOnBlock[fromId] = 0;
        entityNodeCount[msg.sender] = entityNodeCount[msg.sender] - 1;

        emit Migrated(msg.sender, to, nodeId, toNodeId, entityNodeIsBYON[fromId]);
    }

    function claimAll(uint256 blockNumber, bool toStrongPool) public payable {
        for (uint16 i = 1; i <= entityNodeCount[msg.sender]; i++) {
            uint256 reward = getRewardByBlock(msg.sender, i, blockNumber);
            uint256 fee = reward.mul(claimingFeeNumerator).div(claimingFeeDenominator);
            this.claim{value : fee}(i, blockNumber, toStrongPool);
        }
    }

    function payAll() public payable {
        for (uint16 i = 1; i <= entityNodeCount[msg.sender]; i++) {
            bytes memory id = getNodeId(msg.sender, i);
            uint256 fee = entityNodeIsBYON[id] ? recurringFeeInWei : recurringNaaSFeeInWei;
            this.payFee{value : fee}(i);
        }
    }

    function addNFTBonusContract(address _contract) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin);

        strongNFTBonus = StrongNFTBonusInterface(_contract);
    }

    function payFeeAdmin(address entity, uint128[] memory nodes) public {
        require(msg.sender == admin || msg.sender == serviceAdmin || msg.sender == superAdmin);

        for (uint256 i = 0; i < nodes.length; i++) {
            uint128 nodeId = nodes[i];
            bytes memory id = getNodeId(entity, nodeId);
            entityNodePaidOnBlock[id] = entityNodePaidOnBlock[id].add(recurringPaymentCycleInBlocks);

            emit Paid(entity, nodeId, entityNodeIsBYON[id], true, entityNodePaidOnBlock[id]);
        }
    }

}

contract StrongNFTBonus is Context {

    using SafeMath for uint256;

    event Staked(address indexed sender, uint256 tokenId, uint128 nodeId, uint256 block);
    event Unstaked(address indexed sender, uint256 tokenId, uint128 nodeId, uint256 block);

    ServiceInterface public service;
    IERC1155Preset public nft;

    bool public initDone;

    address public serviceAdmin;
    address public superAdmin;

    string[] public nftBonusNames;
    mapping(string => uint256) public nftBonusLowerBound;
    mapping(string => uint256) public nftBonusUpperBound;
    mapping(string => uint256) public nftBonusValue;

    mapping(uint256 => uint256) public nftIdStakedForNodeId;
    mapping(address => mapping(uint128 => uint256)) public entityNodeStakedNftId;
    mapping(address => mapping(uint128 => uint256)) public entityNodeStakedNftBlock;

    function init(address serviceContract, address nftContract, address serviceAdminAddress, address superAdminAddress) public {
        require(initDone == false, "init done");

        serviceAdmin = serviceAdminAddress;
        superAdmin = superAdminAddress;
        service = ServiceInterface(serviceContract);
        nft = IERC1155Preset(nftContract);
        initDone = true;
    }

    function isNftStaked(uint256 _tokenId) public view returns (bool) {
        return nftIdStakedForNodeId[_tokenId] != 0;
    }

    function getNftStakedForNodeId(uint256 _tokenId) public view returns (uint256) {
        return nftIdStakedForNodeId[_tokenId];
    }

    function getStakedNftId(address _entity, uint128 _nodeId) public view returns (uint256) {
        return entityNodeStakedNftId[_entity][_nodeId];
    }

    function getStakedNftBlock(address _entity, uint128 _nodeId) public view returns (uint256) {
        return entityNodeStakedNftBlock[_entity][_nodeId];
    }

    function getBonus(address _entity, uint128 _nodeId, uint256 _fromBlock, uint256 _toBlock) public view returns (uint256) {
        uint256 nftId = entityNodeStakedNftId[_entity][_nodeId];

        if (nftId == 0) return 0;
        if (nftId < nftBonusLowerBound["BRONZE"]) return 0;
        if (nftId > nftBonusUpperBound["BRONZE"]) return 0;
        if (nft.balanceOf(_entity, nftId) == 0) return 0;
        if (_fromBlock >= _toBlock) return 0;

        uint256 stakedAtBlock = entityNodeStakedNftBlock[_entity][_nodeId];

        if (stakedAtBlock == 0) return 0;

        uint256 startFromBlock = stakedAtBlock > _fromBlock ? stakedAtBlock : _fromBlock;

        if (startFromBlock >= _toBlock) return 0;

        return _toBlock.sub(startFromBlock).mul(nftBonusValue["BRONZE"]);
    }

    function stakeNFT(uint256 _tokenId, uint128 _nodeId) public payable {
        require(nft.balanceOf(_msgSender(), _tokenId) != 0, "not enough");
        require(_tokenId >= nftBonusLowerBound["BRONZE"] && _tokenId <= nftBonusUpperBound["BRONZE"], "not eligible");
        require(nftIdStakedForNodeId[_tokenId] == 0, "already staked");
        require(service.doesNodeExist(_msgSender(), _nodeId), "node doesnt exist");

        nftIdStakedForNodeId[_tokenId] = _nodeId;
        entityNodeStakedNftId[_msgSender()][_nodeId] = _tokenId;
        entityNodeStakedNftBlock[_msgSender()][_nodeId] = block.number;

        emit Staked(msg.sender, _tokenId, _nodeId, block.number);
    }

    function unStakeNFT(uint256 _tokenId, uint128 _nodeId, uint256 _blockNumber) public payable {
        require(nft.balanceOf(_msgSender(), _tokenId) != 0, "not enough");
        require(nftIdStakedForNodeId[_tokenId] == _nodeId, "not this node");

        service.claim{value : msg.value}(_nodeId, _blockNumber, false);

        nftIdStakedForNodeId[_tokenId] = 0;
        entityNodeStakedNftId[_msgSender()][_nodeId] = 0;
        entityNodeStakedNftBlock[_msgSender()][_nodeId] = 0;

        emit Unstaked(msg.sender, _tokenId, _nodeId, _blockNumber);
    }

    function updateBonus(string memory _name, uint256 _lowerBound, uint256 _upperBound, uint256 _value) public {
        require(msg.sender == serviceAdmin || msg.sender == superAdmin, "not admin");

        bool alreadyExit = false;
        for (uint i = 0; i < nftBonusNames.length; i++) {
            if (keccak256(abi.encode(nftBonusNames[i])) == keccak256(abi.encode(_name))) {
                alreadyExit = true;
            }
        }

        if (!alreadyExit) {
            nftBonusNames.push(_name);
        }

        nftBonusLowerBound[_name] = _lowerBound;
        nftBonusUpperBound[_name] = _upperBound;
        nftBonusValue[_name] = _value;
    }

    function updateContracts(address serviceContract, address nftContract) public {
        require(msg.sender == superAdmin, "not admin");
        service = ServiceInterface(serviceContract);
        nft = IERC1155Preset(nftContract);
    }

    function updateServiceAdmin(address newServiceAdmin) public {
        require(msg.sender == superAdmin, "not admin");
        serviceAdmin = newServiceAdmin;
    }
}

contract StrongPoolV4 {
    event MinedFor(address indexed miner, uint256 amount);
    event Mined(address indexed miner, uint256 amount);
    event MinedForVotesOnly(address indexed miner, uint256 amount);
    event UnminedForVotesOnly(address indexed miner, uint256 amount);
    event Unmined(address indexed miner, uint256 amount);
    event Claimed(address indexed miner, uint256 reward);

    using SafeMath for uint256;

    bool public initDone;
    address public admin;
    address public pendingAdmin;
    address public superAdmin;
    address public pendingSuperAdmin;
    address public parameterAdmin;
    address payable public feeCollector;

    IERC20 public strongToken;
    VoteInterface public vote;

    mapping(address => uint256) public minerBalance;
    uint256 public totalBalance;
    mapping(address => uint256) public minerBlockLastClaimedOn;

    mapping(address => uint256) public minerVotes;

    uint256 public rewardBalance;

    uint256 public rewardPerBlockNumerator;
    uint256 public rewardPerBlockDenominator;

    uint256 public miningFeeNumerator;
    uint256 public miningFeeDenominator;

    uint256 public unminingFeeNumerator;
    uint256 public unminingFeeDenominator;

    uint256 public claimingFeeNumerator;
    uint256 public claimingFeeDenominator;

    mapping(address => uint256) public inboundContractIndex;
    address[] public inboundContracts;
    mapping(address => bool) public inboundContractTrusted;

    uint256 public claimingFeeInWei;

    bool public removedTokens;

    uint256 public rewardPerBlockNumeratorNew;
    uint256 public rewardPerBlockDenominatorNew;
    uint256 public rewardPerBlockNewEffectiveBlock;

    function init(
        address voteAddress,
        address strongTokenAddress,
        address adminAddress,
        address superAdminAddress,
        uint256 rewardPerBlockNumeratorValue,
        uint256 rewardPerBlockDenominatorValue,
        uint256 miningFeeNumeratorValue,
        uint256 miningFeeDenominatorValue,
        uint256 unminingFeeNumeratorValue,
        uint256 unminingFeeDenominatorValue,
        uint256 claimingFeeNumeratorValue,
        uint256 claimingFeeDenominatorValue
    ) public {
        require(!initDone, "init done");
        vote = VoteInterface(voteAddress);
        strongToken = IERC20(strongTokenAddress);
        admin = adminAddress;
        superAdmin = superAdminAddress;
        rewardPerBlockNumerator = rewardPerBlockNumeratorValue;
        rewardPerBlockDenominator = rewardPerBlockDenominatorValue;
        miningFeeNumerator = miningFeeNumeratorValue;
        miningFeeDenominator = miningFeeDenominatorValue;
        unminingFeeNumerator = unminingFeeNumeratorValue;
        unminingFeeDenominator = unminingFeeDenominatorValue;
        claimingFeeNumerator = claimingFeeNumeratorValue;
        claimingFeeDenominator = claimingFeeDenominatorValue;
        initDone = true;
    }

    // ADMIN
    // *************************************************************************************
    function updateParameterAdmin(address newParameterAdmin) public {
        require(newParameterAdmin != address(0), "zero");
        require(msg.sender == superAdmin);
        parameterAdmin = newParameterAdmin;
    }

    function updateFeeCollector(address payable newFeeCollector) public {
        require(newFeeCollector != address(0), "zero");
        require(msg.sender == superAdmin);
        feeCollector = newFeeCollector;
    }

    function setPendingAdmin(address newPendingAdmin) public {
        require(newPendingAdmin != address(0), "zero");
        require(msg.sender == admin, "not admin");
        pendingAdmin = newPendingAdmin;
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin && msg.sender != address(0), "not pendingAdmin");
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function setPendingSuperAdmin(address newPendingSuperAdmin) public {
        require(newPendingSuperAdmin != address(0), "zero");
        require(msg.sender == superAdmin, "not superAdmin");
        pendingSuperAdmin = newPendingSuperAdmin;
    }

    function acceptSuperAdmin() public {
        require(msg.sender == pendingSuperAdmin && msg.sender != address(0), "not pendingSuperAdmin");
        superAdmin = pendingSuperAdmin;
        pendingSuperAdmin = address(0);
    }

    // INBOUND CONTRACTS
    // *************************************************************************************
    function addInboundContract(address contr) public {
        require(contr != address(0), "zero");
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
        if (inboundContracts.length != 0) {
            uint256 index = inboundContractIndex[contr];
            require(inboundContracts[index] != contr, "exists");
        }
        uint256 len = inboundContracts.length;
        inboundContractIndex[contr] = len;
        inboundContractTrusted[contr] = true;
        inboundContracts.push(contr);
    }

    function inboundContractTrustStatus(address contr, bool trustStatus) public {
        require(contr != address(0), "zero");
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
        uint256 index = inboundContractIndex[contr];
        require(inboundContracts[index] == contr, "not exists");
        inboundContractTrusted[contr] = trustStatus;
    }

    // REWARD
    // *************************************************************************************
    function updateRewardPerBlock(uint256 numerator, uint256 denominator) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
        require(denominator != 0, "invalid value");
        rewardPerBlockNumerator = numerator;
        rewardPerBlockDenominator = denominator;
    }

    function deposit(uint256 amount) public {
        require(msg.sender == superAdmin, "not an admin");
        require(amount > 0, "zero");
        strongToken.transferFrom(msg.sender, address(this), amount);
        rewardBalance = rewardBalance.add(amount);
    }

    function withdraw(address destination, uint256 amount) public {
        require(msg.sender == superAdmin, "not an admin");
        require(amount > 0, "zero");
        require(rewardBalance >= amount, "not enough");
        strongToken.transfer(destination, amount);
        rewardBalance = rewardBalance.sub(amount);
    }

    // FEES
    // *************************************************************************************
    function updateMiningFee(uint256 numerator, uint256 denominator) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
        require(denominator != 0, "invalid value");
        miningFeeNumerator = numerator;
        miningFeeDenominator = denominator;
    }

    function updateUnminingFee(uint256 numerator, uint256 denominator) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
        require(denominator != 0, "invalid value");
        unminingFeeNumerator = numerator;
        unminingFeeDenominator = denominator;
    }

    function updateClaimingFee(uint256 numerator, uint256 denominator) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
        require(denominator != 0, "invalid value");
        claimingFeeNumerator = numerator;
        claimingFeeDenominator = denominator;
    }

    // CORE
    // *************************************************************************************
    function mineForVotesOnly(uint256 amount) public {
        require(amount > 0, "zero");
        strongToken.transferFrom(msg.sender, address(this), amount);
        minerVotes[msg.sender] = minerVotes[msg.sender].add(amount);
        vote.updateVotes(msg.sender, amount, true);
        emit MinedForVotesOnly(msg.sender, amount);
    }

    function unmineForVotesOnly(uint256 amount) public {
        require(amount > 0, "zero");
        require(minerVotes[msg.sender] >= amount, "not enough");
        minerVotes[msg.sender] = minerVotes[msg.sender].sub(amount);
        vote.updateVotes(msg.sender, amount, false);
        strongToken.transfer(msg.sender, amount);
        emit UnminedForVotesOnly(msg.sender, amount);
    }

    function mineFor(address miner, uint256 amount) public {
        require(inboundContractTrusted[msg.sender], "not trusted");
        require(amount > 0, "zero");
        strongToken.transferFrom(msg.sender, address(this), amount);
        minerBalance[miner] = minerBalance[miner].add(amount);
        totalBalance = totalBalance.add(amount);
        if (minerBlockLastClaimedOn[miner] == 0) {
            minerBlockLastClaimedOn[miner] = block.number;
        }
        vote.updateVotes(miner, amount, true);
        emit MinedFor(miner, amount);
    }

    function mine(uint256 amount) public payable {
        require(amount > 0, "zero");
        uint256 fee = amount.mul(miningFeeNumerator).div(miningFeeDenominator);
        require(msg.value == fee, "invalid fee");
        feeCollector.transfer(msg.value);
        strongToken.transferFrom(msg.sender, address(this), amount);
        if (block.number > minerBlockLastClaimedOn[msg.sender]) {
            uint256 reward = getReward(msg.sender);
            if (reward > 0) {
                minerBalance[msg.sender] = minerBalance[msg.sender].add(reward);
                totalBalance = totalBalance.add(reward);
                rewardBalance = rewardBalance.sub(reward);
                vote.updateVotes(msg.sender, reward, true);
                minerBlockLastClaimedOn[msg.sender] = block.number;
            }
        }
        minerBalance[msg.sender] = minerBalance[msg.sender].add(amount);
        totalBalance = totalBalance.add(amount);
        if (minerBlockLastClaimedOn[msg.sender] == 0) {
            minerBlockLastClaimedOn[msg.sender] = block.number;
        }
        vote.updateVotes(msg.sender, amount, true);
        emit Mined(msg.sender, amount);
    }

    function unmine(uint256 amount) public payable {
        require(amount > 0, "zero");
        uint256 fee = amount.mul(unminingFeeNumerator).div(unminingFeeDenominator);
        require(msg.value == fee, "invalid fee");
        require(minerBalance[msg.sender] >= amount, "not enough");
        feeCollector.transfer(msg.value);
        bool unmineAll = (amount == minerBalance[msg.sender]);
        if (block.number > minerBlockLastClaimedOn[msg.sender]) {
            uint256 reward = getReward(msg.sender);
            if (reward > 0) {
                minerBalance[msg.sender] = minerBalance[msg.sender].add(reward);
                totalBalance = totalBalance.add(reward);
                rewardBalance = rewardBalance.sub(reward);
                vote.updateVotes(msg.sender, reward, true);
                minerBlockLastClaimedOn[msg.sender] = block.number;
            }
        }
        uint256 amountToUnmine = unmineAll ? minerBalance[msg.sender] : amount;
        minerBalance[msg.sender] = minerBalance[msg.sender].sub(amountToUnmine);
        totalBalance = totalBalance.sub(amountToUnmine);
        strongToken.transfer(msg.sender, amountToUnmine);
        vote.updateVotes(msg.sender, amountToUnmine, false);
        if (minerBalance[msg.sender] == 0) {
            minerBlockLastClaimedOn[msg.sender] = 0;
        }
        emit Unmined(msg.sender, amountToUnmine);
    }

    function claim(uint256 blockNumber) public payable {
        require(blockNumber <= block.number, "invalid block number");
        require(minerBlockLastClaimedOn[msg.sender] != 0, "error");
        require(blockNumber > minerBlockLastClaimedOn[msg.sender], "too soon");
        uint256 reward = getRewardByBlock(msg.sender, blockNumber);
        require(reward > 0, "no reward");
        uint256 fee = reward.mul(claimingFeeNumerator).div(claimingFeeDenominator);
        require(msg.value == fee, "invalid fee");
        feeCollector.transfer(msg.value);
        minerBalance[msg.sender] = minerBalance[msg.sender].add(reward);
        totalBalance = totalBalance.add(reward);
        rewardBalance = rewardBalance.sub(reward);
        minerBlockLastClaimedOn[msg.sender] = blockNumber;
        vote.updateVotes(msg.sender, reward, true);
        emit Claimed(msg.sender, reward);
    }

    function getReward(address miner) public view returns (uint256) {
        return getRewardByBlock(miner, block.number);
    }

    function getRewardByBlock(address miner, uint256 blockNumber) public view returns (uint256) {
        uint256 blockLastClaimedOn = minerBlockLastClaimedOn[miner];

        if (blockNumber > block.number) return 0;
        if (blockLastClaimedOn == 0) return 0;
        if (blockNumber < blockLastClaimedOn) return 0;
        if (totalBalance == 0) return 0;

        uint256[2] memory rewardBlocks = rewards.blocks(blockLastClaimedOn, rewardPerBlockNewEffectiveBlock, blockNumber);
        uint256 rewardOld = rewardPerBlockDenominator > 0 ? rewardBlocks[0].mul(rewardPerBlockNumerator).div(rewardPerBlockDenominator) : 0;
        uint256 rewardNew = rewardPerBlockDenominatorNew > 0 ? rewardBlocks[1].mul(rewardPerBlockNumeratorNew).div(rewardPerBlockDenominatorNew) : 0;

        return rewardOld.add(rewardNew).mul(minerBalance[miner]).div(totalBalance);
    }

    function updateRewardPerBlockNew(
        uint256 numerator,
        uint256 denominator,
        uint256 effectiveBlock
    ) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");

        rewardPerBlockNumeratorNew = numerator;
        rewardPerBlockDenominatorNew = denominator;
        rewardPerBlockNewEffectiveBlock = effectiveBlock != 0 ? effectiveBlock : block.number;
    }
}

contract VoteV3 {
    event Voted(address indexed voter, address indexed service, address indexed entity, uint256 amount);
    event RecalledVote(address indexed voter, address indexed service, address indexed entity, uint256 amount);
    event Claimed(address indexed claimer, uint256 amount);
    event VotesAdded(address indexed miner, uint256 amount);
    event VotesSubtracted(address indexed miner, uint256 amount);
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    using SafeMath for uint256;

    StrongPoolInterface public strongPool;
    IERC20 public strongToken;

    bool public initDone;
    address public admin;
    address public pendingAdmin;
    address public superAdmin;
    address public pendingSuperAdmin;
    address public parameterAdmin;

    uint256 public rewardBalance;

    uint256 public voterRewardPerBlockNumerator;
    uint256 public voterRewardPerBlockDenominator;
    uint256 public entityRewardPerBlockNumerator;
    uint256 public entityRewardPerBlockDenominator;

    mapping(address => uint96) public balances;
    mapping(address => address) public delegates;

    mapping(address => mapping(uint32 => uint32)) public checkpointsFromBlock;
    mapping(address => mapping(uint32 => uint96)) public checkpointsVotes;
    mapping(address => uint32) public numCheckpoints;

    mapping(address => uint256) public voterVotesOut;
    uint256 public totalVotesOut;

    mapping(address => uint256) public serviceVotes;
    mapping(address => mapping(address => uint256)) public serviceEntityVotes;
    mapping(address => mapping(address => mapping(address => uint256))) public voterServiceEntityVotes;

    mapping(address => address[]) public voterServices;
    mapping(address => mapping(address => uint256)) public voterServiceIndex;

    mapping(address => mapping(address => address[])) public voterServiceEntities;
    mapping(address => mapping(address => mapping(address => uint256))) public voterServiceEntityIndex;

    mapping(address => uint256) public voterBlockLastClaimedOn;
    mapping(address => mapping(address => uint256)) public serviceEntityBlockLastClaimedOn;

    address[] public serviceContracts;
    mapping(address => uint256) public serviceContractIndex;
    mapping(address => bool) public serviceContractActive;

    uint256 public voterRewardPerBlockNumeratorNew;
    uint256 public voterRewardPerBlockDenominatorNew;
    uint256 public entityRewardPerBlockNumeratorNew;
    uint256 public entityRewardPerBlockDenominatorNew;
    uint256 public rewardPerBlockNewEffectiveBlock;

    function init(
        address strongTokenAddress,
        address strongPoolAddress,
        address adminAddress,
        address superAdminAddress,
        uint256 voterRewardPerBlockNumeratorValue,
        uint256 voterRewardPerBlockDenominatorValue,
        uint256 entityRewardPerBlockNumeratorValue,
        uint256 entityRewardPerBlockDenominatorValue
    ) public {
        require(!initDone, "init done");
        strongToken = IERC20(strongTokenAddress);
        strongPool = StrongPoolInterface(strongPoolAddress);
        admin = adminAddress;
        superAdmin = superAdminAddress;
        voterRewardPerBlockNumerator = voterRewardPerBlockNumeratorValue;
        voterRewardPerBlockDenominator = voterRewardPerBlockDenominatorValue;
        entityRewardPerBlockNumerator = entityRewardPerBlockNumeratorValue;
        entityRewardPerBlockDenominator = entityRewardPerBlockDenominatorValue;
        initDone = true;
    }

    // ADMIN
    // *************************************************************************************
    function updateParameterAdmin(address newParameterAdmin) public {
        require(newParameterAdmin != address(0), "zero");
        require(msg.sender == superAdmin);
        parameterAdmin = newParameterAdmin;
    }

    function setPendingAdmin(address newPendingAdmin) public {
        require(newPendingAdmin != address(0), "zero");
        require(msg.sender == admin, "not admin");
        pendingAdmin = newPendingAdmin;
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin && msg.sender != address(0), "not pendingAdmin");
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function setPendingSuperAdmin(address newPendingSuperAdmin) public {
        require(newPendingSuperAdmin != address(0), "zero");
        require(msg.sender == superAdmin, "not superAdmin");
        pendingSuperAdmin = newPendingSuperAdmin;
    }

    function acceptSuperAdmin() public {
        require(msg.sender == pendingSuperAdmin && msg.sender != address(0), "not pendingSuperAdmin");
        superAdmin = pendingSuperAdmin;
        pendingSuperAdmin = address(0);
    }

    // SERVICE CONTRACTS
    // *************************************************************************************
    function addServiceContract(address contr) public {
        require(contr != address(0), "zero");
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
        if (serviceContracts.length != 0) {
            uint256 index = serviceContractIndex[contr];
            require(serviceContracts[index] != contr, "exists");
        }
        uint256 len = serviceContracts.length;
        serviceContractIndex[contr] = len;
        serviceContractActive[contr] = true;
        serviceContracts.push(contr);
    }

    function updateServiceContractActiveStatus(address contr, bool activeStatus) public {
        require(contr != address(0), "zero");
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
        require(serviceContracts.length > 0, "zero");
        uint256 index = serviceContractIndex[contr];
        require(serviceContracts[index] == contr, "not exists");
        serviceContractActive[contr] = activeStatus;
    }

    function getServiceContracts() public view returns (address[] memory) {
        return serviceContracts;
    }

    // REWARD
    // *************************************************************************************
    function updateVoterRewardPerBlock(uint256 numerator, uint256 denominator) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
        require(denominator != 0, "invalid value");
        voterRewardPerBlockNumerator = numerator;
        voterRewardPerBlockDenominator = denominator;
    }

    function updateEntityRewardPerBlock(uint256 numerator, uint256 denominator) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
        require(denominator != 0, "invalid value");
        entityRewardPerBlockNumerator = numerator;
        entityRewardPerBlockDenominator = denominator;
    }

    function deposit(uint256 amount) public {
        require(msg.sender == superAdmin, "not an admin");
        require(amount > 0, "zero");
        strongToken.transferFrom(msg.sender, address(this), amount);
        rewardBalance = rewardBalance.add(amount);
    }

    function withdraw(address destination, uint256 amount) public {
        require(msg.sender == superAdmin, "not an admin");
        require(amount > 0, "zero");
        require(rewardBalance >= amount, "not enough");
        strongToken.transfer(destination, amount);
        rewardBalance = rewardBalance.sub(amount);
    }

    // CORE
    // *************************************************************************************
    function getVoterServices(address voter) public view returns (address[] memory) {
        return voterServices[voter];
    }

    function getVoterServiceEntities(address voter, address service) public view returns (address[] memory) {
        return voterServiceEntities[voter][service];
    }

    function getVoterReward(address voter) public view returns (uint256) {
        uint256 blockLastClaimedOn = voterBlockLastClaimedOn[voter];

        if (totalVotesOut == 0) return 0;
        if (blockLastClaimedOn == 0) return 0;

        uint256[2] memory rewardBlocks = rewards.blocks(blockLastClaimedOn, rewardPerBlockNewEffectiveBlock, block.number);
        uint256 rewardOld = voterRewardPerBlockNumerator > 0 ? rewardBlocks[0].mul(voterRewardPerBlockNumerator).div(voterRewardPerBlockDenominator) : 0;
        uint256 rewardNew = voterRewardPerBlockNumeratorNew > 0 ? rewardBlocks[1].mul(voterRewardPerBlockNumeratorNew).div(voterRewardPerBlockDenominatorNew) : 0;

        return rewardOld.add(rewardNew).mul(voterVotesOut[voter]).div(totalVotesOut);
    }

    function getEntityReward(address service, address entity) public view returns (uint256) {
        uint256 blockLastClaimedOn = serviceEntityBlockLastClaimedOn[service][entity];

        if (serviceVotes[service] == 0) return 0;
        if (blockLastClaimedOn == 0) return 0;

        uint256[2] memory rewardBlocks = rewards.blocks(blockLastClaimedOn, rewardPerBlockNewEffectiveBlock, block.number);
        uint256 rewardOld = entityRewardPerBlockNumerator > 0 ? rewardBlocks[0].mul(entityRewardPerBlockNumerator).div(entityRewardPerBlockDenominator) : 0;
        uint256 rewardNew = entityRewardPerBlockNumeratorNew > 0 ? rewardBlocks[1].mul(entityRewardPerBlockNumeratorNew).div(entityRewardPerBlockDenominatorNew) : 0;

        return rewardOld.add(rewardNew).mul(serviceEntityVotes[service][entity]).div(serviceVotes[service]);
    }

    function vote(
        address service,
        address entity,
        uint256 amount
    ) public {
        require(amount > 0, "zero");
        require(uint256(_getAvailableServiceEntityVotes(msg.sender)) >= amount, "not enough");
        require(serviceContractActive[service], "service not active");
        require(ServiceInterface(service).isEntityActive(entity), "entity not active");

        uint256 serviceIndex = voterServiceIndex[msg.sender][service];
        if (voterServices[msg.sender].length == 0 || voterServices[msg.sender][serviceIndex] != service) {
            uint256 len = voterServices[msg.sender].length;
            voterServiceIndex[msg.sender][service] = len;
            voterServices[msg.sender].push(service);
        }

        uint256 entityIndex = voterServiceEntityIndex[msg.sender][service][entity];
        if (
            voterServiceEntities[msg.sender][service].length == 0 ||
            voterServiceEntities[msg.sender][service][entityIndex] != entity
        ) {
            uint256 len = voterServiceEntities[msg.sender][service].length;
            voterServiceEntityIndex[msg.sender][service][entity] = len;
            voterServiceEntities[msg.sender][service].push(entity);
        }

        if (block.number > voterBlockLastClaimedOn[msg.sender]) {
            uint256 reward = getVoterReward(msg.sender);
            if (reward > 0) {
                rewardBalance = rewardBalance.sub(reward);
                strongToken.approve(address(strongPool), reward);
                strongPool.mineFor(msg.sender, reward);
                voterBlockLastClaimedOn[msg.sender] = block.number;
            }
        }

        if (block.number > serviceEntityBlockLastClaimedOn[service][entity]) {
            uint256 reward = getEntityReward(service, entity);
            if (reward > 0) {
                rewardBalance = rewardBalance.sub(reward);
                strongToken.approve(address(strongPool), reward);
                strongPool.mineFor(entity, reward);
                serviceEntityBlockLastClaimedOn[service][entity] = block.number;
            }
        }

        serviceVotes[service] = serviceVotes[service].add(amount);
        serviceEntityVotes[service][entity] = serviceEntityVotes[service][entity].add(amount);
        voterServiceEntityVotes[msg.sender][service][entity] = voterServiceEntityVotes[msg.sender][service][entity].add(
            amount
        );

        voterVotesOut[msg.sender] = voterVotesOut[msg.sender].add(amount);
        totalVotesOut = totalVotesOut.add(amount);

        if (voterBlockLastClaimedOn[msg.sender] == 0) {
            voterBlockLastClaimedOn[msg.sender] = block.number;
        }

        if (serviceEntityBlockLastClaimedOn[service][entity] == 0) {
            serviceEntityBlockLastClaimedOn[service][entity] = block.number;
        }

        emit Voted(msg.sender, service, entity, amount);
    }

    function recallVote(
        address service,
        address entity,
        uint256 amount
    ) public {
        require(amount > 0, "zero");
        require(voterServiceEntityVotes[msg.sender][service][entity] >= amount, "not enough");

        if (block.number > voterBlockLastClaimedOn[msg.sender]) {
            uint256 reward = getVoterReward(msg.sender);
            if (reward > 0) {
                rewardBalance = rewardBalance.sub(reward);
                strongToken.approve(address(strongPool), reward);
                strongPool.mineFor(msg.sender, reward);
                voterBlockLastClaimedOn[msg.sender] = block.number;
            }
        }

        if (block.number > serviceEntityBlockLastClaimedOn[service][entity]) {
            uint256 reward = getEntityReward(service, entity);
            if (reward > 0) {
                rewardBalance = rewardBalance.sub(reward);
                strongToken.approve(address(strongPool), reward);
                strongPool.mineFor(entity, reward);
                serviceEntityBlockLastClaimedOn[service][entity] = block.number;
            }
        }

        serviceVotes[service] = serviceVotes[service].sub(amount);
        serviceEntityVotes[service][entity] = serviceEntityVotes[service][entity].sub(amount);
        voterServiceEntityVotes[msg.sender][service][entity] = voterServiceEntityVotes[msg.sender][service][entity].sub(
            amount
        );

        voterVotesOut[msg.sender] = voterVotesOut[msg.sender].sub(amount);
        totalVotesOut = totalVotesOut.sub(amount);

        if (voterVotesOut[msg.sender] == 0) {
            voterBlockLastClaimedOn[msg.sender] = 0;
        }

        if (serviceEntityVotes[service][entity] == 0) {
            serviceEntityBlockLastClaimedOn[service][entity] = 0;
        }
        emit RecalledVote(msg.sender, service, entity, amount);
    }

    function voterClaim() public {
        require(voterBlockLastClaimedOn[msg.sender] != 0, "error");
        require(block.number > voterBlockLastClaimedOn[msg.sender], "too soon");
        uint256 reward = getVoterReward(msg.sender);
        require(reward > 0, "no reward");
        rewardBalance = rewardBalance.sub(reward);
        strongToken.approve(address(strongPool), reward);
        strongPool.mineFor(msg.sender, reward);
        voterBlockLastClaimedOn[msg.sender] = block.number;
        emit Claimed(msg.sender, reward);
    }

    function entityClaim(address service) public {
        require(serviceEntityBlockLastClaimedOn[service][msg.sender] != 0, "error");
        require(block.number > serviceEntityBlockLastClaimedOn[service][msg.sender], "too soon");
        require(ServiceInterface(service).isEntityActive(msg.sender), "not active");
        uint256 reward = getEntityReward(service, msg.sender);
        require(reward > 0, "no reward");
        rewardBalance = rewardBalance.sub(reward);
        strongToken.approve(address(strongPool), reward);
        strongPool.mineFor(msg.sender, reward);
        serviceEntityBlockLastClaimedOn[service][msg.sender] = block.number;
        emit Claimed(msg.sender, reward);
    }

    function updateVotes(
        address voter,
        uint256 rawAmount,
        bool adding
    ) public {
        require(msg.sender == address(strongPool), "not strongPool");
        uint96 amount = _safe96(rawAmount, "amount exceeds 96 bits");
        if (adding) {
            _addVotes(voter, amount);
        } else {
            require(_getAvailableServiceEntityVotes(voter) >= amount, "recall votes");
            _subVotes(voter, amount);
        }
    }

    function getCurrentProposalVotes(address account) external view returns (uint96) {
        return _getCurrentProposalVotes(account);
    }

    function getPriorProposalVotes(address account, uint256 blockNumber) external view returns (uint96) {
        require(blockNumber < block.number, "not yet determined");
        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }
        if (checkpointsFromBlock[account][nCheckpoints - 1] <= blockNumber) {
            return checkpointsVotes[account][nCheckpoints - 1];
        }
        if (checkpointsFromBlock[account][0] > blockNumber) {
            return 0;
        }
        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2;
            uint32 fromBlock = checkpointsFromBlock[account][center];
            uint96 votes = checkpointsVotes[account][center];
            if (fromBlock == blockNumber) {
                return votes;
            } else if (fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpointsVotes[account][lower];
    }

    function getAvailableServiceEntityVotes(address account) public view returns (uint96) {
        return _getAvailableServiceEntityVotes(account);
    }

    // SUPPORT
    // *************************************************************************************
    function _addVotes(address voter, uint96 amount) internal {
        require(voter != address(0), "zero address");
        balances[voter] = _add96(balances[voter], amount, "vote amount overflows");
        _addDelegates(voter, amount);
        emit VotesAdded(voter, amount);
    }

    function _subVotes(address voter, uint96 amount) internal {
        balances[voter] = _sub96(balances[voter], amount, "vote amount exceeds balance");
        _subtractDelegates(voter, amount);
        emit VotesSubtracted(voter, amount);
    }

    function _addDelegates(address miner, uint96 amount) internal {
        if (delegates[miner] == address(0)) {
            delegates[miner] = miner;
        }
        address currentDelegate = delegates[miner];
        _moveDelegates(address(0), currentDelegate, amount);
    }

    function _subtractDelegates(address miner, uint96 amount) internal {
        address currentDelegate = delegates[miner];
        _moveDelegates(currentDelegate, address(0), amount);
    }

    function _moveDelegates(
        address srcRep,
        address dstRep,
        uint96 amount
    ) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpointsVotes[srcRep][srcRepNum - 1] : 0;
                uint96 srcRepNew = _sub96(srcRepOld, amount, "vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }
            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpointsVotes[dstRep][dstRepNum - 1] : 0;
                uint96 dstRepNew = _add96(dstRepOld, amount, "vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint96 oldVotes,
        uint96 newVotes
    ) internal {
        uint32 blockNumber = _safe32(block.number, "block number exceeds 32 bits");
        if (nCheckpoints > 0 && checkpointsFromBlock[delegatee][nCheckpoints - 1] == blockNumber) {
            checkpointsVotes[delegatee][nCheckpoints - 1] = newVotes;
        } else {
            checkpointsFromBlock[delegatee][nCheckpoints] = blockNumber;
            checkpointsVotes[delegatee][nCheckpoints] = newVotes;
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function _safe32(uint256 n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function _safe96(uint256 n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function _add96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function _sub96(
        uint96 a,
        uint96 b,
        string memory errorMessage
    ) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function _getCurrentProposalVotes(address account) internal view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpointsVotes[account][nCheckpoints - 1] : 0;
    }

    function _getAvailableServiceEntityVotes(address account) internal view returns (uint96) {
        uint96 proposalVotes = _getCurrentProposalVotes(account);
        return proposalVotes == 0 ? 0 : proposalVotes - _safe96(voterVotesOut[account], "voterVotesOut exceeds 96 bits");
    }

    function updateRewardPerBlockNew(
        uint256 numeratorVoter,
        uint256 denominatorVoter,
        uint256 numeratorEntity,
        uint256 denominatorEntity,
        uint256 effectiveBlock
    ) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");

        voterRewardPerBlockNumeratorNew = numeratorVoter;
        voterRewardPerBlockDenominatorNew = denominatorVoter;
        entityRewardPerBlockNumeratorNew = numeratorEntity;
        entityRewardPerBlockDenominatorNew = denominatorEntity;
        rewardPerBlockNewEffectiveBlock = effectiveBlock != 0 ? effectiveBlock : block.number;
    }
}

contract PoolV4 {
    event Mined(address indexed miner, uint256 amount);
    event Unmined(address indexed miner, uint256 amount);
    event Claimed(address indexed miner, uint256 reward);

    using SafeMath for uint256;

    bool public initDone;
    address public admin;
    address public pendingAdmin;
    address public superAdmin;
    address public pendingSuperAdmin;
    address public parameterAdmin;
    address payable public feeCollector;

    IERC20 public token;
    IERC20 public strongToken;
    StrongPoolInterface public strongPool;

    mapping(address => uint256) public minerBalance;
    uint256 public totalBalance;
    mapping(address => uint256) public minerBlockLastClaimedOn;

    uint256 public rewardBalance;

    uint256 public rewardPerBlockNumerator;
    uint256 public rewardPerBlockDenominator;

    uint256 public miningFeeNumerator;
    uint256 public miningFeeDenominator;

    uint256 public unminingFeeNumerator;
    uint256 public unminingFeeDenominator;

    uint256 public claimingFeeNumerator;
    uint256 public claimingFeeDenominator;

    uint256 public claimingFeeInWei;

    uint256 public rewardPerBlockNumeratorNew;
    uint256 public rewardPerBlockDenominatorNew;
    uint256 public rewardPerBlockNewEffectiveBlock;

    function init(
        address strongTokenAddress,
        address tokenAddress,
        address strongPoolAddress,
        address adminAddress,
        address superAdminAddress,
        uint256 rewardPerBlockNumeratorValue,
        uint256 rewardPerBlockDenominatorValue,
        uint256 miningFeeNumeratorValue,
        uint256 miningFeeDenominatorValue,
        uint256 unminingFeeNumeratorValue,
        uint256 unminingFeeDenominatorValue,
        uint256 claimingFeeNumeratorValue,
        uint256 claimingFeeDenominatorValue
    ) public {
        require(!initDone, "init done");
        strongToken = IERC20(strongTokenAddress);
        token = IERC20(tokenAddress);
        strongPool = StrongPoolInterface(strongPoolAddress);
        admin = adminAddress;
        superAdmin = superAdminAddress;
        rewardPerBlockNumerator = rewardPerBlockNumeratorValue;
        rewardPerBlockDenominator = rewardPerBlockDenominatorValue;
        miningFeeNumerator = miningFeeNumeratorValue;
        miningFeeDenominator = miningFeeDenominatorValue;
        unminingFeeNumerator = unminingFeeNumeratorValue;
        unminingFeeDenominator = unminingFeeDenominatorValue;
        claimingFeeNumerator = claimingFeeNumeratorValue;
        claimingFeeDenominator = claimingFeeDenominatorValue;
        initDone = true;
    }

    // ADMIN
    // *************************************************************************************
    function updateParameterAdmin(address newParameterAdmin) public {
        require(newParameterAdmin != address(0), "zero");
        require(msg.sender == superAdmin);
        parameterAdmin = newParameterAdmin;
    }

    function setPendingAdmin(address newPendingAdmin) public {
        require(newPendingAdmin != address(0), "zero");
        require(msg.sender == admin, "not admin");
        pendingAdmin = newPendingAdmin;
    }

    function acceptAdmin() public {
        require(msg.sender == pendingAdmin && msg.sender != address(0), "not pendingAdmin");
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    function setPendingSuperAdmin(address newPendingSuperAdmin) public {
        require(newPendingSuperAdmin != address(0), "zero");
        require(msg.sender == superAdmin, "not superAdmin");
        pendingSuperAdmin = newPendingSuperAdmin;
    }

    function acceptSuperAdmin() public {
        require(msg.sender == pendingSuperAdmin && msg.sender != address(0), "not pendingSuperAdmin");
        superAdmin = pendingSuperAdmin;
        pendingSuperAdmin = address(0);
    }

    // REWARD
    // *************************************************************************************
    function updateRewardPerBlock(uint256 numerator, uint256 denominator) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
        require(denominator != 0, "invalid value");
        rewardPerBlockNumerator = numerator;
        rewardPerBlockDenominator = denominator;
    }

    function deposit(uint256 amount) public {
        require(msg.sender == superAdmin, "not an admin");
        require(amount > 0, "zero");
        strongToken.transferFrom(msg.sender, address(this), amount);
        rewardBalance = rewardBalance.add(amount);
    }

    function withdraw(address destination, uint256 amount) public {
        require(msg.sender == superAdmin, "not an admin");
        require(amount > 0, "zero");
        require(rewardBalance >= amount, "not enough");
        strongToken.transfer(destination, amount);
        rewardBalance = rewardBalance.sub(amount);
    }

    // FEES
    // *************************************************************************************
    function updateFeeCollector(address payable newFeeCollector) public {
        require(newFeeCollector != address(0), "zero");
        require(msg.sender == superAdmin);
        feeCollector = newFeeCollector;
    }

    function updateMiningFee(uint256 numerator, uint256 denominator) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
        require(denominator != 0, "invalid value");
        miningFeeNumerator = numerator;
        miningFeeDenominator = denominator;
    }

    function updateUnminingFee(uint256 numerator, uint256 denominator) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
        require(denominator != 0, "invalid value");
        unminingFeeNumerator = numerator;
        unminingFeeDenominator = denominator;
    }

    function updateClaimingFee(uint256 numerator, uint256 denominator) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not an admin");
        require(denominator != 0, "invalid value");
        claimingFeeNumerator = numerator;
        claimingFeeDenominator = denominator;
    }

    // CORE
    // *************************************************************************************
    function mine(uint256 amount) public payable {
        require(amount > 0, "zero");
        uint256 fee = amount.mul(miningFeeNumerator).div(miningFeeDenominator);
        require(msg.value == fee, "invalid fee");
        feeCollector.transfer(msg.value);
        if (block.number > minerBlockLastClaimedOn[msg.sender]) {
            uint256 reward = getReward(msg.sender);
            if (reward > 0) {
                rewardBalance = rewardBalance.sub(reward);
                strongToken.approve(address(strongPool), reward);
                strongPool.mineFor(msg.sender, reward);
                minerBlockLastClaimedOn[msg.sender] = block.number;
            }
        }
        token.transferFrom(msg.sender, address(this), amount);
        minerBalance[msg.sender] = minerBalance[msg.sender].add(amount);
        totalBalance = totalBalance.add(amount);
        if (minerBlockLastClaimedOn[msg.sender] == 0) {
            minerBlockLastClaimedOn[msg.sender] = block.number;
        }
        emit Mined(msg.sender, amount);
    }

    function unmine(uint256 amount) public payable {
        require(amount > 0, "zero");
        uint256 fee = amount.mul(unminingFeeNumerator).div(unminingFeeDenominator);
        require(msg.value == fee, "invalid fee");
        require(minerBalance[msg.sender] >= amount, "not enough");
        feeCollector.transfer(msg.value);
        if (block.number > minerBlockLastClaimedOn[msg.sender]) {
            uint256 reward = getReward(msg.sender);
            if (reward > 0) {
                rewardBalance = rewardBalance.sub(reward);
                strongToken.approve(address(strongPool), reward);
                strongPool.mineFor(msg.sender, reward);
                minerBlockLastClaimedOn[msg.sender] = block.number;
            }
        }
        minerBalance[msg.sender] = minerBalance[msg.sender].sub(amount);
        totalBalance = totalBalance.sub(amount);
        token.transfer(msg.sender, amount);
        if (minerBalance[msg.sender] == 0) {
            minerBlockLastClaimedOn[msg.sender] = 0;
        }
        emit Unmined(msg.sender, amount);
    }

    function claim(uint256 blockNumber) public payable {
        require(blockNumber <= block.number, "invalid block number");
        require(minerBlockLastClaimedOn[msg.sender] != 0, "error");
        require(blockNumber > minerBlockLastClaimedOn[msg.sender], "too soon");
        uint256 reward = getRewardByBlock(msg.sender, blockNumber);
        require(reward > 0, "no reward");
        uint256 fee = reward.mul(claimingFeeNumerator).div(claimingFeeDenominator);
        require(msg.value == fee, "invalid fee");
        feeCollector.transfer(msg.value);
        strongToken.approve(address(strongPool), reward);
        strongPool.mineFor(msg.sender, reward);
        rewardBalance = rewardBalance.sub(reward);
        minerBlockLastClaimedOn[msg.sender] = blockNumber;
        emit Claimed(msg.sender, reward);
    }

    function getReward(address miner) public view returns (uint256) {
        return getRewardByBlock(miner, block.number);
    }

    function getRewardByBlock(address miner, uint256 blockNumber) public view returns (uint256) {
        uint256 blockLastClaimedOn = minerBlockLastClaimedOn[miner];

        if (blockNumber > block.number) return 0;
        if (blockLastClaimedOn == 0) return 0;
        if (blockNumber < blockLastClaimedOn) return 0;
        if (totalBalance == 0) return 0;

        uint256[2] memory rewardBlocks = rewards.blocks(blockLastClaimedOn, rewardPerBlockNewEffectiveBlock, blockNumber);
        uint256 rewardOld = rewardPerBlockDenominator > 0 ? rewardBlocks[0].mul(rewardPerBlockNumerator).div(rewardPerBlockDenominator) : 0;
        uint256 rewardNew = rewardPerBlockDenominatorNew > 0 ? rewardBlocks[1].mul(rewardPerBlockNumeratorNew).div(rewardPerBlockDenominatorNew) : 0;

        return rewardOld.add(rewardNew).mul(minerBalance[miner]).div(totalBalance);
    }

    function updateRewardPerBlockNew(
        uint256 numerator,
        uint256 denominator,
        uint256 effectiveBlock
    ) public {
        require(msg.sender == admin || msg.sender == parameterAdmin || msg.sender == superAdmin, "not admin");

        rewardPerBlockNumeratorNew = numerator;
        rewardPerBlockDenominatorNew = denominator;
        rewardPerBlockNewEffectiveBlock = effectiveBlock != 0 ? effectiveBlock : block.number;
    }
}