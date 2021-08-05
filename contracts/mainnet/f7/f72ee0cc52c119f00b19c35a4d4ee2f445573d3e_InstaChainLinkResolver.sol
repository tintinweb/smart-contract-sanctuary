/**
 *Submitted for verification at Etherscan.io on 2020-08-16
*/

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

interface ChainLinkInterface {
    function latestAnswer() external view returns (int256);
    function decimals() external view returns (uint256);
}

interface ConnectorsInterface {
  function chief(address) external view returns (bool);
}

interface IndexInterface {
  function master() external view returns (address);
}

contract Basic {
    address public constant connectors = 0xD6A602C01a023B98Ecfb29Df02FBA380d3B21E0c;
    address public constant instaIndex = 0x2971AdFa57b20E5a416aE5a708A8655A9c74f723;
    uint public version = 1;

    modifier isChief {
        require(
        ConnectorsInterface(connectors).chief(msg.sender) ||
        IndexInterface(instaIndex).master() == msg.sender, "not-Chief");
        _;
    }

    event LogAddChainLinkMapping(
        string tokenSymbol,
        address chainlinkFeed
    );

    event LogRemoveChainLinkMapping(
        string tokenSymbol,
        address chainlinkFeed
    );

    mapping (string => address) public chainLinkMapping;

    function _addChainLinkMapping(
        string memory token,
        address chainlinkFeed
    ) internal {
        require(bytes(token).length > 0, "token-not-vaild");
        require(chainlinkFeed != address(0), "chainlinkFeed-not-vaild");
        require(chainLinkMapping[token] == address(0), "chainlinkFeed-already-added");

        chainLinkMapping[token] = chainlinkFeed;
        emit LogAddChainLinkMapping(token, chainlinkFeed);
    }

    function _removeChainLinkMapping(string memory token) internal {
        require(bytes(token).length > 0, "token-not-vaild");
        require(chainLinkMapping[token] != address(0), "chainlinkFeed-not-added-yet");

        emit LogRemoveChainLinkMapping(token, chainLinkMapping[token]);
        delete chainLinkMapping[token];
    }

    function addChainLinkMapping(
        string[] memory tokens,
        address[] memory chainlinkFeeds
    ) public isChief {
        require(tokens.length == chainlinkFeeds.length, "lenght-not-same");
        for (uint i = 0; i < tokens.length; i++) {
            _addChainLinkMapping(tokens[i], chainlinkFeeds[i]);
        }
    }

    function removeChainLinkMapping(string[] memory tokens) public isChief {
        for (uint i = 0; i < tokens.length; i++) {
            _removeChainLinkMapping(tokens[i]);
        }
    }
}

contract Resolver is Basic {
    struct PriceData {
        uint price;
        uint decimals;
    }
    function getPrice(string[] memory tokens)
    public
    view
    returns (
        PriceData memory ethPriceInUsd,
        PriceData memory btcPriceInUsd,
        PriceData[] memory tokensPriceInETH
    ) {
        tokensPriceInETH = new PriceData[](tokens.length);
        for (uint i = 0; i < tokens.length; i++) {
            ChainLinkInterface feedContract = ChainLinkInterface(chainLinkMapping[tokens[i]]);
            if (address(feedContract) != address(0)) {
                tokensPriceInETH[i] = PriceData({
                    price: uint(feedContract.latestAnswer()),
                    decimals: feedContract.decimals()
                });
            } else {
                tokensPriceInETH[i] = PriceData({
                    price: 0,
                    decimals: 0
                });
            }
        }
        ChainLinkInterface ethFeed = ChainLinkInterface(chainLinkMapping["ETH"]);
        ChainLinkInterface btcFeed = ChainLinkInterface(chainLinkMapping["BTC"]);
        ethPriceInUsd = PriceData({
            price: uint(ethFeed.latestAnswer()),
            decimals: ethFeed.decimals()
        });

        btcPriceInUsd = PriceData({
            price: uint(btcFeed.latestAnswer()),
            decimals: btcFeed.decimals()
        });
    }

    function getGasPrice() public view returns (uint gasPrice) {
        gasPrice = uint(ChainLinkInterface(chainLinkMapping["gasFast"]).latestAnswer());
    }
}

contract InstaChainLinkResolver is Resolver {
    constructor (string[] memory tokens, address[] memory chainlinkFeeds) public {
        require(tokens.length == chainlinkFeeds.length, "Lenght-not-same");
        for (uint i = 0; i < tokens.length; i++) {
            _addChainLinkMapping(tokens[i], chainlinkFeeds[i]);
        }
    }

    string public constant name = "ChainLink-Resolver-v1";
}