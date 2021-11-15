// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./libraries/Utils.sol";
import "./libraries/Signature.sol";
import "./Domain.sol";
import "./TLD.sol";
import "./Settings.sol";

contract Ordering is Ownable {
  using SafeMath for uint256;
  bool public initialized;
  Settings settings;
  
  struct AcquisitionOrder {
      address payable custodianAddress;
      address requester;
      uint256 acquisitionType;
      uint256 acquisitionFee;
      uint256 paidAcquisitionFee;
      uint256 transferInitiated;
      uint256 acquisitionSuccessful;
      uint256 acquisitionFail;
      uint256 acquisitionYears;
      uint256 validUntil;
      uint256 custodianNonce;
      uint256 reservedId;
  }

  mapping(bytes32=>AcquisitionOrder) acquisitionOrders;

  event AcquisitionOrderCreated(address custodianAddress,
                                  address requesterAddress,
                                  bytes32 domainHash,
                                  uint256 acquisitionType,
                                  uint256 custodianNonce,
                                  bytes acquisitionCustodianEncryptedData);
    event TransferInitiated( bytes32 domainHash );
    event DomainAcquisitionPaid(bytes32 domainHash,
                                uint256 acquisitionFeePaid);
    
    event AcquisitionSuccessful(bytes32 domainHash,
                                string domainName,
                                uint256 acquisitionType);
    
    event AcquisitionFailed(bytes32 domainHash);
    
    event AcquisitionPaid(bytes32 domainHash,
                          string domainName,
                          uint256 amount);
    event RefundPaid(bytes32 domainHash,
                     address requester,
                     uint256 amount);
    event OrderCancel(bytes32 domainHash);
    
    event TokenExpirationExtension(bytes32 domainHash,
                                   uint256 tokenId,
                                   uint256 extensionTime);
    
  
  enum OrderStatus {
      UNDEFINED, // 0
      OPEN, // 1
      ACQUISITION_CONFIRMED, // 2
      ACQUISITION_FAILED, // 3
      EXPIRED, // 4
      TRANSFER_INITIATED // 5
  }
  
  enum OrderType {
      UNKNOWN, // should not be used
      REGISTRATION, // 1
      TRANSFER, // 2
      EXTENSION // 3
  }
  constructor(){
    
  }

  
  function initialize(Settings _settings) public onlyOwner {
    require(!initialized, "Contract instance has already been initialized");
    initialized = true;
    settings = _settings;
  }

  function user() public view returns(User){
      return User(settings.getNamedAddress("USER"));
  }
      
  function getAcquisitionOrder(bytes32 domainHash) public view returns(AcquisitionOrder memory){
      return acquisitionOrders[domainHash];
  }
  
  function getAcquisitionOrderByDomainName(string memory domainName) public view returns(AcquisitionOrder memory){
      bytes32 domainHash = Utils.hashString(domainName);
      return acquisitionOrders[domainHash];
  }
  
  
  function setSettingsAddress(Settings _settings) public onlyOwner {
      settings = _settings;
  }

  function tld() public view returns(TLD){
      return TLD(payable(settings.getNamedAddress("TLD")));
  }
  function tokenCreationFee(bytes32 domainHash)
    public
    view
    returns(uint256){
    return tld().rprice(acquisitionOrders[domainHash].reservedId);
      
  }
    
  
  function minimumOrderValidityTime(uint256 orderType)
      public
      view
      returns (uint256) {
      if(orderType == uint256(OrderType.REGISTRATION)){
          return settings.getNamedUint("ORDER_MINIMUM_VALIDITY_TIME_REGISTRATION");
      }
      if(orderType == uint256(OrderType.TRANSFER)){
          return settings.getNamedUint("ORDER_MINIMUM_VALIDITY_TIME_TRANSFER");
      }
      if(orderType == uint256(OrderType.EXTENSION)){
          return settings.getNamedUint("ORDER_MINIMUM_VALIDITY_TIME_EXTENSION");
      }
      return 0;
  }

  
    function orderStatus(bytes32 domainHash)
        public
        view
        returns (uint256) {
         if(isOrderConfirmed(domainHash)){
            return uint256(OrderStatus.ACQUISITION_CONFIRMED);
        }
        if(isOrderFailed(domainHash)){
            return uint256(OrderStatus.ACQUISITION_FAILED);
        }
        
        if(isTransferInitiated(domainHash)){
          return uint256(OrderStatus.TRANSFER_INITIATED);
        }
        if(isOrderExpired(domainHash)){
            return uint256(OrderStatus.EXPIRED);
        }
        
        if(isOrderOpen(domainHash)){
            return uint256(OrderStatus.OPEN);
        }
        
        return uint256(OrderStatus.UNDEFINED);
    }
    
    function orderExists(bytes32 domainHash)
      public
      view
      returns (bool){
      
      return acquisitionOrders[domainHash].validUntil > 0;
      
    }

    function isOrderExpired(bytes32 domainHash)
        public
        view
        returns (bool){
        return acquisitionOrders[domainHash].validUntil > 0
            && acquisitionOrders[domainHash].validUntil < block.timestamp
            && acquisitionOrders[domainHash].transferInitiated == 0
            && acquisitionOrders[domainHash].acquisitionSuccessful == 0
            && acquisitionOrders[domainHash].acquisitionFail == 0;
    }
    
    function isOrderOpen(bytes32 domainHash)
      public
      view
      returns (bool){
      return acquisitionOrders[domainHash].validUntil > block.timestamp
        || isOrderConfirmed(domainHash)
        || isTransferInitiated(domainHash);
    }
    
    function isOrderConfirmed(bytes32 domainHash)
      public
      view
      returns (bool){
      
      return acquisitionOrders[domainHash].acquisitionSuccessful > 0;
      
    }
    
    function isOrderFailed(bytes32 domainHash)
      public
      view
      returns (bool){

      return acquisitionOrders[domainHash].acquisitionFail > 0;
      
    }

    function isTransferInitiated(bytes32 domainHash)
      public
      view
      returns(bool){
      return acquisitionOrders[domainHash].transferInitiated > 0;
    }

    function canCancelOrder(bytes32 domainHash)
      public
      view
      returns (bool){
      
      return orderExists(domainHash)
        && acquisitionOrders[domainHash].validUntil > block.timestamp
        && !isOrderConfirmed(domainHash)
        && !isOrderFailed(domainHash)
        && !isTransferInitiated(domainHash);
      
    }
    
    function orderDomainAcquisition(bytes32 domainHash,
                                    address requester,
                                    uint256 acquisitionType,
                                    uint256 acquisitionYears,
                                    uint256 acquisitionFee,
                                    uint256 acquisitionOrderTimestamp,
                                    uint256 custodianNonce,
                                    bytes memory signature,
                                    bytes memory acquisitionCustodianEncryptedData)
      public
      payable {
        require(user().isActive(requester), "Requester must be an active user");
        require(acquisitionOrderTimestamp > block.timestamp.sub(settings.getNamedUint("ACQUISITION_ORDER_TIME_WINDOW")),
              "Try again with a fresh acquisition order");

      bytes32 message = keccak256(abi.encode(requester,
                                             acquisitionType,
                                             acquisitionYears,
                                             acquisitionFee,
                                             acquisitionOrderTimestamp,
                                             custodianNonce,
                                             domainHash));
      
      address custodianAddress = Signature.recoverSigner(message,signature);
      
      require(settings.hasNamedRole("CUSTODIAN", custodianAddress),
              "Signer is not a registered custodian");
      
      if(isOrderOpen(domainHash)){
        revert("An order for this domain is already active");
      }

      if(acquisitionType == uint256(OrderType.EXTENSION)){
        require(domainToken().tokenForHashExists(domainHash), "Token for domain does not exist");
      }
      
      require(msg.value >= acquisitionFee,
              "Acquisition fee must be paid upfront");
      uint256 reservedId = 0;
      acquisitionOrders[domainHash] = AcquisitionOrder(
                                                       payable(custodianAddress),
                                                       requester,
                                                       acquisitionType,
                                                       acquisitionFee,
                                                       0, // paidAcquisitionFee
                                                       0, // transferInitiated
                                                       0, // acquisitionSuccessful flag,
                                                       0, // acquisitionFail flag,
                                                       acquisitionYears,
                                                       block.timestamp.add(minimumOrderValidityTime(acquisitionType)), //validUntil,
                                                       custodianNonce,
                                                       reservedId
                                                       );
        
      emit  AcquisitionOrderCreated(custodianAddress,
                                    requester,
                                    domainHash,
                                    acquisitionType,
                                    custodianNonce,
                                    acquisitionCustodianEncryptedData);
      
    }
    modifier onlyCustodian() {
      require(settings.hasNamedRole("CUSTODIAN", _msgSender())
              || _msgSender() == owner(),
              "Must be a custodian");
      _;
    }

    function transferInitiated(bytes32 domainHash)
      public onlyCustodian {
      require(acquisitionOrders[domainHash].validUntil > 0,
              "Order does not exist");
      require(acquisitionOrders[domainHash].acquisitionType == uint256(OrderType.TRANSFER),
              "Order is not Transfer");
      require(acquisitionOrders[domainHash].transferInitiated == 0,
              "Already marked");
      acquisitionOrders[domainHash].transferInitiated = block.timestamp;
      if(acquisitionOrders[domainHash].paidAcquisitionFee == 0
         && acquisitionOrders[domainHash].acquisitionFee > 0){

        uint256 communityFee = Utils.calculatePercentageCents(acquisitionOrders[domainHash].acquisitionFee,
                                                           settings.getNamedUint("COMMUNITY_FEE"));
        address payable custodianAddress = acquisitionOrders[domainHash].custodianAddress;
        uint256 custodianFee = acquisitionOrders[domainHash].acquisitionFee.sub(communityFee);
        acquisitionOrders[domainHash].paidAcquisitionFee = acquisitionOrders[domainHash].acquisitionFee;
        custodianAddress.transfer(custodianFee);
        payable(address(tld())).transfer(communityFee);
          
      }
      emit TransferInitiated(domainHash);
    }
    
    function domainToken() public view returns(Domain){
        return Domain(settings.getNamedAddress("DOMAIN"));
    }
    function acquisitionSuccessful(string memory domainName)
      public onlyCustodian {
        bytes32 domainHash = domainToken().registryDiscover(domainName);
        require(acquisitionOrders[domainHash].validUntil > 0,
                "Order does not exist");
        require(acquisitionOrders[domainHash].acquisitionSuccessful == 0,
                "Already marked");
        if(acquisitionOrders[domainHash].acquisitionType == uint256(OrderType.TRANSFER)
           && acquisitionOrders[domainHash].transferInitiated == 0){
          revert("Transfer was not initiated");
        }
        acquisitionOrders[domainHash].acquisitionSuccessful = block.timestamp;
        acquisitionOrders[domainHash].acquisitionFail = 0;
       
        if(acquisitionOrders[domainHash].paidAcquisitionFee == 0
           && acquisitionOrders[domainHash].acquisitionFee > 0){
          uint256 communityFee = Utils.calculatePercentageCents(acquisitionOrders[domainHash].acquisitionFee,
                                                             settings.getNamedUint("COMMUNITY_FEE"));
          address payable custodianAddress = acquisitionOrders[domainHash].custodianAddress;
          uint256 custodianFee = acquisitionOrders[domainHash].acquisitionFee.sub(communityFee);
          acquisitionOrders[domainHash].paidAcquisitionFee = acquisitionOrders[domainHash].acquisitionFee;
          custodianAddress.transfer(custodianFee);
          payable(address(tld())).transfer(communityFee);
        }
        uint256 acquisitionType = acquisitionOrders[domainHash].acquisitionType;
        if(acquisitionOrders[domainHash].acquisitionType == uint256(OrderType.EXTENSION)){
          
            emit TokenExpirationExtension(domainHash,
                                          domainToken().tokenIdForHash(domainHash),
                                          acquisitionOrders[domainHash].acquisitionYears.mul(365 days));
            delete acquisitionOrders[domainHash];
        }
        
        emit AcquisitionSuccessful(domainHash, domainName, acquisitionType);

    }
    function getAcquisitionYears(bytes32 domainHash) public view returns(uint256){
      return acquisitionOrders[domainHash].acquisitionYears;
    }
    
    function acquisitionFail(bytes32 domainHash)
      public onlyCustodian {
      require(acquisitionOrders[domainHash].validUntil > 0,
              "Order does not exist");
      require(acquisitionOrders[domainHash].acquisitionFail == 0,
              "Already marked");
      acquisitionOrders[domainHash].transferInitiated = 0;
      acquisitionOrders[domainHash].acquisitionSuccessful = 0;
      acquisitionOrders[domainHash].acquisitionFail = block.timestamp;
      if( acquisitionOrders[domainHash].paidAcquisitionFee == 0
          && acquisitionOrders[domainHash].acquisitionFee > 0){
        
        address payable requester = payable(acquisitionOrders[domainHash].requester);
        uint256 refundAmount = acquisitionOrders[domainHash].acquisitionFee;
        requester.transfer(refundAmount);
        
      }
      
      delete acquisitionOrders[domainHash];
      
      emit AcquisitionFailed(domainHash);

    }

    function cancelOrder(bytes32 domainHash)
      public {
      require(canCancelOrder(domainHash),
              "Can not cancel order");
      if(acquisitionOrders[domainHash].paidAcquisitionFee == 0
         && acquisitionOrders[domainHash].acquisitionFee > 0){
        address payable requester = payable(acquisitionOrders[domainHash].requester);
        acquisitionOrders[domainHash].paidAcquisitionFee = acquisitionOrders[domainHash].acquisitionFee;
        if(requester.send(acquisitionOrders[domainHash].acquisitionFee)){

            emit RefundPaid(domainHash, requester, acquisitionOrders[domainHash].acquisitionFee);

        }
      }
      delete acquisitionOrders[domainHash];
      emit OrderCancel(domainHash);
    }

    function canClaim(bytes32 domainHash)
      public view returns(bool){
      return (acquisitionOrders[domainHash].validUntil > 0 &&
              acquisitionOrders[domainHash].acquisitionFail == 0 &&
              acquisitionOrders[domainHash].acquisitionSuccessful > 0 &&
              !domainToken().tokenForHashExists(domainHash));
      
    }
        
    function orderRequester(bytes32 domainHash)
      public view returns(address){
      return acquisitionOrders[domainHash].requester;
    }

    function computedExpirationDate(bytes32 domainHash)
      public view returns(uint256){
      return acquisitionOrders[domainHash].acquisitionSuccessful
        .add(acquisitionOrders[domainHash].acquisitionYears
             .mul(365 days));
    }
    function tldOrderReservedId(bytes32 domainHash)
      public view returns(uint256){
      return acquisitionOrders[domainHash].reservedId;
    }

    function finishOrder(bytes32 domainHash)
      public onlyOwner {
      delete acquisitionOrders[domainHash];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

library Utils {
  using SafeMath for uint256;
    function hashString(string memory domainName)
      internal
      pure
      returns (bytes32) {
      return keccak256(abi.encode(domainName));
    }
    function calculatePercentage(uint256 amount,
                                 uint256 percentagePoints,
                                 uint256 maxPercentagePoints)
      internal
      pure
      returns (uint256){  
      return amount.mul(percentagePoints).div(maxPercentagePoints);
    }

    function percentageCentsMax()
        internal
        pure
        returns (uint256){
        return 10000;
    }

    function calculatePercentageCents(uint256 amount,
                                      uint256 percentagePoints)
        internal
        pure
        returns (uint256){
        return calculatePercentage(amount, percentagePoints, percentageCentsMax());
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Signature {
  function recoverSigner(bytes32 message, bytes memory sig)
    internal
    pure
    returns (address){
    
    uint8 v;
    bytes32 r;
    bytes32 s;
    (v, r, s) = splitSignature(sig);
    return ecrecover(message, v, r, s);
  }
  
  function splitSignature(bytes memory sig)
    internal
    pure
    returns (uint8, bytes32, bytes32){
    
    require(sig.length == 65, "Invalid Signature");
    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
    r := mload(add(sig, 32))
        s := mload(add(sig, 64))
        v := byte(0, mload(add(sig, 96)))
        }
    return (v, r, s);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./libraries/Utils.sol";
import "./libraries/Signature.sol";
import "./User.sol";
import "./Registry.sol";
import "./Settings.sol";

contract Domain is  ERC721Enumerable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;
  
  Settings settings;
  Counters.Counter private _tokenIds;
  struct DomainInfo {
      bytes32 domainHash;
      uint256 expireTimestamp;
      uint256 transferCooloffTime;
      bool active;
      uint256 canBurnAfter;
      bool burnRequest;
      bool burnRequestCancel;
      bool burnInit;
  }
  
  address private _owner;

  mapping(uint256=>DomainInfo) public domains;
  mapping(bytes32=>uint256) public domainHashToToken;
  mapping(address=>mapping(address=>mapping(uint256=>uint256))) public offchainTransferConfirmations;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  event DomainDeactivated(uint256 tokenId);
  event DomainActivated(uint256 tokenId);
  event InitBurnRequest(uint256 tokenId);
  event BurnInitiated(uint256 tokenId);
  event InitCancelBurn(uint256 tokenId);
  event BurnCancel(uint256 tokenId);
  event Burned(uint256 tokenId, bytes32 domainHash);
   
  string public _custodianBaseUri;
  
  constructor(string memory baseUri, Settings _settings) ERC721("Domain Name Token", "DOMAIN") {
    _owner = msg.sender;
    _custodianBaseUri = baseUri;
    settings = _settings;
  }
  
  function _baseURI()
    internal
    view
    virtual
    override
    returns (string memory) {
    return _custodianBaseUri;
  }
  
  
  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory) {
    require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
    
    string memory baseURI = _baseURI();
    string memory domainName = getDomainName(tokenId);
    return string(abi.encodePacked(baseURI, "/", "api" "/","info","/","domain","/",domainName,".json"));
    
  }
  
  function owner() public view virtual returns (address) {
    return _owner;
  }
  modifier onlyOwner() {
    require(owner() == msg.sender, "Ownable: caller is not the owner");
    _;
  }

  function setSettingsAddress(Settings _settings) public onlyOwner {
      settings = _settings;
  }

  function burnRestrictionWindow() public view returns(uint256){
      return settings.getNamedUint("BURN_RESTRICTION_WINDOW");
  }
  
  function changeOwner(address nextOwner) public onlyOwner {
    address previousOwner = _owner;
    _owner = nextOwner;
    emit OwnershipTransferred(previousOwner, nextOwner);
  }

  function user() public view returns(User){
      return User(settings.getNamedAddress("USER"));
  }
  function registry() public view returns(Registry){
      return Registry(settings.getNamedAddress("REGISTRY"));
  }
  
  function isDomainActive(uint256 tokenId)
    public
    view
    returns (bool){
    
    return _exists(tokenId) && domains[tokenId].active && domains[tokenId].expireTimestamp > block.timestamp;
  }
  
  function isDomainNameActive(string memory domainName)
    public
    view
    returns (bool){
    return isDomainActive(tokenOfDomain(domainName));
  }
  function getDomainName(uint256 tokenId)
    public
    view
    returns (string memory){
      return registry().reveal(domains[tokenId].domainHash);
  }

  function getHashOfTokenId(uint256 tokenId) public view returns(bytes32){
      return domains[tokenId].domainHash;
  }
  
  function registryDiscover(string memory name) public returns(bytes32){
      return registry().discover(name);
  }
  function registryReveal(bytes32 key) public view returns(string memory){
      return registry().reveal(key);
  }
  
  function tokenOfDomain(string memory domainName)
    public
    view
    returns (uint256){
    
    bytes32 domainHash = Utils.hashString(domainName);
    return domainHashToToken[domainHash];
    
  }
  
  function getTokenId(string memory domainName)
    public
    view
    returns (uint256){
    
    return tokenOfDomain(domainName);
  }
  
  function getExpirationDate(uint256 tokenId)
    public
    view
    returns(uint256){
    return domains[tokenId].expireTimestamp;
  }
  
  function extendExpirationDate(uint256 tokenId, uint256 interval) public onlyOwner {
    require(_exists(tokenId), "Token id does not exist");
    domains[tokenId].expireTimestamp = domains[tokenId].expireTimestamp.add(interval);
  }
  
  function extendExpirationDateDomainHash(bytes32 domainHash, uint256 interval) public onlyOwner {
    extendExpirationDate(domainHashToToken[domainHash], interval);
  }
  
  function getTokenInfo(uint256 tokenId)
    public
    view
    returns(uint256, // tokenId
            address, // ownerOf tokenId
            uint256, // expireTimestamp
            bytes32, // domainHash
            string memory // domainName
            ){
    return (tokenId,
            ownerOf(tokenId),
            domains[tokenId].expireTimestamp,
            domains[tokenId].domainHash,
            registry().reveal(domains[tokenId].domainHash));
  }
  function getTokenInfoByDomainHash(bytes32 domainHash)
    public
    view
    returns (
             uint256, // tokenId
             address, // ownerOf tokenId
             uint256, // expireTimestamp
             bytes32, // domainHash
             string memory // domainName
             ){
    if(_exists(domainHashToToken[domainHash])){
      return getTokenInfo(domainHashToToken[domainHash]);
    }else{
      return (
              0,
              address(0x0),
              0,
              bytes32(0x00),
              ""
              );
    }
  }

  
  function claim(address domainOwner, bytes32 domainHash, uint256 expireTimestamp) public onlyOwner returns (uint256){
    require(domainHashToToken[domainHash] == 0, "Token already exists");
    require(user().isActive(domainOwner), "Domain Owner is not an active user");
    _tokenIds.increment();
    uint256 tokenId = _tokenIds.current();
    
    domains[tokenId] = DomainInfo(domainHash,
                                  expireTimestamp,
                                  0,
                                  true,
                                  block.timestamp.add(burnRestrictionWindow()),
                                  false,
                                  false,
                                  false);
    domainHashToToken[domainHash] = tokenId;
    _mint(domainOwner, tokenId); 
    return tokenId;
  }

  function transferCooloffTime() public view returns (uint256){
    return settings.getNamedUint("TRANSFER_COOLOFF_WINDOW");
  }
  
  function _deactivate(uint256 tokenId) internal {
      domains[tokenId].active = false;
      emit DomainDeactivated(tokenId);
  }

  function _activate(uint256 tokenId) internal {
      domains[tokenId].active = true;
      emit DomainActivated(tokenId);
  }
  
  function deactivate(uint256 tokenId) public onlyOwner {
    require(_exists(tokenId), "Token does not exist");
    require(domains[tokenId].active, "Token is already deactivated");
    _deactivate(tokenId);
  }
  function activate(uint256 tokenId) public onlyOwner {
    require(_exists(tokenId), "Token does not exist");
    require(!domains[tokenId].active, "Token is already activated");
    _activate(tokenId);
  }
  function isInBurnCycle(uint256 tokenId) public view returns(bool){
      return _exists(tokenId)
          &&
          (
           domains[tokenId].burnRequest
           || domains[tokenId].burnRequestCancel
           || domains[tokenId].burnInit
           );
  }
  
  function canBeTransferred(uint256 tokenId) public view returns(bool){
      return user().isActive(ownerOf(tokenId))
        && domains[tokenId].active
        && domains[tokenId].transferCooloffTime <= block.timestamp
        && domains[tokenId].expireTimestamp > block.timestamp
        && !isInBurnCycle(tokenId);
  }

  function canBeBurned(uint256 tokenId) public view returns(bool){
      return domains[tokenId].canBurnAfter < block.timestamp;
  }
  
  function canTransferTo(address _receiver) public view returns(bool){
      return user().isActive(_receiver);
  }
  function extendCooloffTimeForToken(uint256 tokenId, uint256 window) public onlyOwner {
    if(_exists(tokenId)){
      domains[tokenId].transferCooloffTime = block.timestamp.add(window);
    }
  }
  function extendCooloffTimeForHash(bytes32 hash, uint256 window) public onlyOwner {
    uint256 tokenId = tokenIdForHash(hash);
    if(_exists(tokenId)){
      domains[tokenId].transferCooloffTime = block.timestamp.add(window);
    }
  }
  function offchainConfirmTransfer(address from, address to, uint256 tokenId, uint256 validUntil, uint256 custodianNonce, bytes memory signature) public {
    bytes32 message = keccak256(abi.encode(from,
                                           to,
                                           tokenId,
                                           validUntil,
                                           custodianNonce));
    address signer = Signature.recoverSigner(message, signature);
    require(settings.hasNamedRole("CUSTODIAN", signer), "Signer is not a registered custodian");
    require(_exists(tokenId), "Token does not exist");
    require(_isApprovedOrOwner(from, tokenId), "Is not token owner");
    require(isDomainActive(tokenId), "Token is not active");
    require(user().isActive(to), "Destination address is not an active user");
    offchainTransferConfirmations[from][to][tokenId] = validUntil;
  }
  function transferFrom(address from, address to, uint256 tokenId) public virtual override(ERC721){
    require(canBeTransferred(tokenId), "Token can not be transfered now");
    require(user().isActive(to), "Destination address is not an active user");
    if(settings.getNamedUint("OFFCHAIN_TRANSFER_CONFIRMATION_ENABLED") > 0){
      require(offchainTransferConfirmations[from][to][tokenId] > block.timestamp, "Transfer requires offchain confirmation");
    }
    domains[tokenId].transferCooloffTime = block.timestamp.add(transferCooloffTime());
    super.transferFrom(from, to, tokenId);
  }
  
  function adminTransferFrom(address from, address to, uint256 tokenId) public onlyOwner {
    require(_exists(tokenId), "Token does not exist");
    require(_isApprovedOrOwner(from, tokenId), "Can not transfer");
    require(user().isActive(to), "Destination address is not an active user");
    _transfer(from, to, tokenId);
  }
  
  function transferOwnership(address newOwner) public virtual onlyOwner {
    require(newOwner != address(0), "Ownable: new owner is the zero address");
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
  function tokenExists(uint256 tokenId) public view returns(bool){
    return _exists(tokenId);
  }
  function tokenForHashExists(bytes32 hash) public view returns(bool){
    return tokenExists(tokenIdForHash(hash));
  }
  function tokenIdForHash(bytes32 hash) public view returns(uint256){
      return domainHashToToken[hash];
  }
  
    
  function initBurn(uint256 tokenId) public {
      require(canBeBurned(tokenId), "Domain is in burn restriction period");
      require(!isInBurnCycle(tokenId), "Domain already in burn cycle");
      require(_exists(tokenId), "Domain does not exist");
      require(ownerOf(tokenId) == msg.sender, "Must be owner of domain");

      domains[tokenId].burnRequest = true;
      _deactivate(tokenId);
      
      emit InitBurnRequest(tokenId);
  }
  
  function cancelBurn(uint256 tokenId) public {
      require(_exists(tokenId), "Domain does not exist");
      require(ownerOf(tokenId) == msg.sender, "Must be owner of domain");
      require(domains[tokenId].burnRequest, "No burn initiated");

      domains[tokenId].burnRequestCancel = true;
      emit InitCancelBurn(tokenId);
  }

  function burnInit(uint256 tokenId) public onlyOwner {
      require(_exists(tokenId), "Token does not exist");
      
      domains[tokenId].burnRequest = true;
      domains[tokenId].burnRequestCancel = false;
      domains[tokenId].burnInit = true;
      _deactivate(tokenId);
      emit BurnInitiated(tokenId);
  }

  function burnCancel(uint256 tokenId) public onlyOwner {
      require(_exists(tokenId), "Token does not exist");
      domains[tokenId].burnRequest = false;
      domains[tokenId].burnRequestCancel = false;
      domains[tokenId].burnInit = false;
      _activate(tokenId);
      emit BurnCancel(tokenId);
  }
  
  function burn(uint256 tokenId) public onlyOwner {
      require(_exists(tokenId), "Token does not exist");
      bytes32 domainHash = domains[tokenId].domainHash;
      delete domainHashToToken[domainHash];
      delete domains[tokenId];
      _burn(tokenId);
      emit Burned(tokenId, domainHash);    
  }
  
}

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "./ERC20Changeable.sol";

contract TLD is ERC20Changeable {
  using SafeMath for uint256;
  using Counters for Counters.Counter;
  
  address private _owner;
  uint256 private AVERAGE_LENGTH;
  uint256 private MINT_UNIT = 1;
  uint256 private gasUnitsHistory;
  uint256 private gasPriceHistory;
  uint256 private MINTED_ETH = 0;
  uint256 private MINTED_TLD = 0;
  uint256 private MINTED_CONSTANT = 0;
  uint256 private REIMBURSEMENT_TX_GAS_HISTORY;
  uint256 private DEFAULT_REIMBURSEMENT_TX_GAS = 90000;
  uint256 private BASE_PRICE_MULTIPLIER = 3;
  uint256 private _basePrice;
  
  Counters.Counter private _reservedIds;
  mapping(uint256=>uint256) reservedPrice;
  
  event Skimmed(address destinationAddress, uint256 amount);
  constructor() ERC20Changeable("Domain Name Community Token", ".TLD") {
    _owner = msg.sender;
  }

  function changeSymbol(string memory symbol_) public onlyOwner{
    _symbol = symbol_;
  }
  function changeName(string memory name_) public onlyOwner{
    _name = name_;
  }
  
  function init(uint256 initialGasEstimation, uint256 averageLength, uint256 basePriceMultiplier) public payable onlyOwner returns(uint256){
    if(MINTED_CONSTANT != 0){
      revert("Already initialized");
    }
    AVERAGE_LENGTH = averageLength;
    BASE_PRICE_MULTIPLIER = basePriceMultiplier;
    trackGasReimburses(initialGasEstimation);
    trackGasPrice(tx.gasprice.add(1));
    uint256 toMint = msg.value.mul(unit()).div(basePrice());
    MINTED_ETH = msg.value;
    MINTED_TLD = toMint;
    MINTED_CONSTANT = MINTED_ETH.mul(MINTED_TLD);
    _mint(msg.sender, toMint);
    return toMint;
  }
  function setBasePriceMultiplier(uint256 basePriceMultiplier) public onlyOwner {
    BASE_PRICE_MULTIPLIER = basePriceMultiplier;
  }
  function setAverageLength(uint256 averageLength) public onlyOwner {
      require(averageLength > 1, "Average length must be greater than one.");
      AVERAGE_LENGTH = averageLength;
  }
  function mintedEth() public view returns(uint256){
    return MINTED_ETH;
  }
  function mintedTld() public view returns(uint256){
    return MINTED_TLD;
  }
  function unit() public view returns (uint256) {
    return MINT_UNIT.mul(10 ** decimals());
  }
  function owner() public view virtual returns (address) {
    return _owner;
  }
  function payableOwner() public view virtual returns(address payable){
    return payable(_owner);
  }
  modifier onlyOwner() {
    require(owner() == msg.sender, "Caller is not the owner");
    _;
  }
  function decimals() public view virtual override returns (uint8) {
    return 8;
  }
  function totalAvailableEther() public view returns (uint256) {
    return address(this).balance;
  }
  function basePrice() public view returns (uint256){
    return averageGasUnits().mul(averageGasPrice()).mul(BASE_PRICE_MULTIPLIER);
  }
  function mintPrice(uint256 numberOfTokensToMint) public view returns (uint256){
    if(numberOfTokensToMint >= MINTED_TLD){
        return basePrice()
            .add(uncovered()
                 .div(AVERAGE_LENGTH));
    }
    uint256 computedPrice = MINTED_CONSTANT
        .div( MINTED_TLD
              .sub(numberOfTokensToMint))
        .add(uncovered()
             .div(AVERAGE_LENGTH))
      .add(basePrice());
    if(computedPrice <= MINTED_ETH){
      return uncovered().add(basePrice());
    }
    return computedPrice
      .sub(MINTED_ETH);
  }
  
  function burnPrice(uint256 numberOfTokensToBurn) public view returns (uint256) {
    if(MINTED_CONSTANT == 0){
      return 0;
    }
    if(uncovered() > 0){
        return 0;
    }
    return MINTED_ETH.sub(MINTED_CONSTANT.div( MINTED_TLD.add(numberOfTokensToBurn)));
  }
  function isCovered() public view returns (bool){
    return  MINTED_ETH > 0 && MINTED_ETH <= address(this).balance;
  }
  function uncovered() public view returns (uint256){
    if(isCovered()){
      return 0;
    }
    
    return MINTED_ETH.sub(address(this).balance);
  }
  function overflow() public view returns (uint256){
    if(!isCovered()){
      return 0;
    }
    
    return address(this).balance.sub(MINTED_ETH);
  }
  function transferOwnership(address newOwner) public onlyOwner returns(address){
    require(newOwner != address(0), "New owner is the zero address");
    _owner = newOwner;
    return _owner;
  }
  function mintUpdateMintedStats(uint256 unitsAmount, uint256 ethAmount) internal {
    MINTED_TLD = MINTED_TLD.add(unitsAmount);
    MINTED_ETH = MINTED_ETH.add(ethAmount);
    MINTED_CONSTANT = MINTED_TLD.mul(MINTED_ETH);
  }
  function rprice(uint256 reservedId) public view returns(uint256){
      return reservedPrice[reservedId];
  }
  function reserveMint() public returns (uint256) {
    _reservedIds.increment();

    uint256 reservedId = _reservedIds.current();
    reservedPrice[reservedId] = mintPrice(unit());
    return reservedId;
  }
  function mint(uint256 reservedId) payable public onlyOwner returns (uint256){
    require(msg.value >= reservedPrice[reservedId], "Minimum payment is not met.");
    mintUpdateMintedStats(unit(), basePrice());
    _mint(msg.sender, unit());
    return unit();
  }
  function unitsToBurn(uint256 ethAmount) public view returns (uint256){
    if(MINTED_CONSTANT == 0){
      return totalSupply();
    }
    if(ethAmount > MINTED_ETH){
      return totalSupply();
    }
    return MINTED_CONSTANT.div( MINTED_ETH.sub(ethAmount) ).sub(MINTED_TLD);
  }
  function trackGasReimburses(uint256 gasUnits) internal {
      gasUnitsHistory = gasUnitsHistory.mul(AVERAGE_LENGTH-1).add(gasUnits).div(AVERAGE_LENGTH);
  }
  function trackGasPrice(uint256 gasPrice) internal {
      gasPriceHistory = gasPriceHistory.mul(AVERAGE_LENGTH-1).add(gasPrice).div(AVERAGE_LENGTH);
  }
  function averageGasPrice() public view returns(uint256){
      return gasPriceHistory;
  }
  function averageGasUnits() public view returns(uint256){
    return gasUnitsHistory;
  }
  function reimbursementValue() public view returns(uint256){
    return averageGasUnits().mul(averageGasPrice()).mul(2);
  }
  function burn(uint256 unitsAmount) public returns(uint256){
    require(balanceOf(msg.sender) >= unitsAmount, "Insuficient funds to burn");
    uint256 value = burnPrice(unitsAmount);
    if(value > 0 && value <= address(this).balance){
      _burn(msg.sender, unitsAmount);
      payable(msg.sender).transfer(value);
    }
    return 0;
  }
  function skim(address destination) public onlyOwner returns (uint256){
      uint256 amountToSkim = overflow();
      if(amountToSkim > 0){
          if(payable(destination).send(amountToSkim)){
              emit Skimmed(destination, amountToSkim);
          }
      }
      return amountToSkim;
  }
  function reimburse(uint256 gasUnits, address payable toAddress) public onlyOwner returns (bool){
    uint256 gasStart = gasleft();
    uint256 value = reimbursementValue();
    if(value > MINTED_ETH){
      return false;
    }
    uint256 reimbursementUnits = unitsToBurn(value);

    trackGasPrice(tx.gasprice.add(1));
    if(balanceOf(msg.sender) >= reimbursementUnits && address(this).balance > value){
      _burn(msg.sender, reimbursementUnits);
      payable(toAddress).transfer(value);
    }else{
      mintUpdateMintedStats(0, value);
    }
    trackGasReimburses(gasUnits.add(gasStart.sub(gasleft()))); 
    return false;
  }
  receive() external payable {
      
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract Settings is AccessControlEnumerable {
    mapping(bytes32=>uint256) uintSetting;
    mapping(bytes32=>address) addressSetting;

    modifier onlyAdmin() {
      require(hasRole(DEFAULT_ADMIN_ROLE, _msgSender()),
              "Must be admin");
      _;
    }
    
    constructor(){
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function isAdmin(address _address) public view returns(bool){
      return hasRole(DEFAULT_ADMIN_ROLE, _address);
    }

    function changeAdmin(address adminAddress)
        public onlyAdmin {     
        require(adminAddress != address(0), "New admin must be a valid address");
        _setupRole(DEFAULT_ADMIN_ROLE, adminAddress);
        revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    function registerNamedRole(string memory _name, address _address) public onlyAdmin {
        bytes32 role = toKey(_name);
        require(!hasRole(role, _address), "Address already has role");
        _setupRole(role, _address);
    }
    function unregisterNamedRole(string memory _name, address _address) public onlyAdmin {
      bytes32 role = toKey(_name);
      require(hasRole(role, _address), "Address already has role");
      revokeRole(role, _address);
    }
    
    function hasNamedRole(string memory _name, address _address) public view returns(bool){
      return hasRole(toKey(_name), _address);
    }
    
    function toKey(string memory _name) public pure returns(bytes32){
      return keccak256(abi.encode(_name));
    }
    function ownerSetNamedUint(string memory _name, uint256 _value) public onlyAdmin{
        ownerSetUint(toKey(_name), _value);
    }
    function ownerSetUint(bytes32 _key, uint256 _value) public onlyAdmin {
        uintSetting[_key] = _value;
    }
    function ownerSetAddress(bytes32 _key, address _value) public onlyAdmin {
        addressSetting[_key] = _value;
    }
    function ownerSetNamedAddress(string memory _name, address _value) public onlyAdmin{
        ownerSetAddress(toKey(_name), _value);
    }
    
    function getUint(bytes32 _key) public view returns(uint256){
        return uintSetting[_key];
    }
    
    function getAddress(bytes32 _key) public view returns(address){
        return addressSetting[_key];
    }

    function getNamedUint(string memory _name) public view returns(uint256){
        return getUint(toKey(_name));
    }
    function getNamedAddress(string memory _name) public view returns(address){
        return getAddress(toKey(_name));
    }
    function removeNamedUint(string memory _name) public onlyAdmin {
      delete uintSetting[toKey(_name)];
    }
    function removeNamedAddress(string memory _name) public onlyAdmin {
      delete addressSetting[toKey(_name)];
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "./extensions/IERC721Enumerable.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721.sol";
import "./IERC721Enumerable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Settings.sol";

contract User is Ownable{
  bool public initialized;
  Settings settings;
  struct Account {
        uint256 registered;
        uint256 active;
    }
    mapping (address=>Account) users;
    mapping (address=>address) subaccounts;
    mapping (address=>address[]) userSubaccounts;

    constructor() {
      
    }
    function initialize(Settings _settings) public onlyOwner {
      require(!initialized, "Contract instance has already been initialized");
      initialized = true;
      settings = _settings;
    }
    function setSettingsAddress(Settings _settings) public onlyOwner {
      settings = _settings;
    }
    function isRegistered(address userAddress) public view returns(bool){
        return users[userAddress].registered > 0;
    }
    
    function isSubaccount(address anAddress) public view returns(bool){
        return subaccounts[anAddress] != address(0x0);
    }
    
    function parentUser(address anAddress) public view returns(address){
        if(isSubaccount(anAddress) ){
            return subaccounts[anAddress];
        }
        if(isRegistered(anAddress)){
            return anAddress;
        }
        return address(0x0);
    }
    
    function isActive(address anAddress) public view returns(bool){
        address checkAddress = parentUser(anAddress);
        return (isRegistered(checkAddress) && users[checkAddress].active > 0);
    }
    function register(address registerAddress) public onlyOwner {
        require(!isRegistered(registerAddress),"Address already registered");
        require(!isSubaccount(registerAddress), "Address is a subaccount of another address");
        users[registerAddress] = Account(block.timestamp, 0);
    }
    
    function activateUser(address userAddress) public onlyOwner {
        require(isRegistered(userAddress), "Address is not a registered user");
        users[userAddress].active = block.timestamp;
    }
    function deactivateUser(address userAddress) public onlyOwner {
        require(isRegistered(userAddress), "Address is not a registered user");
        users[userAddress].active = 0;
    }
    
    function addSubaccount(address anAddress) public {
        require(isActive(_msgSender()),"Must be a registered active user");
        require(!isRegistered(anAddress), "Address is already registered");
        require(!isSubaccount(anAddress), "Address is already a subaccount");
        require(settings.getNamedUint("SUBACCOUNTS_ENABLED") > 0, "Subaccounts are not enabled");
        subaccounts[anAddress] = _msgSender();
        userSubaccounts[_msgSender()].push(anAddress);
        
    }
    function removeSubaccount(address anAddress) public {
        //require(isActive(_msgSender()),"Must be a registered active user");
        if(anAddress == _msgSender()){
            require(subaccounts[anAddress] != address(0x0), "Address is not a subaccount");
        }else{
            require(subaccounts[anAddress] == _msgSender(), "Subaccount doesnt belong to caller");
        }
        address parent = parentUser(anAddress);
        require(parent != address(0x0), "Address has no parent");
        delete subaccounts[anAddress];
        for(uint256 i = 0; i < userSubaccounts[parent].length; i++){
            if(userSubaccounts[parent][i] == anAddress){
                userSubaccounts[parent][i] = userSubaccounts[parent][userSubaccounts[parent].length-1];
                userSubaccounts[parent].pop();
            }
        }
    }
    
    function listSubaccounts(address anAddress) public view returns(address[] memory){
        return userSubaccounts[anAddress];
    }
    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./libraries/Utils.sol";

contract Registry {

    
    mapping(bytes32=>string) registry;
    bytes32[] private index;

    constructor(){
    
    }

    function count() public view returns(uint256){
        return index.length;
    }

    function atIndex(uint256 _i) public view returns(string memory){
        
        return registry[index[_i]];
    }

    function discover(string memory _name) public returns(bytes32){
        if(bytes(_name).length == 0){
          revert("Revert due to empty name");
        }
        bytes32 hash = Utils.hashString(_name);
        if(bytes(registry[hash]).length == 0){
            registry[hash] = _name;
        }
        return hash;
    }
    function reveal(bytes32 hash) public view returns(string memory){
        return registry[hash];
    }

    function isDiscovered(string memory _name) public view returns(bool) {
        bytes32 hash = Utils.hashString(_name);
        return bytes(registry[hash]).length > 0;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping (bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {grantRole} to track enumerable memberships
     */
    function grantRole(bytes32 role, address account) public virtual override {
        super.grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {revokeRole} to track enumerable memberships
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        super.revokeRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {renounceRole} to track enumerable memberships
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        super.renounceRole(role, account);
        _roleMembers[role].remove(account);
    }

    /**
     * @dev Overload {_setupRole} to track enumerable memberships
     */
    function _setupRole(bytes32 role, address account) internal virtual override {
        super._setupRole(role, account);
        _roleMembers[role].add(account);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    function hasRole(bytes32 role, address account) external view returns (bool);
    function getRoleAdmin(bytes32 role) external view returns (bytes32);
    function grantRole(bytes32 role, address account) external;
    function revokeRole(bytes32 role, address account) external;
    function renounceRole(bytes32 role, address account) external;
}

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping (address => bool) members;
        bytes32 adminRole;
    }

    mapping (bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to grant");

        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override {
        require(hasRole(getRoleAdmin(role), _msgSender()), "AccessControl: sender must be an admin to revoke");

        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        emit RoleAdminChanged(role, getRoleAdmin(role), adminRole);
        _roles[role].adminRole = adminRole;
    }

    function _grantRole(bytes32 role, address account) private {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    function _revokeRole(bytes32 role, address account) private {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20Changeable is Context, IERC20 {
    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string public _name;
    string public _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The defaut value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overloaded;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

