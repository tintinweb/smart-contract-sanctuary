// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

import "./interfaces/IBEP20.sol";
import "./lib/Auth.sol";
import "./lib/Pausable.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/IRouter.sol";

contract RFT is IBEP20, Auth, Pausable {
    using SafeMath for uint;

    string constant _name = "Reflecty";
    string constant _symbol = "RFT";
    uint8 constant _decimals = 18;

    uint256 private _totalSupply = 15000000 * (10 ** _decimals);
    uint256 public _maxTxAmount = 50000 * (10 ** _decimals);

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) public hasFee;
    mapping (address => bool) public isExempt;

    uint256 public autoLiquidityFee = 2;
    uint256 public stakingFee = 3;
    uint256 public feeDenominator = 100;

    address public autoLiquidityReceiver;
    address public stakingFeeReceiver;

    IRouter public router;
    address private WBNB;
    address public liquifyPair;

    uint256 launchedAt;

    bool public liquifyEnabled = true;
    uint256 public liquifyAmount = 250 * (10 ** _decimals);
    bool private inLiquify;

    modifier liquifying() { inLiquify = true; _; inLiquify = false; }

    constructor (address _router) Auth(msg.sender) {
        router = IRouter(_router);
        WBNB = router.WETH();
        liquifyPair = IFactory(router.factory()).createPair(WBNB, address(this));

        _allowances[address(this)][_router] = 2 ** 256 - 1;
        hasFee[liquifyPair] = true;
        isExempt[msg.sender] = true;
        isExempt[address(this)] = true;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);

        (bool success, ) = payable(msg.sender).call{value: address(this).balance}("");
        if(success){
            return;
        }
    }

    receive() external payable {
        assert(msg.sender == WBNB || msg.sender == address(router));
    }

    modifier migrationProtection(address sender) {
        require(!paused || isAuthorized(sender) || isAuthorized(msg.sender), "PROTECTED"); _;
    }

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) external view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function approveMax(address spender) external returns (bool) {
        return approve(spender, 2 ** 256 - 1);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(sender, recipient, amount);
    }

    function _transferFrom(address sender, address recipient, uint256 amount) internal migrationProtection(sender) returns (bool) {
        checkTxLimit(sender, recipient, amount);

        if(sender != msg.sender && _allowances[sender][msg.sender] != 2 ** 256 - 1){
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender].sub(amount, "Insufficient Allowance");
        }

        if(launchedAt == 0 && recipient == liquifyPair){ launch(); }

        bool shouldLiquify = shouldAutoLiquify() && !(isExempt[sender] || isExempt[recipient]);
        if(shouldLiquify){ autoLiquify(); }

        _balances[sender] = _balances[sender].sub(amount, "Insufficient Balance");

        uint256 amountReceived = shouldTakeFee(sender, recipient) ? takeFee(sender, amount) : amount;

        _balances[recipient] = _balances[recipient].add(amountReceived);

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function checkTxLimit(address sender, address recipient, uint256 amount) internal view {
        require(amount <= _maxTxAmount || isExempt[sender] || isExempt[recipient], "TX Limit Exceeded");
    }

    function takeFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 liquidityFeeAmount = amount.mul(getLiquidityFee()).div(feeDenominator);
        uint256 stakingFeeAmount = amount.mul(stakingFee).div(feeDenominator);

        _balances[address(this)] = _balances[address(this)].add(liquidityFeeAmount);
        _balances[stakingFeeReceiver] = _balances[stakingFeeReceiver].add(stakingFeeAmount);

        emit Transfer(sender, address(this), liquidityFeeAmount);
        emit Transfer(sender, stakingFeeReceiver, stakingFeeAmount);

        return amount.sub(liquidityFeeAmount).sub(stakingFeeAmount);
    }

    function getLiquidityFee() internal view returns (uint256) {
        if(launchedAt + 1 >= block.number){ return feeDenominator.sub(stakingFee).sub(1); }
        return autoLiquidityFee;
    }

    function shouldAutoLiquify() internal view returns (bool) {
        return msg.sender != liquifyPair
        && !inLiquify
        && liquifyEnabled
        && _balances[address(this)] >= liquifyAmount;
    }

    function autoLiquify() internal liquifying {
        uint256 amountToSwap = liquifyAmount.div(2);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WBNB;

        uint256 balanceBefore = address(this).balance;

        try router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        ) {} catch {}

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        try router.addLiquidityETH{value: amountBNB}(
            address(this),
            amountToSwap,
            0,
            0,
            autoLiquidityReceiver,
            block.timestamp
        ) {
            emit AutoLiquify(amountBNB, amountToSwap);
        } catch {}
    }

    function launch() internal {
        launchedAt = block.number;        
    }

    function setTxLimit(uint256 amount) external authorized {
        require(amount >= _totalSupply / 1000, "Limit too low");
        _maxTxAmount = amount;
    }

    function setLiquify(bool enabled, uint256 amount) external authorized {
        require(amount <= 1000 * (10 ** _decimals));
        liquifyEnabled = enabled;
        liquifyAmount = amount;
    }

    function migrateAutoLiquidityDEX(address _router, address _liquifyPair) external authorized {
        _allowances[address(this)][address(router)] = 0;
        router = IRouter(_router);
        liquifyPair = _liquifyPair;
        hasFee[liquifyPair] = true;
        _allowances[address(this)][_router] = 2 ** 256 - 1;
    }

    function shouldTakeFee(address sender, address recipient) internal view returns (bool) {
        if(isExempt[sender] || isExempt[recipient] || inLiquify){ return false; }
        return hasFee[sender] || hasFee[recipient];
    }

    function setHasFee(address adr, bool state) external authorized {
        require(!isExempt[adr], "Is Exempt");
        hasFee[adr] = state;
    }

    function setIsExempt(address adr, bool state) external authorized {
        require(!hasFee[adr], "Has Fee");
        isExempt[adr] = state;
    }

    function setFees(uint256 _liquidityFee, uint256 _stakingFee, uint256 _feeDenominator) external authorized {
        autoLiquidityFee = _liquidityFee;
        stakingFee = _stakingFee;

        feeDenominator = _feeDenominator;

        require(autoLiquidityFee.add(stakingFee).mul(100).div(feeDenominator) <= 10, "Fee Limit Exceeded");
    }

    function setFeeReceivers(address _autoLiquidityReceiver, address _stakingFeeReceiver) external authorized {
        autoLiquidityReceiver = _autoLiquidityReceiver;
        stakingFeeReceiver = _stakingFeeReceiver;
    }

    function rescueBNB() external authorized {
        payable(msg.sender).transfer(address(this).balance);
    }

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
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
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
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
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT


