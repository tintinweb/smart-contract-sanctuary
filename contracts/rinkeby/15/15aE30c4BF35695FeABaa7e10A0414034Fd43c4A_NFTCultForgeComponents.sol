// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import '@openzeppelin/contracts/access/Ownable.sol';
import './INFTCultForgeComponents.sol';

/**
 * @title NFTCultForgeComponents
 * @author @NiftyMike, NFT Culture
 * @dev Companion contract to NFTCult, which enables some additional useful functionality
 * for future endeavors.
 */
contract NFTCultForgeComponents is INFTCultForgeComponents, Ownable {
    string public baseUri = 'https://gateway.pinata.cloud/ipfs/';

    mapping(string => uint256) public componentMap;

    constructor() {
        // set default mappings here.
        // componentMap[string(abi.encodePacked(baseUri, 'QmUiY69hp5vaKQUWEeQ6FfwHS4Hg3pZm6w26k9dQUXVaGF'))] = 201;
        // componentMap[string(abi.encodePacked(baseUri, 'QmS7eX8GEhAEba4rKDX4DTupwj1WMuMpM9bEUtZxQ5o2vq'))] = 202;
        // componentMap[string(abi.encodePacked(baseUri, 'Qmeov9xtVHbRVY9SKJQa6dZNszXHUdbvamrSGehecQh57P'))] = 203;
        // componentMap[string(abi.encodePacked(baseUri, 'QmR47kYHrVJrwKfRNWHEasZuSjaXLcDCiHfUMaG91bXxcQ'))] = 301;
        // componentMap[string(abi.encodePacked(baseUri, 'QmUfDC6tiBK53rTPeTp29y5F6hJanCimt8bu7ehfZN1p72'))] = 302;
        // componentMap[string(abi.encodePacked(baseUri, 'QmUrnkTZWUy6X61rdBXu68Q39LGWcMHMj9KehabgsRQ2Z9'))] = 303;
        // componentMap[string(abi.encodePacked(baseUri, 'QmQ6sVaVa2k5YMV3qWxVG2XwdnLspCqv8ae8HXpoM1GmXq'))] = 401;
        // componentMap[string(abi.encodePacked(baseUri, 'QmVSbsfNcESHavUkn7PerVL2QWVnRyyVbHYwAneT5HCLUX'))] = 402;
        // componentMap[string(abi.encodePacked(baseUri, 'QmcebF1sfwfLhherhegZJD1wPX6ijwCf2My8AAyb64bxN1'))] = 403;
        // componentMap[string(abi.encodePacked(baseUri, 'QmcD6HFetuhfcYwBm2255SW4jeFqpxsCCaFMpm61CS37Cc'))] = 997;
        // componentMap[string(abi.encodePacked(baseUri, 'QmTgoB1FLip7CmYPJ3nrAP3qTaRTt5EDHJR1pWi9it9Le7'))] = 901;
        // componentMap[string(abi.encodePacked(baseUri, 'QmdF1Dj1tmgwDQjxi4EKQPTqDEczagPJFaXXEeoBBQVyF7'))] = 902;
        // componentMap[string(abi.encodePacked(baseUri, 'QmZKATcFGhZR8hn1S2tSq9KFUZV28aPJanNCwwtDQNmCVm'))] = 903;

        componentMap['QmUiY69hp5vaKQUWEeQ6FfwHS4Hg3pZm'] = 201;
        componentMap['QmS7eX8GEhAEba4rKDX4DTupwj1WMuMp'] = 202;
        componentMap['Qmeov9xtVHbRVY9SKJQa6dZNszXHUdbv'] = 203;
        componentMap['QmR47kYHrVJrwKfRNWHEasZuSjaXLcDC'] = 301;
        componentMap['QmUfDC6tiBK53rTPeTp29y5F6hJanCim'] = 302;
        componentMap['QmUrnkTZWUy6X61rdBXu68Q39LGWcMHM'] = 303;
        componentMap['QmQ6sVaVa2k5YMV3qWxVG2XwdnLspCqv'] = 401;
        componentMap['QmVSbsfNcESHavUkn7PerVL2QWVnRyyV'] = 402;
        componentMap['QmcebF1sfwfLhherhegZJD1wPX6ijwCf'] = 403;
        componentMap['QmcD6HFetuhfcYwBm2255SW4jeFqpxsC'] = 997;
        componentMap['QmTgoB1FLip7CmYPJ3nrAP3qTaRTt5ED'] = 901;
        componentMap['QmdF1Dj1tmgwDQjxi4EKQPTqDEczagPJ'] = 902;
        componentMap['QmZKATcFGhZR8hn1S2tSq9KFUZV28aPJ'] = 903;
    }

    // Get Mapping
    function getMapping(string calldata tokenUri)
        external
        view
        returns (uint256)
    {
        require(bytes(tokenUri).length == 86, 'Invalid length');

        bytes memory strBytes = bytes(tokenUri);
        bytes memory result = new bytes(32); //66-34=32
        for (uint256 i = 34; i < 66; i++) {
            result[i - 34] = strBytes[i];
        }
        return componentMap[string(result)];
    }

    // Add Mapping
    function addMapping(string memory newURI, uint256 forgeComponentId)
        external
        onlyOwner
    {
        componentMap[newURI] = forgeComponentId;
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface INFTCultForgeComponents {
    function getMapping(string memory tokenUri)
        external
        view
        returns (uint256);

    function addMapping(string memory newURI, uint256 forgeCmponentId)
        external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}