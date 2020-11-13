// SPDX-License-Identifier: MIT

pragma solidity 0.6.11;

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


/**
 * SPDX-License-Identifier: <SPDX-License>
 * @dev Implementation of the {ICXN} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {CXNPresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-CXN-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of CXN applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {ICXN-approve}.
 */


contract CXN {
    
    using SafeMath for uint256;
    using Address for address;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;
    bool private _initialized;

    uint256 private _burnRate; // 7%
    uint256 private _forStakers; // 4%

    uint256 private _burnRateStaker;
    uint256 private _unstakeForStaker;

    uint256 private _Burnt_Limit;
    uint256 private _Min_Stake;

    uint256 private _Scale;
    

    struct Party {
		bool elite;
		uint256 balance;
		uint256 staked;
        uint256 payoutstake;
		mapping(address => uint256) allowance;
	}

	struct Board {
		uint256 totalSupply;
		uint256 totalStaked;
        uint256 totalBurnt;
        uint256 retPerToken;
		mapping(address => Party) parties;
		address owner;
	}

    Board private _board;


    event Transfer(address indexed from, address indexed to, uint256 tokens);
	event Approval(address indexed owner, address indexed spender, uint256 tokens);
	event Eliters(address indexed Party, bool status);
	event Stake(address indexed owner, uint256 tokens);
	event UnStake(address indexed owner, uint256 tokens);
    event StakeGain(address indexed owner, uint256 tokens);
	event Burn(uint256 tokens);


    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor () public {
        
        require(!_initialized);

       _totalSupply = 3e26;
       _name = "CXN Network";
       _symbol = "CXN";
       _decimals = 18;
       _burnRate = 7;
       _forStakers = 4;
       _burnRateStaker = 5;
       _unstakeForStaker= 3;
       _Burnt_Limit=1e26;
       _Scale = 2**64;
       _Min_Stake= 1000;
       
        _board.owner = msg.sender;
		_board.totalSupply = _totalSupply;
		_board.parties[msg.sender].balance = _totalSupply;
        _board.retPerToken = 0;
		emit Transfer(address(0x0), msg.sender, _totalSupply);
		eliters(msg.sender, true);

        _initialized = true;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {CXN} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {ICXN-balanceOf} and {ICXN-transfer}.
     */
    function decimals() external view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {ICXN-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _board.totalSupply;
    }

    /**
     * @dev See {ICXN-balanceOf}.
     */
    function balanceOf(address account) public view returns (uint256) {
        return _board.parties[account].balance;
    }

    function stakeOf(address account) public view returns (uint256) {
        return _board.parties[account].staked;
    }

    function totalStake() public view returns (uint256) {
        return _board.totalStaked;
    }

    function changeAdmin(address _to) external virtual{
        require(msg.sender == _board.owner);
        
        
        transfer(_to,_board.parties[msg.sender].balance);
        eliters(_to,true);
        
        _board.owner = msg.sender;
        
    }



    /**
     * @dev See {ICXN-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual returns (bool) {
        _transfer(msg.sender, recipient, amount);
        
        return true;
    }

    /**
     * @dev See {ICXN-allowance}.
     */
    function allowance(address owner, address spender) external view virtual returns (uint256) {
        return _board.parties[owner].allowance[spender];
    }

    /**
     * @dev See {ICXN-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) external virtual returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {ICXN-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {CXN};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external virtual returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _board.parties[sender].allowance[msg.sender].sub(amount, "CXN: transfer amount exceeds allowance"));
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ICXN-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, _board.parties[msg.sender].allowance[spender].add(addedValue));
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {ICXN-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        _approve(msg.sender, spender, _board.parties[msg.sender].allowance[spender].sub(subtractedValue, "CXN: decreased allowance below zero"));
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
        require(sender != address(0), "CXN: transfer from the zero address");
        require(recipient != address(0), "CXN: transfer to the zero address");
        require(balanceOf(sender) >= amount);

        _board.parties[sender].balance = _board.parties[sender].balance.sub(amount, "CXN: transfer amount exceeds balance");

        uint256 toBurn = amount.mul(_burnRate).div(100);

        if(_board.totalSupply < _Burnt_Limit || _board.parties[sender].elite){
            toBurn = 0;
        }
        uint256 _transferred = amount.sub(toBurn);

        _board.parties[recipient].balance = _board.parties[recipient].balance.add(_transferred);
        
        emit Transfer(sender,recipient,_transferred);

        if(toBurn > 0){
            if(_board.totalStaked > 0){
                uint256 toDistribute = amount.mul(_forStakers).div(100);

               _board.retPerToken = _board.retPerToken.add(toDistribute.mul(_Scale).div(_board.totalStaked));

              toBurn = toBurn.sub(toDistribute);
            }

            _board.totalSupply = _board.totalSupply.sub(toBurn);
            emit Transfer(sender, address(0x0), toBurn);
			emit Burn(toBurn);
        }

        
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
        require(account != address(0), "CXN: burn from the zero address");


        _board.parties[account].balance = _board.parties[account].balance.sub(amount, "CXN: burn amount exceeds balance");
        _board.totalSupply = _board.totalSupply.sub(amount);
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
        require(owner != address(0), "CXN: approve from the zero address");
        require(spender != address(0), "CXN: approve to the zero address");

        _board.parties[owner].allowance[spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function eliters(address party, bool _status) public {
		require(msg.sender == _board.owner);
		_board.parties[party].elite = _status;
		emit Eliters(party, _status);
	}

    function stake(uint256 amount) external virtual {
        require(balanceOf(msg.sender) >= amount);
        require(amount >= _Min_Stake);
        
        redeemGain();

        _board.totalStaked = _board.totalStaked.add(amount);
        _board.parties[msg.sender].balance = _board.parties[msg.sender].balance.sub(amount);
        _board.parties[msg.sender].staked = _board.parties[msg.sender].staked.add(amount);
        _board.parties[msg.sender].payoutstake = _board.retPerToken;
        

        emit Stake(msg.sender, amount);
    }

    function unStake(uint256 amount) external virtual {
        require(_board.parties[msg.sender].staked >= amount);

        uint256 toBurn = amount.mul(_burnRateStaker).div(100);

        uint256 toStakers = amount.mul(_unstakeForStaker).div(100);
        
        uint256 stakeGainOfAmount = _stakeReturnOfAmount(msg.sender,amount);
        
        _board.parties[msg.sender].balance = _board.parties[msg.sender].balance.add(stakeGainOfAmount);
        
        
        _board.totalStaked = _board.totalStaked.sub(amount);

        _board.retPerToken = _board.retPerToken.add(toStakers.mul(_Scale).div(_board.totalStaked));
        
        uint256 toReturn = amount.sub(toBurn);
        
        _board.parties[msg.sender].balance = _board.parties[msg.sender].balance.add(toReturn);
        _board.parties[msg.sender].staked = _board.parties[msg.sender].staked.sub(amount);
        
        emit UnStake(msg.sender, amount);
    }

    function redeemGain() public virtual returns(uint256){
        uint256 ret = stakeReturnOf(msg.sender);
		if(ret == 0){
		    return 0;
		}
		
		_board.parties[msg.sender].payoutstake = _board.retPerToken;
		_board.parties[msg.sender].balance = _board.parties[msg.sender].balance.add(ret);
		emit Transfer(address(this), msg.sender, ret);
		emit StakeGain(msg.sender, ret);
        return ret;
    }

    function stakeReturnOf(address sender) public view returns (uint256) {
        uint256 profitReturnRate = _board.retPerToken.sub(_board.parties[sender].payoutstake);
        return uint256(profitReturnRate.mul(_board.parties[sender].staked).div(_Scale));
        
	}
	
	function _stakeReturnOfAmount(address sender, uint256 amount) internal view returns (uint256) {
	    uint256 profitReturnRate = _board.retPerToken.sub(_board.parties[sender].payoutstake);
        return uint256(profitReturnRate.mul(amount).div(_Scale));
	}
    

    function partyDetails(address sender) external view returns (uint256 totalTokenSupply,uint256 totalStakes,uint256 balance,uint256 staked,uint256 stakeReturns){
       return (totalSupply(),totalStake(), balanceOf(sender),stakeOf(sender),stakeReturnOf(sender));
    }

    function setMinStake(uint256 amount) external virtual returns(uint256) {
         require(msg.sender == _board.owner);
         require(amount > 0);
         _Min_Stake = amount;
         return _Min_Stake;
    }

    function minStake() public view returns(uint256) {
        return _Min_Stake;
    }

    function burn(uint256 amount) external virtual{
        require(amount <= _board.parties[msg.sender].balance);

        _burn(msg.sender,amount);

        emit Burn(amount);
    }

}