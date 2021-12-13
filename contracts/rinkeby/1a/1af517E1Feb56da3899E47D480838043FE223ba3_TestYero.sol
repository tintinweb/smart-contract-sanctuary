pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

/**
 *
 *  ;.  ;.                           
 *  ; | ; |          ||          .-.  
 *  `.| `.| ....     ||  .---.  _|_ \ 
 *  |   | `=.`''===.' '.___.' (_)  
 *
 * The following algorithm is amazing, and I would like to thank Matt Hall and John Watkinson for their astounding work
 * The algorithm have been made for Autoglyphs and have been changed by dsi for Yero
 *
 * MODIFICATIONS
 * Split the contract into multiple part like MainContract, ERC721 and ERC721Receiver.
 * Add a dynamic variable `block.number` inside the `draw` function to make it more dynamic
 * Split the `draw` function into two functions with `getSymbol` and add a struct to avoid Error: Stack Too Deep.
 * Doesn't execute the `draw` function on minting and instead save the seed and the block.number to execute it on a view function (`tokenURI`)
 * Add `saveTokenURI` to save block.number into an array linked to the tokenId
 * Add `setTokenIdDefaultIndex` to change the default returned URI from the `tokenURI` function
 * Add `viewCurrentTokenURI` to view the tokenURI at the current block
 * Add `viewSpecificTokenURI` to view already saved tokenURI
 *
 *
 * FUNCTIONNING
 * The output of the 'tokenURI' function is a set of instructions to make a drawing.
 * Each symbol in the output corresponds to a cell, and there are 64x64 cells arranged in a square grid.
 * The drawing can be any size, and the pen's stroke width should be between 1/5th to 1/10th the size of a cell.
 * The drawing instructions for the nine different symbols are as follows:
 *
 *   .  Draw nothing in the cell.
 *   O  Draw a circle bounded by the cell.
 *   +  Draw centered lines vertically and horizontally the length of the cell.
 *   X  Draw diagonal lines connecting opposite corners of the cell.
 *   |  Draw a centered vertical line the length of the cell.
 *   -  Draw a centered horizontal line the length of the cell.
 *   \  Draw a line connecting the top left corner of the cell to the bottom right corner.
 *   /  Draw a line connecting the bottom left corner of teh cell to the top right corner.
 *   #  Fill in the cell completely.
 *
 */

import { ERC721 } from "./ERC721.sol";

