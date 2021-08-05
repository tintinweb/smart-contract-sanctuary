/**
 *Submitted for verification at Etherscan.io on 2020-11-27
*/

// Dependency file: contracts/libraries/SafeMath.sol

// SPDX-License-Identifier: MIT

// pragma solidity >=0.6.0;

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

// Dependency file: contracts/modules/Configable.sol

// pragma solidity >=0.5.16;
pragma experimental ABIEncoderV2;

interface IConfig {
    function developer() external view returns (address);
    function platform() external view returns (address);
    function factory() external view returns (address);
    function mint() external view returns (address);
    function token() external view returns (address);
    function developPercent() external view returns (uint);
    function share() external view returns (address);
    function base() external view returns (address); 
    function governor() external view returns (address);
    function getPoolValue(address pool, bytes32 key) external view returns (uint);
    function getValue(bytes32 key) external view returns(uint);
    function getParams(bytes32 key) external view returns(uint, uint, uint, uint); 
    function getPoolParams(address pool, bytes32 key) external view returns(uint, uint, uint, uint); 
    function wallets(bytes32 key) external view returns(address);
    function setValue(bytes32 key, uint value) external;
    function setPoolValue(address pool, bytes32 key, uint value) external;
    function setParams(bytes32 _key, uint _min, uint _max, uint _span, uint _value) external;
    function setPoolParams(bytes32 _key, uint _min, uint _max, uint _span, uint _value) external;
    function initPoolParams(address _pool) external;
    function isMintToken(address _token) external returns (bool);
    function prices(address _token) external returns (uint);
    function convertTokenAmount(address _fromToken, address _toToken, uint _fromAmount) external view returns (uint);
    function DAY() external view returns (uint);
    function WETH() external view returns (address);
}

contract Configable {
    address public config;
    address public owner;

    event OwnerChanged(address indexed _oldOwner, address indexed _newOwner);

    constructor() public {
        owner = msg.sender;
    }
    
    function setupConfig(address _config) external onlyOwner {
        config = _config;
        owner = IConfig(config).developer();
    }

    modifier onlyOwner() {
        require(msg.sender == owner, 'OWNER FORBIDDEN');
        _;
    }
    
    modifier onlyDeveloper() {
        require(msg.sender == IConfig(config).developer(), 'DEVELOPER FORBIDDEN');
        _;
    }
    
    modifier onlyPlatform() {
        require(msg.sender == IConfig(config).platform(), 'PLATFORM FORBIDDEN');
        _;
    }

    modifier onlyFactory() {
        require(msg.sender == IConfig(config).factory(), 'FACTORY FORBIDDEN');
        _;
    }

    modifier onlyGovernor() {
        require(msg.sender == IConfig(config).governor(), 'Governor FORBIDDEN');
        _;
    }
}

// Root file: contracts/AAAAToken.sol

pragma solidity >=0.5.16;
// import "contracts/libraries/SafeMath.sol";
// import "contracts/modules/Configable.sol";

contract AAAAToken is Configable {
    using SafeMath for uint;      
    
    // implementation of ERC20 interfaces.
    string public name = "AAAA Token";
    string public symbol = "AAAA";
    uint8 public decimals = 18;
    uint public totalSupply = 10240000 * (1e18);
    
    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;
    
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    
    constructor() public {
        balanceOf[msg.sender] = totalSupply;
    }
    
    function _transfer(address from, address to, uint value) internal {
        require(balanceOf[from] >= value, 'AAAA: INSUFFICIENT_BALANCE');
        balanceOf[from] = balanceOf[from].sub(value);
        balanceOf[to] = balanceOf[to].add(value);
        if (to == address(0)) { // burn
            totalSupply = totalSupply.sub(value);
        }
        emit Transfer(from, to, value);
    }

    function approve(address spender, uint value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transfer(address to, uint value) external returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(address from, address to, uint value) external returns (bool) {
        require(allowance[from][msg.sender] >= value, 'AAAA: INSUFFICIENT_ALLOWANCE');
        allowance[from][msg.sender] = allowance[from][msg.sender].sub(value);
        _transfer(from, to, value);
        return true;
    }
    
}