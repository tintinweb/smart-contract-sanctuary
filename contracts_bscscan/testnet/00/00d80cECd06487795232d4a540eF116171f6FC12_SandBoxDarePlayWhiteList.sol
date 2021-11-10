//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.4;


interface IMarketPlaceExtend {
  function canBuy(address token, uint id, uint buyQuantity, address collector, address currency, address maker, address signer) external returns(bool);
  function afterBuy(address token, uint id, uint buyQuantity, address collector, address currency, address maker, address signer) external;
}

contract SandBoxDarePlayWhiteList is IMarketPlaceExtend {
    
    mapping(address => uint) public limits;
    mapping(address => uint) public boughts;

    address public owner;
    address public market;
    address public maker;
    address public token;
    uint public tokenId;

    event UpdateLimit(address maker, address user, uint limit);
    event Bought(address token, uint id, uint buyQuantity, address collector, address currency, address maker_, address signer);

    modifier onlyOwner {
        require(msg.sender == owner, "SandBoxDarePlayWhiteList: you are not owner");
        _;
    }

    modifier noZero(address addr) {
        require(addr != address(0), "SandBoxDarePlayWhiteList: must not be equal zero address");
        _;
    }

    constructor(address owner_) {
        owner = owner_;
    }

    function setToken(address token_, uint id_) public onlyOwner noZero(token_) {
        tokenId = id_;
        token = token_;
    }

    function setMarket(address market_) public onlyOwner noZero(market_) {
        market = market_;
    }

    function setMaker(address maker_) public onlyOwner noZero(maker_) {
        maker = maker_;
    }

    function changeOwner(address newOwner) onlyOwner noZero(newOwner) public {
        owner = newOwner;
    }

    // patch bulk
    function updateLimits(address[] calldata addresses, uint[] calldata totals) public onlyOwner {
        require(addresses.length == totals.length, "SandBoxDarePlayWhiteList: Length not equal");

        for (uint i = 0; i < addresses.length; ++i) {
            require(addresses[i] != address(0), "SandBoxDarePlayWhiteList: address zero");
            limits[addresses[i]] = totals[i];
            emit UpdateLimit(owner, addresses[i], totals[i]);
        }
    }

    function canBuy(address token_, uint id_, uint buyQuantity, 
    address collector, address currency, address maker_, address signer) public override view returns(bool) {
        if (maker_ != maker) {
            return true; // not in genesis sale
        }

        if (token == token_ && tokenId == id_) {
            return boughts[collector] + buyQuantity <= limits[collector];
        }

        return true;
    }

    function afterBuy(address token_, uint id_, uint buyQuantity, 
    address collector, address currency, address maker_, address signer) public override {
        require(msg.sender == market, "SandBoxDarePlayWhiteList: Not come from market");

        if (maker_ != maker) {
            return;
        }
        
        if (token == token_ && tokenId == id_) {
            require(limits[collector] != 0, "SandBoxDarePlayWhiteList: not in whitelist");

            boughts[collector] += buyQuantity;
            emit Bought(token, tokenId, buyQuantity, collector, currency, maker_, signer);
        }
    }
}