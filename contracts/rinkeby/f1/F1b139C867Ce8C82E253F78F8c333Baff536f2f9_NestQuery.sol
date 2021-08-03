/**
 *Submitted for verification at Etherscan.io on 2021-08-03
*/

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;
pragma experimental ABIEncoderV2;

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract NestQuery {

	mapping(address=>uint128) avg;
    // mapping(address=>uint256) latestPrice;
    mapping(address=>address) ntokenMapping;

    struct Config {

        // Single query fee（0.0001 ether, DIMI_ETHER). 100
        uint16 singleFee;

        // Double query fee（0.0001 ether, DIMI_ETHER). 100
        uint16 doubleFee;

        // The normal state flag of the call address. 0
        uint8 normalFlag;
    }
    Config _config;
    uint constant DIMI_ETHER = 0.0001 ether;

	constructor () public {
        _config = Config(100, 100, 0);
    }

    // function setPrice(address token, uint256 price) public {
    // 	latestPrice[token] = price;
    // }

    function setAvg(address token, uint128 _avg) public {
        avg[token] = _avg;
    }

    function setNTokenMapping(address token, address ntoken) public {
        ntokenMapping[token] = ntoken;
    }

    function setConfig(uint16 singleFee, uint16 doubleFee, uint8 normalFlag) public {
        _config = Config(singleFee, doubleFee, normalFlag);
    }

    function getConfig() external view returns (Config memory) {
        return _config;
    }

    // function queryPriceAvgVola(address token, 
    // 						   address payback)
    //     public 
    //     payable 
    //     returns (uint256 ethAmount, 
    //     	     uint256 tokenAmount, 
    //     	     uint128 avgPrice, 
    //     	     int128 vola, 
    //     	     uint256 bn) {
    //     require(msg.value >= fee, "value");
    //     if (msg.value > fee) {
    //         payEth(payback, uint256(msg.value)-fee);
    //     }
    //     return (0,0,avg[token],0,0);
    // }

    // function latestPrice(address token) 
    //     public view returns(uint256 ethAmount, 
    //                         uint256 tokenAmount, 
    //                         uint128 avgPrice, 
    //                         int128 vola, 
    //                         uint256 bn) {
    //     return (0,0,avg[token],0,0);
    // }

    function triggeredPriceInfo(address tokenAddress, address paybackAddress) external payable returns (uint blockNumber, uint price, uint avgPrice, uint sigmaSQ) {
        Config memory config = _config;
        _pay(tokenAddress, config.singleFee, paybackAddress);
        return (0,0,avg[tokenAddress],0);
    }

    function triggeredPriceInfo2(address tokenAddress, address paybackAddress) external payable returns (uint blockNumber, uint price, uint avgPrice, uint sigmaSQ, uint ntokenBlockNumber, uint ntokenPrice, uint ntokenAvgPrice, uint ntokenSigmaSQ) {
        address ntoken = ntokenMapping[tokenAddress];
        Config memory config = _config;
        _pay(tokenAddress, config.singleFee, paybackAddress);
        return (0,0,avg[tokenAddress],0,0,0,avg[ntoken],0);
    }

    //--------------

    function triggeredPriceInfo(address tokenAddress) external view returns (
        uint blockNumber, 
        uint price, 
        uint avgPrice, 
        uint sigmaSQ
    ) {
        return (0,0,avg[tokenAddress],0);
    }

    function triggeredPriceInfo2(address tokenAddress) external view returns (
        uint blockNumber, 
        uint price, 
        uint avgPrice, 
        uint sigmaSQ, 
        uint ntokenBlockNumber, 
        uint ntokenPrice, 
        uint ntokenAvgPrice, 
        uint ntokenSigmaSQ
    ) {
        address ntoken = ntokenMapping[tokenAddress];
        return (0,0,avg[tokenAddress],0,0,0,avg[ntoken],0);
    }

    function _pay(address tokenAddress, uint fee, address paybackAddress) private {
        fee = fee * DIMI_ETHER;
        if (msg.value > fee) {
            TransferHelper.safeTransferETH(paybackAddress, msg.value - fee);
        } else {
            require(msg.value == fee, "NestPriceFacade:!fee");
        }
    }

    // 转ETH
    // account:转账目标地址
    // asset:资产数量
    function payEth(address account, uint256 asset) private {
        TransferHelper.safeTransferETH(account, asset);
    }
}