pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import "./IACOToken.sol";
import "./IWETH.sol";
import "./ACOAssetHelper.sol";

contract ACOWriterV2 {
    
    address immutable public weth;
    address immutable public zrxExchange;
    
    bool internal _notEntered;

    modifier nonReentrant() {
        require(_notEntered, "ACOWriter::Reentry");
        _notEntered = false;
        _;
        _notEntered = true;
    }
    
    constructor(address _weth, address _zrxExchange) public {
        weth = _weth;
        zrxExchange = _zrxExchange;
        _notEntered = true;
    }
    
    receive() external payable {
        require(tx.origin != msg.sender, "ACOWriter:: Not allowed");
    }
    
    function write(
        address acoToken, 
        uint256 collateralAmount, 
        bytes memory zrxExchangeData
    ) 
        nonReentrant 
        public 
        payable 
    {
        require(msg.value > 0,  "ACOWriter::write: Invalid msg value");
        require(collateralAmount > 0,  "ACOWriter::write: Invalid collateral amount");
        
        address _collateral = IACOToken(acoToken).collateral();
        if (ACOAssetHelper._isEther(_collateral)) {
            IACOToken(acoToken).mintToPayable{value: collateralAmount}(msg.sender);
        } else {
            ACOAssetHelper._callTransferFromERC20(_collateral, msg.sender, address(this), collateralAmount);
            ACOAssetHelper._setAssetInfinityApprove(_collateral, address(this), acoToken, collateralAmount);
            IACOToken(acoToken).mintTo(msg.sender, collateralAmount);
        }
        
        _sellACOTokens(acoToken, zrxExchangeData);
    }
    
    function _sellACOTokens(address acoToken, bytes memory exchangeData) internal {
        uint256 acoBalance = ACOAssetHelper._getAssetBalanceOf(acoToken, address(this));
        ACOAssetHelper._setAssetInfinityApprove(acoToken, address(this), zrxExchange, acoBalance);
        (bool success,) = zrxExchange.call{value: address(this).balance}(exchangeData);
        require(success, "ACOWriter::_sellACOTokens: Error on call the exchange");
        
        address token = IACOToken(acoToken).strikeAsset();
        if(ACOAssetHelper._isEther(token)) {
            uint256 wethBalance = ACOAssetHelper._getAssetBalanceOf(weth, address(this));
            if (wethBalance > 0) {
                IWETH(weth).withdraw(wethBalance);
            }
        } else {
            uint256 remaining = ACOAssetHelper._getAssetBalanceOf(token, address(this));
            if (remaining > 0) {
                ACOAssetHelper._callTransferERC20(token, msg.sender, remaining);
            }
        }
        
        if (address(this).balance > 0) {
            msg.sender.transfer(address(this).balance);
        }
    }
}