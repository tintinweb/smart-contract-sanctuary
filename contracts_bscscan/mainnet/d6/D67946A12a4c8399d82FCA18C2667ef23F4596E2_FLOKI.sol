// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./governance/IGovernanceToken.sol";
import "./tax/ITaxHandler.sol";
import "./treasury/ITreasuryHandler.sol";

/**
 * @title Floki token contract
 * @dev The Floki token has modular systems for tax and treasury handler as well as governance capabilities.
 */
contract FLOKI is IERC20, IGovernanceToken, Ownable {
    /// @dev Registry of user token balances.
    mapping(address => uint256) private _balances;

    /// @dev Registry of addresses users have given allowances to.
    mapping(address => mapping(address => uint256)) private _allowances;

    /// @notice Registry of user delegates for governance.
    mapping(address => address) public delegates;

    /// @notice Registry of nonces for vote delegation.
    mapping(address => uint256) public nonces;

    /// @notice Registry of the number of balance checkpoints an account has.
    mapping(address => uint32) public numCheckpoints;

    /// @notice Registry of balance checkpoints per account.
    mapping(address => mapping(uint32 => Checkpoint)) public checkpoints;

    /// @notice The EIP-712 typehash for the contract's domain.
    bytes32 public constant DOMAIN_TYPEHASH =
        keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract.
    bytes32 public constant DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice The contract implementing tax calculations.
    ITaxHandler public taxHandler;

    /// @notice The contract that performs treasury-related operations.
    ITreasuryHandler public treasuryHandler;

    /// @notice Emitted when the tax handler contract is changed.
    event TaxHandlerChanged(address oldAddress, address newAddress);

    /// @notice Emitted when the treasury handler contract is changed.
    event TreasuryHandlerChanged(address oldAddress, address newAddress);

    /// @dev Name of the token.
    string private _name;

    /// @dev Symbol of the token.
    string private _symbol;

    /**
     * @param name_ Name of the token.
     * @param symbol_ Symbol of the token.
     * @param taxHandlerAddress Initial tax handler contract.
     * @param treasuryHandlerAddress Initial treasury handler contract.
     */
    constructor(
        string memory name_,
        string memory symbol_,
        address taxHandlerAddress,
        address treasuryHandlerAddress
    ) {
        _name = name_;
        _symbol = symbol_;

        taxHandler = ITaxHandler(taxHandlerAddress);
        treasuryHandler = ITreasuryHandler(treasuryHandlerAddress);

        _balances[_msgSender()] = totalSupply();

        emit Transfer(address(0), _msgSender(), totalSupply());
    }

    /**
     * @notice Get token name.
     * @return Name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @notice Get token symbol.
     * @return Symbol of the token.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @notice Get number of decimals used by the token.
     * @return Number of decimals used by the token.
     */
    function decimals() external pure returns (uint8) {
        return 9;
    }

    /**
     * @notice Get the maximum number of tokens.
     * @return The maximum number of tokens that will ever be in existence.
     */
    function totalSupply() public pure override returns (uint256) {
        // Ten trillion, i.e., 10,000,000,000,000 tokens.
        return 1e13 * 1e9;
    }

    /**
     * @notice Get token balance of given account.
     * @param account Address to retrieve balance for.
     * @return The number of tokens owned by `account`.
     */
    function balanceOf(address account) external view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Transfer tokens from caller's address to another.
     * @param recipient Address to send the caller's tokens to.
     * @param amount The number of tokens to transfer to recipient.
     * @return True if transfer succeeds, else an error is raised.
     */
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @notice Get the allowance `owner` has given `spender`.
     * @param owner The address on behalf of whom tokens can be spent by `spender`.
     * @param spender The address authorized to spend tokens on behalf of `owner`.
     * @return The allowance `owner` has given `spender`.
     */
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @notice Approve address to spend caller's tokens.
     * @dev This method can be exploited by malicious spenders if their allowance is already non-zero. See the following
     * document for details: https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit.
     * Ensure the spender can be trusted before calling this method if they've already been approved before. Otherwise
     * use either the `increaseAllowance`/`decreaseAllowance` functions, or first set their allowance to zero, before
     * setting a new allowance.
     * @param spender Address to authorize for token expenditure.
     * @param amount The number of tokens `spender` is allowed to spend.
     * @return True if the approval succeeds, else an error is raised.
     */
    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @notice Transfer tokens from one address to another.
     * @param sender Address to move tokens from.
     * @param recipient Address to send the caller's tokens to.
     * @param amount The number of tokens to transfer to recipient.
     * @return True if the transfer succeeds, else an error is raised.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(
            currentAllowance >= amount,
            "FLOKI:transferFrom:ALLOWANCE_EXCEEDED: Transfer amount exceeds allowance."
        );
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @notice Increase spender's allowance.
     * @param spender Address of user authorized to spend caller's tokens.
     * @param addedValue The number of tokens to add to `spender`'s allowance.
     * @return True if the allowance is successfully increased, else an error is raised.
     */
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);

        return true;
    }

    /**
     * @notice Decrease spender's allowance.
     * @param spender Address of user authorized to spend caller's tokens.
     * @param subtractedValue The number of tokens to remove from `spender`'s allowance.
     * @return True if the allowance is successfully decreased, else an error is raised.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "FLOKI:decreaseAllowance:ALLOWANCE_UNDERFLOW: Subtraction results in sub-zero allowance."
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @notice Delegate votes to given address.
     * @dev It should be noted that users that want to vote themselves, also need to call this method, albeit with their
     * own address.
     * @param delegatee Address to delegate votes to.
     */
    function delegate(address delegatee) external {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegate votes from signatory to `delegatee`.
     * @param delegatee The address to delegate votes to.
     * @param nonce The contract state required to match the signature.
     * @param expiry The time at which to expire the signature.
     * @param v The recovery byte of the signature.
     * @param r Half of the ECDSA signature pair.
     * @param s Half of the ECDSA signature pair.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external {
        bytes32 domainSeparator = keccak256(
            abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name())), block.chainid, address(this))
        );
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);

        require(signatory != address(0), "FLOKI:delegateBySig:INVALID_SIGNATURE: Received signature was invalid.");
        require(block.timestamp <= expiry, "FLOKI:delegateBySig:EXPIRED_SIGNATURE: Received signature has expired.");
        require(nonce == nonces[signatory]++, "FLOKI:delegateBySig:INVALID_NONCE: Received nonce was invalid.");

        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Determine the number of votes for an account as of a block number.
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check.
     * @param blockNumber The block number to get the vote balance at.
     * @return The number of votes the account had as of the given block.
     */
    function getVotesAtBlock(address account, uint32 blockNumber) public view returns (uint224) {
        require(
            blockNumber < block.number,
            "FLOKI:getVotesAtBlock:FUTURE_BLOCK: Cannot get votes at a block in the future."
        );

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance.
        if (checkpoints[account][nCheckpoints - 1].blockNumber <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance.
        if (checkpoints[account][0].blockNumber > blockNumber) {
            return 0;
        }

        // Perform binary search.
        uint32 lowerBound = 0;
        uint32 upperBound = nCheckpoints - 1;
        while (upperBound > lowerBound) {
            uint32 center = upperBound - (upperBound - lowerBound) / 2;
            Checkpoint memory checkpoint = checkpoints[account][center];

            if (checkpoint.blockNumber == blockNumber) {
                return checkpoint.votes;
            } else if (checkpoint.blockNumber < blockNumber) {
                lowerBound = center;
            } else {
                upperBound = center - 1;
            }
        }

        // No exact block found. Use last known balance before that block number.
        return checkpoints[account][lowerBound].votes;
    }

    /**
     * @notice Set new tax handler contract.
     * @param taxHandlerAddress Address of new tax handler contract.
     */
    function setTaxHandler(address taxHandlerAddress) external onlyOwner {
        address oldTaxHandlerAddress = address(taxHandler);
        taxHandler = ITaxHandler(taxHandlerAddress);

        emit TaxHandlerChanged(oldTaxHandlerAddress, taxHandlerAddress);
    }

    /**
     * @notice Set new treasury handler contract.
     * @param treasuryHandlerAddress Address of new treasury handler contract.
     */
    function setTreasuryHandler(address treasuryHandlerAddress) external onlyOwner {
        address oldTreasuryHandlerAddress = address(treasuryHandler);
        treasuryHandler = ITreasuryHandler(treasuryHandlerAddress);

        emit TreasuryHandlerChanged(oldTreasuryHandlerAddress, treasuryHandlerAddress);
    }

    /**
     * @notice Delegate votes from one address to another.
     * @param delegator Address from which to delegate votes for.
     * @param delegatee Address to delegate votes to.
     */
    function _delegate(address delegator, address delegatee) private {
        address currentDelegate = delegates[delegator];
        uint256 delegatorBalance = _balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, uint224(delegatorBalance));
    }

    /**
     * @notice Move delegates from one address to another.
     * @param from Representative to move delegates from.
     * @param to Representative to move delegates to.
     * @param amount Number of delegates to move.
     */
    function _moveDelegates(
        address from,
        address to,
        uint224 amount
    ) private {
        // No need to update checkpoints if the votes don't actually move between different delegates. This can be the
        // case where tokens are transferred between two parties that have delegated their votes to the same address.
        if (from == to) {
            return;
        }

        // Some users preemptively delegate their votes (i.e. before they have any tokens). No need to perform an update
        // to the checkpoints in that case.
        if (amount == 0) {
            return;
        }

        if (from != address(0)) {
            uint32 fromRepNum = numCheckpoints[from];
            uint224 fromRepOld = fromRepNum > 0 ? checkpoints[from][fromRepNum - 1].votes : 0;
            uint224 fromRepNew = fromRepOld - amount;

            _writeCheckpoint(from, fromRepNum, fromRepOld, fromRepNew);
        }

        if (to != address(0)) {
            uint32 toRepNum = numCheckpoints[to];
            uint224 toRepOld = toRepNum > 0 ? checkpoints[to][toRepNum - 1].votes : 0;
            uint224 toRepNew = toRepOld + amount;

            _writeCheckpoint(to, toRepNum, toRepOld, toRepNew);
        }
    }

    /**
     * @notice Write balance checkpoint to chain.
     * @param delegatee The address to write the checkpoint for.
     * @param nCheckpoints The number of checkpoints `delegatee` already has.
     * @param oldVotes Number of votes prior to this checkpoint.
     * @param newVotes Number of votes `delegatee` now has.
     */
    function _writeCheckpoint(
        address delegatee,
        uint32 nCheckpoints,
        uint224 oldVotes,
        uint224 newVotes
    ) private {
        uint32 blockNumber = uint32(block.number);

        if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].blockNumber == blockNumber) {
            checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
        } else {
            checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
            numCheckpoints[delegatee] = nCheckpoints + 1;
        }

        emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    /**
     * @notice Approve spender on behalf of owner.
     * @param owner Address on behalf of whom tokens can be spent by `spender`.
     * @param spender Address to authorize for token expenditure.
     * @param amount The number of tokens `spender` is allowed to spend.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "FLOKI:_approve:OWNER_ZERO: Cannot approve for the zero address.");
        require(spender != address(0), "FLOKI:_approve:SPENDER_ZERO: Cannot approve to the zero address.");

        _allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
    }

    /**
     * @notice Transfer `amount` tokens from account `from` to account `to`.
     * @param from Address the tokens are moved out of.
     * @param to Address the tokens are moved to.
     * @param amount The number of tokens to transfer.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "FLOKI:_transfer:FROM_ZERO: Cannot transfer from the zero address.");
        require(to != address(0), "FLOKI:_transfer:TO_ZERO: Cannot transfer to the zero address.");
        require(amount > 0, "FLOKI:_transfer:ZERO_AMOUNT: Transfer amount must be greater than zero.");
        require(amount <= _balances[from], "FLOKI:_transfer:INSUFFICIENT_BALANCE: Transfer amount exceeds balance.");

        treasuryHandler.beforeTransferHandler(from, to, amount);

        uint256 tax = taxHandler.getTax(from, to, amount);
        uint256 taxedAmount = amount - tax;

        _balances[from] -= amount;
        _balances[to] += taxedAmount;
        _moveDelegates(delegates[from], delegates[to], uint224(taxedAmount));

        if (tax > 0) {
            _balances[address(treasuryHandler)] += tax;

            _moveDelegates(delegates[from], delegates[address(treasuryHandler)], uint224(tax));

            emit Transfer(from, address(treasuryHandler), tax);
        }

        treasuryHandler.afterTransferHandler(from, to, amount);

        emit Transfer(from, to, taxedAmount);
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/**
 * @title Governance token interface.
 */
