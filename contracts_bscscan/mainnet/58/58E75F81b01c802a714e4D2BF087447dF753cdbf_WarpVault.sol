//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "./Context.sol";
import "./Address.sol";
import "./SafeERC20.sol";
import "./AccessControl.sol";

//    Interfaces   

import "./IERC20.sol";
import "./IERC20Metadata.sol";

//**********************************//
//    W  A  R  P  V  A  U  L  T  
//**********************************//
contract WarpVault is AccessControl {
    using SafeERC20 for IERC20;

    struct TokenInfo {
           uint256 targetBalance;
           bool    isLimitUnlocked;
           bool    isInitialized;
    }

    mapping (address => TokenInfo) internal vaultMapping;

    address public   beneficiary;
    address public   contractManager;
    bool    public   immutable isMutable;

    uint8 constant Contract_Manager     = 1;
    uint8 constant Financial_Controller = 11;
    uint8 constant Compliance_Auditor   = 12;

    event BalanceLimitUpdated   (address authorizer, uint256 targetBalance);
    event BeneficiaryUpdated    (address authorizer, address beneficiary);
    event VaultReservesReleased (address authorizer, address token, address beneficiary, uint256 _releasedValue);
    event CoinBalanceReleased   (address authorizer, address beneficiary, uint256 _releasedValue);
    event Tokeninitialized      (address _token, uint256 _targetBalance, bool _isLimitUnlocked );

    constructor (address _manager, address _beneficiary, bool _isMutable)  {
        contractManager = _manager;
        beneficiary     = _beneficiary;
        isMutable       = _isMutable;

        _setupRole(Contract_Manager,     contractManager);
        _setupRole(Financial_Controller, contractManager);
        _setupRole(Compliance_Auditor,   contractManager);

        _setRoleAdmin(Contract_Manager,     Contract_Manager);
        _setRoleAdmin(Financial_Controller, Contract_Manager);
        _setRoleAdmin(Compliance_Auditor,   Contract_Manager);
    }

    function initializeToken(address _token, uint256 _targetBalance, bool _isLimitUnlocked ) external onlyRole(Financial_Controller) {
        require (!vaultMapping[_token].isInitialized, "Token already initialized");
        require (_targetBalance > 0, "Limit invalid");
        vaultMapping[_token].targetBalance      = _targetBalance * (10**IERC20Metadata(_token).decimals());
        vaultMapping[_token].isLimitUnlocked    = _isLimitUnlocked;
        vaultMapping[_token].isInitialized      = true;
        emit Tokeninitialized (_token, _targetBalance, _isLimitUnlocked );
    }

    function changeBeneficiary (address _newBeneficiary) external onlyRole(Compliance_Auditor) {
        require (isMutable, "This contract is immutable.");
        require (hasRole(Financial_Controller, _newBeneficiary),"Beneficiary without the needed role");
        beneficiary = _newBeneficiary;
        emit BeneficiaryUpdated (_msgSender(), beneficiary);
    }

    function changeBalanceLimit (address _token, uint256 _targetBalance) external onlyRole(Compliance_Auditor)  {
        require (isMutable, "This contract is immutable.");
        require (vaultMapping[_token].isInitialized, "Token is not initialized");
        require (_targetBalance > 0, "Limit invalid");
        vaultMapping[_token].targetBalance      = _targetBalance * (10**IERC20Metadata(_token).decimals());
        emit BalanceLimitUpdated (_msgSender(), _targetBalance );
    }

    function setLimitUnlocked (address _token, bool _newStatus) external onlyRole(Financial_Controller) {
        require (vaultMapping[_token].isInitialized, "Token is not initialized");
        vaultMapping[_token].isLimitUnlocked = _newStatus;
    }

    function tokenParams (address _token) external view returns (uint256, bool) {
        require (vaultMapping[_token].isInitialized, "Token is not initialized");        
        return  (vaultMapping[_token].targetBalance / (10**IERC20Metadata(_token).decimals()), vaultMapping[_token].isLimitUnlocked );  
    }
    
    function releaseVaultReserves(address _token) external onlyRole(Financial_Controller) {
        require (vaultMapping[_token].isInitialized, "Token is not initialized");
        uint256 _balanceVault = IERC20(_token).balanceOf(address(this));
        uint256 _releaseValue;
        if (vaultMapping[_token].isLimitUnlocked) {
            uint256 minBalance = vaultMapping[_token].targetBalance / 5;
            require(_balanceVault >= minBalance, "Vault Reserves below limit");
            _releaseValue = (_balanceVault * _balanceVault) / vaultMapping[_token].targetBalance;
            _releaseValue = (_releaseValue > _balanceVault) ?  _balanceVault : _releaseValue;
        } else {
            require(_balanceVault >= vaultMapping[_token].targetBalance, "Vault Reserves below limit");
            _releaseValue = vaultMapping[_token].targetBalance;
        }
        IERC20(_token).safeTransfer(beneficiary, _releaseValue);
        emit VaultReservesReleased (_msgSender(), address(_token), beneficiary, _releaseValue);
    }

    function releaseCoinBalance () external onlyRole(Financial_Controller) {
        uint256 amountToRelease = address(this).balance;
        require(amountToRelease > 0, "The Balance must be greater than 0");

        payable(beneficiary).transfer(amountToRelease);
        emit CoinBalanceReleased (_msgSender(), beneficiary, amountToRelease);
    }

}