// v7

/**
 * InvestorStorage.sol
 * Investor storage is used for storing all investments amounts of investors. It creates a list of investors and their investments in a big hash map.
 * So when the new investments is made by investor, InvestorStorage adds it to the list as new investment, while storing investors address and invested amount.
 * It also gives the ability to get particular investor from the list and to refund him if its needed.
 */

pragma solidity ^0.4.23;

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
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

/**
 * @title InvestorStorage
 * @dev Investor storage is used for storing all investments amounts of investors. It creates a list of investors and their investments in a big hash map.
 * So when the new investments is made by investor, InvestorStorage adds it to the list as new investment, while storing investors address and invested amount.
 * It also gives the ability to get particular investor from the list and to refund him if its needed.
 */
contract InvestorsStorage is Ownable {

  mapping (address => uint256) public investors; // map the invested amount
  address[] public investorsList;
  address authorized;

  /**
   * @dev Allows only presale or crowdsale
   */
  modifier isAuthorized() { // modifier that allows only presale or crowdsale
    require(msg.sender==authorized);
    _;
  }

  /**
   * @dev Set authorized to given address - changes the authorization for presale or crowdsale
   * @param _authorized Authorized address
   */
  function setAuthorized(address _authorized) onlyOwner public { // change the authorization for presale or crowdsale
    authorized = _authorized;
  }

  /**
   * @dev Add new investment to investors storage
   * @param _investor Investors address
   * @param _amount Investment amount
   */
  function newInvestment(address _investor, uint256 _amount) isAuthorized public { // add the invested amount to the map
    if (investors[_investor] == 0) {
      investorsList.push(_investor);
    }
    investors[_investor] += _amount;
  }

  /**
   * @dev Get invested amount for given investor address
   * @param _investor Investors address
   */
  function getInvestedAmount(address _investor) public view returns (uint256) { // return the invested amount
    return investors[_investor];
  }

  /**
   * @dev Refund investment to the investor
   * @param _investor Investors address
   */
  function investmentRefunded(address _investor) isAuthorized public { // set the invested amount to 0 after the refund
    investors[_investor] = 0;
  }
}