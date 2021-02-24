pragma solidity ^0.5.16;

import "./SafeMath.sol";
import "./ERC20.sol";

interface IStrat {
    function invest() external; // underlying amount must be sent from vault to strat address before
    function divest(uint amount) external; // should send requested amount to vault directly, not less or more
    function calcTotalValue() external returns (uint);
    function underlying() external view returns (address);
}

// WARNING: This contract assumes synth and reserve are equally valuable and share the same decimals (e.g. Dola and Dai)
// DO NOT USE WITH USDC OR USDT
// DO NOT USE WITH NON-STANDARD ERC20 TOKENS
contract Stabilizer {
    using SafeMath for uint;

    uint public constant MAX_FEE = 1000; // 10%
    uint public constant FEE_DENOMINATOR = 10000;
    uint public buyFee;
    uint public sellFee;
    uint public supplyCap;
    uint public supply;
    ERC20 public synth;
    ERC20 public reserve;
    address public operator;
    IStrat public strat;
    address public governance;

    constructor(ERC20 synth_, ERC20 reserve_, address gov_, uint buyFee_, uint sellFee_, uint supplyCap_) public {
        require(buyFee_ <= MAX_FEE, "buyFee_ too high");
        require(sellFee_ <= MAX_FEE, "sellFee_ too high");
        synth = synth_;
        reserve = reserve_;
        governance = gov_;
        buyFee = buyFee_;
        sellFee = sellFee_;
        operator = msg.sender;
        supplyCap = supplyCap_;
    }

    modifier onlyOperator {
        require(msg.sender == operator || msg.sender == governance, "ONLY OPERATOR OR GOV");
        _;
    }

    modifier onlyGovernance {
        require(msg.sender == governance, "ONLY GOV");
        _;
    }

    function setOperator(address operator_) public {
        require(msg.sender == governance || msg.sender == operator, "ONLY GOV OR OPERATOR");
        require(operator_ != address(0), "NO ADDRESS ZERO");
        operator = operator_;
    }

    function setBuyFee(uint amount) public onlyGovernance {
        require(amount <= MAX_FEE, "amount too high");
        buyFee = amount;
    }

    function setSellFee(uint amount) public onlyGovernance {
        require(amount <= MAX_FEE, "amount too high");
        sellFee = amount;
    }
    
    function setCap(uint amount) public onlyOperator {
        supplyCap = amount;
    }

    function setGovernance(address gov_) public onlyGovernance {
        require(gov_ != address(0), "NO ADDRESS ZERO");
        governance = gov_;
    }

    function setStrat(IStrat newStrat) public onlyGovernance {
        require(newStrat.underlying() == address(reserve), "Invalid strat");
        if(address(strat) != address(0)) {
            uint prevTotalValue = strat.calcTotalValue();
            strat.divest(prevTotalValue);
        }
        reserve.transfer(address(newStrat), reserve.balanceOf(address(this)));
        newStrat.invest();
        strat = newStrat;
    }

    function removeStrat() public onlyGovernance {
        uint prevTotalValue = strat.calcTotalValue();
        strat.divest(prevTotalValue);

        strat = IStrat(address(0));
    }

    function takeProfit() public {
        uint totalReserves = getTotalReserves();
        if(totalReserves > supply) {
            uint profit = totalReserves - supply; // underflow prevented by if condition
            if(address(strat) != address(0)) {
                uint bal = reserve.balanceOf(address(this));
                if(bal < profit) {
                    strat.divest(profit - bal); // underflow prevented by if condition
                }
            }
            reserve.transfer(governance, profit);
        }
    }

    function buy(uint amount) public {
        require(supply.add(amount) <= supplyCap, "supply exceeded cap");
        if(address(strat) != address(0)) {
            reserve.transferFrom(msg.sender, address(strat), amount);
            strat.invest();
        } else {
            reserve.transferFrom(msg.sender, address(this), amount);
        }

        if(buyFee > 0) {
            uint fee = amount.mul(buyFee).div(FEE_DENOMINATOR);
            reserve.transferFrom(msg.sender, governance, fee);
            emit Buy(msg.sender, amount, amount.add(fee));
        } else {
            emit Buy(msg.sender, amount, amount);
        }

        synth.mint(msg.sender, amount);
        supply = supply.add(amount);
    }

    function sell(uint amount) public {
        synth.transferFrom(msg.sender, address(this), amount);
        synth.burn(amount);

        uint reserveBal = reserve.balanceOf(address(this));
        if(address(strat) != address(0) && reserveBal < amount) {
            strat.divest(amount - reserveBal); // underflow prevented by if condition
        }

        uint afterFee;
        if(sellFee > 0) {
            uint fee = amount.mul(sellFee).div(FEE_DENOMINATOR);
            afterFee = amount.sub(fee);
            reserve.transfer(governance, fee);
        } else {
            afterFee = amount;
        }
        
        reserve.transfer(msg.sender, afterFee);
        supply = supply.sub(amount);
        emit Sell(msg.sender, amount, afterFee);
    }

    function rescue(ERC20 token) public onlyGovernance {
        require(token != reserve, "RESERVE CANNOT BE RESCUED");
        token.transfer(governance, token.balanceOf(address(this)));
    }

    function getTotalReserves() internal returns (uint256 bal) { // new view function because strat.calcTotalValue() is not view function
        bal = reserve.balanceOf(address(this));
        if(address(strat) != address(0)) {
            bal = bal.add(strat.calcTotalValue());
        }
    }

    event Buy(address indexed user, uint purchased, uint spent);
    event Sell(address indexed user, uint sold, uint received);
}