contract TestYero is ERC721 {

    bool public isMintingAllowed;

    uint public constant TOKEN_LIMIT = 512; // 8 for testing, 256 or 512 for prod;
    uint public constant CYBERDAO_LIMIT = 15;

    uint public constant FIRST_PRICE = 60606000000000000 wei; // 0.060606 ether
    uint public constant SECOND_PRICE = 90909000000000000 wei; // 0.090909 ether
    uint public constant THIRD_PRICE = 101010100000000000 wei; // 0.1010101 ether
    uint public constant FOURTH_PRICE = 121212100000000000 wei; // 0.1212121 ether
    uint public constant FIFTH_PRICE = 131313130000000000 wei; // 0.1313131 ether

    // The beneficiary is 350.org
    address public constant BENEFICIARY = 0x0800b5479E4E47E7caeD7c5e9B74Ec44d3F0606a;

    string internal constant TABLE_ENCODE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    mapping (uint => address) private idToCreator;
    mapping (uint => uint8) private idToSymbolScheme;

    /**
     * @dev A mapping from NFT ID to the seed used to make it.
     */
    mapping (uint256 => uint256) internal idToSeed;
    mapping (uint256 => uint256) internal seedToId;
    mapping (uint256 => bool) internal isGenesis;

    mapping (uint256 => uint256) public tokenIdDefaultIndex;
    mapping (uint256 => uint256[]) public blockNumberSaved;

    mapping (string => bool) private passwords;

    function getPasswords(string _password) public view returns(bool) {
        return passwords[_password];
    }
    mapping (string => bool) internal isPassFound;

    address public owner;

    constructor() public {
        owner = msg.sender;
        isMintingAllowed = false;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Sender is not the Owner");
        _;
    }

    modifier mintingAllowed() {
        require(isMintingAllowed, "Minting not allowed");
        _;
    }

    ///////////////////
    //// GENERATOR ////
    ///////////////////

    int constant ONE = int(0x100000000);
    uint constant USIZE = 64;
    int constant SIZE = int(USIZE);
    int constant HALF_SIZE = SIZE / int(2);

    int constant SCALE = int(0x1b81a81ab1a81a823);
    int constant HALF_SCALE = SCALE / int(2);

    bytes prefix = "data:text/plain;charset=utf-8,";

    // 0x2E = .
    // 0x4F = O
    // 0x2B = +
    // 0x58 = X
    // 0x7C = |
    // 0x2D = -
    // 0x5C = \
    // 0x2F = /
    // 0x23 = #

    function abs(int n) internal pure returns (int) {
        if (n >= 0) return n;
        return -n;
    }

    function getScheme(uint a) internal pure returns (uint8) {
        uint index = a % 83;
        uint8 scheme;
        if (index < 20) {
            scheme = 1;
        } else if (index < 35) {
            scheme = 2;
        } else if (index < 48) {
            scheme = 3;
        } else if (index < 59) {
            scheme = 4;
        } else if (index < 68) {
            scheme = 5;
        } else if (index < 73) {
            scheme = 6;
        } else if (index < 77) {
            scheme = 7;
        } else if (index < 80) {
            scheme = 8;
        } else if (index < 82) {
            scheme = 9;
        } else {
            scheme = 10;
        }
        return scheme;
    }

    /* * ** *** ***** ******** ************* ******** ***** *** ** * */

    // The following code generates art.

    struct DrawingValues {

        uint value;
        uint mod;
        bytes5 symbols;
    }

    function draw(uint _id, uint _seed, uint _blockNumber) internal view returns (string) {
        uint a = uint(uint160(keccak256(abi.encodePacked(_seed, _blockNumber))));
        bytes memory output = new bytes(USIZE * (USIZE + 3) + 30);
        uint c;
        for (c = 0; c < 30; c++) {
            output[c] = prefix[c];
        }

        DrawingValues memory drawingValues;

        int x = 0;
        int y = 0;
        uint v = 0;
        drawingValues.value = 0;
        drawingValues.mod = (a % 11) + 5;
        drawingValues.symbols = getSymbol(_id);

        for (int i = int(0); i < SIZE; i++) {
            y = (2 * (i - HALF_SIZE) + 1);
            if (a % 3 == 1) {
                y = -y;
            } else if (a % 3 == 2) {
                y = abs(y);
            }
            y = y * int(a);
            for (int j = int(0); j < SIZE; j++) {
                x = (2 * (j - HALF_SIZE) + 1);
                if (a % 2 == 1) {
                    x = abs(x);
                }
                x = x * int(a);
                v = uint(x * y / ONE) % drawingValues.mod;
                if (v < 5) {
                    drawingValues.value = uint(drawingValues.symbols[v]);
                } else {
                    drawingValues.value = 0x2E;
                }
                output[c] = byte(bytes32(drawingValues.value << 248));
                c++;
            }
            output[c] = byte(0x25);
            c++;
            output[c] = byte(0x30);
            c++;
            output[c] = byte(0x41);
            c++;
        }
        string memory result = string(output);
        return result;
    }

    function getSymbol(uint id) public view returns (bytes5) {
        bytes5 symbols;
        uint8 symbolScheme = idToSymbolScheme[id];

        if (symbolScheme == 0) {
            revert();
        } else if (symbolScheme == 1) {
            symbols = 0x2E582F5C2E; // X/\
        } else if (symbolScheme == 2) {
            symbols = 0x2E2B2D7C2E; // +-|
        } else if (symbolScheme == 3) {
            symbols = 0x2E2F5C2E2E; // /\
        } else if (symbolScheme == 4) {
            symbols = 0x2E5C7C2D2F; // \|-/
        } else if (symbolScheme == 5) {
            symbols = 0x2E4F7C2D2E; // O|-
        } else if (symbolScheme == 6) {
            symbols = 0x2E5C5C2E2E; // \
        } else if (symbolScheme == 7) {
            symbols = 0x2E237C2D2B; // #|-+
        } else if (symbolScheme == 8) {
            symbols = 0x2E4F4F2E2E; // OO
        } else if (symbolScheme == 9) {
            symbols = 0x2E232E2E2E; // #
        } else {
            symbols = 0x2E234F2E2E; // #O
        }

        return symbols;
    }

    /* * ** *** ***** ******** ************* ******** ***** *** ** * */

    function creator(uint _id) external view returns (address) {
        return idToCreator[_id];
    }

    function symbolScheme(uint _id) external view returns (uint8) {
        return idToSymbolScheme[_id];
    }

    function createGlyph(uint seed, string _password) external payable mintingAllowed returns (uint256) {
        require(numTokens < TOKEN_LIMIT, "All token Minted");
        if(numTokens < 30) {
            require(msg.value >= FIRST_PRICE, "Payement too low");
        } else if(numTokens < 80) {
            require(msg.value >= SECOND_PRICE, "Payement too low");
        } else if(numTokens < 432) {
            require(msg.value >= THIRD_PRICE, "Payement too low");
        } else if(numTokens < 482) {
            require(msg.value >= FOURTH_PRICE, "Payement too low");
        } else if(numTokens <= 512) {
            require(msg.value >= FIFTH_PRICE, "Payement too low");
        }
        return _mint(msg.sender, seed, _password);
    }

    /**
     * @dev Mints a new NFT.
     * @notice This is an internal function which should be called from user-implemented external
     * mint function. Its purpose is to show and properly initialize data structures when using this
     * implementation.
     * @param _to The address that will own the minted NFT.
     */
    function _mint(address _to, uint seed, string memory _password) internal returns (uint256) {
        require(_to != address(0));
        require(seedToId[seed] == 0, "Token already minted");
        uint id = numTokens + 1;

        idToCreator[id] = _to;
        idToSeed[id] = seed;
        seedToId[seed] = id;
        if(verifyPassword(_password)) {
            isGenesis[id] = true;
        }
        uint a = uint(uint160(keccak256(abi.encodePacked(seed))));
        idToSymbolScheme[id] = getScheme(a);
        blockNumberSaved[id].push(block.number);
        tokenIdDefaultIndex[id] = 0;
        emit Generated(id, _to, block.number);

        numTokens = numTokens + 1;
        _addNFToken(_to, id);

        BENEFICIARY.transfer(msg.value);

        emit Transfer(address(0), _to, id);
        return block.number;
    }

    /**
     * @dev A distinct URI (RFC 3986) for a given NFT.
     * @param _tokenId Id for which we want uri.
     * @return URI of _tokenId.
     */
    function tokenURI(uint256 _tokenId) external view validNFToken(_tokenId) returns (string memory) {
        uint256 _defaultIndex = tokenIdDefaultIndex[_tokenId]; 
        uint256 _defaultBlockNumber = blockNumberSaved[_tokenId][_defaultIndex];
        uint256 _seed = idToSeed[_tokenId];
        string memory imageURI = draw(_tokenId, _seed, _defaultBlockNumber);
        string memory genesis = isGenesis[_tokenId] ? "true" : "false";
        string memory json = encode(bytes(abi.encodePacked(
            '{"name": "Yero", ', 
            '"description": "Dynamic Generative Art",', 
            '"attributes": [{',
            '"isGenesis": "',
            genesis,
            '"}], "image": "',
            imageURI,
            '"}'
        )));
        string memory data = string(abi.encodePacked("data:application/json;base64,", json));
        return data;
    }

    /**
     * @dev Save the block.number inside an array.
     * @param _tokenId Id for which we want uri.
     */
    function saveTokenURI(uint256 _tokenId) external validNFToken(_tokenId) {
        require(idToCreator[_tokenId] == msg.sender, "Only owner can call");
        blockNumberSaved[_tokenId].push(block.number);
    }

    /**
     * @dev Set the default index for the tokenURI.
     * @param _tokenId Id for which we want uri.
     * @param _defaultIndex Index of block.number used to build the tokenURI to set as default.
     */
    function setTokenIdDefaultIndex(uint256 _tokenId, uint256 _defaultIndex) external validNFToken(_tokenId) {
        require(idToCreator[_tokenId] == msg.sender, "Only owner can call");

        tokenIdDefaultIndex[_tokenId] = _defaultIndex;
    }

    /**
     * @dev View the current tokenURI for a given tokenId at the current block.
     * @param _tokenId Id for which we want the current uri.
     * @return URI of _tokenId.
     */
    function viewCurrentTokenURI(uint256 _tokenId) external view validNFToken(_tokenId) returns (string memory) {
        uint256 _seed = idToSeed[_tokenId];
        return(draw(_tokenId, _seed, block.number));
    }

    /**
     * @dev View a specific, already saved tokenURI.
     * @param _tokenId Id for which we want uri.
     * @param _index Index for which we want to see the tokenURI.
     * @return URI of _tokenId.
     */
    function viewSpecificTokenURI(uint256 _tokenId, uint256 _index) external view returns (string memory) {
        uint256 _seed = idToSeed[_tokenId];
        return(draw(_tokenId, _seed, blockNumberSaved[_tokenId][_index]));
    }

    function totalBlockNumberSaved(uint256 _tokenId) external view returns(uint256) {
        return(blockNumberSaved[_tokenId].length);
    }

    function setPasswords(string[] memory _passwords) public onlyOwner {
        for(uint i = 0; i < _passwords.length; i++) {
            passwords[_passwords[i]] = true;
        }
    }

    function verifyPassword(string memory _password) public returns(bool) {
        if(passwords[_password] && !isPassFound[_password]) {
            isPassFound[_password] = true;
            return true;
        }
        return false;
    }

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return "";

        // load the table into memory
        string memory table = TABLE_ENCODE;

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((data.length + 2) / 3);

        // add some extra buffer at the end required for the writing
        string memory result = new string(encodedLen + 32);

        assembly {
            // set the actual output length
            mstore(result, encodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 3 bytes at a time
            for {} lt(dataPtr, endPtr) {}
            {
                // read 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // write 4 characters
                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(shr( 6, input), 0x3F))))
                resultPtr := add(resultPtr, 1)
                mstore8(resultPtr, mload(add(tablePtr, and(        input,  0x3F))))
                resultPtr := add(resultPtr, 1)
            }

            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }

        return result;
    }

    function setIsMintingAllowed(bool _isMintingAllowed) public onlyOwner {
        isMintingAllowed = _isMintingAllowed;
    }

}

