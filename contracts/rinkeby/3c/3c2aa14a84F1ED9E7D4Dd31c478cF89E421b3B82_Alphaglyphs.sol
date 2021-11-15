/**
 *Submitted for verification at Etherscan.io on 2019-12-11
 */

pragma solidity ^0.4.24;

/**
     *
     *     ****      *****   **         *****   *******     ****    **     **    ** *******   **     **   ****   
     *   **    **  **     ** **       **     ** **     ** **    **  **      **  **  **     ** **     ** **    ** 
     *   **        **     ** **       **     ** **     ** **        **       ****   **     ** **     ** **       
     *   **        **     ** **       **     ** *******   **   **** **        **    *******   *********   ****   
     *   **        **     ** **       **     ** **   **   **    **  **        **    **        **     **       ** 
     *   **    **  **     ** **       **     ** **    **  **    **  **        **    **        **     ** **    ** 
     *     ****      *****   ********   *****   **     **   ****    ********  **    **        **     **   ****   
     *
     *
     *                                                                by Daniel Viau
     *
     * Alphaglyphs extends Autoglyphs.
     * Quoting from Autoglyphs:
     *  The output of the 'tokenURI' function is a set of instructions to make a drawing.
     *  Each symbol in the output corresponds to a cell, and there are 64x64 cells arranged in a square grid.
     *  The drawing can be any size, and the pen's stroke width should be between 1/5th to 1/10th the size of a cell.
     *  The drawing instructions for the nine different symbols are as follows:
     *
     *    .  Draw nothing in the cell.
     *    O  Draw a circle bounded by the cell.
     *    +  Draw centered lines vertically and horizontally the length of the cell.
     *    X  Draw diagonal lines connecting opposite corners of the cell.
     *    |  Draw a centered vertical line the length of the cell.
     *    -  Draw a centered horizontal line the length of the cell.
     *    \  Draw a line connecting the top left corner of the cell to the bottom right corner.
     *    /  Draw a line connecting the bottom left corner of teh cell to the top right corner.
     *    #  Fill in the cell completely.
     *
     * The 'tokenURI' function of Alphaglyphs adds two pieces of information to the response provided by autoglyphs:
     *  1) The color scheme to apply to the Colorglyph.
     *  2) The address of the Colorglyph's creator, from which colors are derived.
     *
     * The address of the Colorglyph's creator is split up into 35 6 digit chunks.
     * For example, the first three chunks of 0xb189f76323678E094D4996d182A792E52369c005 are: b189f7, 189f76, and 89f763.
     * The last chunk is 69c005.
     * Each Colorglyph is an Autoglyph with a color scheme applied to it.
     * Each Colorglyph takes the same shape as the Autoglyph of the corresponding ID.
     * If the Colorglyph's ID is higher than 512, it takes the shape of the Autoglyph with its Alphaglyphs ID - 512.
     * Each black element in the Autoglyph is assigned a new color.
     * The background color of the Autoglyph is changed to either black or one of the address colors.
     * Visual implementations of Alphaglyphs may exercise a substantial degree of flexibility.
     * Color schemes that use multiple colors may apply any permitted color to any element,
     * but no color should appear more than 16 times as often as the color with the lowest number of incidences.
     * In the event that a color meets two conditions (reddest and orangest, for example),
     * it may be used for both purposes.  The previous guideline establishing a threshold ratio of occurances
     * treats the reddest color and the orangest color as two different colors, even if they have the same actual value.

     * lightest address color = chunk with the lowest value resulting from red value + green value + blue value
     * second lightest address color = second lightest chunk in relevant address
     * third lightest address color = third lightest chunk in relevant address
     * fourth lightest address color = fourth lightest chunk in relevant address
     * fifth lightest address color = fifth lightest chunk in relevant address
     * reddest address color = chunk with the lowest value resulting from red value - green value - blue value
     * orangest address color = chunk with the highest value resulting from red value - blue value
     * yellowest address color = chunk with higest value resulting from red value + green value - blue value
     * greenest address color = chunk with higest value resulting from green value - red value - blue value
     * bluest address color = chunk with higest value resulting from blue value - green value - red value
     * darkest address color = darkest chunk in relevant address
     * white = ffffff
     * black = 020408

     * scheme 1 = lightest address color, third lightest address color, and fifth lightest address color on black
     * scheme 2 = lighest 4 address colors on black                            
     * scheme 3 = reddest address color, orangest address color, and yellowest address color on black                                             
     * scheme 4 = reddest address color, yellowest address color, greenest address color, and white on black                                      
     * scheme 5 = lightest address color, reddest address color, yellowest address color, greenest address color, and bluest address color on black                                      
     * scheme 6 = reddest address color and white on black                     
     * scheme 7 = greenest address color on black                              
     * scheme 8 = lightest address color on darkest address color              
     * scheme 9 = greenest address color on reddest address color                                        
     * scheme 10 = reddest address color, yellowest address color, bluest address color, lightest address color, and black on white
     */

