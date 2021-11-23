// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./lib_core.sol";
import "./IERC721Receiver.sol";
import "./Interface_NFT_Marketplace_Agency.sol";

contract NFT_MARKETPLACE_AGENCY is Ownable, IERC721Receiver, Interface_NFT_MARKETPLACE_AGENCY {
    // Version 0.1
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
    // Map for store permitted operator (e.g. another contract that can call upon this contract).
    // 
    mapping(address => bool) private $permitted_operator;
    
    //
    // Map for store ERC721. Use ERC-721 and Serial No (Token ID) to find who is the owner.
    // 
    mapping(address => mapping(uint256 => address)) private $erc721_owner;
    

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
        require($permitted_operator[msg.sender],"[0000]");

        uint256 timestamp = block.timestamp;

        // Send NFT from a permitted operator to this agency for holding it.
        IERC721(erc721_address).safeTransferFrom(msg.sender, address(this), serial_no, "");

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
        require($permitted_operator[msg.sender] || (msg.sender == $erc721_owner[erc721_address][serial_no]), "[0000]");

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
        require(msg.sender == $erc721_owner[erc721_address][serial_no],"[0000]");
        
        uint256 timestamp = block.timestamp;
        
        IERC721(erc721_address).safeTransferFrom(address(this), recipient_address, serial_no, "");
        
        emit TRANSFER("send", erc721_address, serial_no, timestamp, note);
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