/**
 *Submitted for verification at Etherscan.io on 2021-03-17
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
    // IMisoLauncher public launcher;
    
    function setContracts(address _market, address _tokenFactory) public {
        market = IMisoMarket(_market);
        tokenFactory = IMisoTokenFactory(_tokenFactory);
    }

    function getData() public view returns(address) {
        return msg.sender;
    }
}