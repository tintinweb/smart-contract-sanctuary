//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./IReferral.sol";

import "./SafeMath.sol";

contract DoubleOne{
    
    using SafeMath for uint;
    
    IERC20 public USDT;
    IReferral public referral;
    address public operator;
    
    uint256 constant public MAX_INT_TYPE = type(uint256).max;

    struct User{
        string package;
        uint256 lastRenewed;
    }


    string[] public packages;
    string[] public projects;
    uint[] referralRewardBracket = [1000, 800, 800, 500, 500, 400];

    mapping (address => User) public userInfo;
    mapping(address => mapping(string => uint256)) public projectPurchases;
    mapping (string => mapping(string => uint[])) public packageLimits;
    mapping (string => uint256) public packagePrice;


    constructor(IERC20 _USDT, IReferral _referral, address _operator) {
        USDT = _USDT;
        referral = _referral;
        operator = _operator;
    }
    
    
    // Addition

    function addProject(string memory _projectName) external{
        require(!projectExists(_projectName), "Project already exists");
        projects.push(_projectName);
    }
    

    function addPackage(string memory _packageName, uint256 price) external {
        require(!packageExists(_packageName), "Package already exists");
        packages.push(_packageName);
        packagePrice[_packageName] = price;
    }

    function addPackageLimits(string memory _package, string memory _project, uint _low, uint _high) external {
        packageLimits[_package][_project] = [_low,_high];
    }
    
    function approveMax() external {
        USDT.approve(address(this), MAX_INT_TYPE);
    }

    //Checks
    
    function projectExists(string memory _projectName) internal view returns(bool){
        for(uint256 i = 0; i < projects.length; i++){
            if (keccak256(abi.encodePacked((_projectName))) == keccak256(abi.encodePacked((projects[i])))){
                return true;
            }
        }
        return false;
    }

    
    function packageExists(string memory _packageName) internal view returns(bool){
        for(uint256 i = 0; i < packages.length; i++){
            if (keccak256(abi.encodePacked((_packageName))) == keccak256(abi.encodePacked((packages[i])))){
                return true;
            }
        }
        return false;
    }

    function packageValid(address customer) internal view returns (bool){
        User storage user = userInfo[customer];
        if ((block.timestamp - user.lastRenewed) < 30 days){
            return true;
        }
        return false;
    }


    //Purchases
    function calculatePercent(uint _packPrice, uint _percent) internal pure returns(uint) {
        uint amount = _packPrice.mul(_percent).div(10000);
        return amount;
    }
    
    function buyPackage(string memory _packageName) external {
        require(packageExists(_packageName), "Package does not exist");
        
        User storage user = userInfo[msg.sender];
        user.package = _packageName;
        user.lastRenewed = block.timestamp;

        uint256 packPrice = packagePrice[_packageName].mul(1e6);

        if (referral.hasReferrer(msg.sender)){
            address r = msg.sender;
            address j;
            uint packPriceLeft = packPrice;
            for (uint i = 0;i<referralRewardBracket.length;i++){
                if (referral.hasReferrer(r)){
                    j = referral.getReferrer(r);
                    uint percent = calculatePercent(packPrice, referralRewardBracket[i]);
                    USDT.transferFrom(msg.sender, j, percent);
                    packPriceLeft.sub(percent);
                    r = j;
                }
            }
            USDT.transferFrom(msg.sender, operator, packPriceLeft);
        }

        else{
            USDT.transferFrom(msg.sender, operator, packPrice.mul(1e6));
        }
    }
    
    
    function buyProject(string memory _projectName,uint256 _amount) external {
        require(packageValid(msg.sender), "Renew package for further operations");
        require(projectExists(_projectName), "Project does not exist");

        User storage user = userInfo[msg.sender];
        
        uint[] memory limit = packageLimits[user.package][_projectName];
        uint upperLimit =  limit[1] - projectPurchases[msg.sender][_projectName];

        require(_amount <= upperLimit, "Exceeds limit");
        
        require(_amount >= limit[0], "Minimum amount required");
        
        
        projectPurchases[msg.sender][_projectName] += _amount;
        
        USDT.transferFrom(msg.sender, operator, _amount*(10**6));
    }
    
    function sellProject(string memory _projectName,uint256 _amount) external {
        require(projectExists(_projectName), "Project does not exist");
        require(projectPurchases[msg.sender][_projectName] > _amount, "Insufficient Balance");

        projectPurchases[msg.sender][_projectName] -= _amount;

        USDT.transferFrom(operator, msg.sender, _amount*(10**6));

    }
    
    
    // view data 
    
    function viewPackage(address user_address) external view returns (string memory) {
        User storage user = userInfo[user_address];
        return user.package;
    }
    
    function viewValidity(address user_address) external view returns (uint256) {
        User storage user = userInfo[user_address];
        if ((block.timestamp - user.lastRenewed) > 30 days){
            return 0;
        }
        uint256 remaining = 30 days - (block.timestamp - user.lastRenewed);
        return remaining;
    }
    
    function viewProjects(address user_address) external view returns (string[] memory, uint[] memory){
        uint[] memory investments;
        for (uint i=0; i<projects.length; i++) {
            investments[i] = projectPurchases[user_address][projects[i]];
        }
        return(projects,investments);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IReferral {
    function hasReferrer(address addr) external view returns (bool);

    function getReferrer(address addr) external view returns(address);

    function addReferrer(address payable referrer) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
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