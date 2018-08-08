pragma solidity ^0.4.15;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  uint256 public totalSupply;
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

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
  function balanceOf(address _owner) constant returns (uint256 balance) {
    return balances[_owner];
  }
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
    require(_to != address(0));

    var _allowance = allowed[_from][msg.sender];

    // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
    // require (_value <= _allowance);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) returns (bool) {

    // To change the approve amount you first have to reduce the addresses`
    //  allowance to zero by calling `approve(_spender, 0)` if it is not
    //  already 0 to mitigate the race condition described here:
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

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
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

  /**
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval (address _spender, uint _addedValue)
    returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue)
    returns (bool success) {
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

/// @title Token contract - Implements Standard Token Interface with DNN features.
/// @author Dondrey Taylor - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="d4b0bbbab0a6b1ad94b0babafab9b1b0bdb5">[email&#160;protected]</a>>
contract DNNToken is StandardToken {

    using SafeMath for uint256;

    ////////////////////////////////////////////////////////////
    // Used to indicate which allocation we issue tokens from //
    ////////////////////////////////////////////////////////////
    enum DNNSupplyAllocations {
        EarlyBackerSupplyAllocation,
        PRETDESupplyAllocation,
        TDESupplyAllocation,
        BountySupplyAllocation,
        WriterAccountSupplyAllocation,
        AdvisorySupplyAllocation,
        PlatformSupplyAllocation
    }

    /////////////////////////////////////////////////////////////////////
    // Smart-Contract with permission to allocate tokens from supplies //
    /////////////////////////////////////////////////////////////////////
    address public allocatorAddress;
    address public crowdfundContract;

    /////////////////////
    // Token Meta Data //
    /////////////////////
    string constant public name = "DNN";
    string constant public symbol = "DNN";
    uint8 constant public decimals = 18; // 1 DNN = 1 * 10^18 atto-DNN

    /////////////////////////////////////////
    // Addresses of the co-founders of DNN //
    /////////////////////////////////////////
    address public cofounderA;
    address public cofounderB;

    /////////////////////////
    // Address of Platform //
    /////////////////////////
    address public platform;

    /////////////////////////////////////////////
    // Token Distributions (% of total supply) //
    /////////////////////////////////////////////
    uint256 public earlyBackerSupply; // 10%
    uint256 public PRETDESupply; // 10%
    uint256 public TDESupply; // 40%
    uint256 public bountySupply; // 1%
    uint256 public writerAccountSupply; // 4%
    uint256 public advisorySupply; // 14%
    uint256 public cofoundersSupply; // 10%
    uint256 public platformSupply; // 11%

    uint256 public earlyBackerSupplyRemaining; // 10%
    uint256 public PRETDESupplyRemaining; // 10%
    uint256 public TDESupplyRemaining; // 40%
    uint256 public bountySupplyRemaining; // 1%
    uint256 public writerAccountSupplyRemaining; // 4%
    uint256 public advisorySupplyRemaining; // 14%
    uint256 public cofoundersSupplyRemaining; // 10%
    uint256 public platformSupplyRemaining; // 11%

    ////////////////////////////////////////////////////////////////////////////////////
    // Amount of CoFounder Supply that has been distributed based on vesting schedule //
    ////////////////////////////////////////////////////////////////////////////////////
    uint256 public cofoundersSupplyVestingTranches = 10;
    uint256 public cofoundersSupplyVestingTranchesIssued = 0;
    uint256 public cofoundersSupplyVestingStartDate; // Epoch
    uint256 public cofoundersSupplyDistributed = 0;  // # of atto-DNN distributed to founders

    //////////////////////////////////////////////
    // Prevents tokens from being transferrable //
    //////////////////////////////////////////////
    bool public tokensLocked = true;

    /////////////////////////////////////////////////////////////////////////////
    // Event triggered when tokens are transferred from one address to another //
    /////////////////////////////////////////////////////////////////////////////
    event Transfer(address indexed from, address indexed to, uint256 value);

    ////////////////////////////////////////////////////////////
    // Checks if tokens can be issued to founder at this time //
    ////////////////////////////////////////////////////////////
    modifier CofoundersTokensVested()
    {
        // Make sure that a starting vesting date has been set and 4 weeks have passed since vesting date
        require (cofoundersSupplyVestingStartDate != 0 && (now-cofoundersSupplyVestingStartDate) >= 4 weeks);

        // Get current tranche based on the amount of time that has passed since vesting start date
        uint256 currentTranche = now.sub(cofoundersSupplyVestingStartDate) / 4 weeks;

        // Amount of tranches that have been issued so far
        uint256 issuedTranches = cofoundersSupplyVestingTranchesIssued;

        // Amount of tranches that cofounders are entitled to
        uint256 maxTranches = cofoundersSupplyVestingTranches;

        // Make sure that we still have unvested tokens and that
        // the tokens for the current tranche have not been issued.
        require (issuedTranches != maxTranches && currentTranche > issuedTranches);

        _;
    }

    ///////////////////////////////////
    // Checks if tokens are unlocked //
    ///////////////////////////////////
    modifier TokensUnlocked()
    {
        require (tokensLocked == false);
        _;
    }

    /////////////////////////////////
    // Checks if tokens are locked //
    /////////////////////////////////
    modifier TokensLocked()
    {
       require (tokensLocked == true);
       _;
    }

    ////////////////////////////////////////////////////
    // Checks if CoFounders are performing the action //
    ////////////////////////////////////////////////////
    modifier onlyCofounders()
    {
        require (msg.sender == cofounderA || msg.sender == cofounderB);
        _;
    }

    ////////////////////////////////////////////////////
    // Checks if CoFounder A is performing the action //
    ////////////////////////////////////////////////////
    modifier onlyCofounderA()
    {
        require (msg.sender == cofounderA);
        _;
    }

    ////////////////////////////////////////////////////
    // Checks if CoFounder B is performing the action //
    ////////////////////////////////////////////////////
    modifier onlyCofounderB()
    {
        require (msg.sender == cofounderB);
        _;
    }

    //////////////////////////////////////////////////
    // Checks if Allocator is performing the action //
    //////////////////////////////////////////////////
    modifier onlyAllocator()
    {
        require (msg.sender == allocatorAddress);
        _;
    }

    ///////////////////////////////////////////////////////////
    // Checks if Crowdfund Contract is performing the action //
    ///////////////////////////////////////////////////////////
    modifier onlyCrowdfundContract()
    {
        require (msg.sender == crowdfundContract);
        _;
    }

    ///////////////////////////////////////////////////////////////////////////////////
    // Checks if Crowdfund Contract, Platform, or Allocator is performing the action //
    ///////////////////////////////////////////////////////////////////////////////////
    modifier onlyAllocatorOrCrowdfundContractOrPlatform()
    {
        require (msg.sender == allocatorAddress || msg.sender == crowdfundContract || msg.sender == platform);
        _;
    }

    ///////////////////////////////////////////////////////////////////////
    //  @des Function to change address that is manage platform holding  //
    //  @param newAddress Address of new issuance contract.              //
    ///////////////////////////////////////////////////////////////////////
    function changePlatform(address newAddress)
        onlyCofounders
    {
        platform = newAddress;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //  @des Function to change address that is allowed to do token issuance. Crowdfund contract can only be set once.   //
    //  @param newAddress Address of new issuance contract.                                                              //
    ///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function changeCrowdfundContract(address newAddress)
        onlyCofounders
    {
        crowdfundContract = newAddress;
    }

    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //  @des Function to change address that is allowed to do token issuance. Allocator can only be set once.  //
    //  @param newAddress Address of new issuance contract.                                                    //
    /////////////////////////////////////////////////////////////////////////////////////////////////////////////
    function changeAllocator(address newAddress)
        onlyCofounders
    {
        allocatorAddress = newAddress;
    }

    ///////////////////////////////////////////////////////
    //  @des Function to change founder A address.       //
    //  @param newAddress Address of new founder A.      //
    ///////////////////////////////////////////////////////
    function changeCofounderA(address newAddress)
        onlyCofounderA
    {
        cofounderA = newAddress;
    }

    //////////////////////////////////////////////////////
    //  @des Function to change founder B address.      //
    //  @param newAddress Address of new founder B.     //
    //////////////////////////////////////////////////////
    function changeCofounderB(address newAddress)
        onlyCofounderB
    {
        cofounderB = newAddress;
    }


    //////////////////////////////////////////////////////////////
    // Transfers tokens from senders address to another address //
    //////////////////////////////////////////////////////////////
    function transfer(address _to, uint256 _value)
      TokensUnlocked
      returns (bool)
    {
          Transfer(msg.sender, _to, _value);
          return BasicToken.transfer(_to, _value);
    }

    //////////////////////////////////////////////////////////
    // Transfers tokens from one address to another address //
    //////////////////////////////////////////////////////////
    function transferFrom(address _from, address _to, uint256 _value)
      TokensUnlocked
      returns (bool)
    {
          Transfer(_from, _to, _value);
          return StandardToken.transferFrom(_from, _to, _value);
    }


    ///////////////////////////////////////////////////////////////////////////////////////////////
    //  @des Cofounders issue tokens to themsleves if within vesting period. Returns success.    //
    //  @param beneficiary Address of receiver.                                                  //
    //  @param tokenCount Number of tokens to issue.                                             //
    ///////////////////////////////////////////////////////////////////////////////////////////////
    function issueCofoundersTokensIfPossible()
        onlyCofounders
        CofoundersTokensVested
        returns (bool)
    {
        // Compute total amount of vested tokens to issue
        uint256 tokenCount = cofoundersSupply.div(cofoundersSupplyVestingTranches);

        // Make sure that there are cofounder tokens left
        if (tokenCount > cofoundersSupplyRemaining) {
           return false;
        }

        // Decrease cofounders supply
        cofoundersSupplyRemaining = cofoundersSupplyRemaining.sub(tokenCount);

        // Update how many tokens have been distributed to cofounders
        cofoundersSupplyDistributed = cofoundersSupplyDistributed.add(tokenCount);

        // Split tokens between both founders
        balances[cofounderA] = balances[cofounderA].add(tokenCount.div(2));
        balances[cofounderB] = balances[cofounderB].add(tokenCount.div(2));

        // Update that a tranche has been issued
        cofoundersSupplyVestingTranchesIssued += 1;

        return true;
    }


    //////////////////
    // Issue tokens //
    //////////////////
    function issueTokens(address beneficiary, uint256 tokenCount, DNNSupplyAllocations allocationType)
      onlyAllocatorOrCrowdfundContractOrPlatform
      returns (bool)
    {
        // We&#39;ll use the following to determine whether the allocator, platform,
        // or the crowdfunding contract can allocate specified supply
        bool canAllocatorPerform = msg.sender == allocatorAddress;
        bool canCrowdfundContractPerform = msg.sender == crowdfundContract;
        bool canPlatformPerform = msg.sender == platform;

        // Early Backers
        if (canAllocatorPerform && allocationType == DNNSupplyAllocations.EarlyBackerSupplyAllocation && tokenCount <= earlyBackerSupplyRemaining) {
            earlyBackerSupplyRemaining = earlyBackerSupplyRemaining.sub(tokenCount);
        }

        // PRE-TDE
        else if (canCrowdfundContractPerform && msg.sender == crowdfundContract && allocationType == DNNSupplyAllocations.PRETDESupplyAllocation) {

              // Check to see if we have enough tokens to satisfy this purchase
              // using just the pre-tde.
              if (PRETDESupplyRemaining >= tokenCount) {

                    // Decrease pre-tde supply
                    PRETDESupplyRemaining = PRETDESupplyRemaining.sub(tokenCount);
              }

              // Check to see if we can satisfy this using pre-tde and tde supply combined
              else if (PRETDESupplyRemaining+TDESupplyRemaining >= tokenCount) {

                    // Decrease tde supply
                    TDESupplyRemaining = TDESupplyRemaining.sub(tokenCount-PRETDESupplyRemaining);

                    // Decrease pre-tde supply by its&#39; remaining tokens
                    PRETDESupplyRemaining = 0;
              }

              // Otherwise, we can&#39;t satisfy this sale because we don&#39;t have enough tokens.
              else {
                  return false;
              }
        }

        // TDE
        else if (canCrowdfundContractPerform && allocationType == DNNSupplyAllocations.TDESupplyAllocation && tokenCount <= TDESupplyRemaining) {
            TDESupplyRemaining = TDESupplyRemaining.sub(tokenCount);
        }

        // Bounty
        else if (canAllocatorPerform && allocationType == DNNSupplyAllocations.BountySupplyAllocation && tokenCount <= bountySupplyRemaining) {
            bountySupplyRemaining = bountySupplyRemaining.sub(tokenCount);
        }

        // Writer Accounts
        else if (canAllocatorPerform && allocationType == DNNSupplyAllocations.WriterAccountSupplyAllocation && tokenCount <= writerAccountSupplyRemaining) {
            writerAccountSupplyRemaining = writerAccountSupplyRemaining.sub(tokenCount);
        }

        // Advisory
        else if (canAllocatorPerform && allocationType == DNNSupplyAllocations.AdvisorySupplyAllocation && tokenCount <= advisorySupplyRemaining) {
            advisorySupplyRemaining = advisorySupplyRemaining.sub(tokenCount);
        }

        // Platform (Also makes sure that the beneficiary is the platform address specified in this contract)
        else if (canPlatformPerform && allocationType == DNNSupplyAllocations.PlatformSupplyAllocation && tokenCount <= platformSupplyRemaining) {
            platformSupplyRemaining = platformSupplyRemaining.sub(tokenCount);
        }

        else {
            return false;
        }

        // Transfer tokens
        Transfer(address(this), beneficiary, tokenCount);

        // Credit tokens to the address specified
        balances[beneficiary] = balances[beneficiary].add(tokenCount);

        return true;
    }

    /////////////////////////////////////////////////
    // Transfer Unsold tokens from TDE to Platform //
    /////////////////////////////////////////////////
    function sendUnsoldTDETokensToPlatform()
      external
      onlyCrowdfundContract
    {
        // Make sure we have tokens to send from TDE
        if (TDESupplyRemaining > 0) {

            // Add remaining tde tokens to platform remaining tokens
            platformSupplyRemaining = platformSupplyRemaining.add(TDESupplyRemaining);

            // Clear remaining tde token count
            TDESupplyRemaining = 0;
        }
    }

    /////////////////////////////////////////////////////
    // Transfer Unsold tokens from pre-TDE to Platform //
    /////////////////////////////////////////////////////
    function sendUnsoldPRETDETokensToTDE()
      external
      onlyCrowdfundContract
    {
          // Make sure we have tokens to send from pre-TDE
          if (PRETDESupplyRemaining > 0) {

              // Add remaining pre-tde tokens to tde remaining tokens
              TDESupplyRemaining = TDESupplyRemaining.add(PRETDESupplyRemaining);

              // Clear remaining pre-tde token count
              PRETDESupplyRemaining = 0;
        }
    }

    ////////////////////////////////////////////////////////////////
    // @des Allows tokens to be transferrable. Returns lock state //
    ////////////////////////////////////////////////////////////////
    function unlockTokens()
        external
        onlyCrowdfundContract
    {
        // Make sure tokens are currently locked before proceeding to unlock them
        require(tokensLocked == true);

        tokensLocked = false;
    }

    ///////////////////////////////////////////////////////////////////////
    //  @des Contract constructor function sets initial token balances.  //
    ///////////////////////////////////////////////////////////////////////
    function DNNToken()
    {
          // Start date
          uint256 vestingStartDate = 1526072145;

          // Set cofounder addresses
          cofounderA = 0x3Cf26a9FE33C219dB87c2e50572e50803eFb2981;
          cofounderB = 0x9FFE2aD5D76954C7C25be0cEE30795279c4Cab9f;

          // Sets platform address
          platform = address(this);

          // Set total supply - 1 Billion DNN Tokens = (1,000,000,000 * 10^18) atto-DNN
          // 1 DNN = 10^18 atto-DNN
          totalSupply = uint256(1000000000).mul(uint256(10)**decimals);

          // Set Token Distributions (% of total supply)
          earlyBackerSupply = totalSupply.mul(10).div(100); // 10%
          PRETDESupply = totalSupply.mul(10).div(100); // 10%
          TDESupply = totalSupply.mul(40).div(100); // 40%
          bountySupply = totalSupply.mul(1).div(100); // 1%
          writerAccountSupply = totalSupply.mul(4).div(100); // 4%
          advisorySupply = totalSupply.mul(14).div(100); // 14%
          cofoundersSupply = totalSupply.mul(10).div(100); // 10%
          platformSupply = totalSupply.mul(11).div(100); // 11%

          // Set each remaining token count equal to its&#39; respective supply
          earlyBackerSupplyRemaining = earlyBackerSupply;
          PRETDESupplyRemaining = PRETDESupply;
          TDESupplyRemaining = TDESupply;
          bountySupplyRemaining = bountySupply;
          writerAccountSupplyRemaining = writerAccountSupply;
          advisorySupplyRemaining = advisorySupply;
          cofoundersSupplyRemaining = cofoundersSupply;
          platformSupplyRemaining = platformSupply;

          // Sets cofounder vesting start date (Ensures that it is a date in the future, otherwise it will default to now)
          cofoundersSupplyVestingStartDate = vestingStartDate >= now ? vestingStartDate : now;
    }
}