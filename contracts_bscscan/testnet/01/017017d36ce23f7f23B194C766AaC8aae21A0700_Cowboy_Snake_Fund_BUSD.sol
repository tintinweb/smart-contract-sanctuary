/**
 *Submitted for verification at BscScan.com on 2021-11-10
*/

pragma solidity ^0.5.17;

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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


/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
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
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
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
     * - `sender` must have a balance of at least `value`.
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender].sub(amount));
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].add(addedValue));
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender].sub(subtractedValue));
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount);
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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

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
    function _burn(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
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
    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Destoys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, msg.sender, _allowances[account][msg.sender].sub(amount));
    }
}

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
        require(b <= a, "SafeMath: subtraction overflow");
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
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
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
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

/**
 * @title Cowboy_Snake_Fund_BUSD_Contract
 * @dev Cowboy_Snake_Fund_BUSD_Contract is a token holder contract 
 */
contract Cowboy_Snake_Fund_BUSD_Contract {
    using SafeERC20 for IERC20;

    // ERC20 basic token contract being held
    IERC20 private _token;
    uint constant E18 = 10**18;
    // payout wallet
    address private _accountant;
    // owner wallet
    address public owner;
    // send wallet
    address private _signer;
    address public founder_1;
    uint256 public _vote1;
    address public founder_2;
    uint256 public _vote2;
    address public founder_3;
    uint256 public _vote3;
    address public founder_4;
    uint256 public _vote4;
    address public founder_5;
    uint256 public _vote5;

    event releaseAmountAt(address indexed senderAddress,address indexed payoutAddress,uint256 amount);
    event updateSignerAt(address indexed oldAddress,address indexed newAddress);
 

    constructor (IERC20 token,  address accountantAddress, address signerAddress, 
    address founderAddress_1, address founderAddress_2, address founderAddress_3, 
    address founderAddress_4, address founderAddress_5) public 
    {
       
       owner = tx.origin;
        _token = token; // BUSD : 0xe9e7cea3dedca5984780bafc599bd69add087d56
        _signer = signerAddress;
        _accountant = accountantAddress;
        founder_1 =  founderAddress_1;
        founder_2 =  founderAddress_2;
        founder_3 =  founderAddress_3;
        founder_4 =  founderAddress_4;
        founder_5 =  founderAddress_5;
        
        _vote1=0;
        _vote2=0;
        _vote3=0;
        _vote4=0;
        _vote5=0;

    }
    function token() public view returns (IERC20) {
            return _token;
    }

    function totalBUSD() public view returns (uint256) {
        uint256 balanceWallet = _token.balanceOf(address(this));
        return balanceWallet;
    }
    
    function updateSigner(address newAddress) public {
        require(msg.sender == owner, "!access denied");
        emit updateSignerAt(_signer,newAddress);
        _signer = newAddress;
       
    }
    
    function signerAddress() public view returns (address) {
        return _signer;
    }
    
    function accountantAddress() public view returns (address) {
        require(msg.sender == _signer, "!wrong sender. access denied");
        return _accountant;
    }


    function setVote1(uint256 amount) public  returns (uint256) {
        require(msg.sender == founder_1, "!access denied");
         _vote1 = amount;
        return _vote1;
    }
    
    function unsetVote1() public  returns (uint256) {
        require(msg.sender == founder_1, "!access denied");
         _vote1 = 0;
        return _vote1;
    }
    
    function setVote2(uint256 amount) public  returns (uint256) {
        require(msg.sender == founder_2, "!access denied");
         _vote2 = amount;
        return _vote2;
    }
    
    function unsetVote2() public  returns (uint256) {
        require(msg.sender == founder_2, "!access denied");
         _vote2 = 0;
        return _vote2;
    }
    function setVote3(uint256 amount) public  returns (uint256) {
        require(msg.sender == founder_3, "!access denied");
         _vote3 = amount;
        return _vote3;
    }
    function unsetVote3() public  returns (uint256) {
        require(msg.sender == founder_3, "!access denied");
         _vote3 = 0;
        return _vote3;
    }
    
    function setVote4(uint256 amount) public  returns (uint256) {
        require(msg.sender == founder_4, "!access denied");
         _vote4 = amount;
        return _vote4;
    }
    
    function unsetVote4() public  returns (uint256) {
        require(msg.sender == founder_4, "!access denied");
         _vote4 = 0;
        return _vote4;
    }
    
    function setVote5(uint256 amount) public  returns (uint256) {
        require(msg.sender == founder_5, "!access denied");
         _vote5 = amount;
        return _vote5;
    }
    
    function unsetVote5() public  returns (uint256) {
        require(msg.sender == founder_5, "!access denied");
         _vote5 = 0;
        return _vote5;
    }
    
    /**
     * @notice Transfers tokens held by _signer to _accountant.
     */
    
    function releaseAmount(uint256 amount) public {
        // solhint-disable-next-line not-rely-on-time
        require(msg.sender == _signer, "!wrong sender. access denied");
        uint256 balanceWallet = _token.balanceOf(address(this));
        require(amount <= balanceWallet, "Sorry: not enough tokens to send");
        
        uint256 vote=0;
        if ( _vote1 > 0 && _vote2 > 0 && _vote3 > 0 && _vote4 > 0 && _vote1==_vote2 && _vote2==_vote3 && _vote3==_vote4){
            vote=_vote1;
        }
        if ( _vote1 > 0 && _vote2 > 0 && _vote3 > 0 && _vote5 > 0 && _vote1==_vote2 && _vote2==_vote3 && _vote3==_vote5){
            vote=_vote1;
        }
        if (_vote1 > 0 && _vote2 > 0 && _vote4 > 0 && _vote5 > 0 && _vote1==_vote2 && _vote2==_vote4 && _vote4==_vote5){
            vote=_vote1;
        }
        if (_vote1 > 0 && _vote3 > 0 && _vote4 > 0 && _vote5 > 0 && _vote1==_vote3 && _vote3==_vote4 && _vote4==_vote5){
            vote=_vote1;
        }
        if (_vote2 > 0 && _vote3 > 0 && _vote4 > 0 && _vote5 > 0 && _vote2==_vote3 && _vote3==_vote4 && _vote4==_vote5){
            vote=_vote2;
        }
        require(vote > 0, "Sorry: Not enought 4 vote");
        require(amount >0 , "Sorry: not allow tokens to send");
        require(amount == vote, "Sorry: amount not equal vote");
        
         if( ( _vote1 > 0 && _vote2 > 0 && _vote3 > 0 && _vote4 > 0 && _vote1==_vote2 && _vote2==_vote3 && _vote3==_vote4)||
            ( _vote1 > 0 && _vote2 > 0 && _vote3 > 0 && _vote5 > 0 && _vote1==_vote2 && _vote2==_vote3 && _vote3==_vote5)||
            ( _vote1 > 0 && _vote2 > 0 && _vote4 > 0 && _vote5 > 0 && _vote1==_vote2 && _vote2==_vote4 && _vote4==_vote5)||
            ( _vote1 > 0 && _vote3 > 0 && _vote4 > 0 && _vote5 > 0 && _vote1==_vote3 && _vote3==_vote4 && _vote4==_vote5)||
            ( _vote2 > 0 && _vote3 > 0 && _vote4 > 0 && _vote5 > 0 && _vote2==_vote3 && _vote3==_vote4 && _vote4==_vote5) ){
            
           
            _token.safeTransfer(_accountant, amount*E18);
            _vote1 = 0;
            _vote2 = 0;
            _vote3 = 0;
            _vote4 = 0;
            _vote5 = 0;
            emit releaseAmountAt(msg.sender,_accountant,amount*E18);
         }
         else{
             revert('Not enought 4 vote');
         }
    }
    
    
    /**
     * @notice Transfers any BEP20 tokens held by _signer to _accountant.
     */
    
    function releaseAmountBEP20(IERC20 tokenBEP20,uint256 amount) public {
        // solhint-disable-next-line not-rely-on-time
        require(msg.sender == _signer, "!wrong sender. access denied");
        uint256 balanceWallet = tokenBEP20.balanceOf(address(this));
        require(amount <= balanceWallet, "Sorry: not enough tokens to send");
        
        uint256 vote=0;
        if ( _vote1 > 0 && _vote2 > 0 && _vote3 > 0 && _vote4 > 0 && _vote1==_vote2 && _vote2==_vote3 && _vote3==_vote4){
            vote=_vote1;
        }
        if ( _vote1 > 0 && _vote2 > 0 && _vote3 > 0 && _vote5 > 0 && _vote1==_vote2 && _vote2==_vote3 && _vote3==_vote5){
            vote=_vote1;
        }
        if (_vote1 > 0 && _vote2 > 0 && _vote4 > 0 && _vote5 > 0 && _vote1==_vote2 && _vote2==_vote4 && _vote4==_vote5){
            vote=_vote1;
        }
        if (_vote1 > 0 && _vote3 > 0 && _vote4 > 0 && _vote5 > 0 && _vote1==_vote3 && _vote3==_vote4 && _vote4==_vote5){
            vote=_vote1;
        }
        if (_vote2 > 0 && _vote3 > 0 && _vote4 > 0 && _vote5 > 0 && _vote2==_vote3 && _vote3==_vote4 && _vote4==_vote5){
            vote=_vote2;
        }
        require(vote > 0, "Sorry: Not enought 4 vote");
        require(amount >0 , "Sorry: not allow tokens to send");
        require(amount == vote, "Sorry: amount not equal vote");
        
         if( ( _vote1 > 0 && _vote2 > 0 && _vote3 > 0 && _vote4 > 0 && _vote1==_vote2 && _vote2==_vote3 && _vote3==_vote4)||
            ( _vote1 > 0 && _vote2 > 0 && _vote3 > 0 && _vote5 > 0 && _vote1==_vote2 && _vote2==_vote3 && _vote3==_vote5)||
            ( _vote1 > 0 && _vote2 > 0 && _vote4 > 0 && _vote5 > 0 && _vote1==_vote2 && _vote2==_vote4 && _vote4==_vote5)||
            ( _vote1 > 0 && _vote3 > 0 && _vote4 > 0 && _vote5 > 0 && _vote1==_vote3 && _vote3==_vote4 && _vote4==_vote5)||
            ( _vote2 > 0 && _vote3 > 0 && _vote4 > 0 && _vote5 > 0 && _vote2==_vote3 && _vote3==_vote4 && _vote4==_vote5) ){
            
           
            tokenBEP20.safeTransfer(_accountant, amount);
            _vote1 = 0;
            _vote2 = 0;
            _vote3 = 0;
            _vote4 = 0;
            _vote5 = 0;
            emit releaseAmountAt(msg.sender,_accountant,amount);
         }
         else{
             revert('Not enought 4 vote');
         }
    }

    
}


contract Cowboy_Snake_Fund_BUSD is Cowboy_Snake_Fund_BUSD_Contract {
    constructor(IERC20 token, address accountant, address signer,address founderAddress_1, address founderAddress_2, address founderAddress_3, 
    address founderAddress_4, address founderAddress_5)
        public
        Cowboy_Snake_Fund_BUSD_Contract(token, accountant, signer,founderAddress_1,founderAddress_2,founderAddress_3,founderAddress_4,founderAddress_5)
    {}
}