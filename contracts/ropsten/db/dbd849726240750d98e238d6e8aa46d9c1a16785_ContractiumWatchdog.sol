pragma solidity ^0.4.18 ;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor() public {
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
   * @dev Allows the current owner to relinquish control of the contract.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
    // benefit is lost if &#39;b&#39; is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return a / b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ContractiumInterface {
    function balanceOf(address who) public view returns (uint256);
    function contractSpend(address _from, uint256 _value) public returns (bool);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256);
    function owner() public view returns (address);
    function bonusRateOneEth() public view returns (uint256);
    function unitsOneEthCanBuy() public view returns (uint256);
}

contract ContractiumWatchdog is Ownable {

    using SafeMath for uint256;

    ContractiumInterface ctuContract;
    address public constant WATCHDOG = 0xC19174dA6216f07EEa585f760fa06Ed19eC27fDc;
    address public constant CONTRACTIUM = 0x0dc319Fa14b3809ea2f0f9Ae28311f957a9bE4a3;
    address public ownerCtuContract;
    address public owner;

    uint8 public constant decimals = 18;
    uint256 public unitsOneEthCanBuy = 15000;
    uint256 public bonusRateOneEth = 0;


    function() public payable {

        require(msg.sender != owner);

        // number of tokens to sale in wei
        uint256 amount = msg.value.mul(unitsOneEthCanBuy);

        // amount of bonus tokens
        uint256 amountBonus = msg.value.mul(bonusRateOneEth);
        
        // amount with bonus value
        amount = amount.add(amountBonus);

        // offering validation
        uint256 remain = ctuContract.balanceOf(ownerCtuContract);
        require(remain >= amount);

        address _from = ownerCtuContract;
        address _to = msg.sender;
        ctuContract.transferFrom(_from, _to, amount);
    

        //Transfer ether to CONTRACTIUM and  WATCHDOG
        uint256 oneTenth = msg.value.div(10);
        uint256 nineTenth = msg.value.sub(oneTenth);

        WATCHDOG.transfer(oneTenth);
        ownerCtuContract.transfer(nineTenth);  
                              
    }

    constructor() public {
        ctuContract =  ContractiumInterface(CONTRACTIUM);
        ownerCtuContract = ctuContract.owner();
        bonusRateOneEth = ctuContract.bonusRateOneEth();
        unitsOneEthCanBuy = ctuContract.unitsOneEthCanBuy();
        owner = msg.sender;
    }
    
    function setCtuContract(address _ctuAddress) public onlyOwner {
        require(_ctuAddress != address(0x0));
        ctuContract = ContractiumInterface(_ctuAddress);
        ownerCtuContract = ctuContract.owner();
        bonusRateOneEth = ctuContract.bonusRateOneEth();
        unitsOneEthCanBuy = ctuContract.unitsOneEthCanBuy();
    }

    function setRateAgain() public onlyOwner {
        ownerCtuContract = ctuContract.owner();
        bonusRateOneEth = ctuContract.bonusRateOneEth();
    }

    function transferOwnership(address _addr) public onlyOwner{
        super.transferOwnership(_addr);
    }

}