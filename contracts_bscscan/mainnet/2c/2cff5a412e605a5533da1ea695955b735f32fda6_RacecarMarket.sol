/**
 *Submitted for verification at BscScan.com on 2021-12-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

interface RacecarNFT {
    function safeMint(address to, uint256 tokenId, string memory uri, uint256 racecarType) external;
}

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract RacecarMarket {
    RacecarNFT racecar = RacecarNFT(0xd624573D93DDd22897074F2285Ea99e4ee849426);
    IERC20 USDT = IERC20(0x55d398326f99059fF775485246999027B3197955);
    address _owner;
    address _seller;

    struct RacecarMarketInfo {
        uint256 price;
        uint256 maxAmount;
        uint256 sellAmount;
        string tokenURI;
    }

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor(address seller) {
        _owner = msg.sender;
        _seller = seller;
    }

    mapping (address => address) parent;
    mapping (uint256=>RacecarMarketInfo) public RacecarMarketInfoMap;

    function buyRacecar(uint256 _racecarType,uint256 _tokenId,address _parent) public {
        require(RacecarMarketInfoMap[_racecarType].sellAmount < RacecarMarketInfoMap[_racecarType].maxAmount);
        if(parent[msg.sender] == address(0)) {
            parent[msg.sender] = _parent;
        }
        if(parent[msg.sender] == address(0)) {
            USDT.transferFrom(msg.sender, _seller, RacecarMarketInfoMap[_racecarType].price);
        } else {
            uint256 sellerAmount = RacecarMarketInfoMap[_racecarType].price * 90 / 100;
            uint256 parentAmount = RacecarMarketInfoMap[_racecarType].price - sellerAmount;
            USDT.transferFrom(msg.sender, _seller, sellerAmount);
            USDT.transferFrom(msg.sender, parent[msg.sender], parentAmount);
        }
        racecar.safeMint(msg.sender, _tokenId, RacecarMarketInfoMap[_racecarType].tokenURI, _racecarType);
        RacecarMarketInfoMap[_racecarType].sellAmount++;
    }

    function setRacecarPrice(uint256 _racecarType,uint256 _price,uint256 _maxAmount,string memory _tokenURI) public onlyOwner {
        require(_price != 0);
        require(RacecarMarketInfoMap[_racecarType].price == 0);
        RacecarMarketInfoMap[_racecarType].price = _price * 10 ** 18;
        RacecarMarketInfoMap[_racecarType].maxAmount = _maxAmount;
        RacecarMarketInfoMap[_racecarType].tokenURI = _tokenURI;
    }

    function setMaxAmount(uint256 _racecarType,uint256 _maxAmount) public onlyOwner {
        RacecarMarketInfo storage info = RacecarMarketInfoMap[_racecarType];
        require(info.sellAmount <= _maxAmount);
        info.maxAmount = _maxAmount;
    }
}