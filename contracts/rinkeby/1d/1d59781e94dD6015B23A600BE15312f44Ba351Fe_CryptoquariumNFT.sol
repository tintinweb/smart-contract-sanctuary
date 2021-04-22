// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import {Utils} from "./libs/Utils.sol";
import {AbstractFish} from "./fish/AbstractFish.sol";
import {IFishMarketplace} from "./fish/IFishMarketplace.sol";

contract CryptoquariumNFT is AbstractFish {
    constructor() AbstractFish("Cryptoquarium Fish", Utils.bytes32ToString(hex'01F41F')) {
    }

    function mintMultiple(uint8 count, string memory artist) external {
        address to = marketplace;
        if (to == address(0)) {
            to = _msgSender();
        }

        _mintMultiple(to, count, artist);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

import {ByArtist} from "./Artist.sol";
import {IFishNFT} from "./IFishNFT.sol";
import {IFishMarketplace} from "./IFishMarketplace.sol";
import {AbstractFishMarketplace} from "./AbstractFishMarketplace.sol";

import {EIP2309} from "./ERC721ConsecutiveTransfer.sol";
import {Utils} from "../libs/Utils.sol";

abstract contract AbstractFish is IFishNFT, EIP2309, Ownable, ByArtist {
    address public marketplace;

    mapping(uint => string) fish_name;
    mapping(uint => string) fish_image;
    mapping(uint => string) fish_artist;

    mapping(string => uint) artist_fish;
    mapping(uint => bool) fish_locked;

    // Image hash to verify FishNFT image validity
    bool initialized = false;
    uint nextFishId = 3735928495;

    modifier isMarketplace() {
        require(_msgSender() == marketplace, "Not Allowed!");
        _;
    }
    modifier canChangeNameOrURI(uint fishId) {
        address sender = _msgSender();
        require(sender == owner() || _isApprovedOrOwner(sender, fishId), "Not Allowed!");

        _;
    }

    constructor (string memory name_, string memory symbol_) EIP2309(name_, symbol_) {}

    function setMarketplace(address _marketplace) external onlyOwner {
        marketplace = _marketplace;
        _setAlwaysApproved(_marketplace);
    }

    // --[ Internal Methods ]--
    function setBaseURI(string memory _uri) public onlyOwner {
        _setBaseURI(_uri);
    }

    function _mintNoEvent(address to, uint256 fishId, string memory artist) internal {
        _mintNoEvent(to, fishId);
        fish_artist[fishId] = artist;
    }

    function _mint(address to, uint256 fishId, string memory artist) internal {
        _mint(to, fishId);
        fish_artist[fishId] = artist;
    }

    function _mintMultiple(address to, uint256 count, string memory artist) internal {
        uint fishId;
        bool _isMarket = to == marketplace;

        for (fishId = nextFishId; fishId < nextFishId + count - 1; fishId++) {
            ownerOf[fishId] = to;
            fish_artist[fishId] = artist;
            fish_locked[fishId] = _isMarket;
            _tokenURIs[fishId] = Utils.uint2str(fishId);
        }
        balanceOf[to] += count;
        artist_fish[artist] += count;

        emit ConsecutiveTransfer(nextFishId, fishId, address(0), to);
        if (_isMarket) {
            IFishMarketplace(marketplace).sellMultiple(nextFishId, fishId);
            try IFishMarketplace(marketplace).sellMultiple(nextFishId, fishId) {
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("FISH: Is Not IFishMarketplace!");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        }

        nextFishId = fishId + 1;
    }

    function setFishName(uint fishId, string memory name) external canChangeNameOrURI(fishId) {
        fish_name[fishId] = name;
    }

    function fishName(uint fishId) external view returns (string memory name) {
        name = fish_name[fishId];

        if (bytes(name).length == 0) {
            name = Utils.uint2str(fishId);
        }
    }

    function unlockAndTransfer(address buyer, uint fishId) external override isMarketplace {
        unlock(fishId);
        safeTransferFrom(ownerOf[fishId], buyer, fishId, "");
    }

    function artist(uint fishId) external override view returns (ByArtist.Artist memory) {
        return artists[Utils.stringToBytes32(fish_artist[fishId])];
    }

    function lock(uint fishId) isMarketplace external override {
        fish_locked[fishId] = true;
    }

    function unlock(uint fishId) isMarketplace public override {
        delete fish_locked[fishId];
    }

    function fishLocked(uint fishId) external override view returns(bool) {
        return fish_locked[fishId];
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override virtual {
        require(!fish_locked[tokenId], "Fish is locked on the Marketplace");
    }

    function setTokenURI(uint fishId, string memory tokenURI) external canChangeNameOrURI(fishId) {
        _setTokenURI(fishId, tokenURI);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./IFishMarketplace.sol";
import "./IFishNFT.sol";

abstract contract AbstractFishMarketplace is IFishMarketplace, Ownable {
    uint internal percentsFee = 10;
    uint internal defaultPrice = 1 ether;
    mapping(uint => Lot) public lots;
    IFishNFT fishNFT;

    modifier fishOwnerOrApproved(uint fishId) {
        address spender = _msgSender();
        address owner = fishNFT.ownerOf(fishId);

        require(address(fishNFT) == spender || spender == owner
        || fishNFT.getApproved(fishId) == spender
            || fishNFT.isApprovedForAll(owner, spender), "Not Allowed!");

        _;
    }

    modifier isFish() {
        require(address(fishNFT) == _msgSender(), "Not Allowed!");

        _;
    }

    constructor(uint _percentsFee, uint _defaultPrice, address _fishNFT) {
        percentsFee = _percentsFee;
        defaultPrice = _defaultPrice;
        fishNFT = IFishNFT(_fishNFT);
    }

    function buy(uint fishId) payable external {
        address payable buyer = payable(_msgSender());
        Lot memory lot = lots[fishId];
        uint amount = msg.value;
        uint price = lot.price - lot.feeAmount;

        require(amount >= price, "Not enough sent");

        ByArtist.Artist memory artist = fishNFT.artist(fishId);

        address from = lot.seller;
        address payable paymentTo = payable(lot.seller);
        if (from == address(0)) {
            // Selling from the platform
            from = address(this);
            paymentTo = artist.paymentsAddress;
        }

        delete lots[fishId];

        // transfers at the end
        paymentTo.transfer(price);
        artist.feeCollectionAddress.transfer(amount - price);
        fishNFT.unlockAndTransfer(buyer, fishId);
    }

    function sell(uint fishId, uint price) fishOwnerOrApproved(fishId) public {
        Lot storage lot = lots[fishId];
        lot.fishId = fishId;
        lot.seller = _msgSender() == address(fishNFT) ? address(0) : _msgSender();
        lot.feeAmount = price * percentsFee / 100;
        lot.price = price + lot.feeAmount;

        emit FishSelling(fishId, lot.price);
        fishNFT.lock(fishId);
    }

    function cancelSelling(uint fishId) fishOwnerOrApproved(fishId) public {
        Lot storage lot = lots[fishId];
        require(lot.seller == _msgSender(), "Not a seller");

        emit FishNoLongerForSale(fishId);
        fishNFT.unlock(fishId);
    }

    function sellMultiple(uint fishIdFrom, uint fishIdTo) isFish external override {
        uint price = defaultPrice;

        for (uint fishId = fishIdFrom; fishId < fishIdTo; ++fishId) {
            Lot storage lot = lots[fishId];
            lot.fishId = fishId;
            lot.seller = address(0);
            lot.price = price;
        }

        emit ConsecutiveFishSelling(fishIdFrom, fishIdTo, price);
    }

    function setDefaultPrice(uint _defaultPrice) onlyOwner external {
        defaultPrice = _defaultPrice;
    }

    function setPercentsFee(uint _percentsFee) onlyOwner external {
        percentsFee = _percentsFee;
    }

    // -=[ IERC721Receiver implementation ]=-
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data)
    external override returns (bytes4) {
        sell(tokenId, defaultPrice);
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../libs/Utils.sol";

abstract contract ByArtist is Ownable {
    struct Artist {
        bytes32 name;
        address payable paymentsAddress;
        address payable feeCollectionAddress;
    }

    mapping(bytes32 => Artist) artists;

    function updateArtist(string memory name, address payable paymentsAddress, address payable feeCollectionAddress)
    onlyOwner public {
        bytes32 _name = Utils.stringToBytes32(name);

        Artist storage artist = artists[_name];
        artist.name = _name;
        artist.feeCollectionAddress = feeCollectionAddress;
        artist.paymentsAddress = paymentsAddress;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IEIP2309 {
    event ConsecutiveTransfer(
        uint256 indexed fromTokenId,
        uint256 toTokenId,
        address indexed fromAddress,
        address indexed toAddress
    );
}

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

abstract contract EIP2309 is IEIP2309, IERC721, IERC721Metadata, Context {
    using Strings for uint256;
    using Address for address;
    string private baseUri;
    address alwaysApproved;

    // Optional mapping for token URIs
    mapping(uint256 => string) internal _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721URIStorage: URI query for nonexistent token");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return bytes(base).length > 0
        ? string(abi.encodePacked(base, tokenId.toString()))
        : '';
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }


    string public override name;
    string public override symbol;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) {
        name = name_;
        symbol = symbol_;
    }

    function _mintMultiple(address to, uint256 id_from, uint256 id_to) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(id_from), "ERC721: token already minted");

        for (uint tokenId = id_from; tokenId <= id_to; tokenId++) {
            _beforeTokenTransfer(address(0), to, tokenId);
            balanceOf[to] += 1;
            ownerOf[tokenId] = to;
        }

        emit ConsecutiveTransfer(id_from, id_to, address(0), to);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}

    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf[tokenId];

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        balanceOf[owner] -= 1;
        delete ownerOf[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        _mintNoEvent(to, tokenId);

        emit Transfer(address(0), to, tokenId);
    }

    function _mintNoEvent(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        balanceOf[to] += 1;
        ownerOf[tokenId] = to;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC721Metadata).interfaceId
        || interfaceId == type(IERC721).interfaceId;
    }

    mapping(address => uint) public override balanceOf;
    mapping(uint => address) public override ownerOf;
    mapping(uint => address) public override getApproved;

    // --[ IERC721 ]--
    function safeTransferFrom(address from, address to, uint256 tokenId) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        if (spender == alwaysApproved) {
            return true;
        }
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf[tokenId];
        return (spender == owner || getApproved[tokenId] == spender || isApprovedForAll(owner, spender));
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return ownerOf[tokenId] != address(0);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf[tokenId] == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        balanceOf[from] -= 1;
        balanceOf[to] += 1;
        ownerOf[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf[tokenId];
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        getApproved[tokenId] = to;
        emit Approval(ownerOf[tokenId], to, tokenId);
    }

    //noinspection NoReturn
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
    internal returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
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

    function transferFrom(address from, address to, uint256 tokenId) external virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function _baseURI() internal view virtual returns (string memory) {
        return baseUri;
    }

    function _setBaseURI(string memory _uri) internal virtual {
        baseUri = _uri;
    }

    function _setAlwaysApproved(address a) internal virtual {
        alwaysApproved = a;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IFishMarketplace is IERC721Receiver {
    // --[ Events ]--
    event ConsecutiveFishSelling(uint indexed fromFishId, uint toFishId, uint price);
    event FishSelling(uint indexed fishId, uint price);
    event FishBought(uint indexed fishId, uint value, address indexed fromAddress, address indexed toAddress);
    event FishNoLongerForSale(uint indexed fishId);

    struct Lot {
        uint fishId;
        uint price;
        uint feeAmount;
        address seller;
    }

    function sellMultiple(uint fishIdFrom, uint fishIdTo) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "./Artist.sol";

interface IFishNFT is IERC721, IERC721Metadata {
    struct Fish {
        string name;
        uint tokenId;
        string artist;
        string image;
    }

    // --[ Methods ]--
    function artist(uint fishId) external view returns (ByArtist.Artist memory);
    function lock(uint fishId) external;
    function unlock(uint fishId) external;
    function unlockAndTransfer(address buyer, uint fishId) external;
    function fishLocked(uint fishId) external view returns(bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

library Utils {
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
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
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function concat(string memory s1, string memory s2)
    internal pure returns (string memory) {
        return string(abi.encodePacked(s1, s2));
    }

    function concat(string memory s1, string memory s2, string memory s3)
    internal pure returns (string memory) {
        return string(abi.encodePacked(s1, s2, s3));
    }

    function concat(string memory s1, string memory s2, string memory s3, string memory s4)
    internal pure returns (string memory) {
        return string(abi.encodePacked(s1, s2, s3, s4));
    }

    function concat(string memory s1,
        string memory s2,
        string memory s3,
        string memory s4,
        string memory s5
    ) internal pure returns (string memory) {
        return string(abi.encodePacked(s1, s2, s3, s4, s5));
    }

    function stringToBytes32(string memory source) internal pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }
        assembly {
            result := mload(add(source, 32))
        }
    }

    function bytes32ToString(bytes32 _bytes32) public pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
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

{
  "remappings": [],
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "evmVersion": "istanbul",
  "libraries": {
    "/Users/ilyk/projects/midgardtech/FishNFT/contracts/libs/Utils.sol": {
      "Utils": "0x24DD4cB66Ef60B918149c5731Ac3630AB7fa00fb"
    }
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}