pragma solidity ^0.4.0;


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of &quot;user permissions&quot;.
 */
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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
  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

contract Claimable {

    function claim(address to) public;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

}


contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}


/**
 * Safe unsigned safe math.
 *
 * https://blog.aragon.one/library-driven-development-in-solidity-2bebcaf88736#.750gwtwli
 *
 * Originally from https://raw.githubusercontent.com/AragonOne/zeppelin-solidity/master/contracts/SafeMathLib.sol
 *
 * Maintained here until merged to mainline zeppelin-solidity.
 *
 */
library SafeMathLibExt {

  function times(uint a, uint b) returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function divides(uint a, uint b) returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function minus(uint a, uint b) returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function plus(uint a, uint b) returns (uint) {
    uint c = a + b;
    assert(c>=a);
    return c;
  }

}


contract Destructable is Ownable {

    function burn() onlyOwner {
        selfdestruct(owner);
    }

}


contract Insurance is Destructable, Claimable, SafeMath  {

    uint start;
    uint payPeriodDays;
    uint rewardWeiCoefficient;

    struct ClientInsurance {
        uint256 tokensCount;
        bool isApplied;
        bool exists;
    }



    mapping(address => ClientInsurance) insurancesMap;
    uint256 clientsCount;

    function Insurance() {
        clientsCount = 0;
        start = 1529922000;
        payPeriodDays = 365;

        /* 0.1 ether */
        rewardWeiCoefficient = 100000000000000000;
    }

    function isClient(address clientAddress) public constant onlyOwner returns(bool) {
        return insurancesMap[clientAddress].exists;
    }

    function addBuyer(address clientAddress, uint256 tokensCount) public onlyOwner {
        require( (clientAddress != address(0)) && (tokensCount > 0) );

        /* Can be called only once for address */
        require(!insurancesMap[clientAddress].exists);

        insurancesMap[clientAddress] = ClientInsurance(tokensCount, false, true);
    }

    function claim(address to) public onlyOwner {

        /* Can be called only on time range */
        require(now > start && now < start + payPeriodDays * 24 * 60 * 60);


        /* Can be called once for address */
        require( (to != address(0)) && (insurancesMap[to].exists) && (!insurancesMap[to].isApplied) );


        /* Start transfer */
        uint amount = getRewardWei(to);

        require(owner.balance > amount);
        insurancesMap[to].isApplied = true;
        Transfer(owner, to, amount);
    }

    function getRewardWei(address clientAddress) private constant returns (uint256) {
        uint tokensCount = insurancesMap[clientAddress].tokensCount;
        return safeMul(tokensCount, rewardWeiCoefficient);
    }
}