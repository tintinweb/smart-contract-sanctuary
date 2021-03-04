/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/math/SafeMath.sol

pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol



pragma solidity ^0.6.0;

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

// File: @openzeppelin/contracts/utils/Address.sol



pragma solidity ^0.6.2;

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
        // This method relies in extcodesize, which returns 0 for contracts in
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
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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

// File: @openzeppelin/contracts/token/ERC20/SafeERC20.sol



pragma solidity ^0.6.0;




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

// File: @openzeppelin/contracts/cryptography/MerkleProof.sol



pragma solidity ^0.6.0;

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

// File: contracts/interfaces/IMerkleBox.sol



pragma solidity 0.6.12;

interface IMerkleBox {
    event NewMerkle(
        address indexed sender,
        address indexed erc20,
        uint256 amount,
        bytes32 indexed merkleRoot,
        uint256 claimGroupId,
        uint256 withdrawUnlockTime,
        string memo
    );
    event MerkleClaim(address indexed account, address indexed erc20, uint256 amount);
    event MerkleFundUpdate(address indexed funder, bytes32 indexed merkleRoot, uint256 claimGroupId, uint256 amount, bool withdraw);

    function addFunds(uint256 claimGroupId, uint256 amount) external;

    function addFundsWithPermit(
        uint256 claimGroupId,
        address funder,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    function withdrawFunds(uint256 claimGroupId, uint256 amount) external;

    function newClaimsGroup(
        address erc20,
        uint256 amount,
        bytes32 merkleRoot,
        uint256 withdrawUnlockTime,
        string calldata memo
    ) external returns (uint256);

    function isClaimable(
        uint256 claimGroupId,
        address account,
        uint256 amount,
        bytes32[] memory proof
    ) external view returns (bool);

    function claim(
        uint256 claimGroupId,
        address account,
        uint256 amount,
        bytes32[] memory proof
    ) external;
}

// File: contracts/interfaces/IERC20WithPermit.sol



pragma solidity 0.6.12;


interface IERC20WithPermit is IERC20 {
    function permit(
        address,
        address,
        uint256,
        uint256,
        uint8,
        bytes32,
        bytes32
    ) external;
}

// File: contracts/MerkleBox.sol



pragma solidity 0.6.12;






contract MerkleBox is IMerkleBox {
    using MerkleProof for MerkleProof;
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20WithPermit;
    using SafeMath for uint256;

    struct Holding {
        address owner; // account that contributed funds
        address erc20; // claim-able ERC20 asset
        uint256 balance; // amount of token held currently
        bytes32 merkleRoot; // root of claims merkle tree
        uint256 withdrawUnlockTime; // withdraw forbidden before this time
        string memo; // an string to store arbitary notes about the holding
    }

    mapping(uint256 => Holding) public holdings;
    mapping(address => uint256[]) public claimGroupIds;
    mapping(uint256 => mapping(bytes32 => bool)) public leafClaimed;
    uint256 public constant LOCKING_PERIOD = 30 days;
    uint256 public claimGroupCount;

    function addFunds(uint256 claimGroupId, uint256 amount) external override {
        // prelim. parameter checks
        require(amount != 0, "Invalid amount");

        // reference our struct storage
        Holding storage holding = holdings[claimGroupId];
        require(holding.owner != address(0), "Holding does not exist");

        // calculate amount to deposit.  handle deposit-all.
        IERC20 token = IERC20(holding.erc20);
        uint256 balance = token.balanceOf(msg.sender);
        if (amount == uint256(-1)) {
            amount = balance;
        }
        require(amount <= balance, "Insufficient balance");
        require(amount != 0, "Amount cannot be zero");

        // transfer token to this contract
        token.safeTransferFrom(msg.sender, address(this), amount);

        // update holdings record
        holding.balance = holding.balance.add(amount);

        emit MerkleFundUpdate(msg.sender, holding.merkleRoot, claimGroupId, amount, false);
    }

    function addFundsWithPermit(
        uint256 claimGroupId,
        address funder,
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external override {
        // prelim. parameter checks
        require(amount != 0, "Invalid amount");

        // reference our struct storage
        Holding storage holding = holdings[claimGroupId];
        require(holding.owner != address(0), "Holding does not exist");

        // calculate amount to deposit.  handle deposit-all.
        IERC20WithPermit token = IERC20WithPermit(holding.erc20);
        uint256 balance = token.balanceOf(funder);
        if (amount == uint256(-1)) {
            amount = balance;
        }
        require(amount <= balance, "Insufficient balance");
        require(amount != 0, "Amount cannot be zero");

        // transfer token to this contract
        token.permit(funder, address(this), amount, deadline, v, r, s);
        token.safeTransferFrom(funder, address(this), amount);

        // update holdings record
        holding.balance = holding.balance.add(amount);

        emit MerkleFundUpdate(funder, holding.merkleRoot, claimGroupId, amount, false);
    }

    function withdrawFunds(uint256 claimGroupId, uint256 amount) external override {
        // reference our struct storage
        Holding storage holding = holdings[claimGroupId];
        require(holding.owner != address(0), "Holding does not exist");
        require(block.timestamp >= holding.withdrawUnlockTime, "Holdings may not be withdrawn");
        require(holding.owner == msg.sender, "Only owner may withdraw");

        // calculate amount to withdraw.  handle withdraw-all.
        IERC20 token = IERC20(holding.erc20);
        if (amount == uint256(-1)) {
            amount = holding.balance;
        }
        require(amount <= holding.balance, "Insufficient balance");

        // update holdings record
        holding.balance = holding.balance.sub(amount);

        // transfer token to this contract
        token.safeTransfer(msg.sender, amount);

        emit MerkleFundUpdate(msg.sender, holding.merkleRoot, claimGroupId, amount, true);
    }

    function newClaimsGroup(
        address erc20,
        uint256 amount,
        bytes32 merkleRoot,
        uint256 withdrawUnlockTime,
        string calldata memo
    ) external override returns (uint256) {
        // prelim. parameter checks
        require(erc20 != address(0), "Invalid ERC20 address");
        require(merkleRoot != 0, "Merkle cannot be zero");
        require(withdrawUnlockTime >= block.timestamp + LOCKING_PERIOD, "Holding lock must exceed minimum lock period");

        claimGroupCount++;
        // reference our struct storage
        Holding storage holding = holdings[claimGroupCount];

        // calculate amount to deposit.  handle deposit-all.
        IERC20 token = IERC20(erc20);
        uint256 balance = token.balanceOf(msg.sender);
        if (amount == uint256(-1)) {
            amount = balance;
        }
        require(amount <= balance, "Insufficient balance");
        require(amount != 0, "Amount cannot be zero");

        // transfer token to this contract
        token.safeTransferFrom(msg.sender, address(this), amount);

        // record holding in stable storage
        holding.owner = msg.sender;
        holding.erc20 = erc20;
        holding.balance = amount;
        holding.merkleRoot = merkleRoot;
        holding.withdrawUnlockTime = withdrawUnlockTime;
        holding.memo = memo;
        claimGroupIds[msg.sender].push(claimGroupCount);
        emit NewMerkle(msg.sender, erc20, amount, merkleRoot, claimGroupCount, withdrawUnlockTime, memo);
        return claimGroupCount;
    }

    function isClaimable(
        uint256 claimGroupId,
        address account,
        uint256 amount,
        bytes32[] memory proof
    ) external view override returns (bool) {
        // holding exists?
        Holding memory holding = holdings[claimGroupId];
        if (holding.owner == address(0)) {
            return false;
        }
        //  holding owner?
        if (holding.owner == account) {
            return false;
        }
        // sufficient balance exists?   (funder may have under-funded)
        if (holding.balance < amount) {
            return false;
        }

        bytes32 leaf = _leafHash(account, amount);
        // already claimed?
        if (leafClaimed[claimGroupId][leaf]) {
            return false;
        }
        // merkle proof is invalid or claim not found
        if (!MerkleProof.verify(proof, holding.merkleRoot, leaf)) {
            return false;
        }
        return true;
    }

    function claim(
        uint256 claimGroupId,
        address account,
        uint256 amount,
        bytes32[] memory proof
    ) external override {
        // holding exists?
        Holding storage holding = holdings[claimGroupId];
        require(holding.owner != address(0), "Holding not found");

        //  holding owner?
        require(holding.owner != account, "Holding owner cannot claim");

        // sufficient balance exists?   (funder may have under-funded)
        require(holding.balance >= amount, "Claim under-funded by funder.");

        bytes32 leaf = _leafHash(account, amount);

        // already spent?
        require(leafClaimed[claimGroupId][leaf] == false, "Already claimed");

        // merkle proof valid?
        require(MerkleProof.verify(proof, holding.merkleRoot, leaf) == true, "Claim not found");

        // update state
        leafClaimed[claimGroupId][leaf] = true;
        holding.balance = holding.balance.sub(amount);
        IERC20(holding.erc20).safeTransfer(account, amount);

        emit MerkleClaim(account, holding.erc20, amount);
    }

    function getClaimGroupIds(address owner) public view returns (uint256[] memory ids) {
        ids = claimGroupIds[owner];
    }

    //////////////////////////////////////////////////////////

    // generate hash of (claim holder, amount)
    // claim holder must be the caller
    function _leafHash(address account, uint256 amount) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account, amount));
    }
}