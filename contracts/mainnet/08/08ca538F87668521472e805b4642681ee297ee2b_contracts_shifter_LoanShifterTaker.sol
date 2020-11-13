pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../interfaces/ILendingPool.sol";
import "../interfaces/CTokenInterface.sol";
import "../interfaces/ILoanShifter.sol";
import "../interfaces/DSProxyInterface.sol";
import "../interfaces/Vat.sol";
import "../interfaces/Manager.sol";
import "../interfaces/IMCDSubscriptions.sol";
import "../interfaces/ICompoundSubscriptions.sol";
import "../auth/AdminAuth.sol";
import "../auth/ProxyPermission.sol";
import "../exchange/SaverExchangeCore.sol";
import "./ShifterRegistry.sol";
import "../utils/GasBurner.sol";
import "../loggers/DefisaverLogger.sol";


/// @title LoanShifterTaker Entry point for using the shifting operation
contract LoanShifterTaker is AdminAuth, ProxyPermission, GasBurner {

    ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    address public constant MCD_SUB_ADDRESS = 0xC45d4f6B6bf41b6EdAA58B01c4298B8d9078269a;
    address public constant COMPOUND_SUB_ADDRESS = 0x52015EFFD577E08f498a0CCc11905925D58D6207;

    address public constant MANAGER_ADDRESS = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;

    address public constant DEFISAVER_LOGGER = 0x5c55B921f590a89C1Ebe84dF170E655a82b62126;

    Manager public constant manager = Manager(MANAGER_ADDRESS);
    ShifterRegistry public constant shifterRegistry = ShifterRegistry(0x597C52281b31B9d949a9D8fEbA08F7A2530a965e);

    enum Protocols { MCD, COMPOUND }
    enum SwapType { NO_SWAP, COLL_SWAP, DEBT_SWAP }
    enum Unsub { NO_UNSUB, FIRST_UNSUB, SECOND_UNSUB, BOTH_UNSUB }

    struct LoanShiftData {
        Protocols fromProtocol;
        Protocols toProtocol;
        SwapType swapType;
        Unsub unsub;
        bool wholeDebt;
        uint collAmount;
        uint debtAmount;
        address debtAddr1;
        address debtAddr2;
        address addrLoan1;
        address addrLoan2;
        uint id1;
        uint id2;
    }

    /// @notice Main entry point, it will move or transform a loan
    /// @dev Called through DSProxy
    function moveLoan(
        SaverExchangeCore.ExchangeData memory _exchangeData,
        LoanShiftData memory _loanShift
    ) public payable burnGas(20) {
        if (_isSameTypeVaults(_loanShift)) {
            _forkVault(_loanShift);
            logEvent(_exchangeData, _loanShift);
            return;
        }

        _callCloseAndOpen(_exchangeData, _loanShift);
    }

    //////////////////////// INTERNAL FUNCTIONS //////////////////////////

    function _callCloseAndOpen(
        SaverExchangeCore.ExchangeData memory _exchangeData,
        LoanShiftData memory _loanShift
    ) internal {
        address protoAddr = shifterRegistry.getAddr(getNameByProtocol(uint8(_loanShift.fromProtocol)));

        if (_loanShift.wholeDebt) {
            _loanShift.debtAmount = ILoanShifter(protoAddr).getLoanAmount(_loanShift.id1, _loanShift.debtAddr1);
        }

        (
            uint[8] memory numData,
            address[8] memory addrData,
            uint8[3] memory enumData,
            bytes memory callData
        )
        = _packData(_loanShift, _exchangeData);

        // encode data
        bytes memory paramsData = abi.encode(numData, addrData, enumData, callData, address(this));

        address payable loanShifterReceiverAddr = payable(shifterRegistry.getAddr("LOAN_SHIFTER_RECEIVER"));

        loanShifterReceiverAddr.transfer(address(this).balance);

        // call FL
        givePermission(loanShifterReceiverAddr);

        lendingPool.flashLoan(loanShifterReceiverAddr,
           getLoanAddr(_loanShift.debtAddr1, _loanShift.fromProtocol), _loanShift.debtAmount, paramsData);

        removePermission(loanShifterReceiverAddr);

        unsubFromAutomation(
            _loanShift.unsub,
            _loanShift.id1,
            _loanShift.id2,
            _loanShift.fromProtocol,
            _loanShift.toProtocol
        );

        logEvent(_exchangeData, _loanShift);
    }

    function _forkVault(LoanShiftData memory _loanShift) internal {
        // Create new Vault to move to
        if (_loanShift.id2 == 0) {
            _loanShift.id2 = manager.open(manager.ilks(_loanShift.id1), address(this));
        }

        if (_loanShift.wholeDebt) {
            manager.shift(_loanShift.id1, _loanShift.id2);
        }
    }

    function _isSameTypeVaults(LoanShiftData memory _loanShift) internal pure returns (bool) {
        return _loanShift.fromProtocol == Protocols.MCD && _loanShift.toProtocol == Protocols.MCD
                && _loanShift.addrLoan1 == _loanShift.addrLoan2;
    }

    function getNameByProtocol(uint8 _proto) internal pure returns (string memory) {
        if (_proto == 0) {
            return "MCD_SHIFTER";
        } else if (_proto == 1) {
            return "COMP_SHIFTER";
        }
    }

    function getLoanAddr(address _address, Protocols _fromProtocol) internal returns (address) {
        if (_fromProtocol == Protocols.COMPOUND) {
            return CTokenInterface(_address).underlying();
        } else if (_fromProtocol == Protocols.MCD) {
            return DAI_ADDRESS;
        } else {
            return address(0);
        }
    }

    function logEvent(
        SaverExchangeCore.ExchangeData memory _exchangeData,
        LoanShiftData memory _loanShift
    ) internal {
        address srcAddr = _exchangeData.srcAddr;
        address destAddr = _exchangeData.destAddr;

        uint collAmount = _exchangeData.srcAmount;
        uint debtAmount = _exchangeData.destAmount;

        if (_loanShift.swapType == SwapType.NO_SWAP) {
            srcAddr = _loanShift.addrLoan1;
            destAddr = _loanShift.debtAddr1;

            collAmount = _loanShift.collAmount;
            debtAmount = _loanShift.debtAmount;
        }

        DefisaverLogger(DEFISAVER_LOGGER)
            .Log(address(this), msg.sender, "LoanShifter",
            abi.encode(
            _loanShift.fromProtocol,
            _loanShift.toProtocol,
            _loanShift.swapType,
            srcAddr,
            destAddr,
            collAmount,
            debtAmount
        ));
    }

    function unsubFromAutomation(Unsub _unsub, uint _cdp1, uint _cdp2, Protocols _from, Protocols _to) internal {
        if (_unsub != Unsub.NO_UNSUB) {
            if (_unsub == Unsub.FIRST_UNSUB || _unsub == Unsub.BOTH_UNSUB) {
                unsubscribe(_cdp1, _from);
            }

            if (_unsub == Unsub.SECOND_UNSUB || _unsub == Unsub.BOTH_UNSUB) {
                unsubscribe(_cdp2, _to);
            }
        }
    }

    function unsubscribe(uint _cdpId, Protocols _protocol) internal {
        if (_cdpId != 0 && _protocol == Protocols.MCD) {
            IMCDSubscriptions(MCD_SUB_ADDRESS).unsubscribe(_cdpId);
        }

        if (_protocol == Protocols.COMPOUND) {
            ICompoundSubscriptions(COMPOUND_SUB_ADDRESS).unsubscribe();
        }
    }

    function _packData(
        LoanShiftData memory _loanShift,
        SaverExchangeCore.ExchangeData memory exchangeData
    ) internal pure returns (uint[8] memory numData, address[8] memory addrData, uint8[3] memory enumData, bytes memory callData) {

        numData = [
            _loanShift.collAmount,
            _loanShift.debtAmount,
            _loanShift.id1,
            _loanShift.id2,
            exchangeData.srcAmount,
            exchangeData.destAmount,
            exchangeData.minPrice,
            exchangeData.price0x
        ];

        addrData = [
            _loanShift.addrLoan1,
            _loanShift.addrLoan2,
            _loanShift.debtAddr1,
            _loanShift.debtAddr2,
            exchangeData.srcAddr,
            exchangeData.destAddr,
            exchangeData.exchangeAddr,
            exchangeData.wrapper
        ];

        enumData = [
            uint8(_loanShift.fromProtocol),
            uint8(_loanShift.toProtocol),
            uint8(_loanShift.swapType)
        ];

        callData = exchangeData.callData;
    }

}
