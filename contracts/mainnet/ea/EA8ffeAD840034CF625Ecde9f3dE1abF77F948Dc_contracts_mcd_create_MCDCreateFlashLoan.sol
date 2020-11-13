pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../exchange/SaverExchangeCore.sol";
import "./MCDCreateProxyActions.sol";
import "../../utils/FlashLoanReceiverBase.sol";
import "../../interfaces/Manager.sol";
import "../../interfaces/Join.sol";
import "../../DS/DSProxy.sol";

contract MCDCreateFlashLoan is SaverExchangeCore, AdminAuth, FlashLoanReceiverBase {
    address public constant CREATE_PROXY_ACTIONS = 0x6d0984E80a86f26c0dd564ca0CF74a8E9Da03305;

    uint public constant SERVICE_FEE = 400; // 0.25% Fee
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    address public constant DAI_JOIN_ADDRESS = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    address public constant JUG_ADDRESS = 0x19c0976f590D67707E62397C87829d896Dc0f1F1;
    address public constant MANAGER_ADDRESS = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;

    constructor() FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER) public {}

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params)
    external override {

        //check the contract has the specified balance
        require(_amount <= getBalanceInternal(address(this), _reserve),
            "Invalid balance for the contract");

        (
            uint[6] memory numData,
            address[5] memory addrData,
            bytes memory callData,
            address proxy
        )
         = abi.decode(_params, (uint256[6],address[5],bytes,address));

        ExchangeData memory exchangeData = ExchangeData({
            srcAddr: addrData[0],
            destAddr: addrData[1],
            srcAmount: numData[2],
            destAmount: numData[3],
            minPrice: numData[4],
            wrapper: addrData[3],
            exchangeAddr: addrData[2],
            callData: callData,
            price0x: numData[5]
        });

        openAndLeverage(numData[0], numData[1] + _fee, addrData[4], proxy, exchangeData);

        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        // if there is some eth left (0x fee), return it to user
        if (address(this).balance > 0) {
            tx.origin.transfer(address(this).balance);
        }
    }

    function openAndLeverage(
        uint _collAmount,
        uint _daiAmountAndFee,
        address _joinAddr,
        address _proxy,
        ExchangeData memory _exchangeData
    ) public {

        uint dfsFee = getFee(_exchangeData.srcAmount, DSProxy(payable(_proxy)).owner());

        _exchangeData.srcAmount = (_exchangeData.srcAmount - dfsFee);
        (, uint256 collSwaped) = _sell(_exchangeData);

        bytes32 ilk = Join(_joinAddr).ilk();

        if (isEthJoinAddr(_joinAddr)) {
            MCDCreateProxyActions(CREATE_PROXY_ACTIONS).openLockETHAndDraw{value: address(this).balance}(
                MANAGER_ADDRESS,
                JUG_ADDRESS,
                _joinAddr,
                DAI_JOIN_ADDRESS,
                ilk,
                _daiAmountAndFee,
                _proxy
            );
        } else {
            ERC20(address(Join(_joinAddr).gem())).safeApprove(CREATE_PROXY_ACTIONS, 0);
            ERC20(address(Join(_joinAddr).gem())).safeApprove(CREATE_PROXY_ACTIONS, uint256(-1));

            MCDCreateProxyActions(CREATE_PROXY_ACTIONS).openLockGemAndDraw(
                MANAGER_ADDRESS,
                JUG_ADDRESS,
                _joinAddr,
                DAI_JOIN_ADDRESS,
                ilk,
                (_collAmount + collSwaped),
                _daiAmountAndFee,
                true,
                _proxy
            );
        }
    }

    function getFee(uint _amount, address _owner) internal returns (uint feeAmount) {
        uint fee = SERVICE_FEE;

        if (Discount(DISCOUNT_ADDRESS).isCustomFeeSet(_owner)) {
            fee = Discount(DISCOUNT_ADDRESS).getCustomServiceFee(_owner);
        }

        feeAmount = (fee == 0) ? 0 : (_amount / fee);

        // fee can't go over 20% of the whole amount
        if (feeAmount > (_amount / 5)) {
            feeAmount = _amount / 5;
        }

        ERC20(DAI_ADDRESS).transfer(WALLET_ID, feeAmount);
    }

    /// @notice Checks if the join address is one of the Ether coll. types
    /// @param _joinAddr Join address to check
    function isEthJoinAddr(address _joinAddr) internal view returns (bool) {
        // if it's dai_join_addr don't check gem() it will fail
        if (_joinAddr == 0x9759A6Ac90977b93B58547b4A71c78317f391A28) return false;

        // if coll is weth it's and eth type coll
        if (address(Join(_joinAddr).gem()) == 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2) {
            return true;
        }

        return false;
    }

    receive() external override(FlashLoanReceiverBase, SaverExchangeCore) payable {}
}
