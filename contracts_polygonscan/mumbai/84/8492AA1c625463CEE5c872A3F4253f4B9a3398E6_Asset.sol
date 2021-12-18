// SPDX-License-Identifier: MIT
/// @dev size: 7.060 Kbytes
pragma solidity ^0.8.0;

import "./AssetStorage.sol";
import "./AssetInterface.sol";
import "./RiskModel.sol";

import "../utils/Counters.sol";
import "../security/Ownable.sol";

contract Asset is AssetInterface, AssetStorage, Ownable {
    using Counters for Counters.Counter;
    using Risk for Risk.Data;

    Counters.Counter private _tokenIds;
    Risk.Data private riskModel;

    event TokenizeAsset(uint256 indexed tokenId, string tokenHash,string tokenRating, uint256 value, string tokenURI, uint256 maturity, uint256 uploadedAt);

    constructor() ERC721("AmplifyAsset", "AAT") {}

    function tokenizeAsset(
        string memory tokenHash, 
        string memory tokenRating, 
        uint256 value, 
        uint256 maturity, 
        string memory tokenURI
    ) external returns (uint256) {
        _tokenIds.increment();

        uint256 newAssetId = _tokenIds.current();
        _mint(msg.sender, newAssetId);
        
        _tokens[newAssetId] = Token(
            value,
            maturity,
            riskModel.getInterestRate(tokenRating),
            riskModel.getAdvanceRate(tokenRating),
            tokenRating,
            tokenHash,
            false
        );
        _setTokenURI(newAssetId, tokenURI);

        emit TokenizeAsset(newAssetId, tokenHash, tokenRating, value, tokenURI, maturity, block.timestamp);
        return newAssetId;
    }

    function totalSupply() external view returns (uint256) {
        return _tokenIds.current();
    }

    function getTokenInfo(uint256 tokenId_) external override view returns (uint256, uint256, uint256, uint256, string memory, string memory, address, bool) {
        Token storage _info = _tokens[tokenId_];
        address owner = ownerOf(tokenId_);

        return (
            _info.value,
            _info.maturity,
            _info.interestRate,
            _info.advanceRate,
            _info.rating,
            _info._hash,
            owner,
            _info.redeemed
        );
    }

    function markAsRedeemed(uint256 tokenId) external override {
        require(ownerOf(tokenId) == msg.sender, "Only the owner can consume the asset");
        _tokens[tokenId].redeemed = true;
    }

    function addRiskItem(string memory rating, uint256 interestRate, uint256 advanceRate) external onlyOwner {
        riskModel.set(rating, interestRate, advanceRate);
    }

    function updateRiskItem(string memory rating, uint256 interestRate, uint256 advanceRate) external onlyOwner {
        riskModel.set(rating, interestRate, advanceRate);
    }

    function removeRiskItem(string memory rating) external onlyOwner {
        riskModel.remove(rating);
    }

    function getRiskItem(string calldata rating) external view returns (Risk.RiskItem memory) {
        return riskModel.riskItems[rating];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC721/ERC721URIStorage.sol";

abstract contract AssetStorage is ERC721URIStorage {
    struct Token {
        uint256 value;
        uint256 maturity;
        uint256 interestRate;
        uint256 advanceRate;
        string rating;
        string _hash;
        bool redeemed;
    }

    mapping(uint256 => Token) internal _tokens;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../ERC721/IERC721.sol";

abstract contract AssetInterface is IERC721 {
    bool public isAssetsFactory = true;

    function getTokenInfo(uint256 _tokenId) external virtual view returns (uint256, uint256, uint256, uint256, string memory, string memory, address, bool);
    function markAsRedeemed(uint256 tokenId) external virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Risk {
    struct Data {
        mapping(string => RiskItem) riskItems;
    }

    struct RiskItem {
        uint256 interestRate;
        uint256 advanceRate;
    }
    
    function set(Data storage self, string memory key, uint256 interestRate, uint256 advanceRate) public {
        self.riskItems[key] = RiskItem(interestRate, advanceRate);
    }

    function getInterestRate(Data storage self, string memory key) public view returns (uint256) {
        return self.riskItems[key].interestRate;
    }

    function getAdvanceRate(Data storage self, string memory key) public view returns (uint256) {
        return self.riskItems[key].advanceRate;
    }

    function remove(Data storage self, string memory key) public {
        delete self.riskItems[key];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Counters {
    struct Counter {
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
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Ownable {

    /// @notice owner address set on construction
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @notice Transfers ownership role
     * @notice Changes the owner of this contract to a new address
     * @dev Only owner
     * @param _newOwner beneficiary to vest remaining tokens to
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must be non-zero");
        
        address currentOwner = owner;
        require(_newOwner != currentOwner, "New owner cannot be the current owner");

        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC721.sol";

abstract contract ERC721URIStorage is ERC721 {
    mapping(uint => string) private _tokenURIs;

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
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

        return super.tokenURI(tokenId);
    }

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC721.sol";

contract ERC721 is IERC721, IERC721Metadata {
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

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }


    function balanceOf(address owner) public view virtual override returns (uint) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

     function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, toString(tokenId))) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");
        require(msg.sender == owner, "ERC721: approve caller is not owner");

        _approve(to, tokenId);
    }

    function transferFrom(address from, address to, uint tokenId) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function _isApprovedOrOwner(address spender, uint tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return spender == owner;
    }

    function _exists(uint tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _mint(address to, uint tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _transfer(address from, address to, uint tokenId) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    function _approve(address to, uint tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    function toString(uint value) internal pure returns (string memory) {
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

interface IERC721 {
    event Transfer(address indexed from, address indexed to, uint indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint indexed tokenId);

    function balanceOf(address owner) external view returns (uint balance);
    function ownerOf(uint tokenId) external view returns (address owner);
    
    function transferFrom(address from, address to, uint tokenId) external;
    function approve(address to, uint tokenId) external;
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint tokenId) external view returns (string memory);
}