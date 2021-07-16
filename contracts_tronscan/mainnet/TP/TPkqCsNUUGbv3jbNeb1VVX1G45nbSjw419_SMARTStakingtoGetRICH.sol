//SourceUnit: ReentrancyGuard.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

//SourceUnit: SMARTStakingtoGetRICH.sol

pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./Token.sol";
import "./ReentrancyGuard.sol";

contract SMARTStakingtoGetRICH is ReentrancyGuard {
    using SafeMath for uint256;
    
    address owner;
    bool openingStaking;
    bool openingWithdrawal;
    Token private smartToken;
    Token private richToken;

    uint256 public stakeCount;
    uint256 public lastUserId;
    uint256 public totalStakedAll;
    uint256 public totalRewardAll;
    uint256 oneYearToSeconds = 31536000;

    uint256 precision = 18;    
    uint256 decimalToken = uint256(10)**precision;

    struct Account {
        uint256 id;
        uint256 stakeId;
        bool stakeActive;
        bool complete;
        uint256[] nonactive;
    }
    
    struct Staker {
        uint256 id;
        uint256 smart;
        uint256 rich;
        uint256 withdraw;
        uint256 max_reward;
        uint256 startStake;
        uint256 finishStake;
        uint256 checkPoint; 
        uint256 checkPointX;
        uint256 unStake; 
        bool active; 
        address stakeAdd;
    }
    
    mapping(address => Account) public accounts;
    mapping(uint256 => Staker) public stakers;
    
    // Declare Modified
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // Declare Event
    event DepositToStake(address stakers, uint256 stakeId, uint256 amount, uint256 timestamp);
    event WithdrawReward(address stakers, uint256 stakeId ,uint256 amount, uint256 timestamp);
    event UnStake(address stakers, uint256 stakeId, uint256 timestamp);
    
    // ReentrancyGuard()
    constructor(address _smartToken, address _richToken) ReentrancyGuard()  public {
        owner = msg.sender;
        openingStaking = false;
        openingWithdrawal = false;

        smartToken = Token(_smartToken);
        richToken = Token(_richToken);

        lastUserId++; stakeCount++;

        accounts[msg.sender].id = lastUserId;
        accounts[msg.sender].stakeId = stakeCount;
        accounts[msg.sender].stakeActive = false;
        accounts[msg.sender].complete = true;
        createNewStake(stakeCount, 0);

        stakers[stakeCount].active = false;
        
        oneYearToSeconds = 31536000;
        totalStakedAll = 0;
        totalRewardAll = 0;
    }
    
    function () external payable {} 
    
    function createNewStake(uint256 id, uint256 smart) private {
        uint256 maxReward = 0;
        if(id != 1){
            maxReward = smart.mul(10); //1000 %
        }
    
        uint256 startStake = block.timestamp;

        stakers[id].id = id;
        stakers[id].smart = smart;
        stakers[id].rich = 0;
        stakers[id].max_reward = maxReward;
        stakers[id].startStake = startStake;
        stakers[id].checkPoint = startStake;
        stakers[id].checkPointX = startStake;
        stakers[id].finishStake = startStake.add(oneYearToSeconds); // 31536000
        stakers[id].withdraw = 0;
        stakers[id].active = true;
        stakers[id].stakeAdd = msg.sender;

        totalStakedAll += smart;
        totalRewardAll += maxReward;
    }

    function depositSmart(address sender, uint256 amount) private returns (bool) {
        // transfer token to this contract
        uint256 allowance = getAllowance(sender);
        uint256 balance = smartToken.balanceOf(sender);

        require(balance >= amount, "Not enough token in the reserve");
        require(allowance >= amount, "Allowance not enough to this transaction");

        bool sending = smartToken.transferFrom(sender, address(this), amount);
        return sending;
    }
    
    function addNewStake(uint256 stakeAmount) public returns (bool, uint256) {
        require(openingStaking == true, "Staking temporary closed");
        uint256 stakeAmountInDecimal = stakeAmount.mul(decimalToken);
        uint256 balanceOfToken = smartToken.balanceOf(msg.sender);
        uint256 allowance = getAllowance(msg.sender);
        require(balanceOfToken >= stakeAmountInDecimal, "Not enough tokens in the reserve");
        require(allowance >= stakeAmountInDecimal, "Allowance not enough to this transaction");

        bool accountExist = isAccountExists(msg.sender);

        uint256 nextIdStake;
        if(accountExist){
            // if account already
            bool isStakeRuns = accounts[msg.sender].stakeActive;

            if(isStakeRuns){
                // already staking runnings
                revert("Stake already running"); 
            }
            else{
                // transfer token to this contract
                bool sendTokenToContract = depositSmart(msg.sender, stakeAmountInDecimal );
                require(sendTokenToContract, "Failed to deposit your token");
                // create new stakers
                stakeCount++;
                nextIdStake = stakeCount;
                accounts[msg.sender].stakeId = nextIdStake;
                accounts[msg.sender].stakeActive = true;
                accounts[msg.sender].complete = false;
                createNewStake(nextIdStake, stakeAmountInDecimal);
            }
        }
        else{
            // transfer token to this contract            
            bool sendTokenToContract = depositSmart(msg.sender, stakeAmountInDecimal );
            require(sendTokenToContract, "Failed to deposit your token");

            lastUserId++; stakeCount++;
            // if account not exist 
            nextIdStake = stakeCount;

            accounts[msg.sender].id = lastUserId;
            accounts[msg.sender].stakeId = nextIdStake;
            accounts[msg.sender].stakeActive = true;
            accounts[msg.sender].complete = false;
            createNewStake(nextIdStake, stakeAmountInDecimal);
        }

        emit DepositToStake(msg.sender, nextIdStake, stakeAmount, block.timestamp);
        return (true, nextIdStake);
    }

    function isAccountExists(address account) public view returns (bool) {
        return (accounts[account].id != 0);
    }

    function getAllowance(address _address) public view returns (uint256){
        return smartToken.allowance(_address, address(this));
    }

    function updateRewardStaking(uint256 stakeId) public returns (bool){
        require(stakeId > 0, "Stake not found");
        require(stakeId <= stakeCount, "Stake not found");

        uint256 rich = stakers[stakeId].rich;
        uint256 withdraw = stakers[stakeId].withdraw;
        uint256 totalReward = rich.add(withdraw);

        if(stakers[stakeId].active){
            if(totalReward <= stakers[stakeId].max_reward){
                uint256 rewardRemaining = stakers[stakeId].max_reward.sub(totalReward);

                uint256 secondsReward = 0; uint256 NewCheckPoint = 0; uint256 OldCheckPoint = 0; uint256 calculateRewards = 0;
                if(block.timestamp >= stakers[stakeId].finishStake){
                    // add remaining reward 
                    calculateRewards = rewardRemaining;
                    if(calculateRewards > 0){
                        OldCheckPoint = stakers[stakeId].checkPoint;
                        NewCheckPoint = block.timestamp;
                    }
                }
                else{
                    // stake is running
                    OldCheckPoint = stakers[stakeId].checkPoint;
                    uint256 finishTime = block.timestamp;
                    secondsReward = finishTime.sub(OldCheckPoint);
                    if(secondsReward > 0){   
                        NewCheckPoint = finishTime;
                        
                        uint256 rewardPerSeconds = calculateStakeRewardPerSeconds(stakers[stakeId].max_reward);
                        calculateRewards = secondsReward.mul(rewardPerSeconds);
                        
                        if(calculateRewards > rewardRemaining){
                            calculateRewards = rewardRemaining;
                        }
                    }
                }

                if(calculateRewards > 0){
                    stakers[stakeId].rich += calculateRewards;
                    stakers[stakeId].checkPointX = OldCheckPoint;
                    stakers[stakeId].checkPoint = NewCheckPoint;

                }                
            }
            return true;
        }
        else{
            return false;
        }

    }

    function calculateStakeRewardPerSeconds(uint256 stakeAmount) public view returns(uint256){
        return stakeAmount.div(oneYearToSeconds);
    }

    function smartDepositBalance() private returns (uint256){
        return smartToken.balanceOf(address(this));
    }

    function richRewardBalance() private returns (uint256){
        return richToken.balanceOf(address(this));
    }

    function withdrawStakingReward() payable public returns (bool){
        require(openingWithdrawal == true, "Withdrawal temporary closed");

        address _address = msg.sender;
        require(isAccountExists(_address), "Address not exist in account");

        uint stakeId = accounts[_address].stakeId;
        bool update = updateRewardStaking(stakeId);
        require(update, "Failed to updating your reward");

        uint256 richBalance = richRewardBalance();
        
        if(richBalance <= 0){
            if(stakers[stakeId].active){
                // unstake 
                stakers[stakeId].active = false;
                stakers[stakeId].unStake = block.timestamp;
                accounts[_address].stakeActive = false;
                accounts[_address].complete = true;
                accounts[_address].nonactive.push(stakeId);

                totalStakedAll -= stakers[stakeId].smart;
                totalRewardAll -= stakers[stakeId].max_reward;

                // sending all staking deposit 
                sendingDeposit(stakeId);
                emit UnStake(msg.sender, stakeId, block.timestamp);
                return true;
            }
        }

        require(richBalance > 0, "Rich token not enough");

        uint256 richReward = stakers[stakeId].rich;
        require(richReward > 0, "No available stake reward earned");

        if(richBalance <= richReward){
            // last call reward 
            // unstake 
            stakers[stakeId].active = false;
            stakers[stakeId].unStake = block.timestamp;
            accounts[_address].stakeActive = false;
            accounts[_address].complete = true;
            accounts[_address].nonactive.push(stakeId);

            totalStakedAll -= stakers[stakeId].smart;
            totalRewardAll -= stakers[stakeId].max_reward;

            // sending all staking deposit 
            sendingDeposit(stakeId);

            // sending last reward
            stakers[stakeId].rich = 0;
            stakers[stakeId].withdraw += richBalance;

            richToken.transfer(msg.sender, richBalance);
            emit WithdrawReward(msg.sender, stakeId, richBalance, block.timestamp);

            return true;
        }

        require(richBalance >= richReward, "Rich balance not enough");

        uint256 withdraw = stakers[stakeId].withdraw;
        uint256 totalReward = richReward.add(withdraw);

        if(totalReward >= stakers[stakeId].max_reward){
            if(stakers[stakeId].active){
                // unstake 
                stakers[stakeId].active = false;
                stakers[stakeId].unStake = block.timestamp;
                accounts[_address].stakeActive = false;
                accounts[_address].complete = true;
                accounts[_address].nonactive.push(stakeId);

                totalStakedAll -= stakers[stakeId].smart;
                totalRewardAll -= stakers[stakeId].max_reward;

                // sending all staking deposit 
                sendingDeposit(stakeId);
            }
        }

        bool send = sendingReward(stakeId);
        require(send, "Failed send reward to your account");

        emit WithdrawReward(msg.sender, stakeId, richReward, block.timestamp);

        return true;
    }

    function sendingReward(uint256 stakeId) private returns (bool) {
        uint256 richReward = stakers[stakeId].rich;
        stakers[stakeId].rich = 0;
        stakers[stakeId].withdraw += richReward;
        bool send = richToken.transfer(msg.sender, richReward);
        return send;
    }

    function sendingDeposit(uint256 stakeId) private returns (bool){
        uint256 deposit = stakers[stakeId].smart;
        bool send = smartToken.transfer(msg.sender, deposit);
        return send;
    }

    function unStake() public returns (bool){
        address _address = msg.sender;
        require(isAccountExists(_address), "Address not exist in account");

        uint stakeId = accounts[_address].stakeId;
        require(stakeId > 0, "Stake id not found");
        require(stakers[stakeId].active, "Already unstaked");
        
        bool update = updateRewardStaking(stakeId);
        require(update, "Failed to updating your reward");

        uint256 smartBalance = smartDepositBalance();
        require(smartBalance > 0, "Smart token not enough");
        require(smartBalance >= stakers[stakeId].smart, "Smart token not enough than your deposit");

        // set account stake to false or inactive
        stakers[stakeId].active = false;
        stakers[stakeId].unStake = block.timestamp;
        accounts[_address].stakeActive = false;
        accounts[_address].complete = true;
        accounts[_address].nonactive.push(stakeId);

        totalStakedAll -= stakers[stakeId].smart;
        totalRewardAll -= stakers[stakeId].max_reward;

        // sending all reward to wallet if any reward
        uint256 richReward = stakers[stakeId].rich;
        if(richReward > 0){
            uint256 richBalance = richRewardBalance();
            if(richBalance < richReward){
                // sending last reward
                stakers[stakeId].rich = 0;
                stakers[stakeId].withdraw += richBalance;

                richToken.transfer(msg.sender, richBalance);
            }
            else{
                sendingReward(stakeId);
            }
        }

        // sending all staking deposit 
        bool send = sendingDeposit(stakeId);

        require(send, "Failed send reward to your account");

        emit UnStake(msg.sender, stakeId, block.timestamp);
        return true;
    }

    function getAccountByAddress(address _address) public view returns (uint256, uint256, bool, bool, uint256[] memory) {
        return (
            accounts[_address].id,
            accounts[_address].stakeId,
            accounts[_address].stakeActive,
            accounts[_address].complete,
            accounts[_address].nonactive
            );
    }

    function getStakeActiveByAddress(address _address) public view returns (uint256, uint256, uint256, uint256, uint256, uint256, uint256, uint256, bool, address, uint){
        require(isAccountExists(_address), "Address not exist in account");

        uint256 stakeId = 0;
        if(accounts[_address].stakeActive){
            // stake is active
            stakeId = accounts[_address].stakeId;
        }
        return (
                stakers[stakeId].id,
                stakers[stakeId].smart,
                stakers[stakeId].rich,
                stakers[stakeId].max_reward,
                stakers[stakeId].startStake,
                stakers[stakeId].finishStake,
                stakers[stakeId].checkPoint,
                stakers[stakeId].withdraw,
                stakers[stakeId].active,
                stakers[stakeId].stakeAdd,
                block.timestamp
        );
    }

    function setOpening(uint _val) onlyOwner public returns (bool){
        if(_val == 1){
            openingStaking = true;
        }else{
            openingStaking = false;
        }
        return openingStaking;
    }
    
    function setWithdraw(uint _val) onlyOwner public returns (bool){
        if(_val == 1){
            openingWithdrawal = true;
        }else{
            openingWithdrawal = false;
        }
        return openingWithdrawal;
    }
}

