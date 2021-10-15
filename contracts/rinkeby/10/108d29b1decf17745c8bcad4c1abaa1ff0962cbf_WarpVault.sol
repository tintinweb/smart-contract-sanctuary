//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./Context.sol";
import "./Address.sol";
import "./AccessControl.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";

//    Interfaces   

import "./IERC20.sol";

//**********************************//
//     W A R P V A U L T   CONTRACT
//**********************************//
contract WarpVault is AccessControl {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    bytes32 internal constant Contract_Manager = keccak256("Contract_Manager");
    bytes32 internal constant Financial_Controller = keccak256("Financial_Controller");
    bytes32 internal constant Compliance_Auditor = keccak256("Compliance_Auditor");
    

    IERC20  private immutable _token;
    bool    public  immutable isMutable;
    address public  beneficiary;
    address public  contractManager;
    uint256 public  targetAmount;
    bool    public  isLimitLocked = true;
    uint8   internal constant _decimals = 9;

    event TargetAmountUpdated (uint256 targetAmount);
    event BeneficiaryUpdated (address beneficiary);

    constructor (IERC20 token_, address _manager, address _beneficiary, uint256 _targetAmount, bool _isMutable)  {
 
        _token = token_;
        contractManager = _manager;
        beneficiary = _beneficiary;
        targetAmount = _targetAmount;
        isMutable = _isMutable;

        _setupRole(Contract_Manager, contractManager);
        _setupRole(Financial_Controller, contractManager);
        _setupRole(Compliance_Auditor, contractManager);
        _setRoleAdmin(Financial_Controller, Contract_Manager);
        _setRoleAdmin(Compliance_Auditor, Contract_Manager);

    }

    function changeBeneficiary (address _newBeneficiary) external onlyRole(Compliance_Auditor) {
        require (isMutable, "This contract is immutable.");
        require (hasRole(Financial_Controller, _newBeneficiary),"Beneficiary without the needed role");
        beneficiary = _newBeneficiary;
        emit BeneficiaryUpdated(beneficiary);
    }

    function setTargetAmount (uint256 _targetAmount) external onlyRole(Compliance_Auditor)  {
        require (isMutable, "This contract is immutable.");
        targetAmount  = _targetAmount*10**_decimals;
        emit TargetAmountUpdated(targetAmount);
    }

    function setLimitLocked (bool _newStatus) external onlyRole(Financial_Controller) {
        isLimitLocked = _newStatus;
    }


    function releaseVaultReserves() external onlyRole(Financial_Controller) {
        uint256 _balanceVault = _token.balanceOf(address(this));
        uint256 _releaseValue;
        if (isLimitLocked) {
            require(_balanceVault >= targetAmount, "Vault Reserves below limit");
            _releaseValue = targetAmount;
        } else {
            require(_balanceVault >= targetAmount.mul(3).div(10), "Vault Reserves below limit");
            _releaseValue = _balanceVault.mul(_balanceVault).div(targetAmount);
            if (_releaseValue > _balanceVault) {_releaseValue = _balanceVault;}
        }
        _token.safeTransfer(beneficiary, _releaseValue);
    }

}