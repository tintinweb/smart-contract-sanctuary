// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./lib_core.sol";
// import "./Interface_NFT_Registry.sol";
// import "./NFT_MARKETPLACE_REGISTRY.sol";

contract NFT_MARKETPLACE_OPERATOR__V0_1 is Ownable {
    using SafeMath for uint256;

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
    // Wallet address to receive transfer in of all ERC20.
    //
    // address private $payee;
    
    //
    //  NFT Registry address to work with.
    //
    address private $native;
    
    
    address public $nft_registry;


    /**
    * @dev Event Emitters
    */

    //
    // Event for NFT Swap transaction
    //
    event NFT_SELL(
        address indexed buyer,
        address indexed erc721_address,
        uint256 serial_no,
        address indexed erc20_address,
        uint256 amount,
        uint256 timestamp
    );
    
    event NFT_BUY(
    
    );


    /**
    * @dev Constructor
    */

    // Simply setup contract owner and payee to deployer address
    constructor(
        // address nft_registry,
        // address wrap_native_address
    ) {
        $owner = msg.sender;
        // $native = wrap_native_address;
        // $nft_registry = nft_registry;
        // NFTregistry = NFT_Registry(nft_registry);
    }

    /**
    * @dev Public Functionalities
    */

    //
    // Swap registered ERC20 token with an available ERC721 token slot 
    //  and mark status for the slot.
    //
    function sellNFT(
        address erc721_address,
        uint256 serial_no
        // address erc20_address,
        // uint256 amount,
        // string memory remark,
        // string memory meta
    )
        public
    {
        
    // Send NFT from a message sender to the registry for holding
    // TODO Change addres(this) to agency contract -- Using agency to decouple from operator as it should not hold any state.
      IERC721(erc721_address).safeTransferFrom(msg.sender, address(this), serial_no, "");
    
    // Set required papameters to the registry.
    
    // Emit the event
    // emit NFT_SELL()
        
    
    //   I_NFT_Registry.ERC721Token memory _ERC721_Token = NFTregistry.getERC721token(erc721_address);
    //   I_NFT_Registry.SlotState memory _slot = NFTregistry.getNFTslotState(erc721_address, serial_no);
    //   uint256 _exchange_rate_default = NFTregistry.getExchangeRateForNFTcollection(erc721_address, erc20_address);
    //   uint256 _exchange_rate_specific = NFTregistry.getExchangeRateForSpecificNFT(erc721_address, serial_no, erc20_address);
      
    //   uint256 _exchange_rate = _exchange_rate_default;
    //   if (_exchange_rate_specific > 0) {
    //       _exchange_rate = _exchange_rate_specific;
    //   }

    //   // Checking for supported ERC20 tokens.
    //   require(_ERC721_Token.active, "E:[X001]");

    //   // Checking for ERC20 amount and it must be matched with the specified exchange rate.
    //   require(_exchange_rate <= amount, "E:[EX01]");
      
    //   // Checking for available NFT Slot in an ERC721 token
    //   require(!_slot.exists, "E:[EX02]");

    //   address _payee = $payee;
    //   if (_ERC721_Token.payee != address(0)) {
    //       _payee = _ERC721_Token.payee;
    //   }

    //   // Transfer ERC20 token to the payee address
    //   require(IERC20(erc20_address).transferFrom(msg.sender, _payee, _exchange_rate), "E:[TK21]");

    //   // Transfer ERC721 token to message sender address.

    //   // Set status for the token slot
    //   NFTregistry.setNFTslotState(
    //     erc721_address, // ERC721 address
    //     serial_no, // Serial No.
    //     "CLAIMED", // Status
    //     remark, // Remarks
    //     meta // Meta
    //   );

    //   emit NFTswap(msg.sender, erc721_address, serial_no, erc20_address, _exchange_rate, block.timestamp);
    }
    
    function cancelSellNFT(
        address erc721_address,
        uint256 serial_no
    )
        public
    {
        IERC721(erc721_address).safeTransferFrom(address(this), msg.sender, serial_no, "");
    }
    
    // function setAuctionSell (
    //     uint256 tokenId,
    //     uint256 starttime,
    //     uint256 endTime,
    //     uint256 price,
    //     address quoteTokenAddress
    // ) 
    //     external override
    //     inState(SellingState.PENDING, tokenId)
    //     whenNotPaused
    // { 
    //     setAuctionSellTo(
    //         tokenId,
    //         starttime,
    //         endTime,
    //         price,
    //         quoteTokenAddress,
    //         address(_msgSender())
    //     );
    // }
    // //** โดนเรียกมา
    // function setAuctionSellTo (
    //     uint256 tokenId,
    //     uint256 startTime,
    //     uint256 endTime,
    //     uint256 price,
    //     address quoteTokenAddress,
    //     address to
    // )
    //     public
    //     whenNotPaused
    //     onlySupportTokens(quoteTokenAddress)
    //     {

    //     require(
    //         _msgSender() == NFT.ownerOf(tokenId),
    //         "0::Only Token Owner can sell token"
    //     );
    //     require(price != 0, "0::Price must be greater than zero");
    //     require(startTime > now, "0::Start time should be setted to present and so on");
    //     require(endTime > startTime, "endtime need to > starttime");

    //     $asksMap.set(tokenId, price);
    //     $sellingType[tokenId] = SellingState.AUCTION;
    //     $startTimeMap.set(tokenId, startTime);
    //     $endTimeMap.set(tokenId, endTime);
    //     $asksQuoteTokens[tokenId] = quoteTokenAddress;
    //     $tokenSellers[tokenId] = to;
    //     $userSellingTokens[to].add(tokenId);

    //     NFT.safeTransferFrom(address(_msgSender()), address(this), tokenId);

    //     emit Ask(to, tokenId, price, quoteTokenAddress, startTime);

    //     HISTORY.setAuctionHistory(
    //         address(this),
    //         tokenId, 
    //         _msgSender(),
    //         startTime,
    //         endTime,
    //         price,
    //         quoteTokenAddress
    //     );

    // }
    
    
    // function swapNFTbyNative(
    //     address erc721_address,
    //     uint256 serial_no,
    //     string memory remark,
    //     string memory meta
    // )
    //     public
    //     payable
    // {
    //   I_NFT_Registry.ERC721Token memory _ERC721_Token = NFTregistry.getERC721token(erc721_address);
    //   I_NFT_Registry.SlotState memory _slot = NFTregistry.getNFTslotState(erc721_address, serial_no);
    //   uint256 _exchange_rate_default = NFTregistry.getExchangeRateForNFTcollection(erc721_address, $native);
    //   uint256 _exchange_rate_specific = NFTregistry.getExchangeRateForSpecificNFT(erc721_address, serial_no, $native);
      
    //   uint256 _exchange_rate = _exchange_rate_default;
      
    //   if (_exchange_rate_specific > 0) {
    //       _exchange_rate = _exchange_rate_specific;
    //   }

    //   // Checking for supported ERC20 tokens.
    //   require(_ERC721_Token.active, "E:[X001]");

    //   // Checking for ERC20 amount and it must be matched with the specified exchange rate.
    //   require(_exchange_rate <= msg.value, "E:[EX01]");
      
    //   // Checking for available NFT Slot in an ERC721 token
    //   require(!_slot.exists, "E:[EX02]");

    //   address _payee = $payee;
    //   if (_ERC721_Token.payee != address(0)) {
    //       _payee = _ERC721_Token.payee;
    //   }

    //   // Transfer ERC20 token to the payee address
    //   safeTransferNative(_payee, _exchange_rate);
    
    //   // Transfer ERC721 token to message sender address.
    //   IERC721(erc721_address).safeTransferFrom(_ERC721_Token.owner, msg.sender, serial_no, "");

    //   // Set status for the token slot
    //   NFTregistry.setNFTslotState(
    //     erc721_address, // ERC721 address
    //     serial_no, // Serial No.
    //     "CLAIMED", // Status
    //     remark, // Remarks
    //     meta // Meta
    //   );

    //   emit NFTswap(msg.sender, erc721_address, serial_no, address(0), _exchange_rate, block.timestamp);
    // }


    // /**
    // * @dev Contract Setup and Administrations
    // */
    
    // //
    // // Change Contract Owner Address
    // //
    // function changeOwner(
    //     address new_address
    // ) public onlyOwner {
    //     require(new_address != $owner && new_address != address(0), "E:[PM02]");
    //     $owner = new_address;
    //     transferOwnership($owner);
    // }
    
    // //
    // // Change NFT registry.
    // //
    // function changeRegistry(
    //     address contract_address
    // ) public onlyOwner {
    //     $nft_registry = contract_address;
    //     NFTregistry = NFT_Registry(contract_address);
    // }


    // /**
    // * @dev Internal Utilities
    // */
    
    // //
    // // Safely transfer native currency.
    // //
    // function safeTransferNative(address recipient, uint256 value) internal {
    //     (bool success, ) = recipient.call{ value: value }(new bytes(0));
    //     require(success, "E:[CH01]");
    // }

    // //
    // // Simply compare two strings.
    // //
    // function _compareStrings(string memory a, string memory b)
    //     internal
    //     pure
    //     returns (bool)
    // {
    //     return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    // }


    /**
    * @dev Error Codes
    *
    * E:[0000] Undefined error.
    *
    * E:[PM02] New owner address must not be the same as the current one.
    *
    * E:[CH01] Native currency transfer failed.
    * 
    * E:[TK20] ERC20 token was not active or registered.
    *
    * E:[TK21] ERC20 transfer was failed.
    *
    * E:[EX01] ERC721 amount was less than the required exchange rate.
    *
    * E:[EX02] ERC721 token slot was being reserved or already claimed.
    *
    *
    */
}


// Created by Jimmy IsraKhan <[email protected]>
// Latest update: 2021-10-01