//SourceUnit: SafeMath.sol

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.0;

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

//SourceUnit: Token.sol

pragma solidity ^0.5.0;

contract TRC20Interface {
  string public name;
  string public symbol;
  uint8 public decimals;
  uint256 public totalSupply;
  function balanceOf(address _owner) public view returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) public returns (bool success);
  function allowance(address _owner, address _spender) public view returns (uint256 remaining);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor () public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }

  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}

/**
Function to receive approval and execute function in one call.
 */
contract TokenRecipient { 
  function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public; 
}

/**
Token implement
 */
contract Token is TRC20Interface, Owned {

  mapping (address => uint256) _balances;
  mapping (address => mapping (address => uint256)) _allowed;
  
  // This notifies clients about the amount burnt
  event Burn(address indexed from, uint256 value);
  
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return _balances[_owner];
  }

  function transfer(address _to, uint256 _value) public returns (bool success) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
    require(_value <= _allowed[_from][msg.sender]); 
    _allowed[_from][msg.sender] -= _value;
    _transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool success) {
    _allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
    return _allowed[_owner][_spender];
  }

  function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
    return TRC20Interface(tokenAddress).transfer(owner, tokens);
  }
  function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) public returns (bool success) {
    TokenRecipient spender = TokenRecipient(_spender);
    approve(_spender, _value);
    spender.receiveApproval(msg.sender, _value, address(this), _extraData);
    return true;
  }

  function burn(uint256 _value) public returns (bool success) {
    require(_balances[msg.sender] >= _value);
    _balances[msg.sender] -= _value;
    totalSupply -= _value;
    emit Burn(msg.sender, _value);
    return true;
  }

  function burnFrom(address _from, uint256 _value) public returns (bool success) {
    require(_balances[_from] >= _value);
    require(_value <= _allowed[_from][msg.sender]);
    _balances[_from] -= _value;
    _allowed[_from][msg.sender] -= _value;
    totalSupply -= _value;
    emit Burn(_from, _value);
    return true;
  }

  function _transfer(address _from, address _to, uint _value) internal {
    // Prevent transfer to 0x0 address. Use burn() instead
    require(_to != address(0x0));
    // Check if the sender has enough
    require(_balances[_from] >= _value);
    // Check for overflows
    require(_balances[_to] + _value > _balances[_to]);
    // Save this for an assertion in the future
    uint previousBalances = _balances[_from] + _balances[_to];
    // Subtract from the sender
    _balances[_from] -= _value;
    // Add the same to the recipient
    _balances[_to] += _value;
    emit Transfer(_from, _to, _value);
    // Asserts are used to use static analysis to find bugs in your code. They should never fail
    assert(_balances[_from] + _balances[_to] == previousBalances);
  }

}