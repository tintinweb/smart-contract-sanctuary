// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./utils/Base64.sol";

import "./SoulsDescriptor.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract Souls is ERC721 {

    address public owner = 0xaF69610ea9ddc95883f97a6a3171d52165b69B03; // for opensea integration. doesn't do anything else.

    address public collector; // address authorised to withdraw funds recipient
    address payable public recipient; // in this instance, it will be a mirror split on mainnet. 0xec0ef86a3872829F3EC40de1b1b9Df54a3D4a4b3

    uint256 public buyableSoulSupply;

    // minting time
    uint256 public startDate;
    uint256 public endDate;

    mapping(uint256 => bool) public soulsType; // true == full soul

    SoulsDescriptor public descriptor;

    ERC721 public anchorCertificates;

    // uint256 public newlyMinted;

    mapping(uint256 => bool) public claimedACIDs;

    event Claim(address indexed claimer, uint256 indexed tokenId);

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_, address collector_, address payable recipient_, uint256 startDate_, uint256 endDate_, address certificates_) ERC721(name_, symbol_) {
        collector = collector_; 
        recipient = recipient_;
        startDate = startDate_;
        endDate = endDate_;
        descriptor = new SoulsDescriptor();
        anchorCertificates = ERC721(certificates_);

        /* INITIAL CLAIM/MINT */
        // initial claim for un_frontier outside campaign window.
        // allows metadata + graph + storefronts to propagate before launch.
        // let this initial claim come from simondlr's personal collection of anchor certificates.
        // it is default certificate #1.
        // https://opensea.io/assets/0x600a4446094c341693c415e6743567b9bfc8a4a8/86944833354306826451453519009172227432197817959411860297499850535918774474487
        claimedACIDs[86944833354306826451453519009172227432197817959411860297499850535918774474487] = true;
        _createSoul(true,address(0xaF69610ea9ddc95883f97a6a3171d52165b69B03)); // claim the soul for untitled frontier, not simondlr.
        emit Claim(0xaF69610ea9ddc95883f97a6a3171d52165b69B03, 86944833354306826451453519009172227432197817959411860297499850535918774474487);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory soulType = "Sketched";
        if(soulsType[tokenId] == true) {
            soulType = "Fully Painted";
        }

        string memory name = descriptor.generateName(soulType, tokenId); 
        string memory description = "Paintings of forgotten souls by various simulated minds that try to remember those who they once knew in the default world.";

        string memory image = generateBase64Image(tokenId);
        string memory attributes = generateTraits(tokenId);
        return string(
            abi.encodePacked(
                'data:application/json;base64,',
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name":"', 
                            name,
                            '", "description":"', 
                            description,
                            '", "image": "', 
                            'data:image/svg+xml;base64,', 
                            image,'",',
                            attributes,
                            '}'
                        )
                    )
                )
            )
        );
    }

    function generateBase64Image(uint256 tokenId) public view returns (string memory) {
        bytes memory img = bytes(generateImage(tokenId));
        return Base64.encode(img);
    }

    function generateImage(uint256 tokenId) public view returns (string memory) {
        return descriptor.generateImage(tokenId, soulsType[tokenId]);
    }

    function generateTraits(uint256 tokenId) public view returns (string memory) {
        return descriptor.generateTraits(tokenId, soulsType[tokenId]);
    }

    /*
    Owners of Anchor Certificates can claim a full soul.
    Max 160.
    */
    function claimSoul(uint ACID) public  {
        require(block.timestamp > startDate, "NOT_STARTED"); // ~ 2000 gas
        require(block.timestamp < endDate, "ENDED");
        require(claimedACIDs[ACID] == false, "AC_ID ALREADY CLAIMED");
        require(anchorCertificates.ownerOf(ACID) == msg.sender, "AC_ID NOT OWNED BY SENDER");

        claimedACIDs[ACID] = true;
        _createSoul(true, msg.sender);
        emit Claim(msg.sender, ACID);
    }

    function mintSoul() public payable {
        require(block.timestamp > startDate, "NOT_STARTED"); // ~ 2000 gas
        require(block.timestamp < endDate, "ENDED");
        require(msg.value >= 0.010 ether, 'MORE ETH NEEDED'); //~$30

        if(msg.value >= 0.068 ether) { //~$200
            buyableSoulSupply += 1;
            require(buyableSoulSupply <= 96, "MAX_SOLD_96");
            _createSoul(true, msg.sender);
        } else { // don't need to check ETH amount here since it is checked in the require above
            _createSoul(false, msg.sender);
        }
    }

    function _createSoul(bool fullSoul, address _owner) internal {
        uint256 tokenId = uint(keccak256(abi.encodePacked(block.timestamp, _owner)));
        soulsType[tokenId] = fullSoul;
        // newlyMinted = tokenId; // tests
        super._mint(_owner, tokenId);
    }

    function withdrawETH() public {
        require(msg.sender == collector, "NOT_COLLECTOR");
        recipient.transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC721.sol";
import "./interfaces/IERC721Receiver.sol";
import "./interfaces/IERC721Metadata.sol";
import "./utils/Address.sol";
// import "../../utils/Context.sol";
import "./utils/Strings.sol";
import "./ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId
            || interfaceId == type(IERC721Metadata).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty 
     * by default, can be overriden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != msg.sender, "ERC721: approve to caller");

        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        // _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        // _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        // _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    // modified from ERC721 template:
    // removed BeforeTokenTransfer
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides a function for encoding some bytes in base64
library Base64 {
    string internal constant TABLE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';
        
        // load the table into memory
        string memory table = TABLE;

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
               dataPtr := add(dataPtr, 3)
               
               // read 3 bytes
               let input := mload(dataPtr)
               
               // write 4 characters
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr( 6, input), 0x3F)))))
               resultPtr := add(resultPtr, 1)
               mstore(resultPtr, shl(248, mload(add(tablePtr, and(        input,  0x3F)))))
               resultPtr := add(resultPtr, 1)
            }
            
            // padding with '='
            switch mod(mload(data), 3)
            case 1 { mstore(sub(resultPtr, 2), shl(240, 0x3d3d)) }
            case 2 { mstore(sub(resultPtr, 1), shl(248, 0x3d)) }
        }
        
        return result;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
