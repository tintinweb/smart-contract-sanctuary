// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Library.sol";
import "./Interface_NFT_Registry.sol";
import "./NFT_Registry.sol";

contract NFT_Swap__V0_1 is Ownable {
    using SafeMath for uint256;


    /**
    * @dev Structs
    */
    
    NFT_Registry public $NFT_Registry;

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
    address private $payee;
    
    //
    //  NFT Registry address to work with.
    //
    address private $nft_registry;


    // TOBEREMOVE
    // Map for store slot of reserved, used, claimed slot of ERC721 tokens
    //  it's a double map which use contract address of a NFT to access the store
    //  and use serial number (uint256) to access the token slot.
    // 
    // mapping(address => mapping(uint256 => I_NFT_Registry.SlotState)) public $NFTslots;


    /**
    * @dev Event Emitters
    */

    //
    // Event for NFT Swap transaction
    //
    event NFTswap(
        address indexed buyer,
        address indexed erc721_address,
        uint256 serial_no,
        address indexed erc20_address,
        uint256 amount,
        uint256 timestamp
    );


    /**
    * @dev Constructor
    */

    // Simply setup contract owner and payee to deployer address
    constructor(
        address nft_registry    
    ) {
        $owner = msg.sender;
        $payee = msg.sender;
        $nft_registry = nft_registry;
        $NFT_Registry = NFT_Registry($nft_registry);
    }


    /**
    * @dev Public Functionalities
    */

    //
    // Swap registered ERC20 token with an available ERC721 token slot 
    //  and mark status for the slot.
    //
    function swapNFT(
        address erc20_address,
        uint256 amount,
        address erc721_address,
        uint256 serial_no,
        string memory remark,
        string memory meta
    )
        public
    {
      I_NFT_Registry.ERC721Token memory _ERC721_Token = $NFT_Registry.getERC721token(erc721_address);
      I_NFT_Registry.SlotState memory _slot = $NFT_Registry.getNFTslotState(erc721_address, serial_no);
      uint256 _exchange_rate_default = $NFT_Registry.getExchangeRate(erc721_address, erc20_address);
      uint256 _exchange_rate_specific = $NFT_Registry.getExchangeRateForSingleNFT(erc721_address, serial_no, erc20_address);
      
      uint256 _exchange_rate = _exchange_rate_default;
      if (_exchange_rate_specific > 0) {
          _exchange_rate = _exchange_rate_specific;
      }

      // Checking for supported ERC20 tokens.
      require(_ERC721_Token.active, "E:[X001]");

      // Checking for ERC20 amount and it must be matched with the specified exchange rate.
      require(_exchange_rate >= amount, "E:[EX01]");
      
      // Checking for available NFT Slot in an ERC721 token
      require(!_slot.exists, "E:[EX02]");

      // Transfer ERC20 token to the payee address
      require(IERC20(erc20_address).transferFrom(msg.sender, $payee, amount), "E:[TK21]");

      // Transfer ERC721 token to message sender address.
      IERC721(erc721_address).safeTransferFrom(_ERC721_Token.owner, msg.sender, serial_no, "");

      // Set status for the token slot
      $NFT_Registry.setNFTslotState(
        erc721_address, // ERC721 address
        serial_no, // Serial No.
        "CLAIMED", // Status
        remark, // Remarks
        meta // Meta
      );

      emit NFTswap(msg.sender, erc721_address, serial_no, erc20_address, amount, block.timestamp);
    }


    /**
    * @dev Contract Setup and Administrations
    */
    
    //
    // Change Contract Owner Address
    //
    function changeOwner(
        address new_address
    ) public onlyOwner {
        require(new_address != $owner && new_address != address(0), "E:[PM02]");
        $owner = new_address;
        transferOwnership($owner);
    }


    /**
    * @dev Internal Utilities
    */

    //
    // Simply compare two strings.
    //
    function _compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }


    /**
    * @dev Error Codes
    *
    * E:[0000] Undefined error.
    *
    * E:[PM02] New owner address must not be the same as the current one.
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
// Latest update: 2021-09-25