library Strings {
    // via https://github.com/oraclize/ethereum-api/blob/master/oraclizeAPI_0.5.sol
    function strConcat(
        string _a,
        string _b,
        string _c,
        string _d,
        string _e
    ) internal pure returns (string) {
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(
            _ba.length + _bb.length + _bc.length + _bd.length + _be.length
        );
        bytes memory babcde = bytes(abcde);
        uint256 k = 0;
        for (uint256 i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(
        string _a,
        string _b,
        string _c,
        string _d
    ) internal pure returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(
        string _a,
        string _b,
        string _c
    ) internal pure returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal pure returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint256 i) internal pure returns (string) {
        if (i == 0) return "0";
        uint256 j = i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len - 1;
        while (i != 0) {
            bstr[k--] = bytes1(48 + (i % 10));
            i /= 10;
        }
        return string(bstr);
    }
}

interface ERC721TokenReceiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes _data
    ) external returns (bytes4);
}

contract Autoglyphs {
    function draw(uint256 id) public view returns (string);

    function ownerOf(uint256 _tokenId) external view returns (address);
}

contract Alphaglyphs {
    event Generated(uint256 indexed index, address indexed a, string value);

    /// @dev This emits when ownership of any NFT changes by any mechanism.
    ///  This event emits when NFTs are created (`from` == 0) and destroyed
    ///  (`to` == 0). Exception: during contract creation, any number of NFTs
    ///  may be created and assigned without emitting Transfer. At the time of
    ///  any transfer, the approved address for that NFT (if any) is reset to none.
    event Transfer(
        address indexed _from,
        address indexed _to,
        uint256 indexed _tokenId
    );

    /// @dev This emits when the approved address for an NFT is changed or
    ///  reaffirmed. The zero address indicates there is no approved address.
    ///  When a Transfer event emits, this also indicates that the approved
    ///  address for that NFT (if any) is reset to none.
    event Approval(
        address indexed _owner,
        address indexed _approved,
        uint256 indexed _tokenId
    );

    /// @dev This emits when an operator is enabled or disabled for an owner.
    ///  The operator can manage all NFTs of the owner.
    event ApprovalForAll(
        address indexed _owner,
        address indexed _operator,
        bool _approved
    );

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    uint256 public constant CLAIMABLE_TOKEN_LIMIT = 512;
    uint256 public constant CREATEABLE_TOKEN_LIMIT = 512;
    uint256 public constant TOTAL_TOKEN_LIMIT = 1024;
    uint256 public constant ARTIST_PRINTS = 32;

    uint256 public constant PRICE = 50 finney;

    // The beneficiary is eff.org
    address public constant BENEFICIARY =
        0xb189f76323678E094D4996d182A792E52369c005;

    address public autoglyphsAddress =
        0xd4e4078ca3495de5b1d4db434bebc5a986197782;

    /**
     * @dev A mapping from NFT ID to a boolean representing whether an owner of the corresponding Autoglyph has claimed it.
     */
    mapping(uint256 => bool) private idToGlyphIsClaimed;

    /**
     * @dev A mapping from NFT ID to the address that created it.
     */
    mapping(uint256 => address) private idToCreator;
    /**
     * @dev A mapping from NFT ID to the color scheme that applies it.
     */
    mapping(uint256 => string) private idToColorScheme;

    // ERC 165
    mapping(bytes4 => bool) internal supportedInterfaces;

    /**
     * @dev A mapping from NFT ID to the address that owns it.
     */
    mapping(uint256 => address) internal idToOwner;

    /**
     * @dev A mapping from NFT ID to the seed used to make it.
     */
    mapping(uint256 => uint256) internal idToSeed;
    mapping(uint256 => uint256) internal seedToId;

    /**
     * @dev Mapping from NFT ID to approved address.
     */
    mapping(uint256 => address) internal idToApproval;

    /**
     * @dev Mapping from owner address to mapping of operator addresses.
     */
    mapping(address => mapping(address => bool)) internal ownerToOperators;

    /**
     * @dev Mapping from owner to list of owned NFT IDs.
     */
    mapping(address => uint256[]) internal ownerToIds;

    /**
     * @dev Mapping from NFT ID to its index in the owner tokens list.
     */
    mapping(uint256 => uint256) internal idToOwnerIndex;

    /**
     * @dev Total number of createablw tokens. Range 1-512.
     */
    uint256 internal numCreatedTokens = 0;

    /**
     * @dev Total number of claimable tokens. Range 513-1024.
     */
    uint256 internal numClaimedTokens = 0;

    /**
     * @dev Total number of tokens.
     */
    uint256 internal numTotalTokens = 0;

    /**
     * @dev Guarantees that the msg.sender is an owner or operator of the given NFT.
     * @param _tokenId ID of the NFT to validate.
     */
    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender]
        );
        _;
    }

    /**
     * @dev Guarantees that the msg.sender is allowed to transfer NFT.
     * @param _tokenId ID of the NFT to transfer.
     */
    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender ||
                idToApproval[_tokenId] == msg.sender ||
                ownerToOperators[tokenOwner][msg.sender]
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

    string internal nftName = "Alphaglyphs";
    string internal nftSymbol = "☲";

    ///////////////////
    //// GENERATOR ////
    ///////////////////

    function draw(uint256 _tokenId) public view returns (string memory) {
        Autoglyphs autoglyphs = Autoglyphs(autoglyphsAddress);
        uint256 autoglyphsTokenId;
        if (_tokenId > 512) {
            autoglyphsTokenId = _tokenId - 512;
        } else {
            autoglyphsTokenId = _tokenId;
        }
        string memory drawing = autoglyphs.draw(autoglyphsTokenId);
        string memory scheme = idToColorScheme[_tokenId];
        string memory creator_address = toAsciiString(idToCreator[_tokenId]);
        return Strings.strConcat(drawing, scheme, creator_address);
    }

    function getScheme(uint256 a) internal pure returns (string) {
        uint256 index = a % 83;
        string memory scheme;
        if (index < 20) {
            scheme = " 1 ";
        } else if (index < 35) {
            scheme = " 2 ";
        } else if (index < 48) {
            scheme = " 3 ";
        } else if (index < 59) {
            scheme = " 4 ";
        } else if (index < 68) {
            scheme = " 5 ";
        } else if (index < 73) {
            scheme = " 6 ";
        } else if (index < 77) {
            scheme = " 7 ";
        } else if (index < 80) {
            scheme = " 8 ";
        } else if (index < 82) {
            scheme = " 9 ";
        } else {
            scheme = " 10 ";
        }
        return scheme;
    }

    function toAsciiString(address x) returns (string) {
        bytes memory s = new bytes(40);
        for (uint256 i = 0; i < 20; i++) {
            bytes1 b = bytes1(uint8(uint256(x) / (2**(8 * (19 - i)))));
            bytes1 hi = bytes1(uint8(b) / 16);
            bytes1 lo = bytes1(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    }

    function char(bytes1 b) returns (bytes1 c) {
        if (b < 10) return bytes1(uint8(b) + 0x30);
        else return bytes1(uint8(b) + 0x57);
    }

    function creator(uint256 _id) external view returns (address) {
        return idToCreator[_id];
    }

    function colorScheme(uint256 _id) external view returns (string) {
        return idToColorScheme[_id];
    }

    function createGlyph(uint256 seed) external payable returns (string) {
        return _mint(msg.sender, seed, false, 0);
    }

    function claimGlyph(uint256 seed, uint256 idBeingClaimed)
        external
        payable
        returns (string)
    {
        return _mint(msg.sender, seed, true, idBeingClaimed);
    }

    //////////////////////////
    //// ERC 721 and 165  ////
    //////////////////////////

    /**
     * @dev Returns whether the target address is a contract.
     * @param _addr Address to check.
     * @return True if _addr is a contract, false if not.
     */
    function isContract(address _addr)
        internal
        view
        returns (bool addressCheck)
    {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        } // solhint-disable-line
        addressCheck = size > 0;
    }

    /**
     * @dev Function to check which interfaces are suported by this contract.
     * @param _interfaceID Id of the interface.
     * @return True if _interfaceID is supported, false otherwise.
     */
    function supportsInterface(bytes4 _interfaceID)
        external
        view
        returns (bool)
    {
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
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes _data
    ) external {
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
    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
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
    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external canTransfer(_tokenId) validNFToken(_tokenId) {
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
    function approve(address _approved, uint256 _tokenId)
        external
        canOperate(_tokenId)
        validNFToken(_tokenId)
    {
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
    function getApproved(uint256 _tokenId)
        external
        view
        validNFToken(_tokenId)
        returns (address)
    {
        return idToApproval[_tokenId];
    }

    /**
     * @dev Checks if `_operator` is an approved operator for `_owner`.
     * @param _owner The address that owns the NFTs.
     * @param _operator The address that acts on behalf of the owner.
     * @return True if approved for all, false otherwise.
     */
    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool)
    {
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
    function _mint(
        address _to,
        uint256 seed,
        bool autoglyphOwnerIsClaimingToken,
        uint256 idBeingClaimed
    ) internal returns (string) {
        require(_to != address(0));
        require(numCreatedTokens < CREATEABLE_TOKEN_LIMIT);
        require(numClaimedTokens < CLAIMABLE_TOKEN_LIMIT);
        require(numTotalTokens < TOTAL_TOKEN_LIMIT);
        if (autoglyphOwnerIsClaimingToken) {
            Autoglyphs autoglyphs = Autoglyphs(autoglyphsAddress);
            require(idToGlyphIsClaimed[idBeingClaimed] == false);
            require(autoglyphs.ownerOf(idBeingClaimed) == msg.sender);
        }
        uint256 amount = 0;
        if (
            numCreatedTokens >= ARTIST_PRINTS &&
            autoglyphOwnerIsClaimingToken == false
        ) {
            amount = PRICE;
            require(msg.value >= amount);
        }
        require(seedToId[seed] == 0);
        uint256 id;
        if (autoglyphOwnerIsClaimingToken) {
            id = idBeingClaimed + 512;
        } else {
            id = numCreatedTokens + 1;
        }

        idToCreator[id] = _to;
        idToSeed[id] = seed;
        seedToId[seed] = id;
        uint256 a = uint256(uint160(keccak256(abi.encodePacked(seed))));
        idToColorScheme[id] = getScheme(a);
        string memory uri = draw(id);
        emit Generated(id, _to, uri);

        numTotalTokens = numTotalTokens + 1;
        if (autoglyphOwnerIsClaimingToken) {
            numClaimedTokens = numClaimedTokens + 1;
        } else {
            numCreatedTokens = numCreatedTokens + 1;
        }
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
    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) private canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from);
        require(_to != address(0));

        _transfer(_to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(
                msg.sender,
                _from,
                _tokenId,
                _data
            );
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
        return numTotalTokens;
    }

    function totalCreatedSupply() public view returns (uint256) {
        return numCreatedTokens;
    }

    function totalClaimedSupply() public view returns (uint256) {
        return numClaimedTokens;
    }

    function tokenByIndex(uint256 index) public view returns (uint256) {
        require(index < TOTAL_TOKEN_LIMIT);
        if (index < CREATEABLE_TOKEN_LIMIT) {
            require(index < numCreatedTokens);
        } else {
            require(idToGlyphIsClaimed[index]);
        }
        return index;
    }

    /**
     * @dev returns the n-th NFT ID from a list of owner's tokens.
     * @param _owner Token owner's address.
     * @param _index Index number representing n-th token in owner's list of tokens.
     * @return Token id.
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index)
        external
        view
        returns (uint256)
    {
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
    function tokenURI(uint256 _tokenId)
        external
        view
        validNFToken(_tokenId)
        returns (string memory)
    {
        return draw(_tokenId);
    }
}

