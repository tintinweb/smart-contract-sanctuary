// SPDX-License-Identifier: MIT LICENSE

pragma solidity >0.8.0;

library MerkleProof {
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
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
        return computedHash;
    }
}

library Address {
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

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }


    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

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


    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }


    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }


    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }


    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            if (returndata.length > 0) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

interface IERC165 {
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

interface ITraits {
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    function toString(uint256 value) internal pure returns (string memory) {
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

abstract contract ERC165 is IERC165 {
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);
    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;
    function getApproved(uint256 tokenId) external view returns (address operator);
    function setApprovalForAll(address operator, bool _approved) external;
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _setOwner(_msgSender());
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
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

interface IERC721Enumerable is IERC721 {
    function totalSupply() external view returns (uint256);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
    function tokenByIndex(uint256 index) external view returns (uint256);
}

interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;
    string private _name;
    string private _symbol;
    mapping(uint256 => address) private _owners;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
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

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");
        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

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

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

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

    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

abstract contract ERC721Enumerable is ERC721, IERC721Enumerable {
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;
    mapping(uint256 => uint256) private _ownedTokensIndex;
    uint256[] private _allTokens;
    mapping(uint256 => uint256) private _allTokensIndex;

    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC721) returns (bool) {
        return interfaceId == type(IERC721Enumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Enumerable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
}

contract GameFI is ERC721Enumerable, Ownable {
    uint256 public MAX_TOKENS = 1888;
    uint256 public reserved = 88;
    uint16 public minted;
    uint16 public reserveMinted;
    uint256 lastMintBlock;
    uint16 tier1;
    uint16 tier2;
    uint16 tier3;
    bytes32 rootHash = 0x2fbbf2351e3f33e7fbf3f6156a07fab5da10d73f48ebd5ebb79b6ad0abddb8cd;

    uint256 private WhitelistPRICE = 0.2 ether;
    uint256 private auctionStartPrice = 1.5 ether;
    uint256 private auctionEndPrice = 0.3 ether;
    uint256 private auctionDuration = 14400;
    uint256 private auctionStartTime = 1639742400;


    struct GameFi{
        uint8 tier;
        uint8 character;
    }

    mapping(uint256 => uint256) mintBlock;
    mapping(uint256 => GameFi) public tokenTraits;
    mapping (address => uint256) claimed;

    bool publicSaleMode = true;
    bool whitelistMode = true;

    uint8[] elemental;

    ITraits traits;

    constructor() ERC721("GAMEFI CLUB", "GAMEFI CLUB") {
        elemental = [0,1,2,3,4,5,6,7,8,9];
    }

    function getAuctionPrice() public view returns (uint256) {
	if (block.timestamp < auctionStartTime){return auctionStartPrice;}
        if (auctionStartTime > 0) {
            if (block.timestamp - auctionStartTime >= auctionDuration) {
                return auctionEndPrice;
            } else {
                uint256 price = auctionStartPrice -
                    ((auctionStartPrice - auctionEndPrice) *
                        (block.timestamp - auctionStartTime)) /
                    auctionDuration;
                return
                    price <= auctionEndPrice
                        ? auctionEndPrice
                        : price;
            }
        }
        return auctionEndPrice;
    }


    function mint(uint256 amount) external payable {
        require(publicSaleMode && block.timestamp >= auctionStartTime, "Public Sale not yet enabled");
        require(tx.origin == _msgSender(), "Only EOA");
        require(minted + amount <= (MAX_TOKENS - (reserved - reserveMinted)), "All tokens minted");
        require(msg.value >= getAuctionPrice(), "Invalid payment amount");
        uint256 seed;
        for (uint256 i = 0; i < amount; i++) {
    	    minted++;
    	    mintBlock[minted] = block.number;
            lastMintBlock = block.number;
    	    seed = random(minted);
    	    generate(minted, seed);
    	    _safeMint(msg.sender, minted);
            if(tokenTraits[minted].tier == 0){tier1++;} else if(tokenTraits[minted].tier == 1){tier2++;} else {tier3++;}
    	}
    }

    function whitelistMint(bytes32[] calldata _merkleProof) external payable {
        require(whitelistMode && block.timestamp < auctionStartTime, "Whitelist minting is disabled");
        require(claimed[msg.sender] < 2, "Already claimed");
        require(minted + 1 <= (MAX_TOKENS - (reserved - reserveMinted)), "All tokens minted");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof,rootHash,leaf), "invalid proof.");
        require(msg.value >= WhitelistPRICE, "Invalid payment amount");
        claimed[msg.sender] ++;
        uint256 seed;
        minted++;
	    mintBlock[minted] = block.number;
        lastMintBlock = block.number;
        seed = random(minted);
        generate(minted, seed);
        _safeMint(msg.sender,minted);
        if(tokenTraits[minted].tier == 0){tier1++;} else if(tokenTraits[minted].tier == 1){tier2++;} else {tier3++;}
    }

    function reserveMint(uint256 amount) external onlyOwner {
        require(reserveMinted + amount <= reserved, "All reserve tokens minted");
        uint256 seed;
        for (uint256 i = 0; i < amount; i++) {
            reserveMinted++;
    	    minted++;
    	    seed = random(minted);
    	    generate(minted, seed);
    	    _safeMint(msg.sender, minted);
            if(tokenTraits[minted].tier == 0){tier1++;} else if(tokenTraits[minted].tier == 1){tier2++;} else {tier3++;}
    	}
    }


    function transferFrom(address from,address to,uint256 tokenId) public virtual override {
        if (_msgSender() != address(this)){require(_isApprovedOrOwner(_msgSender(), tokenId),"ERC721: transfer caller is not owner nor approved");}
        _transfer(from, to, tokenId);
    }

    function generate(uint256 tokenId, uint256 seed) internal returns (GameFi memory t) {
        t = selectTraits(seed);
        tokenTraits[tokenId] = t;
        return t;
    }


    function selectElement(uint16 seed)
        internal
        view
        returns (uint8)
    {
        uint8 chosenElement = uint8(seed) % uint8(elemental.length);
        return elemental[chosenElement];
    }

    function selectTier(uint256 seed) internal view returns (uint8){
        uint256 tiercalc = (seed & 0xFFFF) % 500;
        if(tiercalc == 499 && tier1 < 50){return 0;} else if(tiercalc >= 495 && tier2 < 500){return 1;} else {
	    return 2;
	    }
    }

    function selectTraits(uint256 seed) internal view returns (GameFi memory t){
        t.tier = selectTier(seed);
        seed >>= 16;
        t.character = selectElement(uint16(seed & 0xFFFF));
    }

    function random(uint256 seed) internal view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(tx.origin,block.timestamp,seed, blockhash(block.number - 3))));
    }

    function getTokenTraits(uint256 tokenId) external view  returns (GameFi memory)
    {require(mintBlock[tokenId] + 1 < block.number);
        return tokenTraits[tokenId];
    }

    function tokenTier(uint256 tokenId) external view returns (uint256 TIER){
        require(mintBlock[tokenId] + 1 < block.number);
        return((tokenTraits[tokenId].tier+1));
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function enableWhitelistMinting()external onlyOwner {
        whitelistMode = true;
        publicSaleMode = false;
    }

    function startAuction()external onlyOwner {
        whitelistMode = false;
        publicSaleMode = true;
    }

    function setTraits(address _traits)external onlyOwner {
        traits = ITraits(_traits);
    }

    function setrootHash(bytes32 _rootHash)external onlyOwner {
        rootHash = _rootHash;
    }

    function setMintPrices(uint256 wlPrice, uint256 startPrice, uint256 endPrice ) external onlyOwner{
        WhitelistPRICE = wlPrice;
        auctionStartPrice = startPrice;
        auctionEndPrice = endPrice;
    }

    function numTiersMinted() external view  returns (uint16 Tier1,uint16 Tier2,uint16 Tier3){
        require(block.number > lastMintBlock);
        return (tier1, tier2, tier3);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        require(mintBlock[tokenId] + 1 < block.number);
        return traits.tokenURI(tokenId);
  }


    function fuseTier3to2(uint256 upgradeTokenID,uint256 burnTokenID) external {
        require(tier2 < 500);
        require(upgradeTokenID != burnTokenID);    
        require(msg.sender == ownerOf(upgradeTokenID) && msg.sender == ownerOf(burnTokenID));
        require(tokenTraits[upgradeTokenID].tier == 2 && tokenTraits[burnTokenID].tier == 2);
        tier3 = tier3-2;
        tier2++;
        this.transferFrom(msg.sender, address(0xDead), burnTokenID);
        tokenTraits[upgradeTokenID].tier = 1;
  }


    function fuseTier2to1(uint256 upgradeTokenID,uint256 burnTokenID) external payable{
        require(tier1 < 50);
        require(msg.value >= 0.5 ether);
        require(upgradeTokenID != burnTokenID);    
        require(msg.sender == ownerOf(upgradeTokenID) && msg.sender == ownerOf(burnTokenID) );
        require(tokenTraits[upgradeTokenID].tier == 1 && tokenTraits[burnTokenID].tier == 1);
        tier2 = tier2-1;
        tier1++;
        this.transferFrom(msg.sender, address(0xDead), burnTokenID);
        tokenTraits[upgradeTokenID].tier = 0;
  }

    function upgradeTier2to1(uint256 upgradeTokenID) external payable{
        require(tier1 < 50);
        require(msg.value >= 1 ether);
        require(msg.sender == ownerOf(upgradeTokenID));
        require(tokenTraits[upgradeTokenID].tier == 1);
        tier2--;
        tier1++;
        tokenTraits[upgradeTokenID].tier = 0;
  }

    function upgradeTier3to1(uint256 upgradeTokenID) external payable{
        require(tier1 < 50);
        require(msg.value >= 1.75 ether);
        require(msg.sender == ownerOf(upgradeTokenID));
        require(tokenTraits[upgradeTokenID].tier == 2);
        tier3--;
        tier1++;
        tokenTraits[upgradeTokenID].tier = 0;
  }
    function upgradeTier3to2(uint256 upgradeTokenID) external payable{
        require(tier2 < 500);
        require(msg.value >= 0.75 ether);
        require(msg.sender == ownerOf(upgradeTokenID));
        require(tokenTraits[upgradeTokenID].tier == 2);
        tier3--;
        tier2++;
        tokenTraits[upgradeTokenID].tier = 1;
  }

    function getIDsOwnedby(address _address) external view returns(uint256[] memory) {
        uint256[] memory tokensOwned = new uint256[](balanceOf(_address));
        for(uint256 i = 0; i < tokensOwned.length; i++) {
            tokensOwned[i] = tokenOfOwnerByIndex(_address, i);
        }
        return tokensOwned;
    }

    function getTokeninfo(address _address) external view returns(uint256[] memory tokenid,uint256[] memory tier) {
        uint256[] memory tokensOwned = new uint256[](balanceOf(_address));
        uint256[] memory tokenTiers = new uint256[](balanceOf(_address));
        for(uint256 i = 0; i < tokensOwned.length; i++) {
            tokensOwned[i] = tokenOfOwnerByIndex(_address, i);
            tokenTiers[i] = tokenTraits[i].tier+1;
        }
        return (tokensOwned, tokenTiers);
    }

    function timeTillDutchAuction() external view returns(uint256){
        uint256 remainingtime = auctionStartTime - block.timestamp;
        if(block.timestamp >= auctionStartTime){
        return 0;
        }
        return remainingtime;    
    }

    function setAuctionStartTime(uint256 time) external onlyOwner{
        auctionStartTime = time;
    }

}