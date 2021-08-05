/**
 *Submitted for verification at Etherscan.io on 2020-07-07
*/

// File: localhost/mcd/maker/Manager.sol

pragma solidity ^0.6.0;

abstract contract Manager {
    function last(address) virtual public returns (uint);
    function cdpCan(address, uint, address) virtual public view returns (uint);
    function ilks(uint) virtual public view returns (bytes32);
    function owns(uint) virtual public view returns (address);
    function urns(uint) virtual public view returns (address);
    function vat() virtual public view returns (address);
    function open(bytes32, address) virtual public returns (uint);
    function give(uint, address) virtual public;
    function cdpAllow(uint, address, uint) virtual public;
    function urnAllow(address, uint) virtual public;
    function frob(uint, int, int) virtual public;
    function flux(uint, address, uint) virtual public;
    function move(uint, address, uint) virtual public;
    function exit(address, uint, address, uint) virtual public;
    function quit(uint, address) virtual public;
    function enter(address, uint) virtual public;
    function shift(uint, uint) virtual public;
}

// File: localhost/mcd/maker/Vat.sol

pragma solidity ^0.6.0;

abstract contract Vat {

    struct Urn {
        uint256 ink;   // Locked Collateral  [wad]
        uint256 art;   // Normalised Debt    [wad]
    }

    struct Ilk {
        uint256 Art;   // Total Normalised Debt     [wad]
        uint256 rate;  // Accumulated Rates         [ray]
        uint256 spot;  // Price with Safety Margin  [ray]
        uint256 line;  // Debt Ceiling              [rad]
        uint256 dust;  // Urn Debt Floor            [rad]
    }

    mapping (bytes32 => mapping (address => Urn )) public urns;
    mapping (bytes32 => Ilk)                       public ilks;
    mapping (bytes32 => mapping (address => uint)) public gem;  // [wad]

    function can(address, address) virtual public view returns (uint);
    function dai(address) virtual public view returns (uint);
    function frob(bytes32, address, address, address, int, int) virtual public;
    function hope(address) virtual public;
    function move(address, address, uint) virtual public;
    function fork(bytes32, address, address, int, int) virtual public;
}

// File: localhost/shifter/LoanShifterTaker.sol

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

// import "../interfaces/ILendingPool.sol";
// import "../interfaces/CTokenInterface.sol";
// import "../interfaces/ILoanShifter.sol";
// import "../interfaces/DSProxyInterface.sol";


// import "../auth/AdminAuth.sol";
// import "../auth/ProxyPermission.sol";
// import "../loggers/FlashLoanLogger.sol";
// import "../utils/ExchangeDataParser.sol";
// import "../exchange/SaverExchangeCore.sol";

