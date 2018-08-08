pragma solidity ^0.4.23;

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
     * @dev Modifier to make a function callable only when the contract is paused.db.getCollection(&#39;transactions&#39;).find({})
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
    uint256 public constant maxTokensToMint = 7320000000 ether;

    modifier canMint() {
        require(!mintingFinished);
        _;
    }

    /**
    * @dev Function to mint tokens
    * @param _to The address that will recieve the minted tokens.
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

contract Avatar is MintableToken {

    string public constant name = "AvataraCoin";

    string public constant symbol = "VTR";

    bool public transferEnabled = false;

    uint8 public constant decimals = 18;

    uint256 public rate = 100000;

    uint256 public constant hardCap = 30000 ether;

    uint256 public weiFounded = 0;

    address public approvedUser = 0x48BAa849622fb4481c0C4D9E7a68bcE6b63b0213;

    address public wallet = 0x48BAa849622fb4481c0C4D9E7a68bcE6b63b0213;

    uint64 public dateStart = 1520348400;

    bool public icoFinished = false;

    uint256 public constant maxTokenToBuy = 4392000000 ether;

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

    modifier onlyOwnerOrApproved() {
        require(msg.sender == owner || msg.sender == approvedUser);
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

    function finishIco() onlyOwner returns (bool) {
        icoFinished = true;
        return true;
    }

    modifier canBuyTokens() {
        require(!icoFinished && weiFounded <= hardCap);
        _;
    }

    function setApprovedUser(address _user) onlyOwner returns (bool) {
        require(_user != address(0));
        approvedUser = _user;
        return true;
    }


    function changeRate(uint256 _rate) onlyOwnerOrApproved returns (bool) {
        require(_rate > 0);
        rate = _rate;
        return true;
    }

    function () payable {
        buyTokens(msg.sender);
    }

    function buyTokens(address beneficiary) canBuyTokens whenNotPaused payable {
        require(beneficiary != 0x0);
        require(msg.value >= 100 finney);

        uint256 weiAmount = msg.value;
        uint256 bonus = 0;
        uint256 totalWei = weiAmount.add(weiFounded);

        if(weiAmount >= 100 finney){
            bonus = 5;
        }else if (weiAmount >= 300 finney){
            bonus = 20;
        }else if (weiAmount >= 500 finney){
            bonus = 30;
        }else if (weiAmount >= 1 ether){
            bonus = 42;
        }else if (weiAmount >= 1500 finney){
            bonus = 45;
        }else if (weiAmount >= 3 ether){
            bonus = 51;
        }else if (weiAmount >= 6 ether){
            bonus = 60;
        }else if (weiAmount >= 15 ether){
            bonus = 70;
        }else if (weiAmount >= 330 ether){
            bonus = 75;
        }
        uint256 tokens = weiAmount.mul(rate);



        if(bonus > 0){
            tokens += tokens.mul(bonus).div(100);
        }

        require(totalSupply.add(tokens) <= maxTokenToBuy);

        mintInternal(beneficiary, tokens);
        weiFounded = totalWei;
        TokenPurchase(msg.sender, beneficiary, tokens);
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

    
}