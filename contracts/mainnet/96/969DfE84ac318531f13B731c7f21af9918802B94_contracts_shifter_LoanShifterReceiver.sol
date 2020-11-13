pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../auth/AdminAuth.sol";
import "../utils/FlashLoanReceiverBase.sol";
import "../interfaces/DSProxyInterface.sol";
import "../exchange/SaverExchangeCore.sol";
import "./ShifterRegistry.sol";

/// @title LoanShifterReceiver Recevies the Aave flash loan and calls actions through users DSProxy
contract LoanShifterReceiver is SaverExchangeCore, FlashLoanReceiverBase, AdminAuth {

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);
    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    ShifterRegistry public constant shifterRegistry = ShifterRegistry(0x597C52281b31B9d949a9D8fEbA08F7A2530a965e);

    struct ParamData {
        bytes proxyData1;
        bytes proxyData2;
        address proxy;
        address debtAddr;
        uint8 protocol1;
        uint8 protocol2;
        uint8 swapType;
    }

    constructor() FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER) public {}

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params)
    external override {
        // Format the call data for DSProxy
        (ParamData memory paramData, ExchangeData memory exchangeData)
                                 = packFunctionCall(_amount, _fee, _params);

        address protocolAddr1 = shifterRegistry.getAddr(getNameByProtocol(paramData.protocol1));
        address protocolAddr2 = shifterRegistry.getAddr(getNameByProtocol(paramData.protocol2));

        // Send Flash loan amount to DSProxy
        sendToProxy(payable(paramData.proxy), _reserve, _amount);

        // Execute the Close/Change debt operation
        DSProxyInterface(paramData.proxy).execute(protocolAddr1, paramData.proxyData1);

        if (paramData.swapType == 1) { // COLL_SWAP
            exchangeData.srcAmount = getBalance(exchangeData.srcAddr);
            (, uint amount) = _sell(exchangeData);

            sendToProxy(payable(paramData.proxy), exchangeData.destAddr, amount);
        } else if (paramData.swapType == 2) { // DEBT_SWAP
            exchangeData.destAmount = (_amount + _fee);
            _buy(exchangeData);

            // Send extra to DSProxy
            sendToProxy(payable(paramData.proxy), exchangeData.srcAddr, ERC20(exchangeData.srcAddr).balanceOf(address(this)));

        } else { // NO_SWAP just send tokens to proxy
            sendToProxy(payable(paramData.proxy), exchangeData.srcAddr, getBalance(exchangeData.srcAddr));
        }

        // Execute the Open operation
        DSProxyInterface(paramData.proxy).execute(protocolAddr2, paramData.proxyData2);

        // Repay FL
        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }
    }

    function packFunctionCall(uint _amount, uint _fee, bytes memory _params)
        internal pure returns (ParamData memory paramData, ExchangeData memory exchangeData) {

        (
            uint[8] memory numData, // collAmount, debtAmount, id1, id2, srcAmount, destAmount, minPrice, price0x
            address[8] memory addrData, // addrLoan1, addrLoan2, debtAddr1, debtAddr2, srcAddr, destAddr, exchangeAddr, wrapper
            uint8[3] memory enumData, // fromProtocol, toProtocol, swapType
            bytes memory callData,
            address proxy
        )
        = abi.decode(_params, (uint256[8],address[8],uint8[3],bytes,address));

        bytes memory proxyData1;
        bytes memory proxyData2;
        uint openDebtAmount = (_amount + _fee);

        if (enumData[0] == 0) { // MAKER FROM
            proxyData1 = abi.encodeWithSignature("close(uint256,address,uint256,uint256)", numData[2], addrData[0], _amount, numData[0]);

        } else if(enumData[0] == 1) { // COMPOUND FROM
            if (enumData[2] == 2) { // DEBT_SWAP
                proxyData1 = abi.encodeWithSignature("changeDebt(address,address,uint256,uint256)", addrData[2], addrData[3], _amount, numData[4]);
            } else {
                proxyData1 = abi.encodeWithSignature("close(address,address,uint256,uint256)", addrData[0], addrData[2], numData[0], numData[1]);
            }
        }

        if (enumData[1] == 0) { // MAKER TO
            proxyData2 = abi.encodeWithSignature("open(uint256,address,uint256)", numData[3], addrData[1], openDebtAmount);
        } else if(enumData[1] == 1) { // COMPOUND TO
            if (enumData[2] == 2) { // DEBT_SWAP
                proxyData2 = abi.encodeWithSignature("repayAll(address)", addrData[3]);
            } else {
                proxyData2 = abi.encodeWithSignature("open(address,address,uint256)", addrData[1], addrData[3], openDebtAmount);
            }
        }


        paramData = ParamData({
            proxyData1: proxyData1,
            proxyData2: proxyData2,
            proxy: proxy,
            debtAddr: addrData[2],
            protocol1: enumData[0],
            protocol2: enumData[1],
            swapType: enumData[2]
        });

        exchangeData = SaverExchangeCore.ExchangeData({
            srcAddr: addrData[4],
            destAddr: addrData[5],
            srcAmount: numData[4],
            destAmount: numData[5],
            minPrice: numData[6],
            wrapper: addrData[7],
            exchangeAddr: addrData[6],
            callData: callData,
            price0x: numData[7]
        });

    }

    function sendToProxy(address payable _proxy, address _reserve, uint _amount) internal {
        if (_reserve != ETH_ADDRESS) {
            ERC20(_reserve).safeTransfer(_proxy, _amount);
        }

        _proxy.transfer(address(this).balance);
    }

    function getNameByProtocol(uint8 _proto) internal pure returns (string memory) {
        if (_proto == 0) {
            return "MCD_SHIFTER";
        } else if (_proto == 1) {
            return "COMP_SHIFTER";
        }
    }

    receive() external override(FlashLoanReceiverBase, SaverExchangeCore) payable {}
}
