// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./lib_core.sol";
import "./IERC721Receiver.sol";
import "./Interface_NFT_Marketplace_Agency.sol";

contract NFT_MARKETPLACE_OPERATOR is Ownable, IERC721Receiver {
    // Version 0.1
    using SafeMath for uint256;
    Interface_NFT_MARKETPLACE_AGENCY NFT_Marketplace_Agency;

    // NFT_Registry NFTregistry;

    /**
    * @dev Structs
    */

    /**
    * @dev Data Structures and Global Variables
    */

    //
    // Contract owner address.
    //
    address private $owner;

    //
    // Contract mark.
    //
    string public $mark;

    //
    // Marketplace Agency contract address. -- Use for hold NFT
    //
    
    address public $nft_marketplace_agency;




    /**
    * @dev Constructor
    */

    // Simply setup contract owner and payee to deployer address
    constructor(
        // address nft_registry,
        // address wrap_native_address
        string memory mark
    ) {
        $owner = msg.sender;
        $mark = mark;
    }

    /**
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function activateMarketplaceAgency(
        address nft_marketplace_agency
    ) 
        public
        onlyOwner
    {
        $nft_marketplace_agency = nft_marketplace_agency;
        NFT_Marketplace_Agency = Interface_NFT_MARKETPLACE_AGENCY(nft_marketplace_agency);
    }
    
    /**
    * @dev Public Functionalities
    */
    
    function agencySelector(
        address agency_address
    )
        private
        view
        returns (address)
    {
        return agency_address != address(0) ? agency_address : $nft_marketplace_agency;
    }

    //
    // Swap registered ERC20 token with an available ERC721 token slot 
    //  and mark status for the slot.
    //
    function sellNFT(
        address agency_address,
        address erc721_address,
        uint256 serial_no,
        string memory note
    )
        public
    {
        
    // Send NFT from a message sender to the registry for holding
        //   IERC721(erc721_address).safeTransferFrom(msg.sender, address(this), serial_no, "");  // For internal store
        Interface_NFT_MARKETPLACE_AGENCY(agencySelector(agency_address)).depositERC721(erc721_address, serial_no, msg.sender, note);

    }
    
    function cancelSellNFT(
        address agency_address,
        address erc721_address,
        uint256 serial_no,
        string memory note
    )
        public
    {
        // IERC721(erc721_address).safeTransferFrom(address(this), msg.sender, serial_no, ""); // For internal store.
        Interface_NFT_MARKETPLACE_AGENCY(agencySelector(agency_address)).withdrawERC721(erc721_address, serial_no, note);
    }

    /**
    * @dev Error Codes
    *
    * E:[0000] Undefined error.
    *
    *
    *
    */
}


// Created by Jimmy IsraKhan <[email protected]>
// Latest update: 2021-11-22