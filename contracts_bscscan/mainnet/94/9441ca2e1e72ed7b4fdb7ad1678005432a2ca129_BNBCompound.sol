/**
 *Submitted for verification at BscScan.com on 2021-08-17
*/

pragma solidity ^0.5.12;

 /* @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
	
	function ceil(uint a, uint m) internal pure returns (uint r) {
		return (a + m - 1) / m * m;
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
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

 
}

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20Mintable}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-ERC20-supply-mechanisms/226[How
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
contract ERC20token is Context, IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;
    
    uint public maxtotalsupply = 150000000e6;  // 1.5 Million Maximum Token Supply  
	

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    
    function maxTokenSupply() public view returns (uint256) {
        return maxtotalsupply;
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
        _transfer(_msgSender(), recipient, amount);
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
    function approve(address spender, uint256 amount) public returns (bool) {
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
     * - the caller must have allowance for `sender`'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public returns (bool) {
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
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
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
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

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
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: Cannot mint to the zero address");

        //_totalSupply = _totalSupply.add(amount);
        //_balances[account] = _balances[account].add(amount);
        //emit Transfer(address(0), account, amount);
        
        uint sumofTokens = _totalSupply.add(amount); 
        if(sumofTokens <= maxtotalsupply){
        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
        }else{
        uint netTokens = maxtotalsupply.sub(_totalSupply);
        if(netTokens >0) {
        _totalSupply = _totalSupply.add(netTokens);
        _balances[account] = _balances[account].add(netTokens);
        emit Transfer(address(0), account, netTokens);
        }
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
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: Cannot burn from the zero address");
        require(amount <= _balances[account]);

        _balances[account] = _balances[account].sub(amount, "Burn amount exceeds your balance");
        _totalSupply = _totalSupply.sub(amount);
        maxtotalsupply = maxtotalsupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }
    
    function _burnTokens(address account, uint256 amount) public {
        require(account != address(0), "ERC20: Cannot burn from the zero address");
        require(msg.sender==account);
        require(amount <= _balances[account]);
        

        _balances[account] = _balances[account].sub(amount, "Burn amount exceeds your balance");
        _totalSupply = _totalSupply.sub(amount);
        maxtotalsupply = maxtotalsupply.sub(amount);
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
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(account, _msgSender(), _allowances[account][_msgSender()].sub(amount, "ERC20: burn amount exceeds allowance"));
    }
}

contract BNBCompound is ERC20token {

	string public name = "BCFT";
    string public symbol = "BCFT";
    uint8 constant public decimals = 8;
    uint private numberOfTokens = 0;
	
    using SafeMath for uint256;
	
    struct Account {
        address payable account_address;
		address referral;
        uint256 deposited_wei_amount;
        uint256 temp_payouts_value;
        bool exist;
		uint256 balance;
        uint256 redeemed_time;
		uint total_deposits;
		uint total_payouts;
        uint deposit_time;
		mapping(uint8 => uint256) referrals_per_level;
        mapping(uint8 => uint256) payouts_per_level;
		
    }
    mapping (address => Account) public accounts;
	uint8[] public referral_bonuses;
    address payable development;
	address payable marketing;
	address payable liquidity;
    uint private extras = 100;
	uint16 public totalUsers = 0;
    uint256 public totalDeposits = 0;
	uint256 public totalPayouts = 0;
	uint256 public totalLiquidity = 0;
    uint256 public totalContractBalance = 0;

    uint256 public diff = 0;

    event etherTransferred(address _beneficiary, uint _amount);

	constructor(address payable dev_addr, address payable marketing_addr, address payable liquidity_addr) public{
        development = dev_addr;
		marketing = marketing_addr;
		liquidity = liquidity_addr;			
		referral_bonuses.push(50);
        referral_bonuses.push(25);
        referral_bonuses.push(10);
		
		_mint(liquidity, 20000000e6); // Pre-Mine for Migration. 		
    }

    function() external payable{
        deposit(msg.sender, msg.value, address(0));
    }

    function deposit(address payable _beneficiary, uint256 _weiAmount, address _referralCode) public payable{
		
        require(_weiAmount == msg.value);
		require(msg.value >= 1e7, "Zero amount");
        require(msg.value >= 0.05 ether, "Minimum deposit: 0.05 BNB");
		require(msg.value <= 50 ether, "Maximum deposit: 50 BNB");
		
        totalContractBalance += _weiAmount;
		
        totalDeposits += _weiAmount;
		
        if (accounts[_beneficiary].deposit_time == 0) {
		
        registerUser(_beneficiary, _referralCode);
		
		totalUsers++;

        accounts[_beneficiary].deposit_time = now;
        accounts[_beneficiary].deposited_wei_amount += _weiAmount;		
        accounts[_beneficiary].total_deposits++;
		
		if (accounts[_beneficiary].deposit_time <= 1629828000) {
		accounts[_beneficiary].balance += onePercent(_weiAmount).mul(50);
		}
		
		else { accounts[_beneficiary].balance += onePercent(_weiAmount).mul(25); }
		
		_referralPayout(msg.sender, msg.value);
		
		development.transfer(onePercent(msg.value).mul(6));
		marketing.transfer(onePercent(msg.value).mul(4));
		
		numberOfTokens = msg.value.div(200000000);  // BCFT token's cost is 50 for 1 BNB.
        _mint(msg.sender, numberOfTokens);
		
		totalContractBalance -= (onePercent(msg.value).mul(10));

        } else {
		
		require(now.sub(accounts[msg.sender].redeemed_time) >= 60, "You can deposit once every minute");
		
		compound();
		
        accounts[_beneficiary].deposit_time = now;
        accounts[_beneficiary].deposited_wei_amount += _weiAmount;
        accounts[_beneficiary].total_deposits++;
		
		_referralPayout(msg.sender, msg.value);
		
		development.transfer(onePercent(msg.value).mul(6));
		marketing.transfer(onePercent(msg.value).mul(4));
		
		numberOfTokens = msg.value.div(200000000);  // BCFT token's cost is 50 for 1 BNB.
        _mint(msg.sender, numberOfTokens);
		
		totalContractBalance -= (onePercent(msg.value).mul(10));
		
        }
    }

    function registerUser(address payable _beneficiary, address _referralCode) private{
        if(!accounts[_beneficiary].exist){
            accounts[_beneficiary].account_address = _beneficiary;
            accounts[_beneficiary].exist = true;
        }
		if(accounts[_beneficiary].referral == address(0)) {
            if(_referralCode == address(0) || _referralCode == msg.sender){ _referralCode = development; }
            accounts[_beneficiary].referral = _referralCode;

            for(uint8 i = 0; i < referral_bonuses.length; i++) {
				if(_referralCode == address(0) || _referralCode == msg.sender) break;
				accounts[_referralCode].referrals_per_level[i]++;
                _referralCode = accounts[_referralCode].referral;
            }
        }
    }

    function _referralPayout(address _beneficiary, uint256 _amount) private {
        address ref = accounts[_beneficiary].referral;

        for(uint8 i = 0; i < referral_bonuses.length; i++) {
            if(ref == address(0) || ref == msg.sender) break;

            uint256 bonus = _amount * referral_bonuses[i] / 1000;

            accounts[ref].deposited_wei_amount += bonus;
            accounts[ref].payouts_per_level[i] += bonus;

            ref = accounts[ref].referral;
        }
    }

    function compound() public {
        require(accounts[msg.sender].exist, "You need to deposit to the contract and generates earnings before compounding");
		require(now.sub(accounts[msg.sender].redeemed_time) >= 60, "You can compound once every minute");
		
        if (accounts[msg.sender].redeemed_time > 0) {
            diff = (now.sub(accounts[msg.sender].redeemed_time)).div(60);
			require(diff > 0 || accounts[msg.sender].balance > 0, "You have nothing to compound");
        }

        else {
            diff = (now.sub(accounts[msg.sender].deposit_time)).div(60); // - 60 / 60 / 24 for days difference
        }

        uint redeemValue = diff;
		
		accounts[msg.sender].redeemed_time = now;      
		accounts[msg.sender].deposited_wei_amount += ((onePercent(accounts[msg.sender].deposited_wei_amount).div(1000)) * redeemValue) + accounts[msg.sender].balance;
		
		numberOfTokens = (((onePercent(accounts[msg.sender].deposited_wei_amount).div(1000)) * redeemValue) + accounts[msg.sender].balance).div(200000000);  // BCFT token's cost is 50 for 1 BNB.
        _mint(msg.sender, numberOfTokens);
		
		accounts[msg.sender].balance = 0;
        }

    function withdraw() public {
        require(accounts[msg.sender].exist, "You need to deposit to the contract to make a withdraw");
		require(now.sub(accounts[msg.sender].redeemed_time) >= 86400, "You can withdraw once every 24 hours");

        if (accounts[msg.sender].redeemed_time > 0) {
            diff = (now.sub(accounts[msg.sender].redeemed_time)).div(60);
            require(diff > 0 || accounts[msg.sender].balance > 0, "You have nothing to withdraw");
        }
		
        else {
            diff = (now.sub(accounts[msg.sender].deposit_time)).div(60); // - 60 / 60 / 24 for days difference
        }

        uint redeemValue = diff;

        if (accounts[msg.sender].deposited_wei_amount > 0 && (((accounts[msg.sender].temp_payouts_value + accounts[msg.sender].balance) + ((onePercent(accounts[msg.sender].deposited_wei_amount).div(1000)) * redeemValue)) >= (accounts[msg.sender].deposited_wei_amount.mul(10)))) {
            
		uint256 redeemValueLast = accounts[msg.sender].deposited_wei_amount.mul(10) - accounts[msg.sender].temp_payouts_value;

        require(totalContractBalance > redeemValueLast, "insufficient balance.");

        totalPayouts += redeemValueLast;
        accounts[msg.sender].total_payouts++;
        totalContractBalance -= redeemValueLast;
		totalLiquidity += onePercent(redeemValueLast).mul(10);

        msg.sender.transfer(onePercent(redeemValueLast).mul(90));
		liquidity.transfer(onePercent(redeemValueLast).mul(10));
        emit etherTransferred(msg.sender, redeemValueLast);
        
		accounts[msg.sender].balance = 0;
        accounts[msg.sender].deposit_time = 0;
        accounts[msg.sender].deposited_wei_amount = 0;
        accounts[msg.sender].temp_payouts_value = 0;
        accounts[msg.sender].redeemed_time = 0;
						
        } else {
		
		accounts[msg.sender].redeemed_time = now;
		
		uint256 redeemValueCurrent = ((onePercent(accounts[msg.sender].deposited_wei_amount).div(1000)) * redeemValue) + accounts[msg.sender].balance;

        require(totalContractBalance > redeemValueCurrent, "insufficient balance.");

        totalPayouts += redeemValueCurrent;

        accounts[msg.sender].total_payouts++;
        
        accounts[msg.sender].temp_payouts_value += redeemValueCurrent;

        totalContractBalance -= redeemValueCurrent;
		
		totalLiquidity += onePercent(redeemValueCurrent).mul(10);

        msg.sender.transfer(onePercent(redeemValueCurrent).mul(90));
		liquidity.transfer(onePercent(redeemValueCurrent).mul(10));
        emit etherTransferred(msg.sender, redeemValueCurrent);
        
		accounts[msg.sender].balance = 0;
        }
    }
	
	function playerReferrals(address _beneficiary) view external returns(uint256[] memory ref_count, uint256[] memory ref_earnings){
        uint256[] memory _ref_count = new uint256[](3);
        uint256[] memory _ref_earnings = new uint256[](3);
        Account storage pl = accounts[_beneficiary];

        for(uint8 i = 0; i < 3; i++){
            _ref_count[i] = pl.referrals_per_level[i];
            _ref_earnings[i] = pl.payouts_per_level[i];
        }

        return (_ref_count, _ref_earnings);
    }

    function onePercent(uint256 amount) internal view returns (uint256){
        uint256 roundValue = amount.ceil(extras);
        uint onePercentofTokens = roundValue.mul(extras).div(extras * 10**uint(2));
        return onePercentofTokens;
    }

}