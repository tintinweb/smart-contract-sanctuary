pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../mcd/saver/MCDSaverProxy.sol";
import "../../utils/FlashLoanReceiverBase.sol";
import "../../auth/AdminAuth.sol";
import "../../exchange/SaverExchangeCore.sol";
import "../../mcd/saver/MCDSaverProxyHelper.sol";

contract MCDCloseFlashLoan is SaverExchangeCore, MCDSaverProxyHelper, FlashLoanReceiverBase, AdminAuth {
    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    uint public constant SERVICE_FEE = 400; // 0.25% Fee

    bytes32 internal constant ETH_ILK = 0x4554482d41000000000000000000000000000000000000000000000000000000;

    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant DAI_JOIN_ADDRESS = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
    address public constant ETH_JOIN_ADDRESS = 0x2F0b23f53734252Bda2277357e97e1517d6B042A;
    address public constant SPOTTER_ADDRESS = 0x65C79fcB50Ca1594B025960e539eD7A9a6D434A3;
    address public constant VAT_ADDRESS = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;

    Manager public constant manager = Manager(0x5ef30b9986345249bc32d8928B7ee64DE9435E39);
    DaiJoin public constant daiJoin = DaiJoin(DAI_JOIN_ADDRESS);
    Spotter public constant spotter = Spotter(SPOTTER_ADDRESS);
    Vat public constant vat = Vat(VAT_ADDRESS);

    struct CloseData {
        uint cdpId;
        uint collAmount;
        uint daiAmount;
        uint minAccepted;
        address joinAddr;
        address proxy;
        uint flFee;
        bool toDai;
    }

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
            uint[8] memory numData,
            address[5] memory addrData,
            bytes memory callData,
            address proxy,
            bool toDai
        )
         = abi.decode(_params, (uint256[8],address[5],bytes,address,bool));

        ExchangeData memory exchangeData = ExchangeData({
            srcAddr: addrData[0],
            destAddr: addrData[1],
            srcAmount: numData[4],
            destAmount: numData[5],
            minPrice: numData[6],
            wrapper: addrData[3],
            exchangeAddr: addrData[2],
            callData: callData,
            price0x: numData[7]
        });

        CloseData memory closeData = CloseData({
            cdpId: numData[0],
            collAmount: numData[1],
            daiAmount: numData[2],
            minAccepted: numData[3],
            joinAddr: addrData[4],
            proxy: proxy,
            flFee: _fee,
            toDai: toDai
        });

        address collAddr = closeCDP(closeData, exchangeData);

        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));

        sendLeftover(collAddr, DAI_ADDRESS, tx.origin);
    }

    function closeCDP(
        CloseData memory _closeData,
        ExchangeData memory _exchangeData
    ) internal returns (address) {

        paybackDebt(_closeData.cdpId, manager.ilks(_closeData.cdpId), _closeData.daiAmount); // payback whole debt
        drawMaxCollateral(_closeData.cdpId, _closeData.joinAddr, _closeData.collAmount); // draw whole collateral

        uint daiSwaped = 0;
        uint dfsFee = 0;
        address user = DSProxy(payable(_closeData.proxy)).owner();

        if (_closeData.toDai) {
            _exchangeData.srcAmount = _closeData.collAmount;
            (, daiSwaped) = _sell(_exchangeData);

            dfsFee = getFee(daiSwaped, user);
        } else {
            dfsFee = getFee(_closeData.daiAmount, user);

            _exchangeData.destAmount = (_closeData.daiAmount + _closeData.flFee + dfsFee);
            (, daiSwaped) = _buy(_exchangeData);
        }

        takeFee(dfsFee);

        address tokenAddr = address(Join(_closeData.joinAddr).gem());

        require(getBalance(tokenAddr) >= _closeData.minAccepted, "Below min. number of eth specified");

        return tokenAddr;

    }

    function drawMaxCollateral(uint _cdpId, address _joinAddr, uint _amount) internal returns (uint) {
        manager.frob(_cdpId, -toPositiveInt(_amount), 0);
        manager.flux(_cdpId, address(this), _amount);

        uint joinAmount = _amount;

        if (Join(_joinAddr).dec() != 18) {
            joinAmount = _amount / (10 ** (18 - Join(_joinAddr).dec()));
        }

        Join(_joinAddr).exit(address(this), joinAmount);

        if (_joinAddr == ETH_JOIN_ADDRESS) {
            Join(_joinAddr).gem().withdraw(joinAmount); // Weth -> Eth
        }

        return joinAmount;
    }

    function paybackDebt(uint _cdpId, bytes32 _ilk, uint _daiAmount) internal {
        address urn = manager.urns(_cdpId);

        daiJoin.dai().approve(DAI_JOIN_ADDRESS, _daiAmount);
        daiJoin.join(urn, _daiAmount);

        manager.frob(_cdpId, 0, normalizePaybackAmount(VAT_ADDRESS, urn, _ilk));
    }

    function takeFee(uint _feeAmount) internal returns (uint) {
        ERC20(DAI_ADDRESS).transfer(WALLET_ID, _feeAmount);
    }

    function getFee(uint _amount, address _owner) internal view returns (uint feeAmount) {
        uint fee = SERVICE_FEE;

        if (Discount(DISCOUNT_ADDRESS).isCustomFeeSet(_owner)) {
            fee = Discount(DISCOUNT_ADDRESS).getCustomServiceFee(_owner);
        }

        feeAmount = (fee == 0) ? 0 : (_amount / fee);

        // fee can't go over 20% of the whole amount
        if (feeAmount > (_amount / 5)) {
            feeAmount = _amount / 5;
        }
    }

    function getPrice(bytes32 _ilk) public view returns (uint256) {
        (, uint256 mat) = spotter.ilks(_ilk);
        (, , uint256 spot, , ) = vat.ilks(_ilk);

        return rmul(rmul(spot, spotter.par()), mat);
    }

    receive() external override(FlashLoanReceiverBase, SaverExchangeCore) payable {}

}
