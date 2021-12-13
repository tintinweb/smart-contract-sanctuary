// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

/**
 * OoOoOoOoOoOoOoOoOoOoOoOoOoOaOoOoOoOoOoOoOoOoOoOoOoOoOoOaOoOoOoOoOoOoOoOoOoOoOoOoo
 * OoOoOoOoOoOoOoOoOoOoOoOoOoO                          OoOoOoOoOoOoOoOoOoOoOoOoOoOo
 * OoOoOoOoOoOoOoOoOoOoO                                      OoOoOoOoOoOoOoOoOoOoOo
 * OoOoOoOoOoOoOoOoOo                                             OoOoOoOoOoOoOoOoOo
 * OoOoOoOoOoOoOo                                                    oOoOoOoOoOoOoOo
 * OoOoOoOoOoOo                                                         OoOoOoOoOoOo
 * OoOoOoOoOo                                                             OoOoOoOoOo
 * OoOoOoOo                                                                 OoOoOoOo
 * OoOoOo                                                                     OoOoOo
 * OoOoO                                                                       oOoOo
 * OoOo                                                                         OoOo
 * OoO                                                                           oOo
 * Oo                                                                             oO
 * Oo                                                                             oO
 * O                                                                               O
 * O                                                                               O
 * OOOOOOOOOOOOOOOOOOOOOOOOO0000000 my name is non OOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOOO
 * O                                                                               O
 * O                                                                               O
 * Oo                                                                             oO
 * Oo                                                                             oO
 * OoO                                                                           oOo
 * OoOo                                                                         OoOo
 * OoOoO                                                                       oOoOo
 * OoOoOo                                                                     OoOoOo
 * OoOoOoOo                                                                 OoOoOoOo
 * OoOoOoOoOo                                                             OoOoOoOoOo
 * OoOoOoOoOoOo                                                         OoOoOoOoOoOo
 * OoOoOoOoOoOoOo                                                    oOoOoOoOoOoOoOo
 * OoOoOoOoOoOoOoOoOo                                             OoOoOoOoOoOoOoOoOo
 * OoOoOoOoOoOoOoOoOoOoO                                      OoOoOoOoOoOoOoOoOoOoOo
 * OoOoOoOoOoOoOoOoOoOoOoOoOoO                          OoOoOoOoOoOoOoOoOoOoOoOoOoOo
 * oOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOooOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOoOooOoOoOo
 */

import {SafeMath} from "../util/SafeMath.sol";
import "../util/Counters.sol";
import "../util/MerkleProof.sol";
import {Strings} from "../util/Strings.sol";
import {IFixedMetadata} from "./FixedMetadata.sol";

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface ERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed fromAddress, address indexed toAddress);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

interface ERC721Metadata {
    function name() external view returns (string memory _name);
    function symbol() external view returns (string memory _symbol);
    function tokenURI(uint256 _tokenId) external view returns (string memory);
}

interface IMerge {
    function getValueOf(uint256 tokenId) external view returns (uint256);
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

contract Fixed is ERC721, ERC721Metadata {
    using SafeMath for uint256;
    using Strings for uint256;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    IFixedMetadata public _metadataGenerator;
    IMerge public _Merge;

    string private _name;
    string private _symbol;

    bytes32 public _merkleRoot;

    bool public _mintingFinalized;

    uint256 public _countMint;
    uint256 public _countToken;

    uint256 immutable public _percentageTotal;
    uint256 public _percentageRoyalty;

    uint256 public _alphaMass;
    uint256 public _alphaId;

    uint256 public _massTotal;

    address public _non;
    address public _dead;
    address public _receiver;

    address proxyRegistryAddress;

    mapping (address => bool) _defaultApprovals;

    event AlphaMassUpdate(uint256 indexed tokenId, uint256 alphaMass);


    event MassUpdate(uint256 indexed tokenIdBurned, uint256 indexed tokenIdPersist, uint256 mass);


    // Mapping of addresses disbarred from holding any token.
    mapping (address => bool) private _blacklistAddress;

    // Mapping of address allowed to hold multiple tokens.
    mapping (address => bool) private _whitelistAddress;

    // Mapping from owner address to token ID.
    mapping (address => uint256) private _tokens;

    // Mapping owner address to token count.
    mapping (address => uint256) private _balances;


    // Mapping from token ID to owner address.
    mapping (uint256 => address) private _owners;

    // Mapping from token ID to approved address.
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals.
    mapping (address => mapping (address => bool)) private _operatorApprovals;



    // Mapping token ID to mass value.
    mapping (uint256 => uint256) private _values;

    // Mapping token ID to all quantity merged into it.
    mapping (uint256 => uint256) private _mergeCount;

    mapping (address => bool) private _mints;


    function getMergeCount(uint256 tokenId) public view returns (uint256 mergeCount) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        return _mergeCount[tokenId];
    }

    modifier onlyNon() {
        require(_msgSender() == _non, "Fixed: msg.sender is not non");
        _;
    }

    /**
     * @dev Set the values carefully!
     *
     * Requirements:
     *
     * - `merge_` merge. (0x27d270B7d58D15D455c85c02286413075f3C8a31)
     * - `metadataGenerator_` (/0xCFF0eDafFe7cAE0D7F2007baf1D7Cc254f38B597)
     * - `non_` - Initial non address (0x4b9cFa53329Fe768a344233a5A1cB821eFc82597)
     * - `proxyRegistryAddress_` - OpenSea proxy registry (0xa5409ec958c83c3f309868babaca7c86dcb077c1/0xf57b2c51ded3a29e6891aba85459d600256cf317)
     * - `transferProxyAddress_` - Rarible transfer proxy (0x4fee7b061c97c9c496b01dbce9cdb10c02f0a0be/0x7d47126a2600E22eab9eD6CF0e515678727779A6)
     * - `merkleRoot_` - Merkle root (0x28bc4b70fafd51f87a3a4ebafe122e5a33fad7152087f2010119805a89c36138)
     */