interface IGovernanceToken {
    /// @notice A checkpoint for marking number of votes as of a given block.
    struct Checkpoint {
        // The 32-bit unsigned integer is valid until these estimated dates for these given chains:
        //  - BSC: Sat Dec 23 2428 18:23:11 UTC
        //  - ETH: Tue Apr 18 3826 09:27:12 UTC
        // This assumes that block mining rates don't speed up.
        uint32 blockNumber;
        // This type is set to `uint224` for optimizations purposes (i.e., specifically to fit in a 32-byte block). It
        // assumes that the number of votes for the implementing governance token never exceeds the maximum value for a
        // 224-bit number.
        uint224 votes;
    }

    /**
     * @notice Determine the number of votes for an account as of a block number.
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check.
     * @param blockNumber The block number to get the vote balance at.
     * @return The number of votes the account had as of the given block.
     */
    function getVotesAtBlock(address account, uint32 blockNumber) external view returns (uint224);

    /// @notice Emitted whenever a new delegate is set for an account.
    event DelegateChanged(address delegator, address currentDelegate, address newDelegate);

    /// @notice Emitted when a delegate's vote count changes.
    event DelegateVotesChanged(address delegatee, uint224 oldVotes, uint224 newVotes);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/**
 * @title Tax handler interface
 * @dev Any class that implements this interface can be used for protocol-specific tax calculations.
 */
interface ITaxHandler {
    /**
     * @notice Get number of tokens to pay as tax.
     * @param benefactor Address of the benefactor.
     * @param beneficiary Address of the beneficiary.
     * @param amount Number of tokens in the transfer.
     * @return Number of tokens to pay as tax.
     */
    function getTax(
        address benefactor,
        address beneficiary,
        uint256 amount
    ) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

/**
 * @title Treasury handler interface
 * @dev Any class that implements this interface can be used for protocol-specific operations pertaining to the treasury.
 */
interface ITreasuryHandler {
    /**
     * @notice Perform operations before a transfer is executed.
     * @param benefactor Address of the benefactor.
     * @param beneficiary Address of the beneficiary.
     * @param amount Number of tokens in the transfer.
     */
    function beforeTransferHandler(
        address benefactor,
        address beneficiary,
        uint256 amount
    ) external;

    /**
     * @notice Perform operations after a transfer is executed.
     * @param benefactor Address of the benefactor.
     * @param beneficiary Address of the beneficiary.
     * @param amount Number of tokens in the transfer.
     */
    function afterTransferHandler(
        address benefactor,
        address beneficiary,
        uint256 amount
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}