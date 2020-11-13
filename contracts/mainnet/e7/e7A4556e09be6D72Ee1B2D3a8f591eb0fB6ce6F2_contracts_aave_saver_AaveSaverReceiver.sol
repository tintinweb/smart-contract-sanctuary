pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../savings/dydx/ISoloMargin.sol";
import "../../utils/SafeERC20.sol";
import "../../interfaces/TokenInterface.sol";
import "../../DS/DSProxy.sol";
import "../AaveHelper.sol";
import "../../auth/AdminAuth.sol";
import "../../exchange/SaverExchangeCore.sol";

/// @title Import Aave position from account to wallet
contract AaveSaverReceiver is AaveHelper, AdminAuth, SaverExchangeCore {

    using SafeERC20 for ERC20;

    address public constant AAVE_SAVER_PROXY = 0x29F4af15ad64C509c4140324cFE71FB728D10d2B;
    address public constant AAVE_BASIC_PROXY = 0x29F4af15ad64C509c4140324cFE71FB728D10d2B;
    address public constant AETH_ADDRESS = 0x3a3A65aAb0dd2A17E3F1947bA16138cd37d08c04;

    function callFunction(
        address sender,
        Account.Info memory account,
        bytes memory data
    ) public {

        (
            bytes memory exchangeDataBytes,
            uint256 gasCost,
            bool isRepay,
            uint256 ethAmount,
            uint256 txValue,
            address user,
            address proxy
        )
        = abi.decode(data, (bytes,uint256,bool,uint256,uint256,address,address));

        // withdraw eth
        TokenInterface(WETH_ADDRESS).withdraw(ethAmount);

        address lendingPoolCoreAddress = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();
        
        // deposit eth on behalf of proxy
        DSProxy(payable(proxy)).execute{value: ethAmount}(AAVE_BASIC_PROXY, abi.encodeWithSignature("deposit(address,uint256)", ETH_ADDR, ethAmount));
        
        bytes memory functionData = packFunctionCall(exchangeDataBytes, gasCost, isRepay);
        DSProxy(payable(proxy)).execute(AAVE_SAVER_PROXY, functionData);

        // withdraw deposited eth
        DSProxy(payable(proxy)).execute(AAVE_BASIC_PROXY, abi.encodeWithSignature("withdraw(address,address,uint256,bool)", ETH_ADDR, AETH_ADDRESS, ethAmount, false));

        // deposit eth, get weth and return to sender
        TokenInterface(WETH_ADDRESS).deposit.value(address(this).balance)();
        ERC20(WETH_ADDRESS).safeTransfer(proxy, ethAmount+2);
    }

    function packFunctionCall(bytes memory _exchangeDataBytes, uint256 _gasCost, bool _isRepay) internal returns (bytes memory) {
        ExchangeData memory exData = unpackExchangeData(_exchangeDataBytes);

        bytes memory functionData;

        if (_isRepay) {
            functionData = abi.encodeWithSignature("repay((address,address,uint256,uint256,uint256,address,address,bytes,uint256),uint256)", exData, _gasCost);
        } else {
            functionData = abi.encodeWithSignature("boost((address,address,uint256,uint256,uint256,address,address,bytes,uint256),uint256)", exData, _gasCost);
        }

        return functionData;
    }

    /// @dev if contract receive eth, convert it to WETH
    receive() external override payable {
        // deposit eth and get weth 
        if (msg.sender == owner) {
            TokenInterface(WETH_ADDRESS).deposit.value(address(this).balance)();
        }
    }
}