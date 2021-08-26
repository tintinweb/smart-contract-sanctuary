/**
 *Submitted for verification at Etherscan.io on 2021-08-26
*/

pragma solidity ^0.5.16;


// Copied from compound/EIP20Interface
/**
 * @title ERC 20 Token Standard Interface
 *  https://eips.ethereum.org/EIPS/eip-20
 */
interface EIP20Interface {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    /**
      * @notice Get the total number of tokens in circulation
      * @return The supply of tokens
      */
    function totalSupply() external view returns (uint256);

    /**
     * @notice Gets the balance of the specified address
     * @param owner The address from which the balance will be retrieved
     * @return The balance
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
      * @notice Transfer `amount` tokens from `msg.sender` to `dst`
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transfer(address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Transfer `amount` tokens from `src` to `dst`
      * @param src The address of the source account
      * @param dst The address of the destination account
      * @param amount The number of tokens to transfer
      * @return Whether or not the transfer succeeded
      */
    function transferFrom(address src, address dst, uint256 amount) external returns (bool success);

    /**
      * @notice Approve `spender` to transfer up to `amount` from `src`
      * @dev This will overwrite the approval amount for `spender`
      *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
      * @param spender The address of the account which may transfer tokens
      * @param amount The number of tokens that are approved (-1 means infinite)
      * @return Whether or not the approval succeeded
      */
    function approve(address spender, uint256 amount) external returns (bool success);

    /**
      * @notice Get the current allowance from `owner` for `spender`
      * @param owner The address of the account which owns the tokens to be spent
      * @param spender The address of the account which may transfer tokens
      * @return The number of tokens allowed to be spent (-1 means infinite)
      */
    function allowance(address owner, address spender) external view returns (uint256 remaining);

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
}

// Copied from Compound/ExponentialNoError
/**
 * @title Exponential module for storing fixed-precision decimals
 * @author DeFil
 * @notice Exp is a struct which stores decimals with a fixed precision of 18 decimal places.
 *         Thus, if we wanted to store the 5.1, mantissa would store 5.1e18. That is:
 *         `Exp({mantissa: 5100000000000000000})`.
 */
