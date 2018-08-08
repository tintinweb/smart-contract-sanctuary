pragma solidity ^0.4.17;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    
    address public owner;

    /**
    * @dev The Ownable constructor sets the original `owner` of the contract to the sender
    * account.
    */
    function Ownable()public {
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
    function transferOwnership(address newOwner)public onlyOwner {
        require(newOwner != address(0));      
        owner = newOwner;
    }
}

/**
* @title ERC20Basic
* @dev Simpler version of ERC20 interface
* @dev https://github.com/ethereum/EIPs/issues/179
*/
contract ERC20Basic is Ownable {
    uint256 public totalSupply;
    function balanceOf(address who) public constant returns (uint256);
    function transfer(address to, uint256 value)public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
* @title ERC20 interface
* @dev https://github.com/ethereum/EIPs/issues/20
*/
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender)public constant returns (uint256);
    function transferFrom(address from, address to, uint256 value)public returns(bool);
    function approve(address spender, uint256 value)public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/**
* @title SafeMath
* @dev Math operations with safety checks that throw on error
*/
library SafeMath {
    
    function mul(uint256 a, uint256 b) internal pure  returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }
    
    function div(uint256 a, uint256 b) internal pure  returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure  returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure  returns (uint256) {
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
    
    bool freeze = false;
    
    mapping(address => uint256) balances;
    
    uint endOfICO = 1527681600; // 05.30.2018 12:00
    
    /**
    * @dev Sets the date of the ICO end.
    * @param ICO_end The date of the ICO end.
    */
    function setEndOfICO(uint ICO_end) public onlyOwner {
        endOfICO = ICO_end;
    }
    
    /**
    * @dev Throws if called before the end of ICO.
    */
    modifier restrictionOnUse() {
        require(now > endOfICO);
        _;
    }
    
    /**
    * @dev Transfers tokens to a specified address.
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint256 _value) public restrictionOnUse isNotFrozen returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }
    
    /**
    * @dev Changes the value of freeze variable.
    */
    function freezeToken()public onlyOwner {
        freeze = !freeze;
    }
    
    /**
    * @dev Throws if called when contract is frozen.
    */
    modifier isNotFrozen(){
        require(!freeze);
        _;
    }
    
    /**
    * @dev Gets the balance of the specified address.
    * @param _owner The address to query the balance of.
    */
    function balanceOf(address _owner)public constant returns (uint256 balance) {
        return balances[_owner];
    }
}

/**
 * @title Standard ERC20 token
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;
    
    /**
    * @dev Transfers tokens from one address to another.
    * @param _from The address which you want to send tokens from.
    * @param _to The address which you want to transfer to.
    * @param _value The amount of tokens to be transfered.
    */
    function transferFrom(address _from, address _to, uint256 _value) public restrictionOnUse isNotFrozen returns(bool) {
        require(_value <= allowed[_from][msg.sender]);
        var _allowance = allowed[_from][msg.sender];
        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }
    
    /**
    * @dev Approves the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * @param _spender The address which will spend the funds.
    * @param _value The amount of tokens to be spent.
    */
    function approve(address _spender, uint256 _value) public restrictionOnUse isNotFrozen returns (bool) {
        require((_value > 0)&&(_value <= balances[msg.sender]));
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner The address which owns the funds.
    * @param _spender The address which will spend the funds.
    */
    function allowance(address _owner, address _spender)public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

/**
 * @title Mintable token
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken {
    
    event Mint(address indexed to, uint256 amount);
    
    event MintFinished();

    bool public mintingFinished = false;
    
    /**
    * @dev Throws if called when minting is finished.
    */
    modifier canMint() {
        require(!mintingFinished);
        _;
    }
    
    /**
    * @dev Function to mint tokens
    * @param _to The address that will recieve the minted tokens.
    * @param _amount The amount of tokens to mint.
    */
    function mint(address _to, uint256 _amount) internal canMint returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        return true;
    }
    
    /**
    * @dev Function to stop minting new tokens.
    */
    function finishMinting() public onlyOwner returns (bool) {
        mintingFinished = !mintingFinished;
        MintFinished();
        return true;
    }
}

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is MintableToken {
    
    using SafeMath for uint;
    
    /**
    * @dev Burns a specific amount of tokens.
    * @param _value The amount of token to be burned.
    */
    function burn(uint _value) restrictionOnUse isNotFrozen public returns (bool success) {
        require((_value > 0) && (_value <= balances[msg.sender]));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Burn(msg.sender, _value);
        return true;
    }
 
    /**
    * @dev Burns a specific amount of tokens from another address.
    * @param _value The amount of tokens to be burned.
    * @param _from The address which you want to burn tokens from.
    */
    function burnFrom(address _from, uint _value) restrictionOnUse isNotFrozen public returns (bool success) {
        require((balances[_from] > _value) && (_value <= allowed[_from][msg.sender]));
        var _allowance = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);
        totalSupply = totalSupply.sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Burn(_from, _value);
        return true;
    }

    event Burn(address indexed burner, uint indexed value);
}

