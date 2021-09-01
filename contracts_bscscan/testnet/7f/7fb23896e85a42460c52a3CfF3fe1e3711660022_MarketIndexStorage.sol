// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./AccessControlUpgradeable.sol";
import "./EnumerableSet.sol";
import "./Initializable.sol";

contract MarketIndexStorage is
    Initializable,
    AccessControlUpgradeable
{
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet internal tokens;

    mapping(address => uint8[]) public categoryMaxValues;

    // Support for 5 categories, each represented by a mapping.
    // The more selective the filter, the fewer arrays to aggregate.
    // For characters:
    //      trait, level, 0, 0, 0
    // For shields and weapons:
    //      trait, stars, stat1trait, stat2trait, stat3trait
    mapping(address =>
    mapping(uint8 =>
    mapping(uint8 =>
    mapping(uint8 =>
    mapping(uint8 =>
    mapping(uint8 => EnumerableSet.UintSet)))))) internal listingIndex;

    mapping(address => EnumerableSet.UintSet) internal listingSets;

    function addToken(address _address, uint8[] memory _categoryMaxValues) public {
        require(!tokens.contains(_address));
        require(_categoryMaxValues.length <= 5);
        require(_categoryMaxValues.length >= 1);
        require(_categoryMaxValues[0] >= 2);

        tokens.add(_address);

        categoryMaxValues[_address] = new uint8[](_categoryMaxValues.length);
        for (uint categoryIndex = 0; categoryIndex < _categoryMaxValues.length; ++categoryIndex) {
            categoryMaxValues[_address][categoryIndex] = _categoryMaxValues[categoryIndex];
        }
    }

    function _keyFromCategoryValues(address _address, uint8[] memory _categoryValues) private view returns(uint8[] memory) {
        require(tokens.contains(_address));
        uint categoriesForToken = categoryMaxValues[_address].length;
        require(_categoryValues.length == categoriesForToken);

        uint8[] memory key = new uint8[](5);
        for (uint categoryIndex = 0; categoryIndex < _categoryValues.length; ++categoryIndex) {
            key[categoryIndex] = _categoryValues[categoryIndex];
        }
        for (uint categoryIndex = categoriesForToken; categoryIndex < 5; ++categoryIndex) {
            key[categoryIndex] = 0;
        }

        return key;
    }

    function _getIndexBucket(address _address, uint8[] memory _key) private view returns(EnumerableSet.UintSet storage) {
        require(tokens.contains(_address));
        require(_key.length == 5);
        return listingIndex[_address][_key[0]][_key[1]][_key[2]][_key[3]][_key[4]];
    }

    function addListing(address _address, uint256 _id, uint8[] memory _categoryValues) public {
        require(tokens.contains(_address));
        require(!listingSets[_address].contains(_id));

        uint8[] memory key = _keyFromCategoryValues(_address, _categoryValues);

        _getIndexBucket(_address, key).add(_id);
        listingSets[_address].add(_id);
    }

    function removeListing(address _address, uint256 _id, uint8[] memory _categoryValues) public {
        require(tokens.contains(_address));
        require(listingSets[_address].contains(_id));

        uint8[] memory key = _keyFromCategoryValues(_address, _categoryValues);

        require(_getIndexBucket(_address, key).contains(_id));
        _getIndexBucket(_address, key).remove(_id);
    }

    function getListings(uint256 _offset, uint256 _pageCount, address _address, uint8[] memory _categoryValues, bool[] memory _categoryFiltersActive)
        public
        view
        returns (uint256[] memory)
    {
        require(tokens.contains(_address));
        require(_categoryValues.length == categoryMaxValues[_address].length);
        require(_categoryFiltersActive.length == categoryMaxValues[_address].length);

        uint256[] memory listings = new uint256[](_pageCount);
        uint256 listingCount = 0;

        uint8[] memory keyCategoryValues = new uint8[](5); 
        for (uint8 a = 0; a < categoryMaxValues[_address][0]; a++) {
            if (_categoryFiltersActive[0] && (_categoryValues[0] != a)) {
                continue;
            }

            keyCategoryValues[0] = a;
            for (uint8 b = 0; b < categoryMaxValues[_address][1]; b++) {
                if ((categoryMaxValues[_address].length >= 2) && _categoryFiltersActive[1] && (_categoryValues[1] != b)) {
                    continue;
                }

                keyCategoryValues[1] = b;
                for (uint8 c = 0; c < categoryMaxValues[_address][2]; c++) {
                    if ((categoryMaxValues[_address].length >= 3) && _categoryFiltersActive[2] && (_categoryValues[2] != c)) {
                        continue;
                    }

                    keyCategoryValues[2] = c;
                    for (uint8 d = 0; d < categoryMaxValues[_address][3]; d++) {
                        if ((categoryMaxValues[_address].length >= 4) && _categoryFiltersActive[3] && (_categoryValues[3] != d)) {
                            continue;
                        }

                        keyCategoryValues[3] = d;
                        for (uint8 e = 0; e < categoryMaxValues[_address][4]; e++) {
                            if ((categoryMaxValues[_address].length >= 5) && _categoryFiltersActive[4] && (_categoryValues[4] != e)) {
                                continue;
                            }

                            keyCategoryValues[4] = e;

                            EnumerableSet.UintSet storage set = _getIndexBucket(_address, _keyFromCategoryValues(_address, keyCategoryValues));

                            if (_offset >= set.length()) {
                                _offset -= set.length();
                                continue;
                            }

                            uint256 i = _offset;
                            _offset = 0;
                            for ( ; ((i < set.length()) && (listingCount < _pageCount)); i++) {
                                listings[listingCount++] = set.at(i);
                            }

                            if (listingCount == _pageCount) {
                                return listings;
                            }
                        }
                    }
                }
            }
        }

        uint256[] memory returnListings = new uint256[](listingCount);
        for (uint i=0; i<listingCount; i++) {
            returnListings[i] = listings[i];
        }
        return returnListings;
    }

    function getTokens() public view returns (address[] memory) {
        address[] memory tokensArray = new address[](tokens.length());
        for (uint i = 0; i < tokens.length(); ++i) {
            tokensArray[i] = tokens.at(i);
        }
        return tokensArray;
    }
}