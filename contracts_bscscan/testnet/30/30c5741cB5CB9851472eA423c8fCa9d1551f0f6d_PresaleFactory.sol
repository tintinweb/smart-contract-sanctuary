// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import './interfaces/IPresaleFactory.sol';
import './Presale.sol';


contract PresaleFactory is IPresaleFactory {
    bytes32 public constant INIT_CODE_PRESALE_HASH = keccak256(abi.encodePacked(type(Presale).creationCode));

    address public feeToVault;
    address public factoryManager;

    mapping(address => mapping(address => address)) public override getPresale;
    address[] public override allPresale;

    constructor(address _factoryManager){
        factoryManager = _factoryManager;
    }

    function allPresaleLength() external override view returns (uint) {
        return allPresale.length;
    }

    function createPresale(address presaleCurrency, address presaleToken) external override returns (address presale) {
        require(presaleCurrency != presaleToken, 'PresaleFactory: PRESALE_IDENTICAL_ADDRESSES');
        require(presaleCurrency != address(0), 'PresaleFactory: BASE_TOKEN_ZERO_ADDRESS');
        require(presaleToken != address(0), 'PresaleFactory: PRESALE_TOKEN_ZERO_ADDRESS');
        require(getPresale[presaleCurrency][presaleToken] == address(0), 'PresaleFactory: PRESALE_EXISTS'); // single check is sufficient
        bytes memory bytecode = getBytecode(presaleCurrency, presaleToken);
        bytes32 _salt = keccak256(abi.encodePacked(presaleCurrency, presaleToken));
        assembly {
            presale := create2(0, add(bytecode, 0x20), mload(bytecode), _salt)

            if iszero(extcodesize(presale)) {
                revert(0, 0)
            }
        }
        IPresale(presale).initialize(presaleCurrency, presaleToken);
        getPresale[presaleCurrency][presaleToken] = presale;
        allPresale.push(presale);
        emit PresaleCreated(presaleCurrency, presaleToken, presale, allPresale.length);
    }

    function initializePresale(
        address presale,
        address payable presaleOwner, 
        uint256 tokenAmount, 
        uint256 currencyMinimum, 
        uint256 currencyMaximum,
        uint256 presalePrice, 
        uint256 presaleCap, 
        bool isTokenBurn, 
        bool isRefPresale, 
        uint16 referralPercentage
    ) external override {
        IPresale(presale).presaleSetup(
            presaleOwner, 
            tokenAmount, 
            currencyMinimum, 
            currencyMaximum,
            presalePrice, 
            presaleCap, 
            isTokenBurn, 
            isRefPresale, 
            referralPercentage
        );
    }

    function initializeToken(
        address presale,
        address presaleCurrency,
        address presaleToken,
        uint8 tokenDecimal,
        bool isPresaleETH
    ) external override {
        IPresale(presale).tokenSetup(presaleCurrency, presaleToken, tokenDecimal, isPresaleETH);
    }

    function initializeSubscription(
        address presale,
        uint256 maxSubscribers,
        uint64 startBlock,
        uint64 endBlock
    ) external override {
        IPresale(presale).subscriptionSetup(
            maxSubscribers,
            startBlock,
            endBlock
        );
    }

    function initializeLiquidity(
        address presale,
        uint16 liquidityListingPercent,
        uint256 listingRate,
        bool isLiquidityLock,
        uint64 liquidityLockTime
    ) external override {
        IPresale(presale).liquiditySetup(
            liquidityListingPercent,
            listingRate,
            isLiquidityLock,
            liquidityLockTime
        );
    }

    function getBytecode(address presaleCurrency, address presaleToken) internal pure returns (bytes memory) {
        bytes memory bytecode = type(Presale).creationCode;

        return abi.encodePacked(bytecode, abi.encode(presaleCurrency, presaleToken));
    }
        
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;
interface IPresaleFactory {
    event PresaleCreated(address indexed presaleCurrency, address indexed presaleToken, address presale, uint);

    function getPresale(address presaleCurrency, address presaleToken) external view returns (address presale);
    function allPresale(uint256) external view returns (address presale);
    function allPresaleLength() external view returns (uint);
    
    function createPresale(address presaleCurrency, address presaleToken) external returns (address presale);

    function initializePresale(
        address presale,
        address payable presaleOwner, 
        uint256 tokenAmount, 
        uint256 currencyMinimum, 
        uint256 currencyMaximum,
        uint256 presalePrice, 
        uint256 presaleCap, 
        bool isTokenBurn, 
        bool isRefPresale, 
        uint16 referralPercentage
    ) external;

    function initializeToken(
        address presale,
        address presaleCurrency,
        address presaleToken,
        uint8 tokenDecimal,
        bool isPresaleETH
    ) external;

    function initializeSubscription(
        address presale,
        uint256 maxSubscribers,
        uint64 startBlock,
        uint64 endBlock
    ) external;

    function initializeLiquidity(
        address presale,
        uint16 liquidityListingPercent,
        uint256 listingRate,
        bool isLiquidityLock,
        uint64 liquidityLockTime
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import './abstracts/ReentrancyGuard.sol';
import './interfaces/IERC20.sol';
import './interfaces/IPresale.sol';
import '../libraries/SafeMath.sol';
import '../libraries/TransferHelper.sol';

contract Presale is IPresale, ReentrancyGuard {
    using SafeMath for uint256;
    using EnumerableSet for EnumerableSet.AddressSet;

    address public immutable override presaleCreator;

    address public presaleCurrency;
    address public presaleToken;

    struct PresaleInfo {
        address payable presaleOwner;
        IERC20 presaleCurrency; // presale token used to purchase presale token. (BNB or BUSD). see presale token below.
        IERC20 presaleToken; // fresh token to be sold
        uint8 tokenDecimal; // token decimal
        uint256 presalePrice; // 1 presaleCurrency = ? presaleToken, fixed price
        uint256 tokenAmount; // the amount of presale tokens up for presale
        uint256 currencyMinimum; // the minumum currency contribution allowed per user
        uint256 currencyMaximum; // the maximum currency contribution allowed per user
        uint256 presaleCap; // cap in ETH
        bool isPresaleETH; // if this flag is true the sale is raising ETH, otherwise an ERC20 token such as BUSD
        bool isTokenBurn; // if this flag is true, unsold tokens will be burnt after sale
    }

    struct SubscriptionInfo {
        uint256 maxSubscribers;
        uint64 startBlock;
        uint64 endBlock;
    }

    struct LiquidityInfo {
        uint16 liquidityListingPercent;
        uint256 listingRate;
        //liqudity lock settings. if lock liquidity, 
        bool isLiquidityLock;
        uint64 liquidityLockTime;
    }

    struct ReferralInfo {
        uint16 percentage; // the percentage of tokens recieved per referal
        bool isPresale; // if this flag is true, users get a number of tokens for referring buyers
    }

    struct PresaleStatus {
        uint256 totalCurrencyDeposited; // total base currency raised (usually BNB)
        uint256 totalTokensSold; // total presale tokens sold
        uint256 totalTokensClaimed; // total tokens withdrawn post successful presale
        uint256 totalCurrencyClaimed; // total base tokens withdrawn on presale failure
        uint256 totalSubscribers; // number of unique subscribers
        bool isPresaleActive;
        bool isPresaleEnded;
    }

    struct SubscriberInfo {
        uint256 currencyDeposited; // total base token (usually BNB) deposited by user
        uint256 tokensClaimed; // num of tokens claimed by the subscriber
        uint256 availableClaim; // num presale tokens a user is owed shown with decimals, can be withdrawn after sale success
    }
    
    struct ReferralSubscribersInfo {
        uint256 subscribersReferred; // total number of addresses referered by this buyer
        uint256 tokensClaimed; // number of tokens user has collected on referal
        uint256 availableClaim; // number of tokens is owed after sale ends 
    }

    PresaleInfo public presaleInfo;
    ReferralInfo public referralInfo;
    PresaleStatus public presaleStatus;
    SubscriptionInfo public subscriptionInfo;
    LiquidityInfo public liquidityInfo;

    mapping(address => SubscriberInfo) public subscribers;
    mapping(address => ReferralSubscribersInfo) public referrals;
    address[] public referralList;
    EnumerableSet.AddressSet private whitelist;

    constructor(){
         presaleCreator = msg.sender;
    }

    modifier onlyPresaleOwner() {
        require(presaleInfo.presaleOwner == msg.sender, "NOT_PRESALE_OWNER");
        _;
    }

    function initialize(address _presaleCurrency, address _presaleToken) external override {
        presaleCurrency = _presaleCurrency;
        presaleToken = _presaleToken;
    }

    function presaleSetup ( 
        address payable _presaleOwner, 
        uint256 _tokenAmount, 
        uint256 _currencyMinimum, 
        uint256 _currencyMaximum,
        uint256 _presalePrice, 
        uint256 _presaleCap, 
        bool _isTokenBurn, 
        bool _isRefPresale, 
        uint16 _referralPercentage
    ) external override {
        require(msg.sender == presaleCreator, 'REQUEST_FORBIDDEN');
        presaleInfo.presaleOwner = _presaleOwner;
        presaleInfo.tokenAmount = _tokenAmount;
        presaleInfo.currencyMinimum = _currencyMinimum;
        presaleInfo.currencyMaximum = _currencyMaximum;
        presaleInfo.presalePrice = _presalePrice;
        presaleInfo.presaleCap = _presaleCap;
        presaleInfo.isTokenBurn = _isTokenBurn;
        referralInfo.isPresale = _isRefPresale;
        referralInfo.percentage = _referralPercentage;
    }

    function tokenSetup (
        address _presaleCurrency,
        address _presaleToken,
        uint8 _tokenDecimal,
        bool _isPresaleETH
    ) external override {
        require(msg.sender == presaleCreator, 'REQUEST_FORBIDDEN');
        presaleInfo.presaleCurrency = IERC20(_presaleCurrency);
        presaleInfo.presaleToken = IERC20(_presaleToken);
        presaleInfo.tokenDecimal = _tokenDecimal;
        presaleInfo.isPresaleETH = _isPresaleETH;
    }

    function subscriptionSetup(
        uint256 _maxSubscribers,
        uint64 _startBlock,
        uint64 _endBlock
    ) external override {
        require(msg.sender == presaleCreator, 'REQUEST_FORBIDDEN');
        subscriptionInfo.maxSubscribers = _maxSubscribers;
        subscriptionInfo.startBlock = _startBlock;
        subscriptionInfo.endBlock = _endBlock;
    }

    function liquiditySetup(
        uint16 _liquidityListingPercent,
        uint256 _listingRate,
        bool _isLiquidityLock,
        uint64 _liquidityLockTime
    ) external override {
        liquidityInfo.liquidityListingPercent = _liquidityListingPercent;
        liquidityInfo.listingRate = _listingRate;
        liquidityInfo.isLiquidityLock = _isLiquidityLock;
        liquidityInfo.liquidityLockTime = _liquidityLockTime;
    }

    function getPresaleStatus () public view returns (uint) {
        if (presaleStatus.totalCurrencyDeposited >= presaleInfo.presaleCap) {
            return 2; // presale success.
        }
        
        if(presaleStatus.isPresaleEnded){
            return 3; // presale is ended
        }
        
        if(presaleStatus.isPresaleActive){
            return 1; // presale is currently active
        }
        
        return 0; // presale is inactive
    }

    // accepts msg.value for eth or _amount for ERC20 tokens
    function userSubscription (uint256 _amount, address _referral) external payable nonReentrant {
        require(whitelist.contains(msg.sender), 'PRESALE_NOT_RESERVED');
        require(getPresaleStatus() == 1, 'PRESALE_NOT_ACTIVE'); // ACTIVE
        _userSubscription(_amount, _referral);
    }

    // accepts msg.value for bnb or _amount for BEP20 tokens
    function _userSubscription (uint256 _currencyAmount, address _referral) internal {
        SubscriberInfo storage subscriber = subscribers[msg.sender];
        uint256 amountIn = presaleInfo.isPresaleETH ? msg.value : _currencyAmount;
        uint256 remaining = presaleInfo.presaleCap.sub(presaleStatus.totalCurrencyDeposited);
        uint256 allowance = amountIn > remaining ? remaining : amountIn;
        uint256 minAllowed = presaleInfo.currencyMinimum;
        uint256 maxAllowed = presaleInfo.currencyMaximum;
        require(amountIn >= minAllowed, "AMOUNT_LESS_THAN_MINIMUM_REQUIRED");
        require(amountIn <= maxAllowed, "AMOUNT_MORE_THAN_MAXIMUM_ALLOWED");
        if (amountIn > allowance) {
            amountIn = allowance;
        }
        
        uint256 tokenAllocation = amountIn.mul(presaleInfo.presalePrice);
        require(amountIn > 0, 'ZERO_TOKENS_NOT_ALLOWED');
        if (subscriber.currencyDeposited == 0) {
            presaleStatus.totalSubscribers++;
        }
        subscriber.currencyDeposited = subscriber.currencyDeposited.add(amountIn);
        subscriber.availableClaim = subscriber.availableClaim.add(tokenAllocation);
        presaleStatus.totalCurrencyDeposited = presaleStatus.totalCurrencyDeposited.add(amountIn);
        presaleStatus.totalTokensSold = presaleStatus.totalTokensSold.add(tokenAllocation);
        
        // deposit and return unused currency amount
        if (presaleInfo.isPresaleETH && amountIn < msg.value) {
            TransferHelper.safeTransferETH(msg.sender, msg.value.sub(amountIn));
        }
        
        if(referralInfo.isPresale){
            uint256 tokenEarned = _calculatePercentage(tokenAllocation);
            _referralSubscription(_referral, tokenEarned);
        }
        
        //switch referal address to dead address
        if(!referralInfo.isPresale){
            _referral = address(0);
        }
        
        // deduct non BNB token from user
        if (!presaleInfo.isPresaleETH) {
            TransferHelper.safeTransferFrom(address(presaleInfo.presaleCurrency), msg.sender, address(this), amountIn);
        }
        
    }

    function activateReferral() external {
        referralInfo.isPresale = !referralInfo.isPresale;
    }
    
    function _referralSubscription(address _referral, uint256 _amount) internal {
        require(msg.sender != _referral, "You cannot refer yourself");
        require(_referral != address(0), "No referers address was given and referer cannot be zero address");
        ReferralSubscribersInfo storage referral = referrals[_referral];
        referral.subscribersReferred = referral.subscribersReferred.add(1);
        referral.availableClaim = referral.availableClaim.add(_amount);
        referralList.push(_referral);
    }

    function fullReferralList()public view returns(address[] memory){
        return referralList;
    }

    function _calculatePercentage(uint256 _tokenAmount) internal view returns (uint){
        require(_tokenAmount.div(10000).mul(10000) == _tokenAmount, 'Presale:: TOKEN_AMOUNT_TOO_SMALL');
        return _tokenAmount.mul(referralInfo.percentage).div(10000);
    }

    function modifyWhitelist(address[] memory _users, bool _add) external onlyPresaleOwner {
        require(getPresaleStatus() == 0, 'SUBSCRIPTION_HAS_STARTED'); // ACTIVE
        if (_add) {
            for (uint i = 0; i < _users.length; i++) {
            whitelist.add(_users[i]);
                require(whitelist.length() <= subscriptionInfo.maxSubscribers, "NOT ENOUGH SPOTS");
            }
        } else {
            for (uint i = 0; i < _users.length; i++) {
                require(subscribers[_users[i]].currencyDeposited == 0, "CANT UNLIST USERS WHO HAVE CONTRIBUTED");
                whitelist.remove(_users[i]);
            }
        }
    }

    // whitelist getters
    function getWhitelistedUsersLength () external view returns (uint256) {
        return whitelist.length();
    }
    
    function getWhitelistedUserAtIndex (uint256 _index) external view returns (address) {
        return whitelist.at(_index);
    }
    
    function getUserWhitelistStatus (address _user) external view returns (bool) {
        return whitelist.contains(_user);
    }
    

    // withdraw presale allocation
    // percentile withdrawls allows fee on transfer or rebasing tokens to still work
    function claimAllocation() external nonReentrant {
        require(getPresaleStatus() == 0, 'PRESALE_STILL_ACTIVE');
        require(address(presaleInfo.presaleToken) != address(0), 'ZERO_ADDRESS_TRANSFER_FORBIDDEN');
        SubscriberInfo storage subscriber = subscribers[msg.sender];
        ReferralSubscribersInfo storage referral = referrals[msg.sender];
        uint256 tokensAvailable = presaleInfo.presaleToken.balanceOf(address(this));
        uint256 allocation = subscriber.availableClaim;
        uint256 refTokens = referral.availableClaim;
        uint256 claimable = allocation.add(refTokens);
        require(tokensAvailable >= claimable, 'INSUFFICIENT_TOKENS_TO_CLAIM_AWAITING_REFILL');
        require(claimable > 0, 'NOTHING_TO_CLAIM');
        presaleStatus.totalTokensClaimed = presaleStatus.totalTokensClaimed.add(claimable);
        subscriber.availableClaim = 0;
        subscriber.tokensClaimed = subscriber.tokensClaimed.add(allocation);
        referral.availableClaim = 0;
        referral.tokensClaimed = referral.tokensClaimed.add(refTokens);
        TransferHelper.safeTransfer(address(presaleInfo.presaleToken), msg.sender, claimable);
    }


    // on presale failure
    // allows the owner to withdraw the tokens they sent for presale & initial liquidity
    function withdrawPresaleToken () external onlyPresaleOwner {
        require(getPresaleStatus() == 3); // FAILED
        TransferHelper.safeTransfer(
            address(presaleInfo.presaleToken), 
            presaleInfo.presaleOwner, 
            presaleInfo.presaleToken.balanceOf(address(this))
        );
    }


}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/structs/EnumerableSet.sol)

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
        mapping(bytes32 => uint256) _indexes;
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

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

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
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
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

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.1;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.1;

interface IPresale {
    
    function presaleCreator() external view returns (address);

    function initialize(address _presaleCurrency, address _presaleToken) external;

    function presaleSetup ( 
        address payable _presaleOwner, 
        uint256 _tokenAmount, 
        uint256 _currencyMinimum, 
        uint256 _currencyMaximum,
        uint256 _presalePrice, 
        uint256 _presaleCap, 
        bool _isTokenBurn, 
        bool _isRefPresale, 
        uint16 _referralPercentage
    ) external;

    function tokenSetup (
        address _presaleCurrency,
        address _presaleToken,
        uint8 _tokenDecimal,
        bool _isPresaleETH
    ) external;

    function subscriptionSetup(
        uint256 _maxSubscribers,
        uint64 _startBlock,
        uint64 _endBlock
    ) external;

    function liquiditySetup(
        uint16 _liquidityListingPercent,
        uint256 _listingRate,
        bool _isLiquidityLock,
        uint64 _liquidityLockTime
    ) external;

    
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.3.2 (utils/math/SafeMath.sol)

pragma solidity ^0.8.1;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
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
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
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
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.6.0;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeApprove: approve failed'
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::transferFrom: transferFrom failed'
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'TransferHelper::safeTransferETH: ETH transfer failed');
    }
}