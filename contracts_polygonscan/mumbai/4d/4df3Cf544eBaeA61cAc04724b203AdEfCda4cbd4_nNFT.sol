// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import './SafeMath.sol';
import './IERC721.sol';
import './Ownable.sol';

contract nNFT is IERC721, Ownable {
    using SafeMath for uint256;

    event Mint(uint256 indexed index, address indexed minter);
    event PeckerOffered(uint256 indexed peckerIndex, uint256 minValue, address indexed toAddress);
    event PeckerBidEntered(uint256 indexed peckerIndex, uint256 value, address indexed fromAddress);
    event PeckerBidWithdrawn(uint256 indexed peckerIndex, uint256 value, address indexed fromAddress);
    event PeckerBought(
        uint256 indexed peckerIndex,
        uint256 value,
        address indexed fromAddress,
        address indexed toAddress
    );
    event PeckerNoLongerForSale(uint256 indexed peckerIndex);

    /**
     * Event emitted when the public sale begins.
     */
    event SaleBegins();

    event updateCharityAddress(address newCharity);
    event updateReferralFee(uint256 newFee);
    event updateCharityFee(uint256 newFee);
    event updateMintPrice(uint256 mintPrice);
    event updateTokenURI(string newURI);
    event addReferral(address referralAddress);
    event removeReferral(address referralAddress);

    bytes4 internal constant MAGIC_ON_ERC721_RECEIVED = 0x150b7a02;

    uint256 public constant TOKEN_LIMIT = 10000;

    mapping(bytes4 => bool) internal supportedInterfaces;

    mapping(uint256 => address) internal idToOwner;

    mapping(uint256 => address) internal idToApproval;

    mapping(address => mapping(address => bool)) internal ownerToOperators;

    mapping(address => uint256[]) internal ownerToIds;

    mapping(uint256 => uint256) internal idToOwnerIndex;

    mapping(address => bool) internal referralWhiteList;
    
    string internal nftName;
    string internal nftSymbol;

    string public baseURI;

    // You can use this hash to verify the image file containing all the NFTS
    string public imageHash;

    uint256 internal numTokens = 0;

    address payable public charity;

    uint256 internal generatedGiveAway = 0;
    uint256 internal maxGiveAway = 100;

    bool public publicSale = false;
    uint256 private mintPrice = 10000000 gwei;
    uint256 private maxDonations;
    uint256 private totalDonations = 0;
    uint256 public saleStartTime;

    uint256 private charityFee;
    uint256 private referralFee;

    //// Random index assignment
    uint256 internal nonce = 0;
    uint256[TOKEN_LIMIT] internal indices;

    //// Market
    bool public marketPaused;
    bool public contractSealed;
    mapping(address => uint256) public ethBalance;
    mapping(bytes32 => bool) public cancelledOffers;

    bool private reentrancyLock = false;

    /* Prevent a contract function from being reentrant-called. */
    modifier reentrancyGuard() {
        if (reentrancyLock) {
            revert();
        }
        reentrancyLock = true;
        _;
        reentrancyLock = false;
    }

    modifier canOperate(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == msg.sender || ownerToOperators[tokenOwner][msg.sender], 'Cannot operate.');
        _;
    }

    modifier canTransfer(uint256 _tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(
            tokenOwner == msg.sender ||
                idToApproval[_tokenId] == msg.sender ||
                ownerToOperators[tokenOwner][msg.sender],
            'Cannot transfer.'
        );
        _;
    }

    modifier validNFToken(uint256 _tokenId) {
        require(idToOwner[_tokenId] != address(0), 'Invalid token.');
        _;
    }

    constructor(
        string memory _nftName,
        string memory _nftSymbol,
        string memory _baseURI,
        address payable _charity,
        string memory _imageHash
    ) {
        supportedInterfaces[0x01ffc9a7] = true; // ERC165
        supportedInterfaces[0x80ac58cd] = true; // ERC721
        supportedInterfaces[0x780e9d63] = true; // ERC721 Enumerable
        supportedInterfaces[0x5b5e139f] = true; // ERC721 Metadata
        require(owner() != address(0), 'Owner must be set');
        nftName = _nftName;
        nftSymbol = _nftSymbol;

        charity = _charity;
        imageHash = _imageHash;
        baseURI = _baseURI;
        charityFee = 50;
        referralFee = 10;
        maxDonations = 100 ether;
    }

    function startSale() external onlyOwner {
        require(!publicSale);
        saleStartTime = block.timestamp;
        publicSale = true;
        emit SaleBegins();
    }

    function pauseMarket(bool _paused) external onlyOwner {
        require(!contractSealed, 'Contract sealed.');
        marketPaused = _paused;
    }

    function setCharityAddress(address payable newCharity) external onlyOwner {
        require(newCharity != address(0), 'Cannot be 0x0');
        charity = newCharity;
        emit updateCharityAddress(charity);
    }

    function setReferralFee(uint256 newFee) external onlyOwner {
        require(newFee < 50, 'Fee too high');
        referralFee = newFee;
        emit updateReferralFee(referralFee);
    }

    function setCharityFee(uint256 newFee) external onlyOwner {
        require(newFee < 50, 'Fee too high');
        referralFee = newFee;
        emit updateCharityFee(referralFee);
    }

    function setMintPrice(uint256 newPrice) external onlyOwner {
        mintPrice = newPrice;
        emit updateMintPrice(mintPrice);
    }

    function sealContract() external onlyOwner {
        contractSealed = true;
    }

    function setTokenURI(string memory newURI) external onlyOwner {
        baseURI = newURI;
        emit updateTokenURI(baseURI);
    }

    //////////////////////////
    //// ERC 721 and 165  ////
    //////////////////////////

    function isContract(address _addr) internal view returns (bool addressCheck) {
        uint256 size;
        assembly {
            size := extcodesize(_addr)
        } // solhint-disable-line
        addressCheck = size > 0;
    }

    function supportsInterface(bytes4 _interfaceID) external view override returns (bool) {
        return supportedInterfaces[_interfaceID];
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes calldata _data
    ) external override {
        _safeTransferFrom(_from, _to, _tokenId, _data);
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external override {
        _safeTransferFrom(_from, _to, _tokenId, '');
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external override canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, 'Wrong from address.');
        require(_to != address(0), 'Cannot send to 0x0.');
        _transfer(_to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId)
        external
        override
        canOperate(_tokenId)
        validNFToken(_tokenId)
    {
        address tokenOwner = idToOwner[_tokenId];
        require(_approved != tokenOwner);
        idToApproval[_tokenId] = _approved;
        emit Approval(tokenOwner, _approved, _tokenId);
    }

    function setApprovalForAll(address _operator, bool _approved) external override {
        ownerToOperators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function balanceOf(address _owner) external view override returns (uint256) {
        require(_owner != address(0));
        return _getOwnerNFTCount(_owner);
    }

    function ownerOf(uint256 _tokenId) public view override returns (address _owner) {
        require(idToOwner[_tokenId] != address(0));
        _owner = idToOwner[_tokenId];
    }

    function getApproved(uint256 _tokenId) external view override validNFToken(_tokenId) returns (address) {
        return idToApproval[_tokenId];
    }

    function isApprovedForAll(address _owner, address _operator) external view override returns (bool) {
        if (_operator == address(0x58807baD0B376efc12F5AD86aAc70E78ed67deaE)) {
            // opensea proxy address
            return true;
        } // add other makerts into the approval
        return ownerToOperators[_owner][_operator];
    }

    function _transfer(address _to, uint256 _tokenId) internal {
        address from = idToOwner[_tokenId];
        _clearApproval(_tokenId);

        _removeNFToken(from, _tokenId);
        _addNFToken(_to, _tokenId);

        emit Transfer(from, _to, _tokenId);
    }

    function randomIndex() internal returns (uint256) {
        uint256 totalSize = TOKEN_LIMIT.sub(numTokens);
        uint256 index = uint256(keccak256(abi.encodePacked(nonce, msg.sender, block.difficulty, block.timestamp))) %
            totalSize;
        uint256 value = 0;
        if (indices[index] != 0) {
            value = indices[index];
        } else {
            value = index;
        }

        // Move last value to selected position
        if (indices[totalSize.sub(1)] == 0) {
            // Array position not initialized, so use position
            indices[index] = totalSize.sub(1);
        } else {
            // Array position holds a value so use that
            indices[index] = indices[totalSize.sub(1)];
        }
        nonce++;
        // Don't allow a zero index, start counting at 1
        return value.add(1);
    }

    function mintsRemaining() external view returns (uint256) {
        return TOKEN_LIMIT.sub(numTokens);
    }

    /**
     * Public sale minting.
     */
    function mint(uint256 numberOfNfts, address payable referralAddress) external payable reentrancyGuard {
        require(publicSale, 'Sale not started.');
        require(!marketPaused);
        require(numberOfNfts > 0, 'numberOfNfts cannot be 0');
        require(numberOfNfts <= 20, 'You can not buy more than 20 NFTs at once');
        require(totalSupply().add(numberOfNfts) <= TOKEN_LIMIT, 'Exceeds TOKEN_LIMIT');

        require(mintPrice.mul(numberOfNfts) == msg.value, 'eth value sent is not correct');

        uint256 referralAmount = 0;
        if (referralAddress != address(0) && referralAddress != msg.sender && referralWhiteList[referralAddress]) {
            referralAmount = _calculateReferralFee(msg.value);
            referralAddress.transfer(referralAmount);
        }

        uint256 charityAmount = 0;
        if (totalDonations < maxDonations) {
            charityAmount = _calculateCharityFee(msg.value);
            totalDonations = totalDonations.add(charityAmount);
            charity.transfer(charityAmount);
        }

        payable(owner()).transfer(msg.value.sub(charityAmount).sub(referralAmount));

        for (uint256 i = 0; i < numberOfNfts; i++) {
            _mint(msg.sender);
        }
    }

    function giveAway(address luckyWinner) public onlyOwner {
        if (generatedGiveAway < maxGiveAway) {
            generatedGiveAway = generatedGiveAway.add(1);
            _mint(luckyWinner);
        }
    }

    function addToReferral(address referralAddress) public {
        referralWhiteList[referralAddress] = true;
        emit addReferral(referralAddress);
    }

    function removeFromReferral(address referralAddress) public {
        referralWhiteList[referralAddress] = false;
        emit removeReferral(referralAddress);
    }

    function _calculateCharityFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(charityFee).div(10**2);
    }

    function _calculateReferralFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(referralFee).div(10**2);
    }

    function _mint(address _to) internal returns (uint256) {
        require(_to != address(0), 'Cannot mint to 0x0.');
        require(numTokens < TOKEN_LIMIT, 'Token limit reached.');
        uint256 id = randomIndex();

        numTokens++;
        _addNFToken(_to, id);

        emit Mint(id, _to);
        emit Transfer(address(0), _to, id);
        return id;
    }

    function _addNFToken(address _to, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == address(0), 'Cannot add, already owned.');
        idToOwner[_tokenId] = _to;

        ownerToIds[_to].push(_tokenId);
        idToOwnerIndex[_tokenId] = ownerToIds[_to].length.sub(1);
    }

    function _removeNFToken(address _from, uint256 _tokenId) internal {
        require(idToOwner[_tokenId] == _from, 'Incorrect owner.');
        delete idToOwner[_tokenId];

        uint256 tokenToRemoveIndex = idToOwnerIndex[_tokenId];
        uint256 lastTokenIndex = ownerToIds[_from].length.sub(1);

        if (lastTokenIndex != tokenToRemoveIndex) {
            uint256 lastToken = ownerToIds[_from][lastTokenIndex];
            ownerToIds[_from][tokenToRemoveIndex] = lastToken;
            idToOwnerIndex[lastToken] = tokenToRemoveIndex;
        }

        ownerToIds[_from].pop();
    }

    function _getOwnerNFTCount(address _owner) internal view returns (uint256) {
        return ownerToIds[_owner].length;
    }

    function _safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) private canTransfer(_tokenId) validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, 'Incorrect owner.');
        require(_to != address(0));

        _transfer(_to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    function _safeTransfer(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory _data
    ) private validNFToken(_tokenId) {
        address tokenOwner = idToOwner[_tokenId];
        require(tokenOwner == _from, 'Incorrect owner.');
        require(_to != address(0));

        _transfer(_to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = ERC721TokenReceiver(_to).onERC721Received(msg.sender, _from, _tokenId, _data);
            require(retval == MAGIC_ON_ERC721_RECEIVED);
        }
    }

    function _clearApproval(uint256 _tokenId) private {
        if (idToApproval[_tokenId] != address(0)) {
            delete idToApproval[_tokenId];
        }
    }

    //// Enumerable

    function totalSupply() public view returns (uint256) {
        return numTokens;
    }

    function tokenByIndex(uint256 index) public pure returns (uint256) {
        require(index >= 0 && index < TOKEN_LIMIT);
        return index + 1;
    }

    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256) {
        require(_index < ownerToIds[_owner].length);
        return ownerToIds[_owner][_index];
    }

    //// Metadata

    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
     */

    function toString(uint256 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return '0';
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

    /**
     * @dev Returns a descriptive name for a collection of NFTokens.
     * @return _name Representing name.
     */
    function name() external view returns (string memory _name) {
        _name = nftName;
    }

    /**
     * @dev Returns an abbreviated name for NFTokens.
     * @return _symbol Representing symbol.
     */
    function symbol() external view returns (string memory _symbol) {
        _symbol = nftSymbol;
    }

    /**
     * @dev A distinct URI (RFC 3986) for a given NFT.
     * @param _tokenId Id for which we want uri.
     * @return _tokenId URI of _tokenId.
     */
    function tokenURI(uint256 _tokenId) external view validNFToken(_tokenId) returns (string memory) {
        return string(abi.encodePacked(baseURI, toString(_tokenId)));
    }

    /**
     * @param _address address to check
     * @return bool
     */
    function isInReferralWhitelist(address _address) external view returns (bool) {
        return referralWhiteList[_address];
    }
}