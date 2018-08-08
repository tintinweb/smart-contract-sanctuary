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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract B0xAccount is Ownable {
    using SafeMath for uint;

	mapping (address => Withdraw[]) public withdrawals;

    address public receiver1;
    address public receiver2;

    uint public numerator = 3;
    uint public denominator = 7;

    struct Withdraw {
        uint amount;
        uint blockNumber;
        uint blockTimestamp;
    }

    function() 
        public
        payable
    {
        require(msg.value > 0);
        uint toSend = address(this).balance.mul(numerator).div(denominator);
        require(receiver1.send(toSend));
        require(receiver2.send(toSend));
    }

    constructor(
        address _receiver1,
        address _receiver2)
        public
    {
        receiver1 = _receiver1;
        receiver2 = _receiver2;
    }

    function deposit()
        public
        payable
        returns(bool)
    {}

    function withdraw(
        uint _value)
        public
        returns(bool)
    {
        require(
            msg.sender == receiver1 
            || msg.sender == receiver2);

        uint amount = _value;
        if (amount > address(this).balance) {
            amount = address(this).balance;
        }

        withdrawals[msg.sender].push(Withdraw({
            amount: amount,
            blockNumber: block.number,
            blockTimestamp: block.timestamp
        }));

        return (msg.sender.send(amount));
    }

    function setReceiver1(
        address _receiver
    )
        public
        onlyOwner
    {
        require(_receiver != address(0) && _receiver != receiver1);
        receiver1 = _receiver;
    }

    function setReceiver2(
        address _receiver
    )
        public
        onlyOwner
    {
        require(_receiver != address(0) && _receiver != receiver2);
        receiver2 = _receiver;
    }

    function setNumeratorDenominator(
        uint _numerator,
        uint _denominator
    )
        public
        onlyOwner
    {
        require(_numerator > 0 && (_numerator*2) <= _denominator);
        numerator = _numerator;
        denominator = _denominator;
    }

    function getBalance()
        public
        view
        returns (uint)
    {
        return address(this).balance;
    }
}