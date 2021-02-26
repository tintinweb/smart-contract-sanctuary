pragma solidity ^0.6.6;
pragma experimental ABIEncoderV2;

import "./ACOAssetHelper.sol";
import "./SafeMath.sol";
import "./IACOPool2.sol";
import "./IACOFactory.sol";
import "./IChiToken.sol";

contract ACOBuyer {
    
    IACOFactory immutable public acoFactory;
	IChiToken immutable public chiToken;

    bool internal _notEntered;

    modifier nonReentrant() {
        require(_notEntered, "ACOBuyer::Reentry");
        _notEntered = false;
        _;
        _notEntered = true;
    }
    
    modifier discountCHI {
        uint256 gasStart = gasleft();
        _;
        uint256 gasSpent = 21000 + gasStart - gasleft() + 16 * msg.data.length;
        chiToken.freeFromUpTo(msg.sender, (gasSpent + 14154) / 41947);
    }
    
    constructor(address _acoFactory, address _chiToken) public {
        acoFactory = IACOFactory(_acoFactory);
	    chiToken = IChiToken(_chiToken);
        _notEntered = true;
    }

    receive() external payable {
        require(tx.origin != msg.sender, "ACOBuyer:: Not allowed");
    }

    function buy(
        address acoToken, 
        address to,
        uint256 deadline,
        address[] calldata acoPools,
        uint256[] calldata amounts,
        uint256[] calldata restrictions
    ) 
        nonReentrant 
        external 
        payable
    {
        _buy(acoToken, to, deadline, acoPools, amounts, restrictions);
    }
    
    function buyWithGasToken(
        address acoToken, 
        address to,
        uint256 deadline,
        address[] calldata acoPools,
        uint256[] calldata amounts,
        uint256[] calldata restrictions
    ) 
        discountCHI
        nonReentrant 
        external 
        payable
    {
        _buy(acoToken, to, deadline, acoPools, amounts, restrictions);
    }
    
    function _buy(
        address acoToken, 
        address to,
        uint256 deadline,
        address[] memory acoPools,
        uint256[] memory acoAmounts,
        uint256[] memory restrictions
    ) internal {
        require(acoToken != address(0), "ACOBuyer::buy: Invalid ACO token");
        require(acoPools.length > 0, "ACOBuyer::buy: Invalid pools");
        require(acoPools.length == acoAmounts.length && acoPools.length == restrictions.length, "ACOBuyer::buy: Invalid arguments");
        
        (,address strikeAsset,,,) = acoFactory.acoTokenData(acoToken);
        
        uint256 amount = _getAssetAmount(acoAmounts, restrictions);
        (uint256 previousBalance, uint256 extraAmount) = _receiveAsset(strikeAsset, amount);
        
        _poolSwap(strikeAsset, acoToken, to, deadline, acoPools, acoAmounts, restrictions);
        
        uint256 afterBalance = ACOAssetHelper._getAssetBalanceOf(strikeAsset, address(this));
        uint256 remaining = SafeMath.add(extraAmount, SafeMath.sub(afterBalance, previousBalance));
        if (remaining > 0) {
            ACOAssetHelper._transferAsset(strikeAsset, msg.sender, remaining);
        }
    }

    function _getAssetAmount(uint256[] memory acoAmounts, uint256[] memory restrictions) internal pure returns(uint256 amount) {
        amount = 0;
        for (uint256 i = 0; i < acoAmounts.length; ++i) {
            require(acoAmounts[i] > 0, "ACOBuyer::buy: Invalid amount");
            require(restrictions[i] > 0, "ACOBuyer::buy: Invalid restriction");
            amount = SafeMath.add(amount, restrictions[i]);
        }
    }

    function _receiveAsset(address strikeAsset, uint256 amount) internal returns(uint256 previousBalance, uint256 extraAmount) {
        previousBalance = ACOAssetHelper._getAssetBalanceOf(strikeAsset, address(this));

        extraAmount = 0;
        if (ACOAssetHelper._isEther(strikeAsset)) {
            require(msg.value >= amount, "ACOBuyer::buy:Invalid ETH amount");
            previousBalance = SafeMath.sub(previousBalance, msg.value);
            extraAmount = SafeMath.sub(msg.value, amount);
        } else {
            require(msg.value == 0, "ACOBuyer::buy:No payable");
            ACOAssetHelper._callTransferFromERC20(strikeAsset, msg.sender, address(this), amount);
        }
    } 

    function _poolSwap(
        address strikeAsset, 
        address acoToken, 
        address to,
        uint256 deadline,
        address[] memory acoPools,
        uint256[] memory acoAmounts,
        uint256[] memory restrictions
    ) internal {
        for (uint256 i = 0; i < acoPools.length; ++i) {
            uint256 etherAmount = 0; 
            if (ACOAssetHelper._isEther(strikeAsset)) {
                etherAmount = restrictions[i];
            } else {
                ACOAssetHelper._setAssetInfinityApprove(strikeAsset, address(this), acoPools[i], restrictions[i]);
            }
            IACOPool2(acoPools[i]).swap{value: etherAmount}(acoToken, acoAmounts[i], restrictions[i], to, deadline);
        }
    }
}