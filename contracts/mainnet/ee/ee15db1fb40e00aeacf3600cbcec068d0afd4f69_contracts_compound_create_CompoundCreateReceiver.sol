pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../DS/DSProxy.sol";
import "../../utils/FlashLoanReceiverBase.sol";
import "../../interfaces/DSProxyInterface.sol";
import "../../exchange/SaverExchangeCore.sol";
import "../../shifter/ShifterRegistry.sol";

/// @title Contract that receives the FL from Aave for Creating loans
contract CompoundCreateReceiver is FlashLoanReceiverBase, SaverExchangeCore {

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);
    ShifterRegistry public constant shifterRegistry = ShifterRegistry(0x2E82103bD91053C781aaF39da17aE58ceE39d0ab);

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address payable public constant WALLET_ADDR = 0x322d58b9E75a6918f7e7849AEe0fF09369977e08;
    address public constant DISCOUNT_ADDR = 0x1b14E8D511c9A4395425314f849bD737BAF8208F;

    // solhint-disable-next-line no-empty-blocks
    constructor() public FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER) {}

    struct CompCreateData {
        address payable proxyAddr;
        bytes proxyData;
        address cCollAddr;
        address cDebtAddr;
    }

    /// @notice Called by Aave when sending back the FL amount
    /// @param _reserve The address of the borrowed token
    /// @param _amount Amount of FL tokens received
    /// @param _fee FL Aave fee
    /// @param _params The params that are sent from the original FL caller contract
   function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params)
    external override {
        // Format the call data for DSProxy
        (CompCreateData memory compCreate, ExchangeData memory exchangeData)
                                 = packFunctionCall(_amount, _fee, _params);


        address leveragedAsset = _reserve;

        // If the assets are different
        if (compCreate.cCollAddr != compCreate.cDebtAddr) {
            (, uint sellAmount) = _sell(exchangeData);
            getFee(sellAmount, exchangeData.destAddr, compCreate.proxyAddr);

            leveragedAsset = exchangeData.destAddr;
        }

        // Send amount to DSProxy
        sendToProxy(compCreate.proxyAddr, leveragedAsset);

        address compOpenProxy = shifterRegistry.getAddr("COMP_SHIFTER");

        // Execute the DSProxy call
        DSProxyInterface(compCreate.proxyAddr).execute(compOpenProxy, compCreate.proxyData);

        // Repay the loan with the money DSProxy sent back
        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            // solhint-disable-next-line avoid-tx-origin
            tx.origin.transfer(address(this).balance);
        }
    }

    /// @notice Formats function data call so we can call it through DSProxy
    /// @param _amount Amount of FL
    /// @param _fee Fee of the FL
    /// @param _params Saver proxy params
    function packFunctionCall(uint _amount, uint _fee, bytes memory _params) internal pure  returns (CompCreateData memory compCreate, ExchangeData memory exchangeData) {
        (
            uint[4] memory numData, // srcAmount, destAmount, minPrice, price0x
            address[6] memory cAddresses, // cCollAddr, cDebtAddr, srcAddr, destAddr, exchangeAddr, wrapper
            bytes memory callData,
            address proxy
        )
        = abi.decode(_params, (uint256[4],address[6],bytes,address));

        bytes memory proxyData = abi.encodeWithSignature(
            "open(address,address,uint256)",
                                cAddresses[0], cAddresses[1], (_amount + _fee));

         exchangeData = SaverExchangeCore.ExchangeData({
            srcAddr: cAddresses[2],
            destAddr: cAddresses[3],
            srcAmount: numData[0],
            destAmount: numData[1],
            minPrice: numData[2],
            wrapper: cAddresses[5],
            exchangeAddr: cAddresses[4],
            callData: callData,
            price0x: numData[3]
        });

        compCreate = CompCreateData({
            proxyAddr: payable(proxy),
            proxyData: proxyData,
            cCollAddr: cAddresses[0],
            cDebtAddr: cAddresses[1]
        });

        return (compCreate, exchangeData);
    }

    /// @notice Send the FL funds received to DSProxy
    /// @param _proxy DSProxy address
    /// @param _reserve Token address
    function sendToProxy(address payable _proxy, address _reserve) internal {
        if (_reserve != ETH_ADDRESS) {
            ERC20(_reserve).safeTransfer(_proxy, ERC20(_reserve).balanceOf(address(this)));
        } else {
            _proxy.transfer(address(this).balance);
        }
    }

    function getFee(uint _amount, address _tokenAddr, address _proxy) internal returns (uint feeAmount) {
        uint fee = 400;

        DSProxy proxy = DSProxy(payable(_proxy));
        address user = proxy.owner();

        if (Discount(DISCOUNT_ADDR).isCustomFeeSet(user)) {
            fee = Discount(DISCOUNT_ADDR).getCustomServiceFee(user);
        }

        feeAmount = (fee == 0) ? 0 : (_amount / fee);

        // fee can't go over 20% of the whole amount
        if (feeAmount > (_amount / 5)) {
            feeAmount = _amount / 5;
        }

        if (_tokenAddr == ETH_ADDRESS) {
            WALLET_ADDR.transfer(feeAmount);
        } else {
            ERC20(_tokenAddr).safeTransfer(WALLET_ADDR, feeAmount);
        }
    }

    // solhint-disable-next-line no-empty-blocks
    receive() external override(FlashLoanReceiverBase, SaverExchangeCore) payable {}
}
