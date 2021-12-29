//SourceUnit: ERC20.sol

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "./SafeMath.sol";

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

//SourceUnit: IERC20.sol

pragma solidity ^0.5.0;

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


//SourceUnit: LimboStaking.sol

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0 <0.6.0;
import './StdFunctions.sol';
import "./ERC20.sol";

contract LimboStaking {
	ERC20 public token_c0_2484c9ff;
	StdFunctions stdFunctions = new StdFunctions();
	address payable public owner;

	struct Table_1 {
		uint StakeDateTime;
		uint StakedAmount;
		address Account;
		uint Counter;
	}

	Table_1[] public table_1;

	function _create_Table_1(uint _StakeDateTime, uint _StakedAmount, address _Account, uint _Counter) private {
		Table_1 memory x = Table_1(_StakeDateTime, _StakedAmount, _Account, _Counter);
		table_1.push(x); emit _Changed_table_1();
	}

	event _Changed_table_1();

	 uint public MinStakeAmount = 500000000;

	 uint public MaxStakeAmount = 25000000000;

	 uint public MinStakePeriod = 86400;

	 uint public DailyYieldPt00001Percent = 11000;

	 uint public StakesCounter = 1;

	event _Changed_StakesCounter(
		uint val
	);

	function set_StakesCounter(uint _StakesCounter) private { StakesCounter = _StakesCounter; emit _Changed_StakesCounter(StakesCounter);}

	constructor() public {
		owner = msg.sender;
		token_c0_2484c9ff = ERC20(stdFunctions.parseAddr("419b6b9d08d2f3c251d6ea6cc13827d34884770495e4ed068a"));
	}

	function formc9_d7accb25_text() public view returns (string memory){
		return stdFunctions.coverWithAppropriateDecimals(token_c0_2484c9ff.balanceOf(address(this)), 8);
	}

	function formc9_28b801b3_text() public view returns (string memory){
		return stdFunctions.coverWithAppropriateDecimals(token_c0_2484c9ff.balanceOf(msg.sender), 8);
	}

	//Withdraw Coins from Smart Contract
	function ac0_0_1_c0_1d747b47_c4_f87dad0e_start(uint _response_Store_TempValue_c4_409b6653) public {
		require((owner == msg.sender),"Only Owner can Withdraw");
		
			token_c0_2484c9ff.transfer(msg.sender, _response_Store_TempValue_c4_409b6653); emit _TokenBalanceShifted_token_c0_2484c9ff(); 
	}

	
	event _TokenBalanceShifted_token_c0_2484c9ff();

	//Transfer Coins to Smart Contract
	function ac0_0_1_c0_f737bf11_c2_a30e3648_start(uint _response_Store_TempValue_c2_c5b5dfe6) public {
		
			token_c0_2484c9ff.transferFrom(msg.sender, address(this), _response_Store_TempValue_c2_c5b5dfe6); emit _TokenBalanceShifted_token_c0_2484c9ff(); 
	}

	//Unstake
	function ac0_0_1_c30_ce9e2f23_c65_a116bfcb_start(uint _gV_c30_0536e749___c64_01e784d0) public {
		require((fc96_5a896cdf_0(_gV_c30_0536e749___c64_01e784d0) == msg.sender),"Not owner of Limbo Cash");
		require(((MinStakePeriod + fc101_ad6b310b_0_0(_gV_c30_0536e749___c64_01e784d0)) <= block.timestamp),"Before minimum stake period");
		
		ac0_0_1_c30_ce9e2f23_c65_a116bfcb(ac0_0_1_c30_ce9e2f23_c65_a116bfcb_e.z_c66_16237f19, _gV_c30_0536e749___c64_01e784d0);
	}

	
	function fc66_16237f19(uint _gV_c30_0536e749___c64_01e784d0) private view returns (uint){
		uint _selectedCounter = 0;
		Table_1[] memory _m_table = new Table_1[](table_1.length);
		for (uint _i = 0; _i < table_1.length; _i++){
			if ((_gV_c30_0536e749___c64_01e784d0 == table_1[_i].Counter)){_m_table[_i] = table_1[_i]; _selectedCounter ++;}
		}
		uint _i = 0;
		return ((_m_table[_i].StakedAmount * (864000000000 + (DailyYieldPt00001Percent * (block.timestamp - _m_table[_i].StakeDateTime)))) / 864000000000);
	}

	function n_c101_410382b5(uint _gV_c30_0536e749___c64_01e784d0) private {
		for (uint _iX = table_1.length; _iX > 0; _iX --){
			uint _i = _iX - 1;
			if ((table_1[_i].Counter == _gV_c30_0536e749___c64_01e784d0)){table_1[_i] = table_1[table_1.length-1]; table_1.pop();}
		}
		emit _Changed_table_1();
	}

	
	function fc96_5a896cdf_0(uint _gV_c30_0536e749___c64_01e784d0) private view returns (address){
		uint _selectedCounter = 0;
		Table_1[] memory _m_table = new Table_1[](table_1.length);
		for (uint _i = 0; _i < table_1.length; _i++){
			if ((table_1[_i].Counter == _gV_c30_0536e749___c64_01e784d0)){_m_table[_i] = table_1[_i]; _selectedCounter ++;}
		}
		uint _i = 0;
		return _m_table[_i].Account;
	}

	
	function fc101_ad6b310b_0_0(uint _gV_c30_0536e749___c64_01e784d0) private view returns (uint){
		uint _selectedCounter = 0;
		Table_1[] memory _m_table = new Table_1[](table_1.length);
		for (uint _i = 0; _i < table_1.length; _i++){
			if ((_gV_c30_0536e749___c64_01e784d0 == table_1[_i].Counter)){_m_table[_i] = table_1[_i]; _selectedCounter ++;}
		}
		uint _i = 0;
		return _m_table[_i].StakeDateTime;
	}

	enum ac0_0_1_c30_ce9e2f23_c65_a116bfcb_e {z_c66_16237f19, z_c101_410382b5}

	function ac0_0_1_c30_ce9e2f23_c65_a116bfcb(ac0_0_1_c30_ce9e2f23_c65_a116bfcb_e _startPoint, uint _gV_c30_0536e749___c64_01e784d0) private{
		if (_startPoint == ac0_0_1_c30_ce9e2f23_c65_a116bfcb_e.z_c66_16237f19){
			token_c0_2484c9ff.transfer(msg.sender, fc66_16237f19(_gV_c30_0536e749___c64_01e784d0)); emit _TokenBalanceShifted_token_c0_2484c9ff(); ac0_0_1_c30_ce9e2f23_c65_a116bfcb(ac0_0_1_c30_ce9e2f23_c65_a116bfcb_e.z_c101_410382b5, _gV_c30_0536e749___c64_01e784d0); 
		} else if (_startPoint == ac0_0_1_c30_ce9e2f23_c65_a116bfcb_e.z_c101_410382b5){
			n_c101_410382b5(_gV_c30_0536e749___c64_01e784d0); 
		}
	}

	function formc30_0536e749_rFormula() public view returns (uint[] memory, uint[] memory, address[] memory, uint[] memory){
		return fc30_0536e749_rFormula();
	}
	
	function fc30_0536e749_rFormula() public view returns (uint[] memory, uint[] memory, address[] memory, uint[] memory){
		uint _selectedCounter = 0;
		Table_1[] memory _m_table = new Table_1[](table_1.length);
		for (uint _i = 0; _i < table_1.length; _i++){
			if ((table_1[_i].Account == msg.sender)){_m_table[_i] = table_1[_i]; _selectedCounter ++;}
		}
		uint[] memory output_c0_f30ef006 = new uint[](_selectedCounter);
		uint[] memory output_c0_86e0d4b2 = new uint[](_selectedCounter);
		address[] memory output_c0_0f8ba5ac = new address[](_selectedCounter);
		uint[] memory output_c64_01e784d0 = new uint[](_selectedCounter);
		for (uint _i = 0; _i < _selectedCounter; _i++){
			output_c0_f30ef006[_i] = _m_table[_i].StakeDateTime;
			output_c0_86e0d4b2[_i] = _m_table[_i].StakedAmount;
			output_c0_0f8ba5ac[_i] = _m_table[_i].Account;
			output_c64_01e784d0[_i] = _m_table[_i].Counter;
		}
		return (output_c0_f30ef006, output_c0_86e0d4b2, output_c0_0f8ba5ac, output_c64_01e784d0);
	}

	function ac0_0_1_c0_e01f981f_condc0_9990858c(uint _response_Store_TempValue_c0_616ca058) public view returns (bool){
		return ((_response_Store_TempValue_c0_616ca058 + stdFunctions.sumUInt(fc0_9990858c_0_0_0())) <= MaxStakeAmount);
	}

	
	function fc0_9990858c_0_0_0() private view returns (uint[] memory){
		uint _selectedCounter = 0;
		Table_1[] memory _m_table = new Table_1[](table_1.length);
		for (uint _i = 0; _i < table_1.length; _i++){
			if ((table_1[_i].Account == msg.sender)){_m_table[_i] = table_1[_i]; _selectedCounter ++;}
		}
		uint[] memory _tableOutput = new uint[](_selectedCounter);
		for (uint _i = 0; _i < _selectedCounter; _i++){
			_tableOutput[_i] = _m_table[_i].StakedAmount;
		}
		return _tableOutput;
	}

	//Stake
	function ac0_0_1_c0_e01f981f_c1_1fab4da7_start(uint _response_Store_TempValue_c0_616ca058) public {
		require((_response_Store_TempValue_c0_616ca058 >= MinStakeAmount),"Below Min Stake amount");
		require(((_response_Store_TempValue_c0_616ca058 + stdFunctions.sumUInt(fc4_4152447d_0_0_0())) <= MaxStakeAmount),"Beyond Max Stake Amount");
		
		ac0_0_1_c0_e01f981f_c1_1fab4da7(ac0_0_1_c0_e01f981f_c1_1fab4da7_e.z_c4_57ae6b7d, _response_Store_TempValue_c0_616ca058);
	}

	
	function fc4_4152447d_0_0_0() private view returns (uint[] memory){
		uint _selectedCounter = 0;
		Table_1[] memory _m_table = new Table_1[](table_1.length);
		for (uint _i = 0; _i < table_1.length; _i++){
			if ((table_1[_i].Account == msg.sender)){_m_table[_i] = table_1[_i]; _selectedCounter ++;}
		}
		uint[] memory _tableOutput = new uint[](_selectedCounter);
		for (uint _i = 0; _i < _selectedCounter; _i++){
			_tableOutput[_i] = _m_table[_i].StakedAmount;
		}
		return _tableOutput;
	}

	enum ac0_0_1_c0_e01f981f_c1_1fab4da7_e {z_c4_57ae6b7d, z_c5_ef20f66d, z_c64_85e7ea47}

	function ac0_0_1_c0_e01f981f_c1_1fab4da7(ac0_0_1_c0_e01f981f_c1_1fab4da7_e _startPoint, uint _response_Store_TempValue_c0_616ca058) private{
		if (_startPoint == ac0_0_1_c0_e01f981f_c1_1fab4da7_e.z_c4_57ae6b7d){
			token_c0_2484c9ff.transferFrom(msg.sender, address(this), _response_Store_TempValue_c0_616ca058); emit _TokenBalanceShifted_token_c0_2484c9ff(); ac0_0_1_c0_e01f981f_c1_1fab4da7(ac0_0_1_c0_e01f981f_c1_1fab4da7_e.z_c5_ef20f66d, _response_Store_TempValue_c0_616ca058); 
		} else if (_startPoint == ac0_0_1_c0_e01f981f_c1_1fab4da7_e.z_c5_ef20f66d){
			_create_Table_1(block.timestamp, _response_Store_TempValue_c0_616ca058, msg.sender, StakesCounter); ac0_0_1_c0_e01f981f_c1_1fab4da7(ac0_0_1_c0_e01f981f_c1_1fab4da7_e.z_c64_85e7ea47, _response_Store_TempValue_c0_616ca058); 
		} else if (_startPoint == ac0_0_1_c0_e01f981f_c1_1fab4da7_e.z_c64_85e7ea47){
			set_StakesCounter((StakesCounter + 1)); 
		}
	}
}

