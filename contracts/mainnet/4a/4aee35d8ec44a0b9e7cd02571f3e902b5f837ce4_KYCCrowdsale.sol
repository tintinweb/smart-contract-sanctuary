pragma solidity 0.4.21;

// File: contracts/BytesDeserializer.sol

/*
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */

/*
 * Deserialize bytes payloads.
 *
 * Values are in big-endian byte order.
 *
 */
library BytesDeserializer {

  /*
   * Extract 256-bit worth of data from the bytes stream.
   */
  function slice32(bytes b, uint offset) public pure returns (bytes32) {
    bytes32 out;

    for (uint i = 0; i < 32; i++) {
      out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
    }
    return out;
  }

  /*
   * Extract Ethereum address worth of data from the bytes stream.
   */
  function sliceAddress(bytes b, uint offset) public pure returns (address) {
    bytes32 out;

    for (uint i = 0; i < 20; i++) {
      out |= bytes32(b[offset + i] & 0xFF) >> ((i+12) * 8);
    }
    return address(uint(out));
  }

  /*
   * Extract 128-bit worth of data from the bytes stream.
   */
  function slice16(bytes b, uint offset) public pure returns (bytes16) {
    bytes16 out;

    for (uint i = 0; i < 16; i++) {
      out |= bytes16(b[offset + i] & 0xFF) >> (i * 8);
    }
    return out;
  }

  /*
   * Extract 32-bit worth of data from the bytes stream.
   */
  function slice4(bytes b, uint offset) public pure returns (bytes4) {
    bytes4 out;

    for (uint i = 0; i < 4; i++) {
      out |= bytes4(b[offset + i] & 0xFF) >> (i * 8);
    }
    return out;
  }

  /*
   * Extract 16-bit worth of data from the bytes stream.
   */
  function slice2(bytes b, uint offset) public pure returns (bytes2) {
    bytes2 out;

    for (uint i = 0; i < 2; i++) {
      out |= bytes2(b[offset + i] & 0xFF) >> (i * 8);
    }
    return out;
  }

}

// File: contracts/KYCPayloadDeserializer.sol

/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 */


/**
 * A mix-in contract to decode AML payloads.
 *
 * @notice This should be a library, but for the complexity and toolchain fragility risks involving of linking library inside library, we put this as a mix-in.
 */
contract KYCPayloadDeserializer {

  using BytesDeserializer for bytes;

  /**
   * This function takes the dataframe and unpacks it
   * We have the users ETH address for verification that they are using their own signature
   * CustomerID so we can track customer purchases
   * Min/Max ETH to invest for AML/CTF purposes - this can be supplied by the user OR by the back-end.
   */
  function getKYCPayload(bytes dataframe) public pure returns(address whitelistedAddress, uint128 customerId, uint32 minEth, uint32 maxEth) {
    address _whitelistedAddress = dataframe.sliceAddress(0);
    uint128 _customerId = uint128(dataframe.slice16(20));
    uint32 _minETH = uint32(dataframe.slice4(36));
    uint32 _maxETH = uint32(dataframe.slice4(40));
    return (_whitelistedAddress, _customerId, _minETH, _maxETH);
  }

}

// File: contracts/Ownable.sol

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

// File: contracts/ERC20Basic.sol

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

// File: contracts/SafeMath.sol

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

// File: contracts/BasicToken.sol

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

// File: contracts/ERC20.sol

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

// File: contracts/StandardToken.sol

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
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

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

// File: contracts/ReleasableToken.sol

/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 *
 * Some of this code has been updated by Pickeringware ltd to faciliatte the new solidity compilation requirements
 */

pragma solidity 0.4.21;




/**
 * Define interface for releasing the token transfer after a successful crowdsale.
 */