contract ExponentialNoError {
    uint constant expScale = 1e18;
    uint constant doubleScale = 1e36;
    uint constant halfExpScale = expScale/2;
    uint constant mantissaOne = expScale;

    struct Exp {
        uint mantissa;
    }

    struct Double {
        uint mantissa;
    }

    /**
     * @dev Truncates the given exp to a whole number value.
     *      For example, truncate(Exp{mantissa: 15 * expScale}) = 15
     */
    function truncate(Exp memory exp) pure internal returns (uint) {
        // Note: We are not using careful math here as we're performing a division that cannot fail
        return exp.mantissa / expScale;
    }

    /**
     * @dev Multiply an Exp by a scalar, then truncate to return an unsigned integer.
     */
    function mul_ScalarTruncate(Exp memory a, uint scalar) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return truncate(product);
    }

    /**
     * @dev Multiply an Exp by a scalar, truncate, then add an to an unsigned integer, returning an unsigned integer.
     */
    function mul_ScalarTruncateAddUInt(Exp memory a, uint scalar, uint addend) pure internal returns (uint) {
        Exp memory product = mul_(a, scalar);
        return add_(truncate(product), addend);
    }

    /**
     * @dev Checks if first Exp is less than second Exp.
     */
    function lessThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa < right.mantissa;
    }

    /**
     * @dev Checks if left Exp <= right Exp.
     */
    function lessThanOrEqualExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa <= right.mantissa;
    }

    /**
     * @dev Checks if left Exp > right Exp.
     */
    function greaterThanExp(Exp memory left, Exp memory right) pure internal returns (bool) {
        return left.mantissa > right.mantissa;
    }

    /**
     * @dev returns true if Exp is exactly zero
     */
    function isZeroExp(Exp memory value) pure internal returns (bool) {
        return value.mantissa == 0;
    }

    function safe224(uint n, string memory errorMessage) pure internal returns (uint224) {
        require(n < 2**224, errorMessage);
        return uint224(n);
    }

    function safe32(uint n, string memory errorMessage) pure internal returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function add_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: add_(a.mantissa, b.mantissa)});
    }

    function add_(uint a, uint b) pure internal returns (uint) {
        return add_(a, b, "addition overflow");
    }

    function add_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: sub_(a.mantissa, b.mantissa)});
    }

    function sub_(uint a, uint b) pure internal returns (uint) {
        return sub_(a, b, "subtraction underflow");
    }

    function sub_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function mul_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b.mantissa) / expScale});
    }

    function mul_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Exp memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / expScale;
    }

    function mul_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b.mantissa) / doubleScale});
    }

    function mul_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: mul_(a.mantissa, b)});
    }

    function mul_(uint a, Double memory b) pure internal returns (uint) {
        return mul_(a, b.mantissa) / doubleScale;
    }

    function mul_(uint a, uint b) pure internal returns (uint) {
        return mul_(a, b, "multiplication overflow");
    }

    function mul_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        if (a == 0 || b == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, errorMessage);
        return c;
    }

    function div_(Exp memory a, Exp memory b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(mul_(a.mantissa, expScale), b.mantissa)});
    }

    function div_(Exp memory a, uint b) pure internal returns (Exp memory) {
        return Exp({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Exp memory b) pure internal returns (uint) {
        return div_(mul_(a, expScale), b.mantissa);
    }

    function div_(Double memory a, Double memory b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a.mantissa, doubleScale), b.mantissa)});
    }

    function div_(Double memory a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(a.mantissa, b)});
    }

    function div_(uint a, Double memory b) pure internal returns (uint) {
        return div_(mul_(a, doubleScale), b.mantissa);
    }

    function div_(uint a, uint b) pure internal returns (uint) {
        return div_(a, b, "divide by zero");
    }

    function div_(uint a, uint b, string memory errorMessage) pure internal returns (uint) {
        require(b > 0, errorMessage);
        return a / b;
    }

    function fraction(uint a, uint b) pure internal returns (Double memory) {
        return Double({mantissa: div_(mul_(a, doubleScale), b)});
    }
}

interface Distributor {
    // The asset to be distributed
    function asset() external view returns (address);

    // Return the accrued amount of account based on stored data
    function accruedStored(address account) external view returns (uint);

    // Accrue and distribute for caller, but not actually transfer assets to the caller
    // returns the new accrued amount
    function accrue() external returns (uint);

