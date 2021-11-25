// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./lib_core.sol";
import "./lib_utils.sol";
import "./IERC721Receiver.sol";
import "./Interface_NFT_Marketplace_Agency.sol";

contract NFT_MARKETPLACE_AGENCY is Ownable, IERC721Receiver, Interface_NFT_MARKETPLACE_AGENCY {
    // Version 0.7.1
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

    // $top_quote[nft_address][serial_no] => top_quote
    mapping(address => mapping(uint256 => NFT_Price)) private $top_quote;


        
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

        // Clear record of the NFT's owner.
        clearNFTOwner(erc721_address, serial_no);

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
        //
        require($permitted_operator[msg.sender], "[E:0001,sendERC721]");
        
        //
        uint256 timestamp = block.timestamp;
        
        //
        IERC721(erc721_address).safeTransferFrom(address(this), recipient_address, serial_no, "");

        // Clear record of the NFT's owner.
        clearNFTOwner(erc721_address, serial_no);
        
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
    // Get current owner of an NFT.
    //
    function getNFTOwner(
        address erc721_address,
        uint256 serial_no
    )
        override
        view
        public
        returns (address)
    {
       return $erc721_owner[erc721_address][serial_no];
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
    function getTopQuote(address erc721_address, uint256 serial_no)
        override
        view
        public
        returns (NFT_Price memory)
    {
       return $top_quote[erc721_address][serial_no];
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

        // Conditionally set top quote. This is use for security reason to limit the attack due to the sendERC20 function.
        if ($top_quote[erc721_address][serial_no].amount < quote.amount) {
            $top_quote[erc721_address][serial_no] = quote;
        }

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

        // Increase deposit amount to total deposit amount of sender by each ERC20 token.
        increaseERC20Record(erc20_address, amount, erc20_owner);
    }


    //
    //
    //
    function getDepositAmountERC20(
        address erc20_address,
        address erc20_owner
    )
        override
        view
        public
        returns (uint256)
    {
        return $erc20_total[erc20_address][erc20_owner];
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
        require($permitted_operator[msg.sender],"[E:0001,withdrawERC20]");

        uint256 _total_save_amount = getDepositAmountERC20(erc20_address, erc20_owner);

        require(_total_save_amount >= amount, "E:[0002,withdrawERC20]");

        // For a security reason then it will allowance to transfer only the amount of the withdraw request.
        IERC20(erc20_address).approve(address(this), amount);

        // Transfer the request ERC20 token back to the owner.
        IERC20(erc20_address).transferFrom(address(this), erc20_owner, amount);
        
        // Subtract total deposit amount of sender by withdraw amount for each ERC20 token.
        decreaseERC20Record(erc20_address, amount, erc20_owner);
        
        // Set allowance back to 0.
        IERC20(erc20_address).approve(address(this), 0);

    }



    //
    // Send ERC20 compatible token to the owner of the NFT.
    //
    function sendERC20ToNFTowner(
        address erc721_address,
        uint256 serial_no,
        address erc20_address,
        address erc20_payer_address,
        uint256 amount
    ) 
        override
        public
    {
        require($permitted_operator[msg.sender],"[E:0001,sendERC20ToNFTowner]");

        //
        uint256 _max_amount = getDepositAmountERC20(erc20_address, erc20_payer_address);

        //
        require(amount <= _max_amount,"[E:0001,sendERC20ToNFTowner]");

        //
        decreaseERC20Record(erc20_address, amount, erc20_payer_address);
        
        //
        address _owner = getNFTOwner(erc721_address, serial_no);

        //
        sendERC20(erc20_address, amount, _owner);
    }


    
    //
    // Transfer an ERC20 compatible token by intent amount to a receipient.
    //
    function sendERC20(
        address erc20_address,
        uint256 amount,
        address recipient_address
    ) 
        internal
    {
        require($permitted_operator[msg.sender],"[E:0001,sendERC20]");

        // For a security reason then it will allowance to transfer only the amount of the withdraw request.
        IERC20(erc20_address).approve(address(this), amount);
        
        // Transfer the request ERC20 token back to recipient.
        IERC20(erc20_address).transferFrom(address(this), recipient_address, amount);
        
        // Set allowance back to 0.
        IERC20(erc20_address).approve(address(this), 0);

    }



    //
    // Increase amount of deposit record of an ERC20 compatible token by intent amount.
    //
    function increaseERC20Record(
        address erc20_address,
        uint256 amount,
        address erc20_owner
    )
        internal
    {
        require($permitted_operator[msg.sender],"[E:0001,increaseERC20Record]");
        
        uint256 _new_amount = $erc20_total[erc20_address][erc20_owner] + amount;
        $erc20_total[erc20_address][erc20_owner] = _new_amount;
    }



    //
    // Decrease amount of deposit record of an ERC20 compatible token by intent amount.
    //
    function decreaseERC20Record(
        address erc20_address,
        uint256 amount,
        address erc20_owner
    )
        internal
    {
        require($permitted_operator[msg.sender],"[E:0001,decreaseERC20Record]");
        
        uint256 _new_amount = $erc20_total[erc20_address][erc20_owner] - amount;
        $erc20_total[erc20_address][erc20_owner] = _new_amount;
    }



    //
    // Clear NFT owner record after sell, transfer or withdraw, to make it available to resell again.
    //
    function clearNFTOwner(
        address erc721_address,
        uint256 serial_no
    )
        internal
    {
        require($permitted_operator[msg.sender],"[E:0001,decreaseERC20Record]");

        delete $erc721_owner[erc721_address][serial_no];
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