// SPDX-Licenser-Identifier: MIT
pragma solidity ^0.4.24;

import "./interfaces/ERC721TokenReceiver.sol";

contract ERC721 {
    
    event Generated(uint indexed index, address indexed a, uint256 value);

    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(address indexed _from, address indexed _to, uint256 indexed _tokenId);

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(address indexed _owner, address indexed _approved, uint256 indexed _tokenId);

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(address indexed _owner, address indexed _operator, bool _approved);

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    /**
     * @dev Mapping from owner address to mapping of operator addresses.
     */
    mapping (address => mapping (address => bool)) internal ownerToOperators;

    /**
     * @dev Mapping from NFT ID to approved address.
     */
    mapping (uint256 => address) internal idToApproval;

    /**
     * @dev A mapping from NFT ID to the address that owns it.
     */
    mapping (uint256 => address) internal idToOwner;

    /**
     * @dev Mapping from NFT ID to its index in the owner tokens list.
     */
    mapping(uint256 => uint256) internal idToOwnerIndex;

    /**
     * @dev Mapping from owner to list of owned NFT IDs.
     */
    mapping(address => uint256[]) internal ownerToIds;

    // ERC 165
    mapping(bytes4 => bool) internal supportedInterfaces;

    /**
     * @dev Total number of tokens.
     */
    uint internal numTokens = 0;

    string internal nftName = "Yero";
    string internal nftSymbol = "ᵹ";

    /**
     * @dev Contract constructor.
     */
    constructor() public {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721 Metadata
    }

        /**
     * @dev Guarantees that the msg.sender is an owner or operator of the given NFT.
     * @param _tokenId ID of the NFT to validate.
     */
    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender]);
        _;
    }

    /**
     * @dev Guarantees that the msg.sender is allowed to transfer NFT.
     * @param _tokenId ID of the NFT to transfer.
     */
    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender
            || idToApproval[_tokenId] == msg.sender
            || ownerToOperators[tokenOwner][msg.sender]
        );
        _;
    }

    /**
     * @dev Guarantees that _tokenId is a valid Token.
     * @param _tokenId ID of the NFT to validate.
     */
    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0), "Query for non-existant token");
        _;
    }

    /**
     * @dev Checks if `_operator` is an approved operator for `_owner`.
     * @param _owner The address that owns the NFTs.
     * @param _operator The address that acts on behalf of the owner.
     * @return True if approved for all, false otherwise.
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return ownerToOperators[_owner][_operator];
    }

    /**
     * @dev Enables or disables approval for a third party ("operator") to manage all of
     * `msg.sender`'s assets. It also emits the ApprovalForAll event.
     * @notice This works even if sender doesn't own any tokens at the time.
     * @param _operator Address to add to the set of authorized operators.
     * @param _approved True if the operators is approved, false to revoke approval.
     */
    function setApprovalForAll(address _operator, bool _approved) external {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }
    
      //////////////////////////
     //// ERC 721 and 165  ////
    //////////////////////////

    /**
     * @dev Function to check which interfaces are suported by this contract.
     * @param _interfaceID Id of the interface.
     * @return True if _interfaceID is supported, false otherwise.
     */
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return supportedInterfaces[_interfaceID];
    }

    /**
     * @dev Returns whether the target address is a contract.
     * @param _addr Address to check.
     * @return True if _addr is a contract, false if not.
     */
    function isContract(address _addr) internal view returns (bool addressCheck) {
        uint256 size;
        assembly { size := extcodesize(_addr) } // solhint-disable-line
        addressCheck = size > 0;
    }

    /**
     * @dev Transfers the ownership of an NFT from one address to another address. This function can
     * be changed to payable.
     * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
     * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
     * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
     * function checks if `_to` is a smart contract (code size > 0). If so, it calls
     * `onERC721Received` on `_to` and throws if the return value is not
     * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The NFT to transfer.
     * @param _data Additional data with no specified format, sent in call to `_to`.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes _data) external {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    /**
     * @dev Transfers the ownership of an NFT from one address to another address. This function can
     * be changed to payable.
     * @notice This works identically to the other function with an extra data parameter, except this
     * function just sets data to ""
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The NFT to transfer.
     */
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external {
        _safeTransferFrom(_from, _to, _tokenId, "");
    }

    /**
     * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
     * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
     * address. Throws if `_tokenId` is not a valid NFT. This function can be changed to payable.
     * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
     * they maybe be permanently lost.
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The NFT to transfer.
     */
    function transferFrom(address _from, address _to, uint256 _tokenId) external canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from);
        require(_to != address(0));
        _transfer(_to, _tokenId);
    }

    /**
     * @dev Set or reaffirm the approved address for an NFT. This function can be changed to payable.
     * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
     * the current NFT owner, or an authorized operator of the current owner.
     * @param _approved Address to be approved for the given NFT ID.
     * @param _tokenId ID of the token to be approved.
     */
    function approve(address _approved, uint256 _tokenId) external canOperate(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner);
        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

        /**
     * @dev Actually perform the safeTransferFrom.
     * @param _from The current owner of the NFT.
     * @param _to The new owner.
     * @param _tokenId The NFT to transfer.
     * @param _data Additional data with no specified format, sent in call to `_to`.
     */
    function _safeTransferFrom(address _from,  address _to,  uint256 _tokenId,  bytes memory _data) private canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from);
        require(_to != address(0));

        _transfer(_to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    /**
     * @dev Actually preforms the transfer.
     * @notice Does NO checks.
     * @param _to Address of a new owner.
     * @param _tokenId The NFT that is being transferred.
     */
    function _transfer(address _to, uint256 _tokenId) internal {
        address from = idToOwner[_tokenId];
        _clearApproval(_tokenId);

        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
    }

    /**
     * @dev Assigns a new NFT to an address.
     * @notice Use and override this function with caution. Wrong usage can have serious consequences.
     * @param _to Address to which we want to add the NFT.
     * @param _tokenId Which NFT we want to add.
     */
    function _addNFToken(address _to, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == address(0));
        idToOwner[_tokenId] = _to;

        uint256 length = ownerToIds[_to].push(_tokenId);
        idToOwnerIndex[_tokenId] = length - 1;
    }

    /**
     * @dev Removes a NFT from an address.
     * @notice Use and override this function with caution. Wrong usage can have serious consequences.
     * @param _from Address from wich we want to remove the NFT.
     * @param _tokenId Which NFT we want to remove.
     */
    function _removeNFToken(address _from, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == _from);
        delete idToOwner[_tokenId];

        uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
        uint256 lastTokenIndex = ownerToIds[_from].length - 1;

        if (lastTokenIndex != tokenToRemoveIndex) {
            uint256 lastToken = ownerToIds[_from][lastTokenIndex];
            ownerToIds[_from][tokenToRemoveIndex] = lastToken;
            idToOwnerIndex[lastToken] = tokenToRemoveIndex;
        }

        ownerToIds[_from].length--;
    }
    
    /**
     * @dev Clears the current approval of a given NFT ID.
     * @param _tokenId ID of the NFT to be transferred.
     */
    function _clearApproval(uint256 _tokenId) private {
        if (idToApproval[_tokenId] != address(0)) {
            delete idToApproval[_tokenId];
        }
    }

    /**
     * @dev Get the approved address for a single NFT.
     * @notice Throws if `_tokenId` is not a valid NFT.
     * @param _tokenId ID of the NFT to query the approval of.
     * @return Address that _tokenId is approved for.
     */
    function getApproved(uint256 _tokenId) external view validNFToken(_tokenId) returns (address) {
        return idToApproval[_tokenId];
    }

        /**
     * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
     * extension to remove double storage (gas optimization) of owner nft count.
     * @param _owner Address for whom to query the count.
     * @return Number of _owner NFTs.
     */
    function _getOwnerNFTCount(address _owner) internal view returns (uint256) {
        return ownerToIds[_owner].length;
    }

    //// Enumerable

    function totalSupply() public view returns (uint256) {
        return numTokens;
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < numTokens);
        return index;
    }

    /**
     * @dev returns the n-th NFT ID from a list of owner's tokens.
     * @param _owner Token owner's address.
     * @param _index Index number representing n-th token in owner's list of tokens.
     * @return Token id.
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        require(_index < ownerToIds[_owner].length);
        return ownerToIds[_owner][_index];
    }

        /**
     * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
     * considered invalid, and this function throws for queries about the zero address.
     * @param _owner Address for whom to query the balance.
     * @return Balance of _owner.
     */
    function balanceOf(address _owner) external view returns (uint256) {
        require(_owner != address(0));
        return _getOwnerNFTCount(_owner);
    }

    /**
     * @dev Returns the address of the owner of the NFT. NFTs assigned to zero address are considered
     * invalid, and queries about them do throw.
     * @param _tokenId The identifier for an NFT.
     * @return Address of _tokenId owner.
     */
    function ownerOf(uint256 _tokenId) external view returns (address _owner) {
        _owner = idToOwner[_tokenId];
        require(_owner != address(0));
    }
    
    //// Metadata

    /**
      * @dev Returns a descriptive name for a collection of NFTokens.
      * @return Representing name.
      */
    function name() external view returns (string memory _name) {
        _name = nftName;
    }

    /**
     * @dev Returns an abbreviated name for NFTokens.
     * @return Representing symbol.
     */
    function symbol() external view returns (string memory _symbol) {
        _symbol = nftSymbol;
    }
}

pragma solidity ^0.4.24;

interface ERC721TokenReceiver
{

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);

}