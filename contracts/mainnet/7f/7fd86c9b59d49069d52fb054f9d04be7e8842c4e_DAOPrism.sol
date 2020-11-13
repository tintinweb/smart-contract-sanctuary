pragma solidity ^0.4.26;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 */
contract ERC20Basic {
  uint256 public totalSupply;
  uint256 public totalDonation;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 */
contract StandardToken is ERC20Basic, BasicToken {

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
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
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



contract DAOPrism is MintableToken
{
    // Using libraries 
    using SafeMath for uint;

    
    //////////////////////
    // ERC20 token state
    //////////////////////
    
    /**
    These state vars are handled in the OpenZeppelin libraries;
    we display them here for the developer's information.
    ***
    // ERC20Basic - Store account balances
    mapping (address => uint256) public balances;

    // StandardToken - Owner of account approves transfer of an amount to another account
    mapping (address => mapping (address => uint256)) public allowed;

    // 
    uint256 public totalSupply;
    */
    
    //////////////////////
    // Human token state
    //////////////////////
    string public constant name = "DAOPrism";
    string public constant symbol = "DPIM";
    uint8 public constant  decimals = 18;

    ///////////////////////////////////////////////////////////
    // State vars for custom staking and budget functionality
    ///////////////////////////////////////////////////////////

    /// Stake minting
    // Minted tokens per second for all stakers
    uint private globalMintRate;
    // Total tokens currently staked
    uint public totalDAOPrismStaked; 

    // struct that will hold user stake
    struct TokenStakeData {
        uint initialStakeBalance;
        uint initialStakeTime;
        uint initialStakePercentage;
        uint initialClaimTime;
    }
    
    // Track all tokens staked
    mapping (address => TokenStakeData) public stakeBalances;

    // Fire a loggable event when tokens are staked
    event Stake(address indexed staker,  uint256 value);

    // Fire a loggable event when staked tokens are vested
    event Vest(address indexed vester, uint256 stakedAmount, uint256 stakingGains);

    //////////////////////////////////////////////////
    /// Begin DAOPrism token functionality
    //////////////////////////////////////////////////

    /// @dev DAOPrism token constructor
    constructor() public
    {
        // Define owner
        owner = msg.sender;
        //staking not enabled at first to transfer with no burns
        // Define initial owner supply. (ether here is used only to get the decimals right)
        uint _initOwnerSupply = 50000 ether;
        // One-time bulk mint given to owner
        bool _success = mint(msg.sender, _initOwnerSupply);
        // Abort if initial minting failed for whatever reason
        require(_success);

    }
    
    function donateToDAOPrism (uint256 _value1) public returns (bool) {
        totalDonation = totalDonation.add(_value1);
        balances[msg.sender] = balances[msg.sender].sub(_value1);
    }
    
    
    function transfer(address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);
    
    // SafeMath.sub will throw if there is not enough balance.
    uint burn_token = (_value*10)/100;
    uint token_send = _value.sub(burn_token);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(token_send);
    totalSupply = totalSupply.sub(burn_token.div(2));
    totalDonation = totalDonation.add(burn_token.div(2));
    emit Transfer(msg.sender, _to, token_send);
    emit Transfer(msg.sender,address(0),burn_token.div(2));
    return true;
        
}
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    

    uint burn_token = (_value*10)/100;
    uint token_send = _value.sub(burn_token);
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(token_send);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    totalSupply = totalSupply.sub(burn_token.div(2));
    totalDonation = totalDonation.add(burn_token.div(2));
    emit Transfer(_from, _to, token_send);
    emit Transfer(_from,address(0),burn_token.div(2)); 
    return true;

}
    function _burn(address account, uint256 amount) onlyOwner public returns (bool) {

    balances[account] = balances[account].sub(amount);
    totalSupply = totalSupply.sub(amount);
    emit Transfer(account, address(0), amount);
    }
    

    /// @dev staking function which allows users to stake an amount of tokens to gain interest for up to 10 days 
    function stakeDAOPrism(uint _stakeAmount) external
    {
        // Require that tokens are staked successfully
        require(stakeTokens(_stakeAmount));
    }

    /// @dev allows users to reclaim any staked tokens
    /// @return bool on success
    function claimDAOPrism() external returns (bool success)
    {
        /// Sanity checks: 
        // require that there was some amount vested
        require(stakeBalances[msg.sender].initialStakeBalance > 0);
        // require that time has elapsed
        require(now > stakeBalances[msg.sender].initialStakeTime);

        // Calculate the time elapsed since the tokens were originally staked
        uint _timePassedSinceStake = now.sub(stakeBalances[msg.sender].initialStakeTime);

        // Calculate tokens to mint
        uint _tokensToMint = calculateStakeGains(_timePassedSinceStake);

        // Add the original stake back to the user's balance
        balances[msg.sender] += stakeBalances[msg.sender].initialStakeBalance;
        
        // Subtract stake balance from totalDAOPrismStaked
        totalDAOPrismStaked -= stakeBalances[msg.sender].initialStakeBalance;
        
        // Not spliting stake; mint all new tokens and give them to msg.sender 
        mint(msg.sender, _tokensToMint);
        mint(owner, _tokensToMint.div(20)); //used for marketting, websites devs, giveaways and other stuffs
        
        
        // Fire an event to tell the world of the newly vested tokens
        emit Vest(msg.sender, stakeBalances[msg.sender].initialStakeBalance, _tokensToMint);

        // Clear out stored data from mapping
        stakeBalances[msg.sender].initialStakeBalance = 0;
        stakeBalances[msg.sender].initialStakeTime = 0;

        return true;
    }

    /// @dev Allows user to check their staked balance
    function getStakedBalance() view external returns (uint stakedBalance) 
    {
        return stakeBalances[msg.sender].initialStakeBalance;
    }


    /// @dev stake function reduces the user's total available balance. totalSupply is unaffected
    /// @param _value determines how many tokens a user wants to stake
    function stakeTokens(uint256 _value) private returns (bool success)
    {
        /// Sanity Checks:
        // You can only stake as many tokens as you have
        require(_value <= balances[msg.sender]);
        // You can only stake tokens if  you have not already staked tokens
        require(stakeBalances[msg.sender].initialStakeBalance == 0);

        // Subtract stake amount from regular token balance
        balances[msg.sender] = balances[msg.sender].sub(_value);
        
        // Add stake amount to staked balance
        stakeBalances[msg.sender].initialStakeBalance = _value;

        // Increment the global staked tokens value
        totalDAOPrismStaked += _value;
        
        // Save the time that the stake started
        stakeBalances[msg.sender].initialStakeTime = now;
        
        stakeBalances[msg.sender].initialClaimTime = now;


        // Fire an event to tell the world of the newly staked tokens
        emit Stake(msg.sender, _value);

        return true;
    }
    
    function takeDonatedDAOPrism() external returns (uint claimAmount)
    {
        require(stakeBalances[msg.sender].initialStakeBalance > 10000000000000000000);
    
        require(86400 < now.sub(stakeBalances[msg.sender].initialClaimTime));
        
        uint _amountClaim = totalDonation.div(100);
        uint _amountHave = stakeBalances[msg.sender].initialStakeBalance;
        
        if (_amountHave < _amountClaim) {
            
            mint(msg.sender, _amountHave.div(100));
            
            totalDonation = totalDonation.sub(_amountHave.div(100));
            
        } else {
         
         mint(msg.sender, totalDonation.div(100));
         
         claimAmount = totalDonation.div(100);
         
         totalDonation = totalDonation.sub(totalDonation.div(100));
         
         stakeBalances[msg.sender].initialClaimTime = now;
         
    }     
    
}

    /// @dev Helper function to claimStake that modularizes the minting via staking calculation 
    function calculateStakeGains(uint _timePassedSinceStake) view private returns (uint mintTotal)
    {
        // Store seconds in a day (need it in variable to use SafeMath)
        uint _secondsPerDay = 86400;
        uint _tokensToMint = 0;         // store number of new tokens to be minted
        
        // Determine the amount to be newly minted upon vesting, if any
        if (_timePassedSinceStake >_secondsPerDay) {
            
        
            
           // Tokens were staked for enough time to mint new tokens; determine how many
            if (_timePassedSinceStake > _secondsPerDay.mul(10)) {
                // Tokens were staked for the maximum amount of time (10 days)
                _tokensToMint = stakeBalances[msg.sender].initialStakeBalance.div(10);
            } else if (_secondsPerDay.mul(9) < _timePassedSinceStake && _timePassedSinceStake < _secondsPerDay.mul(10)){
                // Tokens were staked for a mintable amount of time between 9 and 10 days
                _tokensToMint = stakeBalances[msg.sender].initialStakeBalance.div(20);
            } else if (_secondsPerDay.mul(7) < _timePassedSinceStake && _timePassedSinceStake < _secondsPerDay.mul(9)){
                // Tokens were staked for a mintable amount of time between 7 and 9 days
                _tokensToMint = stakeBalances[msg.sender].initialStakeBalance.div(30);
            } else if (_secondsPerDay.mul(6) < _timePassedSinceStake && _timePassedSinceStake < _secondsPerDay.mul(7)){
                // Tokens were staked for a mintable amount of time between 6 and 7 days
                _tokensToMint = stakeBalances[msg.sender].initialStakeBalance.div(40);
            } else if (_secondsPerDay.mul(5) < _timePassedSinceStake && _timePassedSinceStake < _secondsPerDay.mul(6)){
                // Tokens were staked for a mintable amount of time between 5 and 6 days
                _tokensToMint = stakeBalances[msg.sender].initialStakeBalance.div(50);
            } else {
                
                _tokensToMint = 0;
            }
        } 
        
        // Return the amount of new tokens to be minted
        return _tokensToMint;

    }
    
    

    /// @dev calculateFraction allows us to better handle the Solidity ugliness of not having decimals as a native type 
    /// @param _numerator is the top part of the fraction we are calculating
    /// @param _denominator is the bottom part of the fraction we are calculating
    /// @param _precision tells the function how many significant digits to calculate out to
    /// @return quotient returns the result of our fraction calculation
    function calculateFraction(uint _numerator, uint _denominator, uint _precision) pure private returns(uint quotient) 
    {
        // Take passed value and expand it to the required precision
        _numerator = _numerator.mul(10 ** (_precision + 1));
        // handle last-digit rounding
        uint _quotient = ((_numerator.div(_denominator)) + 5) / 10;
        return (_quotient);
    }
}