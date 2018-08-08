/*************************************************************************
 * This contract has been merged with solidify
 * https://github.com/tiesnetwork/solidify
 *************************************************************************/
 
/** 
	Ties.Network TokenSale contract
	@author Dmitry Kochin <<span class="__cf_email__" data-cfemail="046f44706d61772a6a6170736b766f">[email&#160;protected]</span>>
*/


pragma solidity ^0.4.14;


/*************************************************************************
 * import "./include/MintableToken.sol" : start
 *************************************************************************/

/*************************************************************************
 * import "zeppelin/contracts/token/StandardToken.sol" : start
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
  function balanceOf(address who) constant returns (uint256);
  function transfer(address to, uint256 value) returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}
/*************************************************************************
 * import "./ERC20Basic.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "../math/SafeMath.sol" : start
 *************************************************************************/


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
/*************************************************************************
 * import "../math/SafeMath.sol" : end
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
  function allowance(address owner, address spender) constant returns (uint256);
  function transferFrom(address from, address to, uint256 value) returns (bool);
  function approve(address spender, uint256 value) returns (bool);
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
   * @return A uint256 specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
  }

}
/*************************************************************************
 * import "zeppelin/contracts/token/StandardToken.sol" : end
 *************************************************************************/
/*************************************************************************
 * import "zeppelin/contracts/ownership/Ownable.sol" : start
 *************************************************************************/


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
    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }

}
/*************************************************************************
 * import "zeppelin/contracts/ownership/Ownable.sol" : end
 *************************************************************************/

/**
 * Mintable token
 */

contract MintableToken is StandardToken, Ownable {
    uint public totalSupply = 0;
    address private minter;

    modifier onlyMinter(){
        require(minter == msg.sender);
        _;
    }

    function setMinter(address _minter) onlyOwner {
        minter = _minter;
    }

    function mint(address _to, uint _amount) onlyMinter {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);
        Transfer(address(0x0), _to, _amount);
    }
}
/*************************************************************************
 * import "./include/MintableToken.sol" : end
 *************************************************************************/



contract TokenSale is Ownable {
    using SafeMath for uint;

    // Constants
    // =========

    uint private constant fractions = 1e18;
    uint private constant millions = 1e6*fractions;

    uint private constant CAP = 200*millions;
    uint private constant SALE_CAP = 140*millions;
    uint private constant BONUS_STEP = 14*millions;

    uint public price = 0.0008 ether;

    // Events
    // ======

    event AltBuy(address holder, uint tokens, string txHash);
    event Buy(address holder, uint tokens);
    event RunSale();
    event PauseSale();
    event FinishSale();
    event PriceSet(uint weiPerTIE);

    // State variables
    // ===============

    MintableToken public token;
    address authority; //An account to control the contract on behalf of the owner
    address robot; //An account to purchase tokens for altcoins
    bool public isOpen = false;

    // Constructor
    // ===========

    function TokenSale(address _token, address _multisig, address _authority, address _robot){
        token = MintableToken(_token);
        authority = _authority;
        robot = _robot;
        transferOwnership(_multisig);
    }

    // Public functions
    // ================

    function getCurrentBonus() constant returns (uint){
        return getBonus(token.totalSupply());
    }

    /**
    * Gets the bonus for the specified total supply
    */
    function getBonus(uint totalSupply) constant returns (uint){
        bytes10 bonuses = "\x14\x11\x0F\x0C\x0A\x08\x06\x04\x02\x00";
        uint level = totalSupply/BONUS_STEP;
        if(level < bonuses.length)
            return uint(bonuses[level]);
        return 0;
    }

    /**
    * Computes number of tokens with bonus for the specified ether. Correctly
    * adds bonuses if the sum is large enough to belong to several bonus intervals
    */
    function getTokensAmount(uint etherVal) constant returns (uint) {
        uint tokens = 0;
        uint totalSupply = token.totalSupply();
        while(true){
            //How much we have before next bonus interval
            uint gap = BONUS_STEP - totalSupply%BONUS_STEP;
            //Bonus at the current interval
            uint bonus = 100 + getBonus(totalSupply);
            //The cost of the entire remainder of this interval
            uint gapCost = gap*(price*100)/fractions/bonus;
            if(gapCost >= etherVal){
                //If the gap is large enough just sell the necessary amount of tokens
                tokens += etherVal.mul(bonus).mul(fractions)/(price*100);
                break;
            }else{
                //If the gap is too small sell it and diminish the price by its cost for the next iteration
                tokens += gap;
                etherVal -= gapCost;
                totalSupply += gap;
            }
        }
        return tokens;
    }

    function buy(address to) onlyOpen payable{
        uint amount = msg.value;
        uint tokens = getTokensAmountUnderCap(amount);

        owner.transfer(amount);
        token.mint(to, tokens);

        Buy(to, tokens);
    }

    function () payable{
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
    function buyAlt(address to, uint etherAmount, string _txHash) onlyRobot {
        uint tokens = getTokensAmountUnderCap(etherAmount);
        token.mint(to, tokens);
        AltBuy(to, tokens, _txHash);
    }

    function setAuthority(address _authority) onlyOwner {
        authority = _authority;
    }

    function setRobot(address _robot) onlyAuthority {
        robot = _robot;
    }

    function setPrice(uint etherPerTie) onlyAuthority {
        //Ether is not expected to rate less than $96 and more than $480 during token sale
        require(0.0005 ether <= etherPerTie && etherPerTie <= 0.0025 ether);
        price = etherPerTie;
        PriceSet(price);
    }

    // SALE state management: start / pause / finalize
    // --------------------------------------------
    function open(bool open) onlyAuthority {
        isOpen = open;
        open ? RunSale() : PauseSale();
    }

    function finalize() onlyAuthority {
        uint diff = CAP.sub(token.totalSupply());
        if(diff > 0) //The unsold capacity moves to team
            token.mint(owner, diff);
        selfdestruct(owner);
        FinishSale();
    }

    // Private functions
    // =========================

    /**
    * Gets tokens for specified ether provided that they are still under the cap
    */
    function getTokensAmountUnderCap(uint etherAmount) private constant returns (uint){
        uint tokens = getTokensAmount(etherAmount);
        require(tokens > 0);
        require(tokens.add(token.totalSupply()) <= SALE_CAP);
        return tokens;
    }

}