//SourceUnit: SafeMath.sol

pragma solidity ^0.5.0;
	
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

//SourceUnit: StdFunctions.sol

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0 <0.6.0;
contract StdFunctions {

	function coverWithAppropriateDecimals(uint v, uint decimals) public pure returns (string memory) {
		uint exp = 10 ** decimals;
		string memory inte = uint2str(v / exp);
		uint deci = v % exp;
		if (deci == 0){
			return inte;
		}else{
			string memory deciString = uint2str(deci);
			uint length = numberLength(deci);
			string memory pad = "";
			for (uint i = length; i < decimals; i++){
				pad = string(abi.encodePacked(pad, "0"));
			}
			return string(abi.encodePacked(inte, ".", pad, deciString)); 
		}

	}

	function sumUInt(uint[] memory _v) public pure returns (uint){
		uint _t = 0;
		for (uint _i = 0; _i < _v.length; _i++){
			_t += _v[_i];
		}
		return _t;
	}

	function parseAddr(string memory _a) public pure returns (address _parsedAddress) {
		bytes memory tmp = bytes(_a);
		uint160 iaddr = 0;
		uint160 b1;
		uint160 b2;
		for (uint i = 2; i < 2 + 2 * 20; i += 2) {
			iaddr *= 256;
			b1 = uint160(uint8(tmp[i]));
			b2 = uint160(uint8(tmp[i + 1]));
			if ((b1 >= 97) && (b1 <= 102)) {
				b1 -= 87;
			} else if ((b1 >= 65) && (b1 <= 70)) {
				b1 -= 55;
			} else if ((b1 >= 48) && (b1 <= 57)) {
				b1 -= 48;
			}
			if ((b2 >= 97) && (b2 <= 102)) {
				b2 -= 87;
			} else if ((b2 >= 65) && (b2 <= 70)) {
				b2 -= 55;
			} else if ((b2 >= 48) && (b2 <= 57)) {
				b2 -= 48;
			}
			iaddr += (b1 * 16 + b2);
		}
		return address(iaddr);
	}

	function uint2str(uint v) public pure returns (string memory) {
		uint maxlength = 100;
		bytes memory reversed = new bytes(maxlength);
		uint i = 0;
		while (v != 0) {
			uint remainder = v % 10;
			v = v / 10;
			reversed[i++] = bytes1(uint8(48 + remainder));
		}
		bytes memory s = new bytes(i); // i + 1 is inefficient
		for (uint j = 0; j < i; j++) {
			s[j] = reversed[i - j - 1]; // to avoid the off-by-one error
		}
		string memory str = string(s);  // memory isn't implicitly convertible to storage
		return str;
	}

	function numberLength(uint _n) public pure returns (uint){
	if (_n < 10){
		return 1;
	}else if (_n < 100){
		return 2;
	}else if (_n < 1000){
		return 3;
	}else if (_n < 10000){
		return 4;
	}else if (_n < 100000){
		return 5;
	}else if (_n < 1000000){
		return 6;
	}else if (_n < 10000000){
		return 7;
	}else if (_n < 100000000){
		return 8;
	}else if (_n < 1000000000){
		return 9;
	}else if (_n < 10000000000){
		return 10;
	}else if (_n < 100000000000){
		return 11;
	}else if (_n < 1000000000000){
		return 12;
	}else if (_n < 10000000000000){
		return 13;
	}else if (_n < 100000000000000){
		return 14;
	}else if (_n < 1000000000000000){
		return 15;
	}else if (_n < 10000000000000000){
		return 16;
	}else if (_n < 100000000000000000){
		return 17;
	}else if (_n < 1000000000000000000){
		return 18;
	}else if (_n < 10000000000000000000){
		return 19;
	}else {
		return 20;
	}
}
}