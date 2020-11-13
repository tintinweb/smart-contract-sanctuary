pragma solidity 0.7.0;

// SafeMath library provided by the OpenZeppelin Group on Github
// SPDX-License-Identifier: MIT

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

/* ERC20 Standards followed by OpenZeppelin Group libraries on Github */

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    
    function balanceOf(address who) external view returns (uint256);
    
    function allowance(address owner, address spender) external view returns (uint256);
    
    function transfer(address to, uint256 value) external returns (bool);
    
    function approve(address spender, uint256 value) external returns (bool);
    
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/* Staking process is followed according to the ERC900: Simple Staking Interface #900 issue on Github */

interface Staking {
    
    event Staked(address indexed user, uint256 amount, uint256 total, bytes data);
    
    event Unstaked(address indexed user, uint256 amount, uint256 total, bytes data);

    function stake(uint256 amount, bytes memory data) external returns (bool);
    
    function unstake(uint256 amount, bytes memory data) external returns (bool);
    
    function totalStakedFor(address addr) external view returns (uint256);
    
    function totalStaked() external view returns (uint256);
    
    function supportsHistory() external pure returns (bool);

}

/*PARAMORE Protocol being created with the help of the above interfaces for compatibility*/

contract PARAMORE is IERC20, Staking {
    
    /* Constant variables created for the ERC20 requirements*/
    
    string public constant name = "PARAMORE";
    string public constant symbol = "PARA";
    uint8 public constant decimals = 18;
    
    //Burn address saved as constant for future burning processes
    address public constant burnaddress = 0x0000000000000000000000000000000000000000;

    mapping(address => uint256) balances; //PARA balance for all network participants
    
    mapping(address => uint256) stakedbalances; //PARA stake balance to lock stakes
    
    mapping(address => uint) staketimestamps; //PARA stake timestamp to record updates on staking for multipliers, this involves the idea that multipliers will reset upon staking

    mapping(address => mapping (address => uint256)) allowed; //Approval array to record delegation of thrid-party accounts to handle transaction per allowance
    
    /* Total variables created to record information */
    uint256 totalSupply_;
    uint256 totalstaked = 0;
    address theowner; //Owner address saved to recognise on future processes
    
    using SafeMath for uint256; //Important*** as this library provides security to handle maths without overflow attacks
    
    constructor() public {
        totalSupply_ = 1000000000000000000000000;
        balances[msg.sender] = totalSupply_;
        theowner = msg.sender;
        emit Transfer(msg.sender, msg.sender, totalSupply_);
   } //Constructor stating the total supply as well as saving owner address and sending supply to owner address
   
   //Function to report on totalsupply following ERC20 Standard
   function totalSupply() public override view returns (uint256) {
       return totalSupply_;
   }
   
   //Function to report on account balance following ERC20 Standard
   function balanceOf(address tokenOwner) public override view returns (uint) {
       return balances[tokenOwner];
   }
   
   //Burn process is just a funtion to calculate burn amount depending on an amount of Tokens
   function cutForBurn(uint256 a) public pure returns (uint256) {
       uint256 c = a.div(20);
       return c;
   }
   
   //Straight forward transfer following ERC20 Standard
   function transfer(address receiver, uint256 numTokens) public override returns (bool) {
       require(numTokens <= balances[msg.sender], 'Amount exceeds balance.');
       balances[msg.sender] = balances[msg.sender].sub(numTokens);
       
       balances[receiver] = balances[receiver].add(numTokens);
       emit Transfer(msg.sender, receiver, numTokens);
       return true;
   }
   
   //Approve function following ERC20 Standard
   function approve(address delegate, uint256 numTokens) public override returns (bool) {
       require(numTokens <= balances[msg.sender], 'Amount exceeds balance.');
       allowed[msg.sender][delegate] = numTokens;
       emit Approval(msg.sender, delegate, numTokens);
       return true;
   }
   
   //Allowance function to verify allowance allowed on delegate address following ERC20 Standard
   function allowance(address owner, address delegate) public override view returns (uint) {
       return allowed[owner][delegate];
   }
   
   //The following function is added to mitigate ERC20 API: An Attack Vector on Approve/TransferFrom Methods
   function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
       require(addedValue <= balances[msg.sender].sub(allowed[msg.sender][spender]), 'Amount exceeds balance.');
       
       allowed[msg.sender][spender] = allowed[msg.sender][spender].add(addedValue);
       
       emit Approval(msg.sender, spender, allowed[msg.sender][spender].add(addedValue));
       return true;
   }
   
   //The following function is added to mitigate ERC20 API: An Attack Vector on Approve/TransferFrom Methods
   function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
       require(subtractedValue <= allowed[msg.sender][spender], 'Amount exceeds balance.');
       
       allowed[msg.sender][spender] = allowed[msg.sender][spender].sub(subtractedValue);
       
       emit Approval(msg.sender, spender, allowed[msg.sender][spender].sub(subtractedValue));
   }
   
   //Transfer For function for allowed accounts to allow tranfers
   function transferFrom(address owner, address buyer, uint numTokens) public override returns (bool) {
       require(numTokens <= balances[owner], 'Amount exceeds balance.');
       require(numTokens <= allowed[owner][msg.sender], 'Amount exceeds allowance.');
       
       balances[owner] = balances[owner].sub(numTokens);
       allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
       balances[buyer] = balances[buyer].add(numTokens);
       return true;
   }
   
   //Staking processes
   
   //Stake process created updating balances, stakebalances and also recording time on process run, the process will burn 5% of the amount
   function stake(uint256 amount, bytes memory data) public override returns (bool) {
       require(amount <= balances[msg.sender]);
       require(amount < 20, "Amount to low to process");
       balances[msg.sender] = balances[msg.sender].sub(amount);
       
       uint256 burned = cutForBurn(amount);
       
       totalSupply_ = totalSupply_.sub(burned);
       
       balances[burnaddress] = balances[burnaddress].add(burned);
       
       stakedbalances[msg.sender] = stakedbalances[msg.sender].add(amount.sub(burned));
       totalstaked = totalstaked.add(amount.sub(burned));
       
       staketimestamps[msg.sender] = block.timestamp;
       
       emit Staked(msg.sender, amount.sub(burned), stakedbalances[msg.sender], data);
       emit Transfer(msg.sender, msg.sender, amount.sub(burned));
       emit Transfer(msg.sender, burnaddress, burned);
       return true;
   }
   
   //This function unstakes locked in amount and burns 5%, this also updates amounts on total supply
   function unstake(uint256 amount, bytes memory data) public override returns (bool) {
       require(amount <= stakedbalances[msg.sender]);
       require(amount <= totalstaked);
       require(amount < 20, "Amount to low to process");
       stakedbalances[msg.sender] = stakedbalances[msg.sender].sub(amount);
       totalstaked = totalstaked.sub(amount);
       
       uint256 burned = cutForBurn(amount);
       
       totalSupply_ = totalSupply_.sub(burned);
       
       balances[burnaddress] = balances[burnaddress].add(burned);
       
       balances[msg.sender] = balances[msg.sender].add(amount.sub(burned));
       
       emit Unstaked(msg.sender, amount.sub(burned), stakedbalances[msg.sender], data);
       emit Transfer(msg.sender, msg.sender, amount.sub(burned));
       emit Transfer(msg.sender, burnaddress, burned);
       return true;
   }
   
   //Function to return total staked on a single address
   function totalStakedFor(address addr) public override view returns (uint256) {
       return stakedbalances[addr];
   }
   
   //Function to shows timestamp on stake processes
   function stakeTimestampFor(address addr) public view returns (uint256) {
       return staketimestamps[addr];
   }
   
   //Function to find out time passed since last timestamp on address
   function stakeTimeFor(address addr) public view returns (uint256) {
       return block.timestamp.sub(staketimestamps[addr]);
   }
   
   //Total staked on all addresses
   function totalStaked() public override view returns (uint256) {
       return totalstaked;
   }
   
   //Support History variable to show support on optional stake details
   function supportsHistory() public override pure returns (bool) {
       return false;
   }
   
}