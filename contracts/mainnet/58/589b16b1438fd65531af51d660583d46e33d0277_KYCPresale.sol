/**
   * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
   *
   * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
   */
  
  
  /**
   * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
   *
   * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
   */
  
  
  
  
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
  
  
  /*
   * Haltable
   *
   * Abstract contract that allows children to implement an
   * emergency stop mechanism. Differs from Pausable by causing a throw when in halt mode.
   *
   *
   * Originally envisioned in FirstBlood ICO contract.
   */
  contract Haltable is Ownable {
    bool public halted;
  
    modifier stopInEmergency {
      if (halted) throw;
      _;
    }
  
    modifier stopNonOwnersInEmergency {
      if (halted && msg.sender != owner) throw;
      _;
    }
  
    modifier onlyInEmergency {
      if (!halted) throw;
      _;
    }
  
    // called by the owner on emergency, triggers stopped state
    function halt() external onlyOwner {
      halted = true;
    }
  
    // called by the owner on end of emergency, returns to normal state
    function unhalt() external onlyOwner onlyInEmergency {
      halted = false;
    }
  
  }
  
  /**
   * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
   *
   * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
   */
  
  
  /**
   * Safe unsigned safe math.
   *
   * https://blog.aragon.one/library-driven-development-in-solidity-2bebcaf88736#.750gwtwli
   *
   * Originally from https://raw.githubusercontent.com/AragonOne/zeppelin-solidity/master/contracts/SafeMathLib.sol
   *
   * Maintained here until merged to mainline zeppelin-solidity.
   *
   */
  library SafeMathLib {
  
    function times(uint a, uint b) returns (uint) {
      uint c = a * b;
      assert(a == 0 || c / a == b);
      return c;
    }
  
    function minus(uint a, uint b) returns (uint) {
      assert(b <= a);
      return a - b;
    }
  
    function plus(uint a, uint b) returns (uint) {
      uint c = a + b;
      assert(c>=a);
      return c;
    }
  
  }
  
  /**
   * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
   *
   * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
   */
  
  
  
  
  
  /**
   * @title ERC20Basic
   * @dev Simpler version of ERC20 interface
   * @dev see https://github.com/ethereum/EIPs/issues/179
   */
  contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
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
   * A token that defines fractional units as decimals.
   */
  contract FractionalERC20 is ERC20 {
  
    uint public decimals;
  
  }
  
  /**
   * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
   *
   * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
   */
  
  
  /**
   * Interface for defining crowdsale pricing.
   */
  contract PricingStrategy {
  
    /** Interface declaration. */
    function isPricingStrategy() public constant returns (bool) {
      return true;
    }
  
    /** Self check if all references are correctly set.
     *
     * Checks that pricing strategy matches crowdsale parameters.
     */
    function isSane(address crowdsale) public constant returns (bool) {
      return true;
    }
  
    /**
     * @dev Pricing tells if this is a presale purchase or not.
       @param purchaser Address of the purchaser
       @return False by default, true if a presale purchaser
     */
    function isPresalePurchase(address purchaser) public constant returns (bool) {
      return false;
    }
  
    /**
     * When somebody tries to buy tokens for X eth, calculate how many tokens they get.
     *
     *
     * @param value - What is the value of the transaction send in as wei
     * @param tokensSold - how much tokens have been sold this far
     * @param weiRaised - how much money has been raised this far in the main token sale - this number excludes presale
     * @param msgSender - who is the investor of this transaction
     * @param decimals - how many decimal units the token has
     * @return Amount of tokens the investor receives
     */
    function calculatePrice(uint value, uint weiRaised, uint tokensSold, address msgSender, uint decimals) public constant returns (uint tokenAmount);
  }
  
  /**
   * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
   *
   * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
   */
  
  
  /**
   * Finalize agent defines what happens at the end of succeseful crowdsale.
   *
   * - Allocate tokens for founders, bounties and community
   * - Make tokens transferable
   * - etc.
   */
  contract FinalizeAgent {
  
    function isFinalizeAgent() public constant returns(bool) {
      return true;
    }
  
    /** Return true if we can run finalizeCrowdsale() properly.
     *
     * This is a safety check function that doesn&#39;t allow crowdsale to begin
     * unless the finalizer has been set up properly.
     */
    function isSane() public constant returns (bool);
  
    /** Called once by crowdsale finalize() if the sale was success. */
    function finalizeCrowdsale();
  
  }
  
  
  
  /**
   * Crowdsale state machine without buy functionality.
   *
   * Implements basic state machine logic, but leaves out all buy functions,
   * so that subclasses can implement their own buying logic.
   *
   *
   * For the default buy() implementation see Crowdsale.sol.
   */
  contract CrowdsaleBase is Haltable {
  
    /* Max investment count when we are still allowed to change the multisig address */
    uint public MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE = 5;
  
    using SafeMathLib for uint;
  
    /* The token we are selling */
    FractionalERC20 public token;
  
    /* How we are going to price our offering */
    PricingStrategy public pricingStrategy;
  
    /* Post-success callback */
    FinalizeAgent public finalizeAgent;
  
    /* tokens will be transfered from this address */
    address public multisigWallet;
  
    /* if the funding goal is not reached, investors may withdraw their funds */
    uint public minimumFundingGoal;
  
    /* the UNIX timestamp start date of the crowdsale */
    uint public startsAt;
  
    /* the UNIX timestamp end date of the crowdsale */
    uint public endsAt;
  
    /* the number of tokens already sold through this contract*/
    uint public tokensSold = 0;
  
    /* How many wei of funding we have raised */
    uint public weiRaised = 0;
  
    /* Calculate incoming funds from presale contracts and addresses */
    uint public presaleWeiRaised = 0;
  
    /* How many distinct addresses have invested */
    uint public investorCount = 0;
  
    /* How much wei we have returned back to the contract after a failed crowdfund. */
    uint public loadedRefund = 0;
  
    /* How much wei we have given back to investors.*/
    uint public weiRefunded = 0;
  
    /* Has this crowdsale been finalized */
    bool public finalized;
  
    /** How much ETH each address has invested to this crowdsale */
    mapping (address => uint256) public investedAmountOf;
  
    /** How much tokens this crowdsale has credited for each investor address */
    mapping (address => uint256) public tokenAmountOf;
  
    /** Addresses that are allowed to invest even before ICO offical opens. For testing, for ICO partners, etc. */
    mapping (address => bool) public earlyParticipantWhitelist;
  
    /** This is for manul testing for the interaction from owner wallet. You can set it to any value and inspect this in blockchain explorer to see that crowdsale interaction works. */
    uint public ownerTestValue;
  
    /** State machine
     *
     * - Preparing: All contract initialization calls and variables have not been set yet
     * - Prefunding: We have not passed start time yet
     * - Funding: Active crowdsale
     * - Success: Minimum funding goal reached
     * - Failure: Minimum funding goal not reached before ending time
     * - Finalized: The finalized has been called and succesfully executed
     * - Refunding: Refunds are loaded on the contract for reclaim.
     */
    enum State{Unknown, Preparing, PreFunding, Funding, Success, Failure, Finalized, Refunding}
  
    // A new investment was made
    event Invested(address investor, uint weiAmount, uint tokenAmount, uint128 customerId);
  
    // Refund was processed for a contributor
    event Refund(address investor, uint weiAmount);
  
    // The rules were changed what kind of investments we accept
    event InvestmentPolicyChanged(bool newRequireCustomerId, bool newRequiredSignedAddress, address newSignerAddress);
  
    // Address early participation whitelist status changed
    event Whitelisted(address addr, bool status);
  
    // Crowdsale end time has been changed
    event EndsAtChanged(uint newEndsAt);
  
    function CrowdsaleBase(address _token, PricingStrategy _pricingStrategy, address _multisigWallet, uint _start, uint _end, uint _minimumFundingGoal) {
  
      owner = msg.sender;
  
      token = FractionalERC20(_token);
      setPricingStrategy(_pricingStrategy);
  
      multisigWallet = _multisigWallet;
      if(multisigWallet == 0) {
          throw;
      }
  
      if(_start == 0) {
          throw;
      }
  
      startsAt = _start;
  
      if(_end == 0) {
          throw;
      }
  
      endsAt = _end;
  
      // Don&#39;t mess the dates
      if(startsAt >= endsAt) {
          throw;
      }
  
      // Minimum funding goal can be zero
      minimumFundingGoal = _minimumFundingGoal;
    }
  
    /**
     * Don&#39;t expect to just send in money and get tokens.
     */
    function() payable {
      throw;
    }
  
    /**
     * Make an investment.
     *
     * Crowdsale must be running for one to invest.
     * We must have not pressed the emergency brake.
     *
     * @param receiver The Ethereum address who receives the tokens
     * @param customerId (optional) UUID v4 to track the successful payments on the server side&#39;
     *
     * @return tokenAmount How mony tokens were bought
     */
    function investInternal(address receiver, uint128 customerId) stopInEmergency internal returns(uint tokensBought) {
  
      // Determine if it&#39;s a good time to accept investment from this participant
      if(getState() == State.PreFunding) {
        // Are we whitelisted for early deposit
        if(!earlyParticipantWhitelist[receiver]) {
          throw;
        }
      } else if(getState() == State.Funding) {
        // Retail participants can only come in when the crowdsale is running
        // pass
      } else {
        // Unwanted state
        throw;
      }
  
      uint weiAmount = msg.value;
  
      // Account presale sales separately, so that they do not count against pricing tranches
      uint tokenAmount = pricingStrategy.calculatePrice(weiAmount, weiRaised - presaleWeiRaised, tokensSold, msg.sender, token.decimals());
  
      // Dust transaction
      require(tokenAmount != 0);
  
      if(investedAmountOf[receiver] == 0) {
         // A new investor
         investorCount++;
      }
  
      // Update investor
      investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
      tokenAmountOf[receiver] = tokenAmountOf[receiver].plus(tokenAmount);
  
      // Update totals
      weiRaised = weiRaised.plus(weiAmount);
      tokensSold = tokensSold.plus(tokenAmount);
  
      if(pricingStrategy.isPresalePurchase(receiver)) {
          presaleWeiRaised = presaleWeiRaised.plus(weiAmount);
      }
  
      // Check that we did not bust the cap
      require(!isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold));
  
      assignTokens(receiver, tokenAmount);
  
      // Pocket the money, or fail the crowdsale if we for some reason cannot send the money to our multisig
      if(!multisigWallet.send(weiAmount)) throw;
  
      // Tell us invest was success
      Invested(receiver, weiAmount, tokenAmount, customerId);
  
      return tokenAmount;
    }
  
    /**
     * Finalize a succcesful crowdsale.
     *
     * The owner can triggre a call the contract that provides post-crowdsale actions, like releasing the tokens.
     */
    function finalize() public inState(State.Success) onlyOwner stopInEmergency {
  
      // Already finalized
      if(finalized) {
        throw;
      }
  
      // Finalizing is optional. We only call it if we are given a finalizing agent.
      if(address(finalizeAgent) != 0) {
        finalizeAgent.finalizeCrowdsale();
      }
  
      finalized = true;
    }
  
    /**
     * Allow to (re)set finalize agent.
     *
     * Design choice: no state restrictions on setting this, so that we can fix fat finger mistakes.
     */
    function setFinalizeAgent(FinalizeAgent addr) onlyOwner {
      finalizeAgent = addr;
  
      // Don&#39;t allow setting bad agent
      if(!finalizeAgent.isFinalizeAgent()) {
        throw;
      }
    }
  
    /**
     * Allow crowdsale owner to close early or extend the crowdsale.
     *
     * This is useful e.g. for a manual soft cap implementation:
     * - after X amount is reached determine manual closing
     *
     * This may put the crowdsale to an invalid state,
     * but we trust owners know what they are doing.
     *
     */
    function setEndsAt(uint time) onlyOwner {
  
      if(now > time) {
        throw; // Don&#39;t change past
      }
  
      if(startsAt > time) {
        throw; // Prevent human mistakes
      }
  
      endsAt = time;
      EndsAtChanged(endsAt);
    }
  
    /**
     * Allow to (re)set pricing strategy.
     *
     * Design choice: no state restrictions on the set, so that we can fix fat finger mistakes.
     */
    function setPricingStrategy(PricingStrategy _pricingStrategy) onlyOwner {
      pricingStrategy = _pricingStrategy;
  
      // Don&#39;t allow setting bad agent
      if(!pricingStrategy.isPricingStrategy()) {
        throw;
      }
    }
  
    /**
     * Allow to change the team multisig address in the case of emergency.
     *
     * This allows to save a deployed crowdsale wallet in the case the crowdsale has not yet begun
     * (we have done only few test transactions). After the crowdsale is going
     * then multisig address stays locked for the safety reasons.
     */
    function setMultisig(address addr) public onlyOwner {
  
      // Change
      if(investorCount > MAX_INVESTMENTS_BEFORE_MULTISIG_CHANGE) {
        throw;
      }
  
      multisigWallet = addr;
    }
  
    /**
     * Allow load refunds back on the contract for the refunding.
     *
     * The team can transfer the funds back on the smart contract in the case the minimum goal was not reached..
     */
    function loadRefund() public payable inState(State.Failure) {
      if(msg.value == 0) throw;
      loadedRefund = loadedRefund.plus(msg.value);
    }
  
    /**
     * Investors can claim refund.
     *
     * Note that any refunds from proxy buyers should be handled separately,
     * and not through this contract.
     */
    function refund() public inState(State.Refunding) {
      uint256 weiValue = investedAmountOf[msg.sender];
      if (weiValue == 0) throw;
      investedAmountOf[msg.sender] = 0;
      weiRefunded = weiRefunded.plus(weiValue);
      Refund(msg.sender, weiValue);
      if (!msg.sender.send(weiValue)) throw;
    }
  
    /**
     * @return true if the crowdsale has raised enough money to be a successful.
     */
    function isMinimumGoalReached() public constant returns (bool reached) {
      return weiRaised >= minimumFundingGoal;
    }
  
    /**
     * Check if the contract relationship looks good.
     */
    function isFinalizerSane() public constant returns (bool sane) {
      return finalizeAgent.isSane();
    }
  
    /**
     * Check if the contract relationship looks good.
     */
    function isPricingSane() public constant returns (bool sane) {
      return pricingStrategy.isSane(address(this));
    }
  
    /**
     * Crowdfund state machine management.
     *
     * We make it a function and do not assign the result to a variable, so there is no chance of the variable being stale.
     */
    function getState() public constant returns (State) {
      if(finalized) return State.Finalized;
      else if (address(finalizeAgent) == 0) return State.Preparing;
      else if (!finalizeAgent.isSane()) return State.Preparing;
      else if (!pricingStrategy.isSane(address(this))) return State.Preparing;
      else if (block.timestamp < startsAt) return State.PreFunding;
      else if (block.timestamp <= endsAt && !isCrowdsaleFull()) return State.Funding;
      else if (isMinimumGoalReached()) return State.Success;
      else if (!isMinimumGoalReached() && weiRaised > 0 && loadedRefund >= weiRaised) return State.Refunding;
      else return State.Failure;
    }
  
    /** This is for manual testing of multisig wallet interaction */
    function setOwnerTestValue(uint val) onlyOwner {
      ownerTestValue = val;
    }
  
    /**
     * Allow addresses to do early participation.
     *
     * TODO: Fix spelling error in the name
     */
    function setEarlyParicipantWhitelist(address addr, bool status) onlyOwner {
      earlyParticipantWhitelist[addr] = status;
      Whitelisted(addr, status);
    }
  
  
    /** Interface marker. */
    function isCrowdsale() public constant returns (bool) {
      return true;
    }
  
    //
    // Modifiers
    //
  
    /** Modified allowing execution only if the crowdsale is currently running.  */
    modifier inState(State state) {
      if(getState() != state) throw;
      _;
    }
  
  
    //
    // Abstract functions
    //
  
    /**
     * Check if the current invested breaks our cap rules.
     *
     *
     * The child contract must define their own cap setting rules.
     * We allow a lot of flexibility through different capping strategies (ETH, token count)
     * Called from invest().
     *
     * @param weiAmount The amount of wei the investor tries to invest in the current transaction
     * @param tokenAmount The amount of tokens we try to give to the investor in the current transaction
     * @param weiRaisedTotal What would be our total raised balance after this transaction
     * @param tokensSoldTotal What would be our total sold tokens count after this transaction
     *
     * @return true if taking this investment would break our cap rules
     */
    function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken);
  
    /**
     * Check if the current crowdsale is full and we can no longer sell any tokens.
     */
    function isCrowdsaleFull() public constant returns (bool);
  
    /**
     * Create new tokens or transfer issued tokens to the investor depending on the cap model.
     */
    function assignTokens(address receiver, uint tokenAmount) internal;
  }
  
  /**
   * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
   *
   * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
   */
  
  
  /**
   * This smart contract code is Copyright 2017 TokenMarket Ltd. For more information see https://tokenmarket.net
   *
   * Licensed under the Apache License, version 2.0: https://github.com/TokenMarketNet/ico/blob/master/LICENSE.txt
   */
  
  /**
   * Deserialize bytes payloads.
   *
   * Values are in big-endian byte order.
   *
   */
  library BytesDeserializer {
  
    /**
     * Extract 256-bit worth of data from the bytes stream.
     */
    function slice32(bytes b, uint offset) constant returns (bytes32) {
      bytes32 out;
  
      for (uint i = 0; i < 32; i++) {
        out |= bytes32(b[offset + i] & 0xFF) >> (i * 8);
      }
      return out;
    }
  
    /**
     * Extract Ethereum address worth of data from the bytes stream.
     */
    function sliceAddress(bytes b, uint offset) constant returns (address) {
      bytes32 out;
  
      for (uint i = 0; i < 20; i++) {
        out |= bytes32(b[offset + i] & 0xFF) >> ((i+12) * 8);
      }
      return address(uint(out));
    }
  
    /**
     * Extract 128-bit worth of data from the bytes stream.
     */
    function slice16(bytes b, uint offset) constant returns (bytes16) {
      bytes16 out;
  
      for (uint i = 0; i < 16; i++) {
        out |= bytes16(b[offset + i] & 0xFF) >> (i * 8);
      }
      return out;
    }
  
    /**
     * Extract 32-bit worth of data from the bytes stream.
     */
    function slice4(bytes b, uint offset) constant returns (bytes4) {
      bytes4 out;
  
      for (uint i = 0; i < 4; i++) {
        out |= bytes4(b[offset + i] & 0xFF) >> (i * 8);
      }
      return out;
    }
  
    /**
     * Extract 16-bit worth of data from the bytes stream.
     */
    function slice2(bytes b, uint offset) constant returns (bytes2) {
      bytes2 out;
  
      for (uint i = 0; i < 2; i++) {
        out |= bytes2(b[offset + i] & 0xFF) >> (i * 8);
      }
      return out;
    }
  
  
  
  }
  
  
  /**
   * A mix-in contract to decode different signed KYC payloads.
   *
   * @notice This should be a library, but for the complexity and toolchain fragility risks involving of linking library inside library, we currently use this as a helper method mix-in.
   */
  contract KYCPayloadDeserializer {
  
    using BytesDeserializer for bytes;
  
    // @notice this struct describes what kind of data we include in the payload, we do not use this directly
    // The bytes payload set on the server side
    // total 56 bytes
    struct KYCPayload {
  
      /** Customer whitelisted address where the deposit can come from */
      address whitelistedAddress; // 20 bytes
  
      /** Customer id, UUID v4 */
      uint128 customerId; // 16 bytes
  
      /**
       * Min amount this customer needs to invest in ETH. Set zero if no minimum. Expressed as parts of 10000. 1 ETH = 10000.
       * @notice Decided to use 32-bit words to make the copy-pasted Data field for the ICO transaction less lenghty.
       */
      uint32 minETH; // 4 bytes
  
      /** Max amount this customer can to invest in ETH. Set zero if no maximum. Expressed as parts of 10000. 1 ETH = 10000. */
      uint32 maxETH; // 4 bytes
  
      /**
       * Information about the price promised for this participant. It can be pricing tier id or directly one token price in weis.
       * @notice This is a later addition and not supported in all scenarios yet.
       */
      uint256 pricingInfo;
    }
  
    /**
     * Same as above, does not seem to cause any issue.
     */
    function getKYCPayload(bytes dataframe) public constant returns(address whitelistedAddress, uint128 customerId, uint32 minEth, uint32 maxEth) {
      address _whitelistedAddress = dataframe.sliceAddress(0);
      uint128 _customerId = uint128(dataframe.slice16(20));
      uint32 _minETH = uint32(dataframe.slice4(36));
      uint32 _maxETH = uint32(dataframe.slice4(40));
      return (_whitelistedAddress, _customerId, _minETH, _maxETH);
    }
  
    /**
     * Same as above, but with pricing information included in the payload as the last integer.
     *
     * @notice In a long run, deprecate the legacy methods above and only use this payload.
     */
    function getKYCPresalePayload(bytes dataframe) public constant returns(address whitelistedAddress, uint128 customerId, uint32 minEth, uint32 maxEth, uint256 pricingInfo) {
      address _whitelistedAddress = dataframe.sliceAddress(0);
      uint128 _customerId = uint128(dataframe.slice16(20));
      uint32 _minETH = uint32(dataframe.slice4(36));
      uint32 _maxETH = uint32(dataframe.slice4(40));
      uint256 _pricingInfo = uint256(dataframe.slice32(44));
      return (_whitelistedAddress, _customerId, _minETH, _maxETH, _pricingInfo);
    }
  
  }
  
  
  /**
   * A presale smart contract that collects money from SAFT/SAFTE agreed buyers.
   *
   * Presale contract where we collect money for the token that does not exist yet.
   * The same KYC rules apply as in KYCCrowdsale. No tokens are issued in this point,
   * but they are delivered to the buyers after the token sale is over.
   *
   */
  contract KYCPresale is CrowdsaleBase, KYCPayloadDeserializer {
  
    /** The cap of this presale contract in wei */
    uint256 public saleWeiCap;
  
    /** Server holds the private key to this address to decide if the AML payload is valid or not. */
    address public signerAddress;
  
    /** A new server-side signer key was set to be effective */
    event SignerChanged(address signer);
  
    /** An user made a prepurchase through KYC&#39;ed interface. The money has been moved to the token sale multisig wallet. The buyer will receive their tokens in an airdrop after the token sale is over. */
    event Prepurchased(address investor, uint weiAmount, uint tokenAmount, uint128 customerId, uint256 pricingInfo);
  
    /** The owner changes the presale ETH cap during the sale */
    event CapUpdated(uint256 newCap);
  
    /**
     * Constructor.
     *
     * Presale does not know about token or pricing strategy, as they will be only available during the future airdrop.
     *
     * @dev The parent contract has some unnecessary variables for our use case. For this round of development, we chose to use null value for token and pricing strategy. In the future versions have a parent sale contract that does not assume an existing token.
     */
    function KYCPresale(address _multisigWallet, uint _start, uint _end, uint _saleWeiCap) CrowdsaleBase(FractionalERC20(address(1)), PricingStrategy(address(0)), _multisigWallet, _start, _end, 0) {
      saleWeiCap = _saleWeiCap;
    }
  
    /**
     * A token purchase with anti-money laundering
     *
     * &#169;return tokenAmount How many tokens where bought
     */
    function buyWithKYCData(bytes dataframe, uint8 v, bytes32 r, bytes32 s) public payable returns(uint tokenAmount) {
  
      // Presale ended / emergency abort
      require(!halted);
  
      bytes32 hash = sha256(dataframe);
      var (whitelistedAddress, customerId, minETH, maxETH, pricingInfo) = getKYCPresalePayload(dataframe);
      uint multiplier = 10 ** 18;
      address receiver = msg.sender;
      uint weiAmount = msg.value;
  
      // The payload was created by token sale server
      require(ecrecover(hash, v, r, s) == signerAddress);
  
      // Determine if it&#39;s a good time to accept investment from this participant
      if(getState() == State.PreFunding) {
        // Are we whitelisted for early deposit
        require(earlyParticipantWhitelist[receiver]);
      } else if(getState() == State.Funding) {
        // Retail participants can only come in when the crowdsale is running
        // pass
      } else {
        // Unwanted state
        revert;
      }
  
      if(investedAmountOf[receiver] == 0) {
         // A new investor
         investorCount++;
      }
  
      // Update per investor amount
      investedAmountOf[receiver] = investedAmountOf[receiver].plus(weiAmount);
  
      // Update totals
      weiRaised = weiRaised.plus(weiAmount);
  
      // Check that we did not bust the cap
      require(!isBreakingCap(weiAmount, tokenAmount, weiRaised, tokensSold));
  
      require(investedAmountOf[msg.sender] >= minETH * multiplier / 10000);
      require(investedAmountOf[msg.sender] <= maxETH * multiplier / 10000);
  
      // Pocket the money, or fail the crowdsale if we for some reason cannot send the money to our multisig
      require(multisigWallet.send(weiAmount));
  
      // Tell us invest was success
      Prepurchased(receiver, weiAmount, tokenAmount, customerId, pricingInfo);
  
      return 0; // In presale we do not issue actual tokens tyet
    }
  
    /// @dev This function can set the server side address
    /// @param _signerAddress The address derived from server&#39;s private key
    function setSignerAddress(address _signerAddress) onlyOwner {
      signerAddress = _signerAddress;
      SignerChanged(signerAddress);
    }
  
    /**
     * Called from invest() to confirm if the curret investment does not break our cap rule.
     */
    function isBreakingCap(uint weiAmount, uint tokenAmount, uint weiRaisedTotal, uint tokensSoldTotal) constant returns (bool limitBroken) {
      if(weiRaisedTotal > saleWeiCap) {
        return true;
      } else {
        return false;
      }
    }
  
    /**
     * We are sold out when our approve pool becomes empty.
     */
    function isCrowdsaleFull() public constant returns (bool) {
      return weiRaised >= saleWeiCap;
    }
  
    /**
     * Allow owner to adjust the cap during the presale.
     *
     * This allows e.g. US dollar pegged caps.
     */
    function setWeiCap(uint newCap) public onlyOwner {
      saleWeiCap = newCap;
      CapUpdated(newCap);
    }
  
    /**
     * Because this is a presale, we do not issue any tokens yet.
     *
     * @dev Have this taken away from the parent contract?
     */
    function assignTokens(address receiver, uint tokenAmount) internal {
      revert;
    }
  
    /**
     * Allow to (re)set pricing strategy.
     *
     * @dev Because we do not have token price set in presale, we do nothing. This will be removed in the future versions.
     */
    function setPricingStrategy(PricingStrategy _pricingStrategy) onlyOwner {
    }
  
    /**
     * Presale state machine management.
     *
     * Presale cannot fail; it is running until manually ended.
     *
     */
    function getState() public constant returns (State) {
      if (block.timestamp < startsAt) {
        return State.PreFunding;
      } else {
        return State.Funding;
      }
    }
  
  }