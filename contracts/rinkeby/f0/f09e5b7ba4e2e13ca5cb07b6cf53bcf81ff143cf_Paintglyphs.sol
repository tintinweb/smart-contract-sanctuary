/**
 *Submitted for verification at Etherscan.io on 2021-08-07
*/

pragma solidity ^0.5.17;


interface ERC721TokenReceiver
{

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data) external returns(bytes4);

}

interface originalGlyphContract {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

contract Paintglyphs {

    event Generated(uint indexed index, address indexed a, string value);

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

    event ColorChanged(uint id, uint symbolToUpdate, uint newColor);
    
    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    uint public constant TOKEN_LIMIT = 512;
    uint public constant ARTIST_PRINTS = 0;

    uint public constant PRICE = 300 finney;

    address payable public constant BENEFICIARY = 0x8C9eEEcaeb226f1B8C1385abE0960754e08EC285;

    mapping (uint => address) private idToCreator;
    mapping (uint => uint8) private idToSymbolScheme;
    mapping (uint => uint256) private idToBackgroundColor;
    mapping (uint => uint256[8]) private idToColorScheme;
    mapping (uint => string) private processingCode;

    // ERC 165
    mapping(bytes4 => bool) internal supportedInterfaces;

    /**
     * @dev A mapping from NFT ID to the address that owns it.
     */
    mapping (uint256 => address) internal idToOwner;

    /**
     * @dev A mapping from NFT ID to the seed used to make it.
     */
    mapping (uint256 => uint256) internal idToSeed;
    mapping (uint256 => uint256) internal seedToId;

    /**
     * @dev Mapping from NFT ID to approved address.
     */
    mapping (uint256 => address) internal idToApproval;

    /**
     * @dev Mapping from owner address to mapping of operator addresses.
     */
    mapping (address => mapping (address => bool)) internal ownerToOperators;

    /**
     * @dev Mapping from owner to list of owned NFT IDs.
     */
    mapping(address => uint256[]) internal ownerToIds;

    /**
     * @dev Mapping from NFT ID to its index in the owner tokens list.
     */
    mapping(uint256 => uint256) internal idToOwnerIndex;

    /**
     * @dev Total number of tokens.
     */
    uint internal numTokens = 0;

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
        require(idToOwner[_tokenId] != address(0));
        _;
    }
    
        
    modifier isOwner() {
        require(msg.sender == owner, "Must be deployer of contract");
        _;
    }

    /**
     * @dev Contract constructor.
     */
    constructor() public {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721 Metadata
        glyphContract = originalGlyphContract(glyphContractAddress);
        owner = msg.sender;
        setURI("https://paintglyphs.azurewebsites.net/api/HttpTrigger?id=");
    }

    ///////////////////
    //// GENERATOR ////
    ///////////////////

    int constant ONE = int(0x100000000);
    uint constant USIZE = 32;
    int constant SIZE = int(USIZE);
    int constant HALF_SIZE = SIZE / int(2);
    address owner;
    string URI;

    int constant SCALE = int(0x1b81a81ab1a81a823);
    int constant HALF_SCALE = SCALE / int(2);

    bytes prefix = "data:text/plain;charset=utf-8,";

    string internal nftName = "Paintglyphs";
    string internal nftSymbol = "p☵";
    address public glyphContractAddress = 0xd4e4078ca3495DE5B1d4dB434BEbc5a986197782;
    string public allSymbols = "0 - ░; 1 - ▒; 2 - ■; 3 - ┼; 4 - ▓; 5 - ▄; 6 - ▀; 7 - ≡";
    
    originalGlyphContract glyphContract;

    function abs(int n) internal pure returns (int) {
        if (n >= 0) return n;
        return -n;
    }
    
    function ownerOfGlyph(uint256 glyphId) public view returns (address payable) {
        address payable currentGlyphOwner =  address(uint160(glyphContract.ownerOf(glyphId)));
        return currentGlyphOwner;
    }
    