Contract that's primarily responsible for generating the metadata, including the image itself in SVG.
Parts of the SVG is encapsulated into custom re-usable components specific to this collection.
*/
contract SoulsDescriptor {

    function generateName(string memory soulType, uint soulNr) public pure returns (string memory) {
        return string(abi.encodePacked(soulType, ' Forgotten Soul #', substring(toString(soulNr),0,8)));
    }

    function generateTraits(uint256 tokenId, bool fullSoul) public pure returns (string memory) {
        bytes memory hash = abi.encodePacked(bytes32(tokenId));

        string memory paintingTraits = "";

        string memory paintingType = string(abi.encodePacked('{"trait_type": "Type", "value": "Fully Painted"},'));
        if(fullSoul == false) { paintingType = string(abi.encodePacked('{"trait_type": "Type", "value": "Sketch"},'));}

        (uint colour1, uint colour2, uint colour3) = generateColours(hash);
        string memory compositionType = getColourCompositionType(toUint8(hash,2));
        uint saturation = 60 - uint256(toUint8(hash,30))*55/255;

        string memory layersTrait = "";
        uint layers;

        bool colours;
        if(toUint8(hash,22) < 128 || fullSoul == true) { 
            paintingTraits = string(abi.encodePacked(paintingTraits, '{"value": "Background"}, {"trait_type": "Colour 1", "value":"',toString(colour1),'" },')); 
            layers++;
            colours = true;
        }
        if(toUint8(hash,23) < 128 || fullSoul == true) { paintingTraits = string(abi.encodePacked(paintingTraits, '{"value": "Frame"},')); layers++; }
        if(toUint8(hash,24) < 128 || fullSoul == true) { paintingTraits = string(abi.encodePacked(paintingTraits, '{"value": "Back Splash"},')); layers++; }
        if(toUint8(hash,25) < 128 || fullSoul == true) { paintingTraits = string(abi.encodePacked(paintingTraits, '{"value": "Body"},')); layers++; }
        if(toUint8(hash,26) < 128 || fullSoul == true) { 
            paintingTraits = string(abi.encodePacked(paintingTraits, '{"value": "Back Head"}, {"trait_type": "Colour 2", "value": "',toString(colour2),'" },')); 
            layers++; 
            colours = true;
        }
        if(toUint8(hash,27) < 128 || fullSoul == true) { 
            paintingTraits = string(abi.encodePacked(paintingTraits, '{"value": "Front Head"}, {"trait_type": "Colour 3", "value": "',toString(colour3),'" },')); 
            layers++; 
            colours = true; 
        }
        if(toUint8(hash,28) < 128 || fullSoul == true) { paintingTraits = string(abi.encodePacked(paintingTraits, '{"value": "Rings"},')); layers++; }
        if(toUint8(hash,29) < 128 || fullSoul == true) { paintingTraits = string(abi.encodePacked(paintingTraits, '{"value": "Eyes"},')); layers++; }

        layersTrait = string(abi.encodePacked('{"trait_type": "Layers", "value": "',toString(layers),'"}'));

        string memory colourCompositionTrait;
        if(colours == true) { colourCompositionTrait = string(abi.encodePacked('{"trait_type": "Colour Composition Type", "value": "',compositionType,'" }, {"trait_type": "Saturation", "value": "',toString(saturation),'" },')); }

        return string(abi.encodePacked(
            '"attributes": [',
            paintingType,
            colourCompositionTrait,
            paintingTraits,
            layersTrait,
            ']'
        ));
    }

    function generateImage(uint256 tokenId, bool fullSoul) public pure returns (string memory) {
        bytes memory hash = abi.encodePacked(bytes32(tokenId));

        (uint colour1, uint colour2, uint colour3) = generateColours(hash);

        string memory background = "";
        string memory innerFrame = "";
        string memory backSplash = "";
        string memory body = "";
        string memory backHead = "";
        string memory frontHead = "";
        string memory rings = "";
        string memory eyes = "";

        // Hash Bytes used to this point-> 21
        if(toUint8(hash,22) < 128 || fullSoul == true) { background = generateBackground(hash, colour1); }
        if(toUint8(hash,23) < 128 || fullSoul == true) { innerFrame = generateInnerFrame(hash); }
        if(toUint8(hash,24) < 128 || fullSoul == true) { backSplash = generateBackSplash(hash); }
        if(toUint8(hash,25) < 128 || fullSoul == true) { body = generateBody(hash); }
        if(toUint8(hash,26) < 128 || fullSoul == true) { backHead = generateBackHead(hash, colour2); }
        if(toUint8(hash,27) < 128 || fullSoul == true) { frontHead = generateFrontHead(hash, colour3); }
        if(toUint8(hash,28) < 128 || fullSoul == true) { rings = generateRings(hash);}
        if(toUint8(hash,29) < 128 || fullSoul == true) { eyes = generateEyes(hash); }

        return string(
            abi.encodePacked(
                '<svg width="600" height="600" viewBox="0 0 600 600" xmlns="http://www.w3.org/2000/svg">',
                '<rect x="0" y="0" width="600" height="600" fill="white" />',
                background,
                innerFrame,
                backSplash,
                body,
                backHead,
                frontHead,
                rings,
                eyes,
                '</svg>'
            )
        );
    }

    function generateColours(bytes memory hash) public pure returns (uint, uint, uint) {
        uint colour1 = uint256(toUint8(hash,1))*360/255; 
        uint colourCompositionByte = toUint8(hash,2);
        uint colour2;
        uint colour3;
        string memory compositionType = getColourCompositionType(colourCompositionByte);

        if(keccak256(bytes(compositionType)) == keccak256(bytes('Split Composition'))) {
            //split composition
            colour2 = (colour1+150) % 360;
            colour3 = (colour1+210) % 360;
        } else if(keccak256(bytes(compositionType)) == keccak256(bytes('Triad Composition'))) {
            // triad composition
            colour2 = (colour1+120) % 360;
            colour3 = (colour1+240) % 360;
        } else {
            // analogous composition
            colour2 = (colour1+30) % 360;
            colour3 = (colour1+90) % 360;
        }

        return (colour1, colour2, colour3);
    }

    function getColourCompositionType(uint compositionByte) public pure returns (string memory) {
        if(compositionByte >= 0 && compositionByte < 85) {
            return 'Split Composition';
        } else if(compositionByte >=85 && compositionByte < 170) {
            return 'Triad Composition';
        } else {
            return 'Analogous Composition';
        }
    }

    /* GENERATION FUNCTIONS (in order of layers) */

    // Layer 1 - Background.
    // Hash Bytes Used - 3,4,5
    function generateBackground(bytes memory hash, uint colour1) public pure returns (string memory) {
        uint backgroundFrequency = uint256(toUint8(hash,3))*1000/255; 
        uint backgroundSurfaceScale = uint256(toUint8(hash,4))*10/255;
        uint elevation = 50 + uint256(toUint8(hash,5))*90/255; 
        uint saturation = 60 - uint256(toUint8(hash,30))*55/255;
        return string(abi.encodePacked(
            svgFilter("backgroundDisplacement"),
            svgFeTurbulence("100",generateDecimalString(backgroundFrequency,2)),
            '<feMorphology in="turbulence" result="morphed" operator="erode" radius="1"></feMorphology>',
            '<feDiffuseLighting in="morphed" lighting-color="hsl(',toString(colour1),', ',toString(saturation),'%, 50%)" surfaceScale="',toString(backgroundSurfaceScale),'"><feDistantLight azimuth="45" elevation="',toString(elevation),'" /></feDiffuseLighting>',
            '</filter><rect x="0" y="0" width="600" height="600" style="filter: url(#backgroundDisplacement)" />'
        ));
    }

    // Layer 2 - Inner Frame
    // Hash Bytes Used - 6,7
    function generateInnerFrame(bytes memory hash) public pure returns (string memory) {
        uint frameFrequency = uint256(toUint8(hash,6))*1000/255; 
        uint frameSeed = uint256(toUint8(hash,6))*1000/255; // added in post. more variation.
        uint frameStrokeWidth = uint256(toUint8(hash,7))*40/255;

        return string(abi.encodePacked(
            svgFilter("frameDisplacement"),
            svgFeTurbulence(toString(frameSeed),generateDecimalString(frameFrequency,4)),
            '<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="50" xChannelSelector="G" yChannelSelector="A"/></filter>',
            '<rect x="50" y="50" width="500" height="500" stroke="black" opacity="0.5" fill="white" stroke-width="',toString(frameStrokeWidth),'" style="filter: url(#frameDisplacement)"/>'
        ));
    }

    // Layer 3 - Back Splash
    // Hash Bytes Used - 8,9
    function generateBackSplash(bytes memory hash) public pure returns (string memory) {
        uint8 radii = toUint8(hash,0)/3;
        uint backSplashFrequency = uint256(toUint8(hash,8))*1000/255; 
        uint backStrokeWidth = uint256(toUint8(hash,9))*40/255;

        return string(abi.encodePacked(
            '<defs>',
            '<linearGradient id="backSplashGrad" x2="0%" y2="100%">',
            '<stop offset="0%" stop-color="black" />',
            '<stop offset="50%" stop-color="white" />',
            '</linearGradient>',
            '</defs>',
            svgFilter("backSplash"),
            svgFeTurbulence("2000",generateDecimalString(backSplashFrequency,4)),
            '<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="200" xChannelSelector="G" yChannelSelector="A"/></filter>',
            svgCircle("300","270",toString(170-radii),"url(#backSplashGrad)",toString(backStrokeWidth),"none", "filter: url(#backSplash)")
        ));
    }

    // Layer 4 - Body
    // Hash Bytes Used - 10
    function generateBody(bytes memory hash) public pure returns (string memory) {
        uint8 radii = toUint8(hash,0)/3;
        uint bodyFrequency = uint256(toUint8(hash,10))*1000/255;  

        return string(abi.encodePacked(
            svgFilter("bodyDisplacement"),
            svgFeTurbulence("100",generateDecimalString(bodyFrequency,4)),
            '<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="50" xChannelSelector="R" yChannelSelector="G"/> </filter>',
            svgCircle("300",toString(700-radii),toString(180-radii),"black","0","black","filter: url(#bodyDisplacement)")
        ));
    }

    // Layer 5 - Back Head
    // Hash Bytes Used - 11,12
    function generateBackHead(bytes memory hash, uint colour2) public pure returns (string memory) {
        uint8 radii = toUint8(hash,0)/3;
        uint backHeadFrequency = uint256(toUint8(hash,11))*1000/255; 
        uint backHeadScale = uint256(toUint8(hash,12))*400/255;
        uint saturation = 60 - uint256(toUint8(hash,30))*55/255;

        string memory fill = string(abi.encodePacked('hsl(',toString(colour2),', ',toString(saturation),'%, 50%)'));

        return string(abi.encodePacked(
            svgFilter("headDisplacement"), 
            svgFeTurbulence("100",generateDecimalString(backHeadFrequency,3)),
            '<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="',toString(backHeadScale),'" xChannelSelector="G" yChannelSelector="A"/> </filter>',
            svgCircle("300","270",toString(140-radii), "none", "0", fill, "filter: url(#headDisplacement)")
        ));
    }

    // Layer 6 - Front Head
    // Hash Bytes Used - 13,14
    function generateFrontHead(bytes memory hash, uint colour3) public pure returns (string memory) {
        uint8 radii = toUint8(hash,0)/3;
        uint frontHeadFrequency = uint256(toUint8(hash,13))*1000/255; 
        uint frontHeadFrequency2 = uint256(toUint8(hash,14))*1000/255; // added in post. more variation.
        uint frontHeadScale = uint256(toUint8(hash,14))*400/255;
        uint saturation = 60 - uint256(toUint8(hash,30))*55/255;

        string memory fill = string(abi.encodePacked('hsl(',toString(colour3),', ',toString(saturation),'%, 50%)'));
        
        return string(abi.encodePacked(
            svgFilter("headDisplacement2"), 
            '<feTurbulence type="turbulence" seed="50" baseFrequency="',generateDecimalString(frontHeadFrequency,3),',',generateDecimalString(frontHeadFrequency2,3),'" numOctaves="5" result="turbulence"/>'
            '<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="',toString(frontHeadScale),'" xChannelSelector="G" yChannelSelector="R"/> </filter>',
            svgCircle("300","270",toString(120-radii), "none", "0", fill, "filter: url(#headDisplacement2)")
        ));
    }

    // Layer 7 - Rings
    // Hash Bytes Used - 15,16,17,18,19,20
    function generateRings(bytes memory hash) public pure returns (string memory) {
        string memory ring1 = generateRing(hash, "ringDisplacement1", 15, 16, "grey", "R", "filter: url(#ringDisplacement1)");        
        string memory ring2 = generateRing(hash, "ringDisplacement2", 17, 18, "black", "G", "filter: url(#ringDisplacement2)");        
        string memory ring3 = generateRing(hash, "ringDisplacement3", 19, 20, "black", "B", "filter: url(#ringDisplacement3)");        

        return string(abi.encodePacked(ring1, ring2, ring3));
    }

    function generateRing(bytes memory hash, string memory id, uint seedIndex1, uint seedIndex2, string memory stroke, string memory xChannel, string memory style) public pure returns (string memory) {
        uint8 radii = toUint8(hash,0)/3;
        uint ringSeed = uint256(toUint8(hash,seedIndex1))*1000/255;
        uint ringFrequency = uint256(toUint8(hash,seedIndex2))*1000/255;  

        return string(abi.encodePacked(
            svgFilter(id), 
            svgFeTurbulence(toString(ringSeed), generateDecimalString(ringFrequency,4)),
            '<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="200" xChannelSelector="',xChannel,'" yChannelSelector="A" /> </filter>',
            svgCircle("300","270",toString(140-radii),stroke,"4","none",style)
        ));
    }

    // Layer 8 - Eyes
    // Hash Bytes Used - 21
    function generateEyes(bytes memory hash) public pure returns (string memory) {
        uint eyesFrequency = uint256(toUint8(hash,21))*1000/255; 
        uint eyesRadius = 25 - uint256(toUint8(hash,21))*15/255; 

        string memory eyeDisplacement = string(abi.encodePacked(
            svgFilter("eyeDisplacement"),
            svgFeTurbulence("100", generateDecimalString(eyesFrequency,4)),
            '<feDisplacementMap in2="turbulence" in="SourceGraphic" scale="100" xChannelSelector="R" yChannelSelector="G"/></filter>'
        ));

        string memory eyes = string(abi.encodePacked(
            svgCircle("250","270",toString(eyesRadius),"black","1","white","filter: url(#eyeDisplacement)"),
            svgCircle("320","270",toString(eyesRadius),"black","1","white","filter: url(#eyeDisplacement)")
        ));

        return string(abi.encodePacked(eyeDisplacement,eyes));
    }

    function svgCircle(string memory cx, string memory cy, string memory r, string memory stroke, string memory strokeWidth, string memory fill, string memory style) public pure returns (string memory) {
        return string(abi.encodePacked(
            '<circle cx="',cx,'" cy="',cy,'" r="',r,'" stroke="',stroke,'" fill="',fill,'" stroke-width="',strokeWidth,'" style="',style,'"/>'
        ));
    }

    function svgFilter(string memory id) public pure returns (string memory) {
        return string(abi.encodePacked('<filter id="',id,'" width="300%" height="300%">'));
    }

    function svgFeTurbulence(string memory seed, string memory baseFrequency) public pure returns (string memory) {
        return string(abi.encodePacked(
            '<feTurbulence type="turbulence" seed="',seed,'" baseFrequency="',baseFrequency,'" numOctaves="5" result="turbulence"/>'
        ));
    }

    // helper function for generation
    // from: https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol 
    function toUint8(bytes memory _bytes, uint256 _start) internal pure returns (uint8) {
        require(_start + 1 >= _start, "toUint8_overflow");
        require(_bytes.length >= _start + 1 , "toUint8_outOfBounds");
        uint8 tempUint;

        assembly {
            tempUint := mload(add(add(_bytes, 0x1), _start))
        }
        return tempUint;
    }

        // from: https://raw.githubusercontent.com/OpenZeppelin/openzeppelin-contracts/master/contracts/utils/Strings.sol
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function generateDecimalString(uint nr, uint decimals) public pure returns (string memory) {
        if(decimals == 1) { return string(abi.encodePacked('0.',toString(nr))); }
        if(decimals == 2) { return string(abi.encodePacked('0.0',toString(nr))); }
        if(decimals == 3) { return string(abi.encodePacked('0.00',toString(nr))); }
        if(decimals == 4) { return string(abi.encodePacked('0.000',toString(nr))); }
    }

    // from: https://ethereum.stackexchange.com/questions/31457/substring-in-solidity/31470
    function substring(string memory str, uint startIndex, uint endIndex) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

