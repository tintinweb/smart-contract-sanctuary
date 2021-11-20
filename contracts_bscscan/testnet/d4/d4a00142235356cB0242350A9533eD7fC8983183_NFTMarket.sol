// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity ^0.8.4;


import './interfaces/IERC20.sol';
import './interfaces/IDOSC.sol';
import './interfaces/IERC721Metadata.sol';

import "./libraries/Context.sol";

contract NFTMarket is Context {

    // total number of NFTs on the market
    uint32 public totalAuctions;

    struct nftInfo {
        uint auctionId;
        address nftContract;
        uint256 tokenId;
        string tokenURI;
    }

    struct auctionNFT {
        uint auctionId;
        address owner;
        uint minPrice;
        uint endAuction;
        address buyer;
        uint sellingPrice;
        bool sold;
    }

    struct auctionInfo{
        uint auctionId;
        uint lastBidNumber;
        address lastbuyer;
        uint lastbid;
    }

    struct buyerInfo{
        uint totalBids;
        uint amountBet;
        bool winner;
    }

    event AuctionCreated (
        uint indexed AuctionId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address owner,
        uint256 minPrice,
        uint endAuction
    );

    event BidCreated (
        uint indexed AuctionId,
        uint bidNumber,
        address lastbuyer,
        uint lastbid
    );

    event Withdraw (
        uint indexed AuctionId,
        address participant,
        uint amount
    );

    event NFTClaimed (
        uint indexed AuctionId,
        address winner
    );

    mapping(uint => nftInfo) public NFTtoInfo;

    mapping(uint => auctionInfo) public AuctiontoInfo;
    mapping(uint => auctionNFT) public AuctiontoNFT;

    mapping(address => mapping(uint => bool)) public ExistingAuctions;
    mapping(address => mapping(address => mapping(uint => buyerInfo))) public BuyerAuction;

    uint public maxPrice;
    
    function setMaxPrice(uint newMax) external Demokratia(){
        require(newMax >= 1000, 'Maximum is too low');
        maxPrice = newMax;
    }

    function createAuction(
        address _nftContract,
        uint256 _tokenId,
        uint256 _minPrice,
        uint256 _endAuction
    ) external {

        totalAuctions += 1;
        require(!ExistingAuctions[_nftContract][_tokenId], 'Auction already exist');
        require(_endAuction > block.timestamp + 3600, 'You need to set at least one hour auction time');
        
        IERC721Metadata nftFactory = IERC721Metadata(_nftContract);
        
        require(_msgSender() == nftFactory.ownerOf(_tokenId), 'Caller must be owner of NFT');
        require(nftFactory.isApprovedForAll(_msgSender(), address(this)), 'Caller must Approve operator');
        require(_minPrice  > 0, "Price must be at least 1 $LENNY");
        require(_minPrice <= maxPrice, "Price must be the less than maxPrice");

        uint256 _auctionId = totalAuctions;
        string memory _uri = nftFactory.tokenURI(_tokenId);
        
        NFTtoInfo[_auctionId] = nftInfo (
            _auctionId,
            _nftContract,
            _tokenId,
            _uri
        );

        AuctiontoNFT[_auctionId] =  auctionNFT (
            _auctionId,
            _msgSender(),
            _minPrice,
            _endAuction,
            address(0),
            0,
            false
        );

        nftFactory.transferFrom(_msgSender(), address(this), _tokenId);
        
        ExistingAuctions[_nftContract][_tokenId] = true;

        AuctiontoInfo[_auctionId] = auctionInfo (
            _auctionId,
            0,
            address(0),
            0
        );
        
        emit AuctionCreated(
            _auctionId,
            _nftContract,
            _tokenId,
            _msgSender(),
            _minPrice,
            _endAuction
        );
    }

    function updateAuction (uint _auctionId, uint _minPrice, uint _endAuction) external {
        auctionNFT storage auction = AuctiontoNFT[_auctionId];
        require(auction.auctionId == _auctionId, 'Auction have to exist');
        require(auction.owner == _msgSender(), 'update has to be made by the owner');
        require(auction.endAuction <= block.timestamp, 'Auction have to be done');

        auction.minPrice = _minPrice;
        auction.endAuction = _endAuction;
        
        nftInfo storage infoNFT = NFTtoInfo[_auctionId];

        emit AuctionCreated(
            _auctionId,
            infoNFT.nftContract,
            infoNFT.tokenId,
            _msgSender(),
            _minPrice,
            _endAuction
        );
    }

    function bid(uint _auctionId, uint _bidPrice) external {
        auctionNFT storage auction = AuctiontoNFT[_auctionId];
        nftInfo storage infoNFT = NFTtoInfo[_auctionId];

        require(auction.auctionId == _auctionId, 'Auction have to exist');
        require(auction.endAuction >= block.timestamp, 'Auction have to be active');

        auctionInfo storage info = AuctiontoInfo[_auctionId];
        require(_bidPrice > info.lastbid && _bidPrice >= auction.minPrice, 'Bid has to be higher than last Price');

        IERC20 lenny = IERC20(addressLENNY);
        uint newBet = _bidPrice * 10 ** lenny.decimals();
        require(lenny.balanceOf(_msgSender())>= newBet, 'No enought Token');

        buyerInfo storage buyer = BuyerAuction[_msgSender()][infoNFT.nftContract][infoNFT.tokenId];
        require(!buyer.winner, 'You are already Winner');
        
        uint newbid = buyer.totalBids + 1;
        uint amountToAdd = newBet - buyer.amountBet * 10 ** lenny.decimals();

        lenny.transferFrom(_msgSender(), address(this), amountToAdd);

        if( info.lastbuyer!=address(0) ){
            BuyerAuction[info.lastbuyer][infoNFT.nftContract][infoNFT.tokenId].winner = false;
        }

        BuyerAuction[_msgSender()][infoNFT.nftContract][infoNFT.tokenId] = buyerInfo (
            newbid,
            _bidPrice,
            true
        );

        uint newBidNumber = info.lastBidNumber + 1;
        
        AuctiontoInfo[_auctionId] = auctionInfo (
            _auctionId,
            newBidNumber,
            _msgSender(),
            _bidPrice
        );

        emit BidCreated(
            _auctionId,
            newBidNumber,
            _msgSender(),
            _bidPrice
        );
    }

    function withdrawBet (uint _auctionId) external {
        nftInfo storage infoNFT = NFTtoInfo[_auctionId];
        buyerInfo storage buyer = BuyerAuction[_msgSender()][infoNFT.nftContract][infoNFT.tokenId];
        require(!buyer.winner, 'Winner can not call withdrawnBet');
        require(buyer.amountBet != 0, 'Only participant can call');

        IERC20 lenny = IERC20(addressLENNY);
        uint decimalAmount = buyer.amountBet * 10 ** lenny.decimals();
        lenny.transfer(_msgSender(), decimalAmount);

        BuyerAuction[_msgSender()][infoNFT.nftContract][infoNFT.tokenId] = buyerInfo (
            0,
            0,
            false
        );

        emit Withdraw(_auctionId, _msgSender(), decimalAmount);
    }


    function claimNFT (uint _auctionId) external {
        auctionNFT storage auction = AuctiontoNFT[_auctionId];
        nftInfo storage infoNFT = NFTtoInfo[_auctionId];

        require(block.timestamp >= auction.endAuction, 'Selling period must have ended');
        require(!auction.sold, 'NFT already claimed');

        buyerInfo storage buyer = BuyerAuction[_msgSender()][infoNFT.nftContract][infoNFT.tokenId];
        require(buyer.winner, 'Only winner can call this function');
        
        IERC20 lenny = IERC20(addressLENNY);
        uint decimalAmount = buyer.amountBet * 10 ** lenny.decimals();

        lenny.transfer(auction.owner, decimalAmount);

        IERC721 nftFactory = IERC721(infoNFT.nftContract);        
        nftFactory.safeTransferFrom(address(this), _msgSender() , infoNFT.tokenId);

        AuctiontoNFT[_auctionId].buyer = _msgSender();
        AuctiontoNFT[_auctionId].sellingPrice = buyer.amountBet;
        AuctiontoNFT[_auctionId].sold = true;

        emit NFTClaimed (_auctionId, _msgSender());
    }

    // Extract items
    function getAllNFT() external view returns (nftInfo[] memory){

        nftInfo[] memory listInfo  = new nftInfo[](totalAuctions);
        
        for (uint i = 1; i <= totalAuctions; i++) {
            nftInfo storage info = NFTtoInfo[i];
            uint index = i - 1;
            listInfo[index] = info;
        }

        return listInfo;
    }

    
    // Add $LENNY Token
    address public addressLENNY;
    
    function addLennyAddress (address newAdd) external Demokratia() {
        addressLENNY = newAdd;
    }

    // democratic 
    address public addressDOSC;
    address public LastAuthorizedAddress;
    uint public LastChangingTime;
    
    function UpdateSC() external {
        IDOSC dosc = IDOSC(addressDOSC);
        LastAuthorizedAddress = dosc.readAuthorizedAddress();
        LastChangingTime = dosc.readEndChangeTime();
    }

    modifier Demokratia() {
        require(LastAuthorizedAddress == _msgSender(), "You are not authorized to change");
        require(LastChangingTime >= block.timestamp, "Time for changes expired");
        _;
    }

    constructor(uint _maxPrice, address _DOSCadd) {
        maxPrice = _maxPrice;
        addressDOSC = _DOSCadd;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IERC20 {
    
    // IERC20
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    // IERC20Metadata 
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;


interface IDOSC {
    function readAuthorizedAddress() external view returns (address);
    function readEndChangeTime() external view returns (uint);
    function RegisterCall(string memory scname, string memory funcname) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
import "./IERC721.sol";


interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * @dev Required interface of an ERC721 compliant contract.
*/
interface IERC721 {

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