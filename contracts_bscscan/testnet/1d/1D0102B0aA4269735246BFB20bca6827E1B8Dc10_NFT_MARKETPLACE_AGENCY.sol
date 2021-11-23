// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./lib_core.sol";
import "./IERC721Receiver.sol";
import "./Interface_NFT_Marketplace_Agency.sol";

contract NFT_MARKETPLACE_AGENCY is Ownable, IERC721Receiver, Interface_NFT_MARKETPLACE_AGENCY {
    // Version 0.2.2
    using SafeMath for uint256;

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
    // Map for store permitted operator (e.g. another contract that can call upon this contract).
    // 
    mapping(address => bool) private $permitted_operator;
    
    //
    // Map for store ERC721. Use ERC-721 and Serial No (Token ID) to find who is its owner.
    // 
    mapping(address => mapping(uint256 => address)) private $erc721_owner;
    
    //
    // Prices for each NFT
    // Map for store prices for each ERC721 token by an ERC20 token.
    // $priceNFT[nft_address][serial_no][erc20_address] => amount
    mapping(address => mapping(uint256 => mapping(address => uint256))) private $priceNFT;
    // $priceNFT[nft_address][serial_no] => currency_address[]
    mapping(address => mapping(uint256 => address[])) private $priceNFTCurrencies;


    /**
    * @dev Event Emitters
    */

    //
    // Event for NFT Marketplace Agent transactions
    //
    event TRANSFER (
        string indexed operation,
        address indexed erc721_address,
        uint256 serial_no,
        uint256 timestamp,
        string note
    );


    /**
    * @dev Constructor
    */

    // Simply setup contract owner and payee to deployer address
    constructor(
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
    
    /**
    * @dev Public Functionalities
    */
    
    //
    // Activate Marketplace Operator
    // Add or activate/deactivate it.
    //
    function activateOperator(
        address operator_address
    )
        public
        onlyOwner
    {
       if ($permitted_operator[operator_address]) {
            $permitted_operator[operator_address] = !$permitted_operator[operator_address];
       } else {
            $permitted_operator[operator_address] = true;
       }
    }

    //
    // Deposit NFT from
    //  and mark status for the slot.
    //
    function depositERC721(
        address erc721_address,
        uint256 serial_no,
        address erc721_owner_address,
        string memory note
    )
        override
        public
    {
        require($permitted_operator[msg.sender],"[E:0001,depositERC721]");

        uint256 timestamp = block.timestamp;

        // Send NFT from a permitted operator to this agency for holding it.
        IERC721(erc721_address).safeTransferFrom(erc721_owner_address, address(this), serial_no, "");

        // Store owner address to 
        $erc721_owner[erc721_address][serial_no] = erc721_owner_address;

        emit TRANSFER("deposit", erc721_address, serial_no, timestamp, note);

    }
    
    //
    // Withdraw NFT from
    //  and mark status for the slot.
    //
    
    function withdrawERC721(
        address erc721_address,
        uint256 serial_no,
        string memory note
    )
        override
        public
    {
        require($permitted_operator[msg.sender] || (msg.sender == $erc721_owner[erc721_address][serial_no]), "[E:0001,withdrawERC721]");

        uint256 timestamp = block.timestamp;
        address _erc721_owner_address = $erc721_owner[erc721_address][serial_no];

        IERC721(erc721_address).safeTransferFrom(address(this), _erc721_owner_address, serial_no, "");

        emit TRANSFER("withdraw", erc721_address, serial_no, timestamp, note);
    }
    
    //
    // Transfer NFT out
    //  and mark status for the slot.
    //
    function sendERC721(
        address erc721_address,
        uint256 serial_no,
        address recipient_address,
        string memory note
    )
        override
        public
    {
        require(msg.sender == $erc721_owner[erc721_address][serial_no],"[E:0001,sendERC721]");
        
        uint256 timestamp = block.timestamp;
        
        IERC721(erc721_address).safeTransferFrom(address(this), recipient_address, serial_no, "");
        
        emit TRANSFER("send", erc721_address, serial_no, timestamp, note);
    }


    //
    //  Set prices for an NFT token.
    //
    function setNFTPrices(
        address erc721_address,
        uint256 serial_no,
        address erc721_owner_address,
        NFT_Price[] memory prices
    )
        override
        public
    {
        require($permitted_operator[msg.sender],"[E:0001,setNFTPrices]");
        
        if ($erc721_owner[erc721_address][serial_no] != address(0)) {
            require($erc721_owner[erc721_address][serial_no] == erc721_owner_address, "[E:0002,setNFTPrices]");
        }

        for (uint i; i < prices.length; i++) {
            NFT_Price memory price = prices[i];
            $priceNFT[erc721_address][serial_no][price.currency_address] = price.amount;
            $priceNFTCurrencies[erc721_address][serial_no].push(price.currency_address);
        }
    }


    //
    //  Get a single price for a NFT token.
    //
    function getNFTPrice(
        address erc721_address,
        uint256 serial_no,
        address currency_address
    )
        override
        public
        view
        returns (uint256)
    {
        return $priceNFT[erc721_address][serial_no][currency_address];
    }

    //
    //  Clear all prices of a NFT token.
    //
    function clearNFTPrices(
        address erc721_address,
        uint256 serial_no,
        address erc721_owner_address
    )
        override
        public
    {        
        require($permitted_operator[msg.sender],"[E:0001,clearNFTPrices]");
        if ($erc721_owner[erc721_address][serial_no] != address(0)) {
            require($erc721_owner[erc721_address][serial_no] == erc721_owner_address, "[E:0002,clearNFTPrices]");
        }

        address[] memory currencies = $priceNFTCurrencies[erc721_address][serial_no];
        for (uint i; i < currencies.length; i++) {
            address currency_address = currencies[i];
            delete $priceNFT[erc721_address][serial_no][currency_address];
            delete $priceNFTCurrencies[erc721_address][serial_no][i];
        }
    }
    
    /**
    * @dev Error Codes
    *
    * E:[0000] Undefined error.
    *
    *
    */
}


// Created by Jimmy IsraKhan <[email protected]>
// Latest update: 2021-11-22