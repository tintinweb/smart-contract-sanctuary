pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../../mcd/saver/MCDSaverProxy.sol";
import "../../utils/FlashLoanReceiverBase.sol";
import "../../auth/AdminAuth.sol";
import "../../exchangeV3/DFSExchangeCore.sol";
import "../../mcd/saver/MCDSaverProxyHelper.sol";
import "./MCDCloseTaker.sol";

contract MCDCloseFlashLoan is DFSExchangeCore, MCDSaverProxyHelper, FlashLoanReceiverBase, AdminAuth {
    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    uint public constant SERVICE_FEE = 400; // 0.25% Fee

    bytes32 internal constant ETH_ILK = 0x4554482d41000000000000000000000000000000000000000000000000000000;

    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant DAI_JOIN_ADDRESS = 0x9759A6Ac90977b93B58547b4A71c78317f391A28;
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
        address reserve;
        uint amount;
    }

    constructor() FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER) public {}

    function executeOperation(
        address _reserve,
        uint256 _amount,
        uint256 _fee,
        bytes calldata _params)
    external override {

        (address proxy, bytes memory packedData) = abi.decode(_params, (address,bytes));

        (MCDCloseTaker.CloseData memory closeDataSent, ExchangeData memory exchangeData) = abi.decode(packedData, (MCDCloseTaker.CloseData,ExchangeData));

        CloseData memory closeData = CloseData({
            cdpId: closeDataSent.cdpId,
            collAmount: closeDataSent.collAmount,
            daiAmount: closeDataSent.daiAmount,
            minAccepted: closeDataSent.minAccepted,
            joinAddr: closeDataSent.joinAddr,
            proxy: proxy,
            flFee: _fee,
            toDai: closeDataSent.toDai,
            reserve: _reserve,
            amount: _amount
        });

        address user = DSProxy(payable(closeData.proxy)).owner();

        exchangeData.dfsFeeDivider = SERVICE_FEE;
        exchangeData.user = user;

        closeCDP(closeData, exchangeData, user);
    }

    function closeCDP(
        CloseData memory _closeData,
        ExchangeData memory _exchangeData,
        address _user
    ) internal {

        paybackDebt(_closeData.cdpId, manager.ilks(_closeData.cdpId), _closeData.daiAmount); // payback whole debt
        uint drawnAmount = drawMaxCollateral(_closeData.cdpId, _closeData.joinAddr, _closeData.collAmount); // draw whole collateral

        uint daiSwaped = 0;

        if (_closeData.toDai) {
            _exchangeData.srcAmount = drawnAmount;
            (, daiSwaped) = _sell(_exchangeData);
        } else {
            _exchangeData.destAmount = _closeData.daiAmount;
            (, daiSwaped) = _buy(_exchangeData);
        }

        address tokenAddr = getVaultCollAddr(_closeData.joinAddr);

        if (_closeData.toDai) {
            tokenAddr = DAI_ADDRESS;
        }

        require(getBalance(tokenAddr) >= _closeData.minAccepted, "Below min. number of eth specified");

        transferFundsBackToPoolInternal(_closeData.reserve, _closeData.amount.add(_closeData.flFee));

        sendLeftover(tokenAddr, DAI_ADDRESS, payable(_user));

    }

    function drawMaxCollateral(uint _cdpId, address _joinAddr, uint _amount) internal returns (uint) {
        manager.frob(_cdpId, -toPositiveInt(_amount), 0);
        manager.flux(_cdpId, address(this), _amount);

        uint joinAmount = _amount;

        if (Join(_joinAddr).dec() != 18) {
            joinAmount = _amount / (10 ** (18 - Join(_joinAddr).dec()));
        }

        Join(_joinAddr).exit(address(this), joinAmount);

        if (isEthJoinAddr(_joinAddr)) {
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

    function getVaultCollAddr(address _joinAddr) internal view returns (address) {
        address tokenAddr = address(Join(_joinAddr).gem());

        if (tokenAddr == WETH_ADDRESS) {
            return KYBER_ETH_ADDRESS;
        }

        return tokenAddr;
    }

    function getPrice(bytes32 _ilk) public view returns (uint256) {
        (, uint256 mat) = spotter.ilks(_ilk);
        (, , uint256 spot, , ) = vat.ilks(_ilk);

        return rmul(rmul(spot, spotter.par()), mat);
    }

    receive() external override(FlashLoanReceiverBase, DFSExchangeCore) payable {}

}
