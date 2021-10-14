/**
 *Submitted for verification at BscScan.com on 2021-03-01
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Context.sol";
import "./Address.sol";
import "./AccessControl.sol";
import "./SafeERC20.sol";

//    Interfaces   

import "./IERC20.sol";

//**********************************//
//     W A R P V A U L T   CONTRACT
//**********************************//
contract WarpVault is AccessControl {
    using SafeERC20 for IERC20;

    bytes32 internal constant Contract_Manager = keccak256("Contract_Manager");
    bytes32 internal constant Financial_Controller = keccak256("Financial_Controller");
    bytes32 internal constant Treasury_Analyst  = keccak256("Treasury_Analyst");

    IERC20  private immutable _token;
    address private immutable _beneficiary;
    address public _manager;
    uint256 public _targetAmount;
    uint8   internal constant _decimals = 9;

    event TargetAmountUpdated(uint256 _targetAmount);

    constructor (IERC20 token_, address manager, address beneficiary, uint256 targetAmount)  {

        _manager = manager;
        _beneficiary = beneficiary;
        _targetAmount = targetAmount;
        _token = token_;

        _setupRole(Contract_Manager, manager);
        _setupRole(Financial_Controller, manager);
        _setupRole(Treasury_Analyst, manager);
        _setRoleAdmin(Financial_Controller, Contract_Manager);
        _setRoleAdmin(Treasury_Analyst, Financial_Controller);

    }

    function setTargetAmount (uint256 targetAmount) external onlyRole(Financial_Controller)  {
        _targetAmount  = targetAmount*10**_decimals;
        emit TargetAmountUpdated(_targetAmount);
    }

    function burnVaultReserves() external onlyRole(Treasury_Analyst) {
        uint256 vaultBalance = _token.balanceOf(address(this));
        require(vaultBalance >= _targetAmount);

        _token.safeTransfer(_beneficiary, _targetAmount);
    }

}