contract ReleasableToken is StandardToken, Ownable {

  /* The finalizer contract that allows unlift the transfer limits on this token */
  address public releaseAgent;

  /** A crowdsale contract can release us to the wild if ICO success. If false we are are in transfer lock up period.*/
  bool public released = false;

  /** Map of agents that are allowed to transfer tokens regardless of the lock down period. These are crowdsale contracts and possible the team multisig itself. */
  mapping (address => bool) public transferAgents;

  /**
   * Limit token transfer until the crowdsale is over.
   *
   */
  modifier canTransfer(address _sender) {
    if(!released) {
        if(!transferAgents[_sender]) {
            revert();
        }
    }
    _;
  }

  /**
   * Set the contract that can call release and make the token transferable.
   *
   * Design choice. Allow reset the release agent to fix fat finger mistakes.
   */
  function setReleaseAgent() onlyOwner inReleaseState(false) public {

    // We don&#39;t do interface check here as we might want to a normal wallet address to act as a release agent
    releaseAgent = owner;
  }

  /**
   * Owner can allow a particular address (a crowdsale contract) to transfer tokens despite the lock up period.
   */
  function setTransferAgent(address addr, bool state) onlyReleaseAgent inReleaseState(false) public {
    transferAgents[addr] = state;
  }

  /**
   * One way function to release the tokens to the wild.
   *
   * Can be called only from the release agent that is the final ICO contract. It is only called if the crowdsale has been success (first milestone reached).
   */
  function releaseTokenTransfer() public onlyReleaseAgent {
    released = true;
  }

  /** The function can be called only before or after the tokens have been releasesd */
  modifier inReleaseState(bool releaseState) {
    if(releaseState != released) {
        revert();
    }
    _;
  }

  /** The function can be called only by a whitelisted release agent. */
  modifier onlyReleaseAgent() {
    if(msg.sender != releaseAgent) {
        revert();
    }
    _;
  }

  function transfer(address _to, uint _value) canTransfer(msg.sender) public returns (bool success) {
    // Call StandardToken.transfer()
   return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint _value) canTransfer(_from) public returns (bool success) {
    // Call StandardToken.transferForm()
    return super.transferFrom(_from, _to, _value);
  }

}

// File: contracts/MintableToken.sol

/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 * 
 * Some of this code has been changed by Pickeringware ltd to facilitate solidities new compilation requirements
 */

contract MintableToken is ReleasableToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address _to, uint256 _amount) onlyOwner canMint public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    Mint(_to, _amount);
    Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() onlyOwner canMint public returns (bool) {
    mintingFinished = true;
    MintFinished();
    return true;
  }
}

// File: contracts/AMLToken.sol

/**
 * This contract has been written by Pickeringware ltd in some areas to facilitate custom crwodsale features
 */

pragma solidity 0.4.21;



/**
 * The AML Token
 *
 * This subset of MintableCrowdsaleToken gives the Owner a possibility to
 * reclaim tokens from a participant before the token is released
 * after a participant has failed a prolonged AML process.
 *
 * It is assumed that the anti-money laundering process depends on blockchain data.
 * The data is not available before the transaction and not for the smart contract.
 * Thus, we need to implement logic to handle AML failure cases post payment.
 * We give a time window before the token release for the token sale owners to
 * complete the AML and claw back all token transactions that were
 * caused by rejected purchases.
 */
contract AMLToken is MintableToken {

  // An event when the owner has reclaimed non-released tokens
  event ReclaimedAllAndBurned(address claimedBy, address fromWhom, uint amount);

    // An event when the owner has reclaimed non-released tokens
  event ReclaimAndBurned(address claimedBy, address fromWhom, uint amount);

  /// @dev Here the owner can reclaim the tokens from a participant if
  ///      the token is not released yet. Refund will be handled in sale contract.
  /// We also burn the tokens in the interest of economic value to the token holder
  /// @param fromWhom address of the participant whose tokens we want to claim
  function reclaimAllAndBurn(address fromWhom) public onlyReleaseAgent inReleaseState(false) {
    uint amount = balanceOf(fromWhom);    
    balances[fromWhom] = 0;
    totalSupply = totalSupply.sub(amount);
    
    ReclaimedAllAndBurned(msg.sender, fromWhom, amount);
  }

  /// @dev Here the owner can reclaim the tokens from a participant if
  ///      the token is not released yet. Refund will be handled in sale contract.
  /// We also burn the tokens in the interest of economic value to the token holder
  /// @param fromWhom address of the participant whose tokens we want to claim
  function reclaimAndBurn(address fromWhom, uint256 amount) public onlyReleaseAgent inReleaseState(false) {       
    balances[fromWhom] = balances[fromWhom].sub(amount);
    totalSupply = totalSupply.sub(amount);
    
    ReclaimAndBurned(msg.sender, fromWhom, amount);
  }
}

// File: contracts/PickToken.sol

/*
 * This token is part of Pickeringware ltds smart contracts
 * It is used to specify certain details about the token upon release
 */


