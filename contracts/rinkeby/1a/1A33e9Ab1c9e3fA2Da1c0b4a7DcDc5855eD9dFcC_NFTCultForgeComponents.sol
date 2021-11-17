// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import './INFTCultForgeComponents.sol';

/**
 * @title NFTCultForgeComponents
 * @author @NiftyMike, NFT Culture
 * @notice Some code cribbed from Open Zeppelin Ownable.sol.
 * @dev Companion contract to NFTCult, which enables some additional useful functionality
 * for future endeavors.
 */
contract NFTCultForgeComponents is INFTCultForgeComponents {
 
    mapping(string => uint256) public componentMap;
    address private _owner;

    constructor() {
        _owner = msg.sender;

        // Set default mappings here. Note the ipfs hashes are trimmed to 32 chars, but
        // this is fine since the hashes will never overlap that much in practice.
        componentMap['UiY69hp5'] = 201;
        componentMap['S7eX8GEh'] = 202;
        componentMap['eov9xtVH'] = 203;
        componentMap['R47kYHrV'] = 301;
        componentMap['UfDC6tiB'] = 302;
        componentMap['UrnkTZWU'] = 303;
        componentMap['Q6sVaVa2'] = 401;
        componentMap['VSbsfNcE'] = 402;
        componentMap['cebF1sfw'] = 403;
        componentMap['cD6HFetu'] = 997;
        componentMap['TgoB1FLi'] = 901;
        componentMap['dF1Dj1tm'] = 902;
        componentMap['ZKATcFGh'] = 903;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Caller is not the owner");
        _;
    }

    // Get Mapping EX: https://gateway.pinata.cloud/ipfs/QmcD6HFetuhfcYwBm2255SW4jeFqpxsCCaFMpm61CS37Cc/10001
    function getMapping(string calldata tokenUri)
        external
        view
        returns (uint256)
    {
        require(bytes(tokenUri).length == 86, 'Invalid length');

        bytes memory strBytes = bytes(tokenUri);
        bytes memory result = new bytes(8); //66-34=32, but using 8 to reduce gas.
        for (uint256 i = 36; i < 44; i++) {
            result[i - 36] = strBytes[i];
        }
        return componentMap[string(result)];
    }

    // Add Mapping
    function addMapping(string calldata newIpfsPart, uint256 forgeComponentId)
        external
        onlyOwner
    {
        componentMap[newIpfsPart] = forgeComponentId;
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