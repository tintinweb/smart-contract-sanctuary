pragma solidity ^0.4.24;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";

contract DividendToken{
 
    using SafeMath for uint256;

    string public name = "Dividend Token";
    string public symbol = "DIV";
    uint8 public decimals = 0;  
    uint256 public totalSupply_ = 1000000;
    uint256 totalDividendPoints = 0;
    uint256 unclaimedDividends = 0;
    uint256 pointMultiplier = 1000000000000000000;
    address owner;

    
    struct account{
         uint256 balance;
         uint256 lastDividendPoints;
     }

    mapping(address => account) public balanceOf;
    
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );


    event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
    );

    modifier onlyOwner() {
    require(msg.sender == owner);
    _;
    }

    modifier updateDividend(address investor) {
    uint256 owing = dividendsOwing(investor);
    if(owing > 0) {
        unclaimedDividends = unclaimedDividends.sub(owing);
        balanceOf[investor].balance = balanceOf[investor].balance.add(owing);
        balanceOf[investor].lastDividendPoints = totalDividendPoints;
        }
     _;
    }

    constructor () public {
        // Initially assign all tokens to the contract's creator.
        balanceOf[msg.sender].balance = totalSupply_;
        owner = msg.sender;
        emit Transfer(address(0), msg.sender, totalSupply_);
    }

    
    /**
     new dividend = totalDividendPoints - investor's lastDividnedPoint
     ( balance * new dividend ) / points multiplier
    
    **/
    function dividendsOwing(address investor) internal returns(uint256) {
        uint256 newDividendPoints = totalDividendPoints.sub(balanceOf[investor].lastDividendPoints);
        return (balanceOf[investor].balance.mul(newDividendPoints)).div(pointMultiplier);
    }

    /**

    **/
    function disburse(uint256 amount)  onlyOwner public{
    totalDividendPoints = totalDividendPoints.add((amount.mul(pointMultiplier)).div(totalSupply_));
    totalSupply_ = totalSupply_.add(amount);
    unclaimedDividends =  unclaimedDividends.add(amount);
    }

    function totalSupply_() public view returns (uint256) {
    return totalSupply_;
    }

   function transfer(address _to, uint256 _value) updateDividend(msg.sender) updateDividend(_to) public returns (bool) {
    require(msg.sender != _to);
    require(_to != address(0));
    require(_value <= balanceOf[msg.sender].balance);
    balanceOf[msg.sender].balance = (balanceOf[msg.sender].balance).sub(_value);
    balanceOf[_to].balance = (balanceOf[_to].balance).add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

 
  function balanceOf(address _owner) public view returns (uint256) {
    return balanceOf[_owner].balance;
  }


   mapping (address => mapping (address => account)) internal allowed;


 
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    updateDividend(_from)
    updateDividend(_to)
    public
    returns (bool)
  {
    require(_to != _from);
    require(_to != address(0));
    require(_value <= balanceOf[_from].balance);
    require(_value <= (allowed[_from][msg.sender]).balance);

    balanceOf[_from].balance = (balanceOf[_from].balance).sub(_value);
    balanceOf[_to].balance = (balanceOf[_to].balance).add(_value);
    (allowed[_from][msg.sender]).balance = (allowed[_from][msg.sender]).balance.sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value) public returns (bool) {
    (allowed[msg.sender][_spender]).balance = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

  
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return (allowed[_owner][_spender]).balance;
  }

 
  function increaseApproval(
    address _spender,
    uint _addedValue
  )
    public
    returns (bool)
  {
    (allowed[msg.sender][_spender]).balance = (
      (allowed[msg.sender][_spender]).balance.add(_addedValue));
    emit Approval(msg.sender, _spender, (allowed[msg.sender][_spender]).balance);
    return true;
  }

  
  function decreaseApproval(
    address _spender,
    uint _subtractedValue
  )
    public
    returns (bool)
  {
    uint oldValue = (allowed[msg.sender][_spender]).balance;
    if (_subtractedValue > oldValue) {
      (allowed[msg.sender][_spender]).balance = 0;
    } else {
      (allowed[msg.sender][_spender]).balance = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, (allowed[msg.sender][_spender]).balance);
    return true;
  }


}

pragma solidity ^0.4.23;


/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
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
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "byzantium",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}