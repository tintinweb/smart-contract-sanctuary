/**
 *Submitted for verification at Etherscan.io on 2021-03-19
*/

// SPDX-License-Identifier: NONE

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;



// Part: IDocument

interface IDocument {
    function getDocument(bytes32 _name) external view returns (string memory, bytes32, uint256);
    function getAllDocuments() external view returns (bytes32[] memory);
}

// Part: IERC20

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);

    // transfer and transferFrom intentionally missing, replaced with safeTransfers
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

// Part: IMisoMarketFactory

interface IMisoMarketFactory {
    function getMarketTemplateId(address _auction) external view returns(uint64);
    function getMarkets() external view returns(address[] memory);
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
        address addr;
        uint256 decimals;
        string name;
        string symbol;
    }

    function getTokensInfo(address[] memory addresses) public view returns (TokenInfo[] memory)
    {
        TokenInfo[] memory infos = new TokenInfo[](addresses.length);

        for (uint256 i = 0; i < addresses.length; i++) {
            infos[i] = getTokenInfo(addresses[i]);
        }

        return infos;
    }

    function getTokenInfo(address _address) public view returns (TokenInfo memory) {
        TokenInfo memory info;
        IERC20 token = IERC20(_address);

        info.addr = _address;
        info.name = token.name();
        info.symbol = token.symbol();
        // info.decimals = token.decimals();

        return info;
    }
}

// File: MISOHelper.sol

contract MISOHelper is TokenHelper, DocumentHepler {
    IMisoMarketFactory public market;
    IMisoTokenFactory public tokenFactory;
    address public launcher;
    address public farmFactory;

    struct MarketBaseInfo {
        address addr;
        uint64 templateId;
        uint64 startTime;
        uint64 endTime;
        bool finalized;
        TokenInfo tokenInfo;
    }

    function setContracts( address _tokenFactory, address _market, address _launcher, address _farmFactory) public {
        if (_market != address(0)) {
            market = IMisoMarketFactory(_market);
        }
        if (_tokenFactory != address(0)) {
            tokenFactory = IMisoTokenFactory(_tokenFactory);
        }
        if (_launcher != address(0)) {
            launcher = _launcher;
        }
        if (_farmFactory != address(0)) {
            farmFactory = _farmFactory;
        }
    }
}