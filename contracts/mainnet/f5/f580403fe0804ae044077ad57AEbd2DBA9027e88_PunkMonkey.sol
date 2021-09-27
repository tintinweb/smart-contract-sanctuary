// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./ERC721.sol";
import "./ERC721Enumerable.sol";
import "./Ownable.sol";
import "./Address.sol";
import "./Strings.sol";

interface CryptoMonkeyKing {
    function balanceOf(address _owner) external view returns (uint256);
}

contract PunkMonkey is Ownable, ERC721Enumerable {
    using Address for address;
    using Strings for uint256;

    /************************************struct********************************/
    enum NFTType {
        Black,
        White
    }

    struct NFT {
        uint256 id;
        address owner;
        uint256 state;
        NFTType nftType;
        string name;
        string imageHash;
    }

    struct NFTMeta {
        NFTType nftType;
        string name;
        string imageHash;
        uint256 diyCount;
        uint256 nameCount;
    }

    struct MintStat {
        uint256 minted;
    }

    /************************************error********************************/
    string constant ID_IS_NOT_VALID = "004000";
    string constant ID_IS_RESERVE = "004001";
    string constant ID_IS_NOT_RESERVE = "004002";
    string constant ID_IS_CMK = "004003";
    string constant ID_IS_NOT_CMK = "004004";
    string constant ID_IS_NOT_FREE = "004005";
    string constant ID_IS_WHITE = "004006";
    string constant ID_IS_NOT_WHITE = "004007";

    string constant NFT_HAS_OWNER = "004020";
    string constant NFT_HAS_NO_OWNER = "004021";
    string constant NFT_IS_MAPPING_OWNER = "004022";
    string constant NFT_IS_NOT_MAPPINT_OWNER = "004023";
    string constant NFT_IS_NOT_ENOUGH = "004024";

    string constant ADDRESS_IS_NOT_VALID = "004030";
    string constant ADDRESS_IS_NOT_CONTRACT = "004031";
    string constant ADDRESS_IS_NOT_AIRDROP = "004032";
    string constant ADDRESS_IS_NOT_CMK = "004033";

    string constant BALANCE_NOT_ENOUGH = "004040";
    string constant AREA_IS_NOT_VALID = "004050";

    string constant OUT_OF_MAX_CMK_VIP_MINT = "004060";
    string constant OUT_OF_MAX_CMK_MINT = "004061";
    string constant OUT_OF_MAX_FREE_MINT = "004062";
    string constant OUT_OF_MAX_DIY_COUNT = "004063";
    string constant OUT_OF_MAX_NAME_COUNT = "004064";
    string constant OUT_OF_MAX_PAGE_SIZE = "004065";

    /************************************variable********************************/
    string private baseURI;
    address private airdropAddress;
    uint256 private maxSupply;
    uint256 private maxMintPerTime;
    uint256 private blackPrice;
    uint256 private whitePrice;
    uint256 private maxDiyCount;
    uint256 private maxNameCount;
    uint256 private maxPageSize;
    MintStat private stat;

    CryptoMonkeyKing private cmkContract;
    uint256 private maxCmkMint;
    uint256 private maxCmkVipMint;
    address[] private cmkVipAddresses;
    mapping(address => uint256) private cmkAddressToMinted;
    mapping(uint256 => NFTMeta) private idToNFTMeta;

    uint256 mintedCmkId = 1000;
    uint256 mintedFreeId = 3000;
    uint256 whileNFTMinted = 0;

    /************************************validator********************************/
    modifier validArea(uint256 _area) {
        require(_area == 0 || _area == 1, AREA_IS_NOT_VALID);
        _;
    }

    modifier validId(uint256 _id) {
        require(_id > 0 && _id <= maxSupply, ID_IS_NOT_VALID);
        _;
    }

    modifier validAddr(address _addr) {
        require(_addr != address(0), ADDRESS_IS_NOT_VALID);
        _;
    }

    modifier onlyAirdrop() {
        require(msg.sender == airdropAddress, ADDRESS_IS_NOT_AIRDROP);
        _;
    }

    /************************************helps********************************/
    uint256 randNonce = 0;

    function _randNumber() private returns (uint256) {
        randNonce++;
        return
            uint256(
                keccak256(
                    abi.encodePacked(block.timestamp, msg.sender, randNonce)
                )
            );
    }

    function _isCmkAddress(address _addr) private view returns (bool) {
        return cmkContract.balanceOf(_addr) > 0;
    }

    function _isVipAddress(address _addr) private view returns (bool) {
        for (uint256 i = 0; i < cmkVipAddresses.length; i++) {
            if (_addr == cmkVipAddresses[i]) return true;
        }
        return false;
    }

    function _isReserveId(uint256 _id) private pure returns (bool) {
        return _id > 0 && _id <= 1000;
    }

    function _isCmkId(uint256 _id) private pure returns (bool) {
        return _id > 1000 && _id <= 3000;
    }

    function _isFreeId(uint256 _id) private view returns (bool) {
        return _id > 3000 && _id <= maxSupply;
    }

    function _isWhiteId(uint256 _id) private view returns (bool) {
        return idToNFTMeta[_id].nftType == NFTType.White;
    }

    function __mint(uint256 _id) private validId(_id) {
        require(!_exists(_id), NFT_HAS_OWNER);
        require(!_isReserveId(_id), ID_IS_RESERVE);

        if (_isCmkId(_id)) {
            require(_isCmkAddress(msg.sender), ADDRESS_IS_NOT_CMK);

            if (_isVipAddress(msg.sender)) {
                uint256 cmkVipMinted = cmkAddressToMinted[msg.sender];
                require(cmkVipMinted < maxCmkVipMint, OUT_OF_MAX_CMK_VIP_MINT);

                cmkAddressToMinted[msg.sender] = cmkVipMinted + 1;
            } else {
                uint256 cmkMinted = cmkAddressToMinted[msg.sender];
                require(cmkMinted < maxCmkMint, OUT_OF_MAX_CMK_MINT);

                cmkAddressToMinted[msg.sender] = cmkMinted + 1;
            }
        }

        _mint(msg.sender, _id);
        stat.minted++;
    }

    function _randomNFTType(string memory rndString, uint8 i)
        private
        view
        returns (NFTType)
    {
        uint256 remain = maxSupply - mintedFreeId;
        require(remain > 0, NFT_IS_NOT_ENOUGH);

        if (whileNFTMinted >= 3000) {
            return NFTType.Black;
        }

        uint256 balckNFTMintedInFreeArea = (mintedFreeId - 3000) -
            whileNFTMinted;
        if (balckNFTMintedInFreeArea >= 4000) {
            return NFTType.White;
        }

        bytes1 char = bytes(rndString)[i];
        uint8 code = uint8(char);
        return code % 7 < 4 ? NFTType.Black : NFTType.White;
    }

    /************************************business********************************/
    /***contructor***/
    constructor(
        string memory _baseUri,
        address _airdropAddress,
        address _cmkContractAddress
    ) ERC721("Punk Monkey", "PM") {
        setBaseURI(_baseUri);
        setAirdropAddress(_airdropAddress);
        setCmkContractAddress(_cmkContractAddress);
        setMaxCmkMint(1);
        setMaxCmkVipMint(500);
        setBlackPrice(0.02 ether);
        setWhitePrice(0.02 ether);
        setMaxSupply(10000);
        setMaxMintPerTime(20);
        setMaxDiyCount(1);
        setMaxNameCount(1);
        setMaxPageSize(1000);
    }

    /***ERC721Metadata***/
    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    /***onlyOwner***/
    function setBaseURI(string memory _uri) public onlyOwner {
        baseURI = _uri;
    }

    function setCmkContractAddress(address _cmkContractAddress)
        public
        onlyOwner
    {
        require(_cmkContractAddress.isContract(), ADDRESS_IS_NOT_CONTRACT);
        cmkContract = CryptoMonkeyKing(_cmkContractAddress);
    }

    function setAirdropAddress(address _airdropAddress) public onlyOwner {
        airdropAddress = _airdropAddress;
    }

    function setCmkVipAddresses(address[] calldata _vipAddresses)
        public
        onlyOwner
    {
        cmkVipAddresses = _vipAddresses;
    }

    function setMaxCmkVipMint(uint256 _maxCmkVipMint) public onlyOwner {
        maxCmkVipMint = _maxCmkVipMint;
    }

    function setMaxCmkMint(uint256 _maxCmkMint) public onlyOwner {
        maxCmkMint = _maxCmkMint;
    }

    function setMaxSupply(uint256 _maxSupply) public onlyOwner {
        maxSupply = _maxSupply;
    }

    function setMaxMintPerTime(uint256 _maxMintPerTime) public onlyOwner {
        maxMintPerTime = _maxMintPerTime;
    }

    function setBlackPrice(uint256 _blackPrice) public onlyOwner {
        blackPrice = _blackPrice;
    }

    function setWhitePrice(uint256 _whitePrice) public onlyOwner {
        whitePrice = _whitePrice;
    }

    function setMaxDiyCount(uint256 _maxDiyCount) public onlyOwner {
        maxDiyCount = _maxDiyCount;
    }

    function setMaxNameCount(uint256 _maxNameCount) public onlyOwner {
        maxNameCount = _maxNameCount;
    }

    function setMaxPageSize(uint256 _maxPageSize) public onlyOwner {
        maxPageSize = _maxPageSize;
    }

    function getCmkVipAddresses()
        public
        view
        onlyOwner
        returns (address[] memory)
    {
        return cmkVipAddresses;
    }

    function getMaxCmkVipMint() public view onlyOwner returns (uint256) {
        return maxCmkVipMint;
    }

    function getMaxCmkMint() public view onlyOwner returns (uint256) {
        return maxCmkMint;
    }

    /***business***/
    function isCmkAddress(address _addr)
        public
        view
        validAddr(_addr)
        returns (bool)
    {
        return _isCmkAddress(_addr);
    }

    function getOwnerOf(uint256 _id)
        public
        view
        validId(_id)
        returns (address _owner)
    {
        _owner = _exists(_id) ? ownerOf(_id) : address(0);
    }

    function getOwnersOf(uint256[] memory _ids)
        public
        view
        returns (address[] memory)
    {
        address[] memory owners = new address[](_ids.length);
        for (uint256 i = 0; i < _ids.length; i++) {
            owners[i] = getOwnerOf(_ids[i]);
        }
        return owners;
    }

    function getBaseURI() public view returns (string memory) {
        return baseURI;
    }

    function getCmkContractAddress() public view returns (address) {
        return address(cmkContract);
    }

    function getAirdropAddress() public view returns (address) {
        return airdropAddress;
    }

    function getMaxSupply() public view returns (uint256) {
        return maxSupply;
    }

    function getMaxMintPerTime() public view returns (uint256) {
        return maxMintPerTime;
    }

    function getMaxPageSize() public view returns (uint256) {
        return maxPageSize;
    }

    function getMintStat() public view returns (MintStat memory) {
        return stat;
    }

    function getBlackPrice() public view returns (uint256) {
        return blackPrice;
    }

    function getWhitePrice() public view returns (uint256) {
        return whitePrice;
    }

    function getMintedCmkId() public view returns (uint256) {
        return mintedCmkId;
    }

    function getMintedFreeId() public view returns (uint256) {
        return mintedFreeId;
    }

    function getMaxDiyCount() public view returns (uint256) {
        return maxDiyCount;
    }

    function getMaxNameCount() public view returns (uint256) {
        return maxNameCount;
    }

    function validDiy(address _addr, uint256 _id)
        public
        view
        validId(_id)
        validAddr(_addr)
        returns (uint256)
    {
        if (!_exists(_id)) return 1;
        if (!_isWhiteId(_id)) return 2;
        if (getOwnerOf(_id) != _addr) return 3;

        uint256 count = idToNFTMeta[_id].diyCount;
        if (count >= maxDiyCount) return 4;

        return 0;
    }

    function validName(address _addr, uint256 _id)
        public
        view
        validId(_id)
        validAddr(_addr)
        returns (uint256)
    {
        if (!_exists(_id)) return 1;
        if (getOwnerOf(_id) != _addr) return 2;

        uint256 count = idToNFTMeta[_id].nameCount;
        if (count >= maxNameCount) return 3;

        return 0;
    }

    function getNFT(uint256 _id) public view validId(_id) returns (NFT memory) {
        address owner = getOwnerOf(_id);

        uint256 state = 0;
        if (owner != address(0)) {
            state = 1;
        } else if (_isReserveId(_id)) {
            state = 0;
        } else {
            state = 2;
        }

        NFTMeta storage meta = idToNFTMeta[_id];
        return NFT(_id, owner, state, meta.nftType, meta.name, meta.imageHash);
    }

    function getNFTs(uint256[] calldata _ids)
        public
        view
        returns (NFT[] memory)
    {
        require(
            _ids.length >= 0 && _ids.length <= maxPageSize,
            OUT_OF_MAX_PAGE_SIZE
        );

        NFT[] memory NFTs = new NFT[](_ids.length);
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            address owner = getOwnerOf(id);

            uint256 state = 0;
            if (owner != address(0)) {
                state = 1;
            } else if (_isReserveId(id)) {
                state = 0;
            } else {
                state = 2;
            }

            NFTMeta storage meta = idToNFTMeta[id];
            NFTs[i] = NFT(
                id,
                owner,
                state,
                meta.nftType,
                meta.name,
                meta.imageHash
            );
        }
        return NFTs;
    }

    function getNFTsOfOwner(address _addr)
        public
        view
        validAddr(_addr)
        returns (NFT[] memory)
    {
        uint256 length = this.balanceOf(_addr);
        NFT[] memory NFTs = new NFT[](length);
        for (uint256 i = 0; i < length; i++) {
            uint256 id = this.tokenOfOwnerByIndex(_addr, i);

            uint256 state = 0;
            if (_addr != address(0)) {
                state = 1;
            } else if (_isReserveId(id)) {
                state = 0;
            } else {
                state = 2;
            }
            NFTMeta storage meta = idToNFTMeta[id];
            NFTs[i] = NFT(
                id,
                _addr,
                state,
                meta.nftType,
                meta.name,
                meta.imageHash
            );
        }
        return NFTs;
    }

    function airdrop(address _to, uint256 _id) public onlyAirdrop validId(_id) {
        require(_isReserveId(_id), ID_IS_NOT_RESERVE);
        require(!_exists(_id), NFT_HAS_OWNER);

        _mint(_to, _id);
        stat.minted++;

        idToNFTMeta[_id] = NFTMeta(NFTType.Black, "", "", 0, 0);
    }

    function airdropNFTs(address _to, uint256[] calldata _ids)
        public
        onlyAirdrop
    {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            airdrop(_to, id);
        }
    }

    function give(address _to, uint256 _id) public validId(_id) validAddr(_to) {
        require(getOwnerOf(_id) == msg.sender, NFT_IS_NOT_MAPPINT_OWNER);
        _transfer(msg.sender, _to, _id);
    }

    function giveNFTs(address _to, uint256[] calldata _ids) public {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            give(_to, id);
        }
    }

    function mint(uint256 _area, uint256 _count)
        public
        payable
        validArea(_area)
    {
        require(_count <= maxMintPerTime, OUT_OF_MAX_FREE_MINT);

        if (_area == 0) {
            require(mintedCmkId + _count <= 3000, NFT_IS_NOT_ENOUGH);

            for (uint256 i = 0; i < _count; i++) {
                mintedCmkId++;
                __mint(mintedCmkId);

                idToNFTMeta[mintedCmkId] = NFTMeta(NFTType.Black, "", "", 0, 0);
            }
        }

        if (_area == 1) {
            require(mintedFreeId + _count <= maxSupply, NFT_IS_NOT_ENOUGH);

            uint256 total = 0;
            string memory rndString = _randNumber().toString();
            NFTMeta[] memory metas = new NFTMeta[](_count);
            for (uint8 i = 0; i < _count; i++) {
                NFTType nftType = _randomNFTType(rndString, i);
                if (nftType == NFTType.White) {
                    whileNFTMinted++;
                }

                metas[i] = NFTMeta(nftType, "", "", 0, 0);
                total += nftType == NFTType.Black ? blackPrice : whitePrice;
            }
            require(msg.value >= total, BALANCE_NOT_ENOUGH);

            for (uint8 i = 0; i < _count; i++) {
                mintedFreeId++;
                __mint(mintedFreeId);

                idToNFTMeta[mintedFreeId] = metas[i];
            }

            payable(owner()).transfer(total);

            if (msg.value > total) {
                payable(msg.sender).transfer(msg.value - total);
            }
        }
    }

    function diy(uint256 _id, string calldata _hash) public validId(_id) {
        require(_exists(_id), NFT_HAS_NO_OWNER);
        require(_isWhiteId(_id), ID_IS_NOT_WHITE);
        require(getOwnerOf(_id) == msg.sender, NFT_IS_NOT_MAPPINT_OWNER);

        uint256 count = idToNFTMeta[_id].diyCount;
        require(count < maxDiyCount, OUT_OF_MAX_DIY_COUNT);

        idToNFTMeta[_id].diyCount++;

        NFTMeta storage meta = idToNFTMeta[_id];
        meta.imageHash = _hash;
    }

    function name(uint256 _id, string calldata _name) public validId(_id) {
        require(_exists(_id), NFT_HAS_NO_OWNER);
        require(getOwnerOf(_id) == msg.sender, NFT_IS_NOT_MAPPINT_OWNER);

        uint256 count = idToNFTMeta[_id].nameCount;
        require(count < maxNameCount, OUT_OF_MAX_NAME_COUNT);

        idToNFTMeta[_id].nameCount++;

        NFTMeta storage meta = idToNFTMeta[_id];
        meta.name = _name;
    }
}