// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721URIStorage.sol";
import "./Counters.sol";

contract Poyomasks is ERC721URIStorage {
    using Counters for Counters.Counter;

    Counters.Counter internal _idCounter;

    constructor() ERC721("Poyomasks", "PM") {}

    function mint(address owner, string memory tokenURI)
        external
        returns (uint256)
    {
        _idCounter.increment();

        uint256 id = _idCounter.current();
        _mint(owner, id);
        _setTokenURI(id, tokenURI);

        return id;
    }
}