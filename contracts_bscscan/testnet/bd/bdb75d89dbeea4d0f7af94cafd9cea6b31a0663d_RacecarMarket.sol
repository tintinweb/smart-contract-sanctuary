/**
 *Submitted for verification at BscScan.com on 2021-12-15
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
    RacecarNFT racecar = RacecarNFT(0x2BB4Ee075ac8af270bA24ce996f440B3EEC63F5d);
    IERC20 USDT = IERC20(0xce88973456fBb7B96156f7DBf15300F21A515FE5);
    address _owner;
    address _seller;

    struct RacecarMarketInfo {
        uint256 price;
        uint256 maxAmount;
        uint256 currentAmount;
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
        require(RacecarMarketInfoMap[_racecarType].currentAmount != 0);
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
        RacecarMarketInfoMap[_racecarType].currentAmount--;
    }

    function setRacecarPrice(uint256 _racecarType,uint256 _price,uint256 _maxAmount,string memory _tokenURI) public onlyOwner {
        require(_price != 0);
        require(RacecarMarketInfoMap[_racecarType].price == 0);
        RacecarMarketInfoMap[_racecarType].price = _price * 10 ** 18;
        RacecarMarketInfoMap[_racecarType].currentAmount = _maxAmount;
        RacecarMarketInfoMap[_racecarType].maxAmount = _maxAmount;
        RacecarMarketInfoMap[_racecarType].tokenURI = _tokenURI;
    }
}