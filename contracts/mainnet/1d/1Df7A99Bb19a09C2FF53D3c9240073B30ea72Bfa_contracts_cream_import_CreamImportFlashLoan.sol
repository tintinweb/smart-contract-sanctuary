pragma solidity ^0.6.0;

import "../../utils/FlashLoanReceiverBase.sol";
import "../../interfaces/ProxyRegistryInterface.sol";
import "../../interfaces/CTokenInterface.sol";
import "../../utils/SafeERC20.sol";

/// @title Receives FL from Aave and imports the position to DSProxy
contract CreamImportFlashLoan is FlashLoanReceiverBase {

    using SafeERC20 for ERC20;

    ILendingPoolAddressesProvider public LENDING_POOL_ADDRESS_PROVIDER = ILendingPoolAddressesProvider(0x24a42fD28C976A61Df5D00D0599C34c4f90748c8);

    address public constant CREAM_BORROW_PROXY = 0x87F198Ef6116CdBC5f36B581d212ad950b7e2Ddd;

    address public owner;

    constructor()
        FlashLoanReceiverBase(LENDING_POOL_ADDRESS_PROVIDER)
        public {
            owner = msg.sender;
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

        (
            address cCollateralToken,
            address cBorrowToken,
            address user,
            address proxy
        )
        = abi.decode(_params, (address,address,address,address));

        // approve FL tokens so we can repay them
        ERC20(_reserve).safeApprove(cBorrowToken, 0);
        ERC20(_reserve).safeApprove(cBorrowToken, uint(-1));

        // repay cream debt
        require(CTokenInterface(cBorrowToken).repayBorrowBehalf(user, uint(-1)) == 0, "Repay borrow behalf fail");

        // transfer cTokens to proxy
        uint cTokenBalance = CTokenInterface(cCollateralToken).balanceOf(user);
        require(CTokenInterface(cCollateralToken).transferFrom(user, proxy, cTokenBalance));

        // borrow
        bytes memory proxyData = getProxyData(cCollateralToken, cBorrowToken, _reserve, (_amount + _fee));
        DSProxyInterface(proxy).execute(CREAM_BORROW_PROXY, proxyData);

        // Repay the loan with the money DSProxy sent back
        transferFundsBackToPoolInternal(_reserve, _amount.add(_fee));
    }

    /// @notice Formats function data call so we can call it through DSProxy
    /// @param _cCollToken CToken address of collateral
    /// @param _cBorrowToken CToken address we will borrow
    /// @param _borrowToken Token address we will borrow
    /// @param _amount Amount that will be borrowed
    /// @return proxyData Formated function call data
    function getProxyData(address _cCollToken, address _cBorrowToken, address _borrowToken, uint _amount) internal pure returns (bytes memory proxyData) {
        proxyData = abi.encodeWithSignature(
            "borrow(address,address,address,uint256)",
            _cCollToken, _cBorrowToken, _borrowToken, _amount);
    }

    function withdrawStuckFunds(address _tokenAddr, uint _amount) public {
        require(owner == msg.sender, "Must be owner");

        if (_tokenAddr == 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE) {
            msg.sender.transfer(_amount);
        } else {
            ERC20(_tokenAddr).safeTransfer(owner, _amount);
        }
    }
}