/**
 * @title SimpleTokenCoin
 * @dev SimpleToken is a standard ERC20 token with some additional functionality
 */
contract SimpleTokenCoin is BurnableToken {
    
    address public forBounty = 0xdd5Aea206449d610A9e0c45B6b3fdAc684e0c8bD;
    address public forTeamCOT = 0x3FFeEcc08Dc94Fd5089A8C377a6e7Bf15F0D2f8d;
    address public forTeamETH = 0x619E27C6BfEbc196BA048Fb79B397314cfA82d89;
    address public forFund = 0x7b7c6d8ce28923e39611dD14A68DA6Af63c63FF7;
    address public forLoyalty = 0x22152A186AaD84b0eaadAD00e3F19547C30CcB02;
    
    string public constant name = "CoinTour";
    
    string public constant symbol = "COT";
    
    uint32 public constant decimals = 8;
    
    address private contractAddress;
    
    /**
    * @dev Sets the address of approveAndCall contract.
    * @param _address The address of approveAndCall contract.
    */
    function setContractAddress (address _address) public onlyOwner {
        contractAddress = _address;
    }
    
    /**
    * @dev The SimpleTokenCoin constructor mints tokens to four addresses.
    */
    function SimpleTokenCoin()public {
        mint(forBounty, 4000000 * 10**8);
        mint(forTeamCOT, 10000000 * 10**8); 
        mint(forFund, 10000000 * 10**8);
        mint(forLoyalty, 2000000 * 10**8);
    }
    
    /**
    * @dev Function to send ETH from contract address to team ETH address.
    */
    function sendETHfromContract() public onlyOwner {
        forTeamETH.transfer(this.balance);
    }
    
    /**
     * @dev Sends to multiple addresses using two arrays which
     * include the address and the amount of tokens.
     * @param users Array of addresses to send to.
     * @param bonus Array of amount of tokens to send.
     */
    function multisend(address[] users, uint[] bonus) public {
        for (uint i = 0; i < users.length; i++) {
            transfer(users[i], bonus[i]);
        }
    }
    
    /**
     * @dev Token owner can approve for spender to execute another function.
     * @param tokens Amount of tokens to execute function.
     * @param data Additional data.
     */
    function approveAndCall(uint tokens, bytes data) public restrictionOnUse returns (bool success) {
        approve(contractAddress, tokens);
        ApproveAndCallFallBack(contractAddress).receiveApproval(msg.sender, tokens, data);
        return true;
    }
}

interface ApproveAndCallFallBack { function receiveApproval(address from, uint256 tokens, bytes data) external; }

/**
 * @title Crowdsale 
 * @dev Based on references from OpenZeppelin: https://github.com/OpenZeppelin/zeppelin-solidity
 */
