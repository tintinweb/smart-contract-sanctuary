pragma solidity ^0.4.18;

// File: zeppelin-solidity/contracts/ownership/Ownable.sol

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

// File: contracts/Restricted.sol

/** @title Restricted
 *  Exposes onlyMonetha modifier
 */
contract Restricted is Ownable {

    //MonethaAddress set event
    event MonethaAddressSet(
        address _address,
        bool _isMonethaAddress
    );

    mapping (address => bool) public isMonethaAddress;

    /**
     *  Restrict methods in such way, that they can be invoked only by monethaAddress account.
     */
    modifier onlyMonetha() {
        require(isMonethaAddress[msg.sender]);
        _;
    }

    /**
     *  Allows owner to set new monetha address
     */
    function setMonethaAddress(address _address, bool _isMonethaAddress) onlyOwner public {
        isMonethaAddress[_address] = _isMonethaAddress;

        MonethaAddressSet(_address, _isMonethaAddress);
    }
}

// File: zeppelin-solidity/contracts/ownership/Contactable.sol

/**
 * @title Contactable token
 * @dev Basic version of a contactable contract, allowing the owner to provide a string with their
 * contact information.
 */
contract Contactable is Ownable{

    string public contactInformation;

    /**
     * @dev Allows the owner to set a string with their contact information.
     * @param info The contact information to attach to the contract.
     */
    function setContactInformation(string info) onlyOwner public {
         contactInformation = info;
     }
}

// File: contracts/MerchantDealsHistory.sol

/**
 *  @title MerchantDealsHistory
 *  Contract stores hash of Deals conditions together with parties reputation for each deal
 *  This history enables to see evolution of trust rating for both parties
 */
contract MerchantDealsHistory is Contactable, Restricted {

    string constant VERSION = "0.3";

    ///  Merchant identifier hash
    bytes32 public merchantIdHash;
    
    //Deal event
    event DealCompleted(
        uint orderId,
        address clientAddress,
        uint32 clientReputation,
        uint32 merchantReputation,
        bool successful,
        uint dealHash
    );

    //Deal cancellation event
    event DealCancelationReason(
        uint orderId,
        address clientAddress,
        uint32 clientReputation,
        uint32 merchantReputation,
        uint dealHash,
        string cancelReason
    );

    //Deal refund event
    event DealRefundReason(
        uint orderId,
        address clientAddress,
        uint32 clientReputation,
        uint32 merchantReputation,
        uint dealHash,
        string refundReason
    );

    /**
     *  @param _merchantId Merchant of the acceptor
     */
    function MerchantDealsHistory(string _merchantId) public {
        require(bytes(_merchantId).length > 0);
        merchantIdHash = keccak256(_merchantId);
    }

    /**
     *  recordDeal creates an event of completed deal
     *  @param _orderId Identifier of deal&#39;s order
     *  @param _clientAddress Address of client&#39;s account
     *  @param _clientReputation Updated reputation of the client
     *  @param _merchantReputation Updated reputation of the merchant
     *  @param _isSuccess Identifies whether deal was successful or not
     *  @param _dealHash Hashcode of the deal, describing the order (used for deal verification)
     */
    function recordDeal(
        uint _orderId,
        address _clientAddress,
        uint32 _clientReputation,
        uint32 _merchantReputation,
        bool _isSuccess,
        uint _dealHash)
        external onlyMonetha
    {
        DealCompleted(
            _orderId,
            _clientAddress,
            _clientReputation,
            _merchantReputation,
            _isSuccess,
            _dealHash
        );
    }

    /**
     *  recordDealCancelReason creates an event of not paid deal that was cancelled 
     *  @param _orderId Identifier of deal&#39;s order
     *  @param _clientAddress Address of client&#39;s account
     *  @param _clientReputation Updated reputation of the client
     *  @param _merchantReputation Updated reputation of the merchant
     *  @param _dealHash Hashcode of the deal, describing the order (used for deal verification)
     *  @param _cancelReason deal cancelation reason (text)
     */
    function recordDealCancelReason(
        uint _orderId,
        address _clientAddress,
        uint32 _clientReputation,
        uint32 _merchantReputation,
        uint _dealHash,
        string _cancelReason)
        external onlyMonetha
    {
        DealCancelationReason(
            _orderId,
            _clientAddress,
            _clientReputation,
            _merchantReputation,
            _dealHash,
            _cancelReason
        );
    }

/**
     *  recordDealRefundReason creates an event of not paid deal that was cancelled 
     *  @param _orderId Identifier of deal&#39;s order
     *  @param _clientAddress Address of client&#39;s account
     *  @param _clientReputation Updated reputation of the client
     *  @param _merchantReputation Updated reputation of the merchant
     *  @param _dealHash Hashcode of the deal, describing the order (used for deal verification)
     *  @param _refundReason deal refund reason (text)
     */
    function recordDealRefundReason(
        uint _orderId,
        address _clientAddress,
        uint32 _clientReputation,
        uint32 _merchantReputation,
        uint _dealHash,
        string _refundReason)
        external onlyMonetha
    {
        DealRefundReason(
            _orderId,
            _clientAddress,
            _clientReputation,
            _merchantReputation,
            _dealHash,
            _refundReason
        );
    }
}