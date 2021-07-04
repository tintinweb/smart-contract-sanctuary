// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "./erc.sol";

contract NFT is ERC721,AccessControlMixin{
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
    event TokenDeleted(uint256 indexed _tokenId);
    event UpdatedURI(uint256 indexed _tokenId, string tokenURI_);
    bytes32 public constant PREDICATE_ROLE = keccak256("PREDICATE_ROLE");
    
    constructor() public ERC721("CHANI", "CT") {
        _setupRole(PREDICATE_ROLE, _msgSender());
        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupContractId("MintableERC721");
    }
    
    
    function mint(string memory tokenURI_)
        external
    only(PREDICATE_ROLE)
    returns (uint256)
    {
            _tokenIds.increment();
            uint256 newItemId = _tokenIds.current();
            _mint(getRoleMember(0x00,0), newItemId);
            _setTokenURI(newItemId,tokenURI_);
            return newItemId;
    }
    
}