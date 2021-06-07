/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

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

contract AaveDelegate {
    ILendingPool constant public lendingPool = ILendingPool(0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9);
    IyRegistry constant public registry = IyRegistry(0xE15461B18EE31b7379019Dc523231C57d1Cbc18c);
    IProtocolDataProvider constant public provider = IProtocolDataProvider(0x057835Ad21a177dbdd3090bB1CAE03EaCF78Fc6d);
    
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
    
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))));
    }
    
    function approvalVariable(address token) external view returns (address) {
        (, , address variableDebtTokenAddress) = provider.getReserveTokensAddresses(token);
        return variableDebtTokenAddress;
    }
    
    function approvalStable(address token) external view returns (address) {
        (, address stableDebtTokenAddress, ) = provider.getReserveTokensAddresses(token);
        return stableDebtTokenAddress;
    }
    
    function vault(address token) external view returns (address) {
        return registry.latestVault(token);
    }
    
    function availableVariable(address delegate, address token) external view returns (uint) {
        (, , address variableDebtTokenAddress) = provider.getReserveTokensAddresses(token);
        return IDebtToken(variableDebtTokenAddress).borrowAllowance(delegate, address(this));
    }
    
    function availableStable(address delegate, address token) external view returns (uint) {
        (, address stableDebtTokenAddress, ) = provider.getReserveTokensAddresses(token);
        return IDebtToken(stableDebtTokenAddress).borrowAllowance(delegate, address(this));
    }
    
    function depositAllVariable(address token) external {
        (, , address variableDebtTokenAddress) = provider.getReserveTokensAddresses(token);
        uint256 variableAllowance = IDebtToken(variableDebtTokenAddress).borrowAllowance(msg.sender, address(this));
        _deposit(token, variableAllowance, 2);
    }
    
    function depositAllStable(address token) external {
        (, address stableDebtTokenAddress, ) = provider.getReserveTokensAddresses(token);
        uint256 stableAllowance = IDebtToken(stableDebtTokenAddress).borrowAllowance(msg.sender, address(this));
        _deposit(token, stableAllowance, 1);
    }
    
    function deposit(address token, uint amount, uint interestRateModel) external {
        _deposit(token, amount, interestRateModel);
    }
    
    // Stable: 1, Variable: 2
    function _deposit(address token, uint amount, uint interestRateModel) internal {
        IyVault _vault = IyVault(registry.latestVault(token));
        lendingPool.borrow(token, amount, interestRateModel, 7, msg.sender);
        IERC20(token).approve(address(_vault), amount);
        _vault.deposit(amount, msg.sender);
    }
    
    function withdrawAll(address token, uint maxLoss, uint rateMode) external {
        IyVault _vault = IyVault(registry.latestVault(token));
        _withdraw(_vault, token, IERC20(address(_vault)).balanceOf(msg.sender), maxLoss, rateMode);
    }
    
    function withdrawAllWithPermit(address token, uint maxLoss, uint expiry, bytes32 signature, uint rateMode) external {
        IyVault _vault = IyVault(registry.latestVault(token));
        uint _amount = IERC20(address(_vault)).balanceOf(msg.sender);
        _vault.permit(msg.sender, address(this), _amount, expiry, signature);
        _withdraw(_vault, token, _amount, maxLoss, rateMode);
    }
    
    function withdraw(address token, uint amount, uint maxLoss, uint rateMode) external {
        IyVault _vault = IyVault(registry.latestVault(token));
        _withdraw(_vault, token, amount, maxLoss, rateMode);
    }
    
    function withdrawWithPermit(address token, uint amount, uint maxLoss, uint expiry, bytes32 signature, uint rateMode) external {
        IyVault _vault = IyVault(registry.latestVault(token));
        _vault.permit(msg.sender, address(this), amount, expiry, signature);
        _withdraw(_vault, token, amount, maxLoss, rateMode);
    }
    
    // Stable: 1, Variable: 2
    function _withdraw(IyVault _vault, address token, uint amount, uint maxLoss, uint rateMode) internal {
        safeTransferFrom(address(_vault), msg.sender, address(this), amount);
        uint _amount = _vault.withdraw(amount, address(this), maxLoss);
        lendingPool.repay(token, _amount, rateMode, msg.sender);
        safeTransfer(token, msg.sender, IERC20(token).balanceOf(address(this)));
    }
}