// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import '@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/utils/ContextUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';
import '@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol';
import './interfaces/IVersionedContract.sol';

contract TraitFactory is
	Initializable,
	ContextUpgradeable,
	AccessControlEnumerableUpgradeable,
	IVersionedContract
{
	using CountersUpgradeable for CountersUpgradeable.Counter;

	/*
   	=======================================================================
   	======================== Structures ===================================
   	=======================================================================
	*/
	struct Item {
		string name;
		uint256 totalSeries;
	}

	struct Series {
		uint256 itemId;
		uint256 seriesId;
		string name;
		uint256 maxNfts;
		uint256 totalNftsMinted;
		bool isNumberedNFT;
		uint8 totalTraits;
	}

	struct TraitDetail {
		uint256 itemId;
		uint256 seriesId;
		string name;
	}

	struct TraitVariation {
		uint256 itemId;
		uint256 seriesId;
		uint256 traitId;
		string name;
		string svg;
		uint256 probability;
	}

	struct ThresholdDetail {
		uint256 max;
		string badgeName;
		string badgeSvg;
	}

	/*
   	=======================================================================
   	======================== Constants ====================================
   	=======================================================================
 	*/
	bytes32 public constant OPERATOR_ROLE = keccak256('OPERATOR_ROLE');
	bytes32 public constant UPDATOR_ROLE = keccak256('UPDATOR_ROLE');

	/*
   	=======================================================================
   	======================== Private Variables ============================
   	=======================================================================
 	*/

	CountersUpgradeable.Counter internal itemCounter;
	CountersUpgradeable.Counter internal traitCounter;
	CountersUpgradeable.Counter internal traitVariationCounter;
	CountersUpgradeable.Counter internal thresholdCounter;

	/*
   	=======================================================================
   	======================== Public Variables ============================
   	=======================================================================
 	*/

	string public fontName;

	/// @notice price for generating new item
	uint256 public generationFee;

	// @notice itemId => Item
	mapping(uint256 => Item) public items;

	// @notice itemId => seriesId => Series
	mapping(uint256 => mapping(uint256 => Series)) public seriesDetails;

	// @notice traitId => TraitDetail
	mapping(uint256 => TraitDetail) public traitDetails;

	// @notice traitVariationId => TraitVariation
	mapping(uint256 => TraitVariation) public traitVariations;

	// @notice itemId => current seriesId
	mapping(uint256 => uint256) public currentSeries;

	// @notice itemId => seriesId => traitIds
	mapping(uint256 => mapping(uint256 => uint256[])) public seriesTraitIds;

	// @notice itemId => seriesId => traitId => totalVariations
	mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256))) public seriesTraitVariations;

	// @notice itemId => seriesId => traitId => variationIds
	mapping(uint256 => mapping(uint256 => mapping(uint256 => uint256[]))) public variationIds;

	// itemId => seriesID => bool
	mapping(uint256 => mapping(uint256 => bool)) public isNftGenerationEnabled;

	/// @notice  thresholdId  => ThresholdDetail
	mapping(uint256 => ThresholdDetail) public thresholds;

	/*
		=======================================================================
   	======================== Constructor/Initializer ======================
   	=======================================================================
 	*/
	/**
	 * @notice Used in place of the constructor to allow the contract to be upgradable via proxy.
	 */
	function initialize(string memory _fontName, uint256 _generationFee)
		external
		virtual
		initializer
	{
		__Context_init_unchained();
		__AccessControl_init_unchained();
		__AccessControlEnumerable_init_unchained();

		_setupRole(DEFAULT_ADMIN_ROLE, _msgSender());

		fontName = _fontName;
		generationFee = _generationFee;
	}

	/*
   	=======================================================================
   	======================== Events =======================================
   	=======================================================================
 	*/
	event ItemAdded(uint256 itemId);
	event SeriesUpdated(uint256 itemId, uint256 seriesId);
	event TraitAdded(uint256 traitId);
	event TraitVariationAdded(uint256 traitVariationId);
	event TraitVariationUpdated(uint256 traitVariationId);

	/* 
	 =======================================================================
   	======================== Modifiers ====================================
   	=======================================================================
 	*/

	modifier onlyOperator() {
		require(hasRole(OPERATOR_ROLE, _msgSender()), 'TraitFactory: ONLY_OPERATOR_CAN_CALL');
		_;
	}

	modifier onlyUpdator() {
		require(hasRole(UPDATOR_ROLE, _msgSender()), 'TraitFactory: ONLY_UPDATOR_CAN_CALL');
		_;
	}

	modifier onlyValidItemId(uint256 _itemId) {
		require(
			_itemId > 0 && _itemId <= itemCounter.current(),
			'TraitFactory: INVALID_ITEM_ID'
		);
		_;
	}

	modifier onlyValidseriesId(uint256 _itemId, uint256 _series) {
		require(
			_series > 0 && _series <= currentSeries[_itemId],
			'TraitFactory: INVALID_SERIES_ID'
		);
		_;
	}

	modifier onlyValidTraitId(uint256 _traitId) {
		require(_traitId > 0 && _traitId <= traitCounter.current(), 'TraitFactory: INVALID_TRAIT_ID');
		_;
	}

	modifier onlyValidName(string memory _name) {
		require(bytes(_name).length > 0, 'TraitFactory: INVALID_NAME');
		_;
	}

	/*
   	=======================================================================
   	======================== Public Methods ===============================
   	=======================================================================
 	*/

	/**
	 * @notice This method allows operator to add the item
	 * @param _itemName - indicates the name of the item. ex. Talien
	 * @return itemId - indicates the id of newly added item
	 */
	function addItem(string memory _itemName)
		external
		virtual
		onlyOperator
		onlyValidName(_itemName)
		returns (uint256 itemId)
	{
		itemCounter.increment();
		itemId = itemCounter.current();

		items[itemId].name = _itemName;
		emit ItemAdded(itemId);
	}

	/**
	 * @notice This method allows operator to add the series for the item to allow minting of nfts
	 * @param _itemId - indicates the id of item for which series to add
	 * @param _maxNFTS - indicates the maximum number of nfts to mint in the series
	 * @param _seriesName - indicates the name of the series
	 * @param _isNumbered - indicates the whether the series nfts will be numbered or not
	 */
	function updateSeries(
		uint256 _itemId,
		uint256 _maxNFTS,
		string memory _seriesName,
		bool _isNumbered
	) external virtual onlyOperator onlyValidItemId(_itemId) onlyValidName(_seriesName) {
		require(_maxNFTS > 0, 'TratiFactory: INSUFFICIENT_NFTS');

		//increament series counter for item
		currentSeries[_itemId] += 1;

		//get current series id
		uint256 seriesId = currentSeries[_itemId];

		seriesDetails[_itemId][seriesId].itemId = _itemId;
		seriesDetails[_itemId][seriesId].seriesId = seriesId;
		seriesDetails[_itemId][seriesId].name = _seriesName;
		seriesDetails[_itemId][seriesId].maxNfts = _maxNFTS;
		seriesDetails[_itemId][seriesId].isNumberedNFT = _isNumbered;

		emit SeriesUpdated(_itemId, seriesId);
	}

	/**
	 * @notice This method allows operator to add the traits for the series of particular item.
	 * @param _itemId - indicates the item id
	 * @param _seriesId - indicates the series of item for which trait to add
	 * @param _traitName - indicates the trait name
	 * @return traitId - indicates the unique trait id.
	 */
	function addTrait(
		uint256 _itemId,
		uint256 _seriesId,
		string memory _traitName
	)
		external
		virtual
		onlyOperator
		onlyValidItemId(_itemId)
		onlyValidseriesId(_itemId, _seriesId)
		onlyValidName(_traitName)
		returns (uint256 traitId)
	{
		traitCounter.increment();
		traitId = traitCounter.current();

		traitDetails[traitId].itemId = _itemId;
		traitDetails[traitId].seriesId = _seriesId;
		traitDetails[traitId].name = _traitName;

		seriesDetails[_itemId][_seriesId].totalTraits = uint8(
			seriesDetails[_itemId][_seriesId].totalTraits + 1
		);

		seriesTraitIds[_itemId][_seriesId].push(traitId);

		emit TraitAdded(traitId);
	}

	/**
	 * @notice This method allows operator to add the variation for the trait
	 * @param _itemId - indicates the item id
	 * @param _seriesId - indicates the series of item
	 * @param _traitId - indicates the trait id of given series
	 * @param _variationName - indicates the variation name
	 * @param _svg - indicates the svg of variation
	 * @param _probabilty - indicates the probablity of variation to get selected
	 * @return variationId - indicatest the unique variation id
	 */
	function addTraitVariation(
		uint256 _itemId,
		uint256 _seriesId,
		uint256 _traitId,
		string memory _variationName,
		string memory _svg,
		uint256 _probabilty
	)
		external
		virtual
		onlyOperator
		onlyValidItemId(_itemId)
		onlyValidseriesId(_itemId, _seriesId)
		onlyValidTraitId(_traitId)
		onlyValidName(_variationName)
		returns (uint256 variationId)
	{
		require(bytes(_svg).length > 0, 'TraitFactory: INVALID_SVG');

		traitVariationCounter.increment();
		variationId = traitVariationCounter.current();

		traitVariations[variationId] = TraitVariation(
			_itemId,
			_seriesId,
			_traitId,
			_variationName,
			_svg,
			_probabilty
		);

		// update total variations of trait
		seriesTraitVariations[_itemId][_seriesId][_traitId] += 1;

		//update variation ids of trait
		variationIds[_itemId][_seriesId][_traitId].push(variationId);

		emit TraitVariationAdded(variationId);
	}

	/**
	 * @notice This method allows operator to update the trait variation details
	 * @param _traitVariationId - indicates the trait variation id which is to update.
	 * @param _variationName - indicates the variation name
	 * @param _svg - indicates the variation svg
	 * @param _probabilty - indicates the probability
	 */
	function updateTraitVariation(
		uint256 _traitVariationId,
		string memory _variationName,
		string memory _svg,
		uint256 _probabilty
	) external virtual onlyOperator onlyValidName(_variationName) {
		require(
			_traitVariationId > 0 && _traitVariationId < traitVariationCounter.current(),
			'TraitFactory: INVALID_VARIATION_ID'
		);
		require(bytes(_svg).length > 0, 'TraitFactory: INVALID_SVG');

		traitVariations[_traitVariationId].name = _variationName;
		traitVariations[_traitVariationId].svg = _svg;
		traitVariations[_traitVariationId].probability = _probabilty;

		emit TraitVariationUpdated(_traitVariationId);
	}

	function activateNFTGeneration(uint256 _itemId, uint256 _seriesId)
		external
		onlyOperator
		onlyValidItemId(_itemId)
		onlyValidseriesId(_itemId, _seriesId)
	{
		isNftGenerationEnabled[_itemId][_seriesId] = true;
	}

	function deactivateNFTGeneration(uint256 _itemId, uint256 _seriesId)
		external
		onlyOperator
		onlyValidItemId(_itemId)
		onlyValidseriesId(_itemId, _seriesId)
	{
		isNftGenerationEnabled[_itemId][_seriesId] = true;
	}

	/**
	 * @notice This method allows admin to add the thresholds for the likes.
	 * If talien exceeds the max value of threshold, we show the respective badge on the talien svg.
	 * @param _maxValue - indicates the max value for threshold
	 * @param _badge - indicates the badge name for the threshold
	 * @param _badgeSvg - indicates the badge svg
	 * @return thresholdId - indicates threshold id
	 */
	function addThreshold(
		uint256 _maxValue,
		string memory _badge,
		string memory _badgeSvg
	) external onlyOperator returns (uint256 thresholdId) {
		require(bytes(_badgeSvg).length > 0, 'TraitFactory: INVALID_BADGE');

		thresholdCounter.increment();
		thresholdId = thresholdCounter.current();

		// threshold value must be greater than previous value
		if (thresholdId > 1) {
			require(_maxValue > thresholds[thresholdId - 1].max, 'TraitFactory: INVALID_VALUE');
		}

		thresholds[thresholdId] = ThresholdDetail(_maxValue, _badge, _badgeSvg);
	}

	/**
	 * @notice This method allows admin to update the threshold details.
	 * @param _thresholdId - indicates the threshold id to update
	 * @param _maxValue - indicates the max value for threshold
	 * @param _badge - indicates the badge name for the threshold
	 * @param _badgeSvg - indicates the badge svg
	 */
	function updateThreshold(
		uint256 _thresholdId,
		uint256 _maxValue,
		string memory _badge,
		string memory _badgeSvg
	) external onlyOperator {
		require(
			_thresholdId > 0 && _thresholdId <= thresholdCounter.current(),
			'TraitFactory: INVALID_THRESHOLD_ID'
		);
		require(bytes(_badgeSvg).length > 0, 'TraitFactory: INVALID_BADGE');

		thresholds[_thresholdId] = ThresholdDetail(_maxValue, _badge, _badgeSvg);
	}

	/**
	 * @notice This method allows admin to update the font name.
	 * @param _fontName - indicates the font name for the nft id text on svg
	 */
	function updateFontName(string memory _fontName)
		external
		virtual
		onlyOperator
		onlyValidName(_fontName)
	{
		fontName = _fontName;
	}

	/**
	 * @notice This method allows updater to update the total nfts minted per series.
	 * @param _itemId - indicates the item id
	 * @param _seriesId - indicates the series of item
	 * @param _amount - indicates the amount of nfts minted
	 */
	function updateTotalNftsMinted(
		uint256 _itemId,
		uint256 _seriesId,
		uint256 _amount
	)
		external
		virtual
		onlyUpdator
		onlyValidItemId(_itemId)
		onlyValidseriesId(_itemId, _seriesId)
	{
		require(_amount > 0, 'TraitFactory: INVALID_AMOUNT');

		Series storage series = seriesDetails[_itemId][_seriesId];
		series.totalNftsMinted += _amount;
	}

	/**
	 * @notice This method allows admin to update the item generation fee
	 * @param _newFee - indicates the new fee for generating the profile s
	 */
	function updateItemGenerationFee(uint256 _newFee) external virtual onlyOperator {
		require(_newFee > 0 && _newFee != generationFee, 'TraitFactory: INVALID_FEE');
		generationFee = _newFee;
	}

	/*
   	=======================================================================
   	======================== Getter Methods ===============================
   	=======================================================================
 	*/

	/**
	 * @notice This method returns the current item id
	 */
	function getCurrentItemId() external view virtual returns (uint256) {
		return itemCounter.current();
	}

	/**
	 * @notice This method returns the current trait id
	 */
	function getCurrentTraitId() external view virtual returns (uint256) {
		return traitCounter.current();
	}

	/**
	 * @notice This method returns the current trait variation id
	 */
	function getCurrentTraitVariationId() external view virtual returns (uint256) {
		return traitVariationCounter.current();
	}

	/**
	 * @notice This method returns the current threshold id
	 */
	function getCurrentThresholdId() external view virtual returns (uint256) {
		return thresholdCounter.current();
	}

	/**
	 * @notice This method returns the total variations of the trait for given series
	 */
	function getTotalVariationsForTrait(
		uint256 _itemId,
		uint256 _seriesId,
		uint256 _traitId
	)
		external
		view
		virtual
		onlyValidItemId(_itemId)
		onlyValidTraitId(_traitId)
		onlyValidseriesId(_itemId, _seriesId)
		returns (uint256)
	{
		return seriesTraitVariations[_itemId][_seriesId][_traitId];
	}

	/**
	 * @notice This method returns the trait id at given index of series
	 */
	function getSeriesTraitId(
		uint256 _itemId,
		uint256 _seriesId,
		uint256 _index
	)
		external
		view
		virtual
		onlyValidItemId(_itemId)
		onlyValidseriesId(_itemId, _seriesId)
		returns (uint256)
	{
		require(
			_index < seriesDetails[_itemId][_seriesId].totalTraits,
			'TraitFactory: INVALID_INDEX'
		);
		return seriesTraitIds[_itemId][_seriesId][_index];
	}

	/**
	 * @notice This method returns the variation id at given index of trait series
	 */
	function getVariationsId(
		uint256 _itemId,
		uint256 _seriesId,
		uint256 _traitId,
		uint256 _index
	)
		external
		view
		virtual
		onlyValidItemId(_itemId)
		onlyValidseriesId(_itemId, _seriesId)
		onlyValidTraitId(_traitId)
		returns (uint256)
	{
		require(
			_index < seriesTraitVariations[_itemId][_seriesId][_traitId],
			'TraitFactory: INVALID_INDEX'
		);
		return variationIds[_itemId][_seriesId][_traitId][_index];
	}

	function getSvgNumber(uint256 _tokenId) external view returns (string memory svgNumber) {
		svgNumber = string(
			abi.encodePacked(
				'<style>@import url(https://assets.lacucina.finance/css/fonts.css);</style><text x="570" y="25" text-anchor="end" font-family="',
				fontName,
				'" fill="#ff17b9" font-size="20">',
				toString(_tokenId),
				'</text>'
			)
		);
	}

	function getSvgBadge(uint256 _totalLikes) external view returns (string memory badge) {
		uint256 threshold;
		for (threshold = 1; threshold <= thresholdCounter.current(); threshold++) {
			if (_totalLikes < thresholds[threshold].max) {
				break;
			}
			badge = thresholds[threshold].badgeSvg;
		}
	}

	function getSvgLikes(uint256 _totalLikes) external view returns (string memory svgLikes) {
		svgLikes = string(
			abi.encodePacked(
				'<style>@import url(https://assets.lacucina.finance/css/fonts.css);</style><text x="10" y="570" text-anchor="start" font-family="',
				fontName,
				'" fill="#ff17b9" font-size="20">',
				toString(_totalLikes),
				'</text>'
			)
		);
	}

	/**
	 * @dev Converts a `uint256` to its ASCII `string` decimal representation.
	 */
	function toString(uint256 value) internal pure returns (string memory) {
		// Inspired by OraclizeAPI's implementation - MIT licence
		// https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

		if (value == 0) {
			return '0';
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
	 * @notice Returns the storage, major, minor, and patch version of the contract.
	 * @return The storage, major, minor, and patch version of the contract.
	 */
	function getVersionNumber()
		external
		pure
		virtual
		override
		returns (
			uint256,
			uint256,
			uint256
		)
	{
		return (1, 0, 0);
	}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVersionedContract {
	/**
	 * @notice Returns the storage, major, minor, and patch version of the contract.
	 * @return The storage, major, minor, and patch version of the contract.
	 */
	function getVersionNumber()
		external
		pure
		returns (
			uint256,
			uint256,
			uint256
		);
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
library EnumerableSetUpgradeable {
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

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
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

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
    }

    function __AccessControl_init_unchained() internal initializer {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

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
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{20}) is missing role (0x[0-9a-f]{32})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
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
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./AccessControlUpgradeable.sol";
import "../utils/structs/EnumerableSetUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerableUpgradeable {
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerableUpgradeable is Initializable, IAccessControlEnumerableUpgradeable, AccessControlUpgradeable {
    function __AccessControlEnumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __AccessControl_init_unchained();
        __AccessControlEnumerable_init_unchained();
    }

    function __AccessControlEnumerable_init_unchained() internal initializer {
    }
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    mapping(bytes32 => EnumerableSetUpgradeable.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerableUpgradeable).interfaceId || super.supportsInterface(interfaceId);
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
    uint256[49] private __gap;
}