contract PickToken is AMLToken {
  string public name = "AX1 Mining token";
  string public symbol = "AX1";
  uint8 public decimals = 5;
}

// File: contracts/Stoppable.sol

contract Stoppable is Ownable {
  bool public halted;

  event SaleStopped(address owner, uint256 datetime);

  modifier stopInEmergency {
    require(!halted);
    _;
  }

  function hasHalted() internal view returns (bool isHalted) {
  	return halted;
  }

   // called by the owner on emergency, triggers stopped state
  function stopICO() external onlyOwner {
    halted = true;
    SaleStopped(msg.sender, now);
  }
}

// File: contracts/Crowdsale.sol

/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale.
 * Crowdsales have a start and end timestamps, where investors can make
 * token purchases and the crowdsale will assign them tokens based
 * on a token per ETH rate. Funds collected are forwarded to a wallet
 * as they arrive.
 *
 * This base contract has been changed in certain areas by Pickeringware ltd to facilitate extra functionality
 */
contract Crowdsale is Stoppable {
  using SafeMath for uint256;

  // The token being sold
  PickToken public token;

  // start and end timestamps where investments are allowed (both inclusive)
  uint256 public startTime;
  uint256 public endTime;

  // address where funds are collected
  address public wallet;
  address public contractAddr;
  
  // how many token units a buyer gets per wei
  uint256 public rate;

  // amount of raised money in wei
  uint256 public weiRaised;
  uint256 public presaleWeiRaised;

  // amount of tokens sent
  uint256 public tokensSent;

  // These store balances of participants by ID, address and in wei, pre-sale wei and tokens
  mapping(uint128 => uint256) public balancePerID;
  mapping(address => uint256) public balanceOf;
  mapping(address => uint256) public presaleBalanceOf;
  mapping(address => uint256) public tokenBalanceOf;

  /**
   * event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount, uint256 datetime);

  /*
   * Contructor
   * This initialises the basic crowdsale data
   * It transfers ownership of this token to the chosen beneficiary 
  */
  function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, PickToken _token) public {
    require(_startTime >= now);
    require(_endTime >= _startTime);
    require(_rate > 0);
    require(_wallet != address(0));

    token = _token;
    startTime = _startTime;
    endTime = _endTime;
    rate = _rate;
    wallet = _wallet;
    transferOwnership(_wallet);
  }

  /*
   * This method has been changed by Pickeringware ltd
   * We have split this method down into overidable functions which may affect how users purchase tokens
   * We also take in a customerID (UUiD v4) which we store in our back-end in order to track users participation
  */ 
  function buyTokens(uint128 buyer) internal stopInEmergency {
    require(buyer != 0);

    uint256 weiAmount = msg.value;

    // calculate token amount to be created
    uint256 tokens = tokensToRecieve(weiAmount);

    // MUST DO REQUIRE AFTER tokens are calculated to check for cap restrictions in stages
    require(validPurchase(tokens));

    // We move the participants sliders before we mint the tokens to prevent re-entrancy
    finalizeSale(weiAmount, tokens, buyer);
    produceTokens(msg.sender, weiAmount, tokens);
  }

  // This function was created to be overridden by a parent contract
  function produceTokens(address buyer, uint256 weiAmount, uint256 tokens) internal {
    token.mint(buyer, tokens);
    TokenPurchase(msg.sender, buyer, weiAmount, tokens, now);
  }

  // This was created to be overriden by stages implementation
  // It will adjust the stage sliders accordingly if needed
  function finalizeSale(uint256 _weiAmount, uint256 _tokens, uint128 _buyer) internal {
    // Collect ETH and send them a token in return
    balanceOf[msg.sender] = balanceOf[msg.sender].add(_weiAmount);
    tokenBalanceOf[msg.sender] = tokenBalanceOf[msg.sender].add(_tokens);
    balancePerID[_buyer] = balancePerID[_buyer].add(_weiAmount);

    // update state
    weiRaised = weiRaised.add(_weiAmount);
    tokensSent = tokensSent.add(_tokens);
  }
  
  // This was created to be overridden by the stages implementation
  // Again, this is dependent on the price of tokens which may or may not be collected in stages
  function tokensToRecieve(uint256 _wei) internal view returns (uint256 tokens) {
    return _wei.div(rate);
  }

  // send ether to the fund collection wallet
  // override to create custom fund forwarding mechanisms
  function successfulWithdraw() external onlyOwner stopInEmergency {
    require(hasEnded());

    owner.transfer(weiRaised);
  }

  // @return true if the transaction can buy tokens
  // Receives tokens to send as variable for custom stage implementation
  // Has an unused variable _tokens which is necessary for capped sale implementation
  function validPurchase(uint256 _tokens) internal view returns (bool) {
    bool withinPeriod = now >= startTime && now <= endTime;
    bool nonZeroPurchase = msg.value != 0;
    return withinPeriod && nonZeroPurchase;
  }

  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    return now > endTime;
  }
}

