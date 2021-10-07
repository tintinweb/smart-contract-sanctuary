// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.8.0;

import "./ERC721.sol";
import "./Counters.sol";

contract LicenseKeyToken is ERC721 {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    constructor (string memory _name, string memory _symbol) public
        ERC721(_name, _symbol)
    {
    }

    /**
    * Custom accessor to create a unique token
    */
    function mintLicenseTokenTo(
        address _to,
        string memory _licenseKey,
        string memory _userId
    ) public returns(uint256)
    {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        
        super._mint(_to, newItemId);
        super._setLicenseInfo(newItemId, _licenseKey, _userId);
        
        return newItemId;
    }
}