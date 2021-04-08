/**
 *Submitted for verification at Etherscan.io on 2021-04-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.7.5;


// ----------------------------------------------------------------------------
// SafeMath library
// ----------------------------------------------------------------------------


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
    
    function ceil(uint a, uint m) internal pure returns (uint r) {
        return (a + m - 1) / m * m;
    }
}

// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address payable public owner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != address(0), "ERC20: sending to the zero address");
        owner = _newOwner;
        emit OwnershipTransferred(msg.sender, _newOwner);
    }
}

// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// ----------------------------------------------------------------------------
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) external view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) external returns (bool success);
    function approve(address spender, uint256 tokens) external returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) external returns (bool success);
    function burnTokens(uint256 _amount) external;
    
    function calculateFeesBeforeSend(
        address sender,
        address recipient,
        uint256 amount
    ) external view returns (uint256, uint256);
    
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}


interface stakeContract {
    function DisributeTxFunds() external;
    function ADDFUNDS(uint256 tokens) external;
}

contract FeeDistributor is Owned {
    using SafeMath for uint256;
    
    address public fBNB   = 0x87b1AccE6a1958E522233A737313C086551a5c76;
    address public dev   = 0x94D4Ac11689C6EbbA91cDC1430fc7dfa9a858753;
    bool public perform = false;

    stakeContract stakingContract; //FEG staking contract address
    stakeContract LPstakingContract; //FEG LP staking contract address
    
    fallback() external payable {
        owner.transfer(msg.value);
    }
    
    receive() external payable{  owner.transfer(msg.value); }

    constructor(stakeContract _stakingContract, stakeContract _lpStakingContract) {
        owner = msg.sender;
        stakingContract     = _stakingContract;
        LPstakingContract   = _lpStakingContract;
    }
    
    function changeStakingContract(stakeContract _stakingContract) external onlyOwner{
        require(address(_stakingContract) != address(0), "setting 0 to contract");
        stakingContract = _stakingContract;
    }
    
    function changeLPStakingContract(stakeContract _lpStakingContract) external onlyOwner{
        require(address(_lpStakingContract) != address(0), "setting 0 to contract");
        LPstakingContract = _lpStakingContract;
    }

    function changedev(address _DEV) external onlyOwner{
        dev = _DEV;
    }
    
    function changePerform(bool _bool) external onlyOwner{
        perform = _bool;
    }


    function distributeAll() public{
        
        uint256 amount = IERC20(fBNB).balanceOf(address(this)).mul(uint256(999)).div(1000);
        uint256 amountForToken  = (onePercent(amount).mul(uint256(480))).div(10); 
        require(IERC20(fBNB).transfer( address(stakingContract), amountForToken), "Tokens cannot be transferred from funder account");
        stakingContract.ADDFUNDS(amountForToken);
        
         uint256 amountForLP     = (onePercent(amount).mul(uint256(320))).div(10);
        require(IERC20(fBNB).transfer( address(LPstakingContract), amountForLP), "Tokens cannot be transferred from funder account");
        if(perform==true) {
        LPstakingContract.ADDFUNDS(amountForLP);}        
        
         uint256 amountFinal     = amount.sub(amountForToken.add(amountForLP));
        require(IERC20(fBNB).transfer( address(dev), amountFinal), "Tokens cannot be transferred from funder account");
    }

    
    // ------------------------------------------------------------------------
    // Private function to calculate 1% percentage
    // ------------------------------------------------------------------------
    function onePercent(uint256 _tokens) private pure returns (uint256){
        uint256 roundValue = _tokens.ceil(100);
        uint onePercentofTokens = roundValue.mul(100).div(100 * 10**uint(2));
        return onePercentofTokens;
    }
    
    
    
}