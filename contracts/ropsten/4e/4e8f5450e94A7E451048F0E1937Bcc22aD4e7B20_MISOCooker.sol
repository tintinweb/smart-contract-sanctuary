/**
 *Submitted for verification at Etherscan.io on 2022-01-10
*/

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function approve(address spender, uint256 amount) external;
    function transfer(address spender, uint256 amount) external;
    function balanceOf(address user) external view returns (uint256);
}

interface IListFactory {
    function deployPointList(
        address listOwner,
        address[] calldata accounts,
        uint256[] calldata amounts
    ) external payable returns (address pointList);
}

interface IMisoTokenFactory {
    function createToken(
        uint256 templateId,
        address payable integratorFeeAccount,
        bytes calldata data
    ) external payable returns (address token);
}

interface IMisoMarket {
    function createMarket(
        uint256 templateId,
        address token,
        uint256 tokenSupply,
        address payable integratorFeeAccount,
        bytes calldata data
    ) external payable returns (address newMarket);
}

interface IPostAuctionLauncher {
    function createLauncher(
        uint256 templateId,
        address token,
        uint256 tokenSupply,
        address payable integratorFeeAccount,
        bytes calldata data
    ) external payable;
}

interface IBatchAuction {
    function getBatchAuctionInitData(
        address funder,
        address token,
        uint256 totalTokens,
        uint256 startTime,
        uint256 endTime,
        address paymentCurrency,
        uint256 minimumCommitmentAmount,
        address admin,
        address pointList,
        address payable wallet
    ) external pure returns (bytes memory);
}