    function getStartColor(uint a) internal pure returns (uint256) {
        uint256 xxxxff = a % 96;
        uint256 xxffxx = xxxxff*256;
        uint256 ffxxxx = xxffxx*256;
        uint256 randomColor = xxxxff + xxffxx + ffxxxx;
        return randomColor;
    }

    function getBackgroundColor(uint a) internal pure returns (uint256) {
        uint256 xxxxff = (a % 128) + 128;
        uint256 xxffxx = xxxxff*256;
        uint256 ffxxxx = xxffxx*256;
        uint256 randomColor = xxxxff + xxffxx + ffxxxx;
        return randomColor;
    }
    
    function getScheme(uint a) internal pure returns (uint8) {
        uint index = a % 100;
        uint8 scheme;
        if (index < 22) {
            scheme = 1;
        } else if (index < 41) {
            scheme = 2;
        } else if (index < 58) {
            scheme = 3;
        } else if (index < 72) {
            scheme = 4;
        } else if (index < 84) {
            scheme = 5;
        } else if (index < 93) {
            scheme = 6;
        }else {
            scheme = 7;
        }
        return scheme;
    }

    /* * ** *** ***** ******** ************* ******** ***** *** ** * */

    // The following code generates art.

    function draw(uint id) public view returns (string memory) {
        uint a = uint((keccak256(abi.encodePacked(idToSeed[id]))));
        bytes memory output = new bytes(USIZE * (USIZE + 3) + 30);
        uint c;
        for (c = 0; c < 30; c++) {
            output[c] = prefix[c];
        }
        int x = 0;
        int y = 0;
        uint v = 0;
        uint value = 0;
        uint mod = (a % 11) + 10;
        bytes10 symbols;
        if (idToSymbolScheme[id] == 0) {
            revert();
        } else if (idToSymbolScheme[id] == 1) {
            symbols = 0x3030302E2E2E2E2E2E2E; // ░
        } else if (idToSymbolScheme[id] == 2) { 
            symbols = 0x303130312E2E2E2E2E2E; // ░▒
        } else if (idToSymbolScheme[id] == 3) {
            symbols = 0x323332332E2E2E2E2E2E; // ■┼
        } else if (idToSymbolScheme[id] == 4) {
            symbols = 0x303134302E2E2E2E2E2E; // ░▒▓
        } else if (idToSymbolScheme[id] == 5) {
            symbols = 0x3035362E2E2E2E2E2E2E; // ░▄▀
        } else if (idToSymbolScheme[id] == 6) {
            symbols = 0x313731332E2E2E2E2E2E; // ▒┼≡
        } else {
            symbols = 0x30313233342E2E2E2E2E; // ░▒■┼▓
        }
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
                v = uint(x * y / ONE) % mod;
                if (v < 10) {
                    value = uint(uint8(symbols[v]));
                } else {
                    value = 0x2E;
                }
                output[c] = byte(bytes32(value << 248));
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

    /* * ** *** ***** ******** ************* ******** ***** *** ** * */
    
    function creator(uint _id) external view returns (address) {
        return idToCreator[_id];
    }

    function symbolScheme(uint _id) external view returns (uint8) {
        return idToSymbolScheme[_id];
    }

    function backgroundScheme(uint _id) external view returns (uint256) {
        return idToBackgroundColor[_id];
    }

    function colorScheme(uint _id) external view returns (uint256 color0, uint256 color1, uint color2, uint color3, uint color4, uint color5, uint color6, uint color7) {
        color0 = idToColorScheme[_id][0];
        color1 = idToColorScheme[_id][1];
        color2 = idToColorScheme[_id][2];
        color3 = idToColorScheme[_id][3];
        color4 = idToColorScheme[_id][4];
        color5 = idToColorScheme[_id][5];
        color6 = idToColorScheme[_id][6];
        color7 = idToColorScheme[_id][7];
    }
    
    function updateProcessingCode(string memory newProcessingCode, uint256 version) public {
        processingCode[version] = newProcessingCode;
    }
    
    function showProcessingCode(uint version) external view returns (string memory) {
        return processingCode[version];
    }

    function createPiece(uint seed) external payable {
        return _mint(msg.sender, seed);
    }

    //////////////////////////
    //// ERC 721 and 165  ////
    //////////////////////////

    /**
     * @dev Returns whether the target address is a contract.
     * @param _addr Address to check.
     */
    function isContract(address _addr) internal view returns (bool addressCheck) {
        uint256 size;
        assembly { size := extcodesize(_addr) } // solhint-disable-line
        addressCheck = size > 0;
    }

    /**
     * @dev Function to check which interfaces are suported by this contract.
     * @param _interfaceID Id of the interface.
     * @return True if _interfaceID is supported, false otherwise.
     */
    function supportsInterface(bytes4 _interfaceID) external view returns (bool) {
        return supportedInterfaces[_interfaceID];
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
    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes calldata _data) external {
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
     */
    function ownerOf(uint256 _tokenId) public view returns (address _owner) {
        _owner = idToOwner[_tokenId];
        require(_owner != address(0));
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
     * @dev Checks if `_operator` is an approved operator for `_owner`.
     * @param _owner The address that owns the NFTs.
     * @param _operator The address that acts on behalf of the owner.
     * @return True if approved for all, false otherwise.
     */
    function isApprovedForAll(address _owner, address _operator) external view returns (bool) {
        return ownerToOperators[_owner][_operator];
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
     * @dev Mints a new NFT.
     * @notice This is an internal function which should be called from user-implemented external
     * mint function. Its purpose is to show and properly initialize data structures when using this
     * implementation.
     * @param _to The address that will own the minted NFT.
     */
    function _mint(address _to, uint seed) internal {
        require(_to != address(0));
        require(numTokens < TOKEN_LIMIT);
        uint amount = 0;
        if (numTokens >= ARTIST_PRINTS) {
            amount = PRICE;
            require(msg.value >= amount);
        }
        require(seedToId[seed] == 0);
        uint id = numTokens + 1;

        idToCreator[id] = _to;
        idToSeed[id] = seed;
        seedToId[seed] = id;
        uint a = uint((keccak256(abi.encodePacked(seed,id))));
        idToBackgroundColor[id] = getBackgroundColor(a);
        idToSymbolScheme[id] = getScheme(a);
        uint randomColor;
        
        for (uint i = 0; i<8; i = i+1) {
            randomColor = getStartColor(uint(keccak256(abi.encodePacked(a,id,i))));
            idToColorScheme[id][i] = randomColor;
        }

        numTokens = numTokens + 1;
        _addNFToken(_to, id);

        if (msg.value > amount) {
            msg.sender.transfer(msg.value - amount);
        }
        if (amount > 0) {
            ownerOfGlyph(id).transfer(amount*1/3);
            BENEFICIARY.transfer(address(this).balance);
        }

        emit Transfer(address(0), _to, id);
        
        feelingLuckyColor(id);
    }
    
    function updateColor(uint id, uint symbolToUpdate, uint newColor) public {
        require(msg.sender == ownerOf(id));
        require(newColor < 16777216);
        require(checkValidSymbol(id,symbolToUpdate) == true);
        
        idToColorScheme[id][symbolToUpdate] = newColor;
        emit ColorChanged(id, symbolToUpdate, newColor);
    }
    
    function feelingLuckyColor(uint id) public {
        require(msg.sender == ownerOf(id));
        
        uint256 symbolToUpdate;
        uint256 seed = uint(keccak256(abi.encodePacked(id,block.number)));
        
        if (idToSymbolScheme[id] == 1) { //if scheme 1, then update symbol 0
            symbolToUpdate == 0;
            }
        else if (idToSymbolScheme[id] == 2) { //if scheme 2, then update symbol 0 or 1
            symbolToUpdate = seed % 2;
        }
        else if (idToSymbolScheme[id] == 3) { //if scheme 3, then update symbol 2 or 3
            symbolToUpdate = (seed % 2) + 2;
        }
        else if (idToSymbolScheme[id] == 4) { //if scheme 4, then update symbol 0, 1, or 4
            symbolToUpdate = (seed % 3);
            if (symbolToUpdate == 2) {
                symbolToUpdate = 4;
            }
        }
        else if (idToSymbolScheme[id] == 5) { //if scheme 5, then update symbol 0, 5, or 6
            symbolToUpdate = (seed % 3);
            if (symbolToUpdate == 1) {
                symbolToUpdate = 5;
            }
            else if (symbolToUpdate == 2) {
                symbolToUpdate = 6;
            }
        }
        else if (idToSymbolScheme[id] == 6) { //if scheme 6, then update symbol 1, 3, or 7
            symbolToUpdate = (seed % 3);
            if (symbolToUpdate == 0) {
                symbolToUpdate = 3;
            }
            else if (symbolToUpdate == 2) {
                symbolToUpdate = 7;
            }
        }
        else {
            symbolToUpdate = seed % 5; // if scheme 7, then update symbol 0, 1, 2, 3, or 4
        }        
        
        uint256 newColor = seed % 16777216;
        
        idToColorScheme[id][symbolToUpdate] = newColor;
        emit ColorChanged(id, symbolToUpdate, newColor);
    }
    
    function checkValidSymbol(uint id, uint symbolToCheck) public view returns (bool isValid){
        if (idToSymbolScheme[id] == 1) {
            if (symbolToCheck == 0) {
                isValid = true;
            }
        }
        else if (idToSymbolScheme[id] == 2) {
            if (symbolToCheck == 0 || symbolToCheck == 1) {
                isValid = true;
            }
        }
        else if (idToSymbolScheme[id] == 3) {
            if (symbolToCheck == 2 || symbolToCheck == 3) {
                isValid = true;
            }
        }
        else if (idToSymbolScheme[id] == 4) {
            if (symbolToCheck == 0 || symbolToCheck == 1 || symbolToCheck == 4) {
                isValid = true;
            }
        }
        else if (idToSymbolScheme[id] == 5) {
            if (symbolToCheck == 0 || symbolToCheck == 5 || symbolToCheck == 6) {
                isValid = true;
            }
        }
        else if (idToSymbolScheme[id] == 6) {
            if (symbolToCheck == 1 || symbolToCheck == 3 || symbolToCheck == 7) {
                isValid = true;
            }
        } 
        else {
            if (symbolToCheck == 0 || symbolToCheck == 1 || symbolToCheck == 2 || symbolToCheck == 3 || symbolToCheck == 4) {
                isValid = true;
            }
        } 
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
     * @dev Helper function that gets NFT count of owner. This is needed for overriding in enumerable
     * extension to remove double storage (gas optimization) of owner nft count.
     * @param _owner Address for whom to query the count.
     * @return Number of _owner NFTs.
     */
    function _getOwnerNFTCount(address _owner) internal view returns (uint256) {
        return ownerToIds[_owner].length;
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
     * @dev Clears the current approval of a given NFT ID.
     * @param _tokenId ID of the NFT to be transferred.
     */
    function _clearApproval(uint256 _tokenId) private {
        if (idToApproval[_tokenId] != address(0)) {
            delete idToApproval[_tokenId];
        }
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

    //// Metadata

    /**
      * @dev Returns a descriptive name for a collection of NFTokens.
      */
    function name() external view returns (string memory _name) {
        _name = nftName;
    }

    /**
     * @dev Returns an abbreviated name for NFTokens.
     */
    function symbol() external view returns (string memory _symbol) {
        _symbol = nftSymbol;
    }

    /**
     * @dev A distinct URI (RFC 3986) for a given NFT.
     */
    function tokenURI(uint256 id) external view returns (string memory) {
        return string(abi.encodePacked(URI, integerToString(uint256(id))));
    }
    
    function setURI(string memory newURI) public isOwner {
        URI = newURI;
    }

    function integerToString(uint _i) internal pure returns (string memory) {
      if (_i == 0) {
         return "0";
      }
      uint j = _i;
      uint len;
      
      while (j != 0) {
         len++;
         j /= 10;
      }
      bytes memory bstr = new bytes(len);
      uint k = len - 1;
      
      while (_i != 0) {
         bstr[k--] = byte(uint8(48 + _i % 10));
         _i /= 10;
      }
      return string(bstr);
   }

}