    constructor(address merge_, address metadataGenerator_, address non_, address proxyRegistryAddress_, address transferProxyAddress_, bytes32 merkleRoot_) {
        _tokenIdCounter.increment();
        _metadataGenerator = IFixedMetadata(metadataGenerator_);
        _Merge = IMerge(merge_);

        _name = "fixed.";
        _symbol = "f";

        _non = non_;
        _receiver = non_;

        _dead = 0x000000000000000000000000000000000000dEaD;


        _percentageTotal = 10000;
        _percentageRoyalty = 1000;


        _blacklistAddress[address(this)] = true;

        proxyRegistryAddress = proxyRegistryAddress_;

        _defaultApprovals[transferProxyAddress_] = true;

        _merkleRoot = merkleRoot_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function totalSupply() public view returns (uint256) {
        return _countToken;
    }

    function setMerkleRoot(bytes32 merkleRoot_) onlyNon public {
        _merkleRoot = merkleRoot_;
    }

    function merge(uint256 tokenIdRcvr, uint256 tokenIdSndr) external returns (uint256 tokenIdDead) {
        address ownerOfTokenIdRcvr = ownerOf(tokenIdRcvr);
        address ownerOfTokenIdSndr = ownerOf(tokenIdSndr);
        require(ownerOfTokenIdRcvr == ownerOfTokenIdSndr, "Fixed: Illegal argument disparate owner.");
        require(_msgSender() == ownerOfTokenIdRcvr, "ERC721: msg.sender is not token owner.");
        return _merge(tokenIdRcvr, tokenIdSndr, ownerOfTokenIdRcvr, ownerOfTokenIdSndr);
    }

    function _transfer(address from, address to, uint256 tokenId) internal {
        require(_exists(tokenId), "ERC721: transfer attempt for nonexistent token");
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");
        require(!_blacklistAddress[to], "Fixed: transfer attempt to blacklist address");
        require(from != to, "ERC721: transfer attempt to self");

        if(to == _dead){
            _burn(tokenId);
            return;
        }

        _approve(address(0), tokenId);

        if(_tokens[to] == 0){
            _tokens[to] = tokenId;
            delete _tokens[from];

            _owners[tokenId] = to;

            _balances[to] = 1;
            _balances[from] = 0;

            emit Transfer(from, to, tokenId);
            return;
        }

        uint256 tokenIdRcvr = _tokens[to];
        uint256 tokenIdSndr = tokenId;
        uint256 tokenIdDead = _merge(tokenIdRcvr, tokenIdSndr, to, from);

        delete _owners[tokenIdDead];
    }

    function _merge(uint256 tokenIdRcvr, uint256 tokenIdSndr, address ownerRcvr, address ownerSndr) internal returns (uint256 tokenIdDead) {
        require(tokenIdRcvr != tokenIdSndr, "Fixed: Illegal argument identical tokenId.");

        uint256 massRcvr = decodeMass(_values[tokenIdRcvr]);
        uint256 massSndr = decodeMass(_values[tokenIdSndr]);

        _balances[ownerRcvr] = 1;
        _balances[ownerSndr] = 0;

        emit Transfer(_owners[tokenIdSndr], address(0), tokenIdSndr);

        _values[tokenIdRcvr] += massSndr;

        uint256 combinedMass = massRcvr + massSndr;

        if(combinedMass > _alphaMass) {
            _alphaId = tokenIdRcvr;
            _alphaMass = combinedMass;
            emit AlphaMassUpdate(_alphaId, combinedMass);
        }

        _mergeCount[tokenIdRcvr]++;

        delete _values[tokenIdSndr];

        delete _tokens[ownerSndr];

        _countToken -= 1;

        emit MassUpdate(tokenIdSndr, tokenIdRcvr, combinedMass);

        return tokenIdSndr;
    }

    function setRoyaltyBips(uint256 percentageRoyalty_) external onlyNon {
        require(percentageRoyalty_ <= _percentageTotal, "Fixed: Illegal argument more than 100%");
        _percentageRoyalty = percentageRoyalty_;
    }

    function royaltyInfo(uint256 tokenId, uint256 salePrice) external view returns (address, uint256) {
        uint256 royaltyAmount = (salePrice * _percentageRoyalty) / _percentageTotal;
        return (_receiver, royaltyAmount);
    }

    function setBlacklistAddress(address address_, bool status) external onlyNon {
        _blacklistAddress[address_] = status;
    }

    function setNon(address non_) external onlyNon {
        _non = non_;
    }

    function setRoyaltyReceiver(address receiver_) external onlyNon {
        _receiver = receiver_;
    }

    function setMetadataGenerator(address metadataGenerator_) external onlyNon {
        _metadataGenerator = IFixedMetadata(metadataGenerator_);
    }

    function whitelistUpdate(address address_, bool status) external onlyNon {
        if(status == false) {
            require(balanceOf(address_) <= 1, "Fixed: Address with more than one token can't be removed.");
        }

        _whitelistAddress[address_] = status;
    }

    function isWhitelisted(address address_) public view returns (bool) {
        return _whitelistAddress[address_];
    }

    function isBlacklisted(address address_) public view returns (bool) {
        return _blacklistAddress[address_];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        require(_exists(tokenId), "ERC721: owner query for nonexistent token");
        return _owners[tokenId];
    }

    /**
     * @dev Generate the NFTs of this collection.
     *
     * Emits a series of {Transfer} events.
     */
    function mint(uint256 mass_, string memory nonce_, bytes32[] calldata proof_) external {
        require(!_mintingFinalized, "Fixed: Minting is finalized.");

        require(_mints[msg.sender] == false);
        _mints[msg.sender] = true;

        string memory key_ = string(abi.encodePacked(mass_.toString(), ":", nonce_));
        require(_verify(_leaf(msg.sender, key_), proof_), "Invalid merkle proof");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        uint256 alphaId = _alphaId;
        uint256 alphaMass = _alphaMass;

        uint256 value = _Merge.getValueOf(tokenId);

        if (value == 0) {
            value = 100000001;
        }

        (uint256 class, uint256 m) = decodeClassAndMass(value);
        value = mass_ + (class * 100000000);

        _values[tokenId] = value;
        _owners[tokenId] = msg.sender;

        _tokens[msg.sender] = tokenId;

        require(class > 0 && class <= 4, "Fixed: Class must be between 1 and 4.");
        require(mass_ > 0 && mass_ < 99999999, "Fixed: Mass must be between 1 and 99999999.");

        if(alphaMass < mass_){
            alphaMass = mass_;
            alphaId = tokenId;
        }

        emit Transfer(address(0), msg.sender, tokenId);

        _countMint += 1;
        _countToken += 1;

        _balances[msg.sender] = 1;

        _massTotal += mass_;

        if(_alphaId != alphaId) {
            _alphaId = alphaId;
            _alphaMass = alphaMass;
            emit AlphaMassUpdate(alphaId, alphaMass);
        }
    }

    function finalize() external onlyNon {
        _mintingFinalized = true;
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _transfer(from, to, tokenId);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        return _balances[owner];
    }

    function massOf(uint256 tokenId) public view virtual returns (uint256) {
        return decodeMass(_values[tokenId]);
    }

    function getValueOf(uint256 tokenId) public view virtual returns (uint256) {
        return _values[tokenId];
    }

    function tokenOf(address owner) public view virtual returns (uint256) {
        uint256 token = _tokens[owner];
        return token;
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }

        return _defaultApprovals[operator] || _operatorApprovals[owner][operator];
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _values[tokenId] != 0;
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");

        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function tokenURI(uint256 tokenId) public virtual view override returns (string memory) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");

        return _metadataGenerator.tokenMetadata(
            tokenId,
            decodeClass(_values[tokenId]),
            decodeMass(_values[tokenId]),
            decodeMass(_values[_alphaId]),
            tokenId == _alphaId,
            getMergeCount(tokenId));
    }

    function encodeClassAndMass(uint256 class, uint256 mass) public pure returns (uint256) {
        require(class > 0 && class <= 4, "Fixed: Class must be between 1 and 4.");
        require(mass > 0 && mass < 99999999, "Fixed: Mass must be between 1 and 99999999.");
        return ((class * 100000000) + mass);
    }

    function decodeClassAndMass(uint256 value) public pure returns (uint256, uint256) {
        uint256 class = value.div(100000000);
        uint256 mass = value.sub(class.mul(100000000));
        require(class > 0 && class <= 4, "Fixed: Class must be between 1 and 4.");
        require(mass > 0 && mass < 99999999, "Fixed: Mass must be between 1 and 99999999.");
        return (class, mass);
    }

    function decodeClass(uint256 value) public pure returns (uint256) {
        return value.div(100000000);
    }

    function decodeMass(uint256 value) public pure returns (uint256) {
        return value.sub(decodeClass(value).mul(100000000));
    }

    function _msgSender() internal view returns (address) {
        return msg.sender;
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool) {
        if (isContract(to)) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                }
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
        return true;
    }

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        bytes4 _ERC165_ = 0x01ffc9a7;
        bytes4 _ERC721_ = 0x80ac58cd;
        bytes4 _ERC2981_ = 0x2a55205a;
        bytes4 _ERC721Metadata_ = 0x5b5e139f;
        return interfaceId == _ERC165_
        || interfaceId == _ERC721_
        || interfaceId == _ERC2981_
        || interfaceId == _ERC721Metadata_;
    }


    function burn(uint256 tokenId) public {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not owner nor approved");
        _burn(tokenId);
    }

    function _burn(uint256 tokenId) internal {
        address owner = ownerOf(tokenId);
        _approve(address(0), tokenId);

        _massTotal -= decodeMass(_values[tokenId]);

        delete _tokens[owner];
        delete _owners[tokenId];
        delete _values[tokenId];

        _countToken -= 1;
        _balances[owner] -= 1;

        emit MassUpdate(tokenId, 0, 0);

        emit Transfer(owner, address(0), tokenId);
    }

    function _leaf(address account, string memory payload) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(payload, account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, _merkleRoot, leaf);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import {ABDKMath64x64} from "../util/ABDKMath64x64.sol";
