/** 
	Etherus presale contract
*/


pragma solidity ^0.4.21;


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
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(address _spender, uint _addedValue) public returns (bool) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   *
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
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


/**
 * Mintable token
 */

contract MintableToken is StandardToken, Ownable {
    uint public totalSupply = 0;
    address private minter;
    bool public mintingEnabled = true;

    modifier onlyMinter() {
        require(minter == msg.sender);
        _;
    }

    function setMinter(address _minter) public onlyOwner {
        minter = _minter;
    }

    function mint(address _to, uint _amount) public onlyMinter {
        require(mintingEnabled);
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(address(0x0), _to, _amount);
    }

    function stopMinting() public onlyMinter {
        mintingEnabled = false;
    }
}




contract EtherusPreSale is Ownable {
    using SafeMath for uint;

    // Constants
    // =========

    uint private constant fractions = 1e18;
    uint private constant millions = 1e6*fractions;

    uint private constant CAP = 15*millions;
    uint private constant SALE_CAP = 5*millions;
    uint private constant ETR_USD_PRICE = 400; //in cents

    uint public ethPrice = 40000; //in cents

    // Events
    // ======

    event AltBuy(address holder, uint tokens, string txHash);
    event Buy(address holder, uint tokens);
    event RunSale();
    event PauseSale();
    event FinishSale();
    event PriceSet(uint USDPerETH);

    // State variables
    // ===============

    MintableToken public token;
    address authority; //An account to control the contract on behalf of the owner
    address robot; //An account to purchase tokens for altcoins
    bool public isOpen = false;

    // Constructor
    // ===========

    function EtherusPreSale(address _token, address _multisig, address _authority, address _robot) public {
        token = MintableToken(_token);
        authority = _authority;
        robot = _robot;
        transferOwnership(_multisig);
    }

    // Public functions
    // ================

    /**
    * Gets the bonus in percents for the specified sum
    */
    function getBonus(uint ethSum) public view returns (uint){

        uint usdSum = ethSum.mul(ethPrice).div(fractions);
        if(usdSum >= 1e6*100)
            return 100;
        if(usdSum >= 5e5*100)
            return 80;
        if(usdSum >= 2.5e5*100)
            return 70;
        if(usdSum >= 2e5*100)
            return 60;
        if(usdSum >= 1.5e5*100)
            return 50;
        if(usdSum >= 1.25e5*100)
            return 40;
        if(usdSum >= 1e5*100)
            return 30;
        if(usdSum >= 7.5e4*100)
            return 20;
        if(usdSum >= 5e4*100)
            return 10;

        return 0;
    }

    /**
    * Computes number of tokens with bonus for the specified ether. Correctly
    * adds bonuses if the sum is large enough to belong to several bonus intervals
    */
    function getTokensAmount(uint etherVal) public view returns (uint) {
        uint bonus = getBonus(etherVal);
        uint tokens = etherVal.mul(ethPrice).mul(100 + bonus).div(ETR_USD_PRICE*100);
        return tokens;
    }

    function buy(address to) public payable onlyOpen {
        uint amount = msg.value;
        uint tokens = getTokensAmountUnderCap(amount);

        owner.transfer(amount);
        token.mint(to, tokens);

        Buy(to, tokens);
    }

    function () public payable{
        buy(msg.sender);
    }

    // Modifiers
    // =================

    modifier onlyAuthority() {
        require(msg.sender == authority || msg.sender == owner);
        _;
    }

    modifier onlyRobot() {
        require(msg.sender == robot);
        _;
    }

    modifier onlyOpen() {
        require(isOpen);
        _;
    }

    // Priveleged functions
    // ====================

    /**
    * Used to buy tokens for altcoins.
    * Robot may call it before TokenSale officially starts to migrate early investors
    */
    function buyAlt(address to, uint etherAmount, string _txHash) public onlyRobot {
        uint tokens = getTokensAmountUnderCap(etherAmount);
        token.mint(to, tokens);
        AltBuy(to, tokens, _txHash);
    }

    function setAuthority(address _authority) public onlyOwner {
        authority = _authority;
    }

    function setRobot(address _robot) public onlyAuthority {
        robot = _robot;
    }

    function setPrice(uint usdPerEther) public onlyAuthority {
        //Ether is not expected to rate less than $1 and more than $100000 during presale
        require(1*100 <= usdPerEther && usdPerEther <= 100000*100);
        ethPrice = usdPerEther;
        PriceSet(ethPrice);
    }

    // SALE state management: start / pause / finalize
    // --------------------------------------------
    function open(bool _open) public onlyAuthority {
        isOpen = _open;
        if (_open) {
            RunSale();
        } else {
            PauseSale();
        }
    }

    function finalize() public onlyAuthority {
        uint diff = CAP.sub(token.totalSupply());
        if(diff > 0) //The unsold capacity moves to team
            token.mint(owner, diff);
        token.stopMinting();
        selfdestruct(owner);
        FinishSale();
    }

    // Private functions
    // =========================

    /**
    * Gets tokens for specified ether provided that they are still under the cap
    */
    function getTokensAmountUnderCap(uint etherAmount) private view returns (uint){
        uint tokens = getTokensAmount(etherAmount);
        require(tokens > 0);
        require(tokens.add(token.totalSupply()) <= SALE_CAP);
        return tokens;
    }

}