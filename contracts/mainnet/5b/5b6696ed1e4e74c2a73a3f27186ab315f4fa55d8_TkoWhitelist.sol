pragma solidity ^0.4.18;


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
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
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
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

/// @title Whitelist for TKO token sale.
/// @author Takeoff Technology OU - <<a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="3950575f56794d58525c565f5f174e4a">[email&#160;protected]</a>>
/// @dev Based on code by OpenZeppelin&#39;s WhitelistedCrowdsale.sol
contract TkoWhitelist is Ownable{

    using SafeMath for uint256;

    // Manage whitelist account address.
    address public admin;

    mapping(address => uint256) internal totalIndividualWeiAmount;
    mapping(address => bool) internal whitelist;

    event AdminChanged(address indexed previousAdmin, address indexed newAdmin);


    /**
     * TkoWhitelist
     * @dev TkoWhitelist is the storage for whitelist and total amount by contributor&#39;s address.
     * @param _admin Address of managing whitelist.
     */
    function TkoWhitelist (address _admin) public {
        require(_admin != address(0));
        admin = _admin;
    }

    /**
     * @dev Throws if called by any account other than the owner or the admin.
     */
    modifier onlyOwnerOrAdmin() {
        require(msg.sender == owner || msg.sender == admin);
        _;
    }

    /**
     * @dev Allows the current owner to change administrator account of the contract to a newAdmin.
     * @param newAdmin The address to transfer ownership to.
     */
    function changeAdmin(address newAdmin) public onlyOwner {
        require(newAdmin != address(0));
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }


    /**
      * @dev Returen whether the beneficiary is whitelisted.
      */
    function isWhitelisted(address _beneficiary) external view onlyOwnerOrAdmin returns (bool) {
        return whitelist[_beneficiary];
    }

    /**
     * @dev Adds single address to whitelist.
     * @param _beneficiary Address to be added to the whitelist
     */
    function addToWhitelist(address _beneficiary) external onlyOwnerOrAdmin {
        whitelist[_beneficiary] = true;
    }

    /**
     * @dev Adds list of addresses to whitelist.
     * @param _beneficiaries Addresses to be added to the whitelist
     */
    function addManyToWhitelist(address[] _beneficiaries) external onlyOwnerOrAdmin {
        for (uint256 i = 0; i < _beneficiaries.length; i++) {
            whitelist[_beneficiaries[i]] = true;
        }
    }

    /**
     * @dev Removes single address from whitelist.
     * @param _beneficiary Address to be removed to the whitelist
     */
    function removeFromWhitelist(address _beneficiary) external onlyOwnerOrAdmin {
        whitelist[_beneficiary] = false;
    }

    /**
     * @dev Return total individual wei amount.
     * @param _beneficiary Addresses to get total wei amount .
     * @return Total wei amount for the address.
     */
    function getTotalIndividualWeiAmount(address _beneficiary) external view onlyOwnerOrAdmin returns (uint256) {
        return totalIndividualWeiAmount[_beneficiary];
    }

    /**
     * @dev Set total individual wei amount.
     * @param _beneficiary Addresses to set total wei amount.
     * @param _totalWeiAmount Total wei amount for the address.
     */
    function setTotalIndividualWeiAmount(address _beneficiary,uint256 _totalWeiAmount) external onlyOwner {
        totalIndividualWeiAmount[_beneficiary] = _totalWeiAmount;
    }

    /**
     * @dev Add total individual wei amount.
     * @param _beneficiary Addresses to add total wei amount.
     * @param _weiAmount Total wei amount to be added for the address.
     */
    function addTotalIndividualWeiAmount(address _beneficiary,uint256 _weiAmount) external onlyOwner {
        totalIndividualWeiAmount[_beneficiary] = totalIndividualWeiAmount[_beneficiary].add(_weiAmount);
    }

}