contract MISOCooker {

    IMisoTokenFactory public immutable tokenFactory;
    IListFactory public immutable listFactory;
    IMisoMarket public immutable misoMarket;
    IPostAuctionLauncher public immutable postAuctionLauncher;

    struct BatchAuctionInitData {
        address funder;
        address token;
        uint256 totalTokens;
        uint256 startTime;
        uint256 endTime;
        address paymentCurrency;
        uint256 minimumCommitmentAmount;
        address admin;
        address pointList;
        address wallet;
        uint256 extra;
    }

    struct CrowdsaleAuctionInitData {
        address funder;
        address token;
        address paymentCurrency;
        uint256 totalTokens;
        uint256 startTime;
        uint256 endTime;
        uint256 rate;
        uint256 goal;
        address admin;
        address pointList;
        address wallet;
    }

    struct DutchAuctionInitData {
        address funder;
        address token;
        uint256 totalTokens;
        uint256 startTime;
        uint256 endTime;
        address paymentCurrency;
        uint256 startPrice;
        uint256 minimumPrice;
        address admin;
        address pointList;
        address wallet;
    }

    constructor(
        IMisoTokenFactory _tokenFactory,
        IListFactory _listFactory,
        IMisoMarket _misoMarket,
        IPostAuctionLauncher _postAuctionLauncher
    ) public {
        tokenFactory = _tokenFactory;
        listFactory = _listFactory;
        misoMarket = _misoMarket;
        postAuctionLauncher = _postAuctionLauncher;
    }

    uint8 internal constant CREATE_TOKEN = 0;
    uint8 internal constant DEPLOY_POINT_LIST = 1;
    uint8 internal constant CREATE_MARKET_DUTCH = 2;
    uint8 internal constant CREATE_MARKET_CROWDSALE = 3;
    uint8 internal constant CREATE_MARKET_BATCH = 4;
    uint8 internal constant LIQUIDITY_LAUNCHER = 5;
    
    function cook(
        uint8[] memory _actions,
        uint256[] memory _values,
        bytes[] memory _datas
    ) external {
        
        address token;
        address pointList;
        address market;
        
        for(uint256 i = 0; i < _actions.length; i++) {
            
            uint8 _action = _actions[i];
            uint256 _value = _values[i];
            bytes memory _data = _datas[i];
            
            if (_action == CREATE_TOKEN) {
                
                (uint256 templateId, address payable integratorFeeAccount, bytes memory data) = abi.decode(_data, (uint256, address, bytes));

                token = tokenFactory.createToken{value: _value}(templateId, integratorFeeAccount, data);
                
                IERC20(token).approve(address(misoMarket), uint256(-1));

            } else if (_action == DEPLOY_POINT_LIST) {

                (address listOwner, address[] memory accounts, uint256[] memory amounts) = abi.decode(_data, (address, address[], uint256[]));
                
                pointList = listFactory.deployPointList{value: _value}(listOwner, accounts, amounts);

            } else if (_action == CREATE_MARKET_DUTCH) {
                
                (uint256 templateId,, uint256 tokenSupply, address payable integratorFeeAccount, bytes memory _auctionData) = abi.decode(_data, (uint256, address, uint256, address, bytes));
                
                (DutchAuctionInitData memory auctionData) = abi.decode(_auctionData, (DutchAuctionInitData));

                auctionData.token = token != address(0) ? token : auctionData.token;
                auctionData.pointList = pointList != address(0) ? pointList : auctionData.pointList;

                bytes memory data = abi.encode(
                    auctionData.funder,
                    auctionData.token,
                    auctionData.totalTokens,
                    auctionData.startTime,
                    auctionData.endTime,
                    auctionData.paymentCurrency,
                    auctionData.startPrice,
                    auctionData.minimumPrice,
                    auctionData.admin,
                    auctionData.pointList,
                    auctionData.wallet
                );

                market = misoMarket.createMarket{value: _value}(templateId, auctionData.token, tokenSupply, integratorFeeAccount, data);

            } else if (_action == CREATE_MARKET_CROWDSALE) {

                (uint256 templateId,, uint256 tokenSupply, address payable integratorFeeAccount, bytes memory _auctionData) = abi.decode(_data, (uint256, address, uint256, address, bytes));
                
                (CrowdsaleAuctionInitData memory auctionData) = abi.decode(_auctionData, (CrowdsaleAuctionInitData));

                auctionData.token = token != address(0) ? token : auctionData.token;
                auctionData.pointList = pointList != address(0) ? pointList : auctionData.pointList;

                bytes memory data = abi.encode(
                    auctionData.funder,
                    auctionData.token,
                    auctionData.paymentCurrency,
                    auctionData.totalTokens,
                    auctionData.startTime,
                    auctionData.endTime,
                    auctionData.rate,
                    auctionData.goal,
                    auctionData.admin,
                    auctionData.pointList,
                    auctionData.wallet
                );

                market = misoMarket.createMarket{value: _value}(templateId, auctionData.token, tokenSupply, integratorFeeAccount, data);

            } else if (_action == CREATE_MARKET_BATCH) {

                (uint256 templateId,, uint256 tokenSupply, address payable integratorFeeAccount, bytes memory _auctionData) = abi.decode(_data, (uint256, address, uint256, address, bytes));
                
                (BatchAuctionInitData memory auctionData) = abi.decode(_auctionData, (BatchAuctionInitData));

                auctionData.token = token != address(0) ? token : auctionData.token;
                auctionData.pointList = pointList != address(0) ? pointList : auctionData.pointList;

                bytes memory data = abi.encode(
                    auctionData.funder,
                    auctionData.token,
                    auctionData.totalTokens,
                    auctionData.startTime,
                    auctionData.endTime,
                    auctionData.paymentCurrency,
                    auctionData.minimumCommitmentAmount,
                    auctionData.admin,
                    auctionData.pointList,
                    auctionData.wallet,
                    auctionData.extra
                );

                market = misoMarket.createMarket{value: _value}(templateId, auctionData.token, tokenSupply, integratorFeeAccount, data);

            } else if (_action == LIQUIDITY_LAUNCHER) {

                (
                    uint256 templateId,
                    address _token,
                    uint256 tokenSupply,
                    address payable integratorFeeAccount,
                    bytes memory data
                ) = abi.decode(_data, (uint256, address, uint256, address, bytes));

                if (_token != address(0)) token = _token;

                postAuctionLauncher.createLauncher{value: _value}(templateId, token, tokenSupply, integratorFeeAccount, data);

            }

        }

        if (token != address(0)) { // don't need to use safeTransfer as we are dealing with known tokens
            uint256 balance = IERC20(token).balanceOf(address(this));
            if (balance > 0) {
                IERC20(token).transfer(msg.sender, balance);
            }
        }
    }

}