import {Base64} from "../util/Base64.sol";
import {Roots} from "../util/Roots.sol";
import {Strings} from "../util/Strings.sol";

interface IFixedMetadata {
    function tokenMetadata(
        uint256 tokenId,
        uint256 rarity,
        uint256 tokenMass,
        uint256 alphaMass,
        bool isAlpha,
        uint256 mergeCount) external view returns (string memory);
}

contract FixedMetadata is IFixedMetadata {

    struct ERC721MetadataStructure {
        bool isImageLinked;
        string name;
        string description;
        string createdBy;
        string image;
        ERC721MetadataAttribute[] attributes;
    }

    struct ERC721MetadataAttribute {
        bool includeDisplayType;
        bool includeTraitType;
        bool isValueAString;
        string displayType;
        string traitType;
        string value;
    }

    using ABDKMath64x64 for int128;
    using Base64 for string;
    using Roots for uint;
    using Strings for uint256;

    address public owner;

    string private _name;
    string private _imageBaseURI;
    string private _imageExtension;
    uint256 private _maxRadius;
    string[] private _imageParts;
    mapping (string => string) private _classStyles;
    mapping (string => string) private _spheres;
    mapping (string => string) private _sphereDefs;

    string constant private _RADIUS_TAG = '<RADIUS>';
    string constant private _SPHERE_TAG = '<SPHERE>';
    string constant private _SPHERE_DEFS_TAG = '<SPHERE_DEFS>';
    string constant private _CLASS_TAG = '<CLASS>';
    string constant private _CLASS_STYLE_TAG = '<CLASS_STYLE>';

    constructor() {
        owner = msg.sender;
        _name = "f";
        _imageBaseURI = ""; // Set to empty string - results in on-chain SVG generation by default unless this is set later
        _imageExtension = ""; // Set to empty string - can be changed later to remain empty, .png, .mp4, etc
        _maxRadius = 1000;

        // Deploy with default SVG image parts - can be completely replaced later
        _imageParts.push("<svg xmlns='http://www.w3.org/2000/svg' version='1.1' width='2000' height='2000'>");
        _imageParts.push("<style>");
        _imageParts.push(".m1 #c{fill: #fff;}");
        _imageParts.push(".m1 #r{fill: #000;}");
        _imageParts.push(".m2 #c{fill: #fc3;}");
        _imageParts.push(".m2 #r{fill: #000;}");
        _imageParts.push(".m3 #c{fill: #fff;}");
        _imageParts.push(".m3 #r{fill: #33f;}");
        _imageParts.push(".m4 #c{fill: #fff;}");
        _imageParts.push(".m4 #r{fill: #f33;}");
        _imageParts.push(".a #c{fill: #000 !important;}");
        _imageParts.push(".a #r{fill: #fff !important;}");
        _imageParts.push(".s{transform:scale(calc(");
        _imageParts.push(_RADIUS_TAG);
        _imageParts.push(" / 1000));transform-origin:center}");
        _imageParts.push(_CLASS_STYLE_TAG);
        _imageParts.push("</style>");
        _imageParts.push("<g class='");
        _imageParts.push(_CLASS_TAG);
        _imageParts.push("'>");
        _imageParts.push("<rect id='r' width='2000' height='2000'/>");
        _imageParts.push("<circle id='c' cx='1000' cy='1000' r='");
        _imageParts.push(_RADIUS_TAG);
        _imageParts.push("'/>");
        _imageParts.push("<g class='s'>");
        _imageParts.push("<svg width='2000' height='2000' viewBox='0 0 800 800' fill='none' xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink'>");
        _imageParts.push(_SPHERE_TAG);
        _imageParts.push("<defs>");
        _imageParts.push(_SPHERE_DEFS_TAG);
        _imageParts.push("<image id='i0' width='96' height='96' xlink:href='data:image/png;base64,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'/>");
        _imageParts.push("</defs></svg></g></g>");
        _imageParts.push("<defs></defs>");
        _imageParts.push("</svg>");

        
        string memory defaultSphere = "<circle cx='400' cy='400' r='400' fill='url(#pt0)'/> <g> <mask id='m0' style='mask-type:alpha' maskUnits='userSpaceOnUse' x='0' y='0' width='800' height='800'> <circle cx='400' cy='400' r='400' fill='url(#pt1)'/> </mask> <g mask='url(#m0)'> <rect x='-695.895' y='-297.542' width='1819.48' height='1854.64' transform='rotate(-13.0766 -695.895 -297.542)' fill='url(#p0)'/> </g> </g> <g style='mix-blend-mode:screen'> <circle cx='400' cy='400' r='400' fill='url(#pt2)'/> </g> <g style='mix-blend-mode:screen'> <circle cx='400' cy='400' r='400' fill='url(#pt3)'/> </g>";
        string memory alphaSphere = "<circle cx='400' cy='400' r='400' fill='url(#pt0)'/> <g style='mix-blend-mode:screen'> <circle cx='400' cy='400' r='400' fill='url(#pt1)'/> </g> <g opacity='0.2'> <mask id='m0' style='mask-type:alpha' maskUnits='userSpaceOnUse' x='0' y='0' width='800' height='800'> <circle cx='400' cy='400' r='400' fill='url(#pt2)'/> </mask> <g mask='url(#m0)'> <rect x='-695.895' y='-297.543' width='1819.48' height='1854.64' transform='rotate(-13.0766 -695.895 -297.543)' fill='url(#pattern0)'/> </g> </g>";

        _spheres["a"] = alphaSphere;
        _spheres["1"] = defaultSphere;
        _spheres["2"] = defaultSphere;
        _spheres["3"] = defaultSphere;
        _spheres["4"] = defaultSphere;

        string memory defaultSphereDef = "<pattern id='p0' patternContentUnits='objectBoundingBox' width='0.0325926' height='0.0325926'> <use xlink:href='#i0' transform='scale(0.0004)'/> </pattern> <radialGradient id='pt0' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(555.396 214.388) rotate(133.821) scale(691.992)'> <stop stop-color='#E1E1E1'/> <stop offset='1'/> </radialGradient> <radialGradient id='pt1' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(555.396 214.388) rotate(133.821) scale(691.992)'> <stop stop-color='#C4C4C4'/> <stop offset='1'/> </radialGradient> <radialGradient id='pt2' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(555.396 214.388) rotate(133.821) scale(691.992)'> <stop stop-color='white'/> <stop offset='0.404291' stop-color='#A2A2A2'/> <stop offset='1'/> </radialGradient> <radialGradient id='pt3' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(555.396 214.388) rotate(133.821) scale(691.992)'> <stop stop-color='#F4F4F4'/> <stop offset='1'/> </radialGradient>";
        string memory alphaSphereDef = "<pattern id='p0' patternContentUnits='objectBoundingBox' width='0.0325926' height='0.0325926'> <use xlink:href='#i0' transform='scale(0.0004)'/> </pattern> <radialGradient id='pt0' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(555.396 214.388) rotate(133.821) scale(691.992)'> <stop stop-color='#C4C4C4'/> <stop offset='0.197917'/> </radialGradient> <radialGradient id='pt1' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(555.396 214.388) rotate(133.821) scale(691.992)'> <stop offset='0.203125' stop-color='#C4C4C4' stop-opacity='0.9'/> <stop offset='0.723958'/> </radialGradient> <radialGradient id='pt2' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(555.396 214.388) rotate(133.821) scale(691.992)'> <stop stop-color='#C4C4C4'/> <stop offset='1'/> </radialGradient>";
        string memory yellowSphereDef = "<pattern id='p0' patternContentUnits='objectBoundingBox' width='0.0325926' height='0.0325926'> <use xlink:href='#i0' transform='scale(0.0004)' opacity='0.25'/> </pattern> <radialGradient id='pt0' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(555.396 214.388) rotate(133.821) scale(691.992)'> <stop stop-color='#C4C4C4'/> <stop offset='0.197917' stop-color='#FFCC33'/> </radialGradient> <radialGradient id='pt1' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(555.396 214.388) rotate(133.821) scale(691.992)'> <stop stop-color='#C4C4C4'/> <stop offset='1' stop-color='#FFCC33'/> </radialGradient> <radialGradient id='pt2' cx='0' cy='0' r='1' gradientUnits='userSpaceOnUse' gradientTransform='translate(555.396 214.388) rotate(133.821) scale(691.992)'> <stop stop-color='#C4C4C4'/> <stop offset='1'/> </radialGradient>";

        _sphereDefs["a"] = alphaSphereDef;
        _sphereDefs["1"] = defaultSphereDef;
        _sphereDefs["2"] = yellowSphereDef;
        _sphereDefs["3"] = defaultSphereDef;
        _sphereDefs["4"] = defaultSphereDef;

    }

    function setName(string calldata name_) external {
        _requireOnlyOwner();
        _name = name_;
    }

    function setImageBaseURI(string calldata imageBaseURI_, string calldata imageExtension_) external {
        _requireOnlyOwner();
        _imageBaseURI = imageBaseURI_;
        _imageExtension = imageExtension_;
    }

    function setMaxRadius(uint256 maxRadius_) external {
        _requireOnlyOwner();
        _maxRadius = maxRadius_;
    }

    function tokenMetadata(uint256 tokenId, uint256 rarity, uint256 tokenMass, uint256 alphaMass, bool isAlpha, uint256 mergeCount) external view override returns (string memory) {
        string memory base64Json = Base64.encode(bytes(string(abi.encodePacked(_getJson(tokenId, rarity, tokenMass, alphaMass, isAlpha, mergeCount)))));
        return string(abi.encodePacked('data:application/json;base64,', base64Json));
    }

    function updateImageParts(string[] memory imageParts_) public {
        _requireOnlyOwner();
        _imageParts = imageParts_;
    }

    function pushToImageParts(string[] memory imageParts_) public {
        _requireOnlyOwner();

        for (uint i = 0; i < imageParts_.length; i++) {
            _imageParts.push(imageParts_[i]);
        }
    }

    function updateClassStyle(string calldata cssClass, string calldata cssStyle) external {
        _requireOnlyOwner();
        _classStyles[cssClass] = cssStyle;
    }

    function getClassStyle(string memory cssClass) public view returns (string memory) {
        return _classStyles[cssClass];
    }

    function updateSphere(string calldata cssClass, string calldata cssStyle) external {
        _requireOnlyOwner();
        _spheres[cssClass] = cssStyle;
    }

    function getSphere(string memory cssClass) public view returns (string memory) {
        return _spheres[cssClass];
    }

    function updateSphereDef(string calldata cssClass, string calldata cssStyle) external {
        _requireOnlyOwner();
        _sphereDefs[cssClass] = cssStyle;
    }

    function getSphereDef(string memory cssClass) public view returns (string memory) {
        return _sphereDefs[cssClass];
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function imageBaseURI() public view returns (string memory) {
        return _imageBaseURI;
    }

    function imageExtension() public view returns (string memory) {
        return _imageExtension;
    }

    function maxRadius() public view returns (uint256) {
        return _maxRadius;
    }

    function getClassString(uint256 tokenId, uint256 rarity, bool isAlpha, bool offchainImage) public pure returns (string memory) {
        return _getClassString(tokenId, rarity, isAlpha, offchainImage);
    }

    function _getJson(uint256 tokenId, uint256 rarity, uint256 tokenMass, uint256 alphaMass, bool isAlpha, uint256 mergeCount) private view returns (string memory) {
        string memory imageData =
        bytes(_imageBaseURI).length == 0 ?
        _getSvg(tokenId, rarity, tokenMass, alphaMass, isAlpha) :
        string(abi.encodePacked(imageBaseURI(), _getClassString(tokenId, rarity, isAlpha, true), "_", uint256(int256(_getScaledRadius(tokenMass, alphaMass, _maxRadius).toInt())).toString(), imageExtension()));

        ERC721MetadataStructure memory metadata = ERC721MetadataStructure({
        isImageLinked: bytes(_imageBaseURI).length > 0,
        name: string(abi.encodePacked(name(), "(", tokenMass.toString(), ") #", tokenId.toString())),
        description: tokenMass.toString(),
        createdBy: "Non",
        image: imageData,
        attributes: _getJsonAttributes(tokenId, rarity, tokenMass, mergeCount, isAlpha)
        });

        return _generateERC721Metadata(metadata);
    }

    function _getJsonAttributes(uint256 tokenId, uint256 rarity, uint256 tokenMass, uint256 mergeCount, bool isAlpha) private pure returns (ERC721MetadataAttribute[] memory) {
        uint256 tensDigit = tokenId % 100 / 10;
        uint256 onesDigit = tokenId % 10;
        uint256 class = tensDigit * 10 + onesDigit;

        ERC721MetadataAttribute[] memory metadataAttributes = new ERC721MetadataAttribute[](5);
        metadataAttributes[0] = _getERC721MetadataAttribute(false, true, false, "", "Mass", tokenMass.toString());
        metadataAttributes[1] = _getERC721MetadataAttribute(false, true, false, "", "Alpha", isAlpha ? "1" : "0");
        metadataAttributes[2] = _getERC721MetadataAttribute(false, true, false, "", "Tier", rarity.toString());
        metadataAttributes[3] = _getERC721MetadataAttribute(false, true, false, "", "Class", class.toString());
        metadataAttributes[4] = _getERC721MetadataAttribute(false, true, false, "", "Merges", mergeCount.toString());
        return metadataAttributes;
    }

    function _getERC721MetadataAttribute(bool includeDisplayType, bool includeTraitType, bool isValueAString, string memory displayType, string memory traitType, string memory value) private pure returns (ERC721MetadataAttribute memory) {
        ERC721MetadataAttribute memory attribute = ERC721MetadataAttribute({
        includeDisplayType: includeDisplayType,
        includeTraitType: includeTraitType,
        isValueAString: isValueAString,
        displayType: displayType,
        traitType: traitType,
        value: value
        });

        return attribute;
    }

    function _getSvg(uint256 tokenId, uint256 rarity, uint256 tokenMass, uint256 alphaMass, bool isAlpha) private view returns (string memory) {
        bytes memory byteString;
        for (uint i = 0; i < _imageParts.length; i++) {
            if (_checkTag(_imageParts[i], _RADIUS_TAG)) {
                byteString = abi.encodePacked(byteString, _floatToString(_getScaledRadius(tokenMass, alphaMass, _maxRadius)));
            } else if (_checkTag(_imageParts[i], _SPHERE_TAG)) {
                if (isAlpha) {
                    byteString = abi.encodePacked(byteString, _spheres['a']);
                } else {
                    byteString = abi.encodePacked(byteString, _spheres[rarity.toString()]);
                }
            } else if (_checkTag(_imageParts[i], _SPHERE_DEFS_TAG)) {
                if (isAlpha) {
                    byteString = abi.encodePacked(byteString, _sphereDefs['a']);
                } else {
                    byteString = abi.encodePacked(byteString, _sphereDefs[rarity.toString()]);
                }
            } else if (_checkTag(_imageParts[i], _CLASS_TAG)) {
                byteString = abi.encodePacked(byteString, _getClassString(tokenId, rarity, isAlpha, false));
            } else if (_checkTag(_imageParts[i], _CLASS_STYLE_TAG)) {
                uint256 tensDigit = tokenId % 100 / 10;
                uint256 onesDigit = tokenId % 10;
                uint256 class = tensDigit * 10 + onesDigit;
                string memory classCss = getClassStyle(_getTokenIdClass(class));
                if(bytes(classCss).length > 0) {
                    byteString = abi.encodePacked(byteString, classCss);
                }
            } else {
                byteString = abi.encodePacked(byteString, _imageParts[i]);
            }
        }
        return string(byteString);
    }

    function _getScaledRadius(uint256 tokenMass, uint256 alphaMass, uint256 maximumRadius) private pure returns (int128) {
        int128 radiusMass = _getRadius64x64(tokenMass);
        int128 radiusAlphaMass = _getRadius64x64(alphaMass);
        int128 scalePercentage = ABDKMath64x64.div(radiusMass, radiusAlphaMass);
        int128 scaledRadius = ABDKMath64x64.mul(ABDKMath64x64.fromUInt(maximumRadius), scalePercentage);
        if(uint256(int256(scaledRadius.toInt())) == 0) {
            scaledRadius = ABDKMath64x64.fromUInt(1);
        }
        return scaledRadius;
    }

    // Radius = Cube Root(Mass) * Cube Root (0.23873241463)
    // Radius = Cube Root(Mass) * 0.62035049089
    function _getRadius64x64(uint256 mass) private pure returns (int128) {
        int128 cubeRootScalar = ABDKMath64x64.divu(62035049089, 100000000000);
        int128 cubeRootMass = ABDKMath64x64.divu(mass.nthRoot(3, 6, 32), 1000000);
        int128 radius = ABDKMath64x64.mul(cubeRootMass, cubeRootScalar);
        return radius;
    }

    function _generateERC721Metadata(ERC721MetadataStructure memory metadata) private pure returns (string memory) {
        bytes memory byteString;

        byteString = abi.encodePacked(
            byteString,
            _openJsonObject());

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("name", metadata.name, true));

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("description", metadata.description, true));

        byteString = abi.encodePacked(
            byteString,
            _pushJsonPrimitiveStringAttribute("created_by", metadata.createdBy, true));

        if(metadata.isImageLinked) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute("image", metadata.image, true));
        } else {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute("image_data", metadata.image, true));
        }

        byteString = abi.encodePacked(
            byteString,
            _pushJsonComplexAttribute("attributes", _getAttributes(metadata.attributes), false));

        byteString = abi.encodePacked(
            byteString,
            _closeJsonObject());

        return string(byteString);
    }

    function _getAttributes(ERC721MetadataAttribute[] memory attributes) private pure returns (string memory) {
        bytes memory byteString;

        byteString = abi.encodePacked(
            byteString,
            _openJsonArray());

        for (uint i = 0; i < attributes.length; i++) {
            ERC721MetadataAttribute memory attribute = attributes[i];

            byteString = abi.encodePacked(
                byteString,
                _pushJsonArrayElement(_getAttribute(attribute), i < (attributes.length - 1)));
        }

        byteString = abi.encodePacked(
            byteString,
            _closeJsonArray());

        return string(byteString);
    }

    function _getAttribute(ERC721MetadataAttribute memory attribute) private pure returns (string memory) {
        bytes memory byteString;

        byteString = abi.encodePacked(
            byteString,
            _openJsonObject());

        if(attribute.includeDisplayType) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute("display_type", attribute.displayType, true));
        }

        if(attribute.includeTraitType) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute("trait_type", attribute.traitType, true));
        }

        if(attribute.isValueAString) {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveStringAttribute("value", attribute.value, false));
        } else {
            byteString = abi.encodePacked(
                byteString,
                _pushJsonPrimitiveNonStringAttribute("value", attribute.value, false));
        }

        byteString = abi.encodePacked(
            byteString,
            _closeJsonObject());

        return string(byteString);
    }

    function _getClassString(uint256 tokenId, uint256 rarity, bool isAlpha, bool offchainImage) private pure returns (string memory) {
        bytes memory byteString;

        byteString = abi.encodePacked(byteString, _getRarityClass(rarity));

        if(isAlpha) {
            byteString = abi.encodePacked(
                byteString,
                string(abi.encodePacked(offchainImage ? "_" : " ", "a")));
        }

        uint256 tensDigit = tokenId % 100 / 10;
        uint256 onesDigit = tokenId % 10;
        uint256 class = tensDigit * 10 + onesDigit;

        byteString = abi.encodePacked(
            byteString,
            string(abi.encodePacked(offchainImage ? "_" : " ", _getTokenIdClass(class))));

        return string(byteString);
    }

    function _getRarityClass(uint256 rarity) private pure returns (string memory) {
        return string(abi.encodePacked("m", rarity.toString()));
    }

    function _getTokenIdClass(uint256 class) private pure returns (string memory) {
        return string(abi.encodePacked("c", class.toString()));
    }

    function _checkTag(string storage a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function _floatToString(int128 value) private pure returns (string memory) {
        uint256 decimal4 = (value & 0xFFFFFFFFFFFFFFFF).mulu(10000);
        return string(abi.encodePacked(uint256(int256(value.toInt())).toString(), '.', _decimal4ToString(decimal4)));
    }

    function _decimal4ToString(uint256 decimal4) private pure returns (string memory) {
        bytes memory decimal4Characters = new bytes(4);
        for (uint i = 0; i < 4; i++) {
            decimal4Characters[3 - i] = bytes1(uint8(0x30 + decimal4 % 10));
            decimal4 /= 10;
        }
        return string(abi.encodePacked(decimal4Characters));
    }

    function _requireOnlyOwner() private view {
        require(msg.sender == owner, "You are not the owner");
    }

    function _openJsonObject() private pure returns (string memory) {
        return string(abi.encodePacked("{"));
    }

    function _closeJsonObject() private pure returns (string memory) {
        return string(abi.encodePacked("}"));
    }

    function _openJsonArray() private pure returns (string memory) {
        return string(abi.encodePacked("["));
    }

    function _closeJsonArray() private pure returns (string memory) {
        return string(abi.encodePacked("]"));
    }

    function _pushJsonPrimitiveStringAttribute(string memory key, string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked('"', key, '": "', value, '"', insertComma ? ',' : ''));
    }

    function _pushJsonPrimitiveNonStringAttribute(string memory key, string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked('"', key, '": ', value, insertComma ? ',' : ''));
    }

    function _pushJsonComplexAttribute(string memory key, string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked('"', key, '": ', value, insertComma ? ',' : ''));
    }

    function _pushJsonArrayElement(string memory value, bool insertComma) private pure returns (string memory) {
        return string(abi.encodePacked(value, insertComma ? ',' : ''));
    }
}

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

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];

            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        // Check if the computed hash (root) is equal to the provided root
        return computedHash == root;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is no longer needed starting with Solidity 0.8. The compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

