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


contract TokensContract {
   function balanceOf(address who) public constant returns (uint256);
}

contract Insurance is Destructable, SafeMath  {

    uint start;
    uint payPeriodDays;
    uint rewardWeiCoefficient;
    uint256 contractBalance;
    uint256 buyPrice;
    address tokensContractAddress;

    mapping (address => uint256) buyersBalances;

    struct ClientInsurance {
        uint256 tokensCount;
        bool isApplied;
        bool exists;
    }



    mapping(address => ClientInsurance) insurancesMap;
    uint256 clientsCount;

    function Insurance() {
        tokensContractAddress = 0x687E1acAACd35D2B54d21F116F0aEf8C378F13eF;
        contractBalance = 0;
        clientsCount = 0;
        start = 1529922000;
        payPeriodDays = 365;

        /* 0.1 ether */
        rewardWeiCoefficient = 100000000000000000;

        /* 0.05 ether */
        buyPrice = 50000000000000000;
    }

    /**
     * Don&#39;t expect to just send money
     */
    function () payable {
        throw;
    }


    /**
     * Basic entry point for buy insurance
     */
    function buy() public payable {
        require(buyersBalances[msg.sender] == 0);
        require(msg.value == buyPrice);
        require(hasTokens(msg.sender));

        buyersBalances[msg.sender] = safeAdd(buyersBalances[msg.sender], msg.value);
        contractBalance = safeAdd(contractBalance, msg.value);
    }


    function isClient(address clientAddress) public constant onlyOwner returns(bool) {
        return insurancesMap[clientAddress].exists;
    }

    /**
     * Sets buy price for insurance
     */
    function setBuyPrice(uint256 priceWei) public onlyOwner {
        buyPrice = priceWei;
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

        /* Tokens exists */
        require(getTokensCount(to) >= insurancesMap[to].tokensCount);


        /* Start transfer */
        uint amount = getRewardWei(to);

        require(contractBalance > amount);
        insurancesMap[to].isApplied = true;
        contractBalance = safeSub(contractBalance, amount);

        to.transfer(amount);
    }

    function getRewardWei(address clientAddress) private constant returns (uint256) {
        uint tokensCount = insurancesMap[clientAddress].tokensCount;
        return safeMul(tokensCount, rewardWeiCoefficient);
    }

    function hasTokens(address clientAddress) private constant returns (bool) {
        return getTokensCount(clientAddress) > 0;
    }

    function getTokensCount(address clientAddress) private constant returns (uint256) {
        TokensContract tokensContract = TokensContract(tokensContractAddress);
        return tokensContract.balanceOf(clientAddress);
    }
}