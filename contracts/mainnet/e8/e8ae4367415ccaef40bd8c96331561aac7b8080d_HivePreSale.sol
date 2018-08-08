pragma solidity ^0.4.18;


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



library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
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


contract Hive is ERC20 {

    using SafeMath for uint;
    string public constant name = "UHIVE";
    string public constant symbol = "HVE";    
    uint256 public constant decimals = 18;
    uint256 _totalSupply = 80000000000 * (10**decimals);

    mapping (address => bool) public frozenAccount;
    event FrozenFunds(address target, bool frozen);

    // Balances for each account
    mapping(address => uint256) balances;

    // Owner of account approves the transfer of an amount to another account
    mapping(address => mapping (address => uint256)) allowed;

    // Owner of this contract
    address public owner;

    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function changeOwner(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        owner = _newOwner;
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        FrozenFunds(target, freeze);
    }

    function isFrozenAccount(address _addr) public constant returns (bool) {
        return frozenAccount[_addr];
    }

    function destroyCoins(address addressToDestroy, uint256 amount) onlyOwner public {
        require(addressToDestroy != address(0));
        require(amount > 0);
        require(amount <= balances[addressToDestroy]);
        balances[addressToDestroy] -= amount;    
        _totalSupply -= amount;
    }

    // Constructor
    function Hive() public {
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }

    function totalSupply() public constant returns (uint256 supply) {
        supply = _totalSupply;
    }

    // What is the balance of a particular account?
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
    
    // Transfer the balance from owner&#39;s account to another account
    function transfer(address _to, uint256 _value) public returns (bool success) {        
        if (_to != address(0) && isFrozenAccount(msg.sender) == false && balances[msg.sender] >= _value && _value > 0 && balances[_to].add(_value) > balances[_to]) {
            balances[msg.sender] = balances[msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    // Send _value amount of tokens from address _from to address _to
    // The transferFrom method is used for a withdraw workflow, allowing contracts to send
    // tokens on your behalf, for example to "deposit" to a contract address and/or to charge
    // fees in sub-currencies; the command should fail unless the _from account has
    // deliberately authorized the sender of the message via some mechanism; we propose
    // these standardized APIs for approval:
    function transferFrom(address _from,address _to, uint256 _value) public returns (bool success) {
        if (_to != address(0) && isFrozenAccount(_from) == false && balances[_from] >= _value && allowed[_from][msg.sender] >= _value && _value > 0 && balances[_to].add(_value) > balances[_to]) {
            balances[_from] = balances[_from].sub(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
            balances[_to] = balances[_to].add(_value);
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
    
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
}

contract HivePreSale {

    using SafeMath for uint256;
    // The token being sold
    Hive public token;

    // Address where funds are collected
    address public vaultWallet;

    // How many token units a buyer gets per wei
    uint256 public hivePerEther;

    // How much hive cost per USD
    uint256 public hivePerUSD;

    // Owner of this contract
    address public owner;

    //Flag paused sale
    bool public paused;

    uint256 public openingTime;
    uint256 public closingTime;

    uint256 public minimumWei;

    /**
    * @dev Reverts if not in crowdsale time range. 
    */
    modifier onlyWhileOpen {
        require(now >= openingTime && now <= closingTime && paused == false);
        _;
    }

    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function HivePreSale(uint256 _hivePerEther, address _vaultWallet, Hive _token, uint256 _openingTime, uint256 _closingTime) public {
        hivePerEther = _hivePerEther;
        vaultWallet = _vaultWallet;
        token = _token;
        owner = msg.sender;
        openingTime = _openingTime;
        closingTime = _closingTime;
        paused = false;
        hivePerUSD = 667; //each hive is 0.0015$
        minimumWei = 100000000000000000; //0.1 Ether
    }

    function () external payable {
        buyTokens(msg.sender);
    }
    
    /**
    * Event for token purchase logging
    * @param purchaser who paid for the tokens
    * @param beneficiary who got the tokens
    * @param value weis paid for purchase
    * @param amount amount of tokens purchased
    */
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    /**
    * @dev Checks whether the period in which the crowdsale is open has already elapsed.
    * @return Whether crowdsale period has elapsed
    */
    function hasClosed() public view returns (bool) {
        return now > closingTime;
    }


    /**
    * @dev low level token purchase ***DO NOT OVERRIDE***
    * @param _beneficiary Address performing the token purchase
    */
    function buyTokens(address _beneficiary) public payable onlyWhileOpen {

        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);
        _verifyAvailability(tokens);

        _processPurchase(_beneficiary, tokens);
        TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);
        _forwardFunds();
    }

    function changeRate(uint256 _newRate) onlyOwner public {
        require(_newRate > 0);
        hivePerEther = _newRate;
    }

    function changeMinimumWei(uint256 _newMinimumWei) onlyOwner public {        
        minimumWei = _newMinimumWei;
    }

    function extendSale(uint256 _newClosingTime) onlyOwner public {
        require(_newClosingTime > closingTime);
        closingTime = _newClosingTime;
    }

    function haltSale() onlyOwner public {
        paused = true;
    }

    function resumeSale() onlyOwner public {
        paused = false;
    }

    //Called from outside to auto handle BTC and FIAT purchases
    function forwardTokens(address _beneficiary, uint256 totalTokens) onlyOwner onlyWhileOpen public {        
        _preValidateTokenTransfer(_beneficiary, totalTokens);
        _deliverTokens(_beneficiary, totalTokens);
    }

    function changeOwner(address _newOwner) onlyOwner public {
        require(_newOwner != address(0));
        owner = _newOwner;
    }

    function changeVaultWallet(address _newVaultWallet) onlyOwner public {
        require(_newVaultWallet != address(0));
        vaultWallet = _newVaultWallet;
    }

    //Called after the sale ends to withdraw remaining unsold tokens
    function withdrawUnsoldTokens() onlyOwner public {    
        uint256 unsold = token.balanceOf(this);
        token.transfer(owner, unsold);
    }

    function terminate() public onlyOwner {
        selfdestruct(owner);
    }

    // -----------------------------------------
    // Internal interface (extensible)
    // -----------------------------------------

    /**
    * @dev Validation of an incoming purchase.
    * @param _beneficiary Address performing the token purchase
    * @param _weiAmount Value in wei involved in the purchase
    */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view {
        require(hasClosed() == false);
        require(paused == false);
        require(_beneficiary != address(0));
        require(_weiAmount >= minimumWei);
    }

    /**
    * @dev Validation of a token transfer, used with BTC purchase.
    * @param _beneficiary Address performing the token purchase
    * @param _tokenAmount Number to tokens to transfer
    */
    function _preValidateTokenTransfer(address _beneficiary, uint256 _tokenAmount) internal view {
        require(hasClosed() == false);
        require(paused == false);
        require(_beneficiary != address(0));
        require(_tokenAmount > 0);
    }

    /**
    * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
    * @param _beneficiary Address performing the token purchase
    * @param _tokenAmount Number of tokens to be emitted
    */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) private {
        token.transfer(_beneficiary, _tokenAmount);
    }

    /**
    * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
    * @param _beneficiary Address receiving the tokens
    * @param _tokenAmount Number of tokens to be purchased
    */
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) private {
        _deliverTokens(_beneficiary, _tokenAmount);
    }
  

    /**
    * @dev Override to extend the way in which ether is converted to tokens.
    * @param _weiAmount Value in wei to be converted into tokens
    * @return Number of tokens that can be purchased with the specified _weiAmount
    */
    function _getTokenAmount(uint256 _weiAmount) private view returns (uint256) {
        return _weiAmount.mul(hivePerEther);
    }

    /**
    * @dev Determines how ETH is stored/forwarded on purchases.
    */
    function _forwardFunds() private {
        vaultWallet.transfer(msg.value);
    }

    function _verifyAvailability(uint256 _requestedAmount) private view {
        uint256 remaining = token.balanceOf(this);
        require(remaining >= _requestedAmount);
    }
}