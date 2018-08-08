pragma solidity ^0.4.21;

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

contract SafeMath {
  function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal pure returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal pure returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal pure returns (uint256) {
    return a < b ? a : b;
  }

  function toWei(uint256 a) internal pure returns (uint256){
    assert(a>0);
    return a * 10 ** 18;
  }
}

interface tokenRecipient { 
    function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; 
}

contract TokenERC20 is SafeMath{

    // Token information
    // Public variables of the token
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;


    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract
     */
    constructor(string _name, string _symbol, uint8 _decimals, uint256 _totalSupply) public {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply * 10 ** uint256(decimals);
    }

    /**
     * Internal transfer, only can be called by this contract
     */
    function _transfer(address _from, address _to, uint _value) internal {
        // Prevent transfer to 0x0 address. Use burn() instead
        require(_to != 0x0);
        // Check if the sender has enough
        require(balanceOf[_from] >= _value);
        // Check for overflows
        require(safeAdd(balanceOf[_to], _value) > balanceOf[_to]);
        // Save this for an assertion in the future
        uint previousBalances = safeAdd(balanceOf[_from],balanceOf[_to]);
        // Subtract from the sender
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        // Add the same to the recipient
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        emit Transfer(_from, _to, _value);
        // Asserts are used to use static analysis to find bugs in your code. They should never fail
        assert(safeAdd(balanceOf[_from],balanceOf[_to]) == previousBalances);
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` in behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender],_value);
        _transfer(_from, _to, _value);
        return true;
    }
      
    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }

    /**
     * Set allowance for other address and notify
     *
     * Allows `_spender` to spend no more than `_value` tokens in your behalf, and then ping the contract about it
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     * @param _extraData some extra information to send to the approved contract
     */
    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   // Check if the sender has enough
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);            // Subtract from the sender
        totalSupply = safeSub(totalSupply,_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= allowance[_from][msg.sender]);    // Check allowance
        balanceOf[_from] = safeSub(balanceOf[_from], _value);                         // Subtract from the targeted balance
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);             // Subtract from the sender&#39;s allowance
        totalSupply = safeSub(totalSupply,_value);                              // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }
}

/******************************************/
/*          GAMEREWARD TOKEN              */
/******************************************/

contract GameRewardToken is owned, TokenERC20 {

    // State machine
    enum State{PrivateFunding, PreFunding, Funding, Success, Failure}


    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public bounties;
    mapping (address => uint256) public bonus;
    mapping (address => address) public referrals;
    mapping (address => uint256) public investors;
    mapping (address => uint256) public funders;

    /* This generates a public event on the blockchain that will notify clients */
    event FrozenFunds(address indexed target, bool frozen);
    event FundTransfer(address indexed to, uint256 eth , uint256 value, uint block);
    event Fee(address indexed from, address indexed collector, uint256 fee);
    event FreeDistribution(address indexed to, uint256 value, uint block);
    event Refund(address indexed to, uint256 value, uint block);
    event BonusTransfer(address indexed to, uint256 value, uint block);
    event BountyTransfer(address indexed to, uint256 value, uint block);
    event SetReferral(address indexed target, address indexed broker);
    event ChangeCampaign(uint256 fundingStartBlock, uint256 fundingEndBlock);
    event AddBounty(address indexed bountyHunter, uint256 value);
    event ReferralBonus(address indexed investor, address indexed broker, uint256 value);

     // Crowdsale information
    bool public finalizedCrowdfunding = false;

    uint256 public fundingStartBlock = 0; // crowdsale start block
    uint256 public fundingEndBlock = 0;   // crowdsale end block
    uint256 public constant lockedTokens =                250000000*10**18; //25% tokens to Vault and locked for 6 months - 250 millions
    uint256 public bonusAndBountyTokens =                  50000000*10**18; //5% tokens for referral bonus and bounty - 50 millions
    uint256 public constant devsTokens =                  100000000*10**18; //10% tokens for team - 100 millions
    uint256 public constant hundredPercent =                           100;
    uint256 public constant tokensPerEther =                         20000; //GRD:ETH exchange rate - 20.000 GRD per ETH
    uint256 public constant tokenCreationMax =            600000000*10**18; //ICO hard target - 600 millions
    uint256 public constant tokenCreationMin =             60000000*10**18; //ICO soft target - 60 millions

    uint256 public constant tokenPrivateMax =             100000000*10**18; //Private-sale must stop when 100 millions tokens sold

    uint256 public constant minContributionAmount =             0.1*10**18; //Investor must buy atleast 0.1ETH in open-sale
    uint256 public constant maxContributionAmount =             100*10**18; //Max 100 ETH in open-sale and pre-sale

    uint256 public constant minPrivateContribution =              5*10**18; //Investor must buy atleast 5ETH in private-sale
    uint256 public constant minPreContribution =                  1*10**18; //Investor must buy atleast 1ETH in pre-sale

    uint256 public constant minAmountToGetBonus =                 1*10**18; //Investor must buy atleast 1ETH to receive referral bonus
    uint256 public constant referralBonus =                              5; //5% for referral bonus
    uint256 public constant privateBonus =                              40; //40% bonus in private-sale
    uint256 public constant preBonus =                                  20; //20% bonus in pre-sale;

    uint256 public tokensSold;
    uint256 public collectedETH;

    uint256 public constant numBlocksLocked = 1110857;  //180 days locked vault tokens
    bool public releasedBountyTokens = false; //bounty release status
    uint256 public unlockedAtBlockNumber;

    address public lockedTokenHolder;
    address public releaseTokenHolder;
    address public devsHolder;
    address public multiSigWalletAddress;


    constructor(address _lockedTokenHolder,
                address _releaseTokenHolder,
                address _devsAddress,
                address _multiSigWalletAddress
    ) TokenERC20("GameReward", // Name
                 "GRD",        // Symbol 
                  18,          // Decimals
                  1000000000   // Total Supply 1 Billion
                  ) public {
        
        require (_lockedTokenHolder != 0x0);
        require (_releaseTokenHolder != 0x0);
        require (_devsAddress != 0x0);
        require (_multiSigWalletAddress != 0x0);
        lockedTokenHolder = _lockedTokenHolder;
        releaseTokenHolder = _releaseTokenHolder;
        devsHolder = _devsAddress;
        multiSigWalletAddress = _multiSigWalletAddress;
    }

    /* Internal transfer, only can be called by this contract */
    function _transfer(address _from, address _to, uint _value) internal {
        require (getState() == State.Success);
        require (_to != 0x0);                                      // Prevent transfer to 0x0 address. Use burn() instead
        require (balanceOf[_from] >= _value);                      // Prevent transfer to 0x0 address. Use burn() instead
        require (safeAdd(balanceOf[_to],_value) > balanceOf[_to]); // Check for overflows
        require (!frozenAccount[_from]);                           // Check if sender is frozen
        require (!frozenAccount[_to]);                             // Check if recipient is frozen
        require (_from != lockedTokenHolder);
        balanceOf[_from] = safeSub(balanceOf[_from],_value);       // Subtract from the sender
        balanceOf[_to] = safeAdd(balanceOf[_to],_value);           // Add the same to the recipient
        emit Transfer(_from, _to, _value);
    }

    ///@notice change token&#39;s name and symbol
    function updateNameAndSymbol(string _newname, string _newsymbol) onlyOwner public{
      name = _newname;
      symbol = _newsymbol;
    }

    /// @notice `freeze? Prevent | Allow` `target` from sending & receiving tokens
    /// @param _target Address to be frozen
    /// @param _freeze either to freeze it or not
    function freezeAccount(address _target, bool _freeze) onlyOwner public {
        frozenAccount[_target] = _freeze;
        emit FrozenFunds(_target, _freeze);
    }

    function setMultiSigWallet(address newWallet) external {
        require (msg.sender == multiSigWalletAddress);
        multiSigWalletAddress = newWallet;
    }

    //Crowdsale Functions

    /// @notice get early bonus for Investor
    function _getEarlyBonus() internal view returns(uint){
        if(getState()==State.PrivateFunding) return privateBonus;  
        else if(getState()==State.PreFunding) return preBonus; 
        else return 0;
    }

    /// @notice set start and end block for funding
    /// @param _fundingStartBlock start funding
    /// @param _fundingEndBlock  end funding
    function setCampaign(uint256 _fundingStartBlock, uint256 _fundingEndBlock) onlyOwner public{
        if(block.number < _fundingStartBlock){
            fundingStartBlock = _fundingStartBlock;
        }
        if(_fundingEndBlock > fundingStartBlock && _fundingEndBlock > block.number){
            fundingEndBlock = _fundingEndBlock;
        }
        emit ChangeCampaign(_fundingStartBlock,_fundingEndBlock);
    }

    function releaseBountyTokens() onlyOwner public{
      require(!releasedBountyTokens);
      require(getState()==State.Success);
      releasedBountyTokens = true;
    }


    /// @notice set Broker for Investor
    /// @param _target address of Investor
    /// @param _broker address of Broker
    function setReferral(address _target, address _broker, uint256 _amount) onlyOwner public {
        require (_target != 0x0);
        require (_broker != 0x0);
        referrals[_target] = _broker;
        emit SetReferral(_target, _broker);
        if(_amount>0x0){
            uint256 brokerBonus = safeDiv(safeMul(_amount,referralBonus),hundredPercent);
            bonus[_broker] = safeAdd(bonus[_broker],brokerBonus);
            emit ReferralBonus(_target,_broker,brokerBonus);
        }
    }

    /// @notice set token for bounty hunter to release when ICO success
    function addBounty(address _hunter, uint256 _amount) onlyOwner public{
        require(_hunter!=0x0);
        require(toWei(_amount)<=safeSub(bonusAndBountyTokens,toWei(_amount)));
        bounties[_hunter] = safeAdd(bounties[_hunter],toWei(_amount));
        bonusAndBountyTokens = safeSub(bonusAndBountyTokens,toWei(_amount));
        emit AddBounty(_hunter, toWei(_amount));
    }

    /// @notice Create tokens when funding is active. This fallback function require 90.000 gas or more
    /// @dev Required state: Funding
    /// @dev State transition: -> Funding Success (only if cap reached)
    function() payable public{
        // Abort if not in Funding Active state.
        // Do not allow creating 0 or more than the cap tokens.
        require (getState() != State.Success);
        require (getState() != State.Failure);
        require (msg.value != 0);

        if(getState()==State.PrivateFunding){
            require(msg.value>=minPrivateContribution);
        }else if(getState()==State.PreFunding){
            require(msg.value>=minPreContribution && msg.value < maxContributionAmount);
        }else{
            require(msg.value>=minContributionAmount && msg.value < maxContributionAmount);
        }

        // multiply by exchange rate to get newly created token amount
        uint256 createdTokens = safeMul(msg.value, tokensPerEther);
        uint256 brokerBonus = 0;
        uint256 earlyBonus = safeDiv(safeMul(createdTokens,_getEarlyBonus()),hundredPercent);

        createdTokens = safeAdd(createdTokens,earlyBonus);

        // don&#39;t go over the limit!
        if(getState()==State.PrivateFunding){
            require(safeAdd(tokensSold,createdTokens) <= tokenPrivateMax);
        }else{
            require (safeAdd(tokensSold,createdTokens) <= tokenCreationMax);
        }

        // we are creating tokens, so increase the tokenSold
        tokensSold = safeAdd(tokensSold, createdTokens);
        collectedETH = safeAdd(collectedETH,msg.value);
        
        // add bonus if has referral
        if(referrals[msg.sender]!= 0x0){
            brokerBonus = safeDiv(safeMul(createdTokens,referralBonus),hundredPercent);
            bonus[referrals[msg.sender]] = safeAdd(bonus[referrals[msg.sender]],brokerBonus);
            emit ReferralBonus(msg.sender,referrals[msg.sender],brokerBonus);
        }

        // Save funder info for refund and free distribution
        funders[msg.sender] = safeAdd(funders[msg.sender],msg.value);
        investors[msg.sender] = safeAdd(investors[msg.sender],createdTokens);

        // Assign new tokens to the sender
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender], createdTokens);
        // Log token creation event
        emit FundTransfer(msg.sender,msg.value, createdTokens, block.number);
        emit Transfer(0, msg.sender, createdTokens);
    }

    /// @notice send bonus token to broker
    function requestBonus() external{
      require(getState()==State.Success);
      uint256 bonusAmount = bonus[msg.sender];
      assert(bonusAmount>0);
      require(bonusAmount<=safeSub(bonusAndBountyTokens,bonusAmount));
      balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender],bonusAmount);
      bonus[msg.sender] = 0;
      bonusAndBountyTokens = safeSub(bonusAndBountyTokens,bonusAmount);
      emit BonusTransfer(msg.sender,bonusAmount,block.number);
      emit Transfer(0,msg.sender,bonusAmount);
    }

    /// @notice send lockedTokens to devs address
    /// require State == Success
    /// require tokens unlocked
    function releaseLockedToken() external {
        require (getState() == State.Success);
        require (balanceOf[lockedTokenHolder] > 0x0);
        require (block.number >= unlockedAtBlockNumber);
        balanceOf[devsHolder] = safeAdd(balanceOf[devsHolder],balanceOf[lockedTokenHolder]);
        emit Transfer(lockedTokenHolder,devsHolder,balanceOf[lockedTokenHolder]);
        balanceOf[lockedTokenHolder] = 0;
    }
    
    /// @notice request to receive bounty tokens
    /// @dev require State == Succes
    function requestBounty() external{
        require(releasedBountyTokens); //locked bounty hunter&#39;s token for 7 days after end of campaign
        require(getState()==State.Success);
        assert (bounties[msg.sender]>0);
        balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender],bounties[msg.sender]);
        emit BountyTransfer(msg.sender,bounties[msg.sender],block.number);
        emit Transfer(0,msg.sender,bounties[msg.sender]);
        bounties[msg.sender] = 0;
    }

    /// @notice Finalize crowdfunding
    /// @dev If cap was reached or crowdfunding has ended then:
    /// create GRD for the Vault and developer,
    /// transfer ETH to the devs address.
    /// @dev Required state: Success
    function finalizeCrowdfunding() external {
        // Abort if not in Funding Success state.
        require (getState() == State.Success); // don&#39;t finalize unless we won
        require (!finalizedCrowdfunding); // can&#39;t finalize twice (so sneaky!)

        // prevent more creation of tokens
        finalizedCrowdfunding = true;
        // Endowment: 25% of total goes to vault, timelocked for 6 months
        balanceOf[lockedTokenHolder] = safeAdd(balanceOf[lockedTokenHolder], lockedTokens);

        // Transfer lockedTokens to lockedTokenHolder address
        unlockedAtBlockNumber = block.number + numBlocksLocked;
        emit Transfer(0, lockedTokenHolder, lockedTokens);

        // Endowment: 10% of total goes to devs
        balanceOf[devsHolder] = safeAdd(balanceOf[devsHolder], devsTokens);
        emit Transfer(0, devsHolder, devsTokens);

        // Transfer ETH to the multiSigWalletAddress address.
        multiSigWalletAddress.transfer(address(this).balance);
    }

    /// @notice send @param _unSoldTokens to all Investor base on their share
    function requestFreeDistribution() external{
      require(getState()==State.Success);
      assert(investors[msg.sender]>0);
      uint256 unSoldTokens = safeSub(tokenCreationMax,tokensSold);
      require(unSoldTokens>0);
      uint256 freeTokens = safeDiv(safeMul(unSoldTokens,investors[msg.sender]),tokensSold);
      balanceOf[msg.sender] = safeAdd(balanceOf[msg.sender],freeTokens);
      investors[msg.sender] = 0;
      emit FreeDistribution(msg.sender,freeTokens,block.number);
      emit Transfer(0,msg.sender, freeTokens);

    }

    /// @notice Get back the ether sent during the funding in case the funding
    /// has not reached the soft cap.
    /// @dev Required state: Failure
    function requestRefund() external {
        // Abort if not in Funding Failure state.
        assert (getState() == State.Failure);
        assert (funders[msg.sender]>0);
        msg.sender.transfer(funders[msg.sender]);  
        emit Refund( msg.sender, funders[msg.sender],block.number);
        funders[msg.sender]=0;
    }

    /// @notice This manages the crowdfunding state machine
    /// We make it a function and do not assign the result to a variable
    /// So there is no chance of the variable being stale
    function getState() public constant returns (State){
      // once we reach success, lock in the state
      if (finalizedCrowdfunding) return State.Success;
      if(fundingStartBlock ==0 && fundingEndBlock==0) return State.PrivateFunding;
      else if (block.number < fundingStartBlock) return State.PreFunding;
      else if (block.number <= fundingEndBlock && tokensSold < tokenCreationMax) return State.Funding;
      else if (tokensSold >= tokenCreationMin) return State.Success;
      else return State.Failure;
    }
}