/*************************************************************************
 * This contract has been merged with solidify
 * https://github.com/tiesnetwork/solidify
 *************************************************************************/
 
 pragma solidity ^0.4.22;


/*************************************************************************
 * import "zeppelin-solidity/contracts/math/SafeMath.sol" : start
 *************************************************************************/


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
/*************************************************************************
 * import "zeppelin-solidity/contracts/math/SafeMath.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "zeppelin-solidity/contracts/token/MintableToken.sol" : start
 *************************************************************************/


/*************************************************************************
 * import "./StandardToken.sol" : start
 *************************************************************************/


/*************************************************************************
 * import "./BasicToken.sol" : start
 *************************************************************************/


/*************************************************************************
 * import "./ERC20Basic.sol" : start
 *************************************************************************/


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
/*************************************************************************
 * import "./ERC20Basic.sol" : end
 *************************************************************************/



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
/*************************************************************************
 * import "./BasicToken.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "./ERC20.sol" : start
 *************************************************************************/





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
/*************************************************************************
 * import "./ERC20.sol" : end
 *************************************************************************/


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
/*************************************************************************
 * import "./StandardToken.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "../ownership/Ownable.sol" : start
 *************************************************************************/


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
/*************************************************************************
 * import "../ownership/Ownable.sol" : end
 *************************************************************************/



/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * @dev Issue: * https://github.com/OpenZeppelin/zeppelin-solidity/issues/120
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */

contract MintableToken is StandardToken, Ownable {
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
/*************************************************************************
 * import "zeppelin-solidity/contracts/token/MintableToken.sol" : end
 *************************************************************************/


contract HC8 is MintableToken {

    /* Token constants */

    string public name = "Hydrocarbon8";

    string public symbol = "HC8";

    uint public decimals = 6;

    /* Blocks token transfers until ICO is finished.*/
    bool public tokensBlocked = true;

    // list of addresses with time-freezend tokens
    mapping (address => uint) public teamTokensFreeze;

    event debugLog(string key, uint value);




    /* Allow token transfer.*/
    function unblock() external onlyOwner {
        tokensBlocked = false;
    }

    /* Override some function to add support of blocking .*/
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(!tokensBlocked);
        require(allowTokenOperations(_to));
        require(allowTokenOperations(msg.sender));
        super.transfer(_to, _value);
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(!tokensBlocked);
        require(allowTokenOperations(_from));
        require(allowTokenOperations(_to));
        super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(!tokensBlocked);
        require(allowTokenOperations(_spender));
        super.approve(_spender, _value);
    }

    // Hold team/founders tokens for defined time
    function freezeTokens(address _holder, uint time) public onlyOwner {
        require(_holder != 0x0);
        teamTokensFreeze[_holder] = time;
    }

    function allowTokenOperations(address _holder) public constant returns (bool) {
        return teamTokensFreeze[_holder] == 0 || now >= teamTokensFreeze[_holder];
    }

}


