// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./Base64.sol";
import "./PonziRugsGenerator.sol";

contract FLOKIINU is ERC721, Ownable{    
    // Ruggening information
    uint256 public  MAX_SUPPLY          = 1250;
    uint256 public  GET_RUGGED_IN_ETHER = 0.06 ether;
    uint256 public  RUG_GIVEAWAY        = 16;
    uint256 public  totalSupply;
    
    // Ruggening toggle
    bool public hasRuggeningStarted = false;

    // Internal Rug crafting
    mapping(string => bool) isMinted;
    mapping(uint256 => uint256[]) idToCombination;

    constructor() ERC721("FLOKIINU", "FI") {}


    // The Ruggers
    function toggleRuggening() public onlyOwner 
    {
        hasRuggeningStarted = !hasRuggeningStarted;
    }

    function devRug(uint rugs) public onlyOwner 
    {
        require(totalSupply + rugs <= RUG_GIVEAWAY, "Exceeded giveaway limit");
        rugPull(rugs);
    }

    // The Ruggees
    function getRugged(uint256 rugs) public payable
    {
        require(hasRuggeningStarted,                        "The ruggening has not started");
        require(rugs > 0 && rugs <= 2,                      "You can only get rugged twice per transaction");   
        require(GET_RUGGED_IN_ETHER * rugs == msg.value,    "Ether Amount invalid to get rugged do: getRuggedInEther * rugs");
        rugPull(rugs);
    }
    
    function rugPull(uint256 rugPulls) internal 
    {
        require(totalSupply + rugPulls < MAX_SUPPLY);
        require(!PonziRugsGenerator.isTryingToRug(msg.sender));

        for (uint256 i; i < rugPulls; i++)
        {
            idToCombination[totalSupply] = craftRug(totalSupply);
            _mint(msg.sender, totalSupply);
            totalSupply++;
        }
    }

    function craftRug(uint256 seed) internal returns (uint256[] memory colorCombination)
    {
        uint256[] memory colors = new uint256[](5);
        colors[0] = random(seed) % 1000;
        for (uint8 i = 1; i < 4; i++)
        {
            seed++;
            colors[i] = random(seed) % 21;
        }
        string memory combination = string(abi.encodePacked(colors[0], colors[1], colors[2], colors[3]));
        if(isMinted[combination]) craftRug(seed + 1);
        isMinted[combination] = true;
        return colors;
    }

    function random(uint256 seed) internal view returns (uint256)
    {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty, msg.sender, seed)));
    }

    function tokenURI(uint256 tokenId) override public view returns (string memory) 
    {
        require(tokenId >= 0 && tokenId <= totalSupply, "Invalid token ID");
        // Get the PonziRug data and generated SVG
        PonziRugsGenerator.PonziRugsStruct memory rug;
        string memory svg;
        (rug, svg) = PonziRugsGenerator.getRugForSeed(idToCombination[tokenId]);
        
        string memory json = Base64.encode(bytes(string(abi.encodePacked(
            '{"name": "Ponzi Rugs #', Utils.uint2str(tokenId),
            '", "description": "Ever been rugged before? Good, Now you can do it on chain! No IPFS, no API, all images and metadata exist on the blockchain",',
            '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(svg)),'",', rug.metadata,'}'
        ))));    
        return string(abi.encodePacked('data:application/json;base64,', json));
    }
    function withdrawAll() public payable onlyOwner 
    {
        require(payable(msg.sender).send(address(this).balance));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
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
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
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

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
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
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
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
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
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
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
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

        _beforeTokenTransfer(address(0), to, tokenId);

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

        _beforeTokenTransfer(owner, address(0), tokenId);

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
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

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
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0;

/// @title Base64
/// @author Brecht Devos - <[email protected]>
/// @notice Provides functions for encoding/decoding base64
library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function encode(bytes memory data) internal pure returns (string memory) {
        if (data.length == 0) return '';

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

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}

//SPDX-License-Identifier: Unlicense
/// @title: PonziRugs library
/// @author: Rug Dev

pragma solidity ^0.8.0;

library PonziRugsGenerator {
    struct PonziRugsStruct 
    {
        uint pattern;
        uint background;
        uint colorOne;
        uint colorTwo;
        uint colorThree;
        bool set;
        string metadata;
        string combination;
    }

    struct RandValues {
        uint256 patternSelect;
        uint256 backgroundSelect;
    }

    function getRugForSeed(uint256[] memory combination) external pure returns (PonziRugsStruct memory, string memory)
    {
        PonziRugsStruct memory rug;
        RandValues memory rand;
        string[10] memory patterns = ["Ether", "Circles", "Hoots", "Scales", "Heart", "Squares", "Encore", "Kubrick", "Triangle", "NGMI"];
        
        string[21] memory colors =  ["deeppink", "darkturquoise", "orange", "gold", "white", "silver", "green", 
                                    "darkviolet", "orangered", "lawngreen", "mediumvioletred", "red", "olivedrab",
                                    "bisque", "cornsilk", "darkorange", "slateblue", "floralwhite", "khaki", "crimson", "thistle"];

        string[21] memory ngmiPalette = ["black", "red", "green", "blue", "maroon", "violet", "tan", "turquoise", "cyan", 
                                        "darkred", "darkorange", "crimson", "darkviolet", "goldenrod", "forestgreen", "lime", "magenta", 
                                        "springgreen", "teal", "navy", "indigo"];

        // Determine the Pattern for the rug
        rand.patternSelect = combination[0];

        if(rand.patternSelect < 1) rug.pattern = 9;
        else if (rand.patternSelect < 40)  rug.pattern = 8;
        else if (rand.patternSelect < 100) rug.pattern = 7;
        else if (rand.patternSelect < 160) rug.pattern = 6;
        else if (rand.patternSelect < 240) rug.pattern = 5;
        else if (rand.patternSelect < 340) rug.pattern = 4;
        else if (rand.patternSelect < 460) rug.pattern = 3;
        else if (rand.patternSelect < 580) rug.pattern = 2;
        else if (rand.patternSelect < 780) rug.pattern = 1;
        else  rug.pattern = 0;

        // Rug Traits
        rug.background  = combination[1];
        rug.colorOne    = combination[2];
        rug.colorTwo    = combination[3];
        rug.colorThree  = combination[4];
        rug.set         = (rug.colorOne == rug.colorTwo) && (rug.colorTwo == rug.colorThree);
        rug.combination = string(abi.encodePacked(Utils.uint2str(rug.pattern), Utils.uint2str(rug.background), Utils.uint2str(rug.colorOne), Utils.uint2str(rug.colorTwo) , Utils.uint2str(rug.colorThree)));

        // Build the SVG from various parts
        string memory svg = string(abi.encodePacked('<svg customPattern = "', Utils.uint2str(rug.pattern), '" xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 128 55" >'));

        //svg = string(abi.encodePacked(svg, id));
        string memory currentSvg = "";
        if(rug.pattern == 0)
        {
            //ETHERS
            currentSvg = string(abi.encodePacked('<pattern id="rug" viewBox="5.5,0,10,10" width="24%" height="20%"><polygon points="-10,-10 -10,30 30,30 30,-10" fill ="', colors[rug.background],'"/><polygon points="0,5 9,1 10,1 10,2 8,4 1,5 8,6 10,8 10,9 9,9 0,5"/><polygon points="10,5 13,1 14,1  21,5 14,9 13,9 10,5"/><polygon points="13.25,2.25 14.5,5 13.25,7.75 11,5" fill="', colors[rug.colorOne],'"/><polygon points="14.5,2.5 15.5,4.5 18.5,4.5" fill="', colors[rug.colorTwo],'"/><polygon points="18.5,5.5 15.5,5.5 14.5,7.5" fill="', colors[rug.colorThree],'"/><polygon points="18.5,5.5 15.5,5.5 14.5,7.5" transform="scale(-1,-1) translate(-35,-15)"/><polygon points="14.5,2.5 15.5,4.5 18.5,4.5" transform="scale(-1,-1) translate(-35,-5)"/><polygon points="13.25,2.25 14.5,5 13.25,7.75 11,5" transform="scale(-1,-1) translate(-35,-15)"/><polygon points="13.25,2.25 14.5,5 13.25,7.75 11,5" transform="scale(-1,-1) translate(-35,-5)"/><polygon points="2,5 10,5 13,9 10,9 8,6" transform="scale(-1,-1) translate(-9,-15)"/><polygon points="2,5 8,4 10,1 13,1 10,5" transform="scale(-1,-1) translate(-9,-5)"/><animate attributeName="x" from="0" to="2.4" dur="20s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="url(#rug)" stroke-width="3" stroke="black"/>'));
        }
        else if(rug.pattern == 1)
        {
            //CIRCLES
            string[3] memory parts = [
                string(abi.encodePacked
                (
                    '<pattern id="star" viewBox="0,0,12,12" width="11%" height="25%"><circle cx="12" cy="0" r="4" fill="', colors[rug.colorOne],'" stroke="black" stroke-width="1"/><circle cx="12" cy="0" r="2" fill="', colors[rug.colorThree],'" stroke="black" stroke-width="1"/><circle cx="0" cy="12" r="4" fill="', colors[rug.colorOne],'" stroke="black" stroke-width="1"/><circle cx="0" cy="12" r="2" fill="', colors[rug.colorThree],'" stroke="black" stroke-width="1"/>'
                )), 
                string(abi.encodePacked
                (
                    '<circle cx="6" cy="6" r="6" fill="', colors[rug.colorTwo],'" stroke="black" stroke-width="1"/><circle cx="6" cy="6" r="4" fill="', colors[rug.colorOne],'" stroke="black" stroke-width="1"/><circle cx="6" cy="6" r="2" fill="', colors[rug.background],'" stroke="black" stroke-width="1"/><circle cx="0" cy="0" r="6" fill="', colors[rug.colorTwo],'" stroke="black" stroke-width="1"/><circle cx="0" cy="0" r="4" fill="', colors[rug.colorOne],'" stroke="black" stroke-width="1"/><circle cx="0" cy="0" r="2" fill="', colors[rug.colorThree],'" stroke="black" stroke-width="1"/>'
                )),
                string(abi.encodePacked
                (
                    '<circle cx="12" cy="12" r="6" fill="', colors[rug.colorTwo],'" stroke="black" stroke-width="1"/><circle cx="12" cy="12" r="4" fill="', colors[rug.colorOne],'" stroke="black" stroke-width="1"/><circle cx="12" cy="12" r="2" fill="', colors[rug.colorThree],'" stroke="black" stroke-width="1"/><animate attributeName="x" from="0" to="1.1" dur="9s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="url(#star)" stroke="black" stroke-width="3"/>'
                ))
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0], parts[1]), parts[2]));
        }
        else if(rug.pattern == 2)
        {
            //HOOTS
            string[4] memory parts = [
                string(abi.encodePacked
                (
                    '<pattern id="e" viewBox="13,-1,10,15" width="15%" height="95%"><polygon points="-99,-99 -99,99 99,99 99,-99" fill ="', colors[rug.background],'"/> <g stroke="black" stroke-width="0.75"><polygon points="5,5 18,10 23,5 18,0" fill ="', colors[rug.colorTwo],'"/><polygon points="21,0 26,5 21,10 33,5" fill ="', colors[rug.colorThree],'"/> </g><animate attributeName="x" from="0" to="0.3" dur="2.5s" repeatCount="indefinite"/> </pattern>'
                )), 
                string(abi.encodePacked
                (
                    '<pattern id="h" viewBox="10,0,20,25" width="15%" height="107%"><polygon points="-99,-99 -99,99 99,99 99,-99" fill ="', colors[rug.background],'"/><polygon points="9,4 14,9 14,18 9,23 26,23 31,18 31,9 26,4" fill ="', colors[rug.colorOne],'" stroke="black" stroke-width="1"/><g fill ="', colors[rug.background],'" stroke="black" stroke-width="0.5"><circle cx="20" cy="10" r="2.5"/><circle cx="20" cy="17" r="2.5"/><polygon points="24,11 24,16 29,13.5"/></g><circle cx="20" cy="10" r="1.75" fill="black"/><circle cx="20" cy="17" r="1.75" fill="black"/>'
                )),
                string(abi.encodePacked
                (
                    '<animate attributeName="x" from="0" to="0.6" dur="5s" repeatCount="indefinite"/></pattern><pattern id="c" viewBox="13,4,10,20" width="15%" height="135%"><polygon points="-99,-99 -99,99 99,99 99,-99" fill="', colors[rug.background],'"/><polygon points="7,3 7,18 32,18 32,3" fill="black"/><polygon points="11,7 11,15 28,15 28,7" fill="', colors[rug.background],'"/><g fill="black" stroke="', colors[rug.background],'" stroke-width="1">'
                )),
                string(abi.encodePacked
                (
                    '<polygon points="-3,9 -3,13 16,13 16,9"/><polygon points="23,9 23,13 41,13 41,9"/></g><animate attributeName="x" from="2.4" to="0" dur="40s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="', colors[rug.background],'"/><rect x="0" y="2" width="128" height="9" fill="url(#e)"/><rect x="0" y="10" width="128" height="9" fill="url(#c)"/><rect x="0" y="19" width="128" height="15" fill="url(#h)"/><rect x="0" y="36.5" width="128" height="9" fill="url(#c)"/><rect x="0" y="46.25" width="128" height="9" fill="url(#e)"/><rect width="128" height="55" fill="transparent" stroke="black" stroke-width="3"/>'
                ))
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0], parts[1]), parts[2], parts[3]));
        }
        else if(rug.pattern == 3)
        {
            //SCALES
            string[3] memory parts = [
                string(abi.encodePacked
                (
                    '<linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" stop-color="', colors[rug.background],'"/><stop offset="100%" stop-color="', colors[rug.colorOne],'"/></linearGradient>'
                )), 
                string(abi.encodePacked
                (
                    '<pattern id="R" viewBox="0 0 16 16" width="11.4%" height="25%"><g fill="url(#grad1)" stroke-width="1" stroke="black"><polygon points="8,-2 26,-2 26,18 8,18"/><circle cx="8" cy="8" r="8"/><circle cx="0" cy="0" r="8"/><circle cx="0" cy="16" r="8"/><circle cx="8" cy="8" r="3" fill="', colors[rug.colorThree],'"/><circle cx="0" cy="0" r="3" fill="', colors[rug.colorTwo],'"/><circle cx="0" cy="16" r="3" fill="', colors[rug.colorTwo],'"/><circle cx="17" cy="0" r="3" fill="', colors[rug.colorTwo],'"/>'
                )),
                string(abi.encodePacked(
                    '<circle cx="17" cy="16" r="3" fill="', colors[rug.colorTwo],'"/></g><animate attributeName="x" from="0" to="0.798" dur="6.6s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="url(#R)" stroke-width="3" stroke="black"/>'
                ))
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0], parts[1]), parts[2]));
        }
        else if(rug.pattern == 4)
        {
            //HEART
            currentSvg = string(abi.encodePacked('<pattern id="star" viewBox="5.5,-50,100,100" width="25%" height="25%"><g stroke="black" stroke-width="2"><polygon points="-99,-99 -99,99 999,99 999,-99" fill ="', colors[rug.background],'"/> <polygon points="0,-50 -60,-15.36 -60,-84.64" fill="', colors[rug.colorOne],'"/><polygon points="0,50 -60,84.64 -60,15.36" fill="', colors[rug.colorOne],'"/><circle cx="120" cy="0" r="30" fill ="', colors[rug.colorTwo],'" /><path fill="', colors[rug.colorThree],'" id="star" d="M0,0 C37.5,62.5 75,25 50,0 C75,-25 37.5,-62.5 0,0 z"/></g><g transform="translate(0,40)" id="star"></g><animate attributeName="x" from="0" to="0.5" dur="4.1s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="url(#star)" stroke="black" stroke-width="3"/>'));
        }
        else if(rug.pattern == 5)
        {
            //SQUARES
            string[2] memory parts = [
                string(abi.encodePacked
                (
                    '<pattern id="moon" viewBox="0,-0.5,10,10" width="100%" height="100%"><rect width="10" height="10" fill="', colors[rug.colorOne],'" stroke="black" stroke-width="2" transform="translate(0.05,-0.5)"/><rect width="5" height="5" stroke="', colors[rug.colorTwo],'" fill="', colors[rug.colorOne],'" transform="translate(2.5,2)"/><rect width="4" height="4" stroke="black" fill="', colors[rug.colorOne],'" transform="translate(3,2.5)" stroke-width="0.3"/>'
                )), 
                string(abi.encodePacked
                (
                    '<rect width="6" height="6" stroke="black" fill="none" transform="translate(2,1.5)" stroke-width="0.3"/><circle cx="5" cy="4.5" r="1" stroke="', colors[rug.colorTwo],'" fill="', colors[rug.colorThree],'"/><g stroke="black" stroke-width="0.3" fill="none"><circle cx="5" cy="4.5" r="1.5"/><circle cx="5" cy="4.5" r="0.5"/> </g></pattern><pattern id="star" viewBox="7,-0.5,7,10" width="17%" height="20%"><g fill="url(#moon)" stroke="', colors[rug.background],'"><rect width="10" height="10" transform="translate(0,-0.5)"/><rect width="10" height="10" transform="translate(10,4.5)"/><rect width="10" height="10" transform="translate(10,-5.5)"/></g><animate attributeName="x" from="0" to="0.17" dur="1.43s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="url(#star)" stroke-width="3" stroke="black"/>'
                ))
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0], parts[1])));
        }
        else if(rug.pattern == 6)
        {
            //ENCORE
            string[3] memory parts = [
                string(abi.encodePacked
                (
                    '<radialGradient id="a" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" stop-color="', colors[rug.background],'" stop-opacity="1" /><stop offset="100%" stop-color="', colors[rug.colorOne],'" stop-opacity="1" /></radialGradient><radialGradient id="b" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" stop-color="', colors[rug.colorTwo],'" stop-opacity="1" /><stop offset="100%" stop-color="', colors[rug.colorThree],'" stop-opacity="1" /></radialGradient>'
                )), 
                string(abi.encodePacked
                (
                    '<pattern id="R" viewBox="0 0 16 16" width="13.42%" height="33%"><g stroke-width="1" stroke="black" fill="url(#a)"><circle cx="16" cy="16" r="8"/><circle cx="16" cy="14.9" r="6"/><circle cx="16" cy="13" r="4"/><circle cx="16" cy="12" r="2"/><circle cx="0" cy="16" r="8"/><circle cx="0" cy="14.9" r="6"/><circle cx="0" cy="13" r="4"/><circle cx="0" cy="12" r="2"/><circle cx="8" cy="8" r="8" fill="url(#b)"/><circle cx="8" cy="6.5" r="6" fill="url(#b)"/><circle cx="8" cy="5" r="4" fill="url(#b)"/><circle cx="8" cy="4" r="2" fill="url(#b)"/><circle cx="16" cy="0" r="8"/><circle cx="16" cy="-2" r="6"/>'
                )),
                string(abi.encodePacked
                (
                    '<circle cx="16" cy="-3.9" r="4"/><circle cx="0" cy="0" r="8"/><circle cx="0" cy="-2" r="6"/><circle cx="0" cy="-3.9" r="4"/></g><animate attributeName="x" from="0" to="0.4025" dur="3.35s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="url(#R)" stroke-width="3" stroke="black"/>'
                ))
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0], parts[1]), parts[2]));
        }
        else if(rug.pattern == 7)
        {
            //Kubrik
            string[3] memory parts = [
                string(abi.encodePacked
                (
                    '<linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="0%"><stop offset="0%" stop-color="', colors[rug.colorOne],'" stop-opacity="1" /><stop offset="100%" stop-color="', colors[rug.colorTwo],'" stop-opacity="1" /></linearGradient><polygon points="0,0 0,55 128,55 128,0" fill ="url(#grad1)"/>    <pattern id="star" viewBox="5,-2.9,16,16" width="12%" height="20%">'
                )), 
                string(abi.encodePacked
                (
                    '<polygon points="13,6 10.5,10 5.5,10 2.5,5 5.5,0 10.5,0 13,4 21,4 26,-5 28,-5 22.5,5 29,17 27,17 21,6" fill="', colors[rug.background],'" stroke="black" stroke-width="0.3"/>    <polygon points="5,0 10,0 13,5 10,10 5,10 2,5" fill="', colors[rug.colorThree],'" stroke="black" stroke-width="0.6" transform="translate(4.3 2.5) scale(0.5 0.5)"/>    <polygon points="21,6 12.5,6 10,10 5,10 2,5 5,0 10,0 12.5,4 20.5,4 25.5,-5 28,-5 22,5" transform="translate(24.5 8) scale(-1,1)" fill="', colors[rug.background],'" stroke="black" stroke-width="0.3"/>'
                )),
                string(abi.encodePacked
                (
                    '<polygon points="5,0 10,0 13,5 10,10 5,10 2,5" fill="', colors[rug.colorThree],'" stroke="black" stroke-width="0.6" transform="translate(13.3 10.5) scale(0.5 0.5)"/>      <polygon points="20.5,6 12.5,6 10,10 5,10 2,5 5,0 10,0 12.5,4 21,4 22,5 28,17 26.5,17" transform="translate(24.5 -8) scale(-1,1)" fill="', colors[rug.background],'" stroke="black" stroke-width="0.3"/>     <polygon points="5,0 10,0 13,5 10,10 5,10 2,5" fill="', colors[rug.colorThree],'" stroke="black" stroke-width="0.6" transform="translate(13.3 -5.5) scale(0.5 0.5)"/>    <animate attributeName="x" from="0" to="1.2" dur="9.8s" repeatCount="indefinite"/>    </pattern><rect width="128" height="55" fill="url(#star)" stroke="black" stroke-width="3"/>'
                ))
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0], parts[1]), parts[2]));
        }
        else if(rug.pattern == 8)
        {
            //TRIANGLES
            string[2] memory parts = [
                string(abi.encodePacked
                (
                    '<polygon points="0,0 128,0 128,55 0,55" fill="', colors[rug.background],'"/><pattern id="R" viewBox="0 0 20 24" width="11.8%" height="33%"><g stroke-width="0.3" stroke="black"><polygon points="0,24 10,18 10,30" fill="', colors[rug.colorOne],'"/><polygon points="0,0 10,6 10,-6" fill="', colors[rug.colorOne],'"/><polygon points="10,6 20,12 20,0" fill="', colors[rug.colorTwo],'"/>'
                )), 
                string(abi.encodePacked
                (
                    '<polygon points="3,6 13,12 3,18" fill="', colors[rug.colorThree],'"/><polygon points="-7,12 3,18 -7,24" fill="', colors[rug.colorOne],'"/><polygon points="23,18 13,24 13,12" fill="', colors[rug.colorOne],'"/></g><animate attributeName="x" from="0" to="0.7085" dur="5.9s" repeatCount="indefinite"/></pattern><rect width="128" height="55" fill="url(#R)" stroke-width="3" stroke="black"/>'
                ))
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0], parts[1])));
        }
        else if(rug.pattern == 9)
        {   
            rug.background  = combination[1];
            rug.colorOne    = combination[2];
            rug.colorTwo    = combination[3];
            rug.colorThree  = combination[4];
            rug.set         = (rug.colorOne == rug.colorTwo) && (rug.colorTwo == rug.colorThree);
            rug.combination = string(abi.encodePacked(Utils.uint2str(rug.pattern), Utils.uint2str(rug.background), Utils.uint2str(rug.colorOne), Utils.uint2str(rug.colorTwo) , Utils.uint2str(rug.colorThree)));
            string[1] memory parts = [
                string(abi.encodePacked
                (
                    '<pattern id="star" viewBox="5.5,-50,100,100" width="40%" height="50%"><polygon points="-100,-100 -100,300 300,300 300,-100" fill="white"/> <polyline points="11 1,7 1,7 5,11 5,11 3, 10 3" fill="none" stroke="', ngmiPalette[rug.background],'"/><polyline points="1 5,1 1,5 5,5 1" fill="none" stroke="', ngmiPalette[rug.colorOne],'"/><polyline points="13 5,13 1,15 3,17 1, 17 5" fill="none" stroke="', ngmiPalette[rug.colorTwo],'"/><polyline points="19 1, 23 1, 21 1, 21 5, 19 5, 23 5" fill="none" stroke="', ngmiPalette[rug.colorThree],'"/><animate attributeName="x" from="0" to="0.4" dur="3s" repeatCount="indefinite"/>   </pattern>  <rect width="128" height="55" fill="url(#star)" stroke="black" stroke-width="3"/>'
                ))
            ];
            currentSvg = string(abi.encodePacked(abi.encodePacked(parts[0])));
        }
    
        svg = string(abi.encodePacked(svg, currentSvg));
        svg = string(abi.encodePacked(svg, '</svg>'));

        // Keep track of each pn So we can add a trait for each color
        string memory traits = string(abi.encodePacked('"attributes": [{"trait_type": "Pattern","value":"', patterns[rug.pattern],'"},'));
        if(rug.set)
            traits = string(abi.encodePacked(traits, string(abi.encodePacked('{"trait_type": "Set","value":"True"},'))));
        string memory traits2 = string(abi.encodePacked('{"trait_type": "Background","value":"', colors[rug.background],'"},{"trait_type": "Color One","value": "', colors[rug.colorOne],'"},{"trait_type": "Color Two","value": "', colors[rug.colorTwo],'"},{"trait_type": "Color Three","value": "', colors[rug.colorThree],'"},'));
        string memory traits3 = string(abi.encodePacked('{"trait_type": "Combination","value": "', Utils.uint2str(rug.pattern),'-',Utils.uint2str(rug.background),'-',Utils.uint2str(rug.colorOne),'-',Utils.uint2str(rug.colorTwo),'-',Utils.uint2str(rug.colorThree),'"}]'));
        string memory allTraits = string(abi.encodePacked(traits,traits2,traits3));
        rug.metadata = allTraits;

        return (rug, svg);
    }

    function isTryingToRug(address account) internal view returns (bool) 
    {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
library Utils 
{
    function uint2str(uint256 _i) internal pure returns (string memory str)
    {
        if (_i == 0)
        {
            return "0";
        }
        
        uint256 j = _i;
        uint256 length;
        
        while (j != 0)
        {
            length++;
            j /= 10;
        }
        
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        j = _i;
        
        while (j != 0)
        {
            bstr[--k] = bytes1(uint8(48 + j % 10));
            j /= 10;
        }
        
        str = string(bstr);
        
        return str;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

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
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
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
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721.sol";

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
        assembly {
            size := extcodesize(account)
        }
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

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
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
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
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
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
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
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

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
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165.sol";

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