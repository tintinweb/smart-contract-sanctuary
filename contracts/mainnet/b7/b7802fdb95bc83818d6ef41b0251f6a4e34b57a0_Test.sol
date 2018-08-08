pragma solidity ^0.4.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
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

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
    function transfer(address _to, uint256 _value) returns (bool) {
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

/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * @dev https://github.com/ethereum/EIPs/issues/20
 * @dev Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) allowed;


    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amout of tokens to be transfered
     */
    function transferFrom(address _from, address _to, uint256 _value) returns (bool) {
        var _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
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
     * @return A uint256 specifing the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}

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
    function Ownable() {
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
    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

}

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
    event Pause();
    event Unpause();

    bool public paused = false;


    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(paused);
        _;
    }

    /**
     * @dev called by the owner to pause, triggers stopped state
     */
    function pause() onlyOwner whenNotPaused public {
        paused = true;
        Pause();
    }

    /**
     * @dev called by the owner to unpause, returns to normal state
     */
    function unpause() onlyOwner whenPaused public {
        paused = false;
        Unpause();
    }
}

contract MintableToken is StandardToken, Ownable, Pausable {
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

    bool public mintingFinished = false;
    uint256 public constant maxTokensToMint = 1000000000 ether;
    uint256 public constant maxTokensToBuy  = 600000000 ether;

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
    function mint(address _to, uint256 _amount) whenNotPaused onlyOwner returns (bool) {
        return mintInternal(_to, _amount);
    }

    /**
    * @dev Function to stop minting new tokens.
    * @return True if the operation was successful.
    */
    function finishMinting() whenNotPaused onlyOwner returns (bool) {
        mintingFinished = true;
        MintFinished();
        return true;
    }

    function mintInternal(address _to, uint256 _amount) internal canMint returns (bool) {
        require(totalSupply.add(_amount) <= maxTokensToMint);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Mint(_to, _amount);
        Transfer(this, _to, _amount);
        return true;
    }
}

contract Test is MintableToken {

    string public constant name = "HIH";

    string public constant symbol = "HIH";

    bool public preIcoActive = false;

    bool public preIcoFinished = false;

    bool public icoActive = false;

    bool public icoFinished = false;

    bool public transferEnabled = false;

    uint8 public constant decimals = 18;

    uint256 public constant maxPreIcoTokens = 100000000 ether;

    uint256 public preIcoTokensCount = 0;

    uint256 public tokensForIco = 600000000 ether;

    address public wallet = 0xa74fF9130dBfb9E326Ad7FaE2CAFd60e52129CF0;

    uint256 public dateStart = 1511987870;

    uint256 public rateBase = 35000;

    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 amount);


    /**
    * @dev transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */
    function transfer(address _to, uint _value) whenNotPaused canTransfer returns (bool) {
        require(_to != address(this) && _to != address(0));
        return super.transfer(_to, _value);
    }

    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amout of tokens to be transfered
    */
    function transferFrom(address _from, address _to, uint _value) whenNotPaused canTransfer returns (bool) {
        require(_to != address(this) && _to != address(0));
        return super.transferFrom(_from, _to, _value);
    }

    /**
     * @dev Aprove the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint256 _value) whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    /**
     * @dev Modifier to make a function callable only when the transfer is enabled.
     */
    modifier canTransfer() {
        require(transferEnabled);
        _;
    }

    /**
    * @dev Function to stop transfering tokens.
    * @return True if the operation was successful.
    */
    function enableTransfer() onlyOwner returns (bool) {
        transferEnabled = true;
        return true;
    }

    function startPre() onlyOwner returns (bool) {
        require(!preIcoActive && !preIcoFinished && !icoActive && !icoFinished);
        preIcoActive = true;
        dateStart = block.timestamp;
        return true;
    }

    function finishPre() onlyOwner returns (bool) {
        require(preIcoActive && !preIcoFinished && !icoActive && !icoFinished);
        preIcoActive = false;
        tokensForIco = maxTokensToBuy.sub(totalSupply);
        preIcoTokensCount = totalSupply;
        preIcoFinished = true;
        return true;
    }

    function startIco() onlyOwner returns (bool) {
        require(!preIcoActive && preIcoFinished && !icoActive && !icoFinished);
        icoActive = true;
        return true;
    }

    function finishIco() onlyOwner returns (bool) {
        require(!preIcoActive && preIcoFinished && icoActive && !icoFinished);
        icoActive = false;
        icoFinished = true;
        return true;
    }

    modifier canBuyTokens() {
        require(preIcoActive || icoActive);
        require(block.timestamp >= dateStart);
        _;
    }

    function () payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) whenNotPaused canBuyTokens payable {
        require(beneficiary != 0x0);
        require(msg.value > 0);
        require(msg.value >= 10 finney);

        uint256 weiAmount = msg.value;
        uint256 tokens = 0;
        if(preIcoActive){
            tokens = buyPreIcoTokens(weiAmount);
        }else if(icoActive){
            tokens = buyIcoTokens(weiAmount);
        }
        mintInternal(beneficiary, tokens);
        forwardFunds();

    }

    // send ether to the fund collection wallet
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

    function changeWallet(address _newWallet) onlyOwner returns (bool) {
        require(_newWallet != 0x0);
        wallet = _newWallet;
        return true;
    }

    function buyPreIcoTokens(uint256 _weiAmount) internal returns(uint256){
        uint8 percents = 0;

        if(block.timestamp - dateStart <= 10 days){
            percents = 20;
        }

        if(block.timestamp - dateStart <= 8 days){
            percents = 40;
        }

        if(block.timestamp - dateStart <= 6 days){
            percents = 60;
        }

        if(block.timestamp - dateStart <= 4 days){
            percents = 80;
        }

        if(block.timestamp - dateStart <= 2 days){  // first week
            percents = 100;
        }

        uint256 tokens = _weiAmount.mul(rateBase).mul(2);

        if(percents > 0){
            tokens = tokens.add(tokens.mul(percents).div(100));    // add bonus
        }

        require(totalSupply.add(tokens) <= maxPreIcoTokens);

        return tokens;

    }

    function buyIcoTokens(uint256 _weiAmount) internal returns(uint256){
        uint256 rate = getRate();
        uint256 tokens = _weiAmount.mul(rate);

        tokens = tokens.add(tokens.mul(30).div(100));    // add bonus

        require(totalSupply.add(tokens) <= maxTokensToBuy);

        return tokens;

    }

    function getRate() internal returns(uint256){
        uint256 rate = rateBase;
        uint256 step = tokensForIco.div(5);


        uint8 additionalPercents = 0;

        if(totalSupply < step){
            additionalPercents = 0;
        }else{
            uint256 currentRound = totalSupply.sub(preIcoTokensCount).div(step);

            if(currentRound >= 4){
                additionalPercents = 30;
            }

            if(currentRound >= 3 && currentRound < 4){
                additionalPercents = 30;
            }

            if(currentRound >= 2&& currentRound < 3){
                additionalPercents = 20;
            }

            if(currentRound >= 1 && currentRound < 2){
                additionalPercents = 10;
            }
        }

        if(additionalPercents > 0){
            rate -= rateBase.mul(additionalPercents).div(100);    // add bonus
        }

        return rate;
    }

    function setDateStart(uint256 _dateStart) onlyOwner returns (bool) {
        require(_dateStart > block.timestamp);
        dateStart = _dateStart;
        return true;
    }

    function setRate(uint256 _rate) onlyOwner returns (bool) {
        require(_rate > 0);
        rateBase = _rate;
        return true;
    }

}