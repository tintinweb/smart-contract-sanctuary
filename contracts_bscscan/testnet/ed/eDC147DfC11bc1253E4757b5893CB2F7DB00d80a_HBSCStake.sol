// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the BEP20 standard as defined in the EIP.
 */
interface IBEP20 {
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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../SafeMath.sol";
import "../IBEP20.sol";

/**
 * @dev HBSC Staking Contract
 */
contract HBSCStake {

    using SafeMath for uint256;

    address public _hbscAddress;
    IBEP20 hbscToken;
    address public _wbnbAddress;
    IBEP20 wbnbToken;

    address[] internal stakeholders;
    address public _adminWallet;
    address _owner;

    uint256 public daySeconds = 86400; 
    uint256 public totalStaked;
    uint256 public total0Staked;
    uint256 public total180Staked;
    uint256 public total270Staked;
    uint256 public total365Staked;

    uint256 total0stakeholders;
    uint256 total180stakeholders;
    uint256 total270stakeholders;
    uint256 total365stakeholders;
    
    mapping (address => uint256) public token0StakedBalances;
    mapping (address => uint256) public token180StakedBalances;
    mapping (address => uint256) public token270StakedBalances;
    mapping (address => uint256) public token365StakedBalances;
    
    bool private sync;

    mapping (address => Staked) public staked;
    mapping (address => uint256) public hbscDividends;
    mapping (address => uint256) public bnbDividends;

    struct Staked{
        uint256 Stake0StartTimestamp;
        uint256 Stake180StartTimestamp;
        uint256 Stake270StartTimestamp;
        uint256 Stake365StartTimestamp;
    }

    event TokenStake(
        address user,
        uint value,
        uint length
    );

    event TokenUnStake(
        address user,
        uint value,
        uint length
    );

    event HbscClaimed(
        address user,
        uint value
    );

    event BnbClaimed(
        address user,
        uint value
    );

    modifier onlyAdmin() {
        require(
            msg.sender == _adminWallet || msg.sender == _owner, 
            "Admin only function"
        );
        _;
    }

     /*
    * @dev Protects against reentrancy
    */
    modifier synchronized {
        require(!sync, "Sync lock");
        sync = true;
        _;
        sync = false;
    }

    constructor(
        address hbscTokenAddress, 
        address wbnbAddress,
        address adminWallet
    ) 
    {
        _hbscAddress = hbscTokenAddress;
        hbscToken = IBEP20(hbscTokenAddress);
        _wbnbAddress = wbnbAddress;
        wbnbToken = IBEP20(wbnbAddress);
        _adminWallet = adminWallet;
        _owner = msg.sender;
    }

    /**
    * @notice A method to check if an address is a stakeholder.
    * @param _address The address to verify.
    * @return bool, uint256 Whether the address is a stakeholder,
    * and if so its position in the stakeholders array.
    */
   function isStakeholder(address _address)
       public
       view
       returns(bool, uint256)
   {
       for (uint256 s = 0; s < stakeholders.length; s += 1){
           if (_address == stakeholders[s]) return (true, s);
       }
       return (false, 0);
   }

   /**
    * @notice A method to add a stakeholder.
    * @param _stakeholder The stakeholder to add.
    */
   function addStakeholder(address _stakeholder)
       private
   {
       (bool _isStakeholder, ) = isStakeholder(_stakeholder);
       if(!_isStakeholder) 
       {
        stakeholders.push(_stakeholder);
        staked[_stakeholder] = Staked(0,0,0,0);
       }
   }

   /**
    * @notice A method to remove a stakeholder.
    * @param _stakeholder The stakeholder to remove.
    * can only remove from stakeholder list if amount is 0 in all tiers
    */
   function removeStakeholder(address _stakeholder)
       private
   {
       (bool _isStakeholder, uint256 s) = isStakeholder(_stakeholder);
       if(_isStakeholder
        && token0StakedBalances[_stakeholder] == 0
        && token180StakedBalances[_stakeholder] == 0
        && token270StakedBalances[_stakeholder] == 0
        && token365StakedBalances[_stakeholder] == 0){
           stakeholders[s] = stakeholders[stakeholders.length - 1];
           stakeholders.pop();
           staked[_stakeholder] = Staked(0,0,0,0);
       }
   }
    
    /*
    * @dev Receives WBNB tokens and distributes to stakeholders as dividends
    */
    function receiveWBNB(uint256 amount) 
        external 
    {
        require(
            wbnbToken.transferFrom(msg.sender, address(this), amount),
            "Receive WBNB failed"
        );

        uint256 tier0 = amount.mul(10).div(1000);
        uint256 tier180 = amount.mul(15).div(1000);
        uint256 tier270 = amount.mul(25).div(1000);
        uint256 tier365 = amount.mul(50).div(1000);

        for (uint256 s = 0; s < stakeholders.length; s += 1){
            address stakeholder = stakeholders[s];

            uint256 dividendAmount = 0;

             if(token0StakedBalances[stakeholder] > 0 && total0stakeholders > 0){
                dividendAmount += tier0.mul(token0StakedBalances[stakeholder])
                                              .div(total0Staked);
            }

            if(token180StakedBalances[stakeholder] > 0 && total180stakeholders > 0 
                && !isStakeFinished(stakeholder, 180))
            {
                dividendAmount += tier180.mul(token180StakedBalances[stakeholder])
                                                    .div(total180Staked);
            } 
            if(token270StakedBalances[stakeholder] > 0 && total270stakeholders > 0
                && !isStakeFinished(stakeholder, 270))
            {
                dividendAmount += tier270.mul(token270StakedBalances[stakeholder])
                                                    .div(total270Staked);
            }
            if(token365StakedBalances[stakeholder] > 0 && total365stakeholders > 0
                && !isStakeFinished(stakeholder, 365))
            {
                dividendAmount += tier365.mul(token365StakedBalances[stakeholder])
                                                    .div(total365Staked);
            }

            bnbDividends[stakeholder] += dividendAmount;
        }
    }

    /*
    * @dev Distributes HBSC based on tiers
    */
    function distributeHBSC (uint256 amount)
        internal
    {
        uint256 tier0 = amount.mul(10).div(1000);
        uint256 tier180 = amount.mul(15).div(1000);
        uint256 tier270 = amount.mul(25).div(1000);
        uint256 tier365 = amount.mul(50).div(1000);

        for (uint256 s = 0; s < stakeholders.length; s += 1){
           address stakeholder = stakeholders[s];

           uint256 dividendAmount = 0;

           if(token0StakedBalances[stakeholder] > 0 && total0stakeholders > 0){
                dividendAmount += tier0.mul(token0StakedBalances[stakeholder])
                                       .div(total0Staked);
            }

            if(token180StakedBalances[stakeholder] > 0 && total180stakeholders > 0 
                && !isStakeFinished(stakeholder, 180))
            {
                dividendAmount += tier180.mul(token180StakedBalances[stakeholder])
                                                     .div(total180Staked);
            }
             if(token270StakedBalances[stakeholder] > 0 && total270stakeholders > 0
                && !isStakeFinished(stakeholder, 270))
            {
                dividendAmount += tier270.mul(token270StakedBalances[stakeholder])
                                                     .div(total270Staked);
            }
            if(token365StakedBalances[stakeholder] > 0 && total365stakeholders > 0
                && !isStakeFinished(stakeholder, 365))
            {
                dividendAmount += tier365.mul(token365StakedBalances[stakeholder])
                                                     .div(total365Staked);
            }

            hbscDividends[stakeholder] += dividendAmount;
        }
    }

    /*
    * @dev Receives HBSC tokens and distributed to stakeholders as dividends
    */
    function receiveHBSC (uint256 amount) 
        external
    {
        require(
            hbscToken.transferFrom(msg.sender, address(this), amount),
            "Receive HBSC failed"
        );

        distributeHBSC(amount);
    }

    /*
    * @dev Allows staker to claim HBSC dividends
    */
    function claimHbsc() 
        public 
    {
        require(hbscDividends[msg.sender] > 0, "No dividends to claim");
        hbscToken.transfer(msg.sender, hbscDividends[msg.sender]);
        hbscDividends[msg.sender] = 0;
    }

    /*
    * @dev Allows staker to claim WBNB dividends
    */
    function claimBnb() 
        public
    {
        require(bnbDividends[msg.sender] > 0, "No dividends to claim");
        wbnbToken.transfer(msg.sender, bnbDividends[msg.sender]);
        bnbDividends[msg.sender] = 0;
    }

    /**
    * @dev Stake HBSC tokens
    */
    function StakeTokens(uint256 amount, uint256 dayLength)
        public
    {
        address user = msg.sender;

        require(hbscToken.allowance(user, address(this)) >= amount, 
           "Please first approve HBSC");
        require(amount > 0, "Stake amount can not be 0");
        require(hbscToken.balanceOf(user) >= amount, "Insufficient balance");
        require(hbscToken.transferFrom(user, address(this), amount), "Transfer failed");
        
        addStakeholder(user);
        Staked memory userStake = staked[user];

        if(dayLength == 0){
            if(token0StakedBalances[user] == 0){
                total0stakeholders++; 
            }
            token0StakedBalances[user] += amount;
            total0Staked += amount;
            userStake.Stake0StartTimestamp = block.timestamp;
        }
        else if(dayLength == 180){
            if(token180StakedBalances[user] == 0){
                total180stakeholders++;
            }
            token180StakedBalances[user] += amount;
            total180Staked += amount;
            userStake.Stake180StartTimestamp = block.timestamp;
        }
        else if(dayLength == 270){
            if(token270StakedBalances[user] == 0){
                total270stakeholders++;
            }
            token270StakedBalances[user] += amount;
            total270Staked += amount;
            userStake.Stake270StartTimestamp = block.timestamp;
        }
        else if(dayLength == 365){
            if(token365StakedBalances[user] == 0){
                total365stakeholders++;
            }
            token365StakedBalances[user] += amount;
            total365Staked += amount;
            userStake.Stake365StartTimestamp = block.timestamp;
        }
        else{
            revert("Invalid stake length");
        }
        
        totalStaked = totalStaked.add(amount);
        staked[user] = userStake;

        emit TokenStake(user, amount, dayLength);

    }
    
    /**
    * @dev UnStake HBSC Token
    */
    function unStakeTokens(uint dayLength)
        public
        synchronized
    {
        uint256 amount;

        if(dayLength == 0){
            amount = token0StakedBalances[msg.sender];

            require(
                amount > 0,
                "No available tokens to unstake in tier 0"
            );
            total0stakeholders--;
            token0StakedBalances[msg.sender] = 0;
            staked[msg.sender].Stake0StartTimestamp = 0;
            total0Staked = total0Staked.sub(amount);
            totalStaked = totalStaked.sub(amount);
            removeStakeholder(msg.sender);
            hbscToken.transfer(msg.sender, amount);
        }
        else if(dayLength == 180){
            amount = token180StakedBalances[msg.sender];

            require(
                amount > 0,
                "No available tokens to unstake in tier 180"
            );

            if(isStakeFinished(msg.sender, dayLength)) {
                hbscToken.transfer(msg.sender, amount);
            }
            else {
                emergencyUnstake(msg.sender, dayLength);
            }

            total180stakeholders--;
            token180StakedBalances[msg.sender] = 0;
            staked[msg.sender].Stake180StartTimestamp = 0;
            total180Staked = total180Staked.sub(amount);
            totalStaked = totalStaked.sub(amount);
            removeStakeholder(msg.sender);
        }
        else if(dayLength == 270){
            amount = token270StakedBalances[msg.sender];

            require(
                amount > 0,
                "No available tokens to unstake in tier 270"
            );

            if(isStakeFinished(msg.sender, dayLength)) {
                hbscToken.transfer(msg.sender, amount);
            }
            else {
                emergencyUnstake(msg.sender, dayLength);
            }

            total270stakeholders--;
            token270StakedBalances[msg.sender] = 0;
            staked[msg.sender].Stake270StartTimestamp = 0;
            total270Staked = total270Staked.sub(amount);
            totalStaked = totalStaked.sub(amount);
            removeStakeholder(msg.sender);
        }
        else if(dayLength == 365){
            amount = token365StakedBalances[msg.sender];

            require(
                amount > 0,
                "No available tokens to unstake in tier 365"
            );
            if(isStakeFinished(msg.sender, dayLength)){
                hbscToken.transfer(msg.sender, amount);
            }
            else {
                emergencyUnstake(msg.sender, dayLength);
            }

            total365stakeholders--;
            token365StakedBalances[msg.sender] = 0;
            staked[msg.sender].Stake365StartTimestamp = 0;
            total365Staked = total365Staked.sub(amount);
            totalStaked = totalStaked.sub(amount);
            removeStakeholder(msg.sender);
            
        }
        else{
            revert("Invalid stake length");
        }

        emit TokenUnStake(msg.sender, amount, dayLength);
    }

    /*
    * @dev rounds down to the nearest 10%
    */
    function getPercentileStaked(
        uint256 stakeDayLength, 
        uint256 startTimestamp
    ) 
        internal
        view
        returns (uint256)
    {
        uint256 timeRemaining = block.timestamp - startTimestamp;
        uint256 totalStakeTime = stakeDayLength.mul(daySeconds);

        uint256 percent = timeRemaining.mul(100) / totalStakeTime;

        return percent.sub(percent.mod(10));
    }

    /*
    * @dev Emergency unstake process
    * Refund completed stake amount corresponding to 10% percentiles
    * Distribute 90% of uncompleted stake amount of HBSC among other stakers
    * Remaining 10% goes to team wallet
    */
    function emergencyUnstake(
        address user, 
        uint256 stakeDayLength
    )
        internal
    {
        uint256 balance;
        uint256 startTimestamp;
        Staked memory userStake = staked[user];

        if(stakeDayLength == 180) {
            balance = token180StakedBalances[user];
            startTimestamp = userStake.Stake180StartTimestamp;
        }
        else if(stakeDayLength == 270) {
            balance = token270StakedBalances[user];
            startTimestamp = userStake.Stake270StartTimestamp;
        }
        else if(stakeDayLength == 365) {
            balance = token365StakedBalances[user];
            startTimestamp = userStake.Stake365StartTimestamp;
        }
        else {
            revert("Invalid stake length");
        }

        uint256 percentile = getPercentileStaked(stakeDayLength, startTimestamp);

        uint256 refundAmount = balance.mul(100).div(percentile);
        uint256 lostAmount = balance.sub(refundAmount);

        hbscToken.transfer(user, refundAmount);

        uint256 teamAmount = lostAmount.mul(100).div(10);
        hbscToken.transfer(_adminWallet, teamAmount);

        uint256 distributionAmount = lostAmount.sub(teamAmount);

        distributeHBSC(distributionAmount);
    }

    /*
    * @dev Determines whether stake is fininshed or liable to emergency unstake penalty
    */
    function isStakeFinished(
        address user, 
        uint256 stakeDayLength
    )
        public
        view
        returns(bool)
    {
        if(stakeDayLength == 0){
            return true;
        }
        else if(stakeDayLength == 180){
            if(staked[user].Stake180StartTimestamp == 0){
                return false;
            }
            else{
               return staked[user].Stake180StartTimestamp
                  .add(
                    stakeDayLength
                    .mul(daySeconds)
                  ) <= block.timestamp;               
            }
        }
        else if(stakeDayLength == 270){
            if(staked[user].Stake270StartTimestamp == 0){
                return false;
            }
            else{
               return staked[user].Stake270StartTimestamp
                  .add(
                    stakeDayLength
                    .mul(daySeconds)
                  ) <= block.timestamp;               
            }
        }
        else if(stakeDayLength == 365){
            if(staked[user].Stake365StartTimestamp == 0){
                return false;
            }
            else{
               return staked[user].Stake365StartTimestamp
                  .add(
                    stakeDayLength
                    .mul(daySeconds)
                  ) <= block.timestamp;               
            }
        }
        else{
            return false;
        }
    }

    /*
    * @dev Allows admin to claim tokens accidentaly sent to the contract address
    */
    function reclaimTokens(
        address tokenAddress, 
        address wallet
    ) 
        external
        onlyAdmin
    {
        IBEP20 token = IBEP20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        require(balance > 0, "No tokens available for this contract address");

        token.transfer(wallet, balance);
    }
}

