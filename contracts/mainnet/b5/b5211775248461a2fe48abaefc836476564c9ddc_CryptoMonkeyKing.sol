// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

import "./erc721-metadata.sol";
import "./nf-token-enumerable.sol";
import "./ownable.sol";
import "./address-utils.sol";
import "./cmk-utils.sol";
import "./datetime-library.sol";

contract CryptoMonkeyKing is
    NFTokenEnumerable,
    Ownable,
    CmkUtils,
    ERC721Metadata
{
    using AddressUtils for address;

    /************************************struct********************************/
    struct NFT {
        uint256 id;
        bool isSelling;
        uint256 priceInWei;
        address owner;
    }

    struct MintedInfo {
        uint256 lastYear;
        uint256 lastMonth;
        uint256 lastDay;
        uint256 lastCount;
        uint256 minted;
    }

    /************************************error********************************/
    string constant NOT_VALID_NFT_ID = "004001";
    string constant NOT_RESERVE = "004002";
    string constant NOT_NORMAL = "004003";
    string constant IN_SELLING = "004004";
    string constant NO_SELLING = "004005";
    string constant NFT_HAS_NO_OWNER = "004006";
    string constant NFT_HAS_OWNER = "004007";
    string constant IS_NFT_OWNER = "004008";
    string constant NOT_NFT_OWNER = "004009";
    string constant NOT_AIRDROP_ACCOUNT = "004010";
    string constant NOT_ENOUGH_BALANCE = "004011";
    string constant OUT_OF_MAX_PAGE_SIZE = "004012";
    string constant OUT_OF_MINT_MAX_PER_TIME = "004013";
    string constant OUT_OF_MINT_MAX_PER_DAY = "004014";
    string constant SENDER_MINTED = "004015";

    /************************************variable********************************/
    string private baseURI;
    address private airdropAccount;
    uint256 private maxSupply;
    uint256 private maxPageSize;
    uint256 private maxMintPerTime;
    uint256 private mintMaxPerDay;
    uint256 private mintPrice;
    MintedInfo mintedInfo;
    mapping(address => bool) private addressToMinted;

    /************************************validator********************************/
    modifier onlyAirdrop() {
        require(msg.sender == airdropAccount, NOT_AIRDROP_ACCOUNT);
        _;
    }

    modifier validNFTId(uint256 _id) {
        require(_id >= 0 && _id <= maxSupply - 1, NOT_VALID_NFT_ID);
        _;
    }

    /************************************helps********************************/
    function isReserve(uint256 _id) internal pure returns (bool) {
        return _id >= 7000 && _id < 10000;
    }

    function isNormal(uint256 _id) internal pure returns (bool) {
        return _id >= 0 && _id < 7000;
    }

    /************************************business********************************/
    /***contructor***/
    constructor() {
        baseURI = "https://cryptomonkeyking.com/token";
        airdropAccount = 0x251d42b900973eD14D7Ea82Ce9310D34534f75EC;
        maxSupply = 10000;
        maxPageSize = 1000;
        maxMintPerTime = 5;
        mintMaxPerDay = 200;
    }

    /***ERC721Metadata***/
    function name() external pure override returns (string memory _name) {
        return "Crypto Monkey King";
    }

    function symbol() external pure override returns (string memory _symbol) {
        return "CMK";
    }

    function tokenURI(uint256 _id)
        external
        view
        override
        returns (string memory)
    {
        return strConcat(baseURI, "/", uint2str(_id));
    }

    /***onlyOwner***/
    function setBaseURI(string memory _baseURI) public onlyOwner {
        baseURI = _baseURI;
    }

    function getBaseURI() public view onlyOwner returns (string memory) {
        return baseURI;
    }

    function setAirdropAccount(address _airdropAccount) public onlyOwner {
        airdropAccount = _airdropAccount;
    }

    function getAirdropAccount() public view onlyOwner returns (address) {
        return airdropAccount;
    }

    function setMintPrice(uint256 _mintPrice) public onlyOwner {
        mintPrice = _mintPrice;
    }

    function getMintPrice() public view returns (uint256) {
        return mintPrice;
    }

    function setMaxMintPerTime(uint256 _maxMintPerTime) public onlyOwner {
        maxMintPerTime = _maxMintPerTime;
    }

    function getMaxMintPerTime() public view returns (uint256) {
        return maxMintPerTime;
    }

    function setMintMaxPerDay(uint256 _mintMaxPerDay) public onlyOwner {
        mintMaxPerDay = _mintMaxPerDay;
    }

    function getMintMaxPerDay() public view returns (uint256) {
        return mintMaxPerDay;
    }

    /***business***/
    function getMaxSupply() public view returns (uint256) {
        return maxSupply;
    }

    function getMaxPageSize() public view returns (uint256) {
        return maxPageSize;
    }

    function getMintableRemaining() public view returns (uint256) {
        return 7000 - mintedInfo.minted;
    }

    function getPagedNFTs(uint256 pageSize, uint256 pageIndex)
        public
        view
        returns (NFT[] memory)
    {
        require(pageSize <= maxPageSize, OUT_OF_MAX_PAGE_SIZE);

        uint256 start = pageSize * pageIndex;
        uint256 end = start + pageSize - 1;

        if (start > maxSupply - 1) {
            start = maxSupply - 1;
        }

        if (end > maxSupply - 1) {
            end = maxSupply - 1;
        }

        NFT[] memory NFTs = new NFT[](pageSize);
        for (uint256 i = start; i <= end; i++) {
            address owner = idToOwner[i];
            NFT memory nft = NFT(i, false, 0, owner);
            NFTs[i - start] = nft;
        }
        return NFTs;
    }

    function getMintedCountToday() public view returns(uint256){
        (uint256 year, uint256 month, uint256 day) = BokkyPooBahsDateTimeLibrary
            .timestampToDate(block.timestamp);
        uint count=0;
        if (
            mintedInfo.lastYear == year &&
            mintedInfo.lastMonth == month &&
            mintedInfo.lastDay == day
        ) {
            count = mintedInfo.lastCount;
        } else {
            count = 0;
        }
        return count;
    }

    function getMintableCountToday() public view returns (uint256) {
        (uint256 year, uint256 month, uint256 day) = BokkyPooBahsDateTimeLibrary
            .timestampToDate(block.timestamp);

        uint256 count = 0;
        uint256 remainToday = CmkUtils.getMin(7000 - mintedInfo.minted, mintMaxPerDay);
        if (
            mintedInfo.lastYear == year &&
            mintedInfo.lastMonth == month &&
            mintedInfo.lastDay == day
        ) {
            count = remainToday - mintedInfo.lastCount;
        } else {
            count = remainToday;
        }

        if (count < 0) {
            count = 0;
        }

        return count;
    }

    function isMinted(address _addr) public view returns (bool) {
        return addressToMinted[_addr];
    }

    function mintNFTs(uint256[] memory _ids) public payable {
        // 需要未领过
        require(!addressToMinted[msg.sender], SENDER_MINTED);
        // 不要超过当日可领上限
        require(
            _ids.length <= getMintableCountToday(),
            OUT_OF_MINT_MAX_PER_DAY
        );
        // 不要超过每次可领上限
        require(_ids.length <= maxMintPerTime, OUT_OF_MINT_MAX_PER_TIME);

        uint256 total = _ids.length * mintPrice;
        require(total <= msg.value, NOT_ENOUGH_BALANCE);

        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 _id = _ids[i];
            require(isNormal(_id), NOT_NORMAL);
            require(idToOwner[_id] == address(0), NFT_HAS_OWNER);

            _mint(msg.sender, _id);
        }

        // 更新当日领取数
        (uint256 year, uint256 month, uint256 day) = BokkyPooBahsDateTimeLibrary
            .timestampToDate(block.timestamp);

        if (
            mintedInfo.lastYear == year &&
            mintedInfo.lastMonth == month &&
            mintedInfo.lastDay == day
        ) {
            mintedInfo.lastCount += _ids.length;
        } else {
            mintedInfo.lastCount = _ids.length;
        }

        // 更新最近领取时间
        mintedInfo.lastYear = year;
        mintedInfo.lastMonth = month;
        mintedInfo.lastDay = day;

        // 更新累计已领
        mintedInfo.minted += _ids.length;

        // 标记已领取
        addressToMinted[msg.sender] = true;

        // 收款
        if (mintPrice > 0) {
            payable(owner).transfer(msg.value);
        }
    }

    function airdropNFT(address _to, uint256 _id)
        public
        onlyAirdrop
        validNFTId(_id)
    {
        require(isReserve(_id), NOT_RESERVE);
        require(idToOwner[_id] == address(0), NFT_HAS_OWNER);

        _mint(_to, _id);
    }

    function airdropNFTs(address _to, uint256[] memory _ids) public {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            airdropNFT(_to, id);
        }
    }

    function giveNFT(address _to, uint256 _id) public validNFTId(_id) {
        require(this.ownerOf(_id) == msg.sender, NOT_NFT_OWNER);

        _transfer(_to, _id);
    }

    function giveNFTs(address _to, uint256[] memory _ids) public {
        for (uint256 i = 0; i < _ids.length; i++) {
            uint256 id = _ids[i];
            giveNFT(_to, id);
        }
    }
}