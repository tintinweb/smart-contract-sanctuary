/**
 *Submitted for verification at Etherscan.io on 2021-05-17
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-21
*/

/**
 *Submitted for verification at BscScan.com on 2021-03-11
*/

// SPDX-License-Identifier: GNU GPLv3
pragma solidity ^0.7.6;
contract WCHToken {
    using SafeMath for uint256;
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 tokens
    );
     
    event Burned(
        address indexed _idToDistribute,
        address indexed referrer,
        uint256 burnedAmountToken,
        uint256 percentageBurned,
        uint256 level
        );
       
    event Reward(
       address indexed from,
       address indexed to,
       uint256 rewardAmount,
       uint256 holdingUsdValue,
       uint256 level
    );
    
    event Bonus(
       address indexed buyer,
       uint256 bounusQty,
       uint256 buyingQty,
       uint256 totalBonus
    );
    
    event DestroyedBlackFunds(address _blackListedUser, uint _balance);
    event Approval(address indexed owner, address indexed spender, uint value);

     
    /* Token Basic Details */
    string public tokenName = "WCH Token";
    string public tokenSymbol = "WCH";
    uint8 public decimal = 9;
    uint256 public totalSupply = 1000000000000000 * 10**9;
    uint256 public preSaleLimit = 100000000000000 * 10**9;
    uint256 public pricePerToken = 5000000; // This is the price per token in BNB(0.0025)
   
    /* Variable Declaration */
    // uint256 public basisPointsRate = 0;
    // uint256 public maximumFee = 0;
    address payable internal owner;
    uint256 public tokenInCirculation;
    uint256 public tokenBurned;
    mapping(address => uint256) public balanceOf;
    mapping(address => address) public childParent;
    mapping(address => uint256) public userRewardsBalance;
    mapping(address => uint256) public preSaleBonus;
    mapping(address => bool) public isFirstTimeBuy;
    bool preSaleAllowed = true;
    mapping (address => address[]) public downlinks;
    mapping (address => mapping (address => uint)) public allowed;
    // uint256 holdingAmount = 0*10**6;
   
    modifier onlyOwner() {
         require(msg.sender == owner,"Only Owner Can Call This.");
         _;
     }
     
     constructor()
    {
        owner = msg.sender;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0),owner,totalSupply);
    }
   
   

    function getTotalSupply() external view returns(uint256) {
            return totalSupply;
    }
   
   

    function getParentAddress(address childAddress) external view returns(address) {
            return childParent[childAddress];
    }
   

     function getTokenInCirculation() external view returns(uint256) {
         return tokenInCirculation;
     }
     

     function getPricePerToken() external view returns(uint256) {
         return pricePerToken;
     }
     
     
    function name() external view returns(string memory) {
        return tokenName;
    }

     function symbol() external view returns(string memory) {
         return tokenSymbol;
     }


      function decimals() external view returns(uint8){
            return decimal;
      }
     

     function getTokenBalance(address tokenHolderAddress) external view returns(uint256) {
            return balanceOf[tokenHolderAddress];
     }

     function getContractAddress() external view returns(address) {
         return address(this);
     }
     
     function getPreSaleBonus(address tokenHolderAddress) external view returns(uint256) {
            return preSaleBonus[tokenHolderAddress];
     }
     
     function getUserRewardsBalance(address tokenHolderAddress) external view returns(uint256) {
            return userRewardsBalance[tokenHolderAddress];
     }
     
     function  getChild(address parent) public view returns (address[] memory) {
         return downlinks[parent];
    }
    
    function  getBurnedSupply() public view returns (uint256) {
         return tokenBurned;
    }
     
     function preSalePurchase(address _referredBy) public payable returns (bool) {
         require(msg.sender == tx.origin, "Origin and Sender Mismatched");
         require(_referredBy != msg.sender, "Self reference not allowed buy");
         //require(_referredBy != address(0), "No Referral Code buy");
         childParent[msg.sender] = _referredBy;
         if(!isFirstTimeBuy[msg.sender]){
             downlinks[_referredBy].push(msg.sender);
             isFirstTimeBuy[msg.sender] = true;
         }
         address buyer = msg.sender;
         uint256 bnbValue = msg.value;
         uint256 totalTokenValue = (bnbValue.mul(10**9)).div(pricePerToken);
         tokenInCirculation = tokenInCirculation.add(totalTokenValue);
         require(preSaleAllowed, "Pre Sale Not Allowed");
         require(totalTokenValue > 0, "Purchase more than 0");
         require(buyer != address(0), "ERC20: mint to the zero address");
         emit Transfer(address(this),buyer,totalTokenValue);
         balanceOf[buyer] += totalTokenValue;
         /*emit Transfer(address(this), buyer, taxedTokenAmount);*/
         return true;
    }
   
   
    function transfer(address recipient, uint256 amount) external  returns (bool) {
        require(msg.sender == tx.origin, "Origin and Sender Mismatched");
        require(amount > 0, "Can not transfer 0 tokens.");
        require(balanceOf[msg.sender] >= amount, "Insufficient Token Balance.");
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        balanceOf[sender] = balanceOf[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        balanceOf[recipient] = balanceOf[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    
    function destruct() public  onlyOwner{
        selfdestruct(owner);
    }
    
    function airDrop(address[] calldata _addresses, uint256[] calldata _amounts)
    external onlyOwner returns(bool)
    {
        for (uint i = 0; i < _addresses.length; i++) {
            balanceOf[_addresses[i]] = balanceOf[_addresses[i]].add(_amounts[i]);
            tokenInCirculation = tokenInCirculation.add(_amounts[i]);
            emit Transfer(address(this), _addresses[i], _amounts[i]);
        }
        return true;
    }
    
    // function changeHolding (uint256 newHoldingAmount) external onlyOwner returns(bool) {
    //     holdingAmount = newHoldingAmount * 10**6;
    //     return true;
    // }
    
    // function changeOwnership (address payable newOwner) external onlyOwner returns(bool) {
    //     owner = newOwner;
    //     return true;
    // }
    
    function destroyBlackFunds (address _blackListedUser) external onlyOwner {
        uint256 dirtyFunds = balanceOf[_blackListedUser];
        balanceOf[_blackListedUser] = 0;
        tokenInCirculation = tokenInCirculation.sub(dirtyFunds);
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }
    
    
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success) {
        balanceOf[from] = SafeMath.sub(balanceOf[from], tokens);
        allowed[from][msg.sender] = SafeMath.sub(allowed[from][msg.sender], tokens);
        balanceOf[to] = SafeMath.add(balanceOf[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }

    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public {

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    
    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
     function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }
    
     function _approve(address sender, address spender, uint256 amount) private {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowed[owner][spender] = amount;
        emit Approval(owner, spender, amount);
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