/// @title LoanShifterTaker Entry point for using the shifting operation
contract LoanShifterTaker // is AdminAuth, ProxyPermission
{

    // ILendingPool public constant lendingPool = ILendingPool(0x398eC7346DcD622eDc5ae82352F02bE94C62d119);

    // address public constant ETH_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    // address public constant CETH_ADDRESS = 0x4Ddc2D193948926D02f9B1fE9e1daa0718270ED5;
    // address public constant DAI_ADDRESS = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    // address public constant cDAI_ADDRESS = 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643;

    // address payable public constant LOAN_SHIFTER_RECEIVER = 0xA94B7f0465E98609391C623d0560C5720a3f2D33;

    address public constant MANAGER_ADDRESS = 0x5ef30b9986345249bc32d8928B7ee64DE9435E39;
    address public constant VAT_ADDRESS = 0x35D1b3F3D7966A1DFe207aa4514C12a259A0492B;

    Manager public constant manager = Manager(MANAGER_ADDRESS);

    enum Protocols { MCD, COMPOUND, AAVE }

    struct LoanShiftData {
        Protocols fromProtocol;
        Protocols toProtocol;
        bool wholeDebt;
        uint collAmount;
        uint debtAmount;
        address debtAddr;
        address addrLoan1;
        address addrLoan2;
        uint id1;
        uint id2;
    }

    // mapping (Protocols => address) public contractAddresses;

    /// @notice Main entry point, it will move or transform a loan
    /// @dev If the operation doesn't require exchange send empty data
    function moveLoan(
        LoanShiftData memory _loanShift //,
        // SaverExchangeCore.ExchangeData memory _exchangeData
    ) public {
        if (_isSameTypeVaults(_loanShift)) {
            _forkVault(_loanShift);
            return;
        }

       // _callCloseAndOpen(_loanShift, _exchangeData);
    }

    /// @notice An admin only function to add/change a protocols address
    // function addProtocol(uint8 _protoType, address _protoAddr) public onlyOwner {
    //     contractAddresses[Protocols(_protoType)] = _protoAddr;
    // }

    // function getProtocolAddr(Protocols _proto) public view returns (address) {
    //     return contractAddresses[_proto];
    // }

    //////////////////////// INTERNAL FUNCTIONS //////////////////////////

    // function _callCloseAndOpen(
    //     LoanShiftData memory _loanShift,
    //     SaverExchangeCore.ExchangeData memory _exchangeData
    // ) internal {
    //     address protoAddr = getProtocolAddr(_loanShift.fromProtocol);

    //     uint loanAmount = _loanShift.debtAmount;

    //     if (_loanShift.wholeDebt) {
    //         loanAmount = ILoanShifter(protoAddr).getLoanAmount(_loanShift.id1, _loanShift.addrLoan1);
    //     }

    //     (
    //         uint[8] memory numData,
    //         address[6] memory addrData,
    //         uint8[3] memory enumData,
    //         bytes memory callData
    //     )
    //     = _packData(_loanShift, _exchangeData);

    //     // encode data
    //     bytes memory paramsData = abi.encode(numData, addrData, enumData, callData, address(this));

    //     // call FL
    //     givePermission(LOAN_SHIFTER_RECEIVER);

    //     lendingPool.flashLoan(LOAN_SHIFTER_RECEIVER, _loanShift.debtAddr, loanAmount, paramsData);

    //     removePermission(LOAN_SHIFTER_RECEIVER);
    // }

    function _forkVault(LoanShiftData memory _loanShift) internal {
        // Create new Vault to move to
        if (_loanShift.id2 == 0) {
            _loanShift.id2 = manager.open(manager.ilks(_loanShift.id1), address(this));
        }

        if (_loanShift.wholeDebt) {
            manager.shift(_loanShift.id1, _loanShift.id2);
        } else {
            Vat(VAT_ADDRESS).fork(
                manager.ilks(_loanShift.id1),
                manager.urns(_loanShift.id1),
                manager.urns(_loanShift.id2),
                int(_loanShift.collAmount),
                int(_loanShift.debtAmount)
            );
        }
    }

    function _isSameTypeVaults(LoanShiftData memory _loanShift) internal pure returns (bool) {
        return _loanShift.fromProtocol == Protocols.MCD && _loanShift.toProtocol == Protocols.MCD
                && _loanShift.addrLoan1 == _loanShift.addrLoan2;
    }

    // function _packData(
    //     LoanShiftData memory _loanShift,
    //     SaverExchangeCore.ExchangeData memory exchangeData
    // ) internal pure returns (uint[8] memory numData, address[6] memory addrData, uint8[3] memory enumData, bytes memory callData) {

    //     numData = [
    //         _loanShift.collAmount,
    //         _loanShift.debtAmount,
    //         _loanShift.id1,
    //         _loanShift.id2,
    //         exchangeData.srcAmount,
    //         exchangeData.destAmount,
    //         exchangeData.minPrice,
    //         exchangeData.price0x
    //     ];

    //     addrData = [
    //         _loanShift.addrLoan1,
    //         _loanShift.addrLoan2,
    //         _loanShift.debtAddr,
    //         exchangeData.srcAddr,
    //         exchangeData.destAddr,
    //         exchangeData.exchangeAddr
    //     ];

    //     enumData = [
    //         uint8(_loanShift.fromProtocol),
    //         uint8(_loanShift.toProtocol),
    //         uint8(exchangeData.exchangeType)
    //     ];

    //     callData = exchangeData.callData;
    // }

}