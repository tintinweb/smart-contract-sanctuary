// Submitted for verification at BscScan.com on 2021-10-21

/*
Public contract (Version 2.0) for secure swap between ZEEX (token 0xb9c21a1A716Ee781B0Ab282F3AEdDB3382d7aAdc) and:
USDT(BEP20) or Native BNB.
*
AirDros claim tool and Partner address registration
*
Automatic tranfer Partners comission
*
Used by the Artzeex website and tools. 
*
The Artzeex Ecosystem is a project focused on revolutionizing the art world by adding value to the world of NFT's 
and the metaverse. For more information visit the link bellow:
https://artzeex.com/

200,000,000 Total Supply

Name: Artzeex
Symbol: ZEEX
Decimals: 6
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./AggregatorV3Interface.sol";
import "./IBEP20.sol";
import "./Ownable.sol";

contract SaleAirDrop is Ownable{
    
    AggregatorV3Interface internal priceFeed;
    IBEP20  internal _ZEEX;
    address internal _ownerZEEX;
    IBEP20  internal _USDT;
    uint256 _valueZEEX     = 33 * 10 ** 16;  // 1ZEEX = 0,33USDT 
    int   _percentPriceBNB = 95; // 0-100% BNB/USD
    uint8 _tolerancePercent = 3;
    uint256 _minimalBNBAmount  = 1 * 10 ** 17; //0.1 BNB
    uint256 _minimalUSDTAmount = 30 * 10 ** 18; //30 USDT

    uint256 _lastIdPartner = 10100;
    uint8 _standartRebate = 35;
    uint8 _standartRebateBuyer = 0;
    uint8 _standartRebateAnoter = 5;
    uint8 _standartRebateAirDrop = 100;

    uint256 internal _airDropLimit = 1000000 * 10 ** 6;
    uint256 internal _airDropUsed  = 0;
    bool internal _airDropON = true;
    uint256 internal _feeAirDrop = 400000000000000; //0.0004 BNB
    uint256 internal _amountZEEXEachAirDrop = 10 * 10 ** 6; //10zeex

    mapping (address => bool) internal _airDropInWallet;
    mapping (uint256 => uint256) internal _rebateAirDropPartner;
                                   
    mapping (address => uint256) internal _isPartner;
    struct Partner {
        address wallet;
        uint8 rebate;
        uint8 rebateBuyer;
        uint8 rebateAnoter;
        uint8 rebateAirDrop;
        bool customRebate;
    }
    mapping (uint256 => Partner) internal _idPartner;

    struct Sale {
        address buyer;
        uint256 amoutZeex;
        uint8 anoterToken;
        uint256 amountAnoter;
        uint256 idPartner;
        address walletPartner;
        uint256 rebatePartner;
        uint256 rebateBuyer;
        uint256 rebateAnoter;
    }

    struct AirDropDelivery {
        address receiver;
        uint256 idPartner;
        address walletPartner;
        uint256 amoutReceiver;
        uint256 amountPartner;
    }

    struct Rebate {
        uint256 amoutPartner;
        uint256 amountBuyer;
        uint256 amountAnoter;
    }

    struct RoundDataBNB {
        uint80 roundID;
        int price;
        uint startedAt;
        uint timeStamp;
        uint80 answeredInRound;
    }
    
    bool internal _rebateON = true;

    event SaleEvent (address indexed wallet, Sale sale);
    event NewPartnerEvent (uint256 indexed id, Partner partner);
    event UpdatePartnerEvent (uint256 indexed id, Partner partner);
    event ClaimAirDropEvent (address indexed wallet, uint256 amout, address partnerAddr, uint256 amountPartner);

    /**
    * Network: BSC MainNet
    * Aggregator: BNB/USD
    * Address: 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE
    */
    constructor() {
         priceFeed = AggregatorV3Interface(0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526);
        _ZEEX      = IBEP20(0xa8f8C76CE1528a20e6E837B9d3f53FDFEe0dCD32); 
        _ownerZEEX = 0x8A3DA0982DF04988ad04536D92FeFe88701619Bc;
        _USDT      = IBEP20(0xEdA7631884Ee51b4cAa85c4EEed7b0926954d180);
    }

    function _newPartner(address wallet, uint8 rebate, uint8 rebateBuyer, uint8 rebateAnoter, uint8 rebateAirDrop , bool customRebate) internal returns (bool) {
        if (_isPartner[wallet] != 0) {
            return false;
        }
        _lastIdPartner += 1;
        _isPartner[wallet] = _lastIdPartner;
        Partner memory _partner;
        _partner.wallet            = wallet; 
        _partner.rebate            = rebate;  //0 para não ter rebates
        _partner.rebateBuyer       = rebateBuyer;
        _partner.rebateAnoter      = rebateAnoter;
        _partner.rebateAirDrop     = rebateAirDrop;
        _partner.customRebate      = customRebate;
        _idPartner[_lastIdPartner] = _partner;
        emit NewPartnerEvent(_lastIdPartner, _partner);
        return true;
    }

    function _getLatestRoundBNB() internal view returns (RoundDataBNB memory) {
        (
            uint80 roundID, 
            int price,
            uint startedAt,
            uint timeStamp,
            uint80 answeredInRound
        ) = priceFeed.latestRoundData();
        RoundDataBNB memory data;
        data.roundID         = roundID;
        data.price           = price;
        data.startedAt       = startedAt;
        data.timeStamp       = timeStamp;
        data.answeredInRound = answeredInRound;
        return data;
    }

    function _getLatestPrice() internal view returns (int) {
        return (_getLatestRoundBNB().price * _percentPriceBNB) / 100;
    }

    function getLatestPriceBNBAdjust() external view returns (int) {
        return (_getLatestRoundBNB().price * _percentPriceBNB) / 100;
    }
    
    function _verifySplitSale(uint256 id, uint256 amount) internal view returns(uint256) {
        uint8 customPercent   = _idPartner[id].rebateAnoter;
        uint8 standartPercent = _standartRebateAnoter;
        uint256 amountRebate = 0;
        if(_rebateON && _idPartner[id].wallet != address(0) && _idPartner[id].customRebate && customPercent > 0) {
            amountRebate = (amount * customPercent) / 100;
        }
        if(_rebateON && _idPartner[id].wallet != address(0) && _idPartner[id].customRebate == false && standartPercent > 0) {
            amountRebate = (amount * standartPercent) / 100;
        }
        return amountRebate;
    }

    function _trySendRebate(uint256 id, uint256 amount, address buyer) internal returns(Rebate memory) {
        Rebate memory rebate;
        rebate.amoutPartner = 0; 
        rebate.amountBuyer = 0;
        if (_rebateON == false) {
            return rebate;
        }   
        if(_idPartner[id].wallet == address(0)) {
            return rebate;
        }
        if (_idPartner[id].customRebate == false) {
            rebate.amoutPartner = (amount * _standartRebate) / 100;
            rebate.amountBuyer  = (amount * _standartRebateBuyer) / 100; 
        } else {
            rebate.amoutPartner  = (amount * _idPartner[id].rebate) / 100;
            rebate.amountBuyer   = (amount * _idPartner[id].rebateBuyer) / 100; 
        }
        if(rebate.amoutPartner > 0) {
            _safeTransferFrom(_ZEEX, _ownerZEEX, _idPartner[id].wallet, rebate.amoutPartner);
        }
        if(rebate.amountBuyer > 0) {
            _safeTransferFrom(_ZEEX, _ownerZEEX, buyer, rebate.amountBuyer);
        }
        return rebate;
    }

    function getLatestRoundBNB() external view returns (RoundDataBNB memory) {   //BNB in usd
        return _getLatestRoundBNB(); 
    }

    function buyWithBNB(uint256 idRebate, uint256 nZeex) external payable {
        require(msg.value >= _minimalBNBAmount, "need more BNB");
        uint256 amountBNB = msg.value;
        uint256 _ValueBNBinUSD = uint256(_getLatestPrice());
        uint256 _valueZEEXinBNB = (_valueZEEX * 10 ** 8) / _ValueBNBinUSD;
        uint256 _amountZEEX = (amountBNB * 10 ** 6) / _valueZEEXinBNB;
        
        if (nZeex > 0) {
            uint8 multTolerance = 100 - _tolerancePercent;
            if ( (nZeex * multTolerance) / 100 <= _amountZEEX) {
                _amountZEEX = nZeex;
            }
        }

        require(
            _ZEEX.allowance(_ownerZEEX, address(this)) >= _amountZEEX,  
            "ZEEX allowance too low"
        );
        address payable ownerZ = payable(_ownerZEEX);
        
        uint256 amountBNBtoPartner = _verifySplitSale(idRebate, amountBNB);
        amountBNB = amountBNB - amountBNBtoPartner;
        ownerZ.transfer(amountBNB);
        if (amountBNBtoPartner > 0) {
            address payable partnerWallet = payable(_idPartner[idRebate].wallet);
            partnerWallet.transfer(amountBNBtoPartner);
        }

        _safeTransferFrom(_ZEEX, _ownerZEEX, msg.sender, _amountZEEX);
        Rebate memory rebate = _trySendRebate(idRebate, _amountZEEX, msg.sender);
        Sale memory sale;
        sale.buyer = msg.sender;
        sale.amoutZeex = _amountZEEX;
        sale.anoterToken = 2; //1USDT - 2BNB
        sale.amountAnoter = msg.value;
        sale.idPartner = idRebate;
        sale.walletPartner = _idPartner[idRebate].wallet;
        sale.rebateBuyer = rebate.amountBuyer;
        sale.rebatePartner = rebate.amoutPartner;  
        sale.rebateAnoter = amountBNBtoPartner; 
        emit SaleEvent(msg.sender, sale);
    }

    function swap(uint256 amountUSDT, uint256 idRebate) public {
        require(amountUSDT >= _minimalUSDTAmount, "Need more USDT");
        uint256 _amountZEEX = (amountUSDT * 10 ** 6) / _valueZEEX;
        require(
            _ZEEX.allowance(_ownerZEEX, address(this)) >= _amountZEEX,  
            "ZEEX allowance too low"
        );
        require(
            _USDT.allowance(msg.sender, address(this)) >= amountUSDT,
            "USDT allowance too low"
        );

        uint256 amountUSDTtoPartner = _verifySplitSale(idRebate, amountUSDT); 
        amountUSDT = amountUSDT - amountUSDTtoPartner;
        _safeTransferFrom(_USDT, msg.sender, _ownerZEEX, amountUSDT);
        if (amountUSDTtoPartner > 0) {
            _safeTransferFrom(_USDT, msg.sender, _idPartner[idRebate].wallet, amountUSDTtoPartner);
        }
        _safeTransferFrom(_ZEEX, _ownerZEEX, msg.sender, _amountZEEX);
        Rebate memory rebate = _trySendRebate(idRebate, _amountZEEX, msg.sender);
        Sale memory sale;
        sale.buyer = msg.sender;
        sale.amoutZeex = _amountZEEX;
        sale.anoterToken = 1; //1USDT - 2BNB
        sale.amountAnoter = amountUSDT;
        sale.idPartner = idRebate;
        sale.walletPartner = _idPartner[idRebate].wallet;
        sale.rebateBuyer = rebate.amountBuyer;
        sale.rebatePartner = rebate.amoutPartner;  
        sale.rebateAnoter = amountUSDTtoPartner; 
        emit SaleEvent(msg.sender, sale);
    }

    function _safeTransferFrom (
        IBEP20 token,
        address sender,
        address recipient,
        uint amount
    ) private {
        bool sent = token.transferFrom(sender, recipient, amount);
        require(sent, "Token transfer failed");
    }

    function setValueZEEX(uint256 valueZEEX) external onlyOwner {
        _valueZEEX = valueZEEX;  
    }

    function setOwnerZEEX(address ownerZEEX) external onlyOwner {
        _ownerZEEX = ownerZEEX;  
    }

    function setMinimalBNBAmount(uint256 minimal) external onlyOwner {
        _minimalBNBAmount = minimal;  
    }

    function setMinimalUSDTAmount(uint256 minimal) external onlyOwner {
        _minimalUSDTAmount = minimal;  
    }

    function setPercentPriceBNB(int percent) external onlyOwner {
        _percentPriceBNB = percent;  
    }

    function setStandartRebate(uint8 rebateZEEX, uint8 rebateBuyerZEEX, uint8 rebateUSDTorBNB, uint8 rebateAirDrop) external onlyOwner {
        _standartRebate        = rebateZEEX;  
        _standartRebateBuyer   = rebateBuyerZEEX;  
        _standartRebateAnoter  = rebateUSDTorBNB;
        _standartRebateAirDrop = rebateAirDrop;
    }

    function getStandartRebate() external view returns (uint8, uint8, uint8,uint8) {
       return(_standartRebate, _standartRebateBuyer, _standartRebateAnoter, _standartRebateAirDrop);
    }

    function getParamsPrice() external view returns (address, uint256, int, uint256, uint256) {
        return (_ownerZEEX, _valueZEEX, _percentPriceBNB, _minimalBNBAmount, _minimalUSDTAmount); 
    }

    function signPartner() external {
        require(_isPartner[msg.sender] == 0, "Already sign");
        _newPartner(msg.sender, 0, 0, 0, 0, false);
    }

    function newPartner(address wallet, uint8 rebate, uint8 rebateBuyer, uint8 rebateUSDTorBNB, uint8 rebateAirDrop, bool customRebate) external onlyOwner returns (bool) {
        require(_isPartner[wallet] == 0, "Partner already exist");
        return _newPartner(wallet, rebate, rebateBuyer, rebateUSDTorBNB, rebateAirDrop, customRebate);
    }

    function updatePartner(uint256 id, uint8 rebate, uint8 rebateBuyer, uint8 rebateAnoter, uint8 rebateAirDrop, bool customRebate) external onlyOwner {
        require(_idPartner[id].wallet != address(0), "ID not found");
        _idPartner[id].rebate = rebate;
        _idPartner[id].rebateBuyer = rebateBuyer;
        _idPartner[id].rebateAnoter = rebateAnoter;
        _idPartner[id].rebateAirDrop = rebateAirDrop;
        _idPartner[id].customRebate = customRebate;
        emit UpdatePartnerEvent(id, _idPartner[id]);
    }

    function setRebateON(bool rebateON) external onlyOwner {
        _rebateON = rebateON;
    }

    function getRebateON() external view returns (bool) {
        return (_rebateON);
    }

    function getPartner(uint256 id) external view returns (address, uint8, uint8, uint8, uint8, bool) {
        return (_idPartner[id].wallet, _idPartner[id].rebate, _idPartner[id].rebateBuyer, _idPartner[id].rebateAnoter, _idPartner[id].rebateAirDrop, _idPartner[id].customRebate);
    }

    function getPartnerWithWallet(address wallet) external view returns (uint256, uint8, uint8, uint8, uint8, bool) {
        uint256 id = _isPartner[wallet]; 
        return (id, _idPartner[id].rebate, _idPartner[id].rebateBuyer, _idPartner[id].rebateAnoter, _idPartner[id].rebateAirDrop, _idPartner[id].customRebate);
    }

    function claimAirDrop(uint256 id) public payable {
        require(msg.value >= _feeAirDrop, "More BNB required");
        require(_airDropInWallet[msg.sender] == false, "User already claim AirDrop");
        require(_airDropON, "AirDrop OFF");
        uint256 rebateAirDrop = 0; 
        if (_idPartner[id].wallet != address(0) && _rebateON) {
             if (_idPartner[id].customRebate == false) {
                rebateAirDrop = (_amountZEEXEachAirDrop * _standartRebateAirDrop) / 100;
            } else {
                rebateAirDrop = (_amountZEEXEachAirDrop * _idPartner[id].rebateAirDrop) / 100;
            }
        } 
        uint256 tempAirDropUsed = _airDropUsed + _amountZEEXEachAirDrop + rebateAirDrop;
        require( tempAirDropUsed <= _airDropLimit, "Depleted AirDrop stock");

        _airDropUsed = tempAirDropUsed;
        _airDropInWallet[msg.sender] = true;
        address payable ownerZ = payable(_ownerZEEX);
        ownerZ.transfer(msg.value);
        _safeTransferFrom(_ZEEX, _ownerZEEX, msg.sender, _amountZEEXEachAirDrop);
        if (rebateAirDrop > 0) {
            _safeTransferFrom(_ZEEX, _ownerZEEX, _idPartner[id].wallet, rebateAirDrop);
            _rebateAirDropPartner[id] += rebateAirDrop;
        }

        emit ClaimAirDropEvent (msg.sender, _amountZEEXEachAirDrop, _idPartner[id].wallet, rebateAirDrop);
    }

    function setAirDropLimit(uint256 limit)  external onlyOwner  {
        _airDropLimit = limit;
    }

    function getAirDropLimit() external view returns(uint256) {
        return _airDropLimit;
    }

    function getAirDropUsed() external view returns(uint256) {
        return _airDropUsed;
    }

    function setAirDropON(bool on) external onlyOwner {
        _airDropON = on;
    }

    function getAirDropON() external view returns(bool) {
        return _airDropON;
    }

    function setFeeAirDrop(uint256 amountBNB) external onlyOwner {
        _feeAirDrop = amountBNB;
    }

    function getFeeAirDrop() external view returns(uint256) {
        return _feeAirDrop;
    }

    function getRebateAirDropPartner(uint256 id) external view returns(uint256) {
        return _rebateAirDropPartner[id];
    }

    function setAmountZEEXEachAirDrop(uint256 amount) external onlyOwner {
        _amountZEEXEachAirDrop = amount;
    }

    function getAmountZEEXEachAirDrop() external view returns(uint256) {
        return _amountZEEXEachAirDrop;
    }

    function setTolerancePercent(uint8 percent) external onlyOwner {
        _tolerancePercent = percent;
    }

    function getTolerancePercent() external view returns(uint8) {
        return _tolerancePercent;
    }

    function reSetParamsConstructor(address priceFeedAddr, address ZEEXAddr, address USDTAddr) external onlyOwner {
         priceFeed = AggregatorV3Interface(priceFeedAddr);
        _ZEEX      = IBEP20(ZEEXAddr); 
        _USDT      = IBEP20(USDTAddr); 
    }

    function destruct(string memory confirmation) external onlyOwner  {
        require( keccak256(abi.encodePacked(confirmation)) == keccak256(abi.encodePacked("destroy contract!")), "Requerid confirmation");
        address payable addr = payable(address(_ownerZEEX));
        selfdestruct(addr);
    }

}