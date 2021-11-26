// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./lib_core.sol";
import "./lib_utils.sol";
import "./Interface_NFT_Marketplace_Agency.sol";

contract NFT_MARKETPLACE_OPERATOR is Ownable {
    // Version 0.12.2
    using SafeMath for uint256;
    Interface_NFT_MARKETPLACE_AGENCY NFT_Marketplace_Agency;


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
    // Contract activeness status.
    //
    bool public $active = true;

    //
    // Default Marketplace Agency contract address. -- Use for hold NFT
    //
    
    address public $nft_marketplace_agency;

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
        string memory sell_type,
        Interface_NFT_MARKETPLACE_AGENCY.NFT_Price[] memory prices,
        string memory note
    )
        public
    {
        require(prices.length > 0, "[E:0000]"); // Must include at least a quotation for selling
        
        // Clear all previous prices of an NFT
        Interface_NFT_MARKETPLACE_AGENCY(agencySelector(agency_address)).clearNFTPrices(erc721_address, serial_no, msg.sender);
        
        // Set Prices for an NFT
        Interface_NFT_MARKETPLACE_AGENCY(agencySelector(agency_address)).setNFTPrices(erc721_address, serial_no, msg.sender, prices);
        
        // Set Sell type for an NFT
        Interface_NFT_MARKETPLACE_AGENCY(agencySelector(agency_address)).setSellType(erc721_address, serial_no, sell_type);

        // Send NFT from a message sender to the registry for holding
        Interface_NFT_MARKETPLACE_AGENCY(agencySelector(agency_address)).depositERC721(erc721_address, serial_no, msg.sender, note);
        
    }


    //
    //
    //
    function cancelSellNFT(
        address agency_address,
        address erc721_address,
        uint256 serial_no,
        string memory note
    )
        public
    {
        Interface_NFT_MARKETPLACE_AGENCY _NFT_Marketplace_Agency = Interface_NFT_MARKETPLACE_AGENCY(agencySelector(agency_address));

        // Check that the caller is the NFT owner.
        address _nft_owner = _NFT_Marketplace_Agency.getNFTOwner(erc721_address, serial_no);
        require(_nft_owner == msg.sender, "[E:0001,cancelSellNFT");

        // Check that a sell type is that's nmatch a logic or not.
        string memory _sell_type = _NFT_Marketplace_Agency.getSellType(erc721_address, serial_no);
        require(UTILITY.compareStrings("", _sell_type) != true, "[E:0002,cancelSellNFT");

        // Match a sell cancellation logic with sell type.
        if (UTILITY.compareStrings("auction", _sell_type)) {
            auctionSellCancel(agency_address, erc721_address, serial_no, note);
        }

    }

    

    //
    // Closing a sell of a NFT.
    //
    function closeSellNFT(
        address agency_address,
        address erc721_address,
        uint256 serial_no,
        string memory note
    )
        public
    {
        Interface_NFT_MARKETPLACE_AGENCY _NFT_Marketplace_Agency = Interface_NFT_MARKETPLACE_AGENCY(agencySelector(agency_address));

        // Check that the caller is the NFT owner.
        address _nft_owner = _NFT_Marketplace_Agency.getNFTOwner(erc721_address, serial_no);
        require(_nft_owner == msg.sender, "[E:0001,closeSellNFT");

        // Check that a sell type is that's nmatch a logic or not.
        string memory _sell_type = _NFT_Marketplace_Agency.getSellType(erc721_address, serial_no);
        require(UTILITY.compareStrings("", _sell_type) != true, "[E:0002,closeSellNFT");

        // Match a sell cancellation logic with sell type.
        if (UTILITY.compareStrings("auction", _sell_type)) {
            auctionSellCompletion(agency_address, erc721_address, serial_no, note);
        }

    }



    //
    //
    //
    function buyNFT(
        address agency_address,
        address erc721_address,
        uint256 serial_no,
        string memory sell_type,
        Interface_NFT_MARKETPLACE_AGENCY.NFT_Price memory quote,
        string memory note
    )
        public
    {
        Interface_NFT_MARKETPLACE_AGENCY _NFT_Marketplace_Agency = Interface_NFT_MARKETPLACE_AGENCY(agencySelector(agency_address));
        string memory _sell_type = _NFT_Marketplace_Agency.getSellType(erc721_address, serial_no);
        
        Interface_NFT_MARKETPLACE_AGENCY.NFT_Price memory _price = _NFT_Marketplace_Agency.getNFTPrice(erc721_address, serial_no, quote.currency_address);
        
        // Check that buyer must not be the owner of the NFT.
        require(_price.committer != msg.sender, "[E:0001, buyNFT]");

        // Check that the target NFT is on selling
        require(UTILITY.compareStrings(sell_type, "") != true, "[E:0002,buyNFT]");
        
        // Check that whether sell type of a buy request match the sell type of the target NFT.
        require(UTILITY.compareStrings(sell_type, _sell_type), "[E:0003,buyNFT]");
        
        // Matching the buy request with a sell logic.
        if (UTILITY.compareStrings("auction", _sell_type)) {
            auctionBiddingLogic(agency_address, erc721_address, serial_no, quote, note);
        }
    }
 

 


    /**
    * @dev Business Logical Functions
    */




    //
    //  
    //
    function auctionSellCompletion(
        address agency_address,
        address erc721_address,
        uint256 serial_no,
        string memory note
    )
        internal
    {
        Interface_NFT_MARKETPLACE_AGENCY _NFT_Marketplace_Agency = Interface_NFT_MARKETPLACE_AGENCY(agencySelector(agency_address));

        Interface_NFT_MARKETPLACE_AGENCY.NFT_Price memory _latest_quote = _NFT_Marketplace_Agency.getLatestQuote(erc721_address, serial_no);
    
        // Transfer money to the NFT's owner.
        _NFT_Marketplace_Agency.sendERC20ToNFTowner(erc721_address, serial_no, _latest_quote.currency_address, _latest_quote.committer, _latest_quote.amount);

        // Transfer the NFT to the latest bidder (the winner).
        _NFT_Marketplace_Agency.sendERC721(erc721_address, serial_no, _latest_quote.committer, "");
                
        Interface_NFT_MARKETPLACE_AGENCY.NFT_Price memory _blank_quote = Interface_NFT_MARKETPLACE_AGENCY.NFT_Price({
            symbol: _latest_quote.symbol,
            currency_address: _latest_quote.currency_address,
            amount: 0,
            committer: msg.sender,
            timestamp: block.timestamp
        });

        // Commit the bidding, reserve the quote amount by transfer to an agency.
        _NFT_Marketplace_Agency.commitQuote(erc721_address, serial_no, msg.sender, _blank_quote, note);

        // Set Auction history

        // Clean up all sell data.
        clearNFTSell(agency_address, erc721_address, serial_no);
    }


    //
    //  
    //
    function auctionSellCancel(
        address agency_address,
        address erc721_address,
        uint256 serial_no,
        string memory note
    )
        internal
    {
        Interface_NFT_MARKETPLACE_AGENCY _NFT_Marketplace_Agency = Interface_NFT_MARKETPLACE_AGENCY(agencySelector(agency_address));

        Interface_NFT_MARKETPLACE_AGENCY.NFT_Price memory _latest_quote = _NFT_Marketplace_Agency.getLatestQuote(erc721_address, serial_no);
        
        // This is for preventing cancel an started auction session.
        require(_latest_quote.amount == 0, "[E:0001,auctionSellCancel]");

        address _owner = _NFT_Marketplace_Agency.getNFTOwner(erc721_address, serial_no);

        require(msg.sender == _owner, "[E:0002,auctionSellCancel]");

        // Transfer the NFT back to seller.
        _NFT_Marketplace_Agency.sendERC721(erc721_address, serial_no, msg.sender, "");

        clearNFTSell(agency_address, erc721_address, serial_no);
    }

    //
    //  
    //
    function auctionBiddingLogic(
        address agency_address,
        address erc721_address,
        uint256 serial_no,
        Interface_NFT_MARKETPLACE_AGENCY.NFT_Price memory quote,
        string memory note
    )
        internal
    {
        Interface_NFT_MARKETPLACE_AGENCY _NFT_Marketplace_Agency = Interface_NFT_MARKETPLACE_AGENCY(agencySelector(agency_address));

        // Get the latest quote for the target NFT.
        Interface_NFT_MARKETPLACE_AGENCY.NFT_Price memory _latest_quote = _NFT_Marketplace_Agency.getLatestQuote(erc721_address, serial_no);

        // Quote amount must more than the initial price and the latest bid.
        
        // Get the price of the target NFT.
        // Check for the valid price of a quote currency. It must be the same as the price currency.
        Interface_NFT_MARKETPLACE_AGENCY.NFT_Price memory _price = _NFT_Marketplace_Agency.getNFTPrice(erc721_address, serial_no, quote.currency_address);

        // Committer must not be the NFT owner..
        require(address(_price.committer) != address(msg.sender), "[E:0001,auctionBiddingLogic]");
        
        // Committer must not be the same as of the latest bid.
        require(address(_latest_quote.committer) != address(msg.sender), "[E:0002,auctionBiddingLogic]");
        
        // Price of the target NFT must more than 0.
        require(_price.amount > 0, "[E:0003,auctionBiddingLogic]");
        
        // Price of the quote must greater than the price of the NFT and the latest bid.
        require(quote.amount > _price.amount && quote.amount > _latest_quote.amount, "[E:0004,auctionBiddingLogic]");
        
        // Commit the bidding, reserve the quote amount by transfer to an agency.
        _NFT_Marketplace_Agency.commitQuote(erc721_address, serial_no, msg.sender, quote, note);
         
        // Deposit the bid amount to the agency contract
        _NFT_Marketplace_Agency.depositERC20(quote.currency_address, quote.amount, msg.sender);
    
        // Withdraw the latest bid amount and return back to the latest bidder.
        if (address(_latest_quote.committer) != address(0)) {
            _NFT_Marketplace_Agency.withdrawERC20(_latest_quote.currency_address, _latest_quote.amount, address(_latest_quote.committer));
        }
    }
 

    //
    //
    //
    function clearNFTSell(
        address agency_address,
        address erc721_address,
        uint256 serial_no
    )
        internal
    {
        Interface_NFT_MARKETPLACE_AGENCY _NFT_Marketplace_Agency = Interface_NFT_MARKETPLACE_AGENCY(agencySelector(agency_address));

        // Clear all previous prices of an NFT
        _NFT_Marketplace_Agency.clearNFTPrices(erc721_address, serial_no, msg.sender);

        // Remove sell type of an NFT
        _NFT_Marketplace_Agency.setSellType(erc721_address, serial_no, "");

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