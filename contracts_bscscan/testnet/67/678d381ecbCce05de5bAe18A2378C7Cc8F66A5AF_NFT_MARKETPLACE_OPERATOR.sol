// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./lib_core.sol";
import "./Interface_NFT_Marketplace_Agency.sol";

contract NFT_MARKETPLACE_OPERATOR is Ownable {
    // Version 0.4
    using SafeMath for uint256;
    Interface_NFT_MARKETPLACE_AGENCY NFT_Marketplace_Agency;


    /**
    * @dev Structs
    */
    
    struct NFT_Quote {
        string symbol;
        address currency_address;
        uint256 amount;
    }

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
    // Contract activeness status.
    //
    bool public $active = true;

    //
    // Default Marketplace Agency contract address. -- Use for hold NFT
    //
    
    address public $nft_marketplace_agency;

    //
    // Quote for each NFT
    // Map for store quote (setting price) of an ERC20 token for each ERC721 token.
    // $quoteNFT[nft_address][serial_no][erc20_address] => amount
    mapping(address => mapping(uint256 => mapping(address => uint256))) private $quoteNFT;


    /**
    * @dev Constructor
    */

    // Simply setup contract owner by its deployer and its mark
    constructor(
        string memory mark
    ) {
        $owner = msg.sender;
        $mark = mark;
    }

    function setDefaultMarketplaceAgency(
        address nft_marketplace_agency
    ) 
        public
        onlyOwner
    {
        $nft_marketplace_agency = nft_marketplace_agency;
        NFT_Marketplace_Agency = Interface_NFT_MARKETPLACE_AGENCY(nft_marketplace_agency);
    }
    
    function agencySelector(
        address agency_address
    )
        private
        view
        returns (address)
    {
        return agency_address != address(0) ? agency_address : $nft_marketplace_agency;
    }

    /**
    * @dev Public Functionalities
    */


    //
    //  Setup NFT selling by transfer the NFT to an agency for holding it and set quotations for it.
    //
    function sellNFT(
        address agency_address,
        address erc721_address,
        uint256 serial_no,
        NFT_Quote[] memory quotes,
        string memory note
    )
        public
    {
        require(quotes.length > 0, "[E:0000]"); // Must include at least a quotation for selling
        
        // Send NFT from a message sender to the registry for holding
        Interface_NFT_MARKETPLACE_AGENCY(agencySelector(agency_address)).depositERC721(erc721_address, serial_no, msg.sender, note);
        
        for (uint i; i < quotes.length; i++) {
            NFT_Quote memory quote = quotes[i];
            $quoteNFT[erc721_address][serial_no][quote.currency_address] = quote.amount;
        }
    }


    function cancelSellNFT(
        address agency_address,
        address erc721_address,
        uint256 serial_no,
        string memory note
    )
        public
    {
        // Send NFT from holding by the agency back to its owner.
        Interface_NFT_MARKETPLACE_AGENCY(agencySelector(agency_address)).withdrawERC721(erc721_address, serial_no, note);
    }
   
  
    function getSellNFTQuote(
        address erc721_address,
        uint256 serial_no,
        address currency_address
    )
        public
        view
        returns (uint256)
    {
        return $quoteNFT[erc721_address][serial_no][currency_address];
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