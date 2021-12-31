// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
// import "./RandomNumberGenerator.sol";

contract CharacterNFT is ERC1155, Ownable {
    address private companyOfficalEthAddress;
    // using Counters for Counters.Counter;
    // Counters.Counter private characterIds;

    mapping(uint256 => bool) private tokenIds;

    constructor() public ERC1155("") {
        companyOfficalEthAddress = msg.sender;
    }

    function mint(address to, uint256 tokenId, uint256 amount)
        public
        onlyOwner
        returns (uint256)
    {
        // require(msg.sender != to, 'Cannot mint token for itself');
        
        require(tokenId > 0, "token Id is required");
        require(to == address(to), "Invalid address");
        // characterIds.increment();
        // uint256 characterId = characterIds.current();
        tokenIds[tokenId] = true; 
        _mint(to, tokenId, amount, "");
    }

    function mintBatch(address[] memory owners, uint256[] memory tokenIds, uint256[] memory amounts)
        public
        onlyOwner
    {
        require(msg.sender == companyOfficalEthAddress, "You do not have permission to perform this action.");
        require(owners.length > 0, "Account array can not be empty");
        require(tokenIds.length > 0, "TokenIds array can not be empty");
        require(amounts.length > 0, "Amounts array can not be empty");
        
        // _mintBatch(to, ids, amounts, data);
        for(uint i = 0; i < owners.length; i++) {
            _mint(owners[i], tokenIds[i], amounts[i], "");
        }
    }

    function burn(address account, uint id) public {
        require(msg.sender == account);
        _burn(account, id, 1);
    }

    function getUri(uint256 _tokenId) public view returns (string memory) {
        require(_tokenId > 0, "token Id is required");
        // require( tokenIds[_tokenId] == false, "Token id should be less than the latest token id");
        return (string(abi.encodePacked(uri(0), Strings.toString(_tokenId), ".json")));
        
    }

   function setUri(string memory newUri) public {
       require(bytes(newUri).length > 0, "URI is required.");
       _setURI(newUri);
   }

}