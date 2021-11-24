// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './NFTCultForgeComponentsBase.sol';

/**
 * @title NFTCultForgeComponents_OptB
 * @author @NiftyMike, NFT Culture
 * @notice Some code cribbed from Open Zeppelin Ownable.sol.
 * @dev Companion contract to NFTCult, which enables some additional useful functionality
 * for future endeavors.
 *
 * Note: This option is gas optimized, and does not allow being expanded for future
 * forge components.
 */
contract NFTCultForgeComponents_OptB is NFTCultForgeComponentsBase {
    address private _owner;

    modifier onlyOwner() {
        require(_owner == msg.sender, 'Caller is not the owner');
        _;
    }

    uint256 private constant defaultYield = 1 << 128;
    uint256 private constant twotoneYield = (2 << 128) + 1;
    uint256 private constant ffspecialYield = defaultYield + 1;
    uint256 private constant justiceYield = (3 << 128) + 2;
    uint256 private constant twotoneJusticeYield = (6 << 128) + 5;

    constructor() {
        _owner = msg.sender;
    }

    function getYieldFromMapping(string calldata tokenUri)
        external
        pure
        returns (uint256)
    {
        require(bytes(tokenUri).length == 86, 'Invalid length');

        bytes32 uriPartBytes = bytes32(_SplitUri(tokenUri, 36, 44));

        bytes32[13] memory tokenUriLookup = [
            bytes32('UiY69hp5'),
            'S7eX8GEh',
            'eov9xtVH',
            'R47kYHrV',
            'UfDC6tiB',
            'UrnkTZWU',
            'Q6sVaVa2',
            'VSbsfNcE',
            'cebF1sfw',
            'cD6HFetu',
            'TgoB1FLi',
            'dF1Dj1tm',
            'ZKATcFGh'
        ];

        uint256[13] memory yieldLookup = [
            uint256(defaultYield),
            twotoneJusticeYield, // TODO TODO TODO FIX ME;
            twotoneYield,
            defaultYield,
            defaultYield,
            twotoneYield,
            defaultYield,
            defaultYield,
            twotoneYield,
            ffspecialYield,
            justiceYield,
            justiceYield,
            twotoneJusticeYield
        ];

        for (uint256 i = 0; i < 13; i++) {
            if (tokenUriLookup[i] == uriPartBytes) {
                return yieldLookup[i];
            }
        }

        return 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/**
 * @title NFTCultForgeComponentsBase
 * @author @NiftyMike, NFT Culture
 * @notice Some code cribbed from Open Zeppelin Ownable.sol.
 * @dev Base implementation of a uri splitter.
 */
abstract contract NFTCultForgeComponentsBase {
    function _SplitUri(
        string calldata tokenUri,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (bytes memory) {
        bytes memory strBytes = bytes(tokenUri);
        bytes memory result = new bytes(8); //66-34=32, but using 8 to reduce gas.
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return result;
    }
}