pragma solidity ^0.4.18;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
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
// accepted from zeppelin-solidity https://github.com/OpenZeppelin/zeppelin-solidity
/*
 * ERC20 interface
 * see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address _who) public constant returns (uint);
  function allowance(address _owner, address _spender) public constant returns (uint);

  function transfer(address _to, uint _value) public returns (bool ok);
  function transferFrom(address _from, address _to, uint _value) public returns (bool ok);
  function approve(address _spender, uint _value) public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}
contract Haltable is Ownable {

    // @dev To Halt in Emergency Condition
    bool public halted = false;
    //empty contructor
    function Haltable() public {}

    // @dev Use this as function modifier that should not execute if contract state Halted
    modifier stopIfHalted {
      require(!halted);
      _;
    }

    // @dev Use this as function modifier that should execute only if contract state Halted
    modifier runIfHalted{
      require(halted);
      _;
    }

    // @dev called by only owner in case of any emergecy situation
    function halt() onlyOwner stopIfHalted public {
        halted = true;
    }
    // @dev called by only owner to stop the emergency situation
    function unHalt() onlyOwner runIfHalted public {
        halted = false;
    }
}

contract UpgradeAgent is SafeMath {
  address public owner;
  bool public isUpgradeAgent;
  function upgradeFrom(address _from, uint256 _value) public;
  function setOriginalSupply() public;
}

contract MiBoodleToken is ERC20,SafeMath,Haltable {

    //flag to determine if address is for real contract or not
    bool public isMiBoodleToken = false;

    //Token related information
    string public constant name = "miBoodle";
    string public constant symbol = "MIBO";
    uint256 public constant decimals = 18; // decimal places

    //mapping of token balances
    mapping (address => uint256) balances;
    //mapping of allowed address for each address with tranfer limit
    mapping (address => mapping (address => uint256)) allowed;
    //mapping of allowed address for each address with burnable limit
    mapping (address => mapping (address => uint256)) allowedToBurn;

    //mapping of ether investment
    mapping (address => uint256) investment;

    address public upgradeMaster;
    UpgradeAgent public upgradeAgent;
    uint256 public totalUpgraded;
    bool public upgradeAgentStatus = false;

    //crowdSale related information
     //crowdsale start time
    uint256 public start;
    //crowdsale end time
    uint256 public end;
    //crowdsale prefunding start time
    uint256 public preFundingStart;
    //Tokens per Ether in preFunding
    uint256 public preFundingtokens;
    //Tokens per Ether in Funding
    uint256 public fundingTokens;
    //max token supply
    uint256 public maxTokenSupply = 600000000 ether;
    //max token for sale
    uint256 public maxTokenSale = 200000000 ether;
    //max token for preSale
    uint256 public maxTokenForPreSale = 100000000 ether;
    //address of multisig
    address public multisig;
    //address of vault
    address public vault;
    //Is crowdsale finalized
    bool public isCrowdSaleFinalized = false;
    //Accept minimum ethers
    uint256 minInvest = 1 ether;
    //Accept maximum ethers
    uint256 maxInvest = 50 ether;
    //Is transfer enable
    bool public isTransferEnable = false;
    //Is Released Ether Once
    bool public isReleasedOnce = false;

    //event
    event Allocate(address _address,uint256 _value);
    event Burn(address owner,uint256 _value);
    event ApproveBurner(address owner, address canBurn, uint256 value);
    event BurnFrom(address _from,uint256 _value);
    event Upgrade(address indexed _from, address indexed _to, uint256 _value);
    event UpgradeAgentSet(address agent);
    event Deposit(address _investor,uint256 _value);

    function MiBoodleToken(uint256 _preFundingtokens,uint256 _fundingTokens,uint256 _preFundingStart,uint256 _start,uint256 _end) public {
        upgradeMaster = msg.sender;
        isMiBoodleToken = true;
        preFundingtokens = _preFundingtokens;
        fundingTokens = _fundingTokens;
        preFundingStart = safeAdd(now, _preFundingStart);
        start = safeAdd(now, _start);
        end = safeAdd(now, _end);
    }

    //&#39;owner&#39; can set minimum ether to accept
    // @param _minInvest Minimum value of ether
    function setMinimumEtherToAccept(uint256 _minInvest) public stopIfHalted onlyOwner {
        minInvest = _minInvest;
    }

    //&#39;owner&#39; can set maximum ether to accept
    // @param _maxInvest Maximum value of ether
    function setMaximumEtherToAccept(uint256 _maxInvest) public stopIfHalted onlyOwner {
        maxInvest = _maxInvest;
    }

    //&#39;owner&#39; can set start time of pre funding
    // @param _preFundingStart Starting time of prefunding
    function setPreFundingStartTime(uint256 _preFundingStart) public stopIfHalted onlyOwner {
        preFundingStart = now + _preFundingStart;
    }

    //&#39;owner&#39; can set start time of funding
    // @param _start Starting time of funding
    function setFundingStartTime(uint256 _start) public stopIfHalted onlyOwner {
        start = now + _start;
    }

    //&#39;owner&#39; can set end time of funding
    // @param _end Ending time of funding
    function setFundingEndTime(uint256 _end) public stopIfHalted onlyOwner {
        end = now + _end;
    }

    //&#39;owner&#39; can set transfer enable or disable
    // @param _isTransferEnable Token transfer enable or disable
    function setTransferEnable(bool _isTransferEnable) public stopIfHalted onlyOwner {
        isTransferEnable = _isTransferEnable;
    }

    //&#39;owner&#39; can set number of tokens per Ether in prefunding
    // @param _preFundingtokens Tokens per Ether in prefunding
    function setPreFundingtokens(uint256 _preFundingtokens) public stopIfHalted onlyOwner {
        preFundingtokens = _preFundingtokens;
    }

    //&#39;owner&#39; can set number of tokens per Ether in funding
    // @param _fundingTokens Tokens per Ether in funding
    function setFundingtokens(uint256 _fundingTokens) public stopIfHalted onlyOwner {
        fundingTokens = _fundingTokens;
    }

    //Owner can Set Multisig wallet
    //@ param _multisig address of Multisig wallet.
    function setMultisigWallet(address _multisig) onlyOwner public {
        require(_multisig != 0);
        multisig = _multisig;
    }

    //Owner can Set TokenVault
    //@ param _vault address of TokenVault.
    function setMiBoodleVault(address _vault) onlyOwner public {
        require(_vault != 0);
        vault = _vault;
    }

    //owner can call to allocate tokens to investor who invested in other currencies
    //@ param _investor address of investor
    //@ param _tokens number of tokens to give to investor
    function cashInvestment(address _investor,uint256 _tokens) onlyOwner stopIfHalted external {
        //validate address
        require(_investor != 0);
        //not allow with tokens 0
        require(_tokens > 0);
        //not allow if crowdsale ends.
        require(now >= preFundingStart && now <= end);
        if (now < start && now >= preFundingStart) {
            //total supply should not be greater than max token sale for pre funding
            require(safeAdd(totalSupply, _tokens) <= maxTokenForPreSale);
        } else {
            //total supply should not be greater than max token sale
            require(safeAdd(totalSupply, _tokens) <= maxTokenSale);
        }
        //Call internal method to assign tokens
        assignTokens(_investor,_tokens);
    }

    // transfer the tokens to investor&#39;s address
    // Common function code for cashInvestment and Crowdsale Investor
    function assignTokens(address _investor, uint256 _tokens) internal {
        // Creating tokens and  increasing the totalSupply
        totalSupply = safeAdd(totalSupply,_tokens);
        // Assign new tokens to the sender
        balances[_investor] = safeAdd(balances[_investor],_tokens);
        // Finally token created for sender, log the creation event
        Allocate(_investor, _tokens);
    }

    // Withdraw ether during pre-sale and sale 
    function withdraw() external onlyOwner {
        // Release only if token-sale not ended and multisig set
        require(now <= end && multisig != address(0));
        // Release only if not released anytime before
        require(!isReleasedOnce);
        // Release only if balance more then 200 ether
        require(address(this).balance >= 200 ether);
        // Set ether released once 
        isReleasedOnce = true;
        // Release 200 ether
        assert(multisig.send(200 ether));
    }

    //Finalize crowdsale and allocate tokens to multisig and vault
    function finalizeCrowdSale() external {
        require(!isCrowdSaleFinalized);
        require(multisig != 0 && vault != 0 && now > end);
        require(safeAdd(totalSupply,250000000 ether) <= maxTokenSupply);
        assignTokens(multisig, 250000000 ether);
        require(safeAdd(totalSupply,150000000 ether) <= maxTokenSupply);
        assignTokens(vault, 150000000 ether);
        isCrowdSaleFinalized = true;
        require(multisig.send(address(this).balance));
    }

    //fallback function to accept ethers
    function() payable stopIfHalted external {
        //not allow if crowdsale ends.
        require(now <= end && now >= preFundingStart);
        //not allow to invest with less then minimum investment value
        require(msg.value >= minInvest);
        //not allow to invest with more then maximum investment value
        require(safeAdd(investment[msg.sender],msg.value) <= maxInvest);

        //Hold created tokens for current state of funding
        uint256 createdTokens;
        if (now < start) {
            createdTokens = safeMul(msg.value,preFundingtokens);
            //total supply should not be greater than max token sale for pre funding
            require(safeAdd(totalSupply, createdTokens) <= maxTokenForPreSale);
        } else {
            createdTokens = safeMul(msg.value,fundingTokens);
            //total supply should not greater than maximum token to supply 
            require(safeAdd(totalSupply, createdTokens) <= maxTokenSale);
        }

        // Add investment details of investor
        investment[msg.sender] = safeAdd(investment[msg.sender],msg.value);
        
        //call internal method to assign tokens
        assignTokens(msg.sender,createdTokens);
        Deposit(msg.sender,createdTokens);
    }

    // @param _who The address of the investor to check balance
    // @return balance tokens of investor address
    function balanceOf(address _who) public constant returns (uint) {
        return balances[_who];
    }

    // @param _owner The address of the account owning tokens
    // @param _spender The address of the account able to transfer the tokens
    // @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) public constant returns (uint) {
        return allowed[_owner][_spender];
    }

    // @param _owner The address of the account owning tokens
    // @param _spender The address of the account able to transfer the tokens
    // @return Amount of remaining tokens allowed to spent
    function allowanceToBurn(address _owner, address _spender) public constant returns (uint) {
        return allowedToBurn[_owner][_spender];
    }

    //  Transfer `value` miBoodle tokens from sender&#39;s account
    // `msg.sender` to provided account address `to`.
    // @param _to The address of the recipient
    // @param _value The number of miBoodle tokens to transfer
    // @return Whether the transfer was successful or not
    function transfer(address _to, uint _value) public returns (bool ok) {
        //allow only if transfer is enable
        require(isTransferEnable);
        //require(now >= end);
        //validate receiver address and value.Not allow 0 value
        require(_to != 0 && _value > 0);
        uint256 senderBalance = balances[msg.sender];
        //Check sender have enough balance
        require(senderBalance >= _value);
        senderBalance = safeSub(senderBalance, _value);
        balances[msg.sender] = senderBalance;
        balances[_to] = safeAdd(balances[_to],_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    //  Transfer `value` miBoodle tokens from sender &#39;from&#39;
    // to provided account address `to`.
    // @param from The address of the sender
    // @param to The address of the recipient
    // @param value The number of miBoodle to transfer
    // @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint _value) public returns (bool ok) {
        //allow only if transfer is enable
        require(isTransferEnable);
        //require(now >= end);
        //validate _from,_to address and _value(Not allow with 0)
        require(_from != 0 && _to != 0 && _value > 0);
        //Check amount is approved by the owner for spender to spent and owner have enough balances
        require(allowed[_from][msg.sender] >= _value && balances[_from] >= _value);
        balances[_from] = safeSub(balances[_from],_value);
        balances[_to] = safeAdd(balances[_to],_value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);
        Transfer(_from, _to, _value);
        return true;
    }

    //  `msg.sender` approves `spender` to spend `value` tokens
    // @param spender The address of the account able to transfer the tokens
    // @param value The amount of wei to be approved for transfer
    // @return Whether the approval was successful or not
    function approve(address _spender, uint _value) public returns (bool ok) {
        //validate _spender address
        require(_spender != 0);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    //  `msg.sender` approves `_canBurn` to burn `value` tokens
    // @param _canBurn The address of the account able to burn the tokens
    // @param _value The amount of wei to be approved for burn
    // @return Whether the approval was successful or not
    function approveForBurn(address _canBurn, uint _value) public returns (bool ok) {
        //validate _spender address
        require(_canBurn != 0);
        allowedToBurn[msg.sender][_canBurn] = _value;
        ApproveBurner(msg.sender, _canBurn, _value);
        return true;
    }

    //  Burn `value` miBoodle tokens from sender&#39;s account
    // `msg.sender` to provided _value.
    // @param _value The number of miBoodle tokens to destroy
    // @return Whether the Burn was successful or not
    function burn(uint _value) public returns (bool ok) {
        //allow only if transfer is enable
        require(now >= end);
        //validate receiver address and value.Now allow 0 value
        require(_value > 0);
        uint256 senderBalance = balances[msg.sender];
        require(senderBalance >= _value);
        senderBalance = safeSub(senderBalance, _value);
        balances[msg.sender] = senderBalance;
        totalSupply = safeSub(totalSupply,_value);
        Burn(msg.sender, _value);
        return true;
    }

    //  Burn `value` miBoodle tokens from sender &#39;from&#39;
    // to provided account address `to`.
    // @param from The address of the burner
    // @param to The address of the token holder from token to burn
    // @param value The number of miBoodle to burn
    // @return Whether the transfer was successful or not
    function burnFrom(address _from, uint _value) public returns (bool ok) {
        //allow only if transfer is enable
        require(now >= end);
        //validate _from,_to address and _value(Now allow with 0)
        require(_from != 0 && _value > 0);
        //Check amount is approved by the owner to burn and owner have enough balances
        require(allowedToBurn[_from][msg.sender] >= _value && balances[_from] >= _value);
        balances[_from] = safeSub(balances[_from],_value);
        totalSupply = safeSub(totalSupply,_value);
        allowedToBurn[_from][msg.sender] = safeSub(allowedToBurn[_from][msg.sender],_value);
        BurnFrom(_from, _value);
        return true;
    }

    // Token upgrade functionality

    /// @notice Upgrade tokens to the new token contract.
    /// @param value The number of tokens to upgrade
    function upgrade(uint256 value) external {
        /*if (getState() != State.Success) throw; // Abort if not in Success state.*/
        require(upgradeAgentStatus); // need a real upgradeAgent address

        // Validate input value.
        require (value > 0 && upgradeAgent.owner() != 0x0);
        require (value <= balances[msg.sender]);

        // update the balances here first before calling out (reentrancy)
        balances[msg.sender] = safeSub(balances[msg.sender], value);
        totalSupply = safeSub(totalSupply, value);
        totalUpgraded = safeAdd(totalUpgraded, value);
        upgradeAgent.upgradeFrom(msg.sender, value);
        Upgrade(msg.sender, upgradeAgent, value);
    }

    /// @notice Set address of upgrade target contract and enable upgrade
    /// process.
    /// @param agent The address of the UpgradeAgent contract
    function setUpgradeAgent(address agent) external onlyOwner {
        require(agent != 0x0 && msg.sender == upgradeMaster);
        upgradeAgent = UpgradeAgent(agent);
        require (upgradeAgent.isUpgradeAgent());
        // this needs to be called in success condition to guarantee the invariant is true
        upgradeAgentStatus = true;
        upgradeAgent.setOriginalSupply();
        UpgradeAgentSet(upgradeAgent);
    }

    /// @notice Set address of upgrade target contract and enable upgrade
    /// process.
    /// @param master The address that will manage upgrades, not the upgradeAgent contract address
    function setUpgradeMaster(address master) external {
        require (master != 0x0 && msg.sender == upgradeMaster);
        upgradeMaster = master;
    }
}