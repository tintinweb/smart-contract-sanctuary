pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../helpers/Exponential.sol";
import "../../utils/SafeERC20.sol";
import "../../utils/GasBurner.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../interfaces/ComptrollerInterface.sol";

contract CompBalance is Exponential, GasBurner {

    ComptrollerInterface public constant comp = ComptrollerInterface(0x3d9819210A31b4961b30EF54bE2aeD79B9c9Cd3B);
    address public constant COMP_ADDR = 0xc00e94Cb662C3520282E6f5717214004A7f26888;
    uint224 public constant compInitialIndex = 1e36;

    function claimComp(address _user, address[] memory _cTokensSupply, address[] memory _cTokensBorrow) public burnGas(8) {
        _claim(_user, _cTokensSupply, _cTokensBorrow);

        ERC20(COMP_ADDR).transfer(msg.sender,  ERC20(COMP_ADDR).balanceOf(address(this)));
    }

    function _claim(address _user, address[] memory _cTokensSupply, address[] memory _cTokensBorrow) internal {
        address[] memory u = new address[](1);
        u[0] = _user;

        comp.claimComp(u, _cTokensSupply, false, true);
        comp.claimComp(u, _cTokensBorrow, true, false);
    }

    function getBalance(address _user, address[] memory _cTokens) public view returns (uint) {
        uint compBalance = 0;

        for(uint i = 0; i < _cTokens.length; ++i) {
            compBalance += getSuppyBalance(_cTokens[i], _user);
            compBalance += getBorrowBalance(_cTokens[i], _user);
        }

        compBalance += ERC20(COMP_ADDR).balanceOf(_user);

        return compBalance;
    }


    function getSuppyBalance(address _cToken, address _supplier) public view returns (uint supplierAccrued) {
        ComptrollerInterface.CompMarketState memory supplyState = comp.compSupplyState(_cToken);
        Double memory supplyIndex = Double({mantissa: supplyState.index});
        Double memory supplierIndex = Double({mantissa: comp.compSupplierIndex(_cToken, _supplier)});

        if (supplierIndex.mantissa == 0 && supplyIndex.mantissa > 0) {
            supplierIndex.mantissa = compInitialIndex;
        }

        Double memory deltaIndex = sub_(supplyIndex, supplierIndex);
        uint supplierTokens = CTokenInterface(_cToken).balanceOf(_supplier);
        uint supplierDelta = mul_(supplierTokens, deltaIndex);
        supplierAccrued = add_(comp.compAccrued(_supplier), supplierDelta);
    }

    function getBorrowBalance(address _cToken, address _borrower) public view returns (uint borrowerAccrued) {
        ComptrollerInterface.CompMarketState memory borrowState = comp.compBorrowState(_cToken);
        Double memory borrowIndex = Double({mantissa: borrowState.index});
        Double memory borrowerIndex = Double({mantissa: comp.compBorrowerIndex(_cToken, _borrower)});

        Exp memory marketBorrowIndex = Exp({mantissa: CTokenInterface(_cToken).borrowIndex()});

        if (borrowerIndex.mantissa > 0) {
            Double memory deltaIndex = sub_(borrowIndex, borrowerIndex);
            uint borrowerAmount = div_(CTokenInterface(_cToken).borrowBalanceStored(_borrower), marketBorrowIndex);
            uint borrowerDelta = mul_(borrowerAmount, deltaIndex);
            borrowerAccrued = add_(comp.compAccrued(_borrower), borrowerDelta);
        }
    }
}