// File: contracts/CappedCrowdsale.sol

/**
 * @title CappedCrowdsale
 * @dev Extension of Crowdsale with a max amount of funds raised
 */
contract CappedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public softCap;
  uint256 public hardCap;
  uint256 public withdrawn;
  bool public canWithdraw;
  address public beneficiary;

  event BeneficiaryWithdrawal(address admin, uint256 amount, uint256 datetime);

  // Changed implentation to include soft/hard caps
  function CappedCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _beneficiary, uint256 _softCap, uint256 _hardCap, PickToken _token) 
    Crowdsale(_startTime, _endTime, _rate, _wallet, _token)
      public {

    require(_hardCap > 0 && _softCap > 0 && _softCap < _hardCap);

    softCap = _softCap;
    hardCap = _hardCap;
    withdrawn = 0;
    canWithdraw = false;
    beneficiary = _beneficiary;
  }

  // overriding Crowdsale#validPurchase to add extra cap logic
  // @return true if investors can buy at the moment
  function validPurchase(uint256 _tokens) internal view returns (bool) {
    bool withinCap = tokensSent.add(_tokens) <= hardCap;
    return super.validPurchase(_tokens) && withinCap;
  }
  
  // overriding Crowdsale#hasEnded to add cap logic
  // @return true if crowdsale event has ended
  function hasEnded() public view returns (bool) {
    bool capReached = tokensSent >= hardCap;
    return super.hasEnded() || capReached;
  }

  // overriding Crowdsale#successfulWithdraw to add cap logic
  // only allow beneficiary to withdraw if softcap has been reached
  // Uses withdrawn incase a parent contract requires withdrawing softcap early
  function successfulWithdraw() external onlyOwner stopInEmergency {
    require(hasEnded());
    // This is used for extra functionality if necessary, i.e. KYC checks
    require(canWithdraw);
    require(tokensSent > softCap);

    uint256 withdrawalAmount = weiRaised.sub(withdrawn);

    withdrawn = withdrawn.add(withdrawalAmount);

    beneficiary.transfer(withdrawalAmount);

    BeneficiaryWithdrawal(msg.sender, withdrawalAmount, now);
  }

}

// File: contracts/SaleStagesLib.sol

/*
 * SaleStagesLib is a part of Pickeringware ltd&#39;s smart contracts
 * Its intended use is to abstract the implementation of stages away from a contract to ease deployment and codel length
 * It uses a stage struct to store specific details about each stage
 * It has several functions which are used to get/change this data
*/

