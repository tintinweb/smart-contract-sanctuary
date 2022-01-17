// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./ERC1155.sol";
import "./Ownable.sol";
import "./Counters.sol";
import "./Strings.sol";
// import "./RandomNumberGenerator.sol";


contract OperonOriginsNFT is ERC1155, Ownable {
    address private companyOfficialAddress;
    // using Counters for Counters.Counter;
    // Counters.Counter private characterIds;

    mapping(uint256 => bool) private mappingTokenIdToAvailability;

    constructor() public ERC1155("") {
        companyOfficialAddress = msg.sender;
    }

    /**  
    *    Mint token and transer to provided address
    *
    *    @param to address of the owner
    *    @param tokenId token Id
    *    @param amount quantity of respected tokenId
    */
    function mint(address to, uint256 tokenId, uint256 amount)
        public
        onlyOwner
        returns (uint256)
    {
        require(tokenId > 0, "Token Id is required");
        require(amount >= 1, "Amount is required");
        require(to == address(to), "Error: Invalid address provided");
        require(mappingTokenIdToAvailability[tokenId]  == false, "Error: This token id has been already allocated. Please try different one.");
        
        _mint(to, tokenId, amount, "");
        mappingTokenIdToAvailability[tokenId] = true;
        return tokenId;
    }

    /**
    *    Mint token in batch and transer to provided address
    *
    *    @param to address of owner 
    *    @param tokenIds array iist of token Ids
    *    @param amounts arrray list of quantity of a specific token Id 
    */
    function mintBatch(address to, uint256[] memory tokenIds, uint256[] memory amounts)
        public
        onlyOwner
    {
        require(msg.sender == companyOfficialAddress, "Error: You do not have permission to perform this action.");
        require(to == address(to), "Error: Invalid address provided");
        require(tokenIds.length > 0, "TokenIds array can not be empty");
        require(amounts.length > 0, "Amounts array can not be empty");
        
        _mintBatch(to, tokenIds, amounts, "");
        // for(uint i = 0; i < owners.length; i++) {
        //     _mint(owners[i], tokenIds[i], amounts[i], "");
        // }
    }

    function burn(address account, uint id) public {
        require(msg.sender == account);
        _burn(account, id, 1);
    }

    /**
     *  Return uri of provided token Id
     *  @return token uri
     */
    function getUri(uint256 tokenId) public view returns (string memory) {
        require(tokenId > 0, "Token Id is required");
        return (string(abi.encodePacked(uri(0), Strings.toString(tokenId), ".json")));
        
    }

    /**
     * Sets new metadata uri
     * @param metadataUrl full URL of the metadata
     */
    function setUri(string memory metadataUrl) public {
       require(bytes(metadataUrl).length > 0, "URI is required.");
       _setURI(metadataUrl);
    }


    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public override {
        // require(
        //     from == _msgSender() || isApprovedForAll(from, _msgSender()),
        //     "ERC1155: caller is not owner nor approved"
        // );
        _safeTransferFrom(from, to, id, amount, data);
    }
}