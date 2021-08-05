/**
 *Submitted for verification at Etherscan.io on 2020-09-29
*/

pragma solidity ^0.6.0;

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

contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }

    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;
    using Address for address;

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
    constructor (string memory name, string memory symbol) public {
        _name = name;
        _symbol = symbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
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
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view override returns (uint256) {
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
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
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
     * Requirements
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
     * Requirements
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
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
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
    function _setupDecimals(uint8 decimals_) internal {
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
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

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
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
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
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract dCOCKv2 is ERC20 {
    
    struct stakeTracker {
        uint256 lastBlockChecked;
        uint256 rewards;
        uint256 crumbsStaked;
        
        uint256 lastBlockCheckedLP;
        uint256 rewardsLP;
        uint256 crumbsStakedLP;
    }

    address private owner;
    
    uint256 private rewardsVar;
    uint256 private rewardsVarLP;
    
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
 
    address private crumbsAddress;
    IERC20 private crumbsToken;
    
    //LP
    address private crumbsAddressLP;
    IERC20 private crumbsTokenLP;

    uint256 private _totalCrumbsStaked;
    mapping(address => stakeTracker) private _stakedBalances;
    
    //LP
    uint256 private _totalCrumbsStakedLP;
    mapping(address => stakeTracker) private _stakedBalancesLP;
    
    constructor() public ERC20("dCOCK", "dCOCK") {
        owner = msg.sender;
        _mint(msg.sender, 1 * (10 ** 18));
        rewardsVar = 100000000;
        rewardsVarLP = 200000000;
    }
    
    event Staked(address indexed user, uint256 amount, uint256 totalCrumbsStaked);
    event Withdrawn(address indexed user, uint256 amount);
    event Rewards(address indexed user, uint256 reward);
    
    event StakedLP(address indexed user, uint256 amount, uint256 totalCrumbsStakedLP);
    event WithdrawnLP(address indexed user, uint256 amountLP);
    event RewardsLP(address indexed user, uint256 rewardLP);
    
    modifier _onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier updateStakingReward(address account) {
        if (block.number > _stakedBalances[account].lastBlockChecked) {
            uint256 rewardBlocks = block.number
                                        .sub(_stakedBalances[account].lastBlockChecked);
                                        
                                        
             
            if (_stakedBalances[account].crumbsStaked > 0) {
                _stakedBalances[account].rewards = _stakedBalances[account].rewards
                                                                            .add(
                                                                            _stakedBalances[account].crumbsStaked
                                                                            .mul(rewardBlocks)
                                                                            / rewardsVar);
            }
                    
            _stakedBalances[account].lastBlockChecked = block.number;
            
            emit Rewards(account, _stakedBalances[account].rewards);                                                     
        }
        _;
    }
    
    modifier updateStakingRewardLP(address account) {
        if (block.number > _stakedBalancesLP[account].lastBlockChecked) {
            uint256 rewardBlocksLP = block.number
                                        .sub(_stakedBalancesLP[account].lastBlockCheckedLP);
                                        
                                        
             
            if (_stakedBalancesLP[account].crumbsStakedLP > 0) {
                _stakedBalancesLP[account].rewardsLP = _stakedBalancesLP[account].rewardsLP
                                                                            .add(
                                                                            _stakedBalancesLP[account].crumbsStakedLP
                                                                            .mul(rewardBlocksLP)
                                                                            / rewardsVarLP);
            }
                    
            _stakedBalancesLP[account].lastBlockCheckedLP = block.number;
            
            emit RewardsLP(account, _stakedBalancesLP[account].rewardsLP);                                                     
        }
        _;
    }


    function setCrumbsAddress(address _crumbsAddress) public _onlyOwner returns(uint256) {
        crumbsAddress = _crumbsAddress;
        crumbsToken = IERC20(_crumbsAddress);
    }
    
    function setCrumbsAddressLP(address _crumbsAddressLP) public _onlyOwner returns(uint256) {
        crumbsAddressLP = _crumbsAddressLP;
        crumbsTokenLP = IERC20(_crumbsAddressLP);
    }
    
    function updatingStakingReward(address account) public returns(uint256) {
        if (block.number > _stakedBalances[account].lastBlockChecked) {
            uint256 rewardBlocks = block.number
                                        .sub(_stakedBalances[account].lastBlockChecked);
                                        
                                        
            if (_stakedBalances[account].crumbsStaked > 0) {
                _stakedBalances[account].rewards = _stakedBalances[account].rewards
                                                                            .add(
                                                                            _stakedBalances[account].crumbsStaked
                                                                            .mul(rewardBlocks)
                                                                            / rewardsVar);
            }
                                                
            _stakedBalances[account].lastBlockChecked = block.number;
                                                
            emit Rewards(account, _stakedBalances[account].rewards);                                                     
        
        }
        return(_stakedBalances[account].rewards);
    }
    
    function updatingStakingRewardLP(address account) public returns(uint256) {
        if (block.number > _stakedBalancesLP[account].lastBlockCheckedLP) {
            uint256 rewardBlocksLP = block.number
                                        .sub(_stakedBalancesLP[account].lastBlockCheckedLP);
                                        
                                        
            if (_stakedBalancesLP[account].crumbsStakedLP > 0) {
                _stakedBalancesLP[account].rewardsLP = _stakedBalancesLP[account].rewardsLP
                                                                            .add(
                                                                            _stakedBalancesLP[account].crumbsStakedLP
                                                                            .mul(rewardBlocksLP)
                                                                            / rewardsVarLP);
            }
                                                
            _stakedBalancesLP[account].lastBlockCheckedLP = block.number;
                                                
            emit RewardsLP(account, _stakedBalancesLP[account].rewardsLP);                                                     
        
        }
        return(_stakedBalancesLP[account].rewardsLP);
    }
    
    function getBlockNum() public view returns (uint256) {
        return block.number;
    }
    
    function getLastBlockCheckedNum(address _account) public view returns (uint256) {
        return _stakedBalances[_account].lastBlockChecked;
    }
    
    function getLastBlockCheckedNumLP(address _account) public view returns (uint256) {
        return _stakedBalancesLP[_account].lastBlockCheckedLP;
    }

    function getAddressStakeAmount(address _account) public view returns (uint256) {
        return _stakedBalances[_account].crumbsStaked;
    }
    
    function getAddressStakeAmountLP(address _account) public view returns (uint256) {
        return _stakedBalancesLP[_account].crumbsStakedLP;
    }
    
    function setRewardsVar(uint256 _amount) public _onlyOwner {
        rewardsVar = _amount;
    }
    
    function setRewardsVarLP(uint256 _amount) public _onlyOwner {
        rewardsVarLP = _amount;
    }
    
    function totalStakedSupply() public view returns (uint256) {
        return _totalCrumbsStaked;
    }
    
    function totalStakedSupplyLP() public view returns (uint256) {
        return _totalCrumbsStakedLP;
    }

    function myRewardsBalance(address account) public view returns (uint256) {
        if (block.number > _stakedBalances[account].lastBlockChecked) {
            uint256 rewardBlocks = block.number
                                        .sub(_stakedBalances[account].lastBlockChecked);
                                        
                                        
             
            if (_stakedBalances[account].crumbsStaked > 0) {
                return _stakedBalances[account].rewards
                                                .add(
                                                _stakedBalances[account].crumbsStaked
                                                .mul(rewardBlocks)
                                                / rewardsVar);
            }                                                  
        }

    }
    
    function myRewardsBalanceLP(address account) public view returns (uint256) {
        if (block.number > _stakedBalancesLP[account].lastBlockCheckedLP) {
            uint256 rewardBlocksLP = block.number
                                        .sub(_stakedBalancesLP[account].lastBlockCheckedLP);
                                        
                                        
             
            if (_stakedBalancesLP[account].crumbsStaked > 0) {
                return _stakedBalancesLP[account].rewardsLP
                                                .add(
                                                _stakedBalancesLP[account].crumbsStakedLP
                                                .mul(rewardBlocksLP)
                                                / rewardsVarLP);
            }                                                  
        }

    }

    function stake(uint256 amount) public updateStakingReward(msg.sender) {
        _totalCrumbsStaked = _totalCrumbsStaked.add(amount);
        _stakedBalances[msg.sender].crumbsStaked = _stakedBalances[msg.sender].crumbsStaked.add(amount);
        crumbsToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount, _totalCrumbsStaked);
    }
    
    function stakeLP(uint256 amount) public updateStakingRewardLP(msg.sender) {
        _totalCrumbsStakedLP = _totalCrumbsStakedLP.add(amount);
        _stakedBalancesLP[msg.sender].crumbsStakedLP = _stakedBalancesLP[msg.sender].crumbsStakedLP.add(amount);
        crumbsTokenLP.safeTransferFrom(msg.sender, address(this), amount);
        emit StakedLP(msg.sender, amount, _totalCrumbsStakedLP);
    }

    function withdraw(uint256 amount) public updateStakingReward(msg.sender) {
        _totalCrumbsStaked = _totalCrumbsStaked.sub(amount);
        _stakedBalances[msg.sender].crumbsStaked = _stakedBalances[msg.sender].crumbsStaked.sub(amount);
        crumbsToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }
    
    function withdrawLP(uint256 amount) public updateStakingRewardLP(msg.sender) {
        _totalCrumbsStakedLP = _totalCrumbsStakedLP.sub(amount);
        _stakedBalancesLP[msg.sender].crumbsStakedLP = _stakedBalancesLP[msg.sender].crumbsStakedLP.sub(amount);
        crumbsTokenLP.safeTransfer(msg.sender, amount);
        emit WithdrawnLP(msg.sender, amount);
    }
    
   function getReward() public updateStakingReward(msg.sender) {
       uint256 reward = _stakedBalances[msg.sender].rewards;
       _stakedBalances[msg.sender].rewards = 0;
       _mint(msg.sender, reward.mul(8) / 10);
       uint256 fundingPoolReward = reward.mul(2) / 10;
       _mint(crumbsAddress, fundingPoolReward);
       emit Rewards(msg.sender, reward);
   }
   
    function getRewardLP() public updateStakingRewardLP(msg.sender) {
       uint256 rewardLP = _stakedBalancesLP[msg.sender].rewardsLP;
       _stakedBalancesLP[msg.sender].rewardsLP = 0;
       _mint(msg.sender, rewardLP.mul(8) / 10);
       uint256 fundingPoolRewardLP = rewardLP.mul(2) / 10;
       _mint(crumbsAddressLP, fundingPoolRewardLP);
       emit RewardsLP(msg.sender, rewardLP);
   }

    
}