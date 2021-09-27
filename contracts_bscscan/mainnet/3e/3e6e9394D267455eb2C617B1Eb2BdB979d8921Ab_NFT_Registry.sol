// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./Library.sol";
import "./Interface_NFT_Registry.sol";


contract NFT_Registry is Ownable, I_NFT_Registry {
    using SafeMath for uint256;


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
    // Map for store registry of accept ERC20 tokens which contain setting and its meta data.
    //
    mapping(address => ERC20Token) public $ERC20Tokens;

    //
    // Map for store registry of NFTs (ERC721 tokens) which contain setting and its meta data.
    //
    mapping(address => ERC721Token) public $ERC721Tokens;
    
    //
    // Map for store specific owner of a specific NFT.
    //  it's use a specific NFT collection address and serial no of the NFT to get owner address
    //
    mapping(address => mapping(uint256 => address)) private $ERC721TokenOwner;

    //
    // Map for store exchange rate of an ERC20 token for each ERC721 collection. 
    //
    mapping(address => mapping(address => uint256)) public $exchangeRateDefault;

    //
    // Map for store exchange rate of an ERC20 token for each ERC721 token. 
    //
    mapping(address => mapping(uint256 => mapping(address => uint256))) public $exchangeRateNFT;
    
    //
    // Map for store default exchange rate of each ERC20 token.
    //
    mapping(address => uint256) public $defaultExchangeRate;

    //
    // Map for store slot of reserved, used, claimed slot of ERC721 tokens
    //  it's a double map which use contract address of a NFT to access the store
    //  and use serial number (uint256) to access the token slot.
    // 
    mapping(address => NFTSlots) $NFTslots;
    

    /**
    * @dev Event Emitters
    */

    //
    // Event for NFT slot update
    //
    event SlotUpdate(
        address indexed erc721_address,
        uint256 serial_no,
        string status,
        uint256 timestamp
    );



    /**
    * @dev Constructor
    */

    // Simply setup contract owner and payee to deployer address
    constructor() {
        $owner = msg.sender;
    }


    /**
    * @dev Public Functionalities
    */

    function getERC721token(
        address erc721_address    
    )
        public
        view
        override
        returns (ERC721Token memory)
    {
        return $ERC721Tokens[erc721_address];
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
    * @dev NFT (ERC721 Tokens) Functionalities
    */

    //
    // Change Owner Address for a registered ERC721.
    //
    function changeERC721Owner(
        address erc721_address,
        address new_address
    ) public {
        require(
          ($ERC721Tokens[erc721_address].owner != new_address && new_address != address(0))
          || msg.sender == $owner
        , "E:[PM02]");
        $ERC721Tokens[erc721_address].owner = new_address;
    }

    //
    // Change Payee Address for a registered ERC721.
    //
    function changeERC721Payee(
        address erc721_address,
        address new_address
    ) public {
        require($ERC721Tokens[erc721_address].owner == msg.sender, "E:[PM01]");
        require($ERC721Tokens[erc721_address].payee != new_address && new_address != address(0), "E:[PM03]");
        $ERC721Tokens[erc721_address].payee = new_address;
    }

    //
    // Get details of a registered ERC721 token.
    //
    // function getERC721token(
    //     address erc721_address
    // )
    //     public
    //     view 
    //     returns (ERC721Token memory)
    // {
    //     return $ERC721Tokens[erc721_address];
    // }

    //
    // Register an ERC721 token to be usable with this contract.
    //
    function registerERC721token(
        address erc721_address,
        string memory name,
        uint256 max_supply,
        address erc20_address,
        address erc721_owner_address,
        address erc721_payee_address,
        uint256 rate
    )
        public
        onlyOwner
    {
        $ERC721Tokens[erc721_address].contract_address = erc721_address;
        $ERC721Tokens[erc721_address].name = name;
        $ERC721Tokens[erc721_address].max_supply = max_supply;
        $ERC721Tokens[erc721_address].owner = erc721_owner_address;
        
        if (erc721_payee_address != address(0)) {
            $ERC721Tokens[erc721_address].payee = erc721_payee_address;
        } else {
            $ERC721Tokens[erc721_address].payee = erc721_owner_address;
        }
        $ERC721Tokens[erc721_address].active = true;
        if (rate > 0) {
            $exchangeRateDefault[erc721_address][erc20_address] = rate;
        } else {
            $exchangeRateDefault[erc721_address][erc20_address] = $defaultExchangeRate[erc20_address];
        }
    }

    //
    // Switch current state of a registered ERC721 token (Activate <> Deactive).
    //
    function activateERC721token(
        address erc721_address
    )
        public
    {
        //
        require($ERC721Tokens[erc721_address].owner == msg.sender, "E:[PM01]");
        $ERC721Tokens[erc721_address].active = !$ERC721Tokens[erc721_address].active;
    }

    //
    // Set max supply for ERC721 (Can be changed only once).
    //
    function setNFTmaxSupply(
        address erc721_address,
        uint256 max_supply
    )
        public
    {
        //
        require($ERC721Tokens[erc721_address].owner == msg.sender, "E:[PM01]");
        require($ERC721Tokens[erc721_address].max_supply == 0, "E:[TK11]");
        $ERC721Tokens[erc721_address].max_supply = max_supply;
    }

    //
    // Set max supply for ERC721 (can be changed only once).
    //
    function overrideNFTmaxSupply(
        address erc721_address,
        uint256 max_supply
    )
        public
    {
        require($ERC721Tokens[erc721_address].owner == msg.sender, "E:[PM01]");
        $ERC721Tokens[erc721_address].max_supply_history.push($ERC721Tokens[erc721_address].max_supply);
        $ERC721Tokens[erc721_address].max_supply = max_supply;
    }

    //
    // Bulk setup reservation states for each NFT. 
    //
    function setNFTreserveList(
        address erc721_address,
        uint256[] memory reserve_list
    )
        public
    {
        //
        require($ERC721Tokens[erc721_address].max_supply > 0, "E:[TK12]");
        require($ERC721Tokens[erc721_address].owner == msg.sender, "E:[PM01]");
        
        for (uint8 i = 0; i < reserve_list.length; i++) {
            uint256 _serial_no = reserve_list[i];
            if (!$NFTslots[erc721_address].slot[_serial_no].exists && _serial_no <= $ERC721Tokens[erc721_address].max_supply) {
                $NFTslots[erc721_address].slot[_serial_no].status = "RSV";
                $NFTslots[erc721_address].slot[_serial_no].exists = true;
                $NFTslots[erc721_address].slot[_serial_no].serial_no = _serial_no;
            }
        }
    }

    //
    // Bulk remove reserved NFT slot.
    //
    function removeNFTreserveList(
        address erc721_address,
        uint256[] memory reserve_list
    ) public {
        //
        require($ERC721Tokens[erc721_address].owner == msg.sender, "E:[PM01]");

        //
        for (uint8 i = 0; i < reserve_list.length; i++) {
            uint256 _serial_no = reserve_list[i];
            if (_compareStrings($NFTslots[erc721_address].slot[_serial_no].status , "RSV")) {
                delete $NFTslots[erc721_address].slot[_serial_no];
            }
        }
    }

    // 
    // Get detail of an NFT slot
    //
    function getNFTslotState(
        address erc721_address,
        uint256 serial_no
    )
        override
        public
        view
        returns (SlotState memory)
    {
        return $NFTslots[erc721_address].slot[serial_no];
    }
    
    // 
    // Set detail for an NFT slot
    //
    function setNFTslotState(
        address erc721_address,
        uint256 serial_no,
        string memory status,
        string memory remark,
        string memory meta
    )
        override
        public
        returns (SlotState memory)
    {
        
        require(msg.sender == $owner, "E:[PM01]");
        SlotState memory _slot = $NFTslots[erc721_address].slot[serial_no];

        require(!_slot.exists, "E:[0000]");
        _slot.status = status;
        _slot.exists = true;
        _slot.serial_no = serial_no;
        _slot.remark = remark;
        _slot.meta = meta;
        _slot.create_at = block.timestamp;
    
        emit SlotUpdate(erc721_address, serial_no, status, block.timestamp);

        return _slot;
    }

    //
    // Update detail for an NFT slot
    //
    function updateNFTslotState(
        address erc721_address,
        uint256 serial_no,
        string memory status,
        string memory remark,
        string memory meta
    )
        override
        public
        view
        returns (SlotState memory)
    {
        
        require(msg.sender == $ERC721Tokens[erc721_address].contract_address, "E:[0000]");
        SlotState memory _slot = $NFTslots[erc721_address].slot[serial_no];

        require(_slot.exists, "E:[0000]");
        _slot.status = status;
        _slot.remark = remark;
        _slot.meta = meta;
        _slot.update_at = block.timestamp;

        return _slot;
    }

    /**
    * @dev ERC20 Tokens (Quote Token) Functionalities
    */

    //
    // Get details of a registered ERC20 token.
    //
    function getERC20token(
        address erc20_address
    )
        public
        view 
        returns (ERC20Token memory)
    {
        return $ERC20Tokens[erc20_address];
    }

    //
    // Register an ERC20 token to be usable with this contract.
    //
    function registerERC20token(
        address erc20_address,
        string memory symbol
    )
        internal
    {
        $ERC20Tokens[erc20_address].contract_address = erc20_address;
        $ERC20Tokens[erc20_address].symbol = symbol;
        $ERC20Tokens[erc20_address].active = true;
    }

    //
    // Remove an ERC20 token from the registry.
    //
    function removeERC20token(
        address erc20_address
    )
        internal
        onlyOwner
    {
        delete $ERC721Tokens[erc20_address];
    }

    //
    // Change exchange rate for an ERC20 with an ERC721 NFT.
    //
    function changeExchangeRate(
        address erc721_address,
        address erc20_address,
        uint256 rate
    )
        internal
    {
        require($ERC721Tokens[erc721_address].active, "E:[TK10]");
        require($ERC20Tokens[erc20_address].active, "E:[TK20]");
        require($ERC721Tokens[erc721_address].owner == msg.sender, "E:[PM01]");
        $exchangeRateDefault[erc721_address][erc20_address] = rate;
    }
    
    //
    // Set exchange rate for a specific ERC20 token for a specific ERC721 NFT.
    //
    function changeExchangeRateForSingleNFT(
        address erc721_address,
        uint256 serial_no,
        address erc20_address,
        uint256 rate
    )
        override
        public
    {
        require($ERC721Tokens[erc721_address].active, "E:[TK10]");
        require($ERC20Tokens[erc20_address].active, "E:[TK20]");
        require(
            $ERC721TokenOwner[erc721_address][serial_no] == msg.sender
            || msg.sender == $owner
            , "E:[PM01]"
        );
        $exchangeRateNFT[erc721_address][serial_no][erc20_address] = rate;
    }
    
    //
    // Get exchange rate for a specific ERC20 token bind with a specific ERC721 collection.
    //
    function getExchangeRate(
        address erc721_address,
        address erc20_address
    )
        override
        public
        view
        returns (uint256)
    {
        return $exchangeRateDefault[erc721_address][erc20_address];
    }


    //
    // Get exchange rate for a specific ERC20 token bind with a specific ERC721 token.
    //
    function getExchangeRateForSingleNFT(
        address erc721_address,
        uint256 serial_no,
        address erc20_address
    )
        override
        public
        view
        returns (uint256)
    {
        return $exchangeRateNFT[erc721_address][serial_no][erc20_address];
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
    * E:[PM01] Caller must be the owner of the registered ERC721 token.
    *
    * E:[PM02] New owner address must not be the same as the current one.
    *
    * E:[PM03] New payee address must not be the same as the current one.
    *
    * E:[TK10] ERC721 token was not active or registered.
    *
    * E:[TK11] To set max supply of an NFT, it needed to be zero.
    *
    * E:[TK12] NFT max supply was not set.
    *
    * E:[TK20] ERC20 token was not active or registered.
    *
    */
}


// Created by Jimmy IsraKhan <[email protected]>
// Latest update: 2021-09-25