/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface ILendingPool {
      function borrow(
        address asset,
        uint256 amount,
        uint256 interestRateMode,
        uint16 referralCode,
        address onBehalfOf
      ) external;
      
    function repay(
        address asset,
        uint256 amount,
        uint256 rateMode,
        address onBehalfOf
      ) external returns (uint256);
}

interface IyVault {
    function token() external view returns (address);
    function deposit(uint, address) external returns (uint);
    function withdraw(uint, address, uint) external returns (uint);
    function permit(address, address, uint, uint, bytes32) external view returns (bool);
}

interface IyRegistry {
    function latestVault(address) external view returns (address);
}

interface IProtocolDataProvider {
  function getReserveTokensAddresses(address asset) external view returns (address aTokenAddress, address stableDebtTokenAddress, address variableDebtTokenAddress);
}

interface IDebtToken {
    function borrowAllowance(address, address) external view returns (uint);
}

contract yDelegate {
    ILendingPool constant public lendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    IyRegistry constant public registry = IyRegistry(0xE15461B18EE31b7379019Dc523231C57d1Cbc18c);
    IProtocolDataProvider constant public provider = IProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);
    
    function approval(address token) external view returns (address) {
        (, , address variableDebtTokenAddress) = provider.getReserveTokensAddresses(token);
        return variableDebtTokenAddress;
    }
    
    function vault(address token) external view returns (address) {
        return registry.latestVault(token);
    }
    
    function available(address delegate, address token) external view returns (uint) {
        (, , address variableDebtTokenAddress) = provider.getReserveTokensAddresses(token);
        return IDebtToken(variableDebtTokenAddress).borrowAllowance(delegate, address(this));
    }
    
    function depositAll(address token) external {
        (, , address variableDebtTokenAddress) = provider.getReserveTokensAddresses(token);
        uint256 variableAllowance = IDebtToken(variableDebtTokenAddress).borrowAllowance(msg.sender, address(this));
        _deposit(token, variableAllowance);
    }
    
    function deposit(address token, uint amount) external {
        _deposit(token, amount);
    }
    
    function _deposit(address token, uint amount) internal {
        IyVault _vault = IyVault(registry.latestVault(token));
        lendingPool.borrow(token, amount, 2, 7, msg.sender);
        IERC20(token).approve(address(_vault), amount);
        _vault.deposit(amount, msg.sender);
    }
    
    function withdrawAll(address token, uint maxLoss) external {
        IyVault _vault = IyVault(registry.latestVault(token));
        _withdraw(_vault, token, IERC20(address(_vault)).balanceOf(msg.sender), maxLoss);
    }
    
    function withdrawAllWithPermit(address token, uint maxLoss, uint expiry, bytes32 signature) external {
        IyVault _vault = IyVault(registry.latestVault(token));
        uint _amount = IERC20(address(_vault)).balanceOf(msg.sender);
        _vault.permit(msg.sender, address(this), _amount, expiry, signature);
        _withdraw(_vault, token, _amount, maxLoss);
    }
    
    function withdraw(address token, uint amount, uint maxLoss) external {
        IyVault _vault = IyVault(registry.latestVault(token));
        _withdraw(_vault, token, amount, maxLoss);
    }
    
    function withdrawWithPermit(address token, uint amount, uint maxLoss, uint expiry, bytes32 signature) external {
        IyVault _vault = IyVault(registry.latestVault(token));
        _vault.permit(msg.sender, address(this), amount, expiry, signature);
        _withdraw(_vault, token, amount, maxLoss);
    }
    
    function _withdraw(IyVault _vault, address token, uint amount, uint maxLoss) internal {
        IERC20(address(_vault)).transferFrom(msg.sender, address(this), amount);
        uint _amount = _vault.withdraw(amount, address(this), maxLoss);
        lendingPool.repay(token, _amount, 2, msg.sender);
    }
}