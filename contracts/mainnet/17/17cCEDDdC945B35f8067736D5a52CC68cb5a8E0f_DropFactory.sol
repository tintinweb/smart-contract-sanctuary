// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/Create2.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IDropFactory.sol";

import "./Drop.sol";

contract DropFactory is IDropFactory {
    using SafeERC20 for IERC20;

    uint256 public fee;
    address public feeReceiver;
    address public timelock;
    mapping(address => address) public drops;

    constructor(
        uint256 _fee,
        address _feeReceiver,
        address _timelock
    ) {
        fee = _fee;
        feeReceiver = _feeReceiver;
        timelock = _timelock;
    }

    modifier dropExists(address tokenAddress) {
        require(drops[tokenAddress] != address(0), "FACTORY_DROP_DOES_NOT_EXIST");
        _;
    }

    modifier onlyTimelock() {
        require(msg.sender == timelock, "FACTORY_ONLY_TIMELOCK");
        _;
    }

    function createDrop(address tokenAddress) external override {
        require(drops[tokenAddress] == address(0), "FACTORY_DROP_EXISTS");
        bytes memory bytecode = type(Drop).creationCode;
        bytes32 salt = keccak256(abi.encodePacked(tokenAddress));
        address dropAddress = Create2.deploy(0, salt, bytecode);
        Drop(dropAddress).initialize(tokenAddress);
        drops[tokenAddress] = dropAddress;
        emit DropCreated(dropAddress, tokenAddress);
    }

    function addDropData(
        uint256 tokenAmount,
        uint256 startDate,
        uint256 endDate,
        bytes32 merkleRoot,
        address tokenAddress
    ) external override dropExists(tokenAddress) {
        address dropAddress = drops[tokenAddress];
        IERC20(tokenAddress).safeTransferFrom(msg.sender, dropAddress, tokenAmount);
        Drop(dropAddress).addDropData(msg.sender, merkleRoot, startDate, endDate, tokenAmount);
        emit DropDataAdded(tokenAddress, merkleRoot, tokenAmount, startDate, endDate);
    }

    function updateDropData(
        uint256 additionalTokenAmount,
        uint256 startDate,
        uint256 endDate,
        bytes32 oldMerkleRoot,
        bytes32 newMerkleRoot,
        address tokenAddress
    ) external override dropExists(tokenAddress) {
        address dropAddress = drops[tokenAddress];
        IERC20(tokenAddress).safeTransferFrom(msg.sender, dropAddress, additionalTokenAmount);
        uint256 tokenAmount = Drop(dropAddress).update(msg.sender, oldMerkleRoot, newMerkleRoot, startDate, endDate, additionalTokenAmount);
        emit DropDataUpdated(tokenAddress, oldMerkleRoot, newMerkleRoot, tokenAmount, startDate, endDate);
    }

    function claimFromDrop(
        address tokenAddress,
        uint256 index,
        uint256 amount,
        bytes32 merkleRoot,
        bytes32[] calldata merkleProof
    ) external override dropExists(tokenAddress) {
        Drop(drops[tokenAddress]).claim(index, msg.sender, amount, fee, feeReceiver, merkleRoot, merkleProof);
        emit DropClaimed(tokenAddress, index, msg.sender, amount, merkleRoot);
    }

    function multipleClaimsFromDrop(
        address tokenAddress,
        uint256[] calldata indexes,
        uint256[] calldata amounts,
        bytes32[] calldata merkleRoots,
        bytes32[][] calldata merkleProofs
    ) external override dropExists(tokenAddress) {
        uint256 tempFee = fee;
        address tempFeeReceiver = feeReceiver;
        for (uint256 i = 0; i < indexes.length; i++) {
            Drop(drops[tokenAddress]).claim(indexes[i], msg.sender, amounts[i], tempFee, tempFeeReceiver, merkleRoots[i], merkleProofs[i]);
            emit DropClaimed(tokenAddress, indexes[i], msg.sender, amounts[i], merkleRoots[i]);
        }
    }

    function withdraw(address tokenAddress, bytes32 merkleRoot) external override dropExists(tokenAddress) {
        uint256 withdrawAmount = Drop(drops[tokenAddress]).withdraw(msg.sender, merkleRoot);
        emit DropWithdrawn(tokenAddress, msg.sender, merkleRoot, withdrawAmount);
    }

    function updateFee(uint256 newFee) external override onlyTimelock {
        // max fee 20%
        require(newFee < 2000, "FACTORY_MAX_FEE_EXCEED");
        fee = newFee;
    }

    function updateFeeReceiver(address newFeeReceiver) external override onlyTimelock {
        feeReceiver = newFeeReceiver;
    }

    function pause(address tokenAddress, bytes32 merkleRoot) external override {
        Drop(drops[tokenAddress]).pause(msg.sender, merkleRoot);
        emit DropPaused(merkleRoot);
    }

    function unpause(address tokenAddress, bytes32 merkleRoot) external override {
        Drop(drops[tokenAddress]).unpause(msg.sender, merkleRoot);
        emit DropUnpaused(merkleRoot);
    }

    function getDropDetails(address tokenAddress, bytes32 merkleRoot)
        external
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            address,
            bool
        )
    {
        return Drop(drops[tokenAddress]).dropData(merkleRoot);
    }

    function isDropClaimed(
        address tokenAddress,
        uint256 index,
        bytes32 merkleRoot
    ) external view override dropExists(tokenAddress) returns (bool) {
        return Drop(drops[tokenAddress]).isClaimed(index, merkleRoot);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Helper to make usage of the `CREATE2` EVM opcode easier and safer.
 * `CREATE2` can be used to compute in advance the address where a smart
 * contract will be deployed, which allows for interesting new mechanisms known
 * as 'counterfactual interactions'.
 *
 * See the https://eips.ethereum.org/EIPS/eip-1014#motivation[EIP] for more
 * information.
 */
library Create2 {
    /**
     * @dev Deploys a contract using `CREATE2`. The address where the contract
     * will be deployed can be known in advance via {computeAddress}.
     *
     * The bytecode for a contract can be obtained from Solidity with
     * `type(contractName).creationCode`.
     *
     * Requirements:
     *
     * - `bytecode` must not be empty.
     * - `salt` must have not been used for `bytecode` already.
     * - the factory must have a balance of at least `amount`.
     * - if `amount` is non-zero, `bytecode` must have a `payable` constructor.
     */
    function deploy(uint256 amount, bytes32 salt, bytes memory bytecode) internal returns (address) {
        address addr;
        require(address(this).balance >= amount, "Create2: insufficient balance");
        require(bytecode.length != 0, "Create2: bytecode length is zero");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            addr := create2(amount, add(bytecode, 0x20), mload(bytecode), salt)
        }
        require(addr != address(0), "Create2: Failed on deploy");
        return addr;
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy}. Any change in the
     * `bytecodeHash` or `salt` will result in a new destination address.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash) internal view returns (address) {
        return computeAddress(salt, bytecodeHash, address(this));
    }

    /**
     * @dev Returns the address where a contract will be stored if deployed via {deploy} from a contract located at
     * `deployer`. If `deployer` is this contract's address, returns the same value as {computeAddress}.
     */
    function computeAddress(bytes32 salt, bytes32 bytecodeHash, address deployer) internal pure returns (address) {
        bytes32 _data = keccak256(
            abi.encodePacked(bytes1(0xff), deployer, salt, bytecodeHash)
        );
        return address(uint160(uint256(_data)));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

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
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
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
pragma solidity 0.8.7;

interface IDropFactory {
    function createDrop(address tokenAddress) external;

    function addDropData(
        uint256 tokenAmount,
        uint256 startDate,
        uint256 endDate,
        bytes32 merkleRoot,
        address tokenAddress
    ) external;

    function updateDropData(
        uint256 additionalTokenAmount,
        uint256 startDate,
        uint256 endDate,
        bytes32 oldMerkleRoot,
        bytes32 newMerkleRoot,
        address tokenAddress
    ) external;

    function claimFromDrop(
        address tokenAddress,
        uint256 index,
        uint256 amount,
        bytes32 merkleRoot,
        bytes32[] calldata merkleProof
    ) external;

    function multipleClaimsFromDrop(
        address tokenAddress,
        uint256[] calldata indexes,
        uint256[] calldata amounts,
        bytes32[] calldata merkleRoots,
        bytes32[][] calldata merkleProofs
    ) external;

    function withdraw(address tokenAddress, bytes32 merkleRoot) external;

    function pause(address tokenAddress, bytes32 merkleRoot) external;

    function unpause(address tokenAddress, bytes32 merkleRoot) external;

    function updateFeeReceiver(address newFeeReceiver) external;

    function updateFee(uint256 newFee) external;

    function isDropClaimed(
        address tokenAddress,
        uint256 index,
        bytes32 merkleRoot
    ) external view returns (bool);

    function getDropDetails(address tokenAddress, bytes32 merkleRoot)
        external
        view
        returns (
            uint256,
            uint256,
            uint256,
            address,
            bool
        );

    event DropCreated(address indexed dropAddress, address indexed tokenAddress);
    event DropDataAdded(address indexed tokenAddress, bytes32 merkleRoot, uint256 tokenAmount, uint256 startDate, uint256 endDate);
    event DropDataUpdated(address indexed tokenAddress, bytes32 oldMerkleRoot, bytes32 newMerkleRoot, uint256 tokenAmount, uint256 startDate, uint256 endDate);
    event DropClaimed(address indexed tokenAddress, uint256 index, address indexed account, uint256 amount, bytes32 indexed merkleRoot);
    event DropWithdrawn(address indexed tokenAddress, address indexed account, bytes32 indexed merkleRoot, uint256 amount);
    event DropPaused(bytes32 merkleRoot);
    event DropUnpaused(bytes32 merkleRoot);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract Drop {
    using MerkleProof for bytes;
    using SafeERC20 for IERC20;

    struct DropData {
        uint256 startDate;
        uint256 endDate;
        uint256 tokenAmount;
        address owner;
        bool isActive;
    }

    address public factory;
    address public token;

    mapping(bytes32 => DropData) public dropData;
    mapping(bytes32 => mapping(uint256 => uint256)) private claimedBitMap;

    constructor() {
        factory = msg.sender;
    }

    modifier onlyFactory {
        require(msg.sender == factory, "DROP_ONLY_FACTORY");
        _;
    }

    function initialize(address tokenAddress) external onlyFactory {
        token = tokenAddress;
    }

    function addDropData(
        address owner,
        bytes32 merkleRoot,
        uint256 startDate,
        uint256 endDate,
        uint256 tokenAmount
    ) external onlyFactory {
        _addDropData(owner, merkleRoot, startDate, endDate, tokenAmount);
    }

    function claim(
        uint256 index,
        address account,
        uint256 amount,
        uint256 fee,
        address feeReceiver,
        bytes32 merkleRoot,
        bytes32[] calldata merkleProof
    ) external onlyFactory {
        DropData memory dd = dropData[merkleRoot];

        require(dd.startDate < block.timestamp, "DROP_NOT_STARTED");
        require(dd.endDate > block.timestamp, "DROP_ENDED");
        require(dd.isActive, "DROP_NOT_ACTIVE");
        require(!isClaimed(index, merkleRoot), "DROP_ALREADY_CLAIMED");

        // Verify the merkle proof.
        bytes32 node = keccak256(abi.encodePacked(index, account, amount));
        require(MerkleProof.verify(merkleProof, merkleRoot, node), "DROP_INVALID_PROOF");

        // Calculate fees
        uint256 feeAmount = (amount * fee) / 10000;
        uint256 userReceivedAmount = amount - feeAmount;

        // Subtract from the drop amount
        dropData[merkleRoot].tokenAmount -= amount;

        // Mark it claimed and send the tokens.
        _setClaimed(index, merkleRoot);
        IERC20(token).safeTransfer(account, userReceivedAmount);
        if (feeAmount > 0) {
            IERC20(token).safeTransfer(feeReceiver, feeAmount);
        }
    }

    function _addDropData(
        address owner,
        bytes32 merkleRoot,
        uint256 startDate,
        uint256 endDate,
        uint256 tokenAmount
    ) internal {
        require(dropData[merkleRoot].startDate == 0, "DROP_EXISTS");
        require(endDate > block.timestamp, "DROP_INVALID_END_DATE");
        require(endDate > startDate, "DROP_INVALID_START_DATE");
        dropData[merkleRoot] = DropData(startDate, endDate, tokenAmount, owner, true);
    }

    function update(
        address account,
        bytes32 merkleRoot,
        bytes32 newMerkleRoot,
        uint256 newStartDate,
        uint256 newEndDate,
        uint256 newTokenAmount
    ) external onlyFactory returns (uint256 tokenAmount) {
        DropData memory dd = dropData[merkleRoot];
        require(dd.owner == account, "DROP_ONLY_OWNER");
        tokenAmount = dd.tokenAmount + newTokenAmount;
        _addDropData(dd.owner, newMerkleRoot, newStartDate, newEndDate, tokenAmount);
        delete dropData[merkleRoot];
    }

    function withdraw(address account, bytes32 merkleRoot) external onlyFactory returns (uint256) {
        DropData memory dd = dropData[merkleRoot];
        require(dd.owner == account, "DROP_ONLY_OWNER");

        delete dropData[merkleRoot];

        IERC20(token).safeTransfer(account, dd.tokenAmount);
        return dd.tokenAmount;
    }

    function isClaimed(uint256 index, bytes32 merkleRoot) public view returns (bool) {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        uint256 claimedWord = claimedBitMap[merkleRoot][claimedWordIndex];
        uint256 mask = (1 << claimedBitIndex);
        return claimedWord & mask == mask;
    }

    function pause(address account, bytes32 merkleRoot) external onlyFactory {
        DropData memory dd = dropData[merkleRoot];
        require(dd.owner == account, "NOT_OWNER");
        dropData[merkleRoot].isActive = false;
    }

    function unpause(address account, bytes32 merkleRoot) external onlyFactory {
        DropData memory dd = dropData[merkleRoot];
        require(dd.owner == account, "NOT_OWNER");
        dropData[merkleRoot].isActive = true;
    }

    function _setClaimed(uint256 index, bytes32 merkleRoot) private {
        uint256 claimedWordIndex = index / 256;
        uint256 claimedBitIndex = index % 256;
        claimedBitMap[merkleRoot][claimedWordIndex] = claimedBitMap[merkleRoot][claimedWordIndex] | (1 << claimedBitIndex);
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

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle trees (hash trees),
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}