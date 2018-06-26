pragma solidity ^0.4.17;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
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
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract MFI {
    mapping (address => mapping (address => uint256)) internal allowed;

    using SafeMath for uint256;

    mapping(address => uint256) deposits;
    mapping(address => uint256) borrowings;
    uint256 totalFund = 0;

    uint256 intRate = 30;
    uint256 depIntRate = 20;

    address public owner;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function MFI() public {
        owner = msg.sender;
        totalFund = 0;
    }

    function() public payable { }

    function sender() view public returns (address) {
        return msg.sender;
    }
    //MFI.deployed().then(function(f) {f.contractAddress().then(function(f) {console.log(f.toString())})})
    function contractAddress() public view returns (address) {
        return this;
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return deposits[_owner];
    }

    function borrowerBalance(address _owner) public view returns (uint256 balance) {
        return borrowings[_owner];
    }

    //MFI.deployed().then(function(f) {f.deposit(&#39;0xcf3d4964a9119c98729de14015c463700d9c5f79&#39;,10000).then(function(f) {console.log(f.toString())})})
    function deposit(address _to, uint256 _value) payable public returns (bool) {
        //require(_to != address(0));
        deposits[_to] = deposits[_to].add(_value);

        totalFund += _value;
        emit Transfer(msg.sender, owner, _value);

        return true;
    }
    //MFI.deployed().then(function(f) {f.fundsAvailable().then(function(f) {console.log(f.toString())})})
    function fundsAvailable() view public returns (uint256) {
        return totalFund;
    }
    function borrow(address _from, uint256 _value) payable public returns (bool) {
        require(_from != address(0));
        require(_value <= totalFund);
        borrowings[msg.sender] = borrowings[msg.sender].add(_value);
        totalFund -= _value;

        return true;
    }

    function approve(address _to, uint256 _value) public returns (bool) {
        //allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _to, _value);
        emit Transfer(owner, _to, _value);
        return true;
    }
/*
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }
*/
    function paybackToDepositer(address _to, uint256 _amount) payable public returns (bool) {
        require(_to != address(0));
        require(_amount <= deposits[_to]);
        uint256 toPay;
        toPay = _amount + ( _amount * depIntRate / 100);
        totalFund -= toPay;

        deposits[_to] = deposits[_to].sub(_amount);
        emit Transfer(owner, _to, toPay);

        return true;
    }

    function paybackToOwner(address _to, uint256 _amount) payable public returns (bool) {
        require(_to != address(0));
        require(_amount <= borrowings[msg.sender]);

        borrowings[msg.sender] = borrowings[msg.sender].sub(_amount);
        uint256 toPay;
        toPay = _amount + ( _amount * intRate / 100);
        totalFund += toPay;
        emit Transfer(msg.sender, _to, toPay);

        return true;
    }
}