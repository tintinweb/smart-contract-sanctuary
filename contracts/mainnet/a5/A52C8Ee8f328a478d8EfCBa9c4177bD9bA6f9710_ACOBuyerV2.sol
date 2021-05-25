pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import "./ACOAssetHelper.sol";
import "./SafeMath.sol";

contract ACOBuyerV2 {
    
    struct BuyACO {
        address from;
        uint256 ethValue;
        bytes data;
    }
    
    bool internal _notEntered;

    modifier nonReentrant() {
        require(_notEntered, "ACOBuyer::Reentry");
        _notEntered = false;
        _;
        _notEntered = true;
    }
    
    constructor() public {
        _notEntered = true;
    }

    receive() external payable {
        require(tx.origin != msg.sender, "ACOBuyer:: Not allowed");
    }
    
    function buy(
        address acoToken,
        address paymentToken, 
        uint256 paymentAmount, 
        BuyACO[] calldata data
    ) 
        nonReentrant
        external
        payable
    {
        require(paymentAmount > 0, "ACOBuyer::buy: Invalid amount");
        require(data.length > 0, "ACOBuyer::buy: Invalid data");
        require(acoToken != address(0), "ACOBuyer::buy: Invalid aco");
        
        bool isEther = ACOAssetHelper._isEther(paymentToken);
        
        uint256 previousEthBalance = SafeMath.sub(address(this).balance, msg.value);
        uint256 previousAcoBalance = ACOAssetHelper._getAssetBalanceOf(acoToken, address(this));
        uint256 previousTokenBalance;
        
        if (isEther) {
            require(msg.value >= paymentAmount, "ACOBuyer::buy:Invalid ETH amount");
        } else {
            previousTokenBalance = ACOAssetHelper._getAssetBalanceOf(paymentToken, address(this));
            ACOAssetHelper._callTransferFromERC20(paymentToken, msg.sender, address(this), paymentAmount);
        }
        
        for (uint256 i = 0; i < data.length; ++i) {
            if (!isEther) {
                ACOAssetHelper._setAssetInfinityApprove(paymentToken, address(this), data[i].from, paymentAmount);
            }
            (bool success,) = data[i].from.call{value:data[i].ethValue}(data[i].data);
            require(success, "ACOBuyer::buy:Error on order");
        }
        
        uint256 remainingEth = SafeMath.sub(address(this).balance, previousEthBalance);
        uint256 afterAcoBalance = ACOAssetHelper._getAssetBalanceOf(acoToken, address(this));
        uint256 remainingAco = SafeMath.sub(afterAcoBalance, previousAcoBalance);

        if (remainingAco > 0) {
            ACOAssetHelper._callTransferERC20(acoToken, msg.sender, remainingAco);
        }
        if (!isEther) {
            uint256 afterTokenBalance = ACOAssetHelper._getAssetBalanceOf(paymentToken, address(this));
            uint256 remainingToken = SafeMath.sub(afterTokenBalance, previousTokenBalance);
            if (remainingToken > 0) {
                ACOAssetHelper._callTransferERC20(paymentToken, msg.sender, remainingToken);
            }
        }
        if (remainingEth > 0) {
            msg.sender.transfer(remainingEth);
        }
    }
}