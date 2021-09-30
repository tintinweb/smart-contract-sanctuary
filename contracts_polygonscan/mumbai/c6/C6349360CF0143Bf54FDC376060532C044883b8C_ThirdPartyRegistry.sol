// SPDX-License-Identifier: MIT

pragma solidity  ^0.7.3;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts/math/SafeMath.sol";

import "../commons//OwnableInitializable.sol";
import "../commons//NativeMetaTransaction.sol";
import "../interfaces/ICommittee.sol";
import "../interfaces/IERC20.sol";
import "../interfaces/ITiers.sol";
import "../libs/String.sol";

contract ThirdPartyRegistry is OwnableInitializable, NativeMetaTransaction {
    using SafeMath for uint256;

    struct ThirdPartyParam {
        string id;
        string metadata;
        string resolver;
        address[] managers;
        bool[] managerValues;
    }

    struct ItemParam {
        string id;
        string metadata;
    }

    struct ItemReviewParam {
        string id;
        string metadata;
        string contentHash;
        bool value;
    }

    struct ThirdPartyReviewParam {
        string id;
        bool value;
        ItemReviewParam[] items;
    }

    struct Item {
        string metadata;
        string contentHash;
        bool isApproved;
        uint256 registered;
    }

    struct ThirdParty {
        string metadata;
        string resolver;
        uint256 maxItems;
        bool isApproved;
        mapping(address => bool) managers;
        mapping(string => Item) items;
        string[] itemIds;
        uint256 registered;
    }

    mapping(string => ThirdParty) public thirdParties;
    string[] public thirdPartyIds;

    address public thirdPartyAgregator;
    address public feesCollector;
    ICommittee public committee;
    IERC20  public acceptedToken;
    ITiers public itemTiers;

    bool public initialThirdPartyValue;
    bool public initialItemValue;

    event ThirdPartyAdded(string _thirdPartyId, string _metadata, string _resolver, bool _isApproved, address[] _managers, address _caller);
    event ThirdPartyUpdated(string _thirdPartyId, string _metadata, string _resolver, address[] _managers, bool[] _managerValues, address _caller);
    event ThirdPartyItemsBought(string _thirdPartyId, uint256 _price, uint256 _value, address _caller);
    event ThirdPartyReviewed(string _thirdPartyId, bool _value, address _caller);

    event ItemAdded(string _thirdPartyId, string _itemId, string _metadata, bool _value, address _caller);
    event ItemUpdated(string _thirdPartyId, string _itemId, string _metadata, address _caller);
    event ItemReviewed(string _thirdPartyId, string _itemId, string _metadata, string _contentHash, bool _value, address _caller);

    event ThirdPartyAgregatorSet(address indexed _oldThirdPartyAgregator, address indexed _newThirdPartyAgregator);
    event FeesCollectorSet(address indexed _oldFeesCollector, address indexed _newFeesCollector);
    event CommitteeSet(ICommittee indexed _oldCommittee, ICommittee indexed _newCommittee);
    event AcceptedTokenSet(IERC20 indexed _oldAcceptedToken, IERC20 indexed _newAcceptedToken);
    event ItemTiersSet(ITiers indexed _oldItemTiers, ITiers indexed _newItemTiers);
    event InitialThirdPartyValueSet(bool _oldInitialThirdPartyValue, bool _newInitialThirdPartyValue);
    event InitialItemValueSet(bool _oldInitialItemValue, bool _newInitialItemValue);

   /**
    * @notice Create the contract
    * @param _owner - owner of the contract
    * @param _thirdPartyAgregator - third party agregator
    * @param _feesCollector - fees collector
    * @param _committee - committee smart contract
    * @param _acceptedToken - accepted token
    * @param _itemTiers - item tiers smart contract
    */
    constructor(
        address _owner,
        address _thirdPartyAgregator,
        address _feesCollector,
        ICommittee _committee,
        IERC20 _acceptedToken,
        ITiers _itemTiers
    ) {
        _initializeEIP712("Decentraland Third Party Registry", "1");
        _initOwnable();

        setThirdPartyAgregator(_thirdPartyAgregator);
        setFeesCollector(_feesCollector);
        setCommittee(_committee);
        setAcceptedToken(_acceptedToken);
        setItemTiers(_itemTiers);
        setInitialItemValue(false);
        setInitialThirdPartyValue(true);

        transferOwnership(_owner);
    }

    modifier onlyCommittee() {
        require(
            committee.members(_msgSender()),
            "TPR#onlyCommittee: CALLER_IS_NOT_A_COMMITTEE_MEMBER"
        );
        _;
    }

    modifier onlyThirdPartyAgregator() {
        require(
            thirdPartyAgregator == _msgSender(),
            "TPR#onlyThirdPartyAgregator: CALLER_IS_NOT_THE_PARTY_AGREGATOR"
        );
        _;
    }

    /**
    * @notice Set the third party agregator
    * @param _newThirdPartyAgregator - third party agregator
    */
    function setThirdPartyAgregator(address _newThirdPartyAgregator) onlyOwner public {
        require(_newThirdPartyAgregator != address(0), "TPR#setThirdPartyAgregator: INVALID_THIRD_PARTY_AGREGATOR");

        emit ThirdPartyAgregatorSet(thirdPartyAgregator, _newThirdPartyAgregator);
        thirdPartyAgregator = _newThirdPartyAgregator;
    }


     /**
    * @notice Set the fees collector
    * @param _newFeesCollector - fees collector
    */
    function setFeesCollector(address _newFeesCollector) onlyOwner public {
        require(_newFeesCollector != address(0), "TPR#setFeesCollector: INVALID_FEES_COLLECTOR");

        emit FeesCollectorSet(feesCollector, _newFeesCollector);
        feesCollector = _newFeesCollector;
    }

    /**
    * @notice Set the committee
    * @param _newCommittee - committee contract
    */
    function setCommittee(ICommittee _newCommittee) onlyOwner public {
        require(address(_newCommittee) != address(0), "TPR#setCommittee: INVALID_COMMITTEE");

        emit CommitteeSet(committee, _newCommittee);
        committee = _newCommittee;
    }

    /**
    * @notice Set the accepted token
    * @param _newAcceptedToken - accepted ERC20 token for collection deployment
    */
    function setAcceptedToken(IERC20 _newAcceptedToken) onlyOwner public {
        require(address(_newAcceptedToken) != address(0), "TPR#setAcceptedToken: INVALID_ACCEPTED_TOKEN");

        emit AcceptedTokenSet(acceptedToken, _newAcceptedToken);
        acceptedToken = _newAcceptedToken;
    }

     /**
    * @notice Set the itemTiers
    * @param _newItemTiers - itemTiers contract
    */
    function setItemTiers(ITiers _newItemTiers) onlyOwner public {
        require(address(_newItemTiers) != address(0), "TPR#setItemTiers: INVALID_ITEM_TIERS");

        emit ItemTiersSet(itemTiers, _newItemTiers);
        itemTiers = _newItemTiers;
    }

    /**
    * @notice Set whether third parties should be init approved or not
    * @param _newinitialThirdPartyValue - initial value
    */
    function setInitialThirdPartyValue(bool _newinitialThirdPartyValue) onlyOwner public {
        emit InitialThirdPartyValueSet(initialThirdPartyValue, _newinitialThirdPartyValue);
        initialThirdPartyValue = _newinitialThirdPartyValue;
    }

    /**
    * @notice Set whether items should be init approved or not
    * @param _newinitialItemValue - initial value
    */
    function setInitialItemValue(bool _newinitialItemValue) onlyOwner public {
        emit InitialItemValueSet(initialItemValue, _newinitialItemValue);
        initialItemValue = _newinitialItemValue;
    }

    /**
    * @notice Add third parties
    * @param _thirdParties - third parties to be added
    */
    function addThirdParties(ThirdPartyParam[] calldata _thirdParties) onlyThirdPartyAgregator external {
        for (uint256 i = 0; i < _thirdParties.length; i++) {
            ThirdPartyParam memory thirdPartyParam = _thirdParties[i];

            require(bytes(thirdPartyParam.id).length > 0, "TPR#addThirdParties: EMPTY_ID");
            require(bytes(thirdPartyParam.metadata).length > 0, "TPR#addThirdParties: EMPTY_METADATA");
            require(bytes(thirdPartyParam.resolver).length > 0, "TPR#addThirdParties: EMPTY_RESOLVER");
            require(thirdPartyParam.managers.length > 0, "TPR#addThirdParties: EMPTY_MANAGERS");

            ThirdParty storage thirdParty = thirdParties[thirdPartyParam.id];
            require(thirdParty.registered == 0, "TPR#addThirdParties: THIRD_PARTY_ALREADY_ADDED");

            thirdParty.registered = 1;
            thirdParty.metadata = thirdPartyParam.metadata;
            thirdParty.resolver = thirdPartyParam.resolver;
            thirdParty.isApproved = initialThirdPartyValue;

            for (uint256 m = 0; m < thirdPartyParam.managers.length; m++) {
                thirdParty.managers[thirdPartyParam.managers[m]] = true;
            }

            thirdPartyIds.push(thirdPartyParam.id);

            emit ThirdPartyAdded(
                thirdPartyParam.id,
                thirdParty.metadata,
                thirdParty.resolver,
                thirdParty.isApproved,
                thirdPartyParam.managers,
                _msgSender()
            );
        }
    }

    /**
    * @notice Update third parties
    * @param _thirdParties - third parties to be updated
    */
    function updateThirdParties(ThirdPartyParam[] calldata _thirdParties) external {
        address sender = _msgSender();

        for (uint256 i = 0; i < _thirdParties.length; i++) {
            ThirdPartyParam memory thirdPartyParam = _thirdParties[i];

            require(bytes(thirdPartyParam.id).length > 0, "TPR#updateThirdParties: EMPTY_ID");

            ThirdParty storage thirdParty = thirdParties[thirdPartyParam.id];
            require(
                thirdParty.managers[sender] || thirdPartyAgregator == sender,
                "TPR#updateThirdParties: CALLER_IS_NOT_MANAGER_OR_THIRD_PARTY_AGREGATOR"
            );

            _checkThirdParty(thirdParty);

            if (bytes(thirdPartyParam.metadata).length > 0) {
                thirdParty.metadata = thirdPartyParam.metadata;
            }

            if (bytes(thirdPartyParam.resolver).length > 0) {
                thirdParty.resolver = thirdPartyParam.resolver;
            }

            require(
                thirdPartyParam.managers.length == thirdPartyParam.managerValues.length,
                "TPR#updateThirdParties: LENGTH_MISMATCH"
            );

            for (uint256 m = 0; m < thirdPartyParam.managers.length; m++) {
                address manager = thirdPartyParam.managers[m];
                bool value = thirdPartyParam.managerValues[m];
                if (!value) {
                    require(sender != manager, "TPR#updateThirdParties: MANAGER_CANT_SELF_REMOVE");
                }

                thirdParty.managers[manager] = value;
            }

            emit ThirdPartyUpdated(
                thirdPartyParam.id,
                thirdParty.metadata,
                thirdParty.resolver,
                thirdPartyParam.managers,
                thirdPartyParam.managerValues,
                sender
            );
        }
    }

    /**
    * @notice Buy item slots
    * @param _thirdPartyId - third parties to be added
    * @param _tierIndex - index of the tier to be bought
    * @param _price - price to be paid
    */
    function buyItemSlots(string calldata _thirdPartyId, uint256 _tierIndex, uint256 _price)  external {
        address sender = _msgSender();

        ThirdParty storage thirdParty = thirdParties[_thirdPartyId];

        _checkThirdParty(thirdParty);

        ITiers.Tier memory tier = itemTiers.tiers(_tierIndex);
        require(tier.value > 0, "TPR#buyItems: INVALID_VALUE_FOR_TIER");
        require(tier.price == _price, "TPR#buyItems: PRICE_MISMATCH");

        if (tier.price > 0) {
            require(
                acceptedToken.transferFrom(sender, feesCollector, tier.price),
                "TPR#buyItems: TRANSFER_FEES_FAILED"
            );
        }

        thirdParty.maxItems = thirdParty.maxItems.add(tier.value);

        emit ThirdPartyItemsBought(_thirdPartyId, tier.price, tier.value, sender);
    }

     /**
    * @notice Add items to a third party
    * @param _thirdPartyId - third party id
    * @param _items - items to be added
    */
    function addItems(string calldata _thirdPartyId, ItemParam[] calldata _items) external {
        address sender = _msgSender();
        bool initValue = initialItemValue;

        ThirdParty storage thirdParty = thirdParties[_thirdPartyId];
        require(thirdParty.managers[sender], "TPR#addItems: INVALID_SENDER");
        require(thirdParty.maxItems >= thirdParty.itemIds.length.add(_items.length), "TPR#addItems: NO_ITEM_SLOTS_AVAILABLE");

        for (uint256 i = 0; i < _items.length; i++) {
            ItemParam memory itemParam = _items[i];
            _checkItemParam(itemParam);

            Item storage item = thirdParty.items[itemParam.id];
            require(item.registered == 0, "TPR#addItems: ITEM_ALREADY_ADDED");

            item.metadata = itemParam.metadata;
            item.isApproved = initValue;
            item.registered = 1;

            thirdParty.itemIds.push(itemParam.id);

            emit ItemAdded(
                _thirdPartyId,
                itemParam.id,
                itemParam.metadata,
                initValue,
                sender
            );
        }
    }

    /**
    * @notice Update items metadata
    * @param _thirdPartyId - third party id
    * @param _items - items to be updated
    */
    function updateItems(string calldata _thirdPartyId, ItemParam[] calldata _items) external {
        address sender = _msgSender();

        ThirdParty storage thirdParty = thirdParties[_thirdPartyId];
        require(thirdParty.managers[sender], "TPR#updateItems: INVALID_SENDER");

        for (uint256 i = 0; i < _items.length; i++) {
            ItemParam memory itemParam = _items[i];
            _checkItemParam(itemParam);

            Item storage item = thirdParty.items[itemParam.id];
            _checkItem(item);

            require(!item.isApproved, "TPR#updateItems: ITEM_IS_APPROVED");

            item.metadata = itemParam.metadata;

            emit ItemUpdated(
                _thirdPartyId,
                itemParam.id,
                itemParam.metadata,
                sender
            );
        }
    }

     /**
    * @notice Review third party items
    * @param _thirdParties - Third parties with items to be reviewed
    */
    function reviewThirdParties(ThirdPartyReviewParam[] calldata _thirdParties) onlyCommittee external {
        address sender = _msgSender();

        for (uint256 i = 0; i < _thirdParties.length; i++) {
            ThirdPartyReviewParam memory thirdPartyReview = _thirdParties[i];

            ThirdParty storage thirdParty = thirdParties[thirdPartyReview.id];
            _checkThirdParty(thirdParty);

            thirdParty.isApproved = thirdPartyReview.value;
            emit ThirdPartyReviewed(thirdPartyReview.id, thirdParty.isApproved, sender);

            for (uint256 j = 0; j < thirdPartyReview.items.length; j++) {
                ItemReviewParam memory itemReview = thirdPartyReview.items[j];
                require(bytes(itemReview.contentHash).length > 0, "TPR#reviewThirdParties: INVALID_CONTENT_HASH");

                Item storage item = thirdParty.items[itemReview.id];
                _checkItem(item);

                item.contentHash = itemReview.contentHash;
                item.isApproved = itemReview.value;

                if (bytes(itemReview.metadata).length > 0) {
                    item.metadata = itemReview.metadata;
                }

                emit ItemReviewed(
                    thirdPartyReview.id,
                    itemReview.id,
                    item.metadata,
                    item.contentHash,
                    item.isApproved,
                    sender
                );
            }
        }
    }

    /**
    * @notice Returns the count of third parties
    * @return Count of tiers
    */
    function thirdPartiesCount() external view returns (uint256) {
        return thirdPartyIds.length;
    }

     /**
    * @notice Returns if an address is a third party's manager
    * @return bool whether an address is a third party's manager or not
    */
    function isThirdPartyManager(string memory _thirdPartyId, address _manager) external view returns (bool) {
        return thirdParties[_thirdPartyId].managers[_manager];
    }

     /**
    * @notice Returns the count of items from a third party
    * @return Count of third party's items
    */
    function itemsCount(string memory _thirdPartyId) external view returns (uint256) {
        return thirdParties[_thirdPartyId].itemIds.length;
    }

    /**
    * @notice Returns an item id by index
    * @return id of the item
    */
    function itemIdByIndex(string memory _thirdPartyId, uint256 _index) external view returns (string memory) {
        return thirdParties[_thirdPartyId].itemIds[_index];
    }

     /**
    * @notice Returns an item
    * @return Item
    */
    function itemsById(string memory _thirdPartyId, string memory _itemId) external view returns (Item memory) {
        return thirdParties[_thirdPartyId].items[_itemId];
    }

    /**
    * @dev Check whether a third party has been registered
    * @param _thirdParty - Third party
    */
    function _checkThirdParty(ThirdParty storage _thirdParty) internal view {
        require(_thirdParty.registered > 0, "TPR#_checkThirdParty: INVALID_THIRD_PARTY");
    }

    /**
    * @dev Check whether an item has been registered
    * @param _item - Item
    */
    function _checkItem(Item memory _item) internal pure {
        require(_item.registered > 0, "TPR#_checkItem: INVALID_ITEM");
    }

    /**
    * @dev Check whether an item param is well formed
    * @param _item - Item param
    */
    function _checkItemParam(ItemParam memory _item) internal pure {
        require(bytes(_item.id).length > 0, "TPR#_checkItemParam: EMPTY_ID");
        require(bytes(_item.metadata).length > 0, "TPR#_checkItemParam: EMPTY_METADATA");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
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
        require(b > 0, errorMessage);
        return a / b;
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
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./ContextMixin.sol";

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
abstract contract OwnableInitializable is ContextMixin {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function _initOwnable () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

pragma solidity ^0.7.6;

import {SafeMath} from "@openzeppelin/contracts/math/SafeMath.sol";

import { EIP712Base } from "./EIP712Base.sol";

contract NativeMetaTransaction is EIP712Base {
    using SafeMath for uint256;
    bytes32 private constant META_TRANSACTION_TYPEHASH = keccak256(
        bytes(
            "MetaTransaction(uint256 nonce,address from,bytes functionSignature)"
        )
    );
    event MetaTransactionExecuted(
        address userAddress,
        address relayerAddress,
        bytes functionSignature
    );
    mapping(address => uint256) nonces;

    struct MetaTransaction {
        uint256 nonce;
        address from;
        bytes functionSignature;
    }

    function executeMetaTransaction(
        address userAddress,
        bytes memory functionSignature,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) external payable returns (bytes memory) {
        MetaTransaction memory metaTx = MetaTransaction({
            nonce: nonces[userAddress],
            from: userAddress,
            functionSignature: functionSignature
        });

        require(
            verify(userAddress, metaTx, sigR, sigS, sigV),
            "NMT#executeMetaTransaction: SIGNER_AND_SIGNATURE_DO_NOT_MATCH"
        );

        // increase nonce for user (to avoid re-use)
        nonces[userAddress] = nonces[userAddress].add(1);

        emit MetaTransactionExecuted(
            userAddress,
            msg.sender,
            functionSignature
        );

        // Append userAddress and relayer address at the end to extract it from calling context
        (bool success, bytes memory returnData) = address(this).call{value: msg.value}(
            abi.encodePacked(functionSignature, userAddress)
        );
        require(success, "NMT#executeMetaTransaction: CALL_FAILED");

        return returnData;
    }

    function hashMetaTransaction(MetaTransaction memory metaTx)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encode(
                    META_TRANSACTION_TYPEHASH,
                    metaTx.nonce,
                    metaTx.from,
                    keccak256(metaTx.functionSignature)
                )
            );
    }

    function getNonce(address user) external view returns (uint256 nonce) {
        nonce = nonces[user];
    }

    function verify(
        address signer,
        MetaTransaction memory metaTx,
        bytes32 sigR,
        bytes32 sigS,
        uint8 sigV
    ) internal view returns (bool) {
        require(signer != address(0), "NMT#verify: INVALID_SIGNER");
        return
            signer ==
            ecrecover(
                toTypedMessageHash(hashMetaTransaction(metaTx)),
                sigV,
                sigR,
                sigS
            );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;


interface ICommittee {
    function members(address _address) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;


interface IERC20 {
    function balanceOf(address from) external view returns (uint256);
    function transferFrom(address from, address to, uint tokens) external returns (bool);
    function transfer(address to, uint tokens) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function burn(uint256 amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;
pragma experimental ABIEncoderV2;


interface ITiers {
    struct Tier {
        uint256 value;
        uint256 price;
    }

    function tiers(uint256 _index) external view returns (Tier memory);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.12;

library String {

    /**
     * @dev Convert bytes32 to string.
     * @param _x - to be converted to string.
     * @return string
     */
    function bytes32ToString(bytes32 _x) internal pure returns (string memory) {
        bytes memory bytesString = new bytes(32);
        uint charCount = 0;
        for (uint j = 0; j < 32; j++) {
            bytes1 currentChar = bytes1(bytes32(uint(_x) * 2 ** (8 * j)));
            if (currentChar != 0) {
                bytesString[charCount] = currentChar;
                charCount++;
            }
        }
        bytes memory bytesStringTrimmed = new bytes(charCount);
        for (uint j = 0; j < charCount; j++) {
            bytesStringTrimmed[j] = bytesString[j];
        }
        return string(bytesStringTrimmed);
    }

    /**
     * @dev Convert uint to string.
     * @param _i - uint256 to be converted to string.
     * @return _uintAsString uint in string
     */
    function uintToString(uint _i) internal pure returns (string memory _uintAsString) {
        uint i = _i;

        if (i == 0) {
            return "0";
        }
        uint j = i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (i != 0) {
            bstr[k--] = bytes1(uint8(48 + i % 10));
            i /= 10;
        }
        return string(bstr);
    }

    /**
     * @dev Convert an address to string.
     * @param _x - address to be converted to string.
     * @return string representation of the address
     */
    function addressToString(address _x) internal pure returns (string memory) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint160(_x) / (2**(8*(19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2*i] = char(hi);
            s[2*i+1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) internal pure returns (bytes1 c) {
        if (uint8(b) < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    /**
     * @dev Lowercase a string.
     * @param _str - to be converted to string.
     * @return string
     */
    function toLowerCase(string memory _str) internal pure returns (string memory) {
        bytes memory bStr = bytes(_str);
        bytes memory bLower = new bytes(bStr.length);

        for (uint i = 0; i < bStr.length; i++) {
            // Uppercase character...
            if ((bStr[i] >= 0x41) && (bStr[i] <= 0x5A)) {
                // So we add 0x20 to make it lowercase
                bLower[i] = bytes1(uint8(bStr[i]) + 0x20);
            } else {
                bLower[i] = bStr[i];
            }
        }
        return string(bLower);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;


abstract contract ContextMixin {
    function _msgSender()
        internal
        view
        virtual
        returns (address payable sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                // Load the 32 bytes word from memory with the address on the lower 20 bytes, and mask those.
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;


contract EIP712Base {
    struct EIP712Domain {
        string name;
        string version;
        address verifyingContract;
        bytes32 salt;
    }

    bytes32 internal constant EIP712_DOMAIN_TYPEHASH = keccak256(
        bytes(
            "EIP712Domain(string name,string version,address verifyingContract,bytes32 salt)"
        )
    );
    bytes32 public domainSeparator;

    // supposed to be called once while initializing.
    // one of the contractsa that inherits this contract follows proxy pattern
    // so it is not possible to do this in a constructor
    function _initializeEIP712(
        string memory name,
        string memory version
    )
        internal
    {
        domainSeparator = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256(bytes(name)),
                keccak256(bytes(version)),
                address(this),
                bytes32(getChainId())
            )
        );
    }

    function getChainId() public pure returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /**
     * Accept message hash and returns hash message in EIP712 compatible form
     * So that it can be used to recover signer from signature signed using EIP712 formatted data
     * https://eips.ethereum.org/EIPS/eip-712
     * "\\x19" makes the encoding deterministic
     * "\\x01" is the version byte to make it compatible to EIP-191
     */
    function toTypedMessageHash(bytes32 messageHash)
        internal
        view
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked("\x19\x01", domainSeparator, messageHash)
            );
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}