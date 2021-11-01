// SPDX-License-Identifier: MIT
/**
Copyright 2021 <vlad, twitter.com/VladFinance, t.me/VladFinanceOfficial>
Copyright 2021 <bitdeep, twitter.com/bitdeep_oficial, t.me/bitdeep>

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
OR OTHER DEALINGS IN THE SOFTWARE.

// 2020 - PancakeSwap Team - https://pancakeswap.com
// 2021 - bitdeep, twitter.com/bitdeep_oficial, t.me/bitdeep
// 2021, Vlad Team, t.me/VladFinanceOfficial, https://vlad.finance/

**/

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./INFT.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./AddrArrayLib.sol";
import "./Uint256ArrayLib.sol";
import "./Uint8ArrayLib.sol";
import "./StringArrayLib.sol";

pragma experimental ABIEncoderV2;
pragma solidity ^0.6.12;

contract NftFarmV2 is Ownable, ReentrancyGuard {
    using SafeMath for uint8;
    using SafeMath for uint256;
    using SafeBEP20 for IBEP20;
    using AddrArrayLib for AddrArrayLib.Addresses;
    using Uint256ArrayLib for Uint256ArrayLib.Values;
    using Uint8ArrayLib for Uint8ArrayLib.Values;
    using StringArrayLib for StringArrayLib.Values;

    INFT public nft;    // default platform nft
    IBEP20 public token;// default platform payment token

    // global stats
    uint256 totalMint; // total of all mints
    uint256 totalBurn; // total of all burns
    uint256 totalTokensCollected; //amount of tokens received
    uint256 totalTokensRefunded; //amount of tokens refunded to users on burn
    uint256 totalPaidToAuthors; //amount of tokens sent to nft authors

    uint8[] public minted; // array of nft minted, unique, added on first mint only.
    mapping(uint8 => AddrArrayLib.Addresses) private ownersOf; // wallets by nftId

    // can manage price and limits
    mapping(address => bool) public mintingManager;

    // fee & payment management
    struct PlatformFees {
        uint256 authorFee; // 30%
        uint256 govFee; // 15%
        uint256 devFee;  //  5%

        uint256 marketAuthorFee; // 30%
        uint256 marketGovFee; // 15%
        uint256 marketDevFee;  //  5%
    }

    PlatformFees platformFees;

    // artist management
    struct PlatformAddresses {
        address govFeeAddr;
        address devFeeAddr;
    }

    PlatformAddresses platformAddresses;

    struct NftInfo {
        uint8 nftId;
        address author; // nft artist/owner, who get paid
        uint256 authorFee; // fee to pay to author of this nft
        bool allowMng; // allow owner to manage this nft
        uint256 authorId; // unique id for this author
        string authorName; // author name (string)
        string authorTwitter; // author twitter account ie (@test)
        string rarity;
        string uri;
        uint256 startBlock; // only allow mint after this block
        uint256 endBlock;   // only allow mint before this block
        uint256 status;     // use to: 0=inactive, 1=active, 2=auction
    }

    struct NftInfoState {
        uint8 nftId;
        uint256 price;      // default price
        uint256 maxMint;    // max amount of nft to be minted
        uint256 multiplier; // factor, to enable price curve
        uint256 rarityId;   // unique id for this rarity
        uint256 minted;     // amount minted
        uint256 lastMint;   // timestamp of last minted
        uint256 burned;     // amount burned
        uint256 lastBurn;   // timestamp of last burn
        address lastOwner;  // last one that minted this nft
        INFT nft;          // mint/burn this nft
        IBEP20 token;      // buy/sell using this token (AfterLife, WBNB, BUSD)
    }

    // global index of each trade
    uint256 tradeIdPool;

    // array of all nft added
    uint256[] public nftIndex;
    // basic nft info to display
    mapping(uint8 => NftInfo) public nftInfo;
    // state info, like minting, minted, burned
    mapping(uint8 => NftInfoState) public nftInfoState;
    // list of all nft minting by nft id
    mapping(uint8 => uint256[]) private listOfTradesByNftId;

    // primary trade info
    struct NftTradeInfo {
        uint8 nftId; // store the market place id (comes from admin)
        uint256 tokenId; // store token id (comes from token)
        uint256 tradeId; // store trade id (sequence generated here)
        address owner;
        uint256 price;
        uint256 artistFee;
        uint256 governanceFee;
        uint256 devFee;
        uint256 reserve;
        uint256 mintedIn;
        uint256 burnedIn;
    }

    mapping(uint256 => NftTradeInfo) private nftTrade; // store all trades by tradeId
    mapping(uint8 => mapping(address => Uint256ArrayLib.Values) ) private nftTradeByUser; // store all trades by user
    mapping(uint8 => mapping(address => Uint256ArrayLib.Values) ) private nftBurnsByUser; // store all trades by user
    mapping(address => Uint8ArrayLib.Values ) private nftIdByUser; // store all nftId by user

    struct NftSecondaryMarket {
        uint8 nftId;
        bool allowSell;   // allow owner to sell this nft
        uint256 sellMinPrice; // min price allowed to sell

        // global secondary market stats
        uint256 totalArtistFee; // total fee paid to this artist
        uint256 totalGovernanceFee; // total fee collected to governance
        uint256 totalDevFee; // total fee collected to dev fund
        uint256 qtdSells; // qtd of sells made
        uint256 totalCollected; // amount of token collected
        uint256 lastSellPrice; // last seel price
        uint256 lastSellIn; // last sell date
    }

    mapping(uint8 => NftSecondaryMarket) public nftSecondaryMarket;
    mapping(uint8 => Uint256ArrayLib.Values) private listOfOpenSells; // list of open sells

    // secondary trade info
    struct NftSecondaryTradeInfo {
        uint256 sellPrice; // price user want to sell
        uint256 sellDate; // when order added
        uint256 soldDate; // price sold
    }
    mapping(uint256 => NftSecondaryTradeInfo) public nftSecondaryTradeInfo;


    // filters
    mapping(string => uint8[]) private listOfNftByRarity;
    mapping(string => uint8[]) private listOfNftByAuthor;

    mapping(string => uint256) private authorIdByName;
    mapping(string => uint256) private rarityIdByName;
    StringArrayLib.Values private listOfAuthors;
    StringArrayLib.Values private listOfRarity;

    // events
    event NftAdded(uint8 indexed nftId, address indexed author, uint256 startBlock, uint256 endBlock);
    event NftChanged(uint8 indexed nftId, address indexed author, uint256 startBlock, uint256 endBlock);
    event NftStateAdded(uint8 indexed nftId, uint256 price, uint256 multiplier);

    event NftMint(address indexed to, uint256 indexed tokenId, uint8 indexed nftId, uint256 amount, uint256 price);
    event NftBurn(address indexed from, uint256 indexed tokenId);
    event NftTransfer(address indexed from, address indexed to, uint256 indexed tradeId);

    constructor(address _nft, address _token) public {
        require( address(nft) == address(0), "!init");
        nft = INFT(_nft);
        token = IBEP20(_token);
        mintingManager[msg.sender] = true;

        // all fee wallets defaults to deployer, must be changed later.
        platformAddresses.govFeeAddr = msg.sender;
        platformAddresses.devFeeAddr = msg.sender;

        platformFees.authorFee = 3000; // 30%
        platformFees.govFee = 1500; // 15%
        platformFees.devFee = 500; //  5%

        platformFees.marketAuthorFee = 3000; // 30%
        platformFees.marketGovFee = 1500; // 15%
        platformFees.marketDevFee = 500; //  5%

    }

    function getOwnersOf(uint8 _nftId) public view returns (address[] memory){
        return ownersOf[_nftId].getAllAddresses();
    }
    function getTotalOfOwners(uint8 _nftId) public view returns (uint256){
        return ownersOf[_nftId].getAllAddresses().length;
    }

    function getMinted(address _user) external view returns
    (uint8[] memory, uint256[] memory, uint256[] memory){
        uint256 total = minted.length;
        uint256[] memory mintedAmounts = new uint256[](total);
        uint256[] memory myMints = new uint256[](total);

        for (uint256 index = 0; index < total; ++index) {
            uint8 nftId = minted[index];
            NftInfoState storage NftState = nftInfoState[nftId];
            mintedAmounts[index] = NftState.minted;
            myMints[index] = getMintsOf(_user, nftId);
        }
        return (minted, mintedAmounts, myMints);
    }

    // get total mints of a nft filtered by user
    function getMintsOf(address user, uint8 _nftId) public view returns (uint256) {
        address[] memory _ownersOf = getOwnersOf(_nftId);
        uint256 total = _ownersOf.length;
        uint256 mints = 0;
        for (uint256 index = 0; index < total; ++index) {
            if (_ownersOf[index] == user) {
                mints = mints.add(1);
            }
        }
        return mints;
    }

    function getPrice(uint8 _nftId, uint256 _minted) public view returns (uint256){
        NftInfoState storage NFT = nftInfoState[_nftId];
        uint256 price = NFT.price;
        if (_minted == 0) {
            return price;
        }
        if (NFT.multiplier > 0) {
            // price curve by m-dot :)
            for (uint256 i = 0; i < _minted; ++i) {
                price = price.mul(NFT.multiplier).div(1000000);
            }
        }
        return price;
    }


    function mint(uint8 _nftId) external nonReentrant {

        NftInfo storage NFT = nftInfo[_nftId];
        NftInfoState storage NftState = nftInfoState[_nftId];

        require(NftState.nftId > 0, "NFT not available");
        require(NFT.status > 0, "nft disabled");
        require(NFT.startBlock == 0 || block.number > NFT.startBlock, "Too early");
        require(NFT.endBlock == 0 || block.number < NFT.endBlock, "Too late");

        if (NftState.minted == 0) {
            minted.push(_nftId);
            NftState.nft.setNftName(_nftId, NFT.rarity);
        }

        NftState.lastOwner = msg.sender;
        NftState.lastMint = block.timestamp;
        NftState.price = getPrice(_nftId, 1);
        NftState.minted = NftState.minted.add(1);

        require(NftState.maxMint == 0 || NftState.minted <= NftState.maxMint, "Max minting reached");

        ownersOf[_nftId].pushAddress(msg.sender, true);

        // we increment before, then we can check if index is != 0
        tradeIdPool = tradeIdPool.add(1); // we finished here, increment trade index by i

        uint256[] storage tradesByNftId = listOfTradesByNftId[_nftId];
        tradesByNftId.push(tradeIdPool);

        NftTradeInfo storage TRADE = nftTrade[tradeIdPool]; // tradeId eg 0
        TRADE.tradeId = tradeIdPool;
        TRADE.nftId = _nftId;
        TRADE.owner = msg.sender;
        TRADE.tokenId = NftState.nft.mint(address(msg.sender), NFT.uri, _nftId);

        TRADE.mintedIn = block.timestamp;
        TRADE.price = NftState.price;
        if (NFT.authorFee == 0) {
            TRADE.artistFee = TRADE.price.mul(platformFees.authorFee).div(10000);
        } else {
            TRADE.artistFee = TRADE.price.mul(NFT.authorFee).div(10000);
        }
        TRADE.governanceFee = TRADE.price.mul(platformFees.govFee).div(10000);
        TRADE.devFee = TRADE.price.mul(platformFees.devFee).div(10000);
        TRADE.reserve = TRADE.price.sub(TRADE.artistFee).sub(TRADE.governanceFee).sub(TRADE.devFee);

        NftState.token.safeTransferFrom(address(msg.sender), NFT.author, TRADE.artistFee);
        NftState.token.safeTransferFrom(address(msg.sender), platformAddresses.govFeeAddr, TRADE.governanceFee);
        NftState.token.safeTransferFrom(address(msg.sender), platformAddresses.devFeeAddr, TRADE.devFee);
        NftState.token.safeTransferFrom(address(msg.sender), address(this), TRADE.reserve);

        totalMint = totalMint.add(1);
        totalTokensCollected = totalTokensCollected.add(NftState.price);
        totalPaidToAuthors = totalPaidToAuthors.add(TRADE.artistFee);


        // add this id of user minted nfts (only once)
        nftIdByUser[msg.sender].pushValue(_nftId);

        // store trades for this user
        nftTradeByUser[_nftId][msg.sender].pushValue(TRADE.tradeId);

        emit NftMint(msg.sender, TRADE.tokenId, _nftId, NftState.minted, NftState.price);


    }



    function burnByNftId(uint8 _nftId) external nonReentrant {
        uint256 tradeId = getTradeIdByNftId(msg.sender, _nftId);
        _burn(tradeId);
    }
    function burn(uint256 tradeId) public nonReentrant {
        _burn(tradeId);
    }
    function _burn(uint256 tradeId) internal {

        NftTradeInfo storage TRADE = nftTrade[tradeId];
        NftInfoState storage NftState = nftInfoState[TRADE.nftId];
        NftInfo storage NFT = nftInfo[TRADE.nftId];

        require(TRADE.owner == msg.sender, "not nft owner");
        require(TRADE.burnedIn == 0, "already burned"); // avoid double burn exploit
        require(NftState.minted > 0, "no burn available");
        require(NFT.status > 0, "disabled");

        require(NftState.nft.ownerOf(TRADE.tokenId) == address(msg.sender), "not owner");
        NftState.nft.burn(TRADE.tokenId);
        nftTradeByUser[TRADE.nftId][msg.sender].removeValue(tradeId);
        nftBurnsByUser[TRADE.nftId][msg.sender].pushValue(tradeId);
        TRADE.burnedIn = block.timestamp;
        if( nftTradeByUser[TRADE.nftId][msg.sender].size() == 0 ){
            ownersOf[TRADE.nftId].removeAddress(msg.sender);
            nftIdByUser[msg.sender].removeValue(TRADE.nftId);
        }
        NftState.burned = NftState.burned.add(1);
        NftState.lastBurn = block.timestamp;
        NftState.minted = NftState.minted.sub(1);

        if( TRADE.reserve > 0 ){
            NftState.token.safeTransfer(address(msg.sender), TRADE.reserve);
            totalTokensRefunded = totalTokensRefunded.add(TRADE.reserve);
        }
        totalBurn = totalBurn.add(1);

        listOfOpenSells[TRADE.nftId].removeValue(tradeId); // added only once

        emit NftBurn(msg.sender, tradeId);
    }

    function itod(uint256 x) private pure returns (string memory) {
        if (x > 0) {
            string memory str;
            while (x > 0) {
                str = string(abi.encodePacked(uint8(x % 10 + 48), str));
                x /= 10;
            }
            return str;
        }
        return "0";
    }


    // manage the minting interval to avoid front-run exploiters
    
    // function add(uint8 _nftId, address _author,
    //     uint256 _startBlock, uint256 _endBlock, bool _allowMng,
    //     string memory _rarity, string memory _uri, uint256 _authorFee,
    //     string memory _authorName, string memory _authorTwitter, uint256 _status)
    // external
    // mintingManagers
    // {

    //     NftInfo storage NFT = nftInfo[_nftId];
    //     NftInfoState storage NftState = nftInfoState[_nftId];

    //     require(_nftId != 0, "invalid nftId");
    //     require(NFT.nftId == 0, "already exists");

    //     nftIndex.push(_nftId);

    //     NFT.nftId = _nftId;
    //     NFT.author = _author;
    //     NFT.authorFee = _authorFee;
    //     NFT.allowMng = _allowMng;
    //     NFT.authorName = _authorName;
    //     NFT.authorTwitter = _authorTwitter;
    //     NFT.rarity = _rarity;
    //     NFT.uri = string(abi.encodePacked(_uri, "/", itod(_nftId), ".json"));
    //     NFT.startBlock = _startBlock;
    //     NFT.endBlock = _endBlock;
    //     NFT.status = _status;

    //     NftState.nftId = _nftId;
    //     NftState.nft = nft; // default platform nft
    //     NftState.token = token; // default platform payment token

    //     // avoid fee mint/burn exploit
    //     require(platformFees.authorFee.add(platformFees.govFee).add(platformFees.devFee).add(_authorFee) < 10000, "TOO HIGH");

    //     uint8[] storage nftByRarity = listOfNftByRarity[_rarity];
    //     uint8[] storage nftByAuthors = listOfNftByAuthor[_authorName];

    //     if ( listOfRarity.pushValue(_rarity) ) {
    //         // generate rarityID by array index.
    //         rarityIdByName[_rarity] = listOfRarity.size();
    //     }

    //     if ( listOfAuthors.pushValue(_authorName) ) {
    //         // generate authorID by array index.
    //         authorIdByName[_authorName] = listOfAuthors.size();
    //     }

    //     NFT.authorId = authorIdByName[_authorName];
    //     NftState.rarityId = rarityIdByName[_rarity];

    //     nftByRarity.push(_nftId);
    //     nftByAuthors.push(_nftId);

    //     emit NftAdded(_nftId, _author, _startBlock, _endBlock);
    // }


    function add(uint8 _nftId, address _author,
        uint256 _startBlock, uint256 _endBlock, bool _allowMng,
        string memory _rarity, string memory _uri, uint256 _authorFee,
        string memory _authorName, string memory _authorTwitter, 
        uint256 _status,
        address _token
        )
    external
    mintingManagers
    {

        NftInfo storage NFT = nftInfo[_nftId];

        require(_nftId != 0, "invalid nftId");
        require(NFT.nftId == 0, "already exists");

        nftIndex.push(_nftId);

        NFT.nftId = _nftId;
        NFT.author = _author;
        NFT.authorFee = _authorFee;
        NFT.allowMng = _allowMng;
        NFT.authorName = _authorName;
        NFT.authorTwitter = _authorTwitter;
        NFT.rarity = _rarity;
        NFT.uri = string(abi.encodePacked(_uri, "/", itod(_nftId), ".json"));
        NFT.startBlock = _startBlock;
        NFT.endBlock = _endBlock;
        NFT.status = _status;


        // avoid fee mint/burn exploit
        
{        require(platformFees.authorFee.add(platformFees.govFee).add(platformFees.devFee).add(_authorFee) < 10000, "TOO HIGH");
}
        
           uint8[] storage nftByAuthors = listOfNftByAuthor[_authorName];

        if ( listOfAuthors.pushValue(_authorName) ) {
            // generate authorID by array index.
            authorIdByName[_authorName] = listOfAuthors.size();}
        

        NFT.authorId = authorIdByName[_authorName];
      
        nftByAuthors.push(_nftId);
        addnftstate(_nftId,_rarity,_token);
    


        emit NftAdded(_nftId, _author, _startBlock, _endBlock);
    }
    
    
    function addnftstate( uint8 _nftId, string memory _rarity,address _token)internal {
        NftInfoState storage NftState = nftInfoState[_nftId];
        
        NftState.nftId = _nftId;
        NftState.nft = nft; // default platform nft
        NftState.token = IBEP20(_token);//specific token for given nftid

        uint8[] storage nftByRarity = listOfNftByRarity[_rarity];

        if ( listOfRarity.pushValue(_rarity) ) {
            // generate rarityID by array index.
            rarityIdByName[_rarity] = listOfRarity.size();
        }
        
        NftState.rarityId = rarityIdByName[_rarity];
        nftByRarity.push(_nftId);

        
        
    }

    function set(uint8 _nftId, address _author,
        uint256 _startBlock, uint256 _endBlock, bool _allowMng,
        string memory _rarity, string memory _uri, uint256 _authorFee,
        string memory _authorName, string memory _authorTwitter)
    external
    mintingManagers
    {

        NftInfo storage NFT = nftInfo[_nftId];

        require(NFT.nftId != 0, "NFT does not exists");

        // add new author/rarity if changed
        listOfAuthors.pushValue(_authorName);
        listOfRarity.pushValue(_rarity);

        NFT.author = _author;
        NFT.authorFee = _authorFee;
        NFT.allowMng = _allowMng;
        NFT.authorName = _authorName;
        NFT.authorTwitter = _authorTwitter;
        NFT.rarity = _rarity;
        NFT.uri = string(abi.encodePacked(_uri, "/", itod(_nftId), ".json"));
        NFT.startBlock = _startBlock;
        NFT.endBlock = _endBlock;

        // avoid fee mint/burn exploit
        require(platformFees.authorFee.add(platformFees.govFee).add(platformFees.devFee).add(_authorFee) < 10000, "TOO HIGH");

        emit NftChanged(_nftId, _author, _startBlock, _endBlock);
    }

    // manage the minting interval to avoid front-run exploiters
    function setState(uint8 _nftId, uint256 _price,
        uint256 _maxMint, uint256 _multiplier)
    external
    mintingManagers
    {
        NftInfoState storage NftState = nftInfoState[_nftId];
        require(NftState.nftId != 0, "does not exists");
        NftState.price = _price;
        NftState.maxMint = _maxMint;
        NftState.multiplier = _multiplier;
        emit NftStateAdded(_nftId, _price, _multiplier);
    }
    function adminSetNftTokenMarket(uint8 nftId, INFT _nft, IBEP20 _token) external mintingManagers {
        NftInfoState storage INFO = nftInfoState[nftId];
        INFO.nft = _nft;
        INFO.token = _token;
    }

    // change governance address
    function adminSetgovFeeAddr(address _newAddr) external onlyOwner {
        platformAddresses.govFeeAddr = _newAddr;
    }
    // change treasure/dev address
    function adminSetdevFeeAddr(address _newAddr) external onlyOwner {
        platformAddresses.devFeeAddr = _newAddr;
    }

    // manage nft emission
    function adminSetMintingManager(address _manager, bool _status) external onlyOwner {
        mintingManager[_manager] = _status;
    }

    function adminSetPlatformFee(uint256 govFee, uint256 devFee, uint256 authorFee) external onlyOwner {
        platformFees.authorFee = govFee;
        platformFees.govFee = devFee;
        platformFees.devFee = authorFee;
        require(authorFee.add(govFee).add(devFee).add(platformFees.authorFee) < 10000, "TOO HIGH");
    }

    function adminSetMarketFee(uint256 govFee, uint256 devFee, uint256 authorFee) external onlyOwner {
        platformFees.marketAuthorFee = govFee;
        platformFees.marketGovFee = devFee;
        platformFees.marketDevFee = authorFee;
        require(authorFee.add(govFee).add(devFee).add(platformFees.authorFee) < 10000, "TOO HIGH");
    }

    modifier mintingManagers(){
        require(mintingManager[_msgSender()] == true, "not manager");
        _;
    }

    function getNftIdByAuthor(string memory author)
    public view returns (uint8[] memory)
    {
        return listOfNftByAuthor[author];
    }
    function getNftIdByRarity(string memory author)
    public view returns (uint8[] memory)
    {
        return listOfNftByRarity[author];
    }
    function getNftByAuthor(string memory author) public view returns
    (NftInfo[] memory nftInfoByAuthor, NftInfoState[] memory nftInfoStateByAuthor)
    {
        uint8[] memory list = getNftIdByAuthor(author);
        uint256 authorId = authorIdByName[author];

        NftInfo[] memory info = new NftInfo[](list.length);
        NftInfoState[] memory state = new NftInfoState[](list.length);

        uint256 i = 0;
        for (uint8 index = 0; index < list.length; ++index) {
            uint8 nftId = list[index];
            if (nftInfo[nftId].authorId != authorId) {
                continue;
            }
            info[i] = nftInfo[nftId];
            state[i] = nftInfoState[nftId];
            i = i.add(1);
        }
        return (info, state);
    }

    function getNftByRarity(string memory rarity) public view returns
    (NftInfo[] memory nftInfoByRarity, NftInfoState[] memory nftInfoStateByRarity)
    {
        uint8[] memory list = getNftIdByRarity(rarity);
        uint256 rarityId = rarityIdByName[rarity];

        NftInfo[] memory info = new NftInfo[](list.length);
        NftInfoState[] memory state = new NftInfoState[](list.length);

        uint256 i = 0;
        for (uint8 index = 0; index < list.length; ++index) {
            uint8 nftId = list[index];
            if (nftInfoState[nftId].rarityId != rarityId) {
                continue;
            }
            info[i] = nftInfo[nftId];
            state[i] = nftInfoState[nftId];
            i = i.add(1);
        }
        return (info, state);
    }

    function transferByNftId(uint8 nftId, address to) external nonReentrant {
        // call "setApprovalForAll(address(this), true)" before transfer
        uint256 tradeId = getTradeIdByNftId(msg.sender, nftId);
        _transfer(tradeId, to);
    }
    // use to transfer your nft to someone (to gif for example)
    function transfer(uint256 tradeId, address to) external nonReentrant {
        // call "setApprovalForAll(address(this), true)" before transfer
        _transfer(tradeId, to);
    }
    function _transfer(uint256 tradeId, address to) internal {
        NftTradeInfo storage TRADE = nftTrade[tradeId];
        NftInfoState storage NftState = nftInfoState[TRADE.nftId];
        // NftSecondaryTradeInfo storage SECONDARY_TRADE = nftSecondaryTradeInfo[tradeId];
        require( TRADE.tradeId > 0, "transfer: nft not found");
        require( TRADE.owner == address(msg.sender), "transfer: not nft owner");
        require( TRADE.burnedIn == 0, "transfer: burned");
        // security check: if user transfer his nft via other contract, this should fail.
        require(NftState.nft.ownerOf(TRADE.tokenId) == address(msg.sender), "not owner");
        NftState.nft.safeTransferFrom(msg.sender, to, TRADE.tokenId);
        TRADE.owner = to; // update trade owner to new owner
        NftState.lastOwner = to; // new owner

        ownersOf[TRADE.nftId].removeAddress(msg.sender); // remove old owner
        ownersOf[TRADE.nftId].pushAddress(to, true); // add new owner

        nftTradeByUser[TRADE.nftId][msg.sender].removeValue(tradeId); // remove old owner
        nftTradeByUser[TRADE.nftId][to].pushValue(tradeId); // add new owner

        // remove from sell list
        listOfOpenSells[TRADE.nftId].removeValue(tradeId); // added only once

        emit NftTransfer(msg.sender, to, tradeId);
    }

    // nft secondary market sub-system:
    function setNftSellable(uint8 _nftId, bool _allowSell,
        uint256 _sellMinPrice)
    external
    mintingManagers
    {
        NftSecondaryMarket storage NFT = nftSecondaryMarket[_nftId];
        require(nftInfoState[_nftId].nftId > 0, "does not exists");
        require(_sellMinPrice > 0, "invalid sell min price");
        NFT.allowSell = _allowSell;
        NFT.sellMinPrice = _sellMinPrice;
    }

    function sell(uint256 tradeId, uint256 _price)
    external nonReentrant
    {
        require(tradeId > 0, "no minted");

        NftTradeInfo storage TRADE = nftTrade[tradeId];
        uint8 _nftId = TRADE.nftId;
        NftSecondaryMarket storage MARKET = nftSecondaryMarket[_nftId];
        NftSecondaryTradeInfo storage secondaryTrade = nftSecondaryTradeInfo[tradeId];
        require(MARKET.allowSell && secondaryTrade.sellPrice == 0, "not sellable");

        require(TRADE.owner == msg.sender, "not owner");
        require(_price >= MARKET.sellMinPrice, "price < min price");
        listOfOpenSells[_nftId].pushValue(tradeId); // added only once


        secondaryTrade.sellPrice = _price;
        secondaryTrade.sellDate = block.timestamp;

    }

    // list all trade id from a specific nft open to sell
    function getListOpenTradesByNftId(uint8 _nftId)
    public view returns (uint256[] memory sells)
    {
        return listOfOpenSells[_nftId].getAllValues();
    }

    // list all trades structs from a specific nft open to sell
    function getOpenTradesByNftId(uint8 _nftId)
    public view returns (NftTradeInfo[] memory TRADES)
    {
        uint256 size = listOfOpenSells[_nftId].size();
        NftTradeInfo[] memory listOfTrades = new NftTradeInfo[](size);
        for (uint256 i = 0; i < size; i++) {
            uint256 tradeId = listOfOpenSells[_nftId].getValueAtIndex(i);
            listOfTrades[i] = nftTrade[tradeId];
        }
        return listOfTrades;
    }

    function buy(uint8 tradeId)
    external nonReentrant
    {
        require(tradeId > 0, "buy: NFT not minted");
        NftTradeInfo storage TRADE = nftTrade[tradeId];
        NftSecondaryMarket storage MARKET = nftSecondaryMarket[TRADE.nftId];
        NftInfoState storage NftState = nftInfoState[TRADE.nftId];
        // NftInfo storage NFT = nftInfo[TRADE.nftId];

        NftSecondaryTradeInfo storage secondaryTrade = nftSecondaryTradeInfo[tradeId];
        require(MARKET.allowSell == true, "buy: NFT not sellable");
        require(TRADE.owner != msg.sender, "buy: no wash trading");
        require(TRADE.burnedIn == 0, "buy: burned");
        require(secondaryTrade.sellPrice > 0, "buy: not for sell");

        buyDoPayment(tradeId);
        // transfer from old owner to hew owner

        require(NftState.nft.ownerOf(TRADE.tokenId) == TRADE.owner, "by: not owner anymore");
        NftState.nft.safeTransferFrom(TRADE.owner, msg.sender, TRADE.tokenId);


        ownersOf[TRADE.nftId].removeAddress(TRADE.owner); // remove old owner
        ownersOf[TRADE.nftId].pushAddress(msg.sender, true); // add new owner

        nftTradeByUser[TRADE.nftId][TRADE.owner].removeValue(tradeId); // remove old owner
        nftTradeByUser[TRADE.nftId][msg.sender].pushValue(tradeId); // add new owner

        emit NftTransfer(TRADE.owner, msg.sender, tradeId);

        MARKET.qtdSells = MARKET.qtdSells.add(1);
        MARKET.lastSellPrice = secondaryTrade.sellPrice;
        MARKET.lastSellIn = block.timestamp;

        TRADE.owner = msg.sender; // update trade owner to new owner
        NftState.lastOwner = msg.sender; // new owner

    }


    function buyDoPayment(uint8 tradeId) internal {
        NftTradeInfo storage TRADE = nftTrade[tradeId];
        NftInfo storage NFT = nftInfo[TRADE.nftId];
        NftInfoState storage STATE = nftInfoState[TRADE.nftId];
        NftSecondaryMarket storage secondaryMarketInfo = nftSecondaryMarket[tradeId];
        NftSecondaryTradeInfo storage secondaryTrade = nftSecondaryTradeInfo[tradeId];


        // transfer tokens from new owner to old owner
        uint256 _authorFee = NFT.authorFee;
        if (_authorFee == 0) {
            _authorFee = platformFees.authorFee;
            // default author fee
        }

        uint256 _artistFee = secondaryTrade.sellPrice.mul(_authorFee).div(10000);
        uint256 _governanceFee = secondaryTrade.sellPrice.mul(platformFees.govFee).div(10000);
        uint256 _devFee = secondaryTrade.sellPrice.mul(platformFees.devFee).div(10000);
        uint256 _totalSold = secondaryTrade.sellPrice.sub(_artistFee).sub(_governanceFee).sub(_devFee);

        // do platform transfers
        STATE.token.safeTransferFrom(address(msg.sender), NFT.author, _artistFee);
        STATE.token.safeTransferFrom(address(msg.sender), platformAddresses.govFeeAddr, _governanceFee);
        STATE.token.safeTransferFrom(address(msg.sender), platformAddresses.devFeeAddr, _devFee);

        // after fees, pay old owner:
        STATE.token.safeTransferFrom(address(msg.sender), TRADE.owner, _totalSold);

        // accumulate fees paid
        secondaryMarketInfo.totalArtistFee = secondaryMarketInfo.totalArtistFee.add(_artistFee);
        secondaryMarketInfo.totalGovernanceFee = secondaryMarketInfo.totalGovernanceFee.add(_governanceFee);
        secondaryMarketInfo.totalDevFee = secondaryMarketInfo.totalDevFee.add(_devFee);
        secondaryMarketInfo.totalCollected = secondaryMarketInfo.totalCollected.add(_totalSold);

        secondaryTrade.sellPrice = 0; // reset selling property
        secondaryTrade.soldDate = block.timestamp; //when sold

        // remove this trade from the list of open trades
        listOfOpenSells[TRADE.nftId].removeValue(tradeId); // added only once

    }



    //auxiliary market views

    // list all unique nft id that this user has minted
    function getNftIdByUser(address user)
        public view returns (uint8[] memory)
    {
        return nftIdByUser[user].getAllValues();
    }

    // return all trade id numbers by nft id and user wallet
    function getTradesByNftIdAndUser(address user, uint8 nftId)
        public view returns (uint256[] memory)
    {
        return nftTradeByUser[nftId][user].getAllValues();
    }
    function getBurnsByNftIdAndUser(address user, uint8 nftId)
        public view returns (uint256[] memory)
    {
        return nftBurnsByUser[nftId][user].getAllValues();
    }

    // return a nft mint/burn (aka trade) by trade id number.
    function getTradeByTradeId(uint256 tradeId)
        public view returns (NftTradeInfo memory)
    {
        return nftTrade[tradeId];
    }

    function getTradeIdByNftId(address user, uint8 nftId)
        public view returns (uint256)
    {
        uint256 size = nftTradeByUser[nftId][user].size();
        require( size > 0, "no nft minted" );
        return nftTradeByUser[nftId][user].getValueAtIndex(0);
    }


    function getAllAuthors()
    public view returns (string[] memory)
    {
        return listOfAuthors.getAllValues();
    }
    function getAllRarity()
    public view returns (string[] memory)
    {
        return listOfRarity.getAllValues();
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` representation.
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
        uint256 index = digits - 1;
        temp = value;
        while (temp != 0) {
            buffer[index--] = bytes1(uint8(48 + temp % 10));
            temp /= 10;
        }
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () internal {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;

        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) { // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            // When the value to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            bytes32 lastvalue = set._values[lastIndex];

            // Move the last value to the index where the value to delete is
            set._values[toDeleteIndex] = lastvalue;
            // Update the index for the moved value
            set._indexes[lastvalue] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }


    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

   /**
    * @dev Returns the value stored at position `index` in the set. O(1).
    *
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Library for managing an enumerable variant of Solidity's
 * https://solidity.readthedocs.io/en/latest/types.html#mapping-types[`mapping`]
 * type.
 *
 * Maps have the following properties:
 *
 * - Entries are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Entries are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableMap for EnumerableMap.UintToAddressMap;
 *
 *     // Declare a set state variable
 *     EnumerableMap.UintToAddressMap private myMap;
 * }
 * ```
 *
 * As of v3.0.0, only maps of type `uint256 -> address` (`UintToAddressMap`) are
 * supported.
 */
library EnumerableMap {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Map type with
    // bytes32 keys and values.
    // The Map implementation uses private functions, and user-facing
    // implementations (such as Uint256ToAddressMap) are just wrappers around
    // the underlying Map.
    // This means that we can only create new EnumerableMaps for types that fit
    // in bytes32.

    struct MapEntry {
        bytes32 _key;
        bytes32 _value;
    }

    struct Map {
        // Storage of map keys and values
        MapEntry[] _entries;

        // Position of the entry defined by a key in the `entries` array, plus 1
        // because index 0 means a key is not in the map.
        mapping (bytes32 => uint256) _indexes;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function _set(Map storage map, bytes32 key, bytes32 value) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex == 0) { // Equivalent to !contains(map, key)
            map._entries.push(MapEntry({ _key: key, _value: value }));
            // The entry is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            map._indexes[key] = map._entries.length;
            return true;
        } else {
            map._entries[keyIndex - 1]._value = value;
            return false;
        }
    }

    /**
     * @dev Removes a key-value pair from a map. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function _remove(Map storage map, bytes32 key) private returns (bool) {
        // We read and store the key's index to prevent multiple reads from the same storage slot
        uint256 keyIndex = map._indexes[key];

        if (keyIndex != 0) { // Equivalent to contains(map, key)
            // To delete a key-value pair from the _entries array in O(1), we swap the entry to delete with the last one
            // in the array, and then remove the last entry (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = keyIndex - 1;
            uint256 lastIndex = map._entries.length - 1;

            // When the entry to delete is the last one, the swap operation is unnecessary. However, since this occurs
            // so rarely, we still do the swap anyway to avoid the gas cost of adding an 'if' statement.

            MapEntry storage lastEntry = map._entries[lastIndex];

            // Move the last entry to the index where the entry to delete is
            map._entries[toDeleteIndex] = lastEntry;
            // Update the index for the moved entry
            map._indexes[lastEntry._key] = toDeleteIndex + 1; // All indexes are 1-based

            // Delete the slot where the moved entry was stored
            map._entries.pop();

            // Delete the index for the deleted slot
            delete map._indexes[key];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function _contains(Map storage map, bytes32 key) private view returns (bool) {
        return map._indexes[key] != 0;
    }

    /**
     * @dev Returns the number of key-value pairs in the map. O(1).
     */
    function _length(Map storage map) private view returns (uint256) {
        return map._entries.length;
    }

   /**
    * @dev Returns the key-value pair stored at position `index` in the map. O(1).
    *
    * Note that there are no guarantees on the ordering of entries inside the
    * array, and it may change when more entries are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function _at(Map storage map, uint256 index) private view returns (bytes32, bytes32) {
        require(map._entries.length > index, "EnumerableMap: index out of bounds");

        MapEntry storage entry = map._entries[index];
        return (entry._key, entry._value);
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     */
    function _tryGet(Map storage map, bytes32 key) private view returns (bool, bytes32) {
        uint256 keyIndex = map._indexes[key];
        if (keyIndex == 0) return (false, 0); // Equivalent to contains(map, key)
        return (true, map._entries[keyIndex - 1]._value); // All indexes are 1-based
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function _get(Map storage map, bytes32 key) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, "EnumerableMap: nonexistent key"); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    /**
     * @dev Same as {_get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {_tryGet}.
     */
    function _get(Map storage map, bytes32 key, string memory errorMessage) private view returns (bytes32) {
        uint256 keyIndex = map._indexes[key];
        require(keyIndex != 0, errorMessage); // Equivalent to contains(map, key)
        return map._entries[keyIndex - 1]._value; // All indexes are 1-based
    }

    // UintToAddressMap

    struct UintToAddressMap {
        Map _inner;
    }

    /**
     * @dev Adds a key-value pair to a map, or updates the value for an existing
     * key. O(1).
     *
     * Returns true if the key was added to the map, that is if it was not
     * already present.
     */
    function set(UintToAddressMap storage map, uint256 key, address value) internal returns (bool) {
        return _set(map._inner, bytes32(key), bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the key was removed from the map, that is if it was present.
     */
    function remove(UintToAddressMap storage map, uint256 key) internal returns (bool) {
        return _remove(map._inner, bytes32(key));
    }

    /**
     * @dev Returns true if the key is in the map. O(1).
     */
    function contains(UintToAddressMap storage map, uint256 key) internal view returns (bool) {
        return _contains(map._inner, bytes32(key));
    }

    /**
     * @dev Returns the number of elements in the map. O(1).
     */
    function length(UintToAddressMap storage map) internal view returns (uint256) {
        return _length(map._inner);
    }

   /**
    * @dev Returns the element stored at position `index` in the set. O(1).
    * Note that there are no guarantees on the ordering of values inside the
    * array, and it may change when more values are added or removed.
    *
    * Requirements:
    *
    * - `index` must be strictly less than {length}.
    */
    function at(UintToAddressMap storage map, uint256 index) internal view returns (uint256, address) {
        (bytes32 key, bytes32 value) = _at(map._inner, index);
        return (uint256(key), address(uint160(uint256(value))));
    }

    /**
     * @dev Tries to returns the value associated with `key`.  O(1).
     * Does not revert if `key` is not in the map.
     *
     * _Available since v3.4._
     */
    function tryGet(UintToAddressMap storage map, uint256 key) internal view returns (bool, address) {
        (bool success, bytes32 value) = _tryGet(map._inner, bytes32(key));
        return (success, address(uint160(uint256(value))));
    }

    /**
     * @dev Returns the value associated with `key`.  O(1).
     *
     * Requirements:
     *
     * - `key` must be in the map.
     */
    function get(UintToAddressMap storage map, uint256 key) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key)))));
    }

    /**
     * @dev Same as {get}, with a custom error message when `key` is not in the map.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryGet}.
     */
    function get(UintToAddressMap storage map, uint256 key, string memory errorMessage) internal view returns (address) {
        return address(uint160(uint256(_get(map._inner, bytes32(key), errorMessage))));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../math/SafeMath.sol";

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 * Since it is not possible to overflow a 256 bit integer with increments of one, `increment` can skip the {SafeMath}
 * overflow check, thereby saving gas. This does assume however correct usage, in that the underlying `_value` is never
 * directly accessed.
 */
library Counters {
    using SafeMath for uint256;

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
        // The {SafeMath} overflow check can be skipped here, see the comment at the top
        counter._value += 1;
    }

    function decrement(Counter storage counter) internal {
        counter._value = counter._value.sub(1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

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

pragma solidity >=0.6.0 <0.8.0;

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

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

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

pragma solidity >=0.6.2 <0.8.0;

import "./IERC721.sol";

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

pragma solidity >=0.6.2 <0.8.0;

import "../../introspection/IERC165.sol";

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

pragma solidity >=0.6.0 <0.8.0;

import "../../utils/Context.sol";
import "./IERC721.sol";
import "./IERC721Metadata.sol";
import "./IERC721Enumerable.sol";
import "./IERC721Receiver.sol";
import "../../introspection/ERC165.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";
import "../../utils/EnumerableSet.sol";
import "../../utils/EnumerableMap.sol";
import "../../utils/Strings.sol";

/**
 * @title ERC721 Non-Fungible Token Standard basic implementation
 * @dev see https://eips.ethereum.org/EIPS/eip-721
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata, IERC721Enumerable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.UintSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;
    using Strings for uint256;

    // Equals to `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
    // which can be also obtained as `IERC721Receiver(0).onERC721Received.selector`
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    // Mapping from holder address to their (enumerable) set of owned tokens
    mapping (address => EnumerableSet.UintSet) private _holderTokens;

    // Enumerable mapping from token ids to their owners
    EnumerableMap.UintToAddressMap private _tokenOwners;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Optional mapping for token URIs
    mapping (uint256 => string) private _tokenURIs;

    // Base URI
    string private _baseURI;

    /*
     *     bytes4(keccak256('balanceOf(address)')) == 0x70a08231
     *     bytes4(keccak256('ownerOf(uint256)')) == 0x6352211e
     *     bytes4(keccak256('approve(address,uint256)')) == 0x095ea7b3
     *     bytes4(keccak256('getApproved(uint256)')) == 0x081812fc
     *     bytes4(keccak256('setApprovalForAll(address,bool)')) == 0xa22cb465
     *     bytes4(keccak256('isApprovedForAll(address,address)')) == 0xe985e9c5
     *     bytes4(keccak256('transferFrom(address,address,uint256)')) == 0x23b872dd
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256)')) == 0x42842e0e
     *     bytes4(keccak256('safeTransferFrom(address,address,uint256,bytes)')) == 0xb88d4fde
     *
     *     => 0x70a08231 ^ 0x6352211e ^ 0x095ea7b3 ^ 0x081812fc ^
     *        0xa22cb465 ^ 0xe985e9c5 ^ 0x23b872dd ^ 0x42842e0e ^ 0xb88d4fde == 0x80ac58cd
     */
    bytes4 private constant _INTERFACE_ID_ERC721 = 0x80ac58cd;

    /*
     *     bytes4(keccak256('name()')) == 0x06fdde03
     *     bytes4(keccak256('symbol()')) == 0x95d89b41
     *     bytes4(keccak256('tokenURI(uint256)')) == 0xc87b56dd
     *
     *     => 0x06fdde03 ^ 0x95d89b41 ^ 0xc87b56dd == 0x5b5e139f
     */
    bytes4 private constant _INTERFACE_ID_ERC721_METADATA = 0x5b5e139f;

    /*
     *     bytes4(keccak256('totalSupply()')) == 0x18160ddd
     *     bytes4(keccak256('tokenOfOwnerByIndex(address,uint256)')) == 0x2f745c59
     *     bytes4(keccak256('tokenByIndex(uint256)')) == 0x4f6ccce7
     *
     *     => 0x18160ddd ^ 0x2f745c59 ^ 0x4f6ccce7 == 0x780e9d63
     */
    bytes4 private constant _INTERFACE_ID_ERC721_ENUMERABLE = 0x780e9d63;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor (string memory name_, string memory symbol_) public {
        _name = name_;
        _symbol = symbol_;

        // register the supported interfaces to conform to ERC721 via ERC165
        _registerInterface(_INTERFACE_ID_ERC721);
        _registerInterface(_INTERFACE_ID_ERC721_METADATA);
        _registerInterface(_INTERFACE_ID_ERC721_ENUMERABLE);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _holderTokens[owner].length();
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        return _tokenOwners.get(tokenId, "ERC721: owner query for nonexistent token");
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

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }

    /**
    * @dev Returns the base URI set via {_setBaseURI}. This will be
    * automatically added as a prefix in {tokenURI} to each token's URI, or
    * to the token ID if no specific URI is set for that token ID.
    */
    function baseURI() public view virtual returns (string memory) {
        return _baseURI;
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        return _holderTokens[owner].at(index);
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        // _tokenOwners are indexed by tokenIds, so .length() returns the number of tokenIds
        return _tokenOwners.length();
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        (uint256 tokenId, ) = _tokenOwners.at(index);
        return tokenId;
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
        return _tokenOwners.contains(tokenId);
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
     d*
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

        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

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
        address owner = ERC721.ownerOf(tokenId); // internal owner

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        // Clear metadata (if any)
        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }

        _holderTokens[owner].remove(tokenId);

        _tokenOwners.remove(tokenId);

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
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own"); // internal owner
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _holderTokens[from].remove(tokenId);
        _holderTokens[to].add(tokenId);

        _tokenOwners.set(tokenId, to);

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721Metadata: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev Internal function to set the base URI for all token IDs. It is
     * automatically added as a prefix to the value returned in {tokenURI},
     * or to the token ID if {tokenURI} is empty.
     */
    function _setBaseURI(string memory baseURI_) internal virtual {
        _baseURI = baseURI_;
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
        if (!to.isContract()) {
            return true;
        }
        bytes memory returndata = to.functionCall(abi.encodeWithSelector(
            IERC721Receiver(to).onERC721Received.selector,
            _msgSender(),
            from,
            tokenId,
            _data
        ), "ERC721: transfer to non ERC721Receiver implementer");
        bytes4 retval = abi.decode(returndata, (bytes4));
        return (retval == _ERC721_RECEIVED);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId); // internal owner
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

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
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
        require(b <= a, "SafeMath: subtraction overflow");
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
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
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
        require(b > 0, "SafeMath: modulo by zero");
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
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
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts may inherit from this and call {_registerInterface} to declare
 * their support of an interface.
 */
abstract contract ERC165 is IERC165 {
    /*
     * bytes4(keccak256('supportsInterface(bytes4)')) == 0x01ffc9a7
     */
    bytes4 private constant _INTERFACE_ID_ERC165 = 0x01ffc9a7;

    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () internal {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(_INTERFACE_ID_ERC165);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

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
    constructor () internal {
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.6.12;
library StringUtils {
    function addTo( string[] storage arr, string memory v )
    public returns (bool)
    {
        for (uint i = 0; i < arr.length; i ++){
            string memory c = arr[i];
            if( equal(v,c) ){
                return false;
            }
        }
        arr.push(v);
        return true;
    }
    /// @dev Does a byte-by-byte lexicographical comparison of two strings.
    /// @return a negative number if `_a` is smaller, zero if they are equal
    /// and a positive numbe if `_b` is smaller.
    function compare(string memory _a, string memory _b) internal pure returns (int) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        uint minLength = a.length;
        if (b.length < minLength) minLength = b.length;
        //@todo unroll the loop into increments of 32 and do full 32 byte comparisons
        for (uint i = 0; i < minLength; i ++)
            if (a[i] < b[i])
                return -1;
            else if (a[i] > b[i])
                return 1;
        if (a.length < b.length)
            return -1;
        else if (a.length > b.length)
            return 1;
        else
            return 0;
    }
    /// @dev Compares two strings and returns true iff they are equal.
    function equal(string memory _a, string memory _b) internal pure returns (bool) {
        return compare(_a, _b) == 0;
    }
    /// @dev Finds the index of the first occurrence of _needle in _haystack
    function indexOf(string memory _haystack, string memory _needle) internal pure returns (int)
    {
        bytes memory h = bytes(_haystack);
        bytes memory n = bytes(_needle);
        if(h.length < 1 || n.length < 1 || (n.length > h.length))
            return -1;
        else if(h.length > (2**128 -1)) // since we have to be able to return -1 (if the char isn't found or input error), this function must return an "int" type with a max length of (2^128 - 1)
            return -1;
        else
        {
            uint subindex = 0;
            for (uint i = 0; i < h.length; i ++)
            {
                if (h[i] == n[0]) // found the first char of b
                {
                    subindex = 1;
                    while(subindex < n.length && (i + subindex) < h.length && h[i + subindex] == n[subindex]) // search until the chars don't match or until we reach the end of a or b
                    {
                        subindex++;
                    }
                    if(subindex == n.length)
                        return int(i);
                }
            }
            return -1;
        }
    }
}

/*
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library Uint8ArrayLib {
    using Uint8ArrayLib for Values;
    struct Values {
        uint8[]  _items;
    }
    function pushValue(Values storage self, uint8 element) internal returns (bool) {
        if (!exists(self, element)) {
            self._items.push(element);
            return true;
        }
        return false;
    }
    function removeValue(Values storage self, uint8 element) internal returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                self._items[i] = self._items[self.size() - 1];
                self._items.pop();
                return true;
            }
        }
        return false;
    }
    function getValueAtIndex(Values storage self, uint8 index) internal view returns (uint8) {
        require(index < size(self), "the index is out of bounds");
        return self._items[index];
    }
    function size(Values storage self) internal view returns (uint256) {
        return self._items.length;
    }
    function exists(Values storage self, uint8 element) internal view returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                return true;
            }
        }
        return false;
    }
    function getAllValues(Values storage self) internal view returns(uint8[] memory) {
        return self._items;
    }

}

/*
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
library Uint256ArrayLib {
    using Uint256ArrayLib for Values;
    struct Values {
        uint256[]  _items;
    }
    function pushValue(Values storage self, uint256 element) internal returns (bool) {
        if (!exists(self, element)) {
            self._items.push(element);
            return true;
        }
        return false;
    }
    function removeValue(Values storage self, uint256 element) internal returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                self._items[i] = self._items[self.size() - 1];
                self._items.pop();
                return true;
            }
        }
        return false;
    }
    function getValueAtIndex(Values storage self, uint256 index) internal view returns (uint256) {
        require(index < size(self), "the index is out of bounds");
        return self._items[index];
    }
    function size(Values storage self) internal view returns (uint256) {
        return self._items.length;
    }
    function exists(Values storage self, uint256 element) internal view returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                return true;
            }
        }
        return false;
    }
    function getAllValues(Values storage self) internal view returns(uint256[] memory) {
        return self._items;
    }
}

/*
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
// SPDX-License-Identifier: MIT
import "./stringUtils.sol";
pragma solidity 0.6.12;

library StringArrayLib {
    using StringArrayLib for Values;
    struct Values {
        string[]  _items;
    }
    function pushValue(Values storage self, string memory element) internal returns (bool) {
        if (!exists(self, element)) {
            self._items.push(element);
            return true;
        }
        return false;
    }
    function removeValue(Values storage self, string memory element) internal returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if ( StringUtils.equal(self._items[i], element)) {
                self._items[i] = self._items[self.size() - 1];
                self._items.pop();
                return true;
            }
        }
        return false;
    }
    function size(Values storage self) internal view returns (uint256) {
        return self._items.length;
    }
    function exists(Values storage self, string memory element) internal view returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if ( StringUtils.equal(self._items[i], element) ) {
                return true;
            }
        }
        return false;
    }
    function getAllValues(Values storage self) internal view returns(string[] memory) {
        return self._items;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./IBEP20.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";

/**
 * @title SafeBEP20
 * @dev Wrappers around BEP20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeBEP20 for IBEP20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeBEP20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(IBEP20 token, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IBEP20 token, address from, address to, uint256 value) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IBEP20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(IBEP20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeBEP20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IBEP20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeBEP20: decreased allowance below zero");
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IBEP20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeBEP20: low-level call failed");
        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeBEP20: BEP20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
/**
Copyright 2021 <bitdeep, twitter.com/bitdeep_oficial, t.me/bitdeep>

Permission is hereby granted, free of charge, to any person obtaining a
copy of this software and associated documentation files (the "Software"),
to deal in the Software without restriction, including without limitation
the rights to use, copy, modify, merge, publish, distribute, sublicense,
and/or sell copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
OR OTHER DEALINGS IN THE SOFTWARE.

// 2021 - bitdeep, twitter.com/bitdeep_oficial, t.me/bitdeep

**/

pragma solidity ^0.6.12;

interface INFT {
    function setNftName(uint8 _nftId, string calldata _name) external;
    function mint(address _to, string calldata _tokenURI, uint8 _nftId) external returns (uint256);
    function getNftId(uint256 _tokenId) external view returns (uint8);
    function burn(uint256 _tokenId) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function approve(address to, uint256 tokenId) external;
    function setApprovalForAll(address operator, bool approved) external;
    function getApproved(uint256 tokenId) external view returns (address);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
    function manageMinters(address user, bool status) external;
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.6.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

/*
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
library AddrArrayLib {
    using AddrArrayLib for Addresses;
    struct Addresses {
        address[]  _items;
    }
    function pushAddress(Addresses storage self, address element, bool allowDup) internal {
        if( allowDup ){
            self._items.push(element);
        }else if (!exists(self, element)) {
            self._items.push(element);
        }
    }
    function removeAddress(Addresses storage self, address element) internal returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                self._items[i] = self._items[self.size() - 1];
                self._items.pop();
                return true;
            }
        }
        return false;
    }
    function getAddressAtIndex(Addresses storage self, uint256 index) internal view returns (address) {
        require(index < size(self), "the index is out of bounds");
        return self._items[index];
    }
    function size(Addresses storage self) internal view returns (uint256) {
        return self._items.length;
    }
    function exists(Addresses storage self, address element) internal view returns (bool) {
        for (uint i = 0; i < self.size(); i++) {
            if (self._items[i] == element) {
                return true;
            }
        }
        return false;
    }
    function getAllAddresses(Addresses storage self) internal view returns(address[] memory) {
        return self._items;
    }
}