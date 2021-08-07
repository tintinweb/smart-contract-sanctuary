// SPDX-License-Identifier: MIT
// @unsupported: ovm

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./L2_Bridge.sol";
import "../interfaces/polygon/messengers/I_L2_PolygonMessengerProxy.sol";

/**
 * @dev An L2_Bridge for Polygon - https://docs.matic.network/docs
 */

contract L2_PolygonBridge is L2_Bridge {
    I_L2_PolygonMessengerProxy public messengerProxy;

    event L1_BridgeMessage(bytes data);

    constructor (
        I_L2_PolygonMessengerProxy _messengerProxy,
        address l1Governance,
        HopBridgeToken hToken,
        address l1BridgeAddress,
        uint256[] memory activeChainIds,
        address[] memory bonders
    )
        public
        L2_Bridge(
            l1Governance,
            hToken,
            l1BridgeAddress,
            activeChainIds,
            bonders
        )
    {
        messengerProxy = _messengerProxy;
    }

    function _sendCrossDomainMessage(bytes memory message) internal override {
        messengerProxy.sendCrossDomainMessage(message);
    }

    function _verifySender(address expectedSender) internal override {
        require(msg.sender == address(messengerProxy), "L2_PLGN_BRG: Caller is not the expected sender");
        // Verify that cross-domain sender is expectedSender
        require(messengerProxy.xDomainMessageSender() == expectedSender, "L2_PLGN_BRG: Invalid cross-domain sender");
    }

    /**
     * @dev Allows the L1 Bridge to set the messengerProxy proxy
     * @param _messengerProxy The new messengerProxy address
     */
    function setMessengerProxy(I_L2_PolygonMessengerProxy _messengerProxy) external onlyGovernance {
        messengerProxy = _messengerProxy;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

import "./Bridge.sol";
import "./HopBridgeToken.sol";
import "../libraries/Lib_MerkleTree.sol";

interface I_L2_AmmWrapper {
    function attemptSwap(address recipient, uint256 amount, uint256 amountOutMin, uint256 deadline) external;
}

/**
 * @dev The L2_Bridge is responsible for aggregating pending Transfers into TransferRoots. Each newly
 * createdTransferRoot is then sent to the L1_Bridge. The L1_Bridge may be the TransferRoot's final
 * destination or the L1_Bridge may forward the TransferRoot to it's destination L2_Bridge.
 */

abstract contract L2_Bridge is Bridge {
    using SafeERC20 for IERC20;

    address public l1Governance;
    HopBridgeToken public immutable hToken;
    address public l1BridgeAddress;
    address public l1BridgeCaller;
    I_L2_AmmWrapper public ammWrapper;
    mapping(uint256 => bool) public activeChainIds;
    uint256 public minimumForceCommitDelay = 4 hours;
    uint256 public maxPendingTransfers = 128;
    uint256 public minBonderBps = 2;
    uint256 public minBonderFeeAbsolute = 0;

    mapping(uint256 => bytes32[]) public pendingTransferIdsForChainId;
    mapping(uint256 => uint256) public pendingAmountForChainId;
    mapping(uint256 => uint256) public lastCommitTimeForChainId;
    uint256 public transferNonceIncrementer;

    bytes32 private immutable NONCE_DOMAIN_SEPARATOR;

    event TransfersCommitted (
        uint256 indexed destinationChainId,
        bytes32 indexed rootHash,
        uint256 totalAmount,
        uint256 rootCommittedAt
    );

    event TransferSent (
        bytes32 indexed transferId,
        uint256 indexed chainId,
        address indexed recipient,
        uint256 amount,
        bytes32 transferNonce,
        uint256 bonderFee,
        uint256 index,
        uint256 amountOutMin,
        uint256 deadline
    );

    event TransferFromL1Completed (
        address indexed recipient,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline,
        address indexed relayer,
        uint256 relayerFee
    );

    modifier onlyL1Bridge {
        _verifySender(l1BridgeCaller);
        _;
    }

    constructor (
        address _l1Governance,
        HopBridgeToken _hToken,
        address _l1BridgeAddress,
        uint256[] memory _activeChainIds,
        address[] memory bonders
    )
        public
        Bridge(bonders)
    {
        l1Governance = _l1Governance;
        hToken = _hToken;
        l1BridgeAddress = _l1BridgeAddress;

        for (uint256 i = 0; i < _activeChainIds.length; i++) {
            activeChainIds[_activeChainIds[i]] = true;
        }

        NONCE_DOMAIN_SEPARATOR = keccak256("L2_Bridge v1.0");
    }

    /* ========== Virtual functions ========== */

    function _sendCrossDomainMessage(bytes memory message) internal virtual;
    function _verifySender(address expectedSender) internal virtual;

    /* ========== Public/External functions ========== */

    /**
     * @notice _amount is the total amount the user wants to send including the Bonder fee
     * @dev Send  hTokens to another supported layer-2 or to layer-1 to be redeemed for the underlying asset.
     * @param chainId The chainId of the destination chain
     * @param recipient The address receiving funds at the destination
     * @param amount The amount being sent
     * @param bonderFee The amount distributed to the Bonder at the destination. This is subtracted from the `amount`.
     * @param amountOutMin The minimum amount received after attempting to swap in the destination
     * AMM market. 0 if no swap is intended.
     * @param deadline The deadline for swapping in the destination AMM market. 0 if no
     * swap is intended.
     */
    function send(
        uint256 chainId,
        address recipient,
        uint256 amount,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline
    )
        external
    {
        require(amount > 0, "L2_BRG: Must transfer a non-zero amount");
        require(amount >= bonderFee, "L2_BRG: Bonder fee cannot exceed amount");
        require(activeChainIds[chainId], "L2_BRG: chainId is not supported");
        uint256 minBonderFeeRelative = amount.mul(minBonderBps).div(10000);
        // Get the max of minBonderFeeRelative and minBonderFeeAbsolute
        uint256 minBonderFee = minBonderFeeRelative > minBonderFeeAbsolute ? minBonderFeeRelative : minBonderFeeAbsolute;
        require(bonderFee >= minBonderFee, "L2_BRG: bonderFee must meet minimum requirements");

        bytes32[] storage pendingTransfers = pendingTransferIdsForChainId[chainId];

        if (pendingTransfers.length >= maxPendingTransfers) {
            _commitTransfers(chainId);
        }

        hToken.burn(msg.sender, amount);

        bytes32 transferNonce = getNextTransferNonce();
        transferNonceIncrementer++;

        bytes32 transferId = getTransferId(
            chainId,
            recipient,
            amount,
            transferNonce,
            bonderFee,
            amountOutMin,
            deadline
        );
        uint256 transferIndex = pendingTransfers.length;
        pendingTransfers.push(transferId);

        pendingAmountForChainId[chainId] = pendingAmountForChainId[chainId].add(amount);

        emit TransferSent(
            transferId,
            chainId,
            recipient,
            amount,
            transferNonce,
            bonderFee,
            transferIndex,
            amountOutMin,
            deadline
        );
    }

    /**
     * @dev Aggregates all pending Transfers to the `destinationChainId` and sends them to the
     * L1_Bridge as a TransferRoot.
     * @param destinationChainId The chainId of the TransferRoot's destination chain
     */
    function commitTransfers(uint256 destinationChainId) external {
        uint256 minForceCommitTime = lastCommitTimeForChainId[destinationChainId].add(minimumForceCommitDelay);
        require(minForceCommitTime < block.timestamp || getIsBonder(msg.sender), "L2_BRG: Only Bonder can commit before min delay");
        lastCommitTimeForChainId[destinationChainId] = block.timestamp;

        _commitTransfers(destinationChainId);
    }

    /**
     * @dev Mints new hTokens for the recipient and optionally swaps them in the AMM market.
     * @param recipient The address receiving funds
     * @param amount The amount being distributed
     * @param amountOutMin The minimum amount received after attempting to swap in the destination
     * AMM market. 0 if no swap is intended.
     * @param deadline The deadline for swapping in the AMM market. 0 if no
     * swap is intended.
     * @param relayer The address of the relayer.
     * @param relayerFee The amount distributed to the relayer. This is subtracted from the `amount`.
     */
    function distribute(
        address recipient,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline,
        address relayer,
        uint256 relayerFee
    )
        external
        onlyL1Bridge
        nonReentrant
    {
        _distribute(recipient, amount, amountOutMin, deadline, relayer, relayerFee);

        emit TransferFromL1Completed(
            recipient,
            amount,
            amountOutMin,
            deadline,
            relayer,
            relayerFee
        );
    }

    /**
     * @dev Allows the Bonder to bond an individual withdrawal and swap it in the AMM for the
     * canonical token on behalf of the user.
     * @param recipient The address receiving the Transfer
     * @param amount The amount being transferred including the `_bonderFee`
     * @param transferNonce Used to avoid transferId collisions
     * @param bonderFee The amount paid to the address that withdraws the Transfer
     * @param amountOutMin The minimum amount received after attempting to swap in the
     * AMM market. 0 if no swap is intended.
     * @param deadline The deadline for swapping in the AMM market. 0 if no
     * swap is intended.
     */
    function bondWithdrawalAndDistribute(
        address recipient,
        uint256 amount,
        bytes32 transferNonce,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline
    )
        external
        onlyBonder
        requirePositiveBalance
        nonReentrant
    {
        bytes32 transferId = getTransferId(
            getChainId(),
            recipient,
            amount,
            transferNonce,
            bonderFee,
            amountOutMin,
            deadline
        );

        _bondWithdrawal(transferId, amount);
        _markTransferSpent(transferId);
        _distribute(recipient, amount, amountOutMin, deadline, msg.sender, bonderFee);
    }

    /**
     * @dev Allows the L1 Bridge to set a TransferRoot
     * @param rootHash The Merkle root of the TransferRoot
     * @param totalAmount The total amount being transferred in the TransferRoot
     */
    function setTransferRoot(bytes32 rootHash, uint256 totalAmount) external onlyL1Bridge {
        _setTransferRoot(rootHash, totalAmount);
    }

    /* ========== Helper Functions ========== */

    function _commitTransfers(uint256 destinationChainId) internal {
        bytes32[] storage pendingTransfers = pendingTransferIdsForChainId[destinationChainId];
        require(pendingTransfers.length > 0, "L2_BRG: Must commit at least 1 Transfer");

        bytes32 rootHash = Lib_MerkleTree.getMerkleRoot(pendingTransfers);
        uint256 totalAmount = pendingAmountForChainId[destinationChainId];
        uint256 rootCommittedAt = block.timestamp;

        emit TransfersCommitted(destinationChainId, rootHash, totalAmount, rootCommittedAt);

        bytes memory confirmTransferRootMessage = abi.encodeWithSignature(
            "confirmTransferRoot(uint256,bytes32,uint256,uint256,uint256)",
            getChainId(),
            rootHash,
            destinationChainId,
            totalAmount,
            rootCommittedAt
        );

        pendingAmountForChainId[destinationChainId] = 0;
        delete pendingTransferIdsForChainId[destinationChainId];

        _sendCrossDomainMessage(confirmTransferRootMessage);
    }

    function _distribute(
        address recipient,
        uint256 amount,
        uint256 amountOutMin,
        uint256 deadline,
        address feeRecipient,
        uint256 fee
    )
        internal
    {
        if (fee > 0) {
            hToken.mint(feeRecipient, fee);
        }
        uint256 amountAfterFee = amount.sub(fee);

        if (amountOutMin == 0 && deadline == 0) {
            hToken.mint(recipient, amountAfterFee);
        } else {
            hToken.mint(address(this), amountAfterFee);
            hToken.approve(address(ammWrapper), amountAfterFee);
            ammWrapper.attemptSwap(recipient, amountAfterFee, amountOutMin, deadline);
        }
    }

    /* ========== Override Functions ========== */

    function _transferFromBridge(address recipient, uint256 amount) internal override {
        hToken.mint(recipient, amount);
    }

    function _transferToBridge(address from, uint256 amount) internal override {
        hToken.burn(from, amount);
    }

    function _requireIsGovernance() internal override {
        _verifySender(l1Governance);
    }

    /* ========== External Config Management Functions ========== */

    function setL1Governance(address _l1Governance) external onlyGovernance {
        l1Governance = _l1Governance;
    }

    function setAmmWrapper(I_L2_AmmWrapper _ammWrapper) external onlyGovernance {
        ammWrapper = _ammWrapper;
    }

    function setL1BridgeAddress(address _l1BridgeAddress) external onlyGovernance {
        l1BridgeAddress = _l1BridgeAddress;
    }

    function setL1BridgeCaller(address _l1BridgeCaller) external onlyGovernance {
        l1BridgeCaller = _l1BridgeCaller;
    }

    function addActiveChainIds(uint256[] calldata chainIds) external onlyGovernance {
        for (uint256 i = 0; i < chainIds.length; i++) {
            activeChainIds[chainIds[i]] = true;
        }
    }

    function removeActiveChainIds(uint256[] calldata chainIds) external onlyGovernance {
        for (uint256 i = 0; i < chainIds.length; i++) {
            activeChainIds[chainIds[i]] = false;
        }
    }

    function setMinimumForceCommitDelay(uint256 _minimumForceCommitDelay) external onlyGovernance {
        minimumForceCommitDelay = _minimumForceCommitDelay;
    }

    function setMaxPendingTransfers(uint256 _maxPendingTransfers) external onlyGovernance {
        maxPendingTransfers = _maxPendingTransfers;
    }

    function setHopBridgeTokenOwner(address newOwner) external onlyGovernance {
        hToken.transferOwnership(newOwner);
    }

    function setMinimumBonderFeeRequirements(uint256 _minBonderBps, uint256 _minBonderFeeAbsolute) external onlyGovernance {
        require(_minBonderBps <= 10000, "L2_BRG: minBonderBps must not exceed 10000");
        minBonderBps = _minBonderBps;
        minBonderFeeAbsolute = _minBonderFeeAbsolute;
    }

    /* ========== Public Getters ========== */

    function getNextTransferNonce() public view returns (bytes32) {
        return keccak256(abi.encodePacked(NONCE_DOMAIN_SEPARATOR, getChainId(), transferNonceIncrementer));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

interface I_L2_PolygonMessengerProxy {
    function sendCrossDomainMessage(bytes memory _calldata) external;
    function xDomainMessageSender() external view returns (address);
    function processMessageFromRoot(
        bytes calldata message
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "./Accounting.sol";
import "../libraries/Lib_MerkleTree.sol";

/**
 * @dev Bridge extends the accounting system and encapsulates the logic that is shared by both the
 * L1 and L2 Bridges. It allows to TransferRoots to be set by parent contracts and for those
 * TransferRoots to be withdrawn against. It also allows the bonder to bond and withdraw Transfers
 * directly through `bondWithdrawal` and then settle those bonds against their TransferRoot once it
 * has been set.
 */

abstract contract Bridge is Accounting {
    using Lib_MerkleTree for bytes32;

    struct TransferRoot {
        uint256 total;
        uint256 amountWithdrawn;
        uint256 createdAt;
    }

    /* ========== Events ========== */

    event Withdrew(
        bytes32 indexed transferId,
        address indexed recipient,
        uint256 amount,
        bytes32 transferNonce
    );

    event WithdrawalBonded(
        bytes32 indexed transferId,
        uint256 amount
    );

    event WithdrawalBondSettled(
        address indexed bonder,
        bytes32 indexed transferId,
        bytes32 indexed rootHash
    );

    event MultipleWithdrawalsSettled(
        address indexed bonder,
        bytes32 indexed rootHash,
        uint256 totalBondsSettled
    );

    event TransferRootSet(
        bytes32 indexed rootHash,
        uint256 totalAmount
    );

    /* ========== State ========== */

    mapping(bytes32 => TransferRoot) private _transferRoots;
    mapping(bytes32 => bool) private _spentTransferIds;
    mapping(address => mapping(bytes32 => uint256)) private _bondedWithdrawalAmounts;

    uint256 constant RESCUE_DELAY = 8 weeks;

    constructor(address[] memory bonders) public Accounting(bonders) {}

    /* ========== Public Getters ========== */

    /**
     * @dev Get the hash that represents an individual Transfer.
     * @param chainId The id of the destination chain
     * @param recipient The address receiving the Transfer
     * @param amount The amount being transferred including the `_bonderFee`
     * @param transferNonce Used to avoid transferId collisions
     * @param bonderFee The amount paid to the address that withdraws the Transfer
     * @param amountOutMin The minimum amount received after attempting to swap in the destination
     * AMM market. 0 if no swap is intended.
     * @param deadline The deadline for swapping in the destination AMM market. 0 if no
     * swap is intended.
     */
    function getTransferId(
        uint256 chainId,
        address recipient,
        uint256 amount,
        bytes32 transferNonce,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline
    )
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(
            chainId,
            recipient,
            amount,
            transferNonce,
            bonderFee,
            amountOutMin,
            deadline
        ));
    }

    /**
     * @notice getChainId can be overridden by subclasses if needed for compatibility or testing purposes.
     * @dev Get the current chainId
     * @return chainId The current chainId
     */
    function getChainId() public virtual view returns (uint256 chainId) {
        this; // Silence state mutability warning without generating any additional byte code
        assembly {
            chainId := chainid()
        }
    }

    /**
     * @dev Get the TransferRoot id for a given rootHash and totalAmount
     * @param rootHash The Merkle root of the TransferRoot
     * @param totalAmount The total of all Transfers in the TransferRoot
     * @return The calculated transferRootId
     */
    function getTransferRootId(bytes32 rootHash, uint256 totalAmount) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(rootHash, totalAmount));
    }

    /**
     * @dev Get the TransferRoot for a given rootHash and totalAmount
     * @param rootHash The Merkle root of the TransferRoot
     * @param totalAmount The total of all Transfers in the TransferRoot
     * @return The TransferRoot with the calculated transferRootId
     */
    function getTransferRoot(bytes32 rootHash, uint256 totalAmount) public view returns (TransferRoot memory) {
        return _transferRoots[getTransferRootId(rootHash, totalAmount)];
    }

    /**
     * @dev Get the amount bonded for the withdrawal of a transfer
     * @param bonder The Bonder of the withdrawal
     * @param transferId The Transfer's unique identifier
     * @return The amount bonded for a Transfer withdrawal
     */
    function getBondedWithdrawalAmount(address bonder, bytes32 transferId) external view returns (uint256) {
        return _bondedWithdrawalAmounts[bonder][transferId];
    }

    /**
     * @dev Get the spent status of a transfer ID
     * @param transferId The transfer's unique identifier
     * @return True if the transferId has been spent
     */
    function isTransferIdSpent(bytes32 transferId) external view returns (bool) {
        return _spentTransferIds[transferId];
    }

    /* ========== User/Relayer External Functions ========== */

    /**
     * @notice Can be called by anyone (recipient or relayer)
     * @dev Withdraw a Transfer from its destination bridge
     * @param recipient The address receiving the Transfer
     * @param amount The amount being transferred including the `_bonderFee`
     * @param transferNonce Used to avoid transferId collisions
     * @param bonderFee The amount paid to the address that withdraws the Transfer
     * @param amountOutMin The minimum amount received after attempting to swap in the destination
     * AMM market. 0 if no swap is intended. (only used to calculate `transferId` in this function)
     * @param deadline The deadline for swapping in the destination AMM market. 0 if no
     * swap is intended. (only used to calculate `transferId` in this function)
     * @param rootHash The Merkle root of the TransferRoot
     * @param transferRootTotalAmount The total amount being transferred in a TransferRoot
     * @param transferIdTreeIndex The index of the transferId in the Merkle tree
     * @param siblings The siblings of the transferId in the Merkle tree
     * @param totalLeaves The total number of leaves in the Merkle tree
     */
    function withdraw(
        address recipient,
        uint256 amount,
        bytes32 transferNonce,
        uint256 bonderFee,
        uint256 amountOutMin,
        uint256 deadline,
        bytes32 rootHash,
        uint256 transferRootTotalAmount,
        uint256 transferIdTreeIndex,
        bytes32[] calldata siblings,
        uint256 totalLeaves
    )
        external
        nonReentrant
    {
        bytes32 transferId = getTransferId(
            getChainId(),
            recipient,
            amount,
            transferNonce,
            bonderFee,
            amountOutMin,
            deadline
        );

        require(
            rootHash.verify(
                transferId,
                transferIdTreeIndex,
                siblings,
                totalLeaves
            )
        , "BRG: Invalid transfer proof");
        bytes32 transferRootId = getTransferRootId(rootHash, transferRootTotalAmount);
        _addToAmountWithdrawn(transferRootId, amount);
        _fulfillWithdraw(transferId, recipient, amount, uint256(0));

        emit Withdrew(transferId, recipient, amount, transferNonce);
    }

    /**
     * @dev Allows the bonder to bond individual withdrawals before their TransferRoot has been committed.
     * @param recipient The address receiving the Transfer
     * @param amount The amount being transferred including the `_bonderFee`
     * @param transferNonce Used to avoid transferId collisions
     * @param bonderFee The amount paid to the address that withdraws the Transfer
     */
    function bondWithdrawal(
        address recipient,
        uint256 amount,
        bytes32 transferNonce,
        uint256 bonderFee
    )
        external
        onlyBonder
        requirePositiveBalance
        nonReentrant
    {
        bytes32 transferId = getTransferId(
            getChainId(),
            recipient,
            amount,
            transferNonce,
            bonderFee,
            0,
            0
        );

        _bondWithdrawal(transferId, amount);
        _fulfillWithdraw(transferId, recipient, amount, bonderFee);
    }

    /**
     * @dev Refunds the Bonder's stake from a bonded withdrawal and counts that withdrawal against
     * its TransferRoot.
     * @param bonder The Bonder of the withdrawal
     * @param transferId The Transfer's unique identifier
     * @param rootHash The Merkle root of the TransferRoot
     * @param transferRootTotalAmount The total amount being transferred in a TransferRoot
     * @param transferIdTreeIndex The index of the transferId in the Merkle tree
     * @param siblings The siblings of the transferId in the Merkle tree
     * @param totalLeaves The total number of leaves in the Merkle tree
     */
    function settleBondedWithdrawal(
        address bonder,
        bytes32 transferId,
        bytes32 rootHash,
        uint256 transferRootTotalAmount,
        uint256 transferIdTreeIndex,
        bytes32[] calldata siblings,
        uint256 totalLeaves
    )
        external
    {
        require(
            rootHash.verify(
                transferId,
                transferIdTreeIndex,
                siblings,
                totalLeaves
            )
        , "BRG: Invalid transfer proof");
        bytes32 transferRootId = getTransferRootId(rootHash, transferRootTotalAmount);

        uint256 amount = _bondedWithdrawalAmounts[bonder][transferId];
        require(amount > 0, "L2_BRG: transferId has no bond");

        _bondedWithdrawalAmounts[bonder][transferId] = 0;
        _addToAmountWithdrawn(transferRootId, amount);
        _addCredit(bonder, amount);

        emit WithdrawalBondSettled(bonder, transferId, rootHash);
    }

    /**
     * @dev Refunds the Bonder for all withdrawals that they bonded in a TransferRoot.
     * @param bonder The address of the Bonder being refunded
     * @param transferIds All transferIds in the TransferRoot in order
     * @param totalAmount The totalAmount of the TransferRoot
     */
    function settleBondedWithdrawals(
        address bonder,
        // transferIds _must_ be calldata or it will be mutated by Lib_MerkleTree.getMerkleRoot
        bytes32[] calldata transferIds,
        uint256 totalAmount
    )
        external
    {
        bytes32 rootHash = Lib_MerkleTree.getMerkleRoot(transferIds);
        bytes32 transferRootId = getTransferRootId(rootHash, totalAmount);

        uint256 totalBondsSettled = 0;
        for(uint256 i = 0; i < transferIds.length; i++) {
            uint256 transferBondAmount = _bondedWithdrawalAmounts[bonder][transferIds[i]];
            if (transferBondAmount > 0) {
                totalBondsSettled = totalBondsSettled.add(transferBondAmount);
                _bondedWithdrawalAmounts[bonder][transferIds[i]] = 0;
            }
        }

        _addToAmountWithdrawn(transferRootId, totalBondsSettled);
        _addCredit(bonder, totalBondsSettled);

        emit MultipleWithdrawalsSettled(bonder, rootHash, totalBondsSettled);
    }

    /* ========== External TransferRoot Rescue ========== */

    /**
     * @dev Allows governance to withdraw the remaining amount from a TransferRoot after the rescue delay has passed.
     * @param rootHash the Merkle root of the TransferRoot
     * @param originalAmount The TransferRoot's recorded total
     * @param recipient The address receiving the remaining balance
     */
    function rescueTransferRoot(bytes32 rootHash, uint256 originalAmount, address recipient) external onlyGovernance {
        bytes32 transferRootId = getTransferRootId(rootHash, originalAmount);
        TransferRoot memory transferRoot = getTransferRoot(rootHash, originalAmount);

        require(transferRoot.createdAt != 0, "BRG: TransferRoot not found");
        assert(transferRoot.total == originalAmount);
        uint256 rescueDelayEnd = transferRoot.createdAt.add(RESCUE_DELAY);
        require(block.timestamp >= rescueDelayEnd, "BRG: TransferRoot cannot be rescued before the Rescue Delay");

        uint256 remainingAmount = transferRoot.total.sub(transferRoot.amountWithdrawn);
        _addToAmountWithdrawn(transferRootId, remainingAmount);
        _transferFromBridge(recipient, remainingAmount);
    }

    /* ========== Internal Functions ========== */

    function _markTransferSpent(bytes32 transferId) internal {
        require(!_spentTransferIds[transferId], "BRG: The transfer has already been withdrawn");
        _spentTransferIds[transferId] = true;
    }

    function _addToAmountWithdrawn(bytes32 transferRootId, uint256 amount) internal {
        TransferRoot storage transferRoot = _transferRoots[transferRootId];
        require(transferRoot.total > 0, "BRG: Transfer root not found");

        uint256 newAmountWithdrawn = transferRoot.amountWithdrawn.add(amount);
        require(newAmountWithdrawn <= transferRoot.total, "BRG: Withdrawal exceeds TransferRoot total");

        transferRoot.amountWithdrawn = newAmountWithdrawn;
    }

    function _setTransferRoot(bytes32 rootHash, uint256 totalAmount) internal {
        bytes32 transferRootId = getTransferRootId(rootHash, totalAmount);
        require(_transferRoots[transferRootId].total == 0, "BRG: Transfer root already set");
        require(totalAmount > 0, "BRG: Cannot set TransferRoot totalAmount of 0");

        _transferRoots[transferRootId] = TransferRoot(totalAmount, 0, block.timestamp);

        emit TransferRootSet(rootHash, totalAmount);
    }

    function _bondWithdrawal(bytes32 transferId, uint256 amount) internal {
        require(_bondedWithdrawalAmounts[msg.sender][transferId] == 0, "BRG: Withdrawal has already been bonded");
        _addDebit(msg.sender, amount);
        _bondedWithdrawalAmounts[msg.sender][transferId] = amount;

        emit WithdrawalBonded(transferId, amount);
    }

    /* ========== Private Functions ========== */

    /// @dev Completes the Transfer, distributes the Bonder fee and marks the Transfer as spent.
    function _fulfillWithdraw(
        bytes32 transferId,
        address recipient,
        uint256 amount,
        uint256 bonderFee
    ) private {
        _markTransferSpent(transferId);
        _transferFromBridge(recipient, amount.sub(bonderFee));
        if (bonderFee > 0) {
            _transferFromBridge(msg.sender, bonderFee);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Hop Bridge Tokens or "hTokens" are layer-2 tokens that represent a deposit in the L1_Bridge
 * contract. Each Hop Bridge Token is a regular ERC20 that can be minted and burned by the L2_Bridge
 * that owns it.
 */

contract HopBridgeToken is ERC20, Ownable {

    constructor (
        string memory name,
        string memory symbol,
        uint8 decimals
    )
        public
        ERC20(name, symbol)
    {
        _setupDecimals(decimals);
    }

    /**
     * @dev Mint new hToken for the account
     * @param account The account being minted for
     * @param amount The amount being minted
     */
    function mint(address account, uint256 amount) external onlyOwner {
        _mint(account, amount);
    }

    /**
     * @dev Burn hToken from the account
     * @param account The account being burned from
     * @param amount The amount being burned
     */
    function burn(address account, uint256 amount) external onlyOwner {
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >0.5.0 <0.8.0;

/**
 * @title Lib_MerkleTree
 * @author River Keefer
 */
library Lib_MerkleTree {

    /**********************
     * Internal Functions *
     **********************/

    /**
     * Calculates a merkle root for a list of 32-byte leaf hashes.  WARNING: If the number
     * of leaves passed in is not a power of two, it pads out the tree with zero hashes.
     * If you do not know the original length of elements for the tree you are verifying,
     * then this may allow empty leaves past _elements.length to pass a verification check down the line.
     * Note that the _elements argument is modified, therefore it must not be used again afterwards
     * @param _elements Array of hashes from which to generate a merkle root.
     * @return Merkle root of the leaves, with zero hashes for non-powers-of-two (see above).
     */
    function getMerkleRoot(
        bytes32[] memory _elements
    )
        internal
        pure
        returns (
            bytes32
        )
    {
        require(
            _elements.length > 0,
            "Lib_MerkleTree: Must provide at least one leaf hash."
        );

        if (_elements.length == 1) {
            return _elements[0];
        }

        uint256[16] memory defaults = [
            0x290decd9548b62a8d60345a988386fc84ba6bc95484008f6362f93160ef3e563,
            0x633dc4d7da7256660a892f8f1604a44b5432649cc8ec5cb3ced4c4e6ac94dd1d,
            0x890740a8eb06ce9be422cb8da5cdafc2b58c0a5e24036c578de2a433c828ff7d,
            0x3b8ec09e026fdc305365dfc94e189a81b38c7597b3d941c279f042e8206e0bd8,
            0xecd50eee38e386bd62be9bedb990706951b65fe053bd9d8a521af753d139e2da,
            0xdefff6d330bb5403f63b14f33b578274160de3a50df4efecf0e0db73bcdd3da5,
            0x617bdd11f7c0a11f49db22f629387a12da7596f9d1704d7465177c63d88ec7d7,
            0x292c23a9aa1d8bea7e2435e555a4a60e379a5a35f3f452bae60121073fb6eead,
            0xe1cea92ed99acdcb045a6726b2f87107e8a61620a232cf4d7d5b5766b3952e10,
            0x7ad66c0a68c72cb89e4fb4303841966e4062a76ab97451e3b9fb526a5ceb7f82,
            0xe026cc5a4aed3c22a58cbd3d2ac754c9352c5436f638042dca99034e83636516,
            0x3d04cffd8b46a874edf5cfae63077de85f849a660426697b06a829c70dd1409c,
            0xad676aa337a485e4728a0b240d92b3ef7b3c372d06d189322bfd5f61f1e7203e,
            0xa2fca4a49658f9fab7aa63289c91b7c7b6c832a6d0e69334ff5b0a3483d09dab,
            0x4ebfd9cd7bca2505f7bef59cc1c12ecc708fff26ae4af19abe852afe9e20c862,
            0x2def10d13dd169f550f578bda343d9717a138562e0093b380a1120789d53cf10
        ];

        // Reserve memory space for our hashes.
        bytes memory buf = new bytes(64);

        // We'll need to keep track of left and right siblings.
        bytes32 leftSibling;
        bytes32 rightSibling;

        // Number of non-empty nodes at the current depth.
        uint256 rowSize = _elements.length;

        // Current depth, counting from 0 at the leaves
        uint256 depth = 0;

        // Common sub-expressions
        uint256 halfRowSize;         // rowSize / 2
        bool rowSizeIsOdd;           // rowSize % 2 == 1

        while (rowSize > 1) {
            halfRowSize = rowSize / 2;
            rowSizeIsOdd = rowSize % 2 == 1;

            for (uint256 i = 0; i < halfRowSize; i++) {
                leftSibling  = _elements[(2 * i)    ];
                rightSibling = _elements[(2 * i) + 1];
                assembly {
                    mstore(add(buf, 32), leftSibling )
                    mstore(add(buf, 64), rightSibling)
                }

                _elements[i] = keccak256(buf);
            }

            if (rowSizeIsOdd) {
                leftSibling  = _elements[rowSize - 1];
                rightSibling = bytes32(defaults[depth]);
                assembly {
                    mstore(add(buf, 32), leftSibling)
                    mstore(add(buf, 64), rightSibling)
                }

                _elements[halfRowSize] = keccak256(buf);
            }

            rowSize = halfRowSize + (rowSizeIsOdd ? 1 : 0);
            depth++;
        }

        return _elements[0];
    }

    /**
     * Verifies a merkle branch for the given leaf hash.  Assumes the original length
     * of leaves generated is a known, correct input, and does not return true for indices
     * extending past that index (even if _siblings would be otherwise valid.)
     * @param _root The Merkle root to verify against.
     * @param _leaf The leaf hash to verify inclusion of.
     * @param _index The index in the tree of this leaf.
     * @param _siblings Array of sibline nodes in the inclusion proof, starting from depth 0 (bottom of the tree).
     * @param _totalLeaves The total number of leaves originally passed into.
     * @return Whether or not the merkle branch and leaf passes verification.
     */
    function verify(
        bytes32 _root,
        bytes32 _leaf,
        uint256 _index,
        bytes32[] memory _siblings,
        uint256 _totalLeaves
    )
        internal
        pure
        returns (
            bool
        )
    {
        require(
            _totalLeaves > 0,
            "Lib_MerkleTree: Total leaves must be greater than zero."
        );

        require(
            _index < _totalLeaves,
            "Lib_MerkleTree: Index out of bounds."
        );

        require(
            _siblings.length == _ceilLog2(_totalLeaves),
            "Lib_MerkleTree: Total siblings does not correctly correspond to total leaves."
        );

        bytes32 computedRoot = _leaf;

        for (uint256 i = 0; i < _siblings.length; i++) {
            if ((_index & 1) == 1) {
                computedRoot = keccak256(
                    abi.encodePacked(
                        _siblings[i],
                        computedRoot
                    )
                );
            } else {
                computedRoot = keccak256(
                    abi.encodePacked(
                        computedRoot,
                        _siblings[i]
                    )
                );
            }

            _index >>= 1;
        }

        return _root == computedRoot;
    }


    /*********************
     * Private Functions *
     *********************/

    /**
     * Calculates the integer ceiling of the log base 2 of an input.
     * @param _in Unsigned input to calculate the log.
     * @return ceil(log_base_2(_in))
     */
    function _ceilLog2(
        uint256 _in
    )
        private
        pure
        returns (
            uint256
        )
    {
        require(
            _in > 0,
            "Lib_MerkleTree: Cannot compute ceil(log_2) of 0."
        );

        if (_in == 1) {
            return 0;
        }

        // Find the highest set bit (will be floor(log_2)).
        // Borrowed with <3 from https://github.com/ethereum/solidity-examples
        uint256 val = _in;
        uint256 highest = 0;
        for (uint256 i = 128; i >= 1; i >>= 1) {
            if (val & (uint(1) << i) - 1 << i != 0) {
                highest += i;
                val >>= i;
            }
        }

        // Increment by one if this is not a perfect logarithm.
        if ((uint(1) << highest) != _in) {
            highest += 1;
        }

        return highest;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/**
 * @dev Accounting is an abstract contract that encapsulates the most critical logic in the Hop contracts.
 * The accounting system works by using two balances that can only increase `_credit` and `_debit`.
 * A bonder's available balance is the total credit minus the total debit. The contract exposes
 * two external functions that allows a bonder to stake and unstake and exposes two internal
 * functions to its child contracts that allow the child contract to add to the credit 
 * and debit balance. In addition, child contracts can override `_additionalDebit` to account
 * for any additional debit balance in an alternative way. Lastly, it exposes a modifier,
 * `requirePositiveBalance`, that can be used by child contracts to ensure the bonder does not
 * use more than its available stake.
 */

abstract contract Accounting is ReentrancyGuard {
    using SafeMath for uint256;

    mapping(address => bool) private _isBonder;

    mapping(address => uint256) private _credit;
    mapping(address => uint256) private _debit;

    event Stake (
        address indexed account,
        uint256 amount
    );

    event Unstake (
        address indexed account,
        uint256 amount
    );

    event BonderAdded (
        address indexed newBonder
    );

    event BonderRemoved (
        address indexed previousBonder
    );

    /* ========== Modifiers ========== */

    modifier onlyBonder {
        require(_isBonder[msg.sender], "ACT: Caller is not bonder");
        _;
    }

    modifier onlyGovernance {
        _requireIsGovernance();
        _;
    }

    /// @dev Used by parent contract to ensure that the Bonder is solvent at the end of the transaction.
    modifier requirePositiveBalance {
        _;
        require(getCredit(msg.sender) >= getDebitAndAdditionalDebit(msg.sender), "ACT: Not enough available credit");
    }

    /// @dev Sets the Bonder addresses
    constructor(address[] memory bonders) public {
        for (uint256 i = 0; i < bonders.length; i++) {
            require(_isBonder[bonders[i]] == false, "ACT: Cannot add duplicate bonder");
            _isBonder[bonders[i]] = true;
            emit BonderAdded(bonders[i]);
        }
    }

    /* ========== Virtual functions ========== */
    /**
     * @dev The following functions are overridden in L1_Bridge and L2_Bridge
     */
    function _transferFromBridge(address recipient, uint256 amount) internal virtual;
    function _transferToBridge(address from, uint256 amount) internal virtual;
    function _requireIsGovernance() internal virtual;

    /**
     * @dev This function can be optionally overridden by a parent contract to track any additional
     * debit balance in an alternative way.
     */
    function _additionalDebit(address /*bonder*/) internal view virtual returns (uint256) {
        this; // Silence state mutability warning without generating any additional byte code
        return 0;
    }

    /* ========== Public/external getters ========== */

    /**
     * @dev Check if address is a Bonder
     * @param maybeBonder The address being checked
     * @return true if address is a Bonder
     */
    function getIsBonder(address maybeBonder) public view returns (bool) {
        return _isBonder[maybeBonder];
    }

    /**
     * @dev Get the Bonder's credit balance
     * @param bonder The owner of the credit balance being checked
     * @return The credit balance for the Bonder
     */
    function getCredit(address bonder) public view returns (uint256) {
        return _credit[bonder];
    }

    /**
     * @dev Gets the debit balance tracked by `_debit` and does not include `_additionalDebit()`
     * @param bonder The owner of the debit balance being checked
     * @return The debit amount for the Bonder
     */
    function getRawDebit(address bonder) external view returns (uint256) {
        return _debit[bonder];
    }

    /**
     * @dev Get the Bonder's total debit
     * @param bonder The owner of the debit balance being checked
     * @return The Bonder's total debit balance
     */
    function getDebitAndAdditionalDebit(address bonder) public view returns (uint256) {
        return _debit[bonder].add(_additionalDebit(bonder));
    }

    /* ========== Bonder external functions ========== */

    /** 
     * @dev Allows the Bonder to deposit tokens and increase its credit balance
     * @param bonder The address being staked on
     * @param amount The amount being staked
     */
    function stake(address bonder, uint256 amount) external payable nonReentrant {
        require(_isBonder[bonder] == true, "ACT: Address is not bonder");
        _transferToBridge(msg.sender, amount);
        _addCredit(bonder, amount);

        emit Stake(bonder, amount);
    }

    /**
     * @dev Allows the caller to withdraw any available balance and add to their debit balance
     * @param amount The amount being unstaked
     */
    function unstake(uint256 amount) external requirePositiveBalance nonReentrant {
        _addDebit(msg.sender, amount);
        _transferFromBridge(msg.sender, amount);

        emit Unstake(msg.sender, amount);
    }

    /**
     * @dev Add Bonder to allowlist
     * @param bonder The address being added as a Bonder
     */
    function addBonder(address bonder) external onlyGovernance {
        require(_isBonder[bonder] == false, "ACT: Address is already bonder");
        _isBonder[bonder] = true;

        emit BonderAdded(bonder);
    }

    /**
     * @dev Remove Bonder from allowlist
     * @param bonder The address being removed as a Bonder
     */
    function removeBonder(address bonder) external onlyGovernance {
        require(_isBonder[bonder] == true, "ACT: Address is not bonder");
        _isBonder[bonder] = false;

        emit BonderRemoved(bonder);
    }

    /* ========== Internal functions ========== */

    function _addCredit(address bonder, uint256 amount) internal {
        _credit[bonder] = _credit[bonder].add(amount);
    }

    function _addDebit(address bonder, uint256 amount) internal {
        _debit[bonder] = _debit[bonder].add(amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC20.sol";
import "../../math/SafeMath.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(amount, "ERC20: burn amount exceeds balance");
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal virtual {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

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