pragma solidity ^0.8;

import "./Auth.sol";

abstract contract Pausable is Auth {

    bool public paused;

    constructor() {
        paused = false;
    }

    modifier notPaused {
        require(isPaused() == false || isAuthorized(msg.sender), "Contract is paused");
        _;
    }

    modifier onlyWhenPaused {
       require(isPaused() == true || isAuthorized(msg.sender), "Contract is active");
        _;
    }

    function pause() notPaused onlyOwner external {
        paused = true;
        emit Paused();
    }

    function unpause() onlyWhenPaused onlyOwner public {
        paused = false;
        emit Unpaused();
    }

    function isPaused() public view returns (bool) {
        return paused;
    }

    event Paused();
    event Unpaused();
}

// SPDX-License-Identifier: MIT


pragma solidity ^0.8;


abstract contract Auth{

    address owner;

    mapping (address => bool) private authorizations;

    constructor(address _owner){
        owner = _owner;
        authorizations[owner] = true;
    }

    modifier onlyOwner{
        require(isOwner(msg.sender), "Only owner can call this function");
        _;
    }

    modifier authorized{
        require(isAuthorized(msg.sender), "Only authorized users can call this function");
        _;
    }

    function isAuthorized(address _account) public view returns (bool){
        return authorizations[_account];
    }

    function isOwner(address account) private view returns (bool){
        return account == owner;
    }

    function authorize(address _account) external authorized{
        authorizations[_account] = true;
    }

    function revoke(address _account) external onlyOwner{
        authorizations[_account] = false;
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
    event Authorized(address adr);
    event Unauthorized(address adr);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}



interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8;

/**
 * BEP20 standard interface.
 */
interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function getOwner() external view returns (address);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}