contract HC8ICO {
    using SafeMath for uint;

    //==========
    // Variables
    //==========
    //States
    enum IcoState {Running, Paused, Failed, Finished}

    // ico successed
    bool public isSuccess = false;

    // contract hardcoded owner
    address public owner = 0x07c88CC4316F47131d5D3AD84B3151397E858120;
    address public wallet = 0x81c9Ad6B14F6cBd71155B504e6E88963420f1829;
    address public unsold = 0x7Cb4C67d020042537476Bc13033461ce154bD3e0;
    // Start time
    uint public constant startTime = 1533715688;
    // End time
    uint public endTime = startTime + 60 days;

    // decimals multiplier for calculation & debug
    uint public constant multiplier = 1000000;

    // minimal amount of tokens for sale
    uint private constant minTokens = 50  * multiplier;

    // one million
    uint public constant mln = 1000000;

    // ICO max tokens for sale
    uint public constant tokensCap = 99 * mln * multiplier;

    //ICO success
    uint public constant minSuccess = 50 * multiplier;

    // Amount of sold tokens
    uint public totalSupply = 0;
    // Amount of tokens w/o bonus
    uint public tokensSoldTotal = 0;


    // State of ICO - default Running
    IcoState public icoState = IcoState.Running;


    // @dev for debug
    uint private constant rateDivider = 1;

    // initial price in wei
    uint public priceInWei = 3105962723;


    // robot address
    address public _robot = 0x63b247db491D3d3E32A9629509Fb459386Aff921;

    // if ICO not finished - we must send all old contract eth to new
    bool public tokensAreFrozen = true;

    // The token being sold
    HC8 public token;

    // Structure for holding bonuses and tokens for btc investors
    // We can now deprecate rate/bonus_tokens/value without bitcoin holding mechanism - we don&#39;t need it
    struct TokensHolder {
    uint value; //amount of wei
    uint tokens; //amount of tokens
    uint bonus; //amount of bonus tokens
    uint total; //total tokens
    uint rate; //conversion rate for hold moment
    uint change; //unused wei amount if tx reaches cap
    }

    //wei amount
    mapping (address => uint) public investors;

    struct teamTokens {
    address holder;
    uint freezePeriod;
    uint percent;
    uint divider;
    uint maxTokens;
    }

    teamTokens[] public listTeamTokens;

    // Bonus params
    uint[] public bonusPatterns = [80, 60, 40, 20];

    uint[] public bonusLimit = [5 * mln * multiplier, 10 * mln * multiplier, 15 * mln * multiplier, 20 * mln * multiplier];

    // flag to prevent team tokens regen with external call
    bool public teamTokensGenerated = false;


    //=========
    //Modifiers
    //=========

    // Active ICO
    modifier ICOActive {
        require(icoState == IcoState.Running);
        require(now >= (startTime));
        require(now <= (endTime));
        _;
    }

    // Finished ICO
    modifier ICOFinished {
        require(icoState == IcoState.Finished);
        _;
    }

    // Failed ICO - time is over 
    modifier ICOFailed {
        require(now >= (endTime));
        require(icoState == IcoState.Failed || !isSuccess);
        _;
    }


    // Allows some methods to be used by team or robot
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyTeam() {
        require(msg.sender == owner || msg.sender == _robot);
        _;
    }

    modifier successICOState() {
        require(isSuccess);
        _;
    }

    
  

    //=======
    // Events
    //=======

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint value, uint amount);

    event RunIco();

    event PauseIco();

    event SuccessIco();

    
    event ICOFails();

    event updateRate(uint time, uint rate);

    event debugLog(string key, uint value);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    //========
    // Methods
    //========

    // Constructor
    function HC8ICO() public {
        token = new HC8();
        //if (owner == 0x0) {//owner not set in contract
        //    owner = msg.sender;
        //}
        //uint freezePeriod;
        //uint percent;
        //uint divider;
        //

        
        // Company tokens 10%, blocked for 182 days
        listTeamTokens.push(teamTokens(0x1b83619057f2230060ea672E7C03C5DAe8A1eEE6, 182 days, 10, 1, 0));

        // Company tokens 10%, blocked for 1 year
        listTeamTokens.push(teamTokens(0xB7F2BD192baAe546F5a48570b5d5990be2C31433, 1 years, 10, 1, 0));


        // Team tokens 6.667%
        listTeamTokens.push(teamTokens(0xB6e2E9019AC0282Bc20b6874dea8488Db4E41512, 0, 32, 10, 0));
        listTeamTokens.push(teamTokens(0x0adC0CC5E9625E893Ec5C56Ee9D189644FF3744F, 0, 16, 10, 0));
        listTeamTokens.push(teamTokens(0xB5c5C8C3615A48c03BF0F2a30fD1EC3Aea8C5A20, 0, 16, 10, 0));
        listTeamTokens.push(teamTokens(0x79C3659236c51C82b7c0A5CD02932551470fA8cF, 0, 200, 1000, 0));
        listTeamTokens.push(teamTokens(0x644dEd1858174fc9b91d614846d1545Ad510074B, 0, 6670, 100000, 0));
        
        
        // Team tokens 6.667%, blocked for 1 year
        listTeamTokens.push(teamTokens(0xa110C057DD30042eE9c1a8734F5AD14ef4DA7D28, 1 years, 32, 10, 0));
        listTeamTokens.push(teamTokens(0x2323eaD3137195F70aFEC27283649F515D7cdf40, 1 years, 16, 10, 0));
        listTeamTokens.push(teamTokens(0x4A536E9F10c19112C33DEA04BFC62216792a197D, 1 years, 16, 10, 0));
        listTeamTokens.push(teamTokens(0x93c7338D6D23Ed36c6eD5d05C80Dc54BDB2ebCcd, 1 years, 200, 1000, 0));
        listTeamTokens.push(teamTokens(0x3bFF85649F76bf0B6719657D1a7Ea7de4C6F77F5, 1 years, 6670, 100000, 0));

  
        // Team tokes 6.667%, blocked for 2 years
        listTeamTokens.push(teamTokens(0x1543E108cDA983eA3e4DF7fa599096EBa2BDC26b, 2 years, 32, 10, 0));
        listTeamTokens.push(teamTokens(0x0d05195af835F64cf42bC01276196E7D313Ca572, 2 years, 16, 10, 0));
        listTeamTokens.push(teamTokens(0x5a9447368cF7D1Ae134444263c51E07e8d8091eA, 2 years, 16, 10, 0));
        listTeamTokens.push(teamTokens(0x9293824d3A66Af4fdE6f29Aa016b784408B5cA5F, 2 years, 200, 1000, 0));
        listTeamTokens.push(teamTokens(0x8bbBd613EA5a840FDE29DFa6F6E53E93FE998c7F, 2 years, 6660, 100000, 0));

    }

    // fallback function can be used to buy tokens
    function() public payable ICOActive {
        require(!isReachedLimit());
        TokensHolder memory tokens = calculateTokens(msg.value);
        require(tokens.total > 0);
        token.mint(msg.sender, tokens.total);
        TokenPurchase(msg.sender, msg.sender, tokens.value, tokens.total);
        if (tokens.change > 0 && tokens.change <= msg.value) {
            msg.sender.transfer(tokens.change);
        }
        investors[msg.sender] = investors[msg.sender].add(tokens.value);
        addToStat(tokens.tokens, tokens.bonus);
		debugLog("rate ", priceInWei);
        manageStatus();
    }

    function hasStarted() public constant returns (bool) {
        return now >= startTime;
    }

    function hasFinished() public constant returns (bool) {
        return now >= endTime || isReachedLimit();
    }

    // Calculates amount of bonus tokens
    function getBonus(uint _value, uint _sold) internal constant returns (TokensHolder) {
        TokensHolder memory result;
        uint _bonus = 0;

        result.tokens = _value;
        for (uint8 i = 0; _value > 0 && i < bonusLimit.length; ++i) {
            uint current_bonus_part = 0;

            if (_value > 0 && _sold < bonusLimit[i]) {
                uint bonus_left = bonusLimit[i] - _sold;
                uint _bonusedPart = min(_value, bonus_left);
                current_bonus_part = current_bonus_part.add(percent(_bonusedPart, bonusPatterns[i]));
                _value = _value.sub(_bonusedPart);
                _sold = _sold.add(_bonusedPart);                
            }
            if (current_bonus_part > 0) {
                _bonus = _bonus.add(current_bonus_part);
            }
            
        }
        result.bonus = _bonus;
        return result;
    }



    // Are we reached tokens limit?
    function isReachedLimit() internal constant returns (bool) {
        return tokensCap.sub(totalSupply) == 0;
    }

    function manageStatus() internal {
        if (totalSupply >= minSuccess && !isSuccess) {
            successICO();
        }
        bool capIsReached = (totalSupply == tokensCap);
        if (capIsReached || (now >= endTime)) {
            if (!isSuccess) {
                failICO();
            }
            else {
                finishICO(false);
            }
        }
    }

    function calculateForValue(uint value) public constant returns (uint, uint, uint)
    {
        TokensHolder memory tokens = calculateTokens(value);
        return (tokens.total, tokens.tokens, tokens.bonus);
    }

    function calculateTokens(uint value) internal constant returns (TokensHolder)
    {
        require(value > 0);
        require(priceInWei * minTokens <= value);

        uint tokens = value.div(priceInWei);
        require(tokens > 0);
        uint remain = tokensCap.sub(totalSupply);
        uint change = 0;
        uint value_clear = 0;
        if (remain <= tokens) {
            tokens = remain;
            change = value.sub(tokens.mul(priceInWei));
            value_clear = value.sub(change);
        }
        else {
            value_clear = value;
        }

        TokensHolder memory bonus = getBonus(tokens, tokensSoldTotal);

        uint total = tokens + bonus.bonus;
        bonus.tokens = tokens;
        bonus.total = total;
        bonus.change = change;
        bonus.rate = priceInWei;
        bonus.value = value_clear;
        return bonus;

    }

    // Add tokens&bonus amount to counters
    function addToStat(uint tokens, uint bonus) internal {
        uint total = tokens + bonus;
        totalSupply = totalSupply.add(total);
        //tokensBought = tokensBought.add(tokens.div(multiplier));
        //tokensBonus = tokensBonus.add(bonus.div(multiplier));
        tokensSoldTotal = tokensSoldTotal.add(tokens);
    }

    // manual start ico after pause
    function startIco() external onlyOwner {
        require(icoState == IcoState.Paused);
        icoState = IcoState.Running;
        RunIco();
    }

    // manual pause ico
    function pauseIco() external onlyOwner {
        require(icoState == IcoState.Running);
        icoState = IcoState.Paused;
        PauseIco();
    }

    // auto success ico - cat withdraw ether now
    function successICO() internal
    {
        isSuccess = true;
        SuccessIco();
    }


    function finishICO(bool manualFinish) internal successICOState
    {
        if(!manualFinish) {
            bool capIsReached = (totalSupply == tokensCap);
            if (capIsReached && now < endTime) {
                endTime = now;
            }
        } else {
            endTime = now;
        }
        icoState = IcoState.Finished;
        tokensAreFrozen = false;
        // maybe this must be called as external one-time call
        token.unblock();
    }

    function failICO() internal
    {
        icoState = IcoState.Failed;
        ICOFails();
    }


    function refund() public ICOFailed
    {
        require(msg.sender != 0x0);
        require(investors[msg.sender] > 0);
        uint refundVal = investors[msg.sender];
        investors[msg.sender] = 0;

        uint balance = token.balanceOf(msg.sender);
        totalSupply = totalSupply.sub(balance);
        msg.sender.transfer(refundVal);

    }

    // Withdraw allowed only on success
    function withdraw(uint value) external onlyOwner successICOState {
        wallet.transfer(value);
    }

    // Generates team tokens after ICO finished
    function generateTeamTokens() internal ICOFinished {
        require(!teamTokensGenerated);
        teamTokensGenerated = true;
        if(tokensCap > totalSupply) {
            uint unsoldAmount = tokensCap.sub(totalSupply);
            token.mint(unsold, unsoldAmount);
            //debugLog(&#39;unsold &#39;, unsoldAmount);
            totalSupply = totalSupply.add(unsoldAmount);
            
        }
        uint totalSupplyTokens = totalSupply;
        totalSupplyTokens = totalSupplyTokens.mul(100);
        totalSupplyTokens = totalSupplyTokens.div(60);
        
        for (uint8 i = 0; i < listTeamTokens.length; ++i) {
            uint teamTokensPart = percent(totalSupplyTokens, listTeamTokens[i].percent);

            if (listTeamTokens[i].divider != 0) {
                teamTokensPart = teamTokensPart.div(listTeamTokens[i].divider);
            }

            if (listTeamTokens[i].maxTokens != 0 && listTeamTokens[i].maxTokens < teamTokensPart) {
                teamTokensPart = listTeamTokens[i].maxTokens;
            }

            token.mint(listTeamTokens[i].holder, teamTokensPart);

            
            if(listTeamTokens[i].freezePeriod != 0) {
                token.freezeTokens(listTeamTokens[i].holder, endTime + listTeamTokens[i].freezePeriod);
            }
            addToStat(teamTokensPart, 0);


        }

    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }


    //==========================
    // Methods for bots requests
    //==========================
    // set/update robot address
    function setRobot(address robot) public onlyOwner {
        require(robot != 0x0);
        _robot = robot;
    }

    // update token price in wei
    function setRate(uint newRate) public onlyTeam {
        require(newRate > 0);
        //todo min rate check! 0 - for debug
        priceInWei = newRate;
        updateRate(now, newRate);
    }

    // mb deprecated
    function robotRefund(address investor) public onlyTeam ICOFailed
    {
        require(investor != 0x0);
        require(investors[investor] > 0);
        uint refundVal = investors[investor];
        investors[investor] = 0;

        uint balance = token.balanceOf(investor);
        totalSupply = totalSupply.sub(balance);
        investor.transfer(refundVal);
    }


    function manualFinish() public onlyTeam successICOState
    {
        require(!hasFinished());
        finishICO(true);
        generateTeamTokens();
    }

    function autoFinishTime() public onlyTeam
    {
        require(hasFinished());
        manageStatus();
        generateTeamTokens();
    }

    //========
    // Helpers
    //========

    // calculation of min value
    function min(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }


    function percent(uint value, uint bonus) internal pure returns (uint) {
        return (value * bonus).div(100);
    }
}