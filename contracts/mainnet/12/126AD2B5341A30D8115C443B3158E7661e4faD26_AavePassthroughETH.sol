// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.4;

interface IPCVDepositBalances {
    
    // ----------- Getters -----------
    
    /// @notice gets the effective balance of "balanceReportedIn" token if the deposit were fully withdrawn
    function balance() external view returns (uint256);

    /// @notice gets the token address in which this deposit returns its balance
    function balanceReportedIn() external view returns (address);

    /// @notice gets the resistant token balance and protocol owned fei of this deposit
    function resistantBalanceAndFei() external view returns (uint256, uint256);
}

/// @title a PCV Deposit interface
/// @author Fei Protocol
interface IPCVDeposit is IPCVDepositBalances {
    // ----------- Events -----------
    event Deposit(address indexed _from, uint256 _amount);

    event Withdrawal(
        address indexed _caller,
        address indexed _to,
        uint256 _amount
    );

    event WithdrawERC20(
        address indexed _caller,
        address indexed _token,
        address indexed _to,
        uint256 _amount
    );

    event WithdrawETH(
        address indexed _caller,
        address indexed _to,
        uint256 _amount
    );

    // ----------- State changing api -----------

    function deposit() external;

    // ----------- PCV Controller only state changing api -----------

    function withdraw(address to, uint256 amount) external;
    function withdrawERC20(address token, address to, uint256 amount) external;
    function withdrawETH(address payable to, uint256 amount) external;
}

contract AavePassthroughETH {
    address payable constant target = payable(0x5B86887e171bAE0C2C826e87E34Df8D558C079B9);
    function deposit(uint256 _amount) external payable {
        (bool success, ) = target.call{value: address(this).balance}("");
        require(success, "Address: unable to send value, recipient may have reverted");
        IPCVDeposit(target).deposit();
    }
}

contract CompoundPassthroughETH {
    address payable constant target = payable(0x4fCB1435fD42CE7ce7Af3cB2e98289F79d2962b3);
    function deposit(uint256 _amount) external payable {
        (bool success, ) = target.call{value: address(this).balance}("");
        require(success, "Address: unable to send value, recipient may have reverted");
        IPCVDeposit(target).deposit();
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "devdoc",
        "userdoc",
        "metadata",
        "abi"
      ]
    }
  }
}