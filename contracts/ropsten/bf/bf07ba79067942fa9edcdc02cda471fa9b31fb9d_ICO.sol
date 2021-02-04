/**
 *Submitted for verification at Etherscan.io on 2021-02-04
*/

// File: ASECTOR\SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// File: ASECTOR\ICO-V4.sol

pragma solidity 0.6.12;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    }

contract ICO {
    using SafeMath for uint256;

    address public token;
    address public owner;
    address payable public development;
    address payable public investment;
    uint256 public phaseNow;
    uint256 public vesting;
    uint256 public state;

    struct UserInfo {
        uint256 amount;
    }

    struct PhaseInfo {
        uint256 allocToken;
        uint256 totalDeposit;
        uint256 tokenPerWEI;
    }

    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
    PhaseInfo[] public phaseInfo;

    constructor(address _token, address payable _dev,address payable _invest) public {
        owner = msg.sender;
        token = _token;
        development = _dev;
        investment = _invest;
        state = 2;
        phaseInfo.push(PhaseInfo({
            allocToken: 0,
            totalDeposit: 0,
            tokenPerWEI: 0
        }));
    }

    receive() external payable {
        require(state==1,"NO:ICO");
        depositX();
    }

    modifier onlyOwner() {
        require(msg.sender==owner,"OnlyOwner");
        _;
    }

    function depositX() public payable {
        require(state==1,"NO:ICO");
        uint256 _phase = phaseNow;
        UserInfo storage user = userInfo[_phase][msg.sender];
        PhaseInfo storage phase = phaseInfo[_phase];
        user.amount = user.amount.add(msg.value);
        phase.totalDeposit = phase.totalDeposit.add(msg.value);
        
        uint256 getDev = msg.value.div(100).mul(30);
        uint256 getInvest = msg.value.div(100).mul(70);
        development.transfer(getDev);
        investment.transfer(getInvest);
    }

    function setICO() onlyOwner external returns(bool) {
        require(state==2,"ICO is ACTIVE:END First");
        phaseInfo.push(PhaseInfo({
            allocToken: 0,
            totalDeposit: 0,
            tokenPerWEI: 0
        }));

        phaseNow++;
        state = 1;
        return true;
    }

    function endICO(uint256 _allocToken) onlyOwner external returns (bool){
        require(state==1,"ICO is ENDED:ACTIVE First");
        PhaseInfo storage phase = phaseInfo[phaseNow];

        phase.allocToken = _allocToken;
        phase.tokenPerWEI = phase.allocToken.div(phase.totalDeposit);
        state = 2;
        return true;
    }

    function Claim() external returns (bool){
        for(uint i=0; i<phaseNow; i++) {
             UserInfo storage user = userInfo[i][msg.sender];
             PhaseInfo storage phase = phaseInfo[i];

             uint256 reward = phase.tokenPerWEI.mul(user.amount);
            
            if (reward > 0) {
               require(IERC20(token).transfer(msg.sender, reward),"FAILED"); 
            }
             user.amount = 0;
        }

        return true;

    }

    function ClaimX(uint256 _phase) external returns (bool){
        require(_phase < phaseNow,"Phase:NOT::END");
        UserInfo storage user = userInfo[_phase][msg.sender];
        PhaseInfo storage phase = phaseInfo[_phase];
        uint256 reward = phase.tokenPerWEI.mul(user.amount);

        if (reward > 0) {
            require(IERC20(token).transfer(msg.sender, reward),"FAILED"); 
        }
         user.amount = 0;

        return true;
    }
   
    function setAddresses(address _token,address payable _development,address payable _investment) onlyOwner external returns (bool) {
        token = _token;
        development = _development;
        investment = _investment;
        return true;
    }

    function transferAnyERC20(address _tokenAddress, address _to, uint _amount) public onlyOwner {
        IERC20(_tokenAddress).transfer(_to, _amount);
    }
}