library SaleStagesLib {
	using SafeMath for uint256;

	// Stores Stage implementation
	struct Stage{
        uint256 deadline;
        uint256 tokenPrice;
        uint256 tokensSold;
        uint256 minimumBuy;
        uint256 cap;
	}

	// The struct that is stored by the contract
	// Contains counter to iterate through map of stages
	struct StageStorage {
 		mapping(uint8 => Stage) stages;
 		uint8 stageCount;
	}

	// Initiliase the stagecount to 0
	function init(StageStorage storage self) public {
		self.stageCount = 0;
	}

	// Create stage adds new stage to stages map and increments stage count
	function createStage(
		StageStorage storage self, 
		uint8 _stage, 
		uint256 _deadline, 
		uint256 _price,
		uint256 _minimum,
		uint256 _cap
	) internal {
        // Ensures stages cannot overlap each other
        uint8 prevStage = _stage - 1;
        require(self.stages[prevStage].deadline < _deadline);
		
        self.stages[_stage].deadline = _deadline;
		self.stages[_stage].tokenPrice = _price;
		self.stages[_stage].tokensSold = 0;
		self.stages[_stage].minimumBuy = _minimum;
		self.stages[_stage].cap = _cap;
		self.stageCount = self.stageCount + 1;
	}

   /*
    * Crowdfund state machine management.
    *
    * We make it a function and do not assign the result to a variable, so there is no chance of the variable being stale.
    * Each one of these conditions checks if the time has passed into another stage and therefore, act as appropriate
    */
    function getStage(StageStorage storage self) public view returns (uint8 stage) {
        uint8 thisStage = self.stageCount + 1;

        for (uint8 i = 0; i < thisStage; i++) {
            if(now <= self.stages[i].deadline){
                return i;
            }
        }

        return thisStage;
    }

    // Both of the below are checked on the overridden validPurchase() function
    // Check to see if the tokens they&#39;re about to purchase is above the minimum for this stage
    function checkMinimum(StageStorage storage self, uint8 _stage, uint256 _tokens) internal view returns (bool isValid) {
    	if(_tokens < self.stages[_stage].minimumBuy){
    		return false;
    	} else {
    		return true;
    	}
    }

    // Both of the below are checked on the overridden validPurchase() function
    // Check to see if the tokens they&#39;re about to purchase is above the minimum for this stage
    function changeDeadline(StageStorage storage self, uint8 _stage, uint256 _deadline) internal {
        require(self.stages[_stage].deadline > now);
        self.stages[_stage].deadline = _deadline;
    }

    // Checks to see if the tokens they&#39;re about to purchase is below the cap for this stage
    function checkCap(StageStorage storage self, uint8 _stage, uint256 _tokens) internal view returns (bool isValid) {
    	uint256 totalTokens = self.stages[_stage].tokensSold.add(_tokens);

    	if(totalTokens > self.stages[_stage].cap){
    		return false;
    	} else {
    		return true;
    	}
    }

    // Refund a particular participant, by moving the sliders of stages he participated in
    function refundParticipant(StageStorage storage self, uint256 stage1, uint256 stage2, uint256 stage3, uint256 stage4) internal {
        self.stages[1].tokensSold = self.stages[1].tokensSold.sub(stage1);
        self.stages[2].tokensSold = self.stages[2].tokensSold.sub(stage2);
        self.stages[3].tokensSold = self.stages[3].tokensSold.sub(stage3);
        self.stages[4].tokensSold = self.stages[4].tokensSold.sub(stage4);
    }
    
	// Both of the below are checked on the overridden validPurchase() function
    // Check to see if the tokens they&#39;re about to purchase is above the minimum for this stage
    function changePrice(StageStorage storage self, uint8 _stage, uint256 _tokenPrice) internal {
        require(self.stages[_stage].deadline > now);

        self.stages[_stage].tokenPrice = _tokenPrice;
    }
}

// File: contracts/PickCrowdsale.sol

