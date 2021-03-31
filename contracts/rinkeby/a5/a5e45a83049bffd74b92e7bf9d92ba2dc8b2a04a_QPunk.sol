pragma solidity ^0.5.0;

import "./ERC721Tradable.sol";
import "./Ownable.sol";

/**
 * @title QPunk
 * QPunk - a contract for my non-fungible qpunks.
 */
contract QPunk is ERC721Tradable {
    constructor(address _proxyRegistryAddress)
        public
        ERC721Tradable("QPunk", "OSC", _proxyRegistryAddress)
    {}

    function baseTokenURI() public pure returns (string memory) {
        return "https://qpunk-metadata-api.herokuapp.com/api/token/";
    }

    function contractURI() public pure returns (string memory) {
        return "https://qpunk-metadata-api.herokuapp.com/contract/opensea-creatures";
    }
}