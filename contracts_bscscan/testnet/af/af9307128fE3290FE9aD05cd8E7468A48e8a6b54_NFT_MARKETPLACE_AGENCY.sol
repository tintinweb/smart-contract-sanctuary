// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./lib_core.sol";
import "./lib_utils.sol";
import "./IERC721Receiver.sol";
import "./Interface_NFT_Marketplace_Agency.sol";

contract NFT_MARKETPLACE_AGENCY is Ownable, IERC721Receiver, Interface_NFT_MARKETPLACE_AGENCY {
    // Version 0.5
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
    // $priceNFT[nft_address][serial_no][erc20_address] => NFT_Price
    mapping(address => mapping(uint256 => mapping(address => NFT_Price))) private $price_NFT;
    // $priceNFT[nft_address][serial_no] => currency_address[]
    mapping(address => mapping(uint256 => address[])) private $price_NFT_currencies;


    //
    // Sell type for each NFT
    // Map for store a sell type for each ERC721 token.
    // $sell_type[nft_address][serial_no] => sell_type
    mapping(address => mapping(uint256 => string)) private $sell_type;


    //
    // Quote for each NFT
    // Map for store a quote by a committer for each ERC721 token.
    // Use committer addres first to provide a way to do withdraw all feature.
    
    // $quote[committer_address][nft_address][serial_no] => quote
    mapping(address => mapping(address => mapping(uint256 => NFT_Price))) private $quote;

    // $quote_note[committer_address][nft_address][serial_no] => quote_note
    mapping(address => mapping(address => mapping(uint256 => string))) private $quote_note;

    // $latest_quote[nft_address][serial_no] => latest_quote
    mapping(address => mapping(uint256 => NFT_Price)) private $latest_quote;


        
    //
    // Map for store total amount of ERC20 of a single address.
    // 
    // $erc20_total[erc20_address][erc20_owner] => amount
    mapping(address => mapping(address => uint256)) private $erc20_total;
    

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
            $price_NFT[erc721_address][serial_no][price.currency_address] = price;
            $price_NFT_currencies[erc721_address][serial_no].push(price.currency_address);
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
        returns (NFT_Price memory)
    {
        return $price_NFT[erc721_address][serial_no][currency_address];
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

        address[] memory currencies = $price_NFT_currencies[erc721_address][serial_no];
        for (uint i; i < currencies.length; i++) {
            address currency_address = currencies[i];
            delete $price_NFT[erc721_address][serial_no][currency_address];
            delete $price_NFT_currencies[erc721_address][serial_no][i];
        }
    }
    
    
    //
    //  Set sell type for an NFT token.
    //
    function setSellType(
        address erc721_address,
        uint256 serial_no,
        string memory sell_type
    )
        override
        public
    {
        require($permitted_operator[msg.sender],"[E:0001,setSellType]");
        if (UTILITY.compareStrings(sell_type, "")) {
            delete $sell_type[erc721_address][serial_no];
        } else {
            $sell_type[erc721_address][serial_no] = sell_type;
        }
    }

    
    //
    //  Get sell type for an NFT token.
    //
    function getSellType(
        address erc721_address,
        uint256 serial_no
    )
        override
        view
        public
        returns (string memory)
    {
        return $sell_type[erc721_address][serial_no];
    }


    //
    //
    //
    function getQuote(address erc721_address, uint256 serial_no, address committer)
        override
        view
        public
        returns (NFT_Price memory)
    {
        return $quote[committer][erc721_address][serial_no];
    }


    //
    //
    //
    function getQuoteNote(address erc721_address, uint256 serial_no, address committer)
        override
        view
        public
        returns (string memory)
    {
        return $quote_note[committer][erc721_address][serial_no];
    }


    //
    //
    //
    function getLatestQuote(address erc721_address, uint256 serial_no)
        override
        view
        public
        returns (NFT_Price memory)
    {
       return $latest_quote[erc721_address][serial_no];
    }


    //
    //
    //
    function commitQuote(
        address erc721_address,
        uint256 serial_no,
        address committer,
        NFT_Price memory quote,
        string memory note
    )
        override
        public
    {
        require($permitted_operator[msg.sender],"[E:0001,commitQuote]");

        $quote[committer][erc721_address][serial_no] = quote;

        $quote_note[committer][erc721_address][serial_no] = note;

        $latest_quote[erc721_address][serial_no] = quote;

    }


    //
    // Deposit an ERC20 compatible token by intent amount.
    //
    //
    function depositERC20(
        address erc20_address,
        uint256 amount,
        address erc20_owner
    )
        override
        public
    {
        require($permitted_operator[msg.sender],"[E:0001,depositERC20]");
        
        IERC20(erc20_address).transferFrom(erc20_owner, address(this), amount);

        // Add new deposit amount to total deposit amount of sender by each ERC20 token.
        uint256 _new_amount = $erc20_total[erc20_address][erc20_owner] + amount;
        $erc20_total[erc20_address][erc20_owner] = _new_amount;
        
        // Set approval for new ammount so it can be withdrawn later.
        IERC20(erc20_address).approve(address(this), _new_amount);
    }


    //
    // Withdraw an ERC20 compatible token by intent amount.
    //
    function withdrawERC20(
        address erc20_address,
        uint256 amount,
        address erc20_owner
    ) 
        override
        public
    {
        require($permitted_operator[msg.sender],"[E:0001,commitQuote]");

        require($erc20_total[erc20_address][erc20_owner] >= amount, "E:[0001,withdrawERC20]");

        IERC20(erc20_address).transferFrom(address(this), erc20_owner, amount);
        
        // Subtract total deposit amount of sender by withdraw amount for each ERC20 token.
        uint256 _new_amount = $erc20_total[erc20_address][erc20_owner] - amount;
        $erc20_total[erc20_address][erc20_owner] = _new_amount;
        
        // Update approval for the new ammount.
        IERC20(erc20_address).approve(address(this), _new_amount);
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