pragma solidity ^0.5.16;

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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
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
    function add(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        uint256 c = a + b;
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
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction underflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on underflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot underflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

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
     * @dev Returns the multiplication of two unsigned integers, reverting on overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
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

pragma solidity ^0.5.16;

import "./SafeMath.sol";

contract ERC20 {
    using SafeMath for uint;

    string public name;
    string public symbol;
    uint8 public decimals;
    uint  public totalSupply;
    address public operator;
    address public pendingOperator;
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    mapping (address => bool) public minters;

    bytes32 public DOMAIN_SEPARATOR;
    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    bytes32 public constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;
    mapping(address => uint) public nonces;

    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    event AddMinter(address indexed minter);
    event RemoveMinter(address indexed minter);
    event ChangeOperator(address indexed newOperator);

    modifier onlyOperator {
        require(msg.sender == operator, "ONLY OPERATOR");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint8 decimals_) public {
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        operator = msg.sender;
        uint chainId;
        assembly {
            chainId := chainid
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                keccak256('EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)'),
                keccak256(bytes(name)),
                keccak256(bytes('1')),
                chainId,
                address(this)
            )
        );
    }

    function setPendingOperator(address newOperator_) public onlyOperator {
        pendingOperator = newOperator_;
    }

    function claimOperator() public {
        require(msg.sender == pendingOperator, "ONLY PENDING OPERATOR");
        operator = pendingOperator;
        pendingOperator = address(0);
        emit ChangeOperator(operator);
    }

    function addMinter(address minter_) public onlyOperator {
        minters[minter_] = true;
        emit AddMinter(minter_);
    }

    function removeMinter(address minter_) public onlyOperator {
        minters[minter_] = false;
        emit RemoveMinter(minter_);
    }

    function mint(address to, uint amount) public {
        require(minters[msg.sender] == true || msg.sender == operator, "ONLY MINTERS OR OPERATOR");
        _mint(to, amount);
    }

    function burn(uint amount) public {
        _burn(msg.sender, amount);
    }

    function _mint(address to, uint value) internal {
        totalSupply = totalSupply.add(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(address(0), to, value);
    }

    function _burn(address from, uint value) internal {
        balanceOf[from] = balanceOf[from].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(from, address(0), value);
    }

    function _approve(address owner, address spender, uint value) private {
        allowance[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function _transfer(address from, address to, uint value) private {
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        if (allowance[from][msg.sender] != uint(-1)) {
            allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        }
        _transfer(from, to, value);
        return true;
    }

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(deadline >= block.timestamp, 'EXPIRED');
        bytes32 digest = keccak256(
            abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, value, nonces[owner]++, deadline))
            )
        );
        address recoveredAddress = ecrecover(digest, v, r, s);
        require(recoveredAddress != address(0) && recoveredAddress == owner, 'INVALID_SIGNATURE');
        _approve(owner, spender, value);
    }
}