contract Crowdsale is SimpleTokenCoin {
    
    using SafeMath for uint;
    
    uint public startPreICO;
    
    uint public startICO;
    
    uint public periodPreICO;
    
    uint public firstPeriodOfICO;
    
    uint public secondPeriodOfICO;
    
    uint public thirdPeriodOfICO;

    uint public hardcap;

    uint public rate;
    
    uint public softcap;
    
    uint public maxTokensAmount;
    
    uint public availableTokensAmount;
    
    mapping(address => uint) ethBalance;
    
    /**
    * @dev Data type to save bonus system&#39;s information.
    */
    struct BonusSystem {
        //Period number
        uint period;
        // UNIX timestamp of period start
        uint start;
        // UNIX timestamp of period finish
        uint end;
        //Amount of tokens available per period
        uint tokensPerPeriod;
        //Sold tokens Amount
        uint soldTokens;
        // How many % tokens will add
        uint bonus;
    }
    
    BonusSystem[] public bonus;
    
    /**
    * @dev Function to change bonus system.
    * @param percentageOfTokens Percentage of tokens for each period.
    * @param bonuses Percentage of bonus for each period.
    */
    function changeBonusSystem(uint[] percentageOfTokens, uint[] bonuses) public onlyOwner{
        for (uint i = 0; i < bonus.length; i++) {
            bonus[i].tokensPerPeriod = availableTokensAmount / 100 * percentageOfTokens[i];
            bonus[i].bonus = bonuses[i];
        }
    }
    
    /**
    * @dev Function to set bonus system.
    * @param preICOtokens , firstPeriodTokens, secondPeriodTokens, thirdPeriodTokens Percentage of tokens for each period.
    * @param preICObonus , firstPeriodBonus, secondPeriodBonus, thirdPeriodBonus Percentage of bonus for each period.
    */
    function setBonusSystem(uint preICOtokens, uint preICObonus, uint firstPeriodTokens, uint firstPeriodBonus, 
                            uint secondPeriodTokens, uint secondPeriodBonus, uint thirdPeriodTokens, uint thirdPeriodBonus) private {
        bonus.push(BonusSystem(0, startPreICO, startPreICO + periodPreICO * 1 days, availableTokensAmount / 100 * preICOtokens, 0, preICObonus));
        bonus.push(BonusSystem(1, startICO, startICO + firstPeriodOfICO * 1 days, availableTokensAmount / 100 * firstPeriodTokens, 0, firstPeriodBonus));
        bonus.push(BonusSystem(2, startICO + firstPeriodOfICO * 1 days, startICO + (firstPeriodOfICO + secondPeriodOfICO) * 1 days, availableTokensAmount / 100 * secondPeriodTokens, 0, secondPeriodBonus));
        bonus.push(BonusSystem(3, startICO + (firstPeriodOfICO + secondPeriodOfICO) * 1 days, startICO + (firstPeriodOfICO + secondPeriodOfICO + thirdPeriodOfICO) * 1 days, availableTokensAmount / 100 * thirdPeriodTokens, 0, thirdPeriodBonus));
    }
    
    /**
    * @dev Gets current bonus system.
    */
    function getCurrentBonusSystem() public constant returns (BonusSystem) {
      for (uint i = 0; i < bonus.length; i++) {
        if (bonus[i].start <= now && bonus[i].end >= now) {
          return bonus[i];
        }
      }
    }

    /**
    * @dev Sets values of periods.
    * @param PreICO_start The value of pre ICO start.
    * @param PreICO_period The duration of pre ICO period.
    * @param ICO_firstPeriod , ICO_secondPeriod, ICO_thirdPeriod The duration of each period.
    */
    function setPeriods(uint PreICO_start, uint PreICO_period, uint ICO_start, uint ICO_firstPeriod, uint ICO_secondPeriod, uint ICO_thirdPeriod) public onlyOwner {
        startPreICO = PreICO_start;
        periodPreICO = PreICO_period;
        startICO = ICO_start;
        firstPeriodOfICO = ICO_firstPeriod;
        secondPeriodOfICO = ICO_secondPeriod;
        thirdPeriodOfICO = ICO_thirdPeriod;
        bonus[0].start = PreICO_start;
        bonus[0].end = PreICO_start + PreICO_period * 1 days;
        bonus[1].start = ICO_start;
        bonus[1].end = ICO_start + ICO_firstPeriod * 1 days;
        bonus[2].start = bonus[1].end;
        bonus[2].end = bonus[2].start + ICO_secondPeriod * 1 days;
        bonus[3].start = bonus[2].end;
        bonus[3].end = bonus[2].end + ICO_thirdPeriod * 1 days;
    }
    
    /**
    * @dev Sets the rate of COT.
    */
    function setRate (uint _rate) public onlyOwner {
        rate = _rate * 10**8 ;
    }
    
    /**
    * @dev The Crowdsale constructor sets the first values to variables.
    */
    function Crowdsale() public{
        rate = 16000 * 10**8 ;
        startPreICO = 1522065600; // 03.26.2018 12:00
        periodPreICO = 14;
        startICO = 1525089600; // 04.30.2018 12:00
        firstPeriodOfICO = secondPeriodOfICO = thirdPeriodOfICO = 10;
        hardcap = 59694 * 10**17;
        softcap = 400 * 10**18;
        maxTokensAmount = 100000000 * 10**8;
        availableTokensAmount = maxTokensAmount - totalSupply;
        setBonusSystem(20, 40, 25, 25, 25, 15, 30, 0);
    }
    
    /**
    * @dev Throws if called when the period or tokens are over.
    */
    modifier isUnderPeriodLimit() {
        require(getCurrentBonusSystem().start <= now && getCurrentBonusSystem().end >= now && getCurrentBonusSystem().tokensPerPeriod - getCurrentBonusSystem().soldTokens > 0);
        _;
    }

    /**
    * @dev Function to mint tokens.
    * @param _to The address that will recieve the minted tokens.
    * @param _amount The amount of tokens to mint.
    */
    function buyTokens(address _to, uint256 _amount) internal canMint isNotFrozen returns (bool) {
        totalSupply = totalSupply.add(_amount);
        bonus[getCurrentBonusSystem().period].soldTokens = getCurrentBonusSystem().soldTokens.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        return true;
    }
    
    /**
    * @dev Refund &#39;msg.sender&#39; in the case the Token Sale didn&#39;t 
    * reach the minimum funding goal.
    */
    function refund() restrictionOnUse isNotFrozen public {
        require(this.balance < softcap);
        uint value = ethBalance[msg.sender]; 
        ethBalance[msg.sender] = 0; 
        msg.sender.transfer(value); 
    }
    
    /**
    * @dev Сalculates the required amount of tokens to be minted. 
    */
    function createTokens()private isUnderPeriodLimit isNotFrozen {
        uint tokens = rate.mul(msg.value).div(1 ether);
        uint bonusTokens = tokens / 100 * getCurrentBonusSystem().bonus;
        tokens += bonusTokens;
        if (msg.value < 10 finney || (tokens > getCurrentBonusSystem().tokensPerPeriod.sub(getCurrentBonusSystem().soldTokens))) {
            msg.sender.transfer(msg.value);
        }
        else {
            forTeamETH.transfer(msg.value);
            buyTokens(msg.sender, tokens);
            ethBalance[msg.sender] = ethBalance[msg.sender].add(msg.value);
        }
    }
    
    /**
    * Called when ETH comes to the contract.
    */
    function() external payable {
        createTokens();
    }
}