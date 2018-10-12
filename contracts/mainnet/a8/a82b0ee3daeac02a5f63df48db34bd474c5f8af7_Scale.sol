pragma solidity ^0.4.24;

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
    owner = msg.sender;
  }


  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/**************************************************************
 * @title Scale Token Contract
 * @file Scale.sol
 * @author Jared Downing and Kane Thomas of the Scale Network
 * @version 1.0
 *
 * @section DESCRIPTION
 *
 * This is an ERC20-based token with staking and inflationary functionality.
 *
 *************************************************************/

//////////////////////////////////
/// OpenZeppelin library imports
//////////////////////////////////

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

    // SafeMath.sub will throw if there is not enough balance.
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   *
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender&#39;s allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 * Modified to allow minting for non-owner addresses
 */

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) internal returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

}

/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <<span class="__cf_email__" data-cfemail="7604131b15193644">[email&#160;protected]</span>π.com>
 * @dev This tries to block incoming ether to prevent accidental loss of Ether. Should Ether end up
 * in the contract, it will allow the owner to reclaim this ether.
 * @notice Ether can still be send to this contract by:
 * calling functions labeled `payable`
 * `selfdestruct(contract_address)`
 * mining directly to the contract address
*/
contract HasNoEther is Ownable {

  /**
  * @dev Constructor that rejects incoming Ether
  * @dev The `payable` flag is added so we can access `msg.value` without compiler warning. If we
  * leave out payable, then Solidity will allow inheriting contracts to implement a payable
  * constructor. By doing it this way we prevent a payable constructor from working. Alternatively
  * we could use assembly to access msg.value.
  */
  constructor() public payable {
    require(msg.value == 0);
  }

  /**
   * @dev Disallows direct send by settings a default function without the `payable` flag.
   */
  function() external {
  }

  /**
   * @dev Transfer all Ether held by the contract to the owner.
   */
  function reclaimEther() external onlyOwner {
    assert(owner.send(address(this).balance));
  }
}


/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender&#39;s balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply = totalSupply.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

//////////////////////////////////
/// Scale Token
//////////////////////////////////

contract Scale is MintableToken, HasNoEther, BurnableToken {

    // Libraries
    using SafeMath for uint;

    //////////////////////
    // Token Information
    //////////////////////
    string public constant name = "SCALE";
    string public constant symbol = "SCALE";
    uint8 public constant  decimals = 18;

    ///////////////////////////////////////////////////////////
    // Variables For Staking and Pooling
    ///////////////////////////////////////////////////////////

    // -- Pool Minting Rates and Percentages -- //
    // Pool for Scale distribution to rewards pool
    // Set to 0 to prohibit issuing to the pool before it is assigned
    address public pool = address(0);

    // Pool and Owner minted tokens per second
    uint public poolMintRate;
    uint public ownerMintRate;

    // Amount of Scale to be staked to the pool, staking, and owner, as calculated through their percentages
    uint public poolMintAmount;
    uint public stakingMintAmount;
    uint public ownerMintAmount;

    // Scale distribution percentages
    uint public poolPercentage = 70;
    uint public ownerPercentage = 5;
    uint public stakingPercentage = 25;

    // Last time minted for owner and pool
    uint public ownerTimeLastMinted;
    uint public poolTimeLastMinted;

    // -- Staking -- //
    // Minted tokens per second
    uint public stakingMintRate;

    // Total Scale currently staked
    uint public totalScaleStaked;

    // Mapping of the timestamp => totalStaking that is created each time an address stakes or unstakes
    mapping (uint => uint) totalStakingHistory;

    // Variable for staking accuracy. Set to 86400 for seconds in a day so that staking gains are based on the day an account begins staking.
    uint timingVariable = 86400;

    // Address staking information
    struct AddressStakeData {
        uint stakeBalance;
        uint initialStakeTime;
        uint unstakeTime;
        mapping (uint => uint) stakePerDay;
    }

    // Track all tokens staked
    mapping (address => AddressStakeData) public stakeBalances;

    // -- Inflation -- //
    // Inflation rate begins at 100% per year and decreases by 30% per year until it reaches 10% where it decreases by 0.5% per year
    uint256 inflationRate = 1000;

    // Used to manage when to inflate. Allowed to inflate once per year until the rate reaches 1%.
    uint256 public lastInflationUpdate;

    // -- Events -- //
    // Fired when tokens are staked
    event Stake(address indexed staker, uint256 value);
    // Fired when tokens are unstaked
    event Unstake(address indexed unstaker, uint256 stakedAmount);
    // Fired when a user claims their stake
    event ClaimStake(address indexed claimer, uint256 stakedAmount, uint256 stakingGains);

    //////////////////////////////////////////////////
    /// Scale Token Functionality
    //////////////////////////////////////////////////

    /// @dev Scale token constructor
    constructor() public {
        // Assign owner
        owner = msg.sender;

        // Assign initial owner supply
        uint _initOwnerSupply = 10000000 ether;
        // Mint given to owner only one-time
        bool _success = mint(msg.sender, _initOwnerSupply);
        // Require minting success
        require(_success);

        // Set pool and owner last minted to ensure extra coins are not minted by either
        ownerTimeLastMinted = now;
        poolTimeLastMinted = now;

        // Set minting amount for pool, staking, and owner over the course of 1 year
        poolMintAmount = _initOwnerSupply.mul(poolPercentage).div(100);
        ownerMintAmount = _initOwnerSupply.mul(ownerPercentage).div(100);
        stakingMintAmount = _initOwnerSupply.mul(stakingPercentage).div(100);

        // One year in seconds
        uint _oneYearInSeconds = 31536000 ether;

        // Set the rate of coins minted per second for the pool, owner, and global staking
        poolMintRate = calculateFraction(poolMintAmount, _oneYearInSeconds, decimals);
        ownerMintRate = calculateFraction(ownerMintAmount, _oneYearInSeconds, decimals);
        stakingMintRate = calculateFraction(stakingMintAmount, _oneYearInSeconds, decimals);

        // Set the last time inflation was updated to now so that the next time it can be updated is 1 year from now
        lastInflationUpdate = now;
    }

    /////////////
    // Inflation
    /////////////

    /// @dev the inflation rate begins at 100% and decreases by 30% every year until it reaches 10%
    /// at 10% the rate begins to decrease by 0.5% until it reaches 1%
    function adjustInflationRate() private {
      // Make sure adjustInflationRate cannot be called for at least another year
      lastInflationUpdate = now;

      // Decrease inflation rate by 30% each year
      if (inflationRate > 100) {
        inflationRate = inflationRate.sub(300);
      }
      // Inflation rate reaches 10%. Decrease inflation rate by 0.5% from here on out until it reaches 1%.
      else if (inflationRate > 10) {
        inflationRate = inflationRate.sub(5);
      }

      adjustMintRates();
    }

    /// @dev adjusts the mint rate when the yearly inflation update is called
    function adjustMintRates() internal {

      // Calculate new mint amount of Scale that should be created per year.
      poolMintAmount = totalSupply.mul(inflationRate).div(1000).mul(poolPercentage).div(100);
      ownerMintAmount = totalSupply.mul(inflationRate).div(1000).mul(ownerPercentage).div(100);
      stakingMintAmount = totalSupply.mul(inflationRate).div(1000).mul(stakingPercentage).div(100);

      // Adjust Scale created per-second for each rate
      poolMintRate = calculateFraction(poolMintAmount, 31536000 ether, decimals);
      ownerMintRate = calculateFraction(ownerMintAmount, 31536000 ether, decimals);
      stakingMintRate = calculateFraction(stakingMintAmount, 31536000 ether, decimals);
    }

    /// @dev anyone can call this function to update the inflation rate yearly
    function updateInflationRate() public {

      // Require 1 year to have passed for every inflation adjustment
      require(now.sub(lastInflationUpdate) >= 31536000);

      adjustInflationRate();
    }

    /////////////
    // Staking
    /////////////

    /// @dev staking function which allows users to stake an amount of tokens to gain interest for up to 1 year
    function stake(uint _stakeAmount) external {
        // Require that tokens are staked successfully
        require(stakeScale(msg.sender, _stakeAmount));
    }

   /// @dev staking function which allows users to stake an amount of tokens for another user
   function stakeFor(address _user, uint _amount) external {
        // Stake for the user
        require(stakeScale(_user, _amount));
   }

   /// @dev Transfer tokens from the contract to the user when unstaking
   /// @param _value uint256 the amount of tokens to be transferred
   function transferFromContract(uint _value) internal {

     // Sanity check to make sure we are not transferring more than the contract has
     require(_value <= balances[address(this)]);

     // Add to the msg.sender balance
     balances[msg.sender] = balances[msg.sender].add(_value);
     
     // Subtract from the contract&#39;s balance
     balances[address(this)] = balances[address(this)].sub(_value);

     // Fire an event for transfer
     emit Transfer(address(this), msg.sender, _value);
   }

   /// @dev stake function reduces the user&#39;s total available balance and adds it to their staking balance
   /// @param _value how many tokens a user wants to stake
   function stakeScale(address _user, uint256 _value) private returns (bool success) {

       // You can only stake / stakeFor as many tokens as you have
       require(_value <= balances[msg.sender]);

       // Require the user is not in power down period
       require(stakeBalances[_user].unstakeTime == 0);

       // Transfer tokens to contract address
       transfer(address(this), _value);

       // Now as a day
       uint _nowAsDay = now.div(timingVariable);

       // Adjust the new staking balance
       uint _newStakeBalance = stakeBalances[_user].stakeBalance.add(_value);

       // If this is the initial stake time, save
       if (stakeBalances[_user].stakeBalance == 0) {
         // Save the time that the stake started
         stakeBalances[_user].initialStakeTime = _nowAsDay;
       }

       // Add stake amount to staked balance
       stakeBalances[_user].stakeBalance = _newStakeBalance;

       // Assign the total amount staked at this day
       stakeBalances[_user].stakePerDay[_nowAsDay] = _newStakeBalance;

       // Increment the total staked tokens
       totalScaleStaked = totalScaleStaked.add(_value);

       // Set the new staking history
       setTotalStakingHistory();

       // Fire an event for newly staked tokens
       emit Stake(_user, _value);

       return true;
   }

    /// @dev deposit a user&#39;s initial stake plus earnings if the user unstaked at least 14 days ago
    function claimStake() external returns (bool) {

      // Require that at least 14 days have passed (days)
      require(now.div(timingVariable).sub(stakeBalances[msg.sender].unstakeTime) >= 14);

      // Get the user&#39;s stake balance 
      uint _userStakeBalance = stakeBalances[msg.sender].stakeBalance;

      // Calculate tokens to mint using unstakeTime, rewards are not received during power-down period
      uint _tokensToMint = calculateStakeGains(stakeBalances[msg.sender].unstakeTime);

      // Clear out stored data from mapping
      stakeBalances[msg.sender].stakeBalance = 0;
      stakeBalances[msg.sender].initialStakeTime = 0;
      stakeBalances[msg.sender].unstakeTime = 0;

      // Return the stake balance to the staker
      transferFromContract(_userStakeBalance);

      // Mint the new tokens to the sender
      mint(msg.sender, _tokensToMint);

      // Scale unstaked event
      emit ClaimStake(msg.sender, _userStakeBalance, _tokensToMint);

      return true;
    }

    /// @dev allows users to start the reclaim process for staked tokens and stake rewards
    /// @return bool on success
    function initUnstake() external returns (bool) {

        // Require that the user has not already started the unstaked process
        require(stakeBalances[msg.sender].unstakeTime == 0);

        // Require that there was some amount staked
        require(stakeBalances[msg.sender].stakeBalance > 0);

        // Log time that user started unstaking
        stakeBalances[msg.sender].unstakeTime = now.div(timingVariable);

        // Subtract stake balance from totalScaleStaked
        totalScaleStaked = totalScaleStaked.sub(stakeBalances[msg.sender].stakeBalance);

        // Set this every time someone adjusts the totalScaleStaked amount
        setTotalStakingHistory();

        // Scale unstaked event
        emit Unstake(msg.sender, stakeBalances[msg.sender].stakeBalance);

        return true;
    }

    /// @dev function to let the user know how much time they have until they can claim their tokens from unstaking
    /// @param _user to check the time until claimable of
    /// @return uint time in seconds until they may claim
    function timeUntilClaimAvaliable(address _user) view external returns (uint) {
      return stakeBalances[_user].unstakeTime.add(14).mul(86400);
    }

    /// @dev function to check the staking balance of a user
    /// @param _user to check the balance of
    /// @return uint of the stake balance
    function stakeBalanceOf(address _user) view external returns (uint) {
      return stakeBalances[_user].stakeBalance;
    }

    /// @dev returns how much Scale a user has earned so far
    /// @param _now is passed in to allow for a gas-free analysis
    /// @return staking gains based on the amount of time passed since staking began
    function getStakingGains(uint _now) view public returns (uint) {
        if (stakeBalances[msg.sender].stakeBalance == 0) {
          return 0;
        }
        return calculateStakeGains(_now.div(timingVariable));
    }

    /// @dev Calculates staking gains 
    /// @param _unstakeTime when the user stopped staking.
    /// @return uint for total coins to be minted
    function calculateStakeGains(uint _unstakeTime) view private returns (uint mintTotal)  {

      uint _initialStakeTimeInVariable = stakeBalances[msg.sender].initialStakeTime; // When the user started staking as a unique day in unix time
      uint _timePassedSinceStakeInVariable = _unstakeTime.sub(_initialStakeTimeInVariable); // How much time has passed, in days, since the user started staking.
      uint _stakePercentages = 0; // Keeps an additive track of the user&#39;s staking percentages over time
      uint _tokensToMint = 0; // How many new Scale tokens to create
      uint _lastDayStakeWasUpdated;  // Last day the totalScaleStaked was updated
      uint _lastStakeDay; // Last day that the user staked

      // If user staked and init unstaked on the same day, gains are 0
      if (_timePassedSinceStakeInVariable == 0) {
        return 0;
      }
      // If user has been staking longer than 365 days, staked days after 365 days do not earn interest 
      else if (_timePassedSinceStakeInVariable >= 365) {
       _unstakeTime = _initialStakeTimeInVariable.add(365);
       _timePassedSinceStakeInVariable = 365;
      }
      // Average this msg.sender&#39;s relative percentage ownership of totalScaleStaked throughout each day since they started staking
      for (uint i = _initialStakeTimeInVariable; i < _unstakeTime; i++) {

        // Total amount user has staked on i day
        uint _stakeForDay = stakeBalances[msg.sender].stakePerDay[i];

        // If this was a day that the user staked or added stake
        if (_stakeForDay != 0) {

            // If the day exists add it to the percentages
            if (totalStakingHistory[i] != 0) {

                // If the day does exist add it to the number to be later averaged as a total average percentage of total staking
                _stakePercentages = _stakePercentages.add(calculateFraction(_stakeForDay, totalStakingHistory[i], decimals));

                // Set the last day someone staked
                _lastDayStakeWasUpdated = totalStakingHistory[i];
            }
            else {
                // Use the last day found in the totalStakingHistory mapping
                _stakePercentages = _stakePercentages.add(calculateFraction(_stakeForDay, _lastDayStakeWasUpdated, decimals));
            }

            _lastStakeDay = _stakeForDay;
        }
        else {

            // If the day exists add it to the percentages
            if (totalStakingHistory[i] != 0) {

                // If the day does exist add it to the number to be later averaged as a total average percentage of total staking
                _stakePercentages = _stakePercentages.add(calculateFraction(_lastStakeDay, totalStakingHistory[i], decimals));

                // Set the last day someone staked
                _lastDayStakeWasUpdated = totalStakingHistory[i];
            }
            else {
                // Use the last day found in the totalStakingHistory mapping
                _stakePercentages = _stakePercentages.add(calculateFraction(_lastStakeDay, _lastDayStakeWasUpdated, decimals));
            }
        }
      }
        // Get the account&#39;s average percentage staked of the total stake over the course of all days they have been staking
        uint _stakePercentageAverage = calculateFraction(_stakePercentages, _timePassedSinceStakeInVariable, 0);

        // Calculate this account&#39;s mint rate per second while staking
        uint _finalMintRate = stakingMintRate.mul(_stakePercentageAverage);

        // Account for 18 decimals when calculating the amount of tokens to mint
        _finalMintRate = _finalMintRate.div(1 ether);

        // Calculate total tokens to be minted. Multiply by timingVariable to convert back to seconds.
        _tokensToMint = calculateMintTotal(_timePassedSinceStakeInVariable.mul(timingVariable), _finalMintRate);

        return  _tokensToMint;
    }

    /// @dev set the new totalStakingHistory mapping to the current timestamp and totalScaleStaked
    function setTotalStakingHistory() private {

      // Get now in terms of the variable staking accuracy (days in Scale&#39;s case)
      uint _nowAsTimingVariable = now.div(timingVariable);

      // Set the totalStakingHistory as a timestamp of the totalScaleStaked today
      totalStakingHistory[_nowAsTimingVariable] = totalScaleStaked;
    }

    /////////////
    // Scale Owner Claiming
    /////////////

    /// @dev allows contract owner to claim their allocated mint
    function ownerClaim() external onlyOwner {

        require(now > ownerTimeLastMinted);

        uint _timePassedSinceLastMint; // The amount of time passed since the owner claimed in seconds
        uint _tokenMintCount; // The amount of new tokens to mint
        bool _mintingSuccess; // The success of minting the new Scale tokens

        // Calculate the number of seconds that have passed since the owner last took a claim
        _timePassedSinceLastMint = now.sub(ownerTimeLastMinted);

        assert(_timePassedSinceLastMint > 0);

        // Determine the token mint amount, determined from the number of seconds passed and the ownerMintRate
        _tokenMintCount = calculateMintTotal(_timePassedSinceLastMint, ownerMintRate);

        // Mint the owner&#39;s tokens; this also increases totalSupply
        _mintingSuccess = mint(msg.sender, _tokenMintCount);

        require(_mintingSuccess);

        // New minting was a success. Set last time minted to current block.timestamp (now)
        ownerTimeLastMinted = now;
    }

    ////////////////////////////////
    // Scale Pool Distribution
    ////////////////////////////////

    // @dev anyone can call this function that mints Scale to the pool dedicated to Scale distribution to rewards pool
    function poolIssue() public {

        // Do not allow tokens to be minted to the pool until the pool is set
        require(pool != address(0));

        // Make sure time has passed since last minted to pool
        require(now > poolTimeLastMinted);
        require(pool != address(0));

        uint _timePassedSinceLastMint; // The amount of time passed since the pool claimed in seconds
        uint _tokenMintCount; // The amount of new tokens to mint
        bool _mintingSuccess; // The success of minting the new Scale tokens

        // Calculate the number of seconds that have passed since the owner last took a claim
        _timePassedSinceLastMint = now.sub(poolTimeLastMinted);

        assert(_timePassedSinceLastMint > 0);

        // Determine the token mint amount, determined from the number of seconds passed and the ownerMintRate
        _tokenMintCount = calculateMintTotal(_timePassedSinceLastMint, poolMintRate);

        // Mint the owner&#39;s tokens; this also increases totalSupply
        _mintingSuccess = mint(pool, _tokenMintCount);

        require(_mintingSuccess);

        // New minting was a success! Set last time minted to current block.timestamp (now)
        poolTimeLastMinted = now;
    }

    /// @dev sets the address for the rewards pool
    /// @param _newAddress pool Address
    function setPool(address _newAddress) public onlyOwner {
        pool = _newAddress;
    }

    ////////////////////////////////
    // Helper Functions
    ////////////////////////////////

    /// @dev calculateFraction allows us to better handle the Solidity ugliness of not having decimals as a native type
    /// @param _numerator is the top part of the fraction we are calculating
    /// @param _denominator is the bottom part of the fraction we are calculating
    /// @param _precision tells the function how many significant digits to calculate out to
    /// @return quotient returns the result of our fraction calculation
    function calculateFraction(uint _numerator, uint _denominator, uint _precision) pure private returns(uint quotient) {
        // Take passed value and expand it to the required precision
        _numerator = _numerator.mul(10 ** (_precision + 1));
        // Handle last-digit rounding
        uint _quotient = ((_numerator.div(_denominator)) + 5) / 10;
        return (_quotient);
    }

    /// @dev Determines the amount of Scale to create based on the number of seconds that have passed
    /// @param _timeInSeconds is the time passed in seconds to mint for
    /// @return uint with the calculated number of new tokens to mint
    function calculateMintTotal(uint _timeInSeconds, uint _mintRate) pure private returns(uint mintAmount) {
        // Calculates the amount of tokens to mint based upon the number of seconds passed
        return(_timeInSeconds.mul(_mintRate));
    }
}