pragma solidity ^0.8.6;

library Roots {

    // calculates a^(1/n) to dp decimal places
    // maxIts bounds the number of iterations performed
    function nthRoot(uint _a, uint _n, uint _dp, uint _maxIts) pure internal returns(uint) {
        assert (_n > 1);

        // The scale factor is a crude way to turn everything into integer calcs.
        // Actually do (a * (10 ^ ((dp + 1) * n))) ^ (1/n)
        // We calculate to one extra dp and round at the end
        uint one = 10 ** (1 + _dp);
        uint a0 = one ** _n * _a;

        // Initial guess: 1.0
        uint xNew = one;

        uint iter = 0;
        while (iter < _maxIts) {
            uint x = xNew;
            uint t0 = x ** (_n - 1);
            if (x * t0 > a0) {
                xNew = x - (x - a0 / t0) / _n;
            } else {
                xNew = x + (a0 / t0 - x) / _n;
            }
            ++iter;
            if(xNew == x) {
                break;
            }
        }

        // Round to nearest in the last dp.
        return (xNew + 5) / 10;
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
mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
resultPtr := add(resultPtr, 1)
mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
resultPtr := add(resultPtr, 1)
}

// padding with '='
switch mod(mload(data), 3)
case 1 {mstore(sub(resultPtr, 2), shl(240, 0x3d3d))}
case 2 {mstore(sub(resultPtr, 1), shl(248, 0x3d))}
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
shl(6, and(mload(add(tablePtr, and(shr(8, input), 0xFF))), 0xFF)),
and(mload(add(tablePtr, and(input, 0xFF))), 0xFF)
)
)
mstore(resultPtr, shl(232, output))
resultPtr := add(resultPtr, 3)
}
}

