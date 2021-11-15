// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import {StringUtils, UintUtils} from "./Utils.sol";

contract RocketComponent is ERC721, Ownable {
    using UintUtils for uint256;
    using StringUtils for string;

    modifier onlyOwnerOrAdmin() {
        require(
            owner() == _msgSender() || adminAddress == _msgSender(),
            "Ownable: caller is not the owner nor the admin"
        );

        _;
    }

    struct ComponentModel {
        string brand;
        uint256 from;
        uint256 to;
    }

    struct ComponentView {
        uint256 tokenId;
        string componentType;
        string brand;
        string imageLink;
        bool hasSticker;
        string sticker;
        string serialNumber;
        uint256 edition;
        uint256 total;
    }

    struct ComponentSticker {
        uint256 tokenId;
        uint256 stickerId;
    }

    uint256 private supply;

    uint256 private claimPrice;

    uint256 private earlyAccessStartDate;

    uint256 private claimStartDate;

    uint16 private maxClaimsPerAddress;

    string private baseURI;

    string private ipfsBaseURI;

    address private rocketFactoryContract;

    address private testFlightCrewContract;

    address private adminAddress;

    uint16[] private availableComponents;

    string[] private stickers;

    ComponentModel[] private componentModels;

    mapping(uint256 => bool) private burnedTokens;

    // tokenId -> stickerId
    mapping(uint256 => uint256) private componentStickers;

    mapping(address => uint16) private claimedComponentsPerAddress;

    /**
     * @dev Throws if called by any account other than the Rocket Contract.
     */
    modifier onlyRocketFactory() {
        require(
            msg.sender == rocketFactoryContract,
            "Ownable: caller is not the rocket factory contract"
        );
        _;
    }

    constructor() ERC721("Tom Sachs Rocket Components", "TSRC") {
        // since 0 is the default value for unset in Solidity, create the first sticker as "none"
        // to allow to use the componentStickers map
        stickers.push("none");
    }

    // ONLY OWNER functions

    /**
     * @dev Sets the claim price.
     */
    function setClaimPrice(uint256 _claimPrice) external onlyOwnerOrAdmin {
        claimPrice = _claimPrice;
    }

    /**
     * @dev Allows to withdraw the Ether in the contract.
     */
    function withdraw() external onlyOwnerOrAdmin {
        payable(msg.sender).transfer(address(this).balance);
    }

    /**
     * @dev Sets the data for the components
     */
    function addComponents(ComponentModel[] memory _components)
        external
        onlyOwnerOrAdmin
    {
        for (uint256 i; i < _components.length; i++) {
            componentModels.push(_components[i]);
        }
    }

    /**
     * @dev Adds tokenIds to the list of tokens that can be claimed by
     * users using the claim function.
     */
    function addAvailableComponents(uint16[] memory _availableComponents)
        external
        onlyOwnerOrAdmin
    {
        for (uint256 i; i < _availableComponents.length; i++) {
            availableComponents.push(_availableComponents[i]);
        }
    }

    /**
     * @dev Removes a tokenId from the list of tokens that can be claimed by
     * users using the claim function.
     */
    function removeFromAvailableComponents(uint16 tokenId)
        external
        onlyOwnerOrAdmin
    {
        for (uint256 i; i < availableComponents.length; i++) {
            if (availableComponents[i] != tokenId) {
                continue;
            }

            availableComponents[i] = availableComponents[
                availableComponents.length - 1
            ];
            availableComponents.pop();

            break;
        }
    }

    /**
     * @dev Removes all tokenIds from the list of tokens that can be claimed by
     * users using the claim function.
     */
    function resetAvailableComponents() external onlyOwnerOrAdmin {
        delete availableComponents;
    }

    /**
     * @dev Returns a list with all the available components that can be claimed by
     * users using the claim function.
     */
    function getAvailableComponents()
        external
        view
        onlyOwnerOrAdmin
        returns (uint16[] memory)
    {
        return availableComponents;
    }

    /**
     * @dev Returns whether or not a tokenId is in the available compoenents list.
     */
    function isInAvailableComponents(uint256 tokenId)
        external
        view
        onlyOwnerOrAdmin
        returns (bool)
    {
        for (uint256 i; i < availableComponents.length; i++) {
            if (availableComponents[i] == tokenId) {
                return true;
            }
        }

        return false;
    }

    /**
     * @dev Sets the base URI for IPFS.
     */
    function setIpfsBaseURI(string memory _ipfsBaseURI)
        external
        onlyOwnerOrAdmin
    {
        ipfsBaseURI = _ipfsBaseURI;
    }

    /**
     * @dev Sets the base URI for the API that provides the NFT data.
     */
    function setBaseTokenURI(string memory _uri) external onlyOwnerOrAdmin {
        baseURI = _uri;
    }

    /**
     * @dev Sets the address of the Rocket Factory contract.
     */
    function setRocketFactoryContract(address _address)
        external
        onlyOwnerOrAdmin
    {
        rocketFactoryContract = _address;
    }

    /**
     * @dev Sets the address of the Test Flight Crew Contract.
     */
    function setTestFlightCrewContract(address _address)
        external
        onlyOwnerOrAdmin
    {
        testFlightCrewContract = _address;
    }

    /**
     * @dev Returns the address of the Rocket Factory contract.
     */
    function getRocketFactoryContract()
        external
        view
        onlyOwnerOrAdmin
        returns (address)
    {
        return rocketFactoryContract;
    }

    /**
     * @dev Returns the address of the Test Flight Crew Contract.
     */
    function getTestFlightCrewContract()
        external
        view
        onlyOwnerOrAdmin
        returns (address)
    {
        return testFlightCrewContract;
    }

    /**
     * @dev Onwer only claim function that allows to mint tokens and send them to a given address.
     */
    function ownerClaim(uint256[] memory tokenIds, address to)
        external
        onlyOwnerOrAdmin
    {
        for (uint256 i; i < tokenIds.length; i++) {
            mint(to, tokenIds[i]);
        }
    }

    /**
     * @dev Adds new stickers into the contract.
     */
    function addStickers(string[] memory _stickers) external onlyOwnerOrAdmin {
        for (uint256 i; i < _stickers.length; i++) {
            stickers.push(_stickers[i]);
        }
    }

    /**
     * @dev Adds an sticker to a compoenent.
     */
    function addComponentStickers(ComponentSticker[] memory _componentStickers)
        external
        onlyOwnerOrAdmin
    {
        for (uint256 i; i < _componentStickers.length; i++) {
            componentStickers[
                _componentStickers[i].tokenId
            ] = _componentStickers[i].stickerId;
        }
    }

    /**
     * @dev Sets the start datetime to allow claims.
     */
    function setClaimStartDate(uint256 _claimStartDate)
        external
        onlyOwnerOrAdmin
    {
        claimStartDate = _claimStartDate;
    }

    /**
     * @dev Sets the start datetime to allow early access claims.
     */
    function setEarlyAccessStartDate(uint256 _earlyAccessStartDate)
        external
        onlyOwnerOrAdmin
    {
        earlyAccessStartDate = _earlyAccessStartDate;
    }

    /**
     * @dev Sets the maximum amount of components that an address can claim
     */
    function setMaxClaimsPerAddress(uint16 _maxClaimsPerAddress)
        external
        onlyOwnerOrAdmin
    {
        maxClaimsPerAddress = _maxClaimsPerAddress;
    }

    /**
     * @dev Sets the admin address for the contract
     */
    function setAdminAddress(address _adminAddress) external onlyOwnerOrAdmin {
        adminAddress = _adminAddress;
    }

    // END ONLY OWNER functions

    // ONLY Rocket Factory functions

    /**
     * @dev Burns rocket components when a rocket is minted. Only can be called by the Rocket Factory contract.
     */
    function burn(
        address _owner,
        uint256 _noseId,
        uint256 _bodyId,
        uint256 _tailId
    ) external onlyRocketFactory {
        require(
            ownerOf(_noseId) == _owner &&
                ownerOf(_bodyId) == _owner &&
                ownerOf(_tailId) == _owner,
            "Invalid owner for given components"
        );

        require(
            _noseId % 3 == 0 && _bodyId % 3 == 1 && _tailId % 3 == 2,
            "Invalid components given"
        );

        _burn(_noseId);
        _burn(_bodyId);
        _burn(_tailId);

        burnedTokens[_noseId] = true;
        burnedTokens[_bodyId] = true;
        burnedTokens[_tailId] = true;

        supply -= 3;
    }

    // END ONLY Rocket Factory functions

    /**
     * @dev Allows to randomly claim an available Component.
     */
    function claim(uint16 amount) external payable {
        require(amount > 0, "At least one component should be claimed");

        require(
            availableComponents.length > 0,
            "No components left to be claimed"
        );

        IERC721 token = IERC721(testFlightCrewContract);
        require(
            (claimStartDate != 0 && claimStartDate <= block.timestamp) ||
                (earlyAccessStartDate <= block.timestamp &&
                    token.balanceOf(msg.sender) > 0),
            "It is not time yet to start claiming"
        );

        require(
            claimedComponentsPerAddress[msg.sender] + amount <=
                maxClaimsPerAddress,
            "You cannot claim more components"
        );

        require(
            msg.sender == tx.origin,
            "Claim can only be called from a wallet"
        );

        if (amount > availableComponents.length) {
            amount = uint16(availableComponents.length);
        }

        uint256 totalClaimPrice = claimPrice * amount;

        require(msg.value >= totalClaimPrice, "Insufficient Ether to claim");

        if (msg.value > totalClaimPrice) {
            payable(msg.sender).transfer(msg.value - totalClaimPrice);
        }

        claimedComponentsPerAddress[msg.sender] += amount;

        for (uint256 i; i < amount; i++) {
            uint256 random = _getRandomNumber(availableComponents.length);
            uint256 tokenId = uint256(availableComponents[random]);

            availableComponents[random] = availableComponents[
                availableComponents.length - 1
            ];
            availableComponents.pop();

            mint(msg.sender, tokenId);
        }
    }

    /**
     * @dev Returns all the metadata of a given Component.
     */
    function retrieve(uint256 _tokenId)
        external
        view
        returns (ComponentView memory)
    {
        for (uint256 i; i < componentModels.length; i++) {
            if (
                _tokenId < componentModels[i].from ||
                _tokenId > componentModels[i].to
            ) {
                continue;
            }

            string memory componentType = _getComponentType(_tokenId);

            (uint256 total, uint256 edition) = _totalComponentEditions(
                _tokenId,
                i
            );

            bool hasSticker;
            string memory stickerName;
            string memory stickerComponentPath;

            if (componentStickers[_tokenId] != 0) {
                hasSticker = true;
                stickerName = stickers[componentStickers[_tokenId]];
                stickerComponentPath = string(
                    abi.encodePacked("-", stickerName, "-sticker")
                );
            }

            string memory serialNumber = "2021.191.";
            string memory tokenIdStr = _tokenId.uint2str();
            if (_tokenId >= 1000) {
                serialNumber = string(
                    abi.encodePacked(serialNumber, tokenIdStr)
                );
            } else if (_tokenId >= 100) {
                serialNumber = string(
                    abi.encodePacked(serialNumber, "0", tokenIdStr)
                );
            } else if (_tokenId >= 10) {
                serialNumber = string(
                    abi.encodePacked(serialNumber, "00", tokenIdStr)
                );
            } else {
                serialNumber = string(
                    abi.encodePacked(serialNumber, "000", tokenIdStr)
                );
            }

            return
                ComponentView(
                    _tokenId,
                    componentType,
                    componentModels[i].brand,
                    string(
                        abi.encodePacked(
                            ipfsBaseURI,
                            componentModels[i].brand.toSlug(),
                            "-",
                            componentType,
                            stickerComponentPath.toSlug(),
                            ".png"
                        )
                    ),
                    hasSticker,
                    stickerName,
                    serialNumber,
                    edition,
                    total
                );
        }

        revert("Component does not exist");
    }

    /**
     * @dev Returns the claim price.
     */
    function getClaimPrice() external view returns (uint256) {
        return claimPrice;
    }

    /**
     * @dev Returns how many components are available to be claimed.
     */
    function getAvailableComponentsCount() external view returns (uint256) {
        return availableComponents.length;
    }

    /**
     * @dev Returns the base URI for the tokens API.
     */
    function baseTokenURI() external view returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Returns the base URI for IPFS.
     */
    function getIpfsBaseURI() external view returns (string memory) {
        return ipfsBaseURI;
    }

    /**
     * @dev Returns a list of all the existing stickers.
     */
    function getStickers() external view returns (string[] memory) {
        return stickers;
    }

    /**
     * @dev Returns an sticker by its id.
     */
    function getSticker(uint256 stickerId)
        external
        view
        returns (string memory)
    {
        return stickers[stickerId];
    }

    /**
     * @dev Returns the total rocket supply
     */
    function totalSupply() external view virtual returns (uint256) {
        return supply;
    }

    /**
     * @dev Returns the total amount of claimed components for the given address
     */
    function getClaimedComponentsPerAddress(address _address)
        external
        view
        returns (uint16)
    {
        return claimedComponentsPerAddress[_address];
    }

    // Private and Internal functions

    /**
     * @dev See {ERC721}.
     */
    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    /**
     * @dev Returns if the given Component is a nose, body or tail.
     */
    function _getComponentType(uint256 _tokenId)
        private
        pure
        returns (string memory)
    {
        uint256 modulo = _tokenId % 3;
        if (modulo == 0) {
            return "nose";
        }

        if (modulo == 1) {
            return "body";
        }

        return "tail";
    }

    /**
     * @dev Checks that the token hasn't been burned and that the token exists before minting it.
     * See {ERC721}.
     */
    function mint(address to, uint256 tokenId) private {
        require(burnedTokens[tokenId] == false, "Token was already burned");

        require(
            tokenId <= componentModels[componentModels.length - 1].to,
            "TokenId is out of bounds"
        );

        supply++;

        _mint(to, tokenId);
    }

    /**
     * @dev Returns the edition number and total of editions for a given tokenId.
     */
    function _totalComponentEditions(uint256 tokenId, uint256 modelId)
        private
        view
        returns (uint256, uint256)
    {
        uint256 edition;
        uint256 total;

        for (
            uint256 i = componentModels[modelId].from;
            i <= componentModels[modelId].to;
            i++
        ) {
            if (i % 3 == tokenId % 3) {
                total++;
            }

            if (tokenId == i) {
                edition = total;
            }
        }

        return (total, edition);
    }

    /**
     * @dev Generates a pseudo-random number.
     */
    function _getRandomNumber(uint256 _upper) private view returns (uint256) {
        uint256 random = uint256(
            keccak256(
                abi.encodePacked(
                    availableComponents.length,
                    blockhash(block.number - 1),
                    block.coinbase,
                    block.difficulty,
                    msg.sender
                )
            )
        );

        return random % _upper;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library StringUtils {
    /**
     * @dev Checks if the given strings are equal.
     */
    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    /**
     * @dev Converts a given string to its slug representation. replacing spaces with hyphens and lowercasing the given string.
     */
    function toSlug(string memory _base) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        uint256 removedChars;

        for (uint256 i = 0; i < _baseBytes.length; i++) {
            _baseBytes[i] = _lower(_baseBytes[i]);

            // replace spaces with hyphens
            if (_baseBytes[i] == 0x20 || _baseBytes[i] == "'") {
                _baseBytes[i] = 0x2D;
            } else if (_baseBytes[i] == 0xC3) {
                // Special Character
                _baseBytes[i] = "";
                removedChars++;
            } else if (_baseBytes[i] == 0xA8) {
                // è to e
                _baseBytes[i] = "e";
            }
        }

        if (removedChars == 0) {
            return string(_baseBytes);
        }

        bytes memory _modifiedBytes = new bytes(
            _baseBytes.length - removedChars
        );
        uint256 index;
        for (uint256 i; i < _baseBytes.length; i++) {
            if (_baseBytes[i] == "") {
                continue;
            }

            _modifiedBytes[index] = _baseBytes[i];
            index++;
        }

        return string(_modifiedBytes);
    }

    /**
     * @dev Converts a given character to lowercase, if it's between the A-Z range.
     */
    function _lower(bytes1 _b1) private pure returns (bytes1) {
        if (_b1 >= 0x41 && _b1 <= 0x5A) {
            return bytes1(uint8(_b1) + 32);
        }

        return _b1;
    }
}

library UintUtils {
    /**
     * @dev converts and uint256 to string
     */
    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }

        uint256 j = _i;
        uint256 len;

        while (j != 0) {
            len++;
            j /= 10;
        }

        bytes memory bstr = new bytes(len);
        uint256 k = len;

        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }

        return string(bstr);
    }
}

library Bytes32Utils {
    function bytes32ToString(bytes32 _bytes32)
        internal
        pure
        returns (string memory)
    {
        uint8 i = 0;
        while (i < 32 && _bytes32[i] != 0) {
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

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "./extensions/IERC721Enumerable.sol";
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
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
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

        require(_msgSender() == owner || ERC721.isApprovedForAll(owner, _msgSender()),
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
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

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
        return (spender == owner || getApproved(tokenId) == spender || ERC721.isApprovedForAll(owner, spender));
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
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
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
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
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
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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

