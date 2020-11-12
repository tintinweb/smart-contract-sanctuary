// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint);
    function decimals() external view returns (uint);
    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint);

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
    function approve(address spender, uint amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint value);
}

// From https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/Math.sol
// Subject to the MIT license.

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
     * @dev Returns the addition of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting with custom message on overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, errorMessage);

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "Uniloan::SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, errorMessage);

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers.
     * Reverts with custom message on division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;
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
     * - The divisor cannot be zero.
     */
    function mod(uint a, uint b) internal pure returns (uint) {
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
     * - The divisor cannot be zero.
     */
    function mod(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IUniswapV2SlidingOracle {
    function quote(address tokenIn, address tokenOut, uint amountIn, uint granularity) external view returns (uint amountOut);
}

library OptionsV1Library {
    using SafeMath for uint;

    /// @notice Uniswap Oracle Router
    IUniswapV2SlidingOracle public constant ORACLE = IUniswapV2SlidingOracle(0xCA2E2df6A7a7Cf5bd19D112E8568910a6C2D3885);

    uint constant public SQRTPERIOD = 777;
    uint constant public PERIOD = 7 days;
    uint constant public GRANULARITY = 8;
    
    address constant public WETH = address(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    address constant public DAI = address(0x6B175474E89094C44Da98b954EedeAC495271d0F);

    /**
     * @notice Provides a quote of how much output can be expected given the inputs
     * @param tokenIn the asset being received
     * @param amountIn the amount of tokenIn being provided
     * @return minOut the minimum amount of liquidity to send
     */
    function quote(address tokenIn, uint amountIn) external view returns (uint minOut) {
        uint _wethOut = ORACLE.quote(tokenIn, WETH, amountIn, GRANULARITY);
        minOut = ORACLE.quote(WETH, DAI, _wethOut, GRANULARITY);
    }

    /**
     * @notice Calculates strikeFee
     * @param amountIn Option amount
     * @param amountOut Strike price of the option
     * @param currentOut Current price of the option
     * @return fee Strike fee amount
     */
    function getStrikeFee(
        uint256 amountIn,
        uint256 amountOut,
        uint256 currentOut
    ) internal pure returns (uint256) {
        if (amountOut > currentOut)
            return amountOut.sub(currentOut).mul(amountIn).div(currentOut);
        return 0;
    }

    /**
     * @notice Calculates periodFee
     * @param amountIn Option amount
     * @param amountOut Strike price of the option
     * @param currentOut Current price of the option
     * @return fee Period fee amount
     *
     * amount < 1e30        |
     * impliedVolRate < 1e10| => amount * impliedVolRate * strike < 1e60 < 2^uint256
     * strike < 1e20 ($1T)  |
     *
     * in case amount * impliedVolRate * strike >= 2^256
     * transaction will be reverted by the SafeMath
     */
    function getPeriodFee(
        uint256 amountIn,
        uint256 amountOut,
        uint256 currentOut
    ) internal pure returns (uint256) {
        return amountIn
                .mul(SQRTPERIOD)
                .mul(amountOut)
                .div(currentOut)
                .mul(5500)
                .div(100000000);
    }

    /**
     * @notice Used for getting the actual options prices
     * @param amountIn Option amount
     * @param amountOut Strike price of the option
     * @param currentOut current price of the option
     * @return total Total price to be paid
     */
    function fees(uint amountIn, uint amountOut, uint currentOut) external pure returns (uint) {
        return getPeriodFee(amountIn, amountOut, currentOut)
                .add(getStrikeFee(amountIn, amountOut, currentOut))
                .add(getSettlementFee(amountIn));
    }

    /**
     * @notice Calculates settlementFee
     * @param amount Option amount
     * @return fee Settlement fee amount
     */
    function getSettlementFee(uint amount) internal pure returns (uint) {
        return amount / 100;
    }
}

contract YearnOptionsV1Manager {
    using SafeMath for uint;

    /// @notice EIP-20 token name for this token
    string public name = "Yearn OptionsV1Manager";

    /// @notice EIP-20 token symbol for this token
    string public symbol = "yOV1M";

    /// @notice EIP-20 token decimals for this token
    uint8 public constant decimals = 18;

    /// @notice Total number of tokens in circulation
    uint public totalSupply = 0; // Initial 0

    mapping (address => mapping (address => uint)) internal allowances;
    mapping (address => uint) internal balances;

    /// @notice The EIP-712 typehash for the contract's domain
    bytes32 public constant DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,uint chainId,address verifyingContract)");

    /// @notice The EIP-712 typehash for the permit struct used by the contract
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint value,uint nonce,uint deadline)");

    /// @notice A record of states for signing / validating signatures
    mapping (address => uint) public nonces;

    /// @notice The standard EIP-20 transfer event
    event Transfer(address indexed from, address indexed to, uint amount);

    /// @notice The standard EIP-20 approval event
    event Approval(address indexed owner, address indexed spender, uint amount);

    /// @notice Deposited event for creditor/LP
    event Deposited(address indexed creditor, uint shares, uint credit);
    
    /// @notice Withdawn event for creditor/LP
    event Withdrew(address indexed creditor, uint shares, uint credit);

    /// @notice The create option event
    event Created(uint id, address indexed owner, address indexed tokenIn, uint amountIn, uint amountOut, uint created, uint expire);
    
    /// @notice swap the position event when processing options
    event Excercised(uint id, address indexed owner, address indexed tokenIn, uint amountIn, uint amountOut, uint created, uint expire);
    
    /// @notice The close position event when processing options
    event Closed(uint id, address indexed owner, uint created, uint expire);

    struct position {
        address owner;
        address asset;
        uint amountIn;
        uint amountOut;
        uint created;
        uint expire;
        bool open;
    }

    /// @notice array of all option positions
    position[] public positions;

    /// @notice the tip index of the positions array
    uint public nextIndex;

    /// @notice the last index processed by the contract
    uint public processedIndex;

    /// @notice mapping of options assigned to users
    mapping(address => uint[]) public options;

    address public governance;
    address public pendingGovernance;
    
    address public constant reserve = address(0x9cA85572E6A3EbF24dEDd195623F188735A5179f);
    
    uint public reserveInUse;

    /// @notice constructor takes a uniswap pair as an argument to set its 2 borrowable assets
    constructor() public {
        governance = msg.sender;
    }
    
    function setGovernance(address _governance) external {
        require(msg.sender == governance, "::setGovernance: only governance");
        pendingGovernance = _governance;
    }
    
    function acceptGovernance() external {
        require(msg.sender == pendingGovernance, "::acceptGovernance: only pendingGovernance");
        governance = pendingGovernance;
    }

    function _mint(address dst, uint amount) internal {
        // mint the amount
        totalSupply = totalSupply.add(amount);

        // transfer the amount to the recipient
        balances[dst] = balances[dst].add(amount);
        emit Transfer(address(0), dst, amount);
    }

    function _burn(address dst, uint amount) internal {
        // burn the amount
        totalSupply = totalSupply.sub(amount, "::_burn: underflow");

        // transfer the amount to the recipient
        balances[dst] = balances[dst].sub(amount, "::_burn: underflow");
        emit Transfer(dst, address(0), amount);
    }

    /**
     * @notice withdraw all liquidity from msg.sender shares
     * @return success/failure
     */
    function withdrawAll() external returns (bool) {
        return withdraw(balances[msg.sender]);
    }
    
    function liquidityBalance() public view returns (uint) {
        return IERC20(reserve).balanceOf(address(this));
    }
    
    function inCaseTokensGetStuck(address token) external {
        require(msg.sender == governance, "::inCaseTokensGetStuck: only governance");
        IERC20(token).transfer(governance, IERC20(token).balanceOf(address(this)));
    }

    /**
     * @notice withdraw `_shares` amount of liquidity for user
     * @param _shares the amount of shares to burn for liquidity
     * @return success/failure
     */
    function withdraw(uint _shares) public returns (bool) {
        uint r = liquidityBalance().mul(_shares).div(totalSupply);
        _burn(msg.sender, _shares);

        IERC20(reserve).transfer(msg.sender, r);
        emit Withdrew(msg.sender, _shares, r);
        return true;
    }

    /**
     * @notice deposit all liquidity from msg.sender
     * @return success/failure
     */
    function depositAll() external returns (bool) {
        return deposit(IERC20(reserve).balanceOf(msg.sender));
    }

    /**
     * @notice deposit `amount` amount of liquidity for user
     * @param amount the amount of liquidity to add for shares
     * @return success/failure
     */
    function deposit(uint amount) public returns (bool) {
        IERC20(reserve).transferFrom(msg.sender, address(this), amount);
        uint _shares = 0;
        if (liquidityBalance() == 0) {
            _shares = amount;
        } else {
            _shares = amount.mul(totalSupply).div(liquidityBalance());
        }
        _mint(msg.sender, _shares);
        emit Deposited(msg.sender, _shares, amount);
        return true;
    }

    /**
     * @notice batch close any pending open options that have expired
     * @param size the maximum size of batch to execute
     * @return the last index processed
     */
    function closeInBatches(uint size) external returns (uint) {
        uint i = processedIndex;
        for (; i < size; i++) {
            close(i);
        }
        processedIndex = i;
        return processedIndex;
    }

    /**
     * @notice iterate through all open options and close
     * @return the last index processed
     */
    function closeAllOpen() external returns (uint) {
        uint i = processedIndex;
        for (; i < nextIndex; i++) {
            close(i);
        }
        processedIndex = i;
        return processedIndex;
    }

    /**
     * @notice close a specific options based on id
     * @param id the `id` of the given options to close
     * @return success/failure
     */
    function close(uint id) public returns (bool) {
        position storage _pos = positions[id];
        if (_pos.owner == address(0x0)) {
            return false;
        }
        if (!_pos.open) {
            return false;
        }
        if (_pos.expire > block.timestamp) {
            return false;
        }
        _pos.open = false;
        reserveInUse = reserveInUse.sub(_pos.amountOut);
        emit Closed(id, _pos.owner, _pos.created, _pos.expire);
        return true;
    }
    
    function calculateFee(address tokenIn, uint amountIn, uint amountOut) public view returns (uint) {
        return OptionsV1Library.fees(amountIn, amountOut, OptionsV1Library.quote(tokenIn, amountIn));
    }
    
    function quote(address tokenIn, uint amountIn) public view returns (uint) {
        return OptionsV1Library.quote(tokenIn, amountIn);
    }

    /**
     * @notice Creates a new option position for the owner
     * @param tokenIn the token you are adding to the pool if you exercise the option
     * @param amountIn the amount of option cover
     * @param amountOut the amount of tokens you would like out
     */
    function createOption(address tokenIn, uint amountIn, uint amountOut) external returns (uint) {
        reserveInUse = reserveInUse.add(amountOut);
        require(liquidityBalance() > reserveInUse, '::createOption: insufficient liquidity');
        
        IERC20(tokenIn).transferFrom(msg.sender, address(this), calculateFee(tokenIn, amountIn, amountOut));

        positions.push(position(msg.sender, tokenIn, amountIn, amountOut, block.timestamp, block.timestamp.add(OptionsV1Library.PERIOD), true));
        options[msg.sender].push(nextIndex);

        emit Created(nextIndex, msg.sender, tokenIn, amountIn, amountOut, block.timestamp, block.timestamp.add(OptionsV1Library.PERIOD));
        return nextIndex++;
    }

    /**
     * @notice swap a non expired option
     * @param id the id of the options to close
     * @return true/false if option was success
     */
    function exercise(uint id) external returns (bool) {
        position storage _pos = positions[id];
        require(_pos.open, "::exercise: position is closed");
        require(_pos.expire < block.timestamp, "::exercise: position expired");
        IERC20(_pos.asset).transferFrom(msg.sender, address(this), _pos.amountIn);
        IERC20(reserve).transfer(msg.sender, _pos.amountOut);
        _pos.open = false;
        positions[id] = _pos;
        emit Excercised(id, _pos.owner, _pos.asset, _pos.amountIn, _pos.amountOut, _pos.created, _pos.expire);
        return true;
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
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @return Whether or not the approval succeeded
     */
    function approve(address spender, uint amount) public returns (bool) {
        allowances[msg.sender][spender] = amount;

        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Triggers an approval from owner to spends
     * @param owner The address to approve from
     * @param spender The address to be approved
     * @param amount The number of tokens that are approved (2^256-1 means infinite)
     * @param deadline The time at which to expire the signature
     * @param v The recovery byte of the signature
     * @param r Half of the ECDSA signature pair
     * @param s Half of the ECDSA signature pair
     */
    function permit(address owner, address spender, uint amount, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        bytes32 domainSeparator = keccak256(abi.encode(DOMAIN_TYPEHASH, keccak256(bytes(name)), getChainId(), address(this)));
        bytes32 structHash = keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, amount, nonces[owner]++, deadline));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signatory = ecrecover(digest, v, r, s);
        require(signatory != address(0), "::permit: invalid signature");
        require(signatory == owner, "::permit: unauthorized");
        require(now <= deadline, "::permit: signature expired");

        allowances[owner][spender] = amount;

        emit Approval(owner, spender, amount);
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
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transfer(address dst, uint amount) public returns (bool) {
        _transferTokens(msg.sender, dst, amount);
        return true;
    }

    /**
     * @notice Transfer `amount` tokens from `src` to `dst`
     * @param src The address of the source account
     * @param dst The address of the destination account
     * @param amount The number of tokens to transfer
     * @return Whether or not the transfer succeeded
     */
    function transferFrom(address src, address dst, uint amount) external returns (bool) {
        address spender = msg.sender;
        uint spenderAllowance = allowances[src][spender];

        if (spender != src && spenderAllowance != uint(-1)) {
            uint newAllowance = spenderAllowance.sub(amount, "::transferFrom: transfer amount exceeds spender allowance");
            allowances[src][spender] = newAllowance;

            emit Approval(src, spender, newAllowance);
        }

        _transferTokens(src, dst, amount);
        return true;
    }

    function _transferTokens(address src, address dst, uint amount) internal {
        require(src != address(0), "::_transferTokens: cannot transfer from the zero address");
        require(dst != address(0), "::_transferTokens: cannot transfer to the zero address");

        balances[src] = balances[src].sub(amount, "::_transferTokens: transfer amount exceeds balance");
        balances[dst] = balances[dst].add(amount, "::_transferTokens: transfer amount overflows");
        emit Transfer(src, dst, amount);
    }

    function getChainId() internal pure returns (uint) {
        uint chainId;
        assembly { chainId := chainid() }
        return chainId;
    }
}