return result;
}
}

// SPDX-License-Identifier: BSD-4-Clause
/*
 * ABDK Math 64.64 Smart Contract Library.  Copyright © 2019 by ABDK Consulting.
 * Author: Mikhail Vladimirov <[email protected]>
 */
pragma solidity ^0.8.6;

/**
 * Smart contract library of mathematical functions operating with signed
 * 64.64-bit fixed point numbers.  Signed 64.64-bit fixed point number is
 * basically a simple fraction whose numerator is signed 128-bit integer and
 * denominator is 2^64.  As long as denominator is always the same, there is no
 * need to store it, thus in Solidity signed 64.64-bit fixed point numbers are
 * represented by int128 type holding only the numerator.
 */
library ABDKMath64x64 {
    /*
     * Minimum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MIN_64x64 = -0x80000000000000000000000000000000;

    /*
     * Maximum value signed 64.64-bit fixed point number may have.
     */
    int128 private constant MAX_64x64 = 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    /**
     * Convert signed 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
    function fromInt (int256 x) internal pure returns (int128) {
    unchecked {
        require (x >= -0x8000000000000000 && x <= 0x7FFFFFFFFFFFFFFF);
        return int128 (x << 64);
    }
    }

    /**
     * Convert signed 64.64 fixed point number into signed 64-bit integer number
     * rounding down.
     *
     * @param x signed 64.64-bit fixed point number
   * @return signed 64-bit integer number
   */
    function toInt (int128 x) internal pure returns (int64) {
    unchecked {
        return int64 (x >> 64);
    }
    }

    /**
     * Convert unsigned 256-bit integer number into signed 64.64-bit fixed point
     * number.  Revert on overflow.
     *
     * @param x unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
    function fromUInt (uint256 x) internal pure returns (int128) {
    unchecked {
        require (x <= 0x7FFFFFFFFFFFFFFF);
        return int128 (int256 (x << 64));
    }
    }

    /**
     * Convert signed 64.64 fixed point number into unsigned 64-bit integer
     * number rounding down.  Revert on underflow.
     *
     * @param x signed 64.64-bit fixed point number
   * @return unsigned 64-bit integer number
   */
    function toUInt (int128 x) internal pure returns (uint64) {
    unchecked {
        require (x >= 0);
        return uint64 (uint128 (x >> 64));
    }
    }

    /**
     * Convert signed 128.128 fixed point number into signed 64.64-bit fixed point
     * number rounding down.  Revert on overflow.
     *
     * @param x signed 128.128-bin fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function from128x128 (int256 x) internal pure returns (int128) {
    unchecked {
        int256 result = x >> 64;
        require (result >= MIN_64x64 && result <= MAX_64x64);
        return int128 (result);
    }
    }

    /**
     * Convert signed 64.64 fixed point number into signed 128.128 fixed point
     * number.
     *
     * @param x signed 64.64-bit fixed point number
   * @return signed 128.128 fixed point number
   */
    function to128x128 (int128 x) internal pure returns (int256) {
    unchecked {
        return int256 (x) << 64;
    }
    }

    /**
     * Calculate x + y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function add (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
        int256 result = int256(x) + y;
        require (result >= MIN_64x64 && result <= MAX_64x64);
        return int128 (result);
    }
    }

    /**
     * Calculate x - y.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function sub (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
        int256 result = int256(x) - y;
        require (result >= MIN_64x64 && result <= MAX_64x64);
        return int128 (result);
    }
    }

    /**
     * Calculate x * y rounding down.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function mul (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
        int256 result = int256(x) * y >> 64;
        require (result >= MIN_64x64 && result <= MAX_64x64);
        return int128 (result);
    }
    }

    /**
     * Calculate x * y rounding towards zero, where x is signed 64.64 fixed point
     * number and y is signed 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
   * @param y signed 256-bit integer number
   * @return signed 256-bit integer number
   */
    function muli (int128 x, int256 y) internal pure returns (int256) {
    unchecked {
        if (x == MIN_64x64) {
            require (y >= -0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF &&
            y <= 0x1000000000000000000000000000000000000000000000000);
            return -y << 63;
        } else {
            bool negativeResult = false;
            if (x < 0) {
                x = -x;
                negativeResult = true;
            }
            if (y < 0) {
                y = -y; // We rely on overflow behavior here
                negativeResult = !negativeResult;
            }
            uint256 absoluteResult = mulu (x, uint256 (y));
            if (negativeResult) {
                require (absoluteResult <=
                    0x8000000000000000000000000000000000000000000000000000000000000000);
                return -int256 (absoluteResult); // We rely on overflow behavior here
            } else {
                require (absoluteResult <=
                    0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
                return int256 (absoluteResult);
            }
        }
    }
    }

    /**
     * Calculate x * y rounding down, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64 fixed point number
   * @param y unsigned 256-bit integer number
   * @return unsigned 256-bit integer number
   */
    function mulu (int128 x, uint256 y) internal pure returns (uint256) {
    unchecked {
        if (y == 0) return 0;

        require (x >= 0);

        uint256 lo = (uint256 (int256 (x)) * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)) >> 64;
        uint256 hi = uint256 (int256 (x)) * (y >> 128);

        require (hi <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        hi <<= 64;

        require (hi <=
            0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF - lo);
        return hi + lo;
    }
    }

    /**
     * Calculate x / y rounding towards zero.  Revert on overflow or when y is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function div (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
        require (y != 0);
        int256 result = (int256 (x) << 64) / y;
        require (result >= MIN_64x64 && result <= MAX_64x64);
        return int128 (result);
    }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are signed 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x signed 256-bit integer number
   * @param y signed 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
    function divi (int256 x, int256 y) internal pure returns (int128) {
    unchecked {
        require (y != 0);

        bool negativeResult = false;
        if (x < 0) {
            x = -x; // We rely on overflow behavior here
            negativeResult = true;
        }
        if (y < 0) {
            y = -y; // We rely on overflow behavior here
            negativeResult = !negativeResult;
        }
        uint128 absoluteResult = divuu (uint256 (x), uint256 (y));
        if (negativeResult) {
            require (absoluteResult <= 0x80000000000000000000000000000000);
            return -int128 (absoluteResult); // We rely on overflow behavior here
        } else {
            require (absoluteResult <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
            return int128 (absoluteResult); // We rely on overflow behavior here
        }
    }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return signed 64.64-bit fixed point number
   */
    function divu (uint256 x, uint256 y) internal pure returns (int128) {
    unchecked {
        require (y != 0);
        uint128 result = divuu (x, y);
        require (result <= uint128 (MAX_64x64));
        return int128 (result);
    }
    }

    /**
     * Calculate -x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function neg (int128 x) internal pure returns (int128) {
    unchecked {
        require (x != MIN_64x64);
        return -x;
    }
    }

    /**
     * Calculate |x|.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function abs (int128 x) internal pure returns (int128) {
    unchecked {
        require (x != MIN_64x64);
        return x < 0 ? -x : x;
    }
    }

    /**
     * Calculate 1 / x rounding towards zero.  Revert on overflow or when x is
     * zero.
     *
     * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function inv (int128 x) internal pure returns (int128) {
    unchecked {
        require (x != 0);
        int256 result = int256 (0x100000000000000000000000000000000) / x;
        require (result >= MIN_64x64 && result <= MAX_64x64);
        return int128 (result);
    }
    }

    /**
     * Calculate arithmetics average of x and y, i.e. (x + y) / 2 rounding down.
     *
     * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function avg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
        return int128 ((int256 (x) + int256 (y)) >> 1);
    }
    }

    /**
     * Calculate geometric average of x and y, i.e. sqrt (x * y) rounding down.
     * Revert on overflow or in case x * y is negative.
     *
     * @param x signed 64.64-bit fixed point number
   * @param y signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function gavg (int128 x, int128 y) internal pure returns (int128) {
    unchecked {
        int256 m = int256 (x) * int256 (y);
        require (m >= 0);
        require (m <
            0x4000000000000000000000000000000000000000000000000000000000000000);
        return int128 (sqrtu (uint256 (m)));
    }
    }

    /**
     * Calculate x^y assuming 0^0 is 1, where x is signed 64.64 fixed point number
     * and y is unsigned 256-bit integer number.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
   * @param y uint256 value
   * @return signed 64.64-bit fixed point number
   */
    function pow (int128 x, uint256 y) internal pure returns (int128) {
    unchecked {
        bool negative = x < 0 && y & 1 == 1;

        uint256 absX = uint128 (x < 0 ? -x : x);
        uint256 absResult;
        absResult = 0x100000000000000000000000000000000;

        if (absX <= 0x10000000000000000) {
            absX <<= 63;
            while (y != 0) {
                if (y & 0x1 != 0) {
                    absResult = absResult * absX >> 127;
                }
                absX = absX * absX >> 127;

                if (y & 0x2 != 0) {
                    absResult = absResult * absX >> 127;
                }
                absX = absX * absX >> 127;

                if (y & 0x4 != 0) {
                    absResult = absResult * absX >> 127;
                }
                absX = absX * absX >> 127;

                if (y & 0x8 != 0) {
                    absResult = absResult * absX >> 127;
                }
                absX = absX * absX >> 127;

                y >>= 4;
            }

            absResult >>= 64;
        } else {
            uint256 absXShift = 63;
            if (absX < 0x1000000000000000000000000) { absX <<= 32; absXShift -= 32; }
            if (absX < 0x10000000000000000000000000000) { absX <<= 16; absXShift -= 16; }
            if (absX < 0x1000000000000000000000000000000) { absX <<= 8; absXShift -= 8; }
            if (absX < 0x10000000000000000000000000000000) { absX <<= 4; absXShift -= 4; }
            if (absX < 0x40000000000000000000000000000000) { absX <<= 2; absXShift -= 2; }
            if (absX < 0x80000000000000000000000000000000) { absX <<= 1; absXShift -= 1; }

            uint256 resultShift = 0;
            while (y != 0) {
                require (absXShift < 64);

                if (y & 0x1 != 0) {
                    absResult = absResult * absX >> 127;
                    resultShift += absXShift;
                    if (absResult > 0x100000000000000000000000000000000) {
                        absResult >>= 1;
                        resultShift += 1;
                    }
                }
                absX = absX * absX >> 127;
                absXShift <<= 1;
                if (absX >= 0x100000000000000000000000000000000) {
                    absX >>= 1;
                    absXShift += 1;
                }

                y >>= 1;
            }

            require (resultShift < 64);
            absResult >>= 64 - resultShift;
        }
        int256 result = negative ? -int256 (absResult) : int256 (absResult);
        require (result >= MIN_64x64 && result <= MAX_64x64);
        return int128 (result);
    }
    }

    /**
     * Calculate sqrt (x) rounding down.  Revert if x < 0.
     *
     * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function sqrt (int128 x) internal pure returns (int128) {
    unchecked {
        require (x >= 0);
        return int128 (sqrtu (uint256 (int256 (x)) << 64));
    }
    }

    /**
     * Calculate binary logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function log_2 (int128 x) internal pure returns (int128) {
    unchecked {
        require (x > 0);

        int256 msb = 0;
        int256 xc = x;
        if (xc >= 0x10000000000000000) { xc >>= 64; msb += 64; }
        if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
        if (xc >= 0x10000) { xc >>= 16; msb += 16; }
        if (xc >= 0x100) { xc >>= 8; msb += 8; }
        if (xc >= 0x10) { xc >>= 4; msb += 4; }
        if (xc >= 0x4) { xc >>= 2; msb += 2; }
        if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

        int256 result = msb - 64 << 64;
        uint256 ux = uint256 (int256 (x)) << uint256 (127 - msb);
        for (int256 bit = 0x8000000000000000; bit > 0; bit >>= 1) {
            ux *= ux;
            uint256 b = ux >> 255;
            ux >>= 127 + b;
            result += bit * int256 (b);
        }

        return int128 (result);
    }
    }

    /**
     * Calculate natural logarithm of x.  Revert if x <= 0.
     *
     * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function ln (int128 x) internal pure returns (int128) {
    unchecked {
        require (x > 0);

        return int128 (int256 (
                uint256 (int256 (log_2 (x))) * 0xB17217F7D1CF79ABC9E3B39803F2F6AF >> 128));
    }
    }

    /**
     * Calculate binary exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function exp_2 (int128 x) internal pure returns (int128) {
    unchecked {
        require (x < 0x400000000000000000); // Overflow

        if (x < -0x400000000000000000) return 0; // Underflow

        uint256 result = 0x80000000000000000000000000000000;

        if (x & 0x8000000000000000 > 0)
            result = result * 0x16A09E667F3BCC908B2FB1366EA957D3E >> 128;
        if (x & 0x4000000000000000 > 0)
            result = result * 0x1306FE0A31B7152DE8D5A46305C85EDEC >> 128;
        if (x & 0x2000000000000000 > 0)
            result = result * 0x1172B83C7D517ADCDF7C8C50EB14A791F >> 128;
        if (x & 0x1000000000000000 > 0)
            result = result * 0x10B5586CF9890F6298B92B71842A98363 >> 128;
        if (x & 0x800000000000000 > 0)
            result = result * 0x1059B0D31585743AE7C548EB68CA417FD >> 128;
        if (x & 0x400000000000000 > 0)
            result = result * 0x102C9A3E778060EE6F7CACA4F7A29BDE8 >> 128;
        if (x & 0x200000000000000 > 0)
            result = result * 0x10163DA9FB33356D84A66AE336DCDFA3F >> 128;
        if (x & 0x100000000000000 > 0)
            result = result * 0x100B1AFA5ABCBED6129AB13EC11DC9543 >> 128;
        if (x & 0x80000000000000 > 0)
            result = result * 0x10058C86DA1C09EA1FF19D294CF2F679B >> 128;
        if (x & 0x40000000000000 > 0)
            result = result * 0x1002C605E2E8CEC506D21BFC89A23A00F >> 128;
        if (x & 0x20000000000000 > 0)
            result = result * 0x100162F3904051FA128BCA9C55C31E5DF >> 128;
        if (x & 0x10000000000000 > 0)
            result = result * 0x1000B175EFFDC76BA38E31671CA939725 >> 128;
        if (x & 0x8000000000000 > 0)
            result = result * 0x100058BA01FB9F96D6CACD4B180917C3D >> 128;
        if (x & 0x4000000000000 > 0)
            result = result * 0x10002C5CC37DA9491D0985C348C68E7B3 >> 128;
        if (x & 0x2000000000000 > 0)
            result = result * 0x1000162E525EE054754457D5995292026 >> 128;
        if (x & 0x1000000000000 > 0)
            result = result * 0x10000B17255775C040618BF4A4ADE83FC >> 128;
        if (x & 0x800000000000 > 0)
            result = result * 0x1000058B91B5BC9AE2EED81E9B7D4CFAB >> 128;
        if (x & 0x400000000000 > 0)
            result = result * 0x100002C5C89D5EC6CA4D7C8ACC017B7C9 >> 128;
        if (x & 0x200000000000 > 0)
            result = result * 0x10000162E43F4F831060E02D839A9D16D >> 128;
        if (x & 0x100000000000 > 0)
            result = result * 0x100000B1721BCFC99D9F890EA06911763 >> 128;
        if (x & 0x80000000000 > 0)
            result = result * 0x10000058B90CF1E6D97F9CA14DBCC1628 >> 128;
        if (x & 0x40000000000 > 0)
            result = result * 0x1000002C5C863B73F016468F6BAC5CA2B >> 128;
        if (x & 0x20000000000 > 0)
            result = result * 0x100000162E430E5A18F6119E3C02282A5 >> 128;
        if (x & 0x10000000000 > 0)
            result = result * 0x1000000B1721835514B86E6D96EFD1BFE >> 128;
        if (x & 0x8000000000 > 0)
            result = result * 0x100000058B90C0B48C6BE5DF846C5B2EF >> 128;
        if (x & 0x4000000000 > 0)
            result = result * 0x10000002C5C8601CC6B9E94213C72737A >> 128;
        if (x & 0x2000000000 > 0)
            result = result * 0x1000000162E42FFF037DF38AA2B219F06 >> 128;
        if (x & 0x1000000000 > 0)
            result = result * 0x10000000B17217FBA9C739AA5819F44F9 >> 128;
        if (x & 0x800000000 > 0)
            result = result * 0x1000000058B90BFCDEE5ACD3C1CEDC823 >> 128;
        if (x & 0x400000000 > 0)
            result = result * 0x100000002C5C85FE31F35A6A30DA1BE50 >> 128;
        if (x & 0x200000000 > 0)
            result = result * 0x10000000162E42FF0999CE3541B9FFFCF >> 128;
        if (x & 0x100000000 > 0)
            result = result * 0x100000000B17217F80F4EF5AADDA45554 >> 128;
        if (x & 0x80000000 > 0)
            result = result * 0x10000000058B90BFBF8479BD5A81B51AD >> 128;
        if (x & 0x40000000 > 0)
            result = result * 0x1000000002C5C85FDF84BD62AE30A74CC >> 128;
        if (x & 0x20000000 > 0)
            result = result * 0x100000000162E42FEFB2FED257559BDAA >> 128;
        if (x & 0x10000000 > 0)
            result = result * 0x1000000000B17217F7D5A7716BBA4A9AE >> 128;
        if (x & 0x8000000 > 0)
            result = result * 0x100000000058B90BFBE9DDBAC5E109CCE >> 128;
        if (x & 0x4000000 > 0)
            result = result * 0x10000000002C5C85FDF4B15DE6F17EB0D >> 128;
        if (x & 0x2000000 > 0)
            result = result * 0x1000000000162E42FEFA494F1478FDE05 >> 128;
        if (x & 0x1000000 > 0)
            result = result * 0x10000000000B17217F7D20CF927C8E94C >> 128;
        if (x & 0x800000 > 0)
            result = result * 0x1000000000058B90BFBE8F71CB4E4B33D >> 128;
        if (x & 0x400000 > 0)
            result = result * 0x100000000002C5C85FDF477B662B26945 >> 128;
        if (x & 0x200000 > 0)
            result = result * 0x10000000000162E42FEFA3AE53369388C >> 128;
        if (x & 0x100000 > 0)
            result = result * 0x100000000000B17217F7D1D351A389D40 >> 128;
        if (x & 0x80000 > 0)
            result = result * 0x10000000000058B90BFBE8E8B2D3D4EDE >> 128;
        if (x & 0x40000 > 0)
            result = result * 0x1000000000002C5C85FDF4741BEA6E77E >> 128;
        if (x & 0x20000 > 0)
            result = result * 0x100000000000162E42FEFA39FE95583C2 >> 128;
        if (x & 0x10000 > 0)
            result = result * 0x1000000000000B17217F7D1CFB72B45E1 >> 128;
        if (x & 0x8000 > 0)
            result = result * 0x100000000000058B90BFBE8E7CC35C3F0 >> 128;
        if (x & 0x4000 > 0)
            result = result * 0x10000000000002C5C85FDF473E242EA38 >> 128;
        if (x & 0x2000 > 0)
            result = result * 0x1000000000000162E42FEFA39F02B772C >> 128;
        if (x & 0x1000 > 0)
            result = result * 0x10000000000000B17217F7D1CF7D83C1A >> 128;
        if (x & 0x800 > 0)
            result = result * 0x1000000000000058B90BFBE8E7BDCBE2E >> 128;
        if (x & 0x400 > 0)
            result = result * 0x100000000000002C5C85FDF473DEA871F >> 128;
        if (x & 0x200 > 0)
            result = result * 0x10000000000000162E42FEFA39EF44D91 >> 128;
        if (x & 0x100 > 0)
            result = result * 0x100000000000000B17217F7D1CF79E949 >> 128;
        if (x & 0x80 > 0)
            result = result * 0x10000000000000058B90BFBE8E7BCE544 >> 128;
        if (x & 0x40 > 0)
            result = result * 0x1000000000000002C5C85FDF473DE6ECA >> 128;
        if (x & 0x20 > 0)
            result = result * 0x100000000000000162E42FEFA39EF366F >> 128;
        if (x & 0x10 > 0)
            result = result * 0x1000000000000000B17217F7D1CF79AFA >> 128;
        if (x & 0x8 > 0)
            result = result * 0x100000000000000058B90BFBE8E7BCD6D >> 128;
        if (x & 0x4 > 0)
            result = result * 0x10000000000000002C5C85FDF473DE6B2 >> 128;
        if (x & 0x2 > 0)
            result = result * 0x1000000000000000162E42FEFA39EF358 >> 128;
        if (x & 0x1 > 0)
            result = result * 0x10000000000000000B17217F7D1CF79AB >> 128;

        result >>= uint256 (int256 (63 - (x >> 64)));
        require (result <= uint256 (int256 (MAX_64x64)));

        return int128 (int256 (result));
    }
    }

    /**
     * Calculate natural exponent of x.  Revert on overflow.
     *
     * @param x signed 64.64-bit fixed point number
   * @return signed 64.64-bit fixed point number
   */
    function exp (int128 x) internal pure returns (int128) {
    unchecked {
        require (x < 0x400000000000000000); // Overflow

        if (x < -0x400000000000000000) return 0; // Underflow

        return exp_2 (
            int128 (int256 (x) * 0x171547652B82FE1777D0FFDA0D23A7D12 >> 128));
    }
    }

    /**
     * Calculate x / y rounding towards zero, where x and y are unsigned 256-bit
     * integer numbers.  Revert on overflow or when y is zero.
     *
     * @param x unsigned 256-bit integer number
   * @param y unsigned 256-bit integer number
   * @return unsigned 64.64-bit fixed point number
   */
    function divuu (uint256 x, uint256 y) private pure returns (uint128) {
    unchecked {
        require (y != 0);

        uint256 result;

        if (x <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF)
            result = (x << 64) / y;
        else {
            uint256 msb = 192;
            uint256 xc = x >> 192;
            if (xc >= 0x100000000) { xc >>= 32; msb += 32; }
            if (xc >= 0x10000) { xc >>= 16; msb += 16; }
            if (xc >= 0x100) { xc >>= 8; msb += 8; }
            if (xc >= 0x10) { xc >>= 4; msb += 4; }
            if (xc >= 0x4) { xc >>= 2; msb += 2; }
            if (xc >= 0x2) msb += 1;  // No need to shift xc anymore

            result = (x << 255 - msb) / ((y - 1 >> msb - 191) + 1);
            require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            uint256 hi = result * (y >> 128);
            uint256 lo = result * (y & 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);

            uint256 xh = x >> 192;
            uint256 xl = x << 64;

            if (xl < lo) xh -= 1;
            xl -= lo; // We rely on overflow behavior here
            lo = hi << 128;
            if (xl < lo) xh -= 1;
            xl -= lo; // We rely on overflow behavior here

            assert (xh == hi >> 128);

            result += xl / y;
        }

        require (result <= 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        return uint128 (result);
    }
    }

    /**
     * Calculate sqrt (x) rounding down, where x is unsigned 256-bit integer
     * number.
     *
     * @param x unsigned 256-bit integer number
   * @return unsigned 128-bit integer number
   */
    function sqrtu (uint256 x) private pure returns (uint128) {
    unchecked {
        if (x == 0) return 0;
        else {
            uint256 xx = x;
            uint256 r = 1;
            if (xx >= 0x100000000000000000000000000000000) { xx >>= 128; r <<= 64; }
            if (xx >= 0x10000000000000000) { xx >>= 64; r <<= 32; }
            if (xx >= 0x100000000) { xx >>= 32; r <<= 16; }
            if (xx >= 0x10000) { xx >>= 16; r <<= 8; }
            if (xx >= 0x100) { xx >>= 8; r <<= 4; }
            if (xx >= 0x10) { xx >>= 4; r <<= 2; }
            if (xx >= 0x8) { r <<= 1; }
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1;
            r = (r + x / r) >> 1; // Seven iterations should be enough
            uint256 r1 = x / r;
            return uint128 (r < r1 ? r : r1);
        }
    }
    }
}