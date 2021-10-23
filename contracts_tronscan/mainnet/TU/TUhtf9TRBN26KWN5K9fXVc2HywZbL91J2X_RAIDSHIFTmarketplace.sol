//SourceUnit: RAIDSHIFTmarketplace.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

library SafeMulDiv {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }
}

interface ERC20_SLIM {
    function transfer(address recipient, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

struct Offer {
    uint256 id;
    address issuer;
    uint256 valTOKEN;
    uint256 valSTABLE;
    bool sell;
}

contract RAIDSHIFTmarketplace {
    using SafeMulDiv for uint256;
    address private _owner;
    address private _ownerClaim;
    bool private _paused; // if true: disable offer creation
    address private _TOKEN;
    address private _STABLE;
    uint256 private _minValTOKEN;
    uint256 private _minValSTABLE;
    uint256 private _feesTOKEN;
    uint256 private _feesSTABLE;
    Offer[] private _offers;
    mapping(uint256 => uint256) private _offersIdx;
    uint256 private _nextOfferId;

    event CreateOffer(uint256 offerId, address issuer, uint256 valTOKEN, uint256 valSTABLE, bool sell);
    event RemoveOffer(uint256 offerId);
    event AcceptOffer(uint256 offerId, uint256 newValTOKEN, uint256 newValSTABLE);

    constructor(
        address token,
        address stable,
        uint256 minValTOKEN,
        uint256 minValSTABLE
    ) {
        _owner = msg.sender;
        _paused = false;
        _TOKEN = token;
        _STABLE = stable;
        _minValTOKEN = minValTOKEN;
        _minValSTABLE = minValSTABLE;
    }

    function getOwner() external view returns (address) {
        return _owner;
    }

    function getFeesTOKEN() external view returns (uint256) {
        require(msg.sender == _owner, "NOT ALLOWED");
        return _feesTOKEN;
    }

    function getFeesSTABLE() external view returns (uint256) {
        require(msg.sender == _owner, "NOT ALLOWED");
        return _feesSTABLE;
    }

    function getAddressTOKEN() external view returns (address) {
        return _TOKEN;
    }

    function getAddressSTABLE() external view returns (address) {
        return _STABLE;
    }

    function getMinValTOKEN() external view returns (uint256) {
        return _minValTOKEN;
    }

    function getMinValSTABLE() external view returns (uint256) {
        return _minValSTABLE;
    }

    function getOffersCount() external view returns (uint256) {
        return _offers.length;
    }

    function getOfferById(uint256 offerId)
        external
        view
        returns (
            uint256,
            address,
            uint256,
            uint256,
            bool
        )
    {
        Offer memory offer = _offers[_offersIdx[offerId] - 1];
        return (offer.id, offer.issuer, offer.valTOKEN, offer.valSTABLE, offer.sell);
    }

    function getOffers(uint256 fromIdx, uint256 toIdx)
        external
        view
        returns (
            uint256[] memory,
            address[] memory,
            uint256[] memory,
            uint256[] memory,
            bool[] memory
        )
    {
        require(toIdx >= fromIdx, "INVALID VALUE");
        uint256[] memory id_t;
        address[] memory issuer_t;
        uint256[] memory valTOKEN_t;
        uint256[] memory valSTABLE_t;
        bool[] memory sell_t;
        if (_offers.length == 0) {
            return (id_t, issuer_t, valTOKEN_t, valSTABLE_t, sell_t);
        }
        uint256 tmpIdx = _offers.length - 1;
        if (fromIdx > tmpIdx) {
            return (id_t, issuer_t, valTOKEN_t, valSTABLE_t, sell_t);
        }
        if (toIdx > tmpIdx) {
            toIdx = tmpIdx;
        }
        uint256 range = toIdx - fromIdx;
        id_t = new uint256[](range + 1);
        issuer_t = new address[](range + 1);
        valTOKEN_t = new uint256[](range + 1);
        valSTABLE_t = new uint256[](range + 1);
        sell_t = new bool[](range + 1);
        for (uint256 i = 0; i <= range; i++) {
            tmpIdx = fromIdx + i;
            id_t[i] = _offers[tmpIdx].id;
            issuer_t[i] = _offers[tmpIdx].issuer;
            valTOKEN_t[i] = _offers[tmpIdx].valTOKEN;
            valSTABLE_t[i] = _offers[tmpIdx].valSTABLE;
            sell_t[i] = _offers[tmpIdx].sell;
        }
        return (id_t, issuer_t, valTOKEN_t, valSTABLE_t, sell_t);
    }

    function transferOwnership(address owner) external {
        require(msg.sender == _owner && owner != address(0), "NOT ALLOWED");
        _ownerClaim = owner;
    }

    function claimOwnership() external {
        require(msg.sender == _ownerClaim || msg.sender == _owner, "NOT ALLOWED");
        _ownerClaim = address(0);
        _owner = msg.sender;
    }

    function pause() external {
        require(msg.sender == _owner, "NOT ALLOWED");
        _paused = true;
    }

    function unpause() external {
        require(msg.sender == _owner, "NOT ALLOWED");
        _paused = false;
    }

    function changeMinVal(uint256 minValTOKEN, uint256 minValSTABLE) external {
        require(msg.sender == _owner, "NOT ALLOWED");
        _minValTOKEN = minValTOKEN;
        _minValSTABLE = minValSTABLE;
    }

    function withdrawFees() external {
        require(msg.sender == _owner, "NOT ALLOWED");
        uint256 fs = _feesSTABLE;
        uint256 ft = _feesTOKEN;
        _feesSTABLE = 0;
        _feesTOKEN = 0;
        ERC20_SLIM(_STABLE).transfer(msg.sender, fs);
        ERC20_SLIM(_TOKEN).transfer(msg.sender, ft);
    }

    function createOffer(
        uint256 valTOKEN,
        uint256 valSTABLE,
        bool sell
    ) external returns (uint256) {
        require(_paused == false, "FUNCTION PAUSED");
        require(valSTABLE >= _minValSTABLE && valTOKEN >= _minValTOKEN, "INVALID VALUE");
        _nextOfferId++;
        uint256 offerId = _nextOfferId;
        Offer memory offer;
        offer.issuer = msg.sender;
        offer.id = offerId;
        offer.valTOKEN = valTOKEN;
        offer.valSTABLE = valSTABLE;
        offer.sell = sell;
        _offers.push(offer);
        _offersIdx[offerId] = _offers.length;
        address contr;
        uint256 val;
        if (sell == true) {
            contr = _TOKEN;
            val = valTOKEN;
        } else {
            contr = _STABLE;
            val = valSTABLE;
        }
        emit CreateOffer(offer.id, offer.issuer, offer.valTOKEN, offer.valSTABLE, offer.sell);
        ERC20_SLIM(contr).transferFrom(msg.sender, address(this), val);
        return offerId;
    }

    function removeOffer(uint256 idx) internal {
        uint256 lastIdx = _offers.length - 1;
        uint256 delId = _offers[idx].id;
        _offers[idx] = _offers[lastIdx];
        _offersIdx[_offers[idx].id] = idx + 1;
        _offers.pop();
        _offersIdx[delId] = 0;
    }

    function cancelOffer(uint256 offerId) external {
        uint256 idx = _offersIdx[offerId] - 1;
        address creator = _offers[idx].issuer;
        require(msg.sender == creator || msg.sender == _owner, "NOT ALLOWED");
        address contr;
        uint256 val;
        if (_offers[idx].sell == true) {
            contr = _TOKEN;
            val = _offers[idx].valTOKEN;
        } else {
            contr = _STABLE;
            val = _offers[idx].valSTABLE;
        }
        removeOffer(idx);
        emit RemoveOffer(offerId);
        ERC20_SLIM(contr).transfer(creator, val);
    }

    function acceptOffer(uint256 offerId, uint256 tradeValTOKEN) external {
        uint256 idx = _offersIdx[offerId] - 1;
        uint256 valTOKEN = _offers[idx].valTOKEN;
        uint256 valSTABLE = _offers[idx].valSTABLE;
        require(tradeValTOKEN <= valTOKEN && tradeValTOKEN >= _minValTOKEN, "INVALID VALUE");
        uint256 tradeValSTABLE = tradeValTOKEN.mul(valSTABLE).div(valTOKEN);
        require(tradeValSTABLE >= _minValSTABLE, "INVALID VALUE");
        valTOKEN = valTOKEN - tradeValTOKEN;
        valSTABLE = valSTABLE - tradeValSTABLE;
        address issuer = _offers[idx].issuer;
        bool sell = _offers[idx].sell;
        if (valTOKEN == 0) {
            removeOffer(idx);
        } else {
            require(valTOKEN >= _minValTOKEN && valSTABLE >= _minValSTABLE, "INVALID VALUE");
            _offers[idx].valTOKEN = valTOKEN;
            _offers[idx].valSTABLE = valSTABLE;
        }
        if (sell == true) {
            uint256 fee = tradeValTOKEN.div(1000); // taker fee = 0,1%
            _feesTOKEN += fee;
            ERC20_SLIM(_STABLE).transferFrom(msg.sender, issuer, tradeValSTABLE);
            ERC20_SLIM(_TOKEN).transfer(msg.sender, tradeValTOKEN - fee);
        } else {
            uint256 fee = tradeValSTABLE.div(1000); // taker fee = 0,1%
            _feesSTABLE += fee;
            ERC20_SLIM(_TOKEN).transferFrom(msg.sender, issuer, tradeValTOKEN);
            ERC20_SLIM(_STABLE).transfer(msg.sender, tradeValSTABLE - fee);
        }
        emit AcceptOffer(offerId, valTOKEN, valSTABLE);
    }
}