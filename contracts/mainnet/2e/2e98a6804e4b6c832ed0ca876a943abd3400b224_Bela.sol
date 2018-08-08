pragma solidity ^0.4.18;


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
  function Ownable() public {
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}


/**************************************************************
 * @title Bela Token Contract
 * @file Bela.sol
 * @author Joe Jordan, BurgTech Solutions
 * @version 1.0
 *
 * @section LICENSE
 *
 * Contact for licensing details. All rights reserved.
 *
 * @section DESCRIPTION
 *
 * This is an ERC20-based token with staking functionality.
 *
 *************************************************************/
//////////////////////////////////
/// OpenZeppelin library imports
//////////////////////////////////

///* Truffle format 













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
    Transfer(msg.sender, _to, _value);
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
    Transfer(_from, _to, _value);
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
    Approval(msg.sender, _spender, _value);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
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
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}





/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  //event MintFinished();

  //bool public mintingFinished = false;

  /*
  modifier canMint() {
    require(!mintingFinished);
    _;
  }
  */

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) internal returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
  */
}





/**
 * @title Contracts that should not own Ether
 * @author Remco Bloemen <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="0a786f6769654a38">[email&#160;protected]</a>π.com>
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
  function HasNoEther() public payable {
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
    assert(owner.send(this.balance));
  }
}


///* Remix format
//import "./MintableToken.sol";
//import "./HasNoEther.sol";


contract Bela is MintableToken, HasNoEther 
{
    // Using libraries 
    using SafeMath for uint;

    //////////////////////////////////////////////////
    /// State Variables for the Bela token contract
    //////////////////////////////////////////////////
    
    //////////////////////
    // ERC20 token state
    //////////////////////
    
    /**
    These state vars are handled in the OpenZeppelin libraries;
    we display them here for the developer&#39;s information.
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
    string public constant name = "Bela";
    string public constant symbol = "BELA";
    uint8 public constant  decimals = 18;

    ///////////////////////////////////////////////////////////
    // State vars for custom staking and budget functionality
    ///////////////////////////////////////////////////////////

    // Owner last minted time
    uint public ownerTimeLastMinted;
    // Owner minted tokens per second
    uint public ownerMintRate;

    /// Stake minting
    // Minted tokens per second for all stakers
    uint private globalMintRate;
    // Total tokens currently staked
    uint public totalBelaStaked; 

    // struct that will hold user stake
    struct TokenStakeData {
        uint initialStakeBalance;
        uint initialStakeTime;
        uint initialStakePercentage;
        address stakeSplitAddress;
    }
    
    // Track all tokens staked
    mapping (address => TokenStakeData) public stakeBalances;

    // Fire a loggable event when tokens are staked
    event Stake(address indexed staker, address indexed stakeSplitAddress, uint256 value);

    // Fire a loggable event when staked tokens are vested
    event Vest(address indexed vester, address indexed stakeSplitAddress, uint256 stakedAmount, uint256 stakingGains);

    //////////////////////////////////////////////////
    /// Begin Bela token functionality
    //////////////////////////////////////////////////

    /// @dev Bela token constructor
    function Bela() public
    {
        // Define owner
        owner = msg.sender;
        // Define initial owner supply. (ether here is used only to get the decimals right)
        uint _initOwnerSupply = 41000000 ether;
        // One-time bulk mint given to owner
        bool _success = mint(msg.sender, _initOwnerSupply);
        // Abort if initial minting failed for whatever reason
        require(_success);

        ////////////////////////////////////
        // Set up state minting variables
        ////////////////////////////////////

        // Set last minted to current block.timestamp (&#39;now&#39;)
        ownerTimeLastMinted = now;
        
        // 4500 minted tokens per day, 86400 seconds in a day
        ownerMintRate = calculateFraction(4500, 86400, decimals);
        
        // 4,900,000 targeted minted tokens per year via staking; 31,536,000 seconds per year
        globalMintRate = calculateFraction(4900000, 31536000, decimals);
    }

    /// @dev staking function which allows users to stake an amount of tokens to gain interest for up to 30 days 
    function stakeBela(uint _stakeAmount) external
    {
        // Require that tokens are staked successfully
        require(stakeTokens(_stakeAmount));
    }

    /// @dev staking function which allows users to split the interest earned with another address
    function stakeBelaSplit(uint _stakeAmount, address _stakeSplitAddress) external
    {
        // Require that a Bela split actually be split with an address
        require(_stakeSplitAddress > 0);
        // Store split address into stake mapping
        stakeBalances[msg.sender].stakeSplitAddress = _stakeSplitAddress;
        // Require that tokens are staked successfully
        require(stakeTokens(_stakeAmount));

    }

    /// @dev allows users to reclaim any staked tokens
    /// @return bool on success
    function claimStake() external returns (bool success)
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

        // Add the original stake back to the user&#39;s balance
        balances[msg.sender] += stakeBalances[msg.sender].initialStakeBalance;
        
        // Subtract stake balance from totalBelaStaked
        totalBelaStaked -= stakeBalances[msg.sender].initialStakeBalance;
        
        // Mint the new tokens; the new tokens are added to the user&#39;s balance
        if (stakeBalances[msg.sender].stakeSplitAddress > 0) 
        {
            // Splitting stake, so mint half to sender and half to stakeSplitAddress
            mint(msg.sender, _tokensToMint.div(2));
            mint(stakeBalances[msg.sender].stakeSplitAddress, _tokensToMint.div(2));
        } else {
            // Not spliting stake; mint all new tokens and give them to msg.sender 
            mint(msg.sender, _tokensToMint);
        }
        
        // Fire an event to tell the world of the newly vested tokens
        Vest(msg.sender, stakeBalances[msg.sender].stakeSplitAddress, stakeBalances[msg.sender].initialStakeBalance, _tokensToMint);

        // Clear out stored data from mapping
        stakeBalances[msg.sender].initialStakeBalance = 0;
        stakeBalances[msg.sender].initialStakeTime = 0;
        stakeBalances[msg.sender].initialStakePercentage = 0;
        stakeBalances[msg.sender].stakeSplitAddress = 0;

        return true;
    }

    /// @dev Allows user to check their staked balance
    function getStakedBalance() view external returns (uint stakedBalance) 
    {
        return stakeBalances[msg.sender].initialStakeBalance;
    }

    /// @dev allows contract owner to claim their mint
    function ownerClaim() external onlyOwner
    {
        // Sanity check: ensure that we didn&#39;t travel back in time
        require(now > ownerTimeLastMinted);
        
        uint _timePassedSinceLastMint;
        uint _tokenMintCount;
        bool _mintingSuccess;

        // Calculate the number of seconds that have passed since the owner last took a claim
        _timePassedSinceLastMint = now.sub(ownerTimeLastMinted);

        // Sanity check: ensure that some time has passed since the owner last claimed
        assert(_timePassedSinceLastMint > 0);

        // Determine the token mint amount, determined from the number of seconds passed and the ownerMintRate
        _tokenMintCount = calculateMintTotal(_timePassedSinceLastMint, ownerMintRate);

        // Mint the owner&#39;s tokens; this also increases totalSupply
        _mintingSuccess = mint(msg.sender, _tokenMintCount);

        // Sanity check: ensure that the minting was successful
        require(_mintingSuccess);
        
        // New minting was a success! Set last time minted to current block.timestamp (now)
        ownerTimeLastMinted = now;
    }

    /// @dev stake function reduces the user&#39;s total available balance. totalSupply is unaffected
    /// @param _value determines how many tokens a user wants to stake
    function stakeTokens(uint256 _value) private returns (bool success)
    {
        /// Sanity Checks:
        // You can only stake as many tokens as you have
        require(_value <= balances[msg.sender]);
        // You can only stake tokens if you have not already staked tokens
        require(stakeBalances[msg.sender].initialStakeBalance == 0);

        // Subtract stake amount from regular token balance
        balances[msg.sender] = balances[msg.sender].sub(_value);

        // Add stake amount to staked balance
        stakeBalances[msg.sender].initialStakeBalance = _value;

        // Increment the global staked tokens value
        totalBelaStaked += _value;

        /// Determine percentage of global stake
        stakeBalances[msg.sender].initialStakePercentage = calculateFraction(_value, totalBelaStaked, decimals);
        
        // Save the time that the stake started
        stakeBalances[msg.sender].initialStakeTime = now;

        // Fire an event to tell the world of the newly staked tokens
        Stake(msg.sender, stakeBalances[msg.sender].stakeSplitAddress, _value);

        return true;
    }

    /// @dev Helper function to claimStake that modularizes the minting via staking calculation 
    function calculateStakeGains(uint _timePassedSinceStake) view private returns (uint mintTotal)
    {
        // Store seconds in a day (need it in variable to use SafeMath)
        uint _secondsPerDay = 86400;
        uint _finalStakePercentage;     // store our stake percentage at the time of stake claim
        uint _stakePercentageAverage;   // store our calculated average minting rate ((initial+final) / 2)
        uint _finalMintRate;            // store our calculated final mint rate (in Bela-per-second)
        uint _tokensToMint = 0;         // store number of new tokens to be minted
        
        // Determine the amount to be newly minted upon vesting, if any
        if (_timePassedSinceStake > _secondsPerDay) {
            
            /// We&#39;ve passed the minimum staking time; calculate minting rate average ((initialRate + finalRate) / 2)
            
            // First, calculate our final stake percentage based upon the total amount of Bela staked
            _finalStakePercentage = calculateFraction(stakeBalances[msg.sender].initialStakeBalance, totalBelaStaked, decimals);

            // Second, calculate average of initial and final stake percentage
            _stakePercentageAverage = calculateFraction((stakeBalances[msg.sender].initialStakePercentage.add(_finalStakePercentage)), 2, 0);

            // Finally, calculate our final mint rate (in Bela-per-second)
            _finalMintRate = globalMintRate.mul(_stakePercentageAverage); 
            _finalMintRate = _finalMintRate.div(1 ether);
            
            // Tokens were staked for enough time to mint new tokens; determine how many
            if (_timePassedSinceStake > _secondsPerDay.mul(30)) {
                // Tokens were staked for the maximum amount of time (30 days)
                _tokensToMint = calculateMintTotal(_secondsPerDay.mul(30), _finalMintRate);
            } else {
                // Tokens were staked for a mintable amount of time, but less than the 30-day max
                _tokensToMint = calculateMintTotal(_timePassedSinceStake, _finalMintRate);
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

    /// @dev Determines mint total based upon how many seconds have passed
    /// @param _timeInSeconds takes the time that has elapsed since the last minting
    /// @return uint with the calculated number of new tokens to mint
    function calculateMintTotal(uint _timeInSeconds, uint _mintRate) pure private returns(uint mintAmount)
    {
        // Calculates the amount of tokens to mint based upon the number of seconds passed
        return(_timeInSeconds.mul(_mintRate));
    }

}