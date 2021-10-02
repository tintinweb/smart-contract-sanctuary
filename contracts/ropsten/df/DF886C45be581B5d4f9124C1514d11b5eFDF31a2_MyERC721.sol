// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC721.sol";
import "./Counters.sol";

contract MyERC721 is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    constructor (string memory _name, string memory _symbol) public
        ERC721(_name, _symbol)
    {
    }

    /**
    * Custom accessor to create a unique token
    */
    function mintUniqueTokenTo(
        address _to,
        string memory _licenseInfo
    ) public returns(uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        
        super._mint(_to, newItemId);
        super._setlicenseInfo(newItemId, _licenseInfo);
        
        return newItemId;
    }
}