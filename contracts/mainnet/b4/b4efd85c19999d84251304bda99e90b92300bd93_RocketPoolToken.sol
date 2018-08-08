pragma solidity ^0.4.11;

contract Owned {

    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
    
}

contract Token {
    uint256 public totalSupply;
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}

contract SalesAgentInterface {
     /**** Properties ***********/
    // Main contract token address
    address tokenContractAddress;
    // Contributions per address
    mapping (address => uint256) public contributions;    
    // Total ETH contributed     
    uint256 public contributedTotal;                       
    /// @dev Only allow access from the main token contract
    modifier onlyTokenContract() {_;}
    /*** Events ****************/
    event Contribute(address _agent, address _sender, uint256 _value);
    event FinaliseSale(address _agent, address _sender, uint256 _value);
    event Refund(address _agent, address _sender, uint256 _value);
    event ClaimTokens(address _agent, address _sender, uint256 _value);  
    /*** Methods ****************/
    /// @dev The address used for the depositAddress must checkin with the contract to verify it can interact with this contract, must happen or it won&#39;t accept funds
    function getDepositAddressVerify() public;
    /// @dev Get the contribution total of ETH from a contributor
    /// @param _owner The owners address
    function getContributionOf(address _owner) constant returns (uint256 balance);
}

/*  ERC 20 token */
contract StandardToken is Token {

    function transfer(address _to, uint256 _value) returns (bool success) {
      if (balances[msg.sender] >= _value && _value > 0) {
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        Transfer(msg.sender, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
      if (balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
      } else {
        return false;
      }
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
      return allowed[_owner][_spender];
    }

    mapping (address => uint256) balances;
    mapping (address => mapping (address => uint256)) allowed;
}

/// @title The main Rocket Pool Token (RPL) contract
/// @author David Rugendyke - http://www.rocketpool.net

/*****************************************************************
*   This is the main Rocket Pool Token (RPL) contract. It features
*   Smart Agent compatibility. The Sale Agent is a new type of 
*   contract that can authorise the minting of tokens on behalf of
*   the traditional ERC20 token contract. This allows you to 
*   distribute your ICO tokens through multiple Sale Agents, 
*   at various times, of various token quantities and of varying
*   fund targets. Once you’ve written a new Sale Agent contract,
*   you can register him with the main ERC20 token contract, 
*   he’s then permitted to sell it’s tokens on your behalf using
*   guidelines such as the amount of tokens he’s allowed to sell, 
*   the maximum ether he’s allowed to raise, the start block and
*   end blocks he’s allowed to sell between and more.
/****************************************************************/

contract RocketPoolToken is StandardToken, Owned {

     /**** Properties ***********/

    string public name = "Rocket Pool";
    string public symbol = "RPL";
    string public version = "1.0";
    // Set our token units
    uint8 public constant decimals = 18;
    uint256 public exponent = 10**uint256(decimals);
    uint256 public totalSupply = 0;                             // The total of tokens currently minted by sales agent contracts    
    uint256 public totalSupplyCap = 18 * (10**6) * exponent;    // 18 Million tokens


    /**** Libs *****************/
    
    using SafeMath for uint;                           
    
    
    /*** Sale Addresses *********/
       
    mapping (address => SalesAgent) private salesAgents;   // Our contract addresses of our sales contracts 
    address[] private salesAgentsAddresses;                // Keep an array of all our sales agent addresses for iteration

    /*** Structs ***************/
             
    struct SalesAgent {                     // These are contract addresses that are authorised to mint tokens
        address saleContractAddress;        // Address of the contract
        bytes32 saleContractType;           // Type of the contract ie. presale, crowdsale 
        uint256 targetEthMax;               // The max amount of ether the agent is allowed raise
        uint256 targetEthMin;               // The min amount of ether to raise to consider this contracts sales a success
        uint256 tokensLimit;                // The maximum amount of tokens this sale contract is allowed to distribute
        uint256 tokensMinted;               // The current amount of tokens minted by this agent
        uint256 minDeposit;                 // The minimum deposit amount allowed
        uint256 maxDeposit;                 // The maximum deposit amount allowed
        uint256 startBlock;                 // The start block when allowed to mint tokens
        uint256 endBlock;                   // The end block when to finish minting tokens
        address depositAddress;             // The address that receives the ether for that sale contract
        bool depositAddressCheckedIn;       // The address that receives the ether for that sale contract must check in with its sale contract to verify its a valid address that can interact
        bool finalised;                     // Has this sales contract been completed and the ether sent to the deposit address?
        bool exists;                        // Check to see if the mapping exists
    }

    /*** Events ****************/

    event MintToken(address _agent, address _address, uint256 _value);
    event SaleFinalised(address _agent, address _address, uint256 _value);
  
    /*** Tests *****************/

    event FlagUint(uint256 flag);
    event FlagAddress(address flag);

    
    /*** Modifiers *************/

    /// @dev Only allow access from the latest version of a sales contract
    modifier isSalesContract(address _sender) {
        // Is this an authorised sale contract?
        assert(salesAgents[_sender].exists == true);
        _;
    }

    
    /**** Methods ***********/

    /// @dev RPL Token Init
    function RocketPoolToken() {}


    // @dev General validation for a sales agent contract receiving a contribution, additional validation can be done in the sale contract if required
    // @param _value The value of the contribution in wei
    // @return A boolean that indicates if the operation was successful.
    function validateContribution(uint256 _value) isSalesContract(msg.sender) returns (bool) {
        // Get an instance of the sale agent contract
        SalesAgentInterface saleAgent = SalesAgentInterface(msg.sender);
        // Did they send anything from a proper address?
        assert(_value > 0);  
        // Check the depositAddress has been verified by the account holder
        assert(salesAgents[msg.sender].depositAddressCheckedIn == true);
        // Check if we&#39;re ok to receive contributions, have we started?
        assert(block.number > salesAgents[msg.sender].startBlock);       
        // Already ended? Or if the end block is 0, it&#39;s an open ended sale until finalised by the depositAddress
        assert(block.number < salesAgents[msg.sender].endBlock || salesAgents[msg.sender].endBlock == 0); 
        // Is it above the min deposit amount?
        assert(_value >= salesAgents[msg.sender].minDeposit); 
        // Is it below the max deposit allowed?
        assert(_value <= salesAgents[msg.sender].maxDeposit); 
        // No contributions if the sale contract has finalised
        assert(salesAgents[msg.sender].finalised == false);      
        // Does this deposit put it over the max target ether for the sale contract?
        assert(saleAgent.contributedTotal().add(_value) <= salesAgents[msg.sender].targetEthMax);       
        // All good
        return true;
    }


    // @dev General validation for a sales agent contract that requires the user claim the tokens after the sale has finished
    // @param _sender The address sent the request
    // @return A boolean that indicates if the operation was successful.
    function validateClaimTokens(address _sender) isSalesContract(msg.sender) returns (bool) {
        // Get an instance of the sale agent contract
        SalesAgentInterface saleAgent = SalesAgentInterface(msg.sender);
        // Must have previously contributed
        assert(saleAgent.getContributionOf(_sender) > 0); 
        // Sale contract completed
        assert(block.number > salesAgents[msg.sender].endBlock);  
        // All good
        return true;
    }
    

    // @dev Mint the Rocket Pool Tokens (RPL)
    // @param _to The address that will receive the minted tokens.
    // @param _amount The amount of tokens to mint.
    // @return A boolean that indicates if the operation was successful.
    function mint(address _to, uint _amount) isSalesContract(msg.sender) returns (bool) {
        // Check if we&#39;re ok to mint new tokens, have we started?
        // We dont check for the end block as some sale agents mint tokens during the sale, and some after its finished (proportional sales)
        assert(block.number > salesAgents[msg.sender].startBlock);   
        // Check the depositAddress has been verified by the designated account holder that will receive the funds from that agent
        assert(salesAgents[msg.sender].depositAddressCheckedIn == true);
        // No minting if the sale contract has finalised
        assert(salesAgents[msg.sender].finalised == false);
        // Check we don&#39;t exceed the assigned tokens of the sale agent
        assert(salesAgents[msg.sender].tokensLimit >= salesAgents[msg.sender].tokensMinted.add(_amount));
        // Verify ok balances and values
        assert(_amount > 0);
         // Check we don&#39;t exceed the supply limit
        assert(totalSupply.add(_amount) <= totalSupplyCap);
         // Ok all good, automatically checks for overflow with safeMath
        balances[_to] = balances[_to].add(_amount);
        // Add to the total minted for that agent, automatically checks for overflow with safeMath
        salesAgents[msg.sender].tokensMinted = salesAgents[msg.sender].tokensMinted.add(_amount);
        // Add to the overall total minted, automatically checks for overflow with safeMath
        totalSupply = totalSupply.add(_amount);
        // Fire the event
        MintToken(msg.sender, _to, _amount);
        // Fire the transfer event
        Transfer(0x0, _to, _amount); 
        // Completed
        return true; 
    }

    /// @dev Returns the amount of tokens that can still be minted
    function getRemainingTokens() public constant returns(uint256) {
        return totalSupplyCap.sub(totalSupply);
    }
    
    /// @dev Set the address of a new crowdsale/presale contract agent if needed, usefull for upgrading
    /// @param _saleAddress The address of the new token sale contract
    /// @param _saleContractType Type of the contract ie. presale, crowdsale, quarterly
    /// @param _targetEthMin The min amount of ether to raise to consider this contracts sales a success
    /// @param _targetEthMax The max amount of ether the agent is allowed raise
    /// @param _tokensLimit The maximum amount of tokens this sale contract is allowed to distribute
    /// @param _minDeposit The minimum deposit amount allowed
    /// @param _maxDeposit The maximum deposit amount allowed
    /// @param _startBlock The start block when allowed to mint tokens
    /// @param _endBlock The end block when to finish minting tokens
    /// @param _depositAddress The address that receives the ether for that sale contract
    function setSaleAgentContract(
        address _saleAddress, 
         string _saleContractType, 
        uint256 _targetEthMin, 
        uint256 _targetEthMax, 
        uint256 _tokensLimit, 
        uint256 _minDeposit,
        uint256 _maxDeposit,
        uint256 _startBlock, 
        uint256 _endBlock, 
        address _depositAddress
    ) 
    // Only the owner can register a new sale agent
    public onlyOwner  
    {
        // Valid addresses?
        assert(_saleAddress != 0x0 && _depositAddress != 0x0);  
        // Must have some available tokens
        assert(_tokensLimit > 0 && _tokensLimit <= totalSupplyCap);
        // Make sure the min deposit is less than or equal to the max
        assert(_minDeposit <= _maxDeposit);
        // Add the new sales contract
        salesAgents[_saleAddress] = SalesAgent({
            saleContractAddress: _saleAddress,
            saleContractType: sha3(_saleContractType),
            targetEthMin: _targetEthMin,
            targetEthMax: _targetEthMax,
            tokensLimit: _tokensLimit,
            tokensMinted: 0,
            minDeposit: _minDeposit,
            maxDeposit: _maxDeposit,
            startBlock: _startBlock,
            endBlock: _endBlock,
            depositAddress: _depositAddress,
            depositAddressCheckedIn: false,
            finalised: false,
            exists: true                      
        });
        // Store our agent address so we can iterate over it if needed
        salesAgentsAddresses.push(_saleAddress);
    }


    /// @dev Sets the contract sale agent process as completed, that sales agent is now retired
    function setSaleContractFinalised(address _sender) isSalesContract(msg.sender) public returns(bool) {
        // Get an instance of the sale agent contract
        SalesAgentInterface saleAgent = SalesAgentInterface(msg.sender);
        // Finalise the crowdsale funds
        assert(!salesAgents[msg.sender].finalised);                       
        // The address that will receive this contracts deposit, should match the original senders
        assert(salesAgents[msg.sender].depositAddress == _sender);            
        // If the end block is 0, it means an open ended crowdsale, once it&#39;s finalised, the end block is set to the current one
        if (salesAgents[msg.sender].endBlock == 0) {
            salesAgents[msg.sender].endBlock = block.number;
        }
        // Not yet finished?
        assert(block.number >= salesAgents[msg.sender].endBlock);         
        // Not enough raised?
        assert(saleAgent.contributedTotal() >= salesAgents[msg.sender].targetEthMin);
        // We&#39;re done now
        salesAgents[msg.sender].finalised = true;
        // Fire the event
        SaleFinalised(msg.sender, _sender, salesAgents[msg.sender].tokensMinted);
        // All good
        return true;
    }


    /// @dev Verifies if the current address matches the depositAddress
    /// @param _verifyAddress The address to verify it matches the depositAddress given for the sales agent
    function setSaleContractDepositAddressVerified(address _verifyAddress) isSalesContract(msg.sender) public {
        // Check its verified
        assert(salesAgents[msg.sender].depositAddress == _verifyAddress && _verifyAddress != 0x0);
        // Ok set it now
        salesAgents[msg.sender].depositAddressCheckedIn = true;
    }

    /// @dev Returns true if this sales contract has finalised
    /// @param _salesAgentAddress The address of the token sale agent contract
    function getSaleContractIsFinalised(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(bool) {
        return salesAgents[_salesAgentAddress].finalised;
    }

    /// @dev Returns the min target amount of ether the contract wants to raise
    /// @param _salesAgentAddress The address of the token sale agent contract
    function getSaleContractTargetEtherMin(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
        return salesAgents[_salesAgentAddress].targetEthMin;
    }

    /// @dev Returns the max target amount of ether the contract can raise
    /// @param _salesAgentAddress The address of the token sale agent contract
    function getSaleContractTargetEtherMax(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
        return salesAgents[_salesAgentAddress].targetEthMax;
    }

    /// @dev Returns the min deposit amount of ether
    /// @param _salesAgentAddress The address of the token sale agent contract
    function getSaleContractDepositEtherMin(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
        return salesAgents[_salesAgentAddress].minDeposit;
    }

    /// @dev Returns the max deposit amount of ether
    /// @param _salesAgentAddress The address of the token sale agent contract
    function getSaleContractDepositEtherMax(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
        return salesAgents[_salesAgentAddress].maxDeposit;
    }

    /// @dev Returns the address where the sale contracts ether will be deposited
    /// @param _salesAgentAddress The address of the token sale agent contract
    function getSaleContractDepositAddress(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(address) {
        return salesAgents[_salesAgentAddress].depositAddress;
    }

    /// @dev Returns the true if the sale agents deposit address has been verified
    /// @param _salesAgentAddress The address of the token sale agent contract
    function getSaleContractDepositAddressVerified(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(bool) {
        return salesAgents[_salesAgentAddress].depositAddressCheckedIn;
    }

    /// @dev Returns the start block for the sale agent
    /// @param _salesAgentAddress The address of the token sale agent contract
    function getSaleContractStartBlock(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
        return salesAgents[_salesAgentAddress].startBlock;
    }

    /// @dev Returns the start block for the sale agent
    /// @param _salesAgentAddress The address of the token sale agent contract
    function getSaleContractEndBlock(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
        return salesAgents[_salesAgentAddress].endBlock;
    }

    /// @dev Returns the max tokens for the sale agent
    /// @param _salesAgentAddress The address of the token sale agent contract
    function getSaleContractTokensLimit(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
        return salesAgents[_salesAgentAddress].tokensLimit;
    }

    /// @dev Returns the token total currently minted by the sale agent
    /// @param _salesAgentAddress The address of the token sale agent contract
    function getSaleContractTokensMinted(address _salesAgentAddress) constant isSalesContract(_salesAgentAddress) public returns(uint256) {
        return salesAgents[_salesAgentAddress].tokensMinted;
    }

    
}