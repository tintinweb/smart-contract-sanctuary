// v7

/**
 * Vault.sol
 * Vault contract is used for storing all team/founder tokens amounts from the crowdsale. It adds team members and their amounts in a list.
 * Vault securely stores team members funds and freezes the particular X amount on set X amount of time.
 * It also gives the ability to release the funds when the X set time limit is met.
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
 * @title TokenContract
 * @dev Token contract interface with transfer and balanceOf functions which need to be implemented
 */
interface TokenContract {

  /**
  * @dev Transfer funds to recipient address
  * @param _recipient Recipients address
  * @param _amount Amount to transfer
  */
  function transfer(address _recipient, uint256 _amount) external returns (bool);

  /**
   * @dev Return balance of holders address
   * @param _holder Holders address
   */
  function balanceOf(address _holder) external view returns (uint256);
}

/**
 * @title Vault
 * Vault contract is used for storing all team/founder tokens amounts from the crowdsale. It adds team members and their amounts in a list.
 * Vault securely stores team members funds and freezes the particular X amount on set X amount of time.
 * It also gives the ability to release the funds when the X set time limit is met.
 */
contract Vault is Ownable {
  TokenContract public tkn;

  uint256 public releaseDate;

  struct Member {
    address memberAddress;
    uint256 tokens;
  }

  Member[] public team;

  /**
   * @dev The Vault constructor sets the release date in epoch time
   */
  constructor() public {
    releaseDate = 1561426200; // set release date in epoch
  }

  /**
   * @dev Release tokens from vault - unlock them and destroy contract
   */
  function releaseTokens() onlyOwner public {
    require(releaseDate > block.timestamp);
    uint256 amount;
    for (uint256 i = 0; i < team.length; i++) {
      require(tkn.transfer(team[i].memberAddress, team[i].tokens));
    }
    amount = tkn.balanceOf(address(this));
    require(tkn.transfer(owner, amount));
    selfdestruct(owner);
  }

  /**
   * @dev Add members to vault to lock funds
   * @param _member Member to be added to the vault
   * @param _tokens Amount of tokens to be locked
   */
  function addMembers(address[] _member, uint256[] _tokens) onlyOwner public {
    require(_member.length > 0);
    require(_member.length == _tokens.length);
    Member memory member;
    for (uint256 i = 0; i < _member.length; i++) {
      member.memberAddress = _member[i];
      member.tokens = _tokens[i];
      team.push(member);
    }
  }
}