// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Ownable.sol";
import "./SafeMath.sol";
import "./Address.sol";
import "./IBEP20.sol";
import "./ERC165.sol";
import "./IERC721Metadata.sol";
import "./EnumerableSet.sol";
import "./EnumerableMap.sol";
import "./IERC721Receiver.sol";
import "./IERC721Enumerable.sol";

contract KaguyaNFT is Ownable, ERC165, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    mapping(address => bool) private commonMints;
    mapping(address => bool) private uncommonMints;
    mapping(address => bool) private epicMints;
    bool public legendaryMint;
    uint256 public constant MAX_COMMON_NFT_SUPPLY = 200;
    uint256 public commonMinted = 0;
    uint256 public constant MAX_UNCOMMON_NFT_SUPPLY = 100;
    uint256 public uncommonMinted = 0;
    uint256 public constant MAX_RARE_NFT_SUPPLY = 50;
    uint256 public rareMinted = 0;
    uint256 public constant MAX_EPIC_NFT_SUPPLY = 5;
    uint256 public epicMinted = 0;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;
    EnumerableMap.UintToAddressMap private _tokenOwners;
    mapping (uint256 => address) private _tokenApprovals;

    mapping (uint256 => string) private _tokenName;
    mapping (uint256 => uint8) private _tokenRarity;
    mapping (uint256 => uint256) private _epicIdToFile;
	mapping (uint256 => uint256) private _generalIdToTierId;
	// rarity => rarity index -> global index
	mapping (uint256 => mapping (uint256 => uint256)) _tierIdToGeneralId;
    uint256 private _epicIdIndex = 1;
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    string private _name;
    string private _symbol;

    IBEP20 private _kaguyaToken;
    IBEP20 private _oldToken;
    IBEP20 private _dokiToken;

	uint256 private mintPrice = 0.1 ether;
	uint256 private minTokens = 500000 * (10 ** 9);

    address public winner;
    mapping (address => bool) public runnerUps;

    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x93254542;
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    string private _baseUri = "https://kaguyahime.asia/nft2/";
	string private _fileExt = ".png";

    constructor () {
        _name = "KaguyaNFT";
        _symbol = "KAGUYA";
        _kaguyaToken = IBEP20(0xb03489e263ECa0F622586e83EB51a68Cb26E5a02);
        _oldToken = IBEP20(0xbE237aa731c46B81118D238b4B181bA84962bD0a);
        _dokiToken = IBEP20(0x0603c8381f050cBB024F27770b59B24a6860CFD9);

        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    function setBaseUri(string calldata uri) external onlyOwner {
        _baseUri = uri;
    }

	function setExtension(string calldata ext) external onlyOwner {
		_fileExt = ext;
	}

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");

        return _holderTokens[owner].length();
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

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
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        (, uint8 rarity, uint256 tierId) = getNFTInformation(tokenId);
        string memory rfolder = "common/";
        if (rarity == 2) {
            rfolder = "uncommon/";
        }
        if (rarity == 3) {
            rfolder = "rare/";
        }
        if (rarity == 4) {
            rfolder = "epic/";
        }
        if (rarity == 5) {
            rfolder = "legendary/";
        }

        return string(abi.encodePacked(_baseUri, rfolder, uint2str(tierId), _fileExt));
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    function totalSupply() public view override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    function tokenByIndex(uint256 index) public view override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
    }

    function tokenNameByIndex(uint256 index) public view returns (string memory) {
        return _tokenName[index];
    }

    function mintRareNFT() public payable {
        require(rareMinted < MAX_RARE_NFT_SUPPLY, "No more available rare NFTs.");
        require(mintPrice == msg.value, "BNB value sent is not correct. Rare mint costs 0.1 BNB.");

        uint mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex, "Rare Kaguya", 3);
        payable(owner()).transfer(msg.value);
		_generalIdToTierId[mintIndex] = rareMinted;
		_tierIdToGeneralId[3][rareMinted] = mintIndex;
		rareMinted++;
    }

    /**
     * @dev Payable Rare NFT, paid by for DOKI
     */
    function mintRareNFTWithDoki() external {
        require(rareMinted < MAX_RARE_NFT_SUPPLY, "No more available rare NFTs.");
        uint256 balance = _dokiToken.balanceOf(msg.sender);
        require(balance >= 100000000000000000, "You need to pay 0.1 DOKI for this.");
        _dokiToken.transferFrom(msg.sender, address(0), mintPrice);

        uint256 mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex, "Rare Kaguya", 3);
		_generalIdToTierId[mintIndex] = rareMinted;
		_tierIdToGeneralId[3][rareMinted] = mintIndex;
		rareMinted++;
    }

    function redeemCommonNFT() external {
        require(commonMinted < MAX_COMMON_NFT_SUPPLY, "No more free NFTs available currently.");
        require(!commonMints[msg.sender], "You can only redeem one Common NFT.");
		uint256 balance1 = _kaguyaToken.balanceOf(msg.sender);
		uint256 balance2 = _oldToken.balanceOf(msg.sender);
		require(balance1 > 0 || balance2 > 0, "You need to own either KAGUYA v1 or v2 to redeem this.");

        uint mintIndex = totalSupply();
        commonMints[msg.sender] = true;
        _safeMint(msg.sender, mintIndex, "The dev is useless", 1);
		_generalIdToTierId[mintIndex] = commonMinted;
		_tierIdToGeneralId[1][commonMinted] = mintIndex;
		commonMinted++;
    }

    function redeemUncommonNFT() external {
        require(uncommonMinted < MAX_UNCOMMON_NFT_SUPPLY, "No more free NFTs available currently.");
        require(!uncommonMints[msg.sender], "You can only redeem one Uncommon NFT.");
        uint256 balance = _kaguyaToken.balanceOf(msg.sender);
        require(balance >= minTokens, "You need more KAGUYA to redeem this.");

        uncommonMints[msg.sender] = true;
        uint mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex, "Rare Kaguya", 2);
		_generalIdToTierId[mintIndex] = uncommonMinted;
		_tierIdToGeneralId[2][uncommonMinted] = mintIndex;
		uncommonMinted++;
    }

    /**
     * @dev To claim legendary. Due to what happened with V1, the winner may no longer be interested,
     * so with this we can change it to the next top holder until someone claims the NFT.
     * It would be a shame if no one claimed it ever.
     */
    function setWinner(address win) external onlyOwner {
        winner = win;
    }

    function addRunnerUp(address runnerup) external onlyOwner {
        runnerUps[runnerup] = true;
    }

    function removeRunnerUp(address runnerup) external onlyOwner {
        runnerUps[runnerup] = false;
    }

	function setTokenMintPrice(uint256 price) external onlyOwner {
		minTokens = price;
	}

	function setBnbMintPrice(uint256 price) external onlyOwner {
		mintPrice = price;
	}

    function redeemEpicNFT() external {
        require(!epicMints[msg.sender], "You can only redeem one Epic NFT.");
        require(runnerUps[msg.sender], "Only the top five Kaguya holders can redeem this.");
        require(epicMinted < MAX_EPIC_NFT_SUPPLY, "All epic NFTs have been minted.");

        uint mintIndex = totalSupply();
        _epicIdToFile[mintIndex] = _epicIdIndex;
        _safeMint(msg.sender, mintIndex, "Epic Kaguya", 4);
		_generalIdToTierId[mintIndex] = _epicIdIndex;
		_tierIdToGeneralId[4][_epicIdIndex] = mintIndex;
		_epicIdIndex++;
        if (_epicIdIndex >= 6) {
            _epicIdIndex = 1;
        }
    }

    function redeemLegendaryNFT() external {
        require(!legendaryMint, "You can only redeem the Legendary NFT once.");
        require(winner == msg.sender, "Only the top Kaguya holder can redeem this.");

        uint mintIndex = totalSupply();
        _safeMint(msg.sender, mintIndex, "The LEGENDARY Kaguya", 5);
		_generalIdToTierId[mintIndex] = 1;
		_tierIdToGeneralId[5][1] = mintIndex;
    }

    function getGeneralIdByRarityId(uint256 rarity, uint256 id) external view returns (uint256) {
		return _tierIdToGeneralId[rarity][id];
	}

	function setKaguya(address addy) external onlyOwner {
		_kaguyaToken = IBEP20(addy);
	}

    function setOldAddress(address addy) onlyOwner external {
        _oldToken = IBEP20(addy);
    }

    function setDokiAddress(address fuwafuwatime) onlyOwner external {
        _dokiToken = IBEP20(fuwafuwatime);
    }

    function withdraw() onlyOwner public {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(msg.sender == owner || isApprovedForAll(owner, msg.sender),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
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
    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
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

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(msg.sender, tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return _tokenOwners.contains(tokenId);
    }

    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    function _safeMint(address to, uint256 tokenId, string memory nftName, uint8 rarity) internal virtual {
        _mint(to, tokenId);
        _tokenName[tokenId] = nftName;
        _tokenRarity[tokenId] = rarity;
        bytes memory _data = abi.encodePacked(nftName, rarity);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(address(0), to, tokenId);
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

        emit Transfer(owner, address(0), tokenId);
    }

    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            msg.sender,
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    function _approve(address to, uint256 tokenId) private {
        _tokenApprovals[tokenId] = to;
        emit Approval(ownerOf(tokenId), to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual {}

    function getNFTInformation(uint256 tokenId) public view returns(string memory, uint8, uint256) {
        return (_tokenName[tokenId], _tokenRarity[tokenId], _generalIdToTierId[tokenId]);
    }
}