    // Claim asset, transfer the given amount assets to receiver
    function claim(address receiver, uint amount) external returns (uint);
}

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
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// Modified from Compound/COMP
contract DFL is EIP20Interface, Ownable {
    /// @notice EIP-20 token name for this token
    string public constant name = "DeFIL-V2";

    /// @notice EIP-20 token symbol for this token
    string public constant symbol = "DFL-V2";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint96 internal _totalSupply;

    /// @notice Allowance amounts on behalf of others
    mapping (address => mapping (address => uint96)) internal allowances;

    /// @notice Official record of token balances for each account
    mapping (address => uint96) internal balances;

    /// @notice A record of each accounts delegate
    mapping (address => address) public delegates;

    /// @notice A checkpoint for marking number of votes from a given block
    struct Checkpoint {
        uint32 fromBlock;
        uint96 votes;
    }

    /// @notice A record of votes checkpoints for each account, by index
    mapping (address => mapping (uint32 => Checkpoint)) public checkpoints;

    /// @notice The number of checkpoints for each account
    mapping (address => uint32) public numCheckpoints;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint256 chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the delegation struct used by the contract
    bytes32 public constant DELEGATION_TYPEHASH = keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /// @notice An event thats emitted when an account changes its delegate
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /// @notice An event thats emitted when a delegate account's vote balance changes
    event DelegateVotesChanged(address indexed delegate, uint previousBalance, uint newBalance);

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint256 amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint256 amount);

    /**
     * @notice Construct a new DFL token
     */
    constructor() public {
        emit Transfer(address(0), address(this), 0);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     * Emits a {Transfer} event with `from` set to the zero address.
     * @param account The address of the account holding the new funds
     * @param rawAmount The number of tokens that are minted
     */
    function mint(address account, uint rawAmount) public onlyOwner {
        require(account != address(0), "DFL:: mint: cannot mint to the zero address");
        uint96 amount = safe96(rawAmount, "DFL::mint: amount exceeds 96 bits");
        _totalSupply = add96(_totalSupply, amount, "DFL::mint: total supply exceeds");
        balances[account] = add96(balances[account], amount, "DFL::mint: mint amount exceeds balance");

        _moveDelegates(address(0), delegates[account], amount);
        emit Transfer(address(0), account, amount);
    }

    /** @dev Burns `amount` tokens, decreasing the total supply.
     * @param rawAmount The number of tokens that are bruned
     */
    function burn(uint rawAmount) external {
        uint96 amount = safe96(rawAmount, "DFL::burn: amount exceeds 96 bits");
        _totalSupply = sub96(_totalSupply, amount, "DFL::burn: total supply exceeds");
        balances[msg.sender] = sub96(balances[msg.sender], amount, "DFL::burn: burn amount exceeds balance");

        _moveDelegates(delegates[msg.sender], address(0), amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    /**
     * @notice Get the number of tokens `spender` is approved to spend on behalf of `account`
     * @param account The address of the account holding the funds
     * @param spender The address of the account spending the funds
     * @return The number of tokens approved
     */
    function allowance(address account, address spender) external view returns (uint) {
        return allowances[account][spender];
    }

    /**
     * @notice Approve `spender` to transfer up to `amount` from `src`
     * @dev This will overwrite the approval amount for `spender`
     *  and is subject to issues noted [here](https://eips.ethereum.org/EIPS/eip-20#approve)
     * @param spender The address of the account which may transfer tokens
     * @param rawAmount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint rawAmount) external returns (bool) {
        uint96 amount;
        if (rawAmount == uint(-1)) {
            amount = uint96(-1);
        } else {
            amount = safe96(rawAmount, "DFL::approve: amount exceeds 96 bits");
        }

        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Get the total supply of tokens
     * @return The total supply of tokens
     */
    function totalSupply() external view returns (uint) {
        return _totalSupply;
    }

    /**
     * @notice Get the number of tokens held by the `account`
     * @param account The address of the account to get the balance of
     * @return The number of tokens held
     */
    function balanceOf(address account) external view returns (uint) {
        return balances[account];
    }

    /**
     * @notice Transfer `amount` tokens from `msg.sender` to `dst`
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint rawAmount) external returns (bool) {
        uint96 amount = safe96(rawAmount, "DFL::transfer: amount exceeds 96 bits");
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param rawAmount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint rawAmount) external returns (bool) {
        address spender = msg.sender;
        uint96 spenderAllowance = allowances[src][spender];
        uint96 amount = safe96(rawAmount, "DFL::approve: amount exceeds 96 bits");

        if (spender != src && spenderAllowance != uint96(-1)) {
            uint96 newAllowance = sub96(spenderAllowance, amount, "DFL::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    /**
     * @notice Delegate votes from `msg.sender` to `delegatee`
     * @param delegatee The address to delegate votes to
     */
    function delegate(address delegatee) public {
        return _delegate(msg.sender, delegatee);
    }

    /**
     * @notice Delegates votes from signatory to `delegatee`
     * @param delegatee The address to delegate votes to
     * @param nonce The contract state required to match the signature
     * @param expiry The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function delegateBySig(address delegatee, uint nonce, uint expiry, uint8 v, bytes32 r, bytes32 s) public {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(DELEGATION_TYPEHASH, delegatee, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "DFL::delegateBySig: invalid signature");
        require(nonce == nonces[signatory]++, "DFL::delegateBySig: invalid nonce");
        require(block.timestamp <= expiry, "DFL::delegateBySig: signature expired");
        return _delegate(signatory, delegatee);
    }

    /**
     * @notice Gets the current votes balance for `account`
     * @param account The address to get votes balance
     * @return The number of current votes for `account`
     */
    function getCurrentVotes(address account) external view returns (uint96) {
        uint32 nCheckpoints = numCheckpoints[account];
        return nCheckpoints > 0 ? checkpoints[account][nCheckpoints - 1].votes : 0;
    }

    /**
     * @notice Determine the prior number of votes for an account as of a block number
     * @dev Block number must be a finalized block or else this function will revert to prevent misinformation.
     * @param account The address of the account to check
     * @param blockNumber The block number to get the vote balance at
     * @return The number of votes the account had as of the given block
     */
    function getPriorVotes(address account, uint blockNumber) public view returns (uint96) {
        require(blockNumber < block.number, "DFL::getPriorVotes: not yet determined");

        uint32 nCheckpoints = numCheckpoints[account];
        if (nCheckpoints == 0) {
            return 0;
        }

        // First check most recent balance
        if (checkpoints[account][nCheckpoints - 1].fromBlock <= blockNumber) {
            return checkpoints[account][nCheckpoints - 1].votes;
        }

        // Next check implicit zero balance
        if (checkpoints[account][0].fromBlock > blockNumber) {
            return 0;
        }

        uint32 lower = 0;
        uint32 upper = nCheckpoints - 1;
        while (upper > lower) {
            uint32 center = upper - (upper - lower) / 2; // ceil, avoiding overflow
            Checkpoint memory cp = checkpoints[account][center];
            if (cp.fromBlock == blockNumber) {
                return cp.votes;
            } else if (cp.fromBlock < blockNumber) {
                lower = center;
            } else {
                upper = center - 1;
            }
        }
        return checkpoints[account][lower].votes;
    }

    function _delegate(address delegator, address delegatee) internal {
        address currentDelegate = delegates[delegator];
        uint96 delegatorBalance = balances[delegator];
        delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveDelegates(currentDelegate, delegatee, delegatorBalance);
    }

    function _transferTokens(address src, address dst, uint96 amount) internal {
        require(src != address(0), "DFL::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "DFL::_transferTokens: cannot transfer to the zero address");

        balances[src] = sub96(balances[src], amount, "DFL::_transferTokens: transfer amount exceeds balance");
        balances[dst] = add96(balances[dst], amount, "DFL::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);

        _moveDelegates(delegates[src], delegates[dst], amount);
    }

    function _moveDelegates(address srcRep, address dstRep, uint96 amount) internal {
        if (srcRep != dstRep && amount > 0) {
            if (srcRep != address(0)) {
                uint32 srcRepNum = numCheckpoints[srcRep];
                uint96 srcRepOld = srcRepNum > 0 ? checkpoints[srcRep][srcRepNum - 1].votes : 0;
                uint96 srcRepNew = sub96(srcRepOld, amount, "DFL::_moveVotes: vote amount underflows");
                _writeCheckpoint(srcRep, srcRepNum, srcRepOld, srcRepNew);
            }

            if (dstRep != address(0)) {
                uint32 dstRepNum = numCheckpoints[dstRep];
                uint96 dstRepOld = dstRepNum > 0 ? checkpoints[dstRep][dstRepNum - 1].votes : 0;
                uint96 dstRepNew = add96(dstRepOld, amount, "DFL::_moveVotes: vote amount overflows");
                _writeCheckpoint(dstRep, dstRepNum, dstRepOld, dstRepNew);
            }
        }
    }

    function _writeCheckpoint(address delegatee, uint32 nCheckpoints, uint96 oldVotes, uint96 newVotes) internal {
      uint32 blockNumber = safe32(block.number, "DFL::_writeCheckpoint: block number exceeds 32 bits");

      if (nCheckpoints > 0 && checkpoints[delegatee][nCheckpoints - 1].fromBlock == blockNumber) {
          checkpoints[delegatee][nCheckpoints - 1].votes = newVotes;
      } else {
          checkpoints[delegatee][nCheckpoints] = Checkpoint(blockNumber, newVotes);
          numCheckpoints[delegatee] = nCheckpoints + 1;
      }

      emit DelegateVotesChanged(delegatee, oldVotes, newVotes);
    }

    function safe32(uint n, string memory errorMessage) internal pure returns (uint32) {
        require(n < 2**32, errorMessage);
        return uint32(n);
    }

    function safe96(uint n, string memory errorMessage) internal pure returns (uint96) {
        require(n < 2**96, errorMessage);
        return uint96(n);
    }

    function add96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        uint96 c = a + b;
        require(c >= a, errorMessage);
        return c;
    }

    function sub96(uint96 a, uint96 b, string memory errorMessage) internal pure returns (uint96) {
        require(b <= a, errorMessage);
        return a - b;
    }

    function getChainId() internal pure returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}

interface SwapRouter {
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
}

contract Repurchase is ExponentialNoError, Ownable {
    // The DFL token
    DFL public dfl;

    /**
     * @notice Incentive volumteer for doing repurchase action
     */
    uint public volunteerIncentiveMantissa;

    // No collateralFactorMantissa may exceed this value
    uint internal constant volunteerIncentiveMaxMantissa = 0.1e18; // 0.1

    struct FundInfo {
        //// individual SwapRouter
        SwapRouter swapRouter;
        /// @notice The path for SwapRouter
        address[] path;
        /// @notice The sources of fund
        Distributor[] sources;
    }

    // The mapping of fund to FundInfo
    mapping(address => FundInfo) public fundInfos;

    /*** Events ***/
    // Event emitted when volunteerIncentiveMantissa is updated
    event NewVolunteerIncentive(uint volunteerIncentive);

    // Event emitted when fund is added
    event FundAdded(address fund, SwapRouter swapRouter, address[] path);

    // Event emitted when new fund source is added
    event FundSourceAdded(address fund, address source);

    // Event emitted when new fund source is removed
    event FundSourceRemoved(address fund, address source);

    // Event emitted when SwapRouter of fund changed
    event FundSwapRouterChanged(address fund, SwapRouter swapRouter, address[] path);

    // Event emitted when path of fund changed
    event FundSwapRouterPathChanged(address fund, address[] path);

    // Event emitted when repurchase happens
    event Repurchase(address volumteer, SwapRouter swapRouter, address[] path, uint[] amounts, uint incentive);

    // constructor
    constructor(DFL dfl_) public {
        dfl = dfl_;
    }

    // repurchase and burn DFL
    function repurchase(address fund) external {
        require(msg.sender == tx.origin, "msg.sender check");

        FundInfo memory fundInfo = fundInfos[fund];
        require(fundInfo.path.length != 0, "Fund not exists");

        // accrue and claim
        for (uint i = 0; i < fundInfo.sources.length; i ++) {
            uint accruedFunds = fundInfo.sources[i].accrue();
            require(fundInfo.sources[i].claim(address(this), accruedFunds) == accruedFunds, "claim amount mismatch");
        }

        EIP20Interface fundToken = EIP20Interface(fund);
        uint availableFunds = fundToken.balanceOf(address(this));
        if (availableFunds == 0) {
            return;
        }

        SwapRouter swapRouter = fundInfo.swapRouter;
        // try approve for swapRouter
        if (fundToken.allowance(address(this), address(swapRouter)) < availableFunds) {
            fundToken.approve(address(swapRouter), availableFunds);
        }

        // do swap
        uint[] memory amounts = swapRouter.swapExactTokensForTokens(availableFunds, 0, fundInfo.path, address(this), block.timestamp);

        // The swap out amount of DFL
        uint dlfAmountOut = amounts[amounts.length - 1];
        uint incentivePart = div_(mul_(dlfAmountOut, volunteerIncentiveMantissa), mantissaOne);
        uint burnPart = sub_(dlfAmountOut, incentivePart);

        // transfer incentive to volumteer
        dfl.transfer(msg.sender, incentivePart);
        // burn
        dfl.burn(burnPart);

        emit Repurchase(msg.sender, swapRouter, fundInfo.path, amounts, incentivePart);
    }

    function availableFunds(address fund) external view returns (uint) {
        FundInfo memory fundInfo = fundInfos[fund];

        uint totalAccruedStored = 0;
        for (uint i = 0; i < fundInfo.sources.length; i ++) {
            totalAccruedStored = add_(totalAccruedStored, fundInfo.sources[i].accruedStored(address(this)));
        }

        EIP20Interface fundToken = EIP20Interface(fund);
        uint localBalance = fundToken.balanceOf(address(this));

        return add_(totalAccruedStored, localBalance);
    }

    /*** Admin Functions ***/
    // update volunteerIncentive
    function setVolunteerIncentive(uint newVolunteerIncentiveMantissa) external onlyOwner {
        require(newVolunteerIncentiveMantissa <= volunteerIncentiveMaxMantissa, "Bad value");

        volunteerIncentiveMantissa = newVolunteerIncentiveMantissa;
        emit NewVolunteerIncentive(newVolunteerIncentiveMantissa);
    }

    // add fund
    function addFund(address fund, SwapRouter swapRouter, address[] calldata path) external onlyOwner {
        require(address(swapRouter) != address(0), "Bad SwapRouter");
        require(path.length > 1, "Bad path length");
        require(path[0] == fund, "Bad first element");
        require(path[path.length - 1] == address(dfl), "Bad last element");

        // reference storage
        FundInfo storage fundInfo = fundInfos[fund];
        require(fundInfo.path.length == 0, "Fund exists");

        // update storage
        fundInfo.swapRouter = swapRouter;
        fundInfo.path = path;

        emit FundAdded(fund, swapRouter, path);
    }

    // add source of fund
    function addSource(Distributor source) external onlyOwner {
        address fund = source.asset();
        require(fund != address(dfl), "Bad fund");

        // reference storage
        FundInfo storage fundInfo = fundInfos[fund];
        // check fund exists
        require(fundInfo.path.length != 0, "Fund not exists");

        // validate source
        uint len = fundInfo.sources.length;
        for (uint i = 0; i < len; i ++) {
            require(fundInfo.sources[i] != source, "Source exists");
        }

        // update storage
        fundInfo.sources.push(source);

        emit FundSourceAdded(fund, address(source));
    }

    // remove source of fund
    function removeSource(Distributor source) external onlyOwner {
        // get fund
        address fund = source.asset();

        // reference storage
        FundInfo storage fundInfo = fundInfos[fund];
        // check fund exists
        require(fundInfo.path.length != 0, "Fund not exists");

        // find index
        uint len = fundInfo.sources.length;
        uint index = len;
        for (uint i = 0; i < len; i ++) {
            if (fundInfo.sources[i] == source) {
                index = i;
                break;
            }
        }
        require(index < len, "Source not found");
        require(source.accruedStored(address(this)) == 0, "Still have funds");

        // update storage
        fundInfo.sources[index] = fundInfo.sources[len - 1];
        fundInfo.sources.length--;

        emit FundSourceRemoved(fund, address(source));
    }

    // set SwapRouter of fund
    function setSwapRouter(address fund, SwapRouter newSwapRouter, address[] calldata newPath) external onlyOwner {
        require(address(newSwapRouter) != address(0), "Bad SwapRouter");
        require(newPath.length > 1, "Bad path length");
        require(newPath[0] == fund, "Bad first element");
        require(newPath[newPath.length - 1] == address(dfl), "Bad last element");

        // reference storage
        FundInfo storage fundInfo = fundInfos[fund];
        // check fund exists
        require(fundInfo.path.length != 0, "Fund not exists");

        // update storage
        fundInfo.path = newPath;
        fundInfo.swapRouter = newSwapRouter;

        emit FundSwapRouterChanged(fund, newSwapRouter, newPath);
    }

    // set path of fund
    function setSwapRouterPath(address fund, address[] calldata newPath) external onlyOwner {
        require(newPath.length > 1, "Bad path length");
        require(newPath[0] == fund, "Bad first element");
        require(newPath[newPath.length - 1] == address(dfl), "Bad last element");

        // reference storage
        FundInfo storage fundInfo = fundInfos[fund];
        // check fund exists
        require(fundInfo.path.length != 0, "Fund not exists");

        // update storage
        fundInfo.path = newPath;

        emit FundSwapRouterPathChanged(fund, newPath);
    }
}