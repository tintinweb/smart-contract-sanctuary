/**
 *Submitted for verification at Etherscan.io on 2021-08-08
*/

pragma solidity ^0.8.0;

// ----------------------------------------------------------------------------
// LunarTokenHelper v0.9.0
//
// https://github.com/bokkypoobah/TokenToolz
//
// Deployed to 0x9809Dbeb9e030eb296C7C410758310Dfcb1ef3DD
// 
// Note: _subdivisions and _parentIds not retrieved as LunaToken plots cannot
// currently be subdivided. And stack-too-deep errors.
//
// SPDX-License-Identifier: MIT
//
// Enjoy. And hello, from the past.
//
// (c) BokkyPooBah / Bok Consulting Pty Ltd 2021. The MIT Licence.
// ----------------------------------------------------------------------------

interface ILunarToken {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint);
    
    function numPlots() external view returns (uint);
    function totalOwned() external view returns (uint);
    function totalPurchases() external view returns (uint);
    function initialPrice() external view returns (uint);
    function feePercentage() external view returns (uint8);
    function tradingEnabled() external view returns (bool);
    function subdivisionEnabled() external view returns (bool);
    function maxSubdivisions() external view returns (uint8);
    
    function plots(uint tokenId) external view returns (address owner, uint price, bool forSale, string memory metadata, bool disabled, uint8 subdivision, uint parentId);
}


contract LunarTokenHelper {
    ILunarToken public constant lunarToken = ILunarToken(0x43fb95c7afA1Ac1E721F33C695b2A0A94C7ddAb2);
    
    function tokenInfo() external view returns(string memory _symbol, string memory _name, uint[] memory _data) {
        _symbol = lunarToken.symbol();
        _name = lunarToken.name();
        _data = new uint[](9);
        _data[0] = lunarToken.totalSupply();
        _data[1] = lunarToken.numPlots();
        _data[2] = lunarToken.totalOwned();
        _data[3] = lunarToken.totalPurchases();
        _data[4] = lunarToken.initialPrice();
        _data[5] = lunarToken.feePercentage();
        _data[6] = lunarToken.tradingEnabled() ? 1 : 0;
        _data[7] = lunarToken.subdivisionEnabled() ? 1 : 0;
        _data[8] = lunarToken.maxSubdivisions();
    }

    function plots(uint from, uint to) external view returns(uint[] memory _tokenIds, address[] memory _owners, uint[] memory _prices, bool[] memory _forSales, string[] memory _metadatas, bool[] memory _disableds/*, uint8[] memory _subdivisions, uint[] memory _parentIds*/) {
        require(from < to && to <= lunarToken.totalSupply());
        uint length = to - from;
        _tokenIds = new uint[](length);
        _owners = new address[](length);
        _prices = new uint[](length);
        _forSales = new bool[](length);
        _metadatas = new string[](length);
        _disableds = new bool[](length);
        // _subdivisions = new uint8[](length);
        // _parentIds = new uint[](length);
        
        uint i = 0;
        for (uint index = from; index < to; index++) {
            _tokenIds[i] = index;
            (_owners[i], _prices[i], _forSales[i], _metadatas[i], _disableds[i], /*_subdivisions[i]*/, /*_parentIds[i]*/) = lunarToken.plots(index);
            i++;
        }
    }
}