/**
 *Submitted for verification at Etherscan.io on 2021-02-07
*/

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

pragma solidity 0.6.12;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    }

contract SECICO {
    using SafeMath for uint256;

    address public token;
    address public owner;
    mapping(address => bool) owners;
    address payable public development;
    address payable public investment;
    uint256 public phaseNow;
    uint256 public lastPhase;
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
        owners[msg.sender] = true;
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

    event Deposit(uint256);
    event NewICO(uint256,uint256);
    event ICOEnded(uint256,uint256,uint256);
    event Claimed(uint256);
    event NewAddressSet(address,address,address);    

    /**
     * @dev Fallback function receives ether and calls depositX
     */
    receive() external payable {
        require(state==1,"NO:ICO");
        depositX();
    }

    /**
     * @dev Modifier for onlyOwner
     */    
    modifier onlyOwner() {
        require(owners[msg.sender]==true,"OnlyOwner");
        _;
    }

    /**
     * @dev Adds additional owners, must be owner.
     */    
    function addOwner(address _add) external returns(bool) {
        require(msg.sender==owner,"NOT::Owner");
        owners[_add] = true;
        return true;
    }

    /**
     * @dev Removes additional owners, must be owner.
     */    
    function removeOwner(address _take) external returns(bool) {
        require(msg.sender==owner,"NOT::Owner");
        owners[_take] = false;
        return true;
    }

    /**
     * @dev Deposits ether to ICO
     * there must be an ongoing ICO, (state==1)
     * splits ether at 70/30 to development and investment wallet.
     */
    function depositX() public payable returns(bool) {
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

        emit Deposit(msg.value);
        return true;
    }
    
    /**
     * @dev Starts a new ICO
     * there must be no ICO running, or if there is any
     * that needs to be ended first, (endICO).
     */
    function setICO() onlyOwner external returns(bool) {
        require(state==2,"ICO is ACTIVE:END First");
        phaseInfo.push(PhaseInfo({
            allocToken: 0,
            totalDeposit: 0,
            tokenPerWEI: 0
        }));

        phaseNow++;
        state = 1;

        emit NewICO(block.timestamp,phaseNow);
        return true;
    }

    /**
     * @dev Ends an existing ICO
     * there must an ICO already running,
     * Send the corresponding token to contract
     * @param _allocToken Number of tokens * 10 ** 18
     */
    function endICO(uint256 _allocToken) onlyOwner external returns (bool){
        require(state==1,"ICO is ENDED:ACTIVE First");
        PhaseInfo storage phase = phaseInfo[phaseNow];

        phase.allocToken = _allocToken;
        phase.tokenPerWEI = phase.allocToken.div(phase.totalDeposit);
        state = 2;
        lastPhase = phaseNow;

        emit ICOEnded(_allocToken,phase.tokenPerWEI,lastPhase);
        return true;
    }

    /**
     * @dev Batch Claims previously ended ICO rewards.
     * the currently running ICO must be ended before,
     * being able to Claim that reward.
     */
    function Claim() external returns (bool){
        uint256 rewardSum;
        for(uint i=0; i<=lastPhase; i++) {
            UserInfo storage user = userInfo[i][msg.sender];
            PhaseInfo storage phase = phaseInfo[i];

            uint256 reward = phase.tokenPerWEI.mul(user.amount);

            user.amount = 0;     
            if (reward > 0) {
               require(IERC20(token).transfer(msg.sender, reward),"FAILED"); 
               rewardSum = rewardSum.add(reward);
            }
             
        }

        emit Claimed(rewardSum);
        return true;
    }

    /**
     * @dev view function to get the number of Batch Claimable tokens
     */
    function getClaim() external view returns (uint256) {
        uint256 rewardSum;
        for(uint i=0; i<=lastPhase; i++) {
            UserInfo storage user = userInfo[i][msg.sender];
            PhaseInfo storage phase = phaseInfo[i];
            uint256 reward = phase.tokenPerWEI.mul(user.amount);

            if (reward > 0) {
               rewardSum = rewardSum.add(reward);
            }
             
        }

        return rewardSum;
    }

    /**
     * @dev Claims previously ended specified phase reward.
     * @param _phase Corresponding phase number, cannot be greater than currnet phase
     */
    function ClaimX(uint256 _phase) external returns(bool) {
        require(_phase <= lastPhase,"Phase:NOT::END");
        UserInfo storage user = userInfo[_phase][msg.sender];
        PhaseInfo storage phase = phaseInfo[_phase];
        uint256 reward = phase.tokenPerWEI.mul(user.amount);

        if (reward > 0) {
            require(IERC20(token).transfer(msg.sender, reward),"FAILED"); 
        }
        user.amount = 0;

        emit Claimed(reward);
        return true;
    }

    /**
     * @dev view function to get the number of specified phase's Claimable tokens
     */
    function getClaimX(uint256 _phase) external view returns(uint256) {
        require(_phase <= lastPhase,"Phase:NOT::END");
        UserInfo storage user = userInfo[_phase][msg.sender];
        PhaseInfo storage phase = phaseInfo[_phase];
        uint256 reward = phase.tokenPerWEI.mul(user.amount);

        return reward;
    }

    /**
     * @dev Sets Addresses for SECToken, development and investment wallet
     * @param _token ERC20 SECToken address
     * @param _development Development Wallet address
     * @param _investment Interested Wallet address
     */   
    function setAddresses(address _token,address payable _development,address payable _investment) onlyOwner external returns (bool) {
        token = _token;
        development = _development;
        investment = _investment;

        emit NewAddressSet(_token, _development, _investment);
        return true;
    }

    function transferAnyERC20(address _tokenAddress, address _to, uint _amount) public onlyOwner {
        IERC20(_tokenAddress).transfer(_to, _amount);
    }
}