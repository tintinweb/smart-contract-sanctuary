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

contract MFI {

    using SafeMath for uint;

    mapping(address => mapping(address => uint256)) internal allowed;
    mapping(address => uint256) deposits;
    mapping(address => uint256) borrowings;

    uint256 public totolFund;
    uint256 public intRate;
    uint256 public depIntRate;
    address public owner;

    event Transfer(address indexed from,  address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor() public {
        totolFund = 0;
        intRate = 30;
        depIntRate = 20;
        owner = msg.sender;
    }

    function() public payable {
        revert("contract don`t acccept any payment");
    } 

    function sender() public view returns(address) {
        return msg.sender;
    }

    function contractAddress() public view returns(address) {
        return this;
    }

    function balanceOf(address _owner) public view returns(uint) {
        return deposits[_owner];
    }

    function borrowerBalance(address _owner) public view returns(uint) {
        return borrowings[_owner];
    }

    function deposit(address _to, uint _value) public returns(bool) {
        require(_to != address(0), "Please provide valid address");

        deposits[_to] = deposits[_to].add(_value);
        totolFund += _value;
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function fundsAvailable() public view returns(uint) {
        return totolFund;
    }

    function borrow(address _from, uint _value) public returns(bool) {
        require(_from != address(0), "Please provide valid address");
        require(_value <= totolFund, "Unsufficient funds");

        borrowings[msg.sender] = borrowings[msg.sender].add(_value);
        totolFund -= _value;

        return true;
    }

    function approve(address _to, uint _value) public returns(bool) {
        require(_to != address(0), "Please provide valid address");

        allowed[msg.sender][_to] = _value;
        emit Approval(msg.sender, _to, _value);
        emit Transfer(owner, _to, _value);

        return true;
    }

    function allowance(address _owner, address _spender) public view returns(uint) {
        return allowed[_owner][_spender];
    }

    function paybackToDepositer(address _to, uint _amount) public returns(bool) {
        require(_to != address(0), "Please provide valid address");
        require(_amount <= deposits[_to], "Unsufficient funds");

        uint toPay;
        toPay = _amount + (_amount * depIntRate / 100);
        totolFund -= toPay;

        deposits[_to] = deposits[_to].sub(_amount);
        emit Transfer(owner, _to, toPay);

        return true;
    }

    function paybackToOwner(address _to, uint _amount) public returns(bool) {
        require(_to != address(0), "Please provide valid address");
        require(_amount <= borrowings[msg.sender], "Unsufficient funds");

        borrowings[msg.sender] = borrowings[msg.sender].sub(_amount);
        uint toPay;
        toPay = _amount + (_amount * intRate / 100);	
        totolFund += toPay;
        emit Transfer(msg.sender, _to, _amount);

        return true;
    }
}