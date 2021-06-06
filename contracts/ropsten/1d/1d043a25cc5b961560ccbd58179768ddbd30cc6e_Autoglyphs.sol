/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

/**
 *Submitted for verification at Etherscan.io on 2019-04-05
*/

pragma solidity ^0.4.24;

/**
 *
 *      ***    **     ** ********  *******   ******   **     **    ** ********  **     **  ******
 *     ** **   **     **    **    **     ** **    **  **      **  **  **     ** **     ** **    **
 *    **   **  **     **    **    **     ** **        **       ****   **     ** **     ** **
 *   **     ** **     **    **    **     ** **   **** **        **    ********  *********  ******
 *   ********* **     **    **    **     ** **    **  **        **    **        **     **       **
 *   **     ** **     **    **    **     ** **    **  **        **    **        **     ** **    **
 *   **     **  *******     **     *******   ******   ********  **    **        **     **  ******
 *
 *
 *                                                                by Matt Hall and John Watkinson
 *
 *
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
interface ERC721TokenReceiver
{

    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes _data) external returns(bytes4);

}

contract Autoglyphs {

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

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    uint public constant TOKEN_LIMIT = 512; // 8 for testing, 256 or 512 for prod;
    uint public constant ARTIST_PRINTS = 128; // 2 for testing, 64 for prod;

    uint public constant PRICE = 200 finney;

    // The beneficiary is 350.org
    address public constant BENEFICIARY = 0x50990F09d4f0cb864b8e046e7edC749dE410916b;

    mapping (uint => address) private idToCreator;
    mapping (uint => uint8) private idToSymbolScheme;

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

    /**
     * @dev Contract constructor.
     */
    constructor() public {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721 Metadata
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

    string internal nftName = "Autoglyphs";
    string internal nftSymbol = "☵";

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

    function draw(uint id) public view returns (string) {
        /*uint a = uint(uint160(keccak256(abi.encodePacked(idToSeed[id]))));
        bytes memory output = new bytes(USIZE * (USIZE + 3) + 30);
        uint c;
        for (c = 0; c < 30; c++) {
            output[c] = prefix[c];
        }
        int x = 0;
        int y = 0;
        uint v = 0;
        uint value = 0;
        uint mod = (a % 11) + 5;
        bytes5 symbols;
        if (idToSymbolScheme[id] == 0) {
            revert();
        } else if (idToSymbolScheme[id] == 1) {
            symbols = 0x2Ee297862E; // X/\ ■▬▮▰●◖◗
        } else if (idToSymbolScheme[id] == 2) {
            symbols = 0x2Ee296b22E; // +-|
        } else if (idToSymbolScheme[id] == 3) {
            symbols = 0x2Ee296bc2E; // /\
        } else if (idToSymbolScheme[id] == 4) {
            symbols = 0x2Ee297a22E; // \|-/
        } else if (idToSymbolScheme[id] == 5) {
            symbols = 0x2Ee297a32E; // O|-
        } else if (idToSymbolScheme[id] == 6) {
            symbols = 0x2Ee297a42E; // \
        } else if (idToSymbolScheme[id] == 7) {
            symbols = 0x2Ee297a52E; // #|-+
        } else if (idToSymbolScheme[id] == 8) {
            symbols = 0x2Ee296b62E; // OO
        } else if (idToSymbolScheme[id] == 9) {
            symbols = 0x2Ee297802E; // #
        } else {
            symbols = 0x2Ee2978f2E; // #O
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
                if (v < 5) {
                    value = uint(symbols[v]);
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
        }*/
        bytes memory output1="data:text/plain;charset=utf-8,..._\///>_.................._|///|_......%0A..//00######0+.............|00##0#0##0/..%0A.000#X+.._/###X...........X###0/_._+X##X.%0A/###0.......0##XX........X##00......_0##+%0A/###X........00##X......X0#0.........0##/%0A>###0........_0###/....X##0_........_0#0+%0A.X###X........|####_.._##0>.........X##X.%0A..//XX/........XX##X..X##X.........//X/.%0A...............__###__###_...............%0A.................X##/X#0X................%0A................./##X0#0\................%0A................._#####0.................%0A..................X##0#X.................%0A................../##0#\.................%0A.................._#0##_.................%0A...................##00..................%0A...................X##X..................%0A...................X##X..................%0A.................../XX/..................";
        string memory result = string(output1);
        return result;
    }

    /* * ** *** ***** ******** ************* ******** ***** *** ** * */

    function creator(uint _id) external view returns (address) {
        return idToCreator[_id];
    }

    function symbolScheme(uint _id) external view returns (uint8) {
        return idToSymbolScheme[_id];
    }

    function createGlyph(uint seed) external payable returns (string) {
        return _mint(msg.sender, seed);
    }

    //////////////////////////
    //// ERC 721 and 165  ////
    //////////////////////////

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
     * @param _tokenId The identifier for an NFT.
     * @return Address of _tokenId owner.
     */
    function ownerOf(uint256 _tokenId) external view returns (address _owner) {
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
    function _mint(address _to, uint seed) internal returns (string) {
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
        uint a = uint(uint160(keccak256(abi.encodePacked(seed))));
        idToSymbolScheme[id] = getScheme(a);
        string memory uri = draw(id);
        emit Generated(id, _to, uri);

        numTokens = numTokens + 1;
        _addNFToken(_to, id);

        if (msg.value > amount) {
            msg.sender.transfer(msg.value - amount);
        }
        if (amount > 0) {
            BENEFICIARY.transfer(amount);
        }

        emit Transfer(address(0), _to, id);
        return uri;
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

    /**
     * @dev A distinct URI (RFC 3986) for a given NFT.
     * @param _tokenId Id for which we want uri.
     * @return URI of _tokenId.
     */
    function tokenURI(uint256 _tokenId) external view validNFToken(_tokenId) returns (string memory) {
        return draw(_tokenId);
    }

}