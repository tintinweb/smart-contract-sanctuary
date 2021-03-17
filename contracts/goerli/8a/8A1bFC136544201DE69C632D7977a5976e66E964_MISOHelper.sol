/**
 *Submitted for verification at Etherscan.io on 2021-03-17
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;



// Part: IBaseAuction

// import "../Auctions/DutchAuction.sol";
// import "../Auctions/BatchAuction.sol";
// import "../Auctions/HyperbolicAuction.sol";

interface IBaseAuction {
    function getBaseInformation() external view returns (
            address auctionToken,
            uint64 startTime,
            uint64 endTime,
            bool finalized
        );
}

// Part: IDocument

interface IDocument {
    function getDocument(bytes32 _name) external view returns (string memory, bytes32, uint256);
    function getAllDocuments() external view returns (bytes32[] memory);
}

// Part: IERC20

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    // function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    // function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /// @notice EIP 2612
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// Part: IMisoMarket

interface IMisoMarket {

    function initMarket(
        bytes calldata data
    ) external;

    function getMarkets() external view returns(address[] memory);

    function getMarketTemplateId(address _auction) external view returns(uint64);
}

// Part: IMisoTokenFactory

interface IMisoTokenFactory {
    function numberOfTokens() external view returns (uint256);
    function getTokens() external view returns (address[] memory);
}

// Part: DocumentHepler

contract DocumentHepler {
    struct Document {
        bytes32 docHash;
        uint256 lastModified;
        string uri;
    }

    function getDocuments(address _document) public view returns(Document[] memory) {
        IDocument document = IDocument(_document);
        bytes32[] memory documentNames = document.getAllDocuments();
        Document[] memory documents = new Document[](documentNames.length);

        for(uint256 i = 0; i < documentNames.length; i++) {
            (
                documents[i].uri,
                documents[i].docHash,
                documents[i].lastModified
            ) = document.getDocument(documentNames[i]);
        }

        return documents;
    }
}

// Part: TokenHelper

contract TokenHelper {
    struct TokenInfo {
        address token;
        uint256 decimals;
        string name;
        string symbol;
    }

    function getTokensInfo(address[] calldata addresses) public view returns (TokenInfo[] memory)
    {
        TokenInfo[] memory infos = new TokenInfo[](addresses.length);

        for (uint256 i = 0; i < addresses.length; i++) {
            IERC20 token = IERC20(addresses[i]);
            infos[i].token = address(token);

            infos[i].name = token.name();
            infos[i].symbol = token.symbol();
            infos[i].decimals = token.decimals();
        }

        return infos;
    }

    function getTokenInfo(address _address) public view returns (TokenInfo memory) {
        TokenInfo memory info;
        IERC20 token = IERC20(_address);

        info.token = _address;
        info.name = token.name();
        info.symbol = token.symbol();
        // info.decimals = token.decimals();

        return info;
    }
}

// File: MISOHelper.sol

contract MISOHelper is TokenHelper, DocumentHepler {
    IMisoMarket public market;
    IMisoTokenFactory public tokenFactory;
    
    // struct CrowdsaleInfo {
    //     address crowdsale;
    //     address paymentCurrency;
    //     uint128 amountRaised;
    //     uint128 totalTokens;
    //     uint128 rate;
    //     uint128 goal;
    //     uint64 startTime;
    //     uint64 endTime;
    //     bool finalized;
    //     bool hasPointList;
    //     TokenInfo tokenInfo;
    //     Document[] documents;
    // }

    struct MarketBaseInfo {
        address market;
        uint64 templateId;
        uint64 startTime;
        uint64 endTime;
        bool finalized;
        TokenInfo tokenInfo;
    }

    function setContracts(address _market, address _tokenFactory) public {
        market = IMisoMarket(_market);
        tokenFactory = IMisoTokenFactory(_tokenFactory);
    }

    function getTokens() public view returns(TokenInfo[] memory) {
        address[] memory tokens = tokenFactory.getTokens();
        TokenInfo[] memory infos = new TokenInfo[](tokens.length);

        for (uint256 i = 0; i < tokens.length; i++) {
            IERC20 token = IERC20(tokens[i]);
            infos[i].token = address(token);
            
            infos[i].name = token.name();
            infos[i].symbol = token.symbol();
            infos[i].decimals = token.decimals();
        }

        return infos;
    }

    function getMarkets() public view returns (MarketBaseInfo[] memory) {
        address[] memory markets = market.getMarkets();
        MarketBaseInfo[] memory infos = new MarketBaseInfo[](markets.length);

        for (uint256 i = 0; i < markets.length; i++) {
            uint64 templateId = market.getMarketTemplateId(markets[i]);
            address auctionToken;
            uint64 startTime;
            uint64 endTime;
            bool finalized;
            (auctionToken, startTime, endTime, finalized) = IBaseAuction(
                markets[i]
            )
                .getBaseInformation();
            TokenInfo memory tokenInfo = getTokenInfo(auctionToken);

            infos[i].market = markets[i];
            infos[i].templateId = templateId;
            infos[i].startTime = startTime;
            infos[i].endTime = endTime;
            infos[i].finalized = finalized;
            infos[i].tokenInfo = tokenInfo;
        }

        return infos;
    }

    // function getCrowdsaleInfo(address _crowdsale) public view returns (CrowdsaleInfo memory) {
    //     IMisoCrowdsale crowdsale = IMisoCrowdsale(_crowdsale);
    //     CrowdsaleInfo memory info;

    //     address auctionToken;
    //     address paymentCurrency;
    //     uint128 totalTokens;
    //     uint128 amountRaised;
    //     uint128 rate;
    //     uint128 goal;
    //     uint64 startTime;
    //     uint64 endTime;
    //     bool finalized;
    //     bool hasPointList;

    //     (
    //         auctionToken,
    //         paymentCurrency,
    //         totalTokens,
    //         startTime,
    //         endTime
    //     ) = crowdsale.getMarketInfo();
    //     (amountRaised, finalized, hasPointList) = crowdsale.getMarketStatus();
    //     (rate, goal) = crowdsale.getMarketPrice();

    //     TokenInfo memory tokenInfo = getTokenInfo(auctionToken);

    //     info.crowdsale = _crowdsale;
    //     info.paymentCurrency = paymentCurrency;
    //     info.amountRaised = amountRaised;
    //     info.totalTokens = totalTokens;
    //     info.startTime = startTime;
    //     info.endTime = endTime;
    //     info.rate = rate;
    //     info.goal = goal;
    //     info.finalized = finalized;
    //     info.hasPointList = hasPointList;
    //     info.tokenInfo = tokenInfo;
    //     info.documents = getDocuments(_crowdsale);

    //     return info;
    // }
}