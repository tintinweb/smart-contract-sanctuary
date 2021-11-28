/**
 *Submitted for verification at BscScan.com on 2021-11-28
*/

pragma solidity ^0.4.26;

contract ERC20 {

	function totalSupply() public constant returns (uint);

	function balanceOf(address tokenOwner) public constant returns (uint balance);

	function allowance(address tokenOwner, address spender) public constant returns (uint remaining);

	function transfer(address to, uint tokens) public returns (bool success);

	function approve(address spender, uint tokens) public returns (bool success);

	function transferFrom(address from, address to, uint tokens) public returns (bool success);

	event Transfer(address indexed from, address indexed to, uint tokens);
	event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}

contract Context {
	// Empty internal constructor, to prevent people from mistakenly deploying
	// an instance of this contract, which should be used via inheritance.
	constructor () internal { }

	function _msgSender() internal view returns (address) {
		return msg.sender;
	}

	function _msgData() internal view returns (bytes memory) {
		this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
		return msg.data;
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

contract FarmTreeTransferable is Context {
	using SafeMath for uint256;

	mapping(address => uint256) public userTrees;
	mapping (address => mapping (address => uint256)) internal _treesAllowances;

	event TransferTrees(address indexed from, address indexed to, uint256 value);
	event ApprovalTrees(address indexed owner, address indexed spender, uint256 value);

	function treesAllowance(address owner, address spender) external view returns (uint256) {
		return _treesAllowances[owner][spender];
	}

	function approveTrees(address spender, uint256 amount) external returns (bool) {
		_approveTrees(_msgSender(), spender, amount);
		return true;
	}

	function increaseTreesAllowance(address spender, uint256 addedValue) public returns (bool) {
		_approveTrees(_msgSender(), spender, _treesAllowances[_msgSender()][spender].add(addedValue));
		return true;
	}

	function decreaseTreesAllowance(address spender, uint256 subtractedValue) public returns (bool) {
		_approveTrees(_msgSender(), spender, _treesAllowances[_msgSender()][spender].sub(subtractedValue, "Trees: decreased allowance below zero"));
		return true;
	}

	function _transferTrees(address sender, address recipient, uint256 amount) internal {
		require(sender != address(0), "Trees: transfer from the zero address");
		require(recipient != address(0), "Trees: transfer to the zero address");

		userTrees[sender] = userTrees[sender].sub(amount, "Trees: transfer amount exceeds balance");
		userTrees[recipient] = userTrees[recipient].add(amount);
		emit TransferTrees(sender, recipient, amount);
	}

	function _approveTrees(address owner, address spender, uint256 amount) internal {
		require(owner != address(0), "Trees: approve from the zero address");
		require(spender != address(0), "Trees: approve to the zero address");

		_treesAllowances[owner][spender] = amount;
		emit ApprovalTrees(owner, spender, amount);
	}

}

contract AdaAppleFarm is FarmTreeTransferable {

	address public weth;
	uint256 public APPLES_TO_TREES = 864000;
	uint256 public APPLE_RIPEN_TIME_SEC = 86400;
	uint256 PSN = 10000;
	uint256 PSNH = 5000;
	uint public version = 1;

	bool public initialized = false;

	address private _owner;
	address public ceoAddress;
	address public marketingAddress;

	mapping(address => uint256) public userApples;
	mapping(address => uint256) public lastHarvestTs;
	mapping(address => address) public referrals;
	mapping(address => uint256) private _totalReferralApples;
	mapping(address => uint256) private _userTotalWethDeposit;
	mapping(address => uint256) private _userTotalWethWithdraw;

	uint256 public marketApples;

	constructor(address weth_, address ceoAddress_, address marketingAddress_) public {
		weth = weth_;
		address msgSender = _msgSender();
		_owner = msgSender;
		ceoAddress = ceoAddress_;
		marketingAddress = marketingAddress_;
	}

	function plantApplesToTrees(address ref) public {
		require(initialized);
		if (referrals[msg.sender] == address(0)) {
			if (ref == msg.sender || ref == 0) {
				ref = marketingAddress;
			}
			referrals[msg.sender] = ref;
		}

		uint256 allUserApples = getMyApples();
		uint256 newTrees = SafeMath.div(allUserApples, APPLES_TO_TREES);
		userTrees[msg.sender] = SafeMath.add(userTrees[msg.sender], newTrees);
		userApples[msg.sender] = 0;
		lastHarvestTs[msg.sender] = now;

		uint256 referralAppleAmount = SafeMath.div(allUserApples, 10);

		userApples[referrals[msg.sender]] = SafeMath.add(userApples[referrals[msg.sender]], referralAppleAmount);
		_totalReferralApples[referrals[msg.sender]] = SafeMath.add(_totalReferralApples[referrals[msg.sender]], referralAppleAmount);

		marketApples = SafeMath.add(marketApples, SafeMath.div(allUserApples, 5));
	}

	function sellApples() public {
		require(initialized);
		uint256 hasProducts = getMyApples();
		uint256 wethAmountOut = calculateApplesSell(hasProducts);
		uint256 feeWeth = devFee(wethAmountOut);
		userApples[msg.sender] = 0;
		lastHarvestTs[msg.sender] = now;
		marketApples = SafeMath.add(marketApples, hasProducts);

		ERC20(weth).transfer(ceoAddress, feeWeth);

		uint256 wethAmountOutAfterFee = SafeMath.sub(wethAmountOut, feeWeth);
		_userTotalWethWithdraw[msg.sender] = SafeMath.add(_userTotalWethWithdraw[msg.sender], wethAmountOutAfterFee);
		ERC20(weth).transfer(address(msg.sender), wethAmountOutAfterFee);
	}

	function buyTrees(address ref, uint256 amount) public {
		require(initialized);

		require(ERC20(weth).transferFrom(address(msg.sender), address(this), amount), 'AdaAppleFarm: TRANSFER_FROM_FAILED');

		uint256 balance = ERC20(weth).balanceOf(address(this));
		uint256 productsBought = calculateApplesBuy(amount, SafeMath.sub(balance, amount));
		uint256 productsDevFee = devFee(productsBought);
		productsBought = SafeMath.sub(productsBought, productsDevFee);
		uint256 fee = devFee(amount);
		ERC20(weth).transfer(ceoAddress, fee);

		userApples[msg.sender] = SafeMath.add(userApples[msg.sender], productsBought);
		_userTotalWethDeposit[msg.sender] = SafeMath.add(_userTotalWethDeposit[msg.sender], amount);
		plantApplesToTrees(ref);
	}

	function calculateTrade(uint256 rt, uint256 rs, uint256 bs) public view returns (uint256) {
		return SafeMath.div(SafeMath.mul(PSN, bs), SafeMath.add(PSNH, SafeMath.div(SafeMath.add(SafeMath.mul(PSN, rs), SafeMath.mul(PSNH, rt)), rt)));
	}

	function calculateApplesSell(uint256 amount) public view returns (uint256) {
		return calculateTrade(amount, marketApples, ERC20(weth).balanceOf(address(this)));
	}

	function calculateApplesBuy(uint256 eth, uint256 contractBalance) public view returns (uint256) {
		return calculateTrade(eth, contractBalance, marketApples);
	}

	function calculateApplesBuySimple(uint256 eth) public view returns (uint256){
		return calculateApplesBuy(eth, ERC20(weth).balanceOf(address(this)));
	}

	function devFee(uint256 amount) public pure returns (uint256){
		return SafeMath.div(SafeMath.mul(amount, 4), 100);
	}

	function seedGarden(uint256 amount) public {
		require(_owner == _msgSender(), "Ownable: caller is not the owner");
		require(marketApples == 0);
		if (amount > 0) {
			ERC20(weth).transferFrom(address(msg.sender), address(this), amount);
		}
		initialized = true;
		marketApples = 86400000000;
	}

	function getBalance() public view returns (uint256) {
		return ERC20(weth).balanceOf(address(this));
	}

	function balanceOf(address account) external view returns (uint256) {
		return userTrees[account];
	}

	function getMyTrees() public view returns (uint256) {
		return userTrees[msg.sender];
	}

	function getMyApples() public view returns (uint256) {
		return SafeMath.add(userApples[msg.sender], getApplesSinceLastFetch(msg.sender));
	}

	function getMyReferralApples() public view returns (uint256) {
		return _totalReferralApples[msg.sender];
	}

	function getMyDeposit() public view returns (uint256) {
		return _userTotalWethDeposit[msg.sender];
	}

	function getMyWithdraw() public view returns (uint256) {
		return _userTotalWethWithdraw[msg.sender];
	}

	function getEarnedReferralApples() public view returns (uint256) {
		return _totalReferralApples[msg.sender];
	}

	function getApplesSinceLastFetch(address adr) public view returns (uint256) {
		uint256 secondsPassed = min(APPLE_RIPEN_TIME_SEC, SafeMath.sub(now, lastHarvestTs[adr]));
		return SafeMath.mul(secondsPassed, userTrees[adr]);
	}

	function getHarvestStatus(address addr) public view returns (uint256 nowTsSec, uint256 lastHarvestTsSec, uint256 nowUserApples) {
		nowTsSec = now;
		lastHarvestTsSec = lastHarvestTs[addr];
		nowUserApples = SafeMath.add(userApples[addr], getApplesSinceLastFetch(addr));
	}

	function min(uint256 a, uint256 b) private pure returns (uint256) {
		return a < b ? a : b;
	}

	function transferTrees(address recipient, uint256 amount) external returns (bool) {
		_harvestApples(_msgSender());
		_harvestApples(recipient);
		_transferTrees(_msgSender(), recipient, amount);
		return true;
	}

	function transferTreesFrom(address sender, address recipient, uint256 amount) external returns (bool) {
		_harvestApples(sender);
		_harvestApples(recipient);
		_transferTrees(sender, recipient, amount);
		_approveTrees(sender, _msgSender(), _treesAllowances[sender][_msgSender()].sub(amount, "Trees: transfer amount exceeds allowance"));
		return true;
	}

	function _harvestApples(address user) private {
		userApples[user] = SafeMath.add(userApples[user], getApplesSinceLastFetch(user));
		lastHarvestTs[user] = now;
	}
}