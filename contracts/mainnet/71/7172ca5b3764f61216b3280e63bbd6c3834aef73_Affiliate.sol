// v7

/**
 * Affiliate.sol
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
 * @title Affiliate
 * @dev Affiliate contract collects and stores all affiliates and token earnings for each affiliate
 */
contract Affiliate is Ownable {

  TokenContract public tkn;
  mapping (address => uint256) affiliates;

  /**
   * @dev Add affiliates in affiliate mapping
   * @param _affiliates List of all affiliates
   * @param _amount Amount earned
   */
  function addAffiliates(address[] _affiliates, uint256[] _amount) onlyOwner public {
    require(_affiliates.length > 0);
    require(_affiliates.length == _amount.length);
    for (uint256 i = 0; i < _affiliates.length; i++) {
      affiliates[_affiliates[i]] = _amount[i];
    }
  }

  /**
   * @dev Claim reward collected through your affiliates
   */
  function claimReward() public {
    if (affiliates[msg.sender] > 0) {
      require(tkn.transfer(msg.sender, affiliates[msg.sender]));
      affiliates[msg.sender] = 0;
    }
  }

  /**
   * @dev Terminate the Affiliate contract and destroy it
   */
  function terminateContract() onlyOwner public {
    uint256 amount = tkn.balanceOf(address(this));
    require(tkn.transfer(owner, amount));
    selfdestruct(owner);
  }
}