/*
 * PickCrowdsale and PickToken are a part of Pickeringware ltd&#39;s smart contracts
 * This uses the SaleStageLib which is also a part of Pickeringware ltd&#39;s smart contracts
 * We create the stages initially in the constructor such that stages cannot be added after the sale has started
 * We then pre-allocate necessary accounts prior to the sale starting
 * This contract implements the stages lib functionality with overriding functions for stages implementation
*/
contract PickCrowdsale is CappedCrowdsale {

  using SaleStagesLib for SaleStagesLib.StageStorage;
  using SafeMath for uint256;

  SaleStagesLib.StageStorage public stages;

  bool preallocated = false;
  bool stagesSet = false;
  address private founders;
  address private bounty;
  address private buyer;
  uint256 public burntBounty;
  uint256 public burntFounder;

  event ParticipantWithdrawal(address participant, uint256 amount, uint256 datetime);
  event StagePriceChanged(address admin, uint8 stage, uint256 price);
  event ExtendedStart(uint256 oldStart, uint256 newStart);

  modifier onlyOnce(bool _check) {
    if(_check) {
      revert();
    }
    _;
  }

  function PickCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _beneficiary, address _buyer, address _founders, address _bounty, uint256 _softCap, uint256 _hardCap, PickToken _token)
  	CappedCrowdsale(_startTime, _endTime, _rate, _wallet, _beneficiary, _softCap, _hardCap, _token)
     public { 
    stages.init();
    stages.createStage(0, _startTime, 0, 0, 0);
    founders = _founders;
    bounty = _bounty;
    buyer = _buyer;
  }

  function setPreallocations() external onlyOwner onlyOnce(preallocated) {
    preallocate(buyer, 1250000, 10000000000);
    preallocate(founders, 1777777, 0);
    preallocate(bounty, 444445, 0);
    preallocated = true;
  }

  function setStages() external onlyOwner onlyOnce(stagesSet) {
    stages.createStage(1, startTime.add(1 days), 10000000000, 10000000, 175000000000);  //Deadline 1 day (86400)  after start - price: 0.001  - min: 90 - cap: 1,250,000
    stages.createStage(2, startTime.add(2 days), 11000000000, 5000000, 300000000000); //Deadline 2 days (172800) after start - price: 0.0011 - min: 60 - cap: 3,000,000 
    stages.createStage(3, startTime.add(3 days), 12000000000, 2500000, 575000000000);  //Deadline 4 days (345600) after start - price: 0.0012 - cap: 5,750,000 
    stages.createStage(4, endTime, 15000000000, 1000000, 2000000000000);               //Deadline 1 week after start - price: 0.0015 - cap: 20,000,000 
    stagesSet = true;
  }

  // Creates new stage for the crowdsale
  // Can ONLY be called by the owner of the contract as should never change after creating them on initialisation
  function createStage(uint8 _stage, uint256 _deadline, uint256 _price, uint256 _minimum, uint256 _cap ) internal onlyOwner {
    stages.createStage(_stage, _deadline, _price, _minimum, _cap);
  }

  // Creates new stage for the crowdsale
  // Can ONLY be called by the owner of the contract as should never change after creating them on initialisation
  function changePrice(uint8 _stage, uint256 _price) public onlyOwner {
    stages.changePrice(_stage, _price);
    StagePriceChanged(msg.sender, _stage, _price);
  }

  // Get stage is required to rethen the stage we are currently in
  // This is necessary to check the stage details listed in the below functions
  function getStage() public view returns (uint8 stage) {
    return stages.getStage();
  }

  function getStageDeadline(uint8 _stage) public view returns (uint256 deadline) { 
    return stages.stages[_stage].deadline;
  }

  function getStageTokensSold(uint8 _stage) public view returns (uint256 sold) { 
    return stages.stages[_stage].tokensSold;
  }

  function getStageCap(uint8 _stage) public view returns (uint256 cap) { 
    return stages.stages[_stage].cap;
  }

  function getStageMinimum(uint8 _stage) public view returns (uint256 min) { 
    return stages.stages[_stage].minimumBuy;
  }

  function getStagePrice(uint8 _stage) public view returns (uint256 price) { 
    return stages.stages[_stage].tokenPrice;
  }

  // This is used for extending the sales start time (and the deadlines of each stage) accordingly
  function extendStart(uint256 _newStart) external onlyOwner {
    require(_newStart > startTime);
    require(_newStart > now); 
    require(now < startTime);

    uint256 difference = _newStart - startTime;
    uint256 oldStart = startTime;
    startTime = _newStart;
    endTime = endTime + difference;

    // Loop through every stage in the sale
    for (uint8 i = 0; i < 4; i++) {
      // Extend that stages deadline accordingly
      uint256 temp = stages.stages[i].deadline;
      temp = temp + difference;

      stages.changeDeadline(i, temp);
    }

    ExtendedStart(oldStart, _newStart);
  }

  // @Override crowdsale contract to check the current stage price
  // @return tokens investors are due to recieve
  function tokensToRecieve(uint256 _wei) internal view returns (uint256 tokens) {
    uint8 stage = getStage();
    uint256 price = getStagePrice(stage);

    return _wei.div(price);
  }

  // overriding Crowdsale validPurchase to add extra stage logic
  // @return true if investors can buy at the moment
  function validPurchase(uint256 _tokens) internal view returns (bool) {
    bool isValid = false;
    uint8 stage = getStage();

    if(stages.checkMinimum(stage, _tokens) && stages.checkCap(stage, _tokens)){
      isValid = true;
    }

    return super.validPurchase(_tokens) && isValid;
  }

  // Override crowdsale finalizeSale function to log balance change plus tokens sold in that stage
  function finalizeSale(uint256 _weiAmount, uint256 _tokens, uint128 _buyer) internal {
    // Collect ETH and send them a token in return
    balanceOf[msg.sender] = balanceOf[msg.sender].add(_weiAmount);
    tokenBalanceOf[msg.sender] = tokenBalanceOf[msg.sender].add(_tokens);
    balancePerID[_buyer] = balancePerID[_buyer].add(_weiAmount);

    // update state
    weiRaised = weiRaised.add(_weiAmount);
    tokensSent = tokensSent.add(_tokens);

    uint8 stage = getStage();
    stages.stages[stage].tokensSold = stages.stages[stage].tokensSold.add(_tokens);
  }

  /**
   * Preallocate tokens for the early investors.
   */
  function preallocate(address receiver, uint tokens, uint weiPrice) internal {
    uint decimals = token.decimals();
    uint tokenAmount = tokens * 10 ** decimals;
    uint weiAmount = weiPrice * tokens; 

    presaleWeiRaised = presaleWeiRaised.add(weiAmount);
    tokensSent = tokensSent.add(tokenAmount);
    tokenBalanceOf[receiver] = tokenBalanceOf[receiver].add(tokenAmount);

    presaleBalanceOf[receiver] = presaleBalanceOf[receiver].add(weiAmount);

    produceTokens(receiver, weiAmount, tokenAmount);
  }

  // If the sale is unsuccessful (has halted or reached deadline and didnt reach softcap)
  // Allows participants to withdraw their balance
  function unsuccessfulWithdrawal() external {
      require(balanceOf[msg.sender] > 0);
      require(hasEnded() && tokensSent < softCap || hasHalted());
      uint256 withdrawalAmount;

      withdrawalAmount = balanceOf[msg.sender];
      balanceOf[msg.sender] = 0; 

      msg.sender.transfer(withdrawalAmount);
      assert(balanceOf[msg.sender] == 0);

      ParticipantWithdrawal(msg.sender, withdrawalAmount, now);
  }

  // Burn the percentage of tokens not sold from the founders and bounty wallets
  // Must do it this way as solidity doesnt deal with decimals
  function burnFoundersTokens(uint256 _bounty, uint256 _founders) internal {
      require(_founders < 177777700000);
      require(_bounty < 44444500000);

      // Calculate the number of tokens to burn from founders and bounty wallet
      burntFounder = _founders;
      burntBounty = _bounty;

      token.reclaimAndBurn(founders, burntFounder);
      token.reclaimAndBurn(bounty, burntBounty);
  }
}

