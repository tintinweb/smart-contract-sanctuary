pragma solidity ^0.6.0;

import "../utils/GasBurner.sol";
import "../interfaces/IAToken.sol";
import "../interfaces/ILendingPool.sol";
import "../interfaces/ILendingPoolAddressesProvider.sol";

import "../utils/SafeERC20.sol";

/// @title Basic compound interactions through the DSProxy
contract AaveBasicProxy is GasBurner {

    using SafeERC20 for ERC20;

    address public constant ETH_ADDR = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address public constant AAVE_LENDING_POOL_ADDRESSES = 0x24a42fD28C976A61Df5D00D0599C34c4f90748c8;

    uint16 public constant AAVE_REFERRAL_CODE = 64;

    /// @notice User deposits tokens to the Aave protocol
    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @param _tokenAddr The address of the token to be deposited
    /// @param _amount Amount of tokens to be deposited
    function deposit(address _tokenAddr, uint256 _amount) public burnGas(5) payable {
        address lendingPoolCore = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();

        uint ethValue = _amount;

        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeTransferFrom(msg.sender, address(this), _amount);
            approveToken(_tokenAddr, lendingPoolCore);
            ethValue = 0;
        }

        ILendingPool(lendingPool).deposit{value: ethValue}(_tokenAddr, _amount, AAVE_REFERRAL_CODE);

        setUserUseReserveAsCollateralIfNeeded(_tokenAddr);
    }

    /// @notice User withdraws tokens from the Aave protocol
    /// @param _tokenAddr The address of the token to be withdrawn
    /// @param _aTokenAddr ATokens to be withdrawn
    /// @param _amount Amount of tokens to be withdrawn
    /// @param _wholeAmount If true we will take the whole amount on chain
    function withdraw(address _tokenAddr, address _aTokenAddr, uint256 _amount, bool _wholeAmount) public burnGas(8) {
        uint256 amount = _wholeAmount ? ERC20(_aTokenAddr).balanceOf(address(this)) : _amount;

        IAToken(_aTokenAddr).redeem(amount);

        withdrawTokens(_tokenAddr);
    }

    /// @notice User borrows tokens to the Aave protocol
    /// @param _tokenAddr The address of the token to be borrowed
    /// @param _amount Amount of tokens to be borrowed
    /// @param _type Send 1 for stable rate and 2 for variable rate
    function borrow(address _tokenAddr, uint256 _amount, uint256 _type) public burnGas(8) {
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();

        ILendingPool(lendingPool).borrow(_tokenAddr, _amount, _type, AAVE_REFERRAL_CODE);

        withdrawTokens(_tokenAddr);
    }

    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @notice User paybacks tokens to the Aave protocol
    /// @param _tokenAddr The address of the token to be paybacked
    /// @param _aTokenAddr ATokens to be paybacked
    /// @param _amount Amount of tokens to be payed back
    /// @param _wholeDebt If true the _amount will be set to the whole amount of the debt
    function payback(address _tokenAddr, address _aTokenAddr, uint256 _amount, bool _wholeDebt) public burnGas(3) payable {
        address lendingPoolCore = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();

        uint256 amount = _amount;

        (,uint256 borrowAmount,,,,,uint256 originationFee,,,) = ILendingPool(lendingPool).getUserReserveData(_tokenAddr, address(this));

        if (_wholeDebt) {
            amount = borrowAmount + originationFee;
        }

        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeTransferFrom(msg.sender, address(this), amount);
            approveToken(_tokenAddr, lendingPoolCore);
        }

        ILendingPool(lendingPool).repay{value: msg.value}(_tokenAddr, amount, payable(address(this)));

        withdrawTokens(_tokenAddr);
    }

    /// @dev User needs to approve the DSProxy to pull the _tokenAddr tokens
    /// @notice User paybacks tokens to the Aave protocol
    /// @param _tokenAddr The address of the token to be paybacked
    /// @param _aTokenAddr ATokens to be paybacked
    /// @param _amount Amount of tokens to be payed back
    /// @param _wholeDebt If true the _amount will be set to the whole amount of the debt
    function paybackOnBehalf(address _tokenAddr, address _aTokenAddr, uint256 _amount, bool _wholeDebt, address payable _onBehalf) public burnGas(3) payable {
        address lendingPoolCore = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPoolCore();
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();

        uint256 amount = _amount;

        (,uint256 borrowAmount,,,,,uint256 originationFee,,,) = ILendingPool(lendingPool).getUserReserveData(_tokenAddr, _onBehalf);

        if (_wholeDebt) {
            amount = borrowAmount + originationFee;
        }

        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeTransferFrom(msg.sender, address(this), amount);
            approveToken(_tokenAddr, lendingPoolCore);
        }

        ILendingPool(lendingPool).repay{value: msg.value}(_tokenAddr, amount, _onBehalf);

        withdrawTokens(_tokenAddr);
    }

    /// @notice Helper method to withdraw tokens from the DSProxy
    /// @param _tokenAddr Address of the token to be withdrawn
    function withdrawTokens(address _tokenAddr) public {
        uint256 amount = _tokenAddr == ETH_ADDR ? address(this).balance : ERC20(_tokenAddr).balanceOf(address(this));

        if (amount > 0) {
            if (_tokenAddr != ETH_ADDR) {
                ERC20(_tokenAddr).safeTransfer(msg.sender, amount);
            } else {
                msg.sender.transfer(amount);
            }
        }
    }

    /// @notice Approves token contract to pull underlying tokens from the DSProxy
    /// @param _tokenAddr Token we are trying to approve
    /// @param _caller Address which will gain the approval
    function approveToken(address _tokenAddr, address _caller) internal {
        if (_tokenAddr != ETH_ADDR) {
            ERC20(_tokenAddr).safeApprove(_caller, uint256(-1));
        }
    }

    function setUserUseReserveAsCollateralIfNeeded(address _tokenAddr) public {
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();
        (,,,,,,,,,bool collateralEnabled) = ILendingPool(lendingPool).getUserReserveData(_tokenAddr, address(this));

        if (!collateralEnabled) {
            ILendingPool(lendingPool).setUserUseReserveAsCollateral(_tokenAddr, true);
        }
    }

    function setUserUseReserveAsCollateral(address _tokenAddr, bool _true) public {
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();

        ILendingPool(lendingPool).setUserUseReserveAsCollateral(_tokenAddr, _true);
    }

    function swapBorrowRateMode(address _reserve) public {
        address lendingPool = ILendingPoolAddressesProvider(AAVE_LENDING_POOL_ADDRESSES).getLendingPool();

        ILendingPool(lendingPool).swapBorrowRateMode(_reserve);
    }
}