// File: contracts/KYCCrowdsale.sol

/**
 * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
 *
 * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
 *
 * Some implementation has been changed by Pickeringware ltd to achieve custom features
 */



/*
 * A crowdsale that allows only signed payload with server-side specified buy in limits.
 *
 * The token distribution happens as in the allocated crowdsale contract
 */
contract KYCCrowdsale is KYCPayloadDeserializer, PickCrowdsale {

  /* Server holds the private key to this address to decide if the AML payload is valid or not. */
  address public signerAddress;
  mapping(address => uint256) public refundable;
  mapping(address => bool) public refunded;
  mapping(address => bool) public blacklist;

  /* A new server-side signer key was set to be effective */
  event SignerChanged(address signer);
  event TokensReclaimed(address user, uint256 amount, uint256 datetime);
  event AddedToBlacklist(address user, uint256 datetime);
  event RemovedFromBlacklist(address user, uint256 datetime);
  event RefundCollected(address user, uint256 datetime);
  event TokensReleased(address agent, uint256 datetime, uint256 bounty, uint256 founders);

  /*
   * Constructor.
   */
  function KYCCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _beneficiary, address _buyer, address _founders, address _bounty, uint256 _softCap, uint256 _hardCap, PickToken _token) public
  PickCrowdsale(_startTime, _endTime, _rate, _wallet, _beneficiary, _buyer, _founders, _bounty, _softCap, _hardCap, _token)
  {}

  // This sets the token agent to the contract, allowing the contract to reclaim and burn tokens if necessary
  function setTokenAgent() external onlyOwner {
    // contractAddr = token.owner();
    // Give the sale contract rights to reclaim tokens
    token.setReleaseAgent();
  }

 /* 
  * This function was written by Pickeringware ltd to facilitate a refund action upon failure of KYC analysis
  * 
  * It simply allows the participant to withdraw his ether from the sale
  * Moves the crowdsale sliders accordingly
  * Reclaims the users tokens and burns them
  * Blacklists the user to prevent them from buying any more tokens
  *
  * Stage 1, 2, 3, & 4 are all collected from the database prior to calling this function
  * It allows us to calculate how many tokens need to be taken from each individual stage
  */
  function refundParticipant(address participant, uint256 _stage1, uint256 _stage2, uint256 _stage3, uint256 _stage4) external onlyOwner {
    require(balanceOf[participant] > 0);

    uint256 balance = balanceOf[participant];
    uint256 tokens = tokenBalanceOf[participant];

    balanceOf[participant] = 0;
    tokenBalanceOf[participant] = 0;

    // Refund the participant
    refundable[participant] = balance;

    // Move the crowdsale sliders
    weiRaised = weiRaised.sub(balance);
    tokensSent = tokensSent.sub(tokens);

    // Reclaim the participants tokens and burn them
    token.reclaimAllAndBurn(participant);

    // Blacklist participant so they cannot make further purchases
    blacklist[participant] = true;
    AddedToBlacklist(participant, now);

    stages.refundParticipant(_stage1, _stage2, _stage3, _stage4);

    TokensReclaimed(participant, tokens, now);
  }

  // Allows only the beneficiary to release tokens to people
  // This is needed as the token is owned by the contract, in order to mint tokens
  // therefore, the owner essentially gives permission for the contract to release tokens
  function releaseTokens(uint256 _bounty, uint256 _founders) onlyOwner external {
      // Unless the hardcap was reached, theremust be tokens to burn
      require(_bounty > 0 || tokensSent == hardCap);
      require(_founders > 0 || tokensSent == hardCap);

      burnFoundersTokens(_bounty, _founders);

      token.releaseTokenTransfer();

      canWithdraw = true;

      TokensReleased(msg.sender, now, _bounty, _founders);
  }
  
  // overriding Crowdsale#validPurchase to add extra KYC blacklist logic
  // @return true if investors can buy at the moment
  function validPurchase(uint256 _tokens) internal view returns (bool) {
    bool onBlackList;

    if(blacklist[msg.sender] == true){
      onBlackList = true;
    } else {
      onBlackList = false;
    }
    return super.validPurchase(_tokens) && !onBlackList;
  }

  // This is necessary for the blacklisted user to pull his ether from the contract upon being refunded
  function collectRefund() external {
    require(refundable[msg.sender] > 0);
    require(refunded[msg.sender] == false);

    uint256 theirwei = refundable[msg.sender];
    refundable[msg.sender] = 0;
    refunded[msg.sender] == true;

    msg.sender.transfer(theirwei);

    RefundCollected(msg.sender, now);
  }

  /*
   * A token purchase with anti-money laundering and KYC checks
   * This function takes in a dataframe and EC signature to verify if the purchaser has been verified
   * on the server side of our application and has therefore, participated in KYC. 
   * Upon registering to the site, users are supplied with a signature allowing them to purchase tokens, 
   * which can be revoked at any time, this containst their ETH address, a unique ID and the min and max 
   * ETH that user has stated they will purchase. (Any more than the max may be subject to AML checks).
   */
  function buyWithKYCData(bytes dataframe, uint8 v, bytes32 r, bytes32 s) public payable {

      bytes32 hash = sha256(dataframe);

      address whitelistedAddress;
      uint128 customerId;
      uint32 minETH;
      uint32 maxETH;
      
      (whitelistedAddress, customerId, minETH, maxETH) = getKYCPayload(dataframe);

      // Check that the KYC data is signed by our server
      require(ecrecover(hash, v, r, s) == signerAddress);

      // Check that the user is using his own signature
      require(whitelistedAddress == msg.sender);

      // Check they are buying within their limits - THIS IS ONLY NEEDED IF SPECIFIED BY REGULATORS
      uint256 weiAmount = msg.value;
      uint256 max = maxETH;
      uint256 min = minETH;

      require(weiAmount < (max * 1 ether));
      require(weiAmount > (min * 1 ether));

      buyTokens(customerId);
  }  

  /// @dev This function can set the server side address
  /// @param _signerAddress The address derived from server&#39;s private key
  function setSignerAddress(address _signerAddress) external onlyOwner {
    // EC rcover returns 0 in case of error therefore, this CANNOT be 0.
    require(_signerAddress != 0);
    signerAddress = _signerAddress;
    SignerChanged(signerAddress);
  }

  function removeFromBlacklist(address _blacklisted) external onlyOwner {
    require(blacklist[_blacklisted] == true);
    blacklist[_blacklisted] = false;
    RemovedFromBlacklist(_blacklisted, now);
  }

}