/** 
 * Vault to secure funds from compromised keys without having to trust 3rd parties.
 * Created by 
**/

pragma solidity ^0.4.25;

contract CryptoVault {
    
    /** Structs **/
    struct Vault {
        bool vaultActive; // Whether or not the vault is active
        address fallbackAddress; // The fallback address if suspicion of account being compromised
        uint fallbackDepositWei; // Amount of wei to submit to invoke fallback from another account
        uint fallbackDepositPeriodSec; // Period to wait before new fallback desposit can be set
        uint balanceWei; // Amount of wei in the vault
        uint cumulativeAllowanceWei; // Amount of wei that can be transferred within a period
        uint allowancePeriodSec; // The period of which cumulativeAllowanceWei can be withdrawn without
        uint freeAllowanceWei; // Amount allowed to be spent within this allowance period
        uint allowanceExpirationSec; // Timestamp of when the current allowance period expires
        uint newAllowancesEffectuationSec; // Unix timestamp of when new allowances take effect
        uint newCumulativeAllowanceWei; // New cumulative allowance waiting to take effect
        uint newAllowancePeriodSec; // New allowance period waiting to take effect
        uint newFallbackDepositEffectuationSec; // Unix timestamp of when new fallback deposit takes effect
        uint newFallbackDepositWei; // New fallback desposit
        uint newFallbackDepositPeriodSec;
    }

    /** Global variables **/
    address cryptoVaultCreator; // Address that created the CryptoVault contract
    mapping(address => Vault) vaults;
    
    /** Events **/
    event Warning(string warningMsg, address vaultAddress, string incident, uint effectuation);
    event Notification(string notificationMsg);
    event Notification(string notificationMsg, address vaultAddress);
    event Notification(string notificationMsg, address vaultAddress, string incident);
    event Notification(string notificationMsg, address vaultAddress, uint uint1);
    event Notification(string notificationMsg, address vaultAddress, uint uint1, uint uint2);
    event Notification(string notificationMsg, address addressSender, address vaultAddress, uint uint1, uint uint2);
    event Notification(string notificationMsg, address addressSender, address addressBeneficiary, uint amountWei, uint newBalanceSender, uint newBalanceWeiBeneficiary);
    
    /** Constructor **/
    constructor(address _fallbackAddress, uint _fallbackDepositWei, uint _fallbackDepositPeriodSec, uint _cumulativeAllowanceWei, uint _allowancePeriodSec) public {
        cryptoVaultCreator = msg.sender; // Set admin as the contract creator
        /** Activate vault for cryptoVaultCreator **/
        vaults[msg.sender].fallbackAddress = _fallbackAddress;
        vaults[msg.sender].fallbackDepositWei = _fallbackDepositWei;
        vaults[msg.sender].fallbackDepositPeriodSec = _fallbackDepositPeriodSec;
        vaults[msg.sender].cumulativeAllowanceWei = _cumulativeAllowanceWei;
        vaults[msg.sender].allowancePeriodSec = _allowancePeriodSec;
        vaults[msg.sender].freeAllowanceWei = _cumulativeAllowanceWei;
        uint _allowanceExpirationSec = now + _allowancePeriodSec;
        require(_allowanceExpirationSec >= now); // Avoid overflow
        vaults[msg.sender].allowanceExpirationSec = _allowanceExpirationSec;
        vaults[msg.sender].newAllowancesEffectuationSec = now;
        vaults[msg.sender].newCumulativeAllowanceWei = _cumulativeAllowanceWei;
        vaults[msg.sender].newAllowancePeriodSec = _allowancePeriodSec;
        vaults[msg.sender].newFallbackDepositWei = _fallbackDepositWei;
        vaults[msg.sender].newFallbackDepositPeriodSec = _fallbackDepositPeriodSec;
        vaults[msg.sender].vaultActive = true;
        emit Notification("CryptoVault Contract created!", msg.sender);
    }
    
    /** Payables **/
    // Payable fallback
    function () external payable {
        revert(); // Don&#39;t accept funds by mistake.
    }
    
    // Activate vault
    function activateVault(address _fallbackAddress, uint _fallbackDepositWei, uint _fallbackDepositPeriodSec, uint _cumulativeAllowanceWei, uint _allowancePeriodSec) external payable returns (bool success) {
        require(!vaults[msg.sender].vaultActive);
        vaults[msg.sender].fallbackAddress = _fallbackAddress;
        vaults[msg.sender].fallbackDepositWei = _fallbackDepositWei;
        vaults[msg.sender].fallbackDepositPeriodSec = _fallbackDepositPeriodSec;
        vaults[msg.sender].balanceWei = msg.value;
        vaults[msg.sender].cumulativeAllowanceWei = _cumulativeAllowanceWei;
        vaults[msg.sender].allowancePeriodSec = _allowancePeriodSec;
        vaults[msg.sender].freeAllowanceWei = _cumulativeAllowanceWei;
        uint _allowanceExpirationSec = now + _allowancePeriodSec;
        require(_allowanceExpirationSec >= now); // Avoid overflow
        vaults[msg.sender].allowanceExpirationSec = _allowanceExpirationSec;
        vaults[msg.sender].newAllowancesEffectuationSec = now;
        vaults[msg.sender].newCumulativeAllowanceWei = _cumulativeAllowanceWei;
        vaults[msg.sender].newAllowancePeriodSec = _allowancePeriodSec;
        vaults[msg.sender].newFallbackDepositWei = _fallbackDepositWei;
        vaults[msg.sender].newFallbackDepositPeriodSec = _fallbackDepositPeriodSec;
        vaults[msg.sender].vaultActive = true;
        emit Notification("Vault activated!", msg.sender);
        return true;
    }
    
    // Deposit funds to own vault
    function depositFunds() external payable returns (bool success) {
        require(vaults[msg.sender].vaultActive);
        uint _newBalanceWei = vaults[msg.sender].balanceWei + msg.value;
        require(_newBalanceWei >= msg.value); // Avoid overflow
        vaults[msg.sender].balanceWei = _newBalanceWei;
        emit Notification("Deposit", msg.sender, msg.value, _newBalanceWei);
        return true;
    }
    
    // Deposit funds to someone else&#39;s vault
    function depositFunds(address _beneficiaryAddress) external payable returns (bool success) {
        require(vaults[_beneficiaryAddress].vaultActive);
        uint _newBalanceWei = vaults[_beneficiaryAddress].balanceWei + msg.value;
        require(_newBalanceWei >= msg.value); // Avoid overflow
        vaults[_beneficiaryAddress].balanceWei = _newBalanceWei;
        emit Notification("Deposit", msg.sender, _beneficiaryAddress, msg.value, _newBalanceWei);
        return true;
    }
    
    // Invoke fallback from other address (requires a deposit which is sent to the fallback address)
    function invokeFallback(address _vaultAddress) external payable returns (bool success) {
        require(vaults[_vaultAddress].vaultActive);
        require(vaults[_vaultAddress].balanceWei > 0);
        updateFallbackDeposit(); // Update falback deposit before checking if it transferred deposit is large enough
        if (msg.value < vaults[_vaultAddress].fallbackDepositWei) {
            revert();
        }
        uint _totalAmountWei = vaults[_vaultAddress].balanceWei + msg.value;
        require(_totalAmountWei >= msg.value); // Avoid overflow
        emit Warning("WARNING!", msg.sender, "Funds being withdrawn to fallback address.", _totalAmountWei); // Emit now to avoid out of gas resulting in funds being withdrawn without emitting a warning
        vaults[_vaultAddress].balanceWei = 0; // Update new balance
        vaults[msg.sender].vaultActive = false; // Deactivate vault
        vaults[_vaultAddress].fallbackAddress.transfer(_totalAmountWei); // Return amount in vault plus the deposit (deposit is returned to fallback to discourage misuse)
        return true;
    }
    
    // Function to donate to cryptoVaultCreator
    function donate() external payable returns (bool success) {
        require(msg.value > 0);
        uint _newBalanceWei = vaults[cryptoVaultCreator].balanceWei + msg.value;
        require(_newBalanceWei >= msg.value); // Avoid overflow
        vaults[cryptoVaultCreator].balanceWei = _newBalanceWei; // Credit cryptoVaultCreator&#39;s vault
        emit Notification("Thanks for the donation!", msg.sender, msg.value, _newBalanceWei);
        return true;
    }
    
    /** Primary functions **/
    // Change allowances
    function changeAllowances(uint _newCumulativeAllowanceWei, uint _newAllowancePeriodSec)  external returns (bool success) {
        require(vaults[msg.sender].vaultActive);
        updateAllowances(); // Update allowances before checking if they are up to date or pending
        if (now < vaults[msg.sender].newAllowancesEffectuationSec) {
            return false;
        }
        uint _newAllowancesEffectuationSec = now + vaults[msg.sender].allowancePeriodSec;
        require(_newAllowancesEffectuationSec >= now); // Avoid overflow
        emit Warning("WARNING!", msg.sender, "Changing allowances.", vaults[msg.sender].newAllowancesEffectuationSec); // Emit now to avoid out of gas resulting in changed allowance without emitting a warning
        vaults[msg.sender].newCumulativeAllowanceWei = _newCumulativeAllowanceWei;
        vaults[msg.sender].newAllowancePeriodSec = _newAllowancePeriodSec;
        vaults[msg.sender].newAllowancesEffectuationSec = _newAllowancesEffectuationSec;
        return true;
    }
    
    // Change fallback deposit
    function changeFallbackDeposit(uint _newFallbackDepositWei) external returns (bool success) {
        require(vaults[msg.sender].vaultActive);
        updateFallbackDeposit(); // Update falback deposit before checking if it is up to date or pending
        if (now < vaults[msg.sender].newFallbackDepositEffectuationSec) {
            return false;
        }
        uint _newFallbackDepositEffectuationSec = now + vaults[msg.sender].fallbackDepositPeriodSec;
        require(_newFallbackDepositEffectuationSec > now);
        emit Warning("WARNING!", msg.sender, "Changing fallback deposit.", vaults[msg.sender].newAllowancesEffectuationSec); // Emit now to avoid out of gas resulting in changed allowance without emitting a warning
        vaults[msg.sender].newFallbackDepositWei = _newFallbackDepositWei;
        vaults[msg.sender].newFallbackDepositEffectuationSec = _newFallbackDepositEffectuationSec;
        return true;
    }
    
    // Transfer funds from vault to someone else&#39;s vault
    function transferFunds(uint _amountWei, address _beneficiaryAddress) external returns (bool success) {
        require(vaults[_beneficiaryAddress].vaultActive); // Only transfer if beneficiary has a vault
        require(vaults[msg.sender].balanceWei >= _amountWei);
        uint _newBalanceWeiSender = vaults[msg.sender].balanceWei - _amountWei;
        updateAllowances(); // Update allowances before checking transaction is allowed
        uint _freeAllowanceWei = vaults[msg.sender].freeAllowanceWei;
        if (_amountWei > _freeAllowanceWei) {
            emit Warning("WARNING!", msg.sender, "Amount exceeding allowance tried to be transferred.", _amountWei);
            return false;
        }
        uint _newBalanceWeiBeneficiary = vaults[_beneficiaryAddress].balanceWei + _amountWei;
        require(_newBalanceWeiBeneficiary >= _amountWei);
        /** Update balances **/
        vaults[msg.sender].balanceWei = _newBalanceWeiSender; // Update sender&#39;s balance
        vaults[msg.sender].freeAllowanceWei = _freeAllowanceWei - _amountWei; // Update remaining allowance
        vaults[_beneficiaryAddress].balanceWei = _newBalanceWeiBeneficiary; // Update beneficiary&#39;s balance
        emit Notification("Funds transferred", msg.sender, _beneficiaryAddress, _amountWei, _newBalanceWeiSender, _newBalanceWeiBeneficiary);
        return true;
    }
    
    // Withdraw funds
    function withdrawFunds(uint _amountWei) external returns (bool success) {
        if (vaults[msg.sender].balanceWei < _amountWei) {
            emit Warning("WARNING!", msg.sender, "Amount exceeding balance tried to be withdrawn.", _amountWei);
            return false;
        }
        uint _newBalanceWei = vaults[msg.sender].balanceWei - _amountWei;
        updateAllowances(); // Update allowances before checking transaction is allowed
        uint _freeAllowanceWei = vaults[msg.sender].freeAllowanceWei;
        if (_amountWei > _freeAllowanceWei) {
            emit Warning("WARNING!", msg.sender, "Amount exceeding allowance tried to be withdrawn.", _amountWei);
            return false;
        }
        vaults[msg.sender].balanceWei = _newBalanceWei; // Update balance
        vaults[msg.sender].freeAllowanceWei = _freeAllowanceWei - _amountWei; // Update remaining allowance
        emit Notification("Withdrawal", msg.sender, _amountWei, _newBalanceWei);
        msg.sender.transfer(_amountWei);
        return true;
    }
    
    // Withdraw funds to specific address
    function withdrawFunds(uint _amountWei, address _beneficiaryAddress) external returns (bool success) {
        if (vaults[msg.sender].balanceWei < _amountWei) {
            emit Warning("WARNING!", msg.sender, "Amount exceeding balance tried to be withdrawn.", _amountWei);
            return false;
        }
        uint _newBalanceWei = vaults[msg.sender].balanceWei - _amountWei;
        updateAllowances(); // Update allowances before checking transaction is allowed
        uint _freeAllowanceWei = vaults[msg.sender].freeAllowanceWei;
        if (_amountWei > _freeAllowanceWei) {
            emit Warning("WARNING!", msg.sender, "Amount exceeding allowance tried to be withdrawn.", _amountWei);
            return false;
        }
        vaults[msg.sender].balanceWei = _newBalanceWei; // Update balance
        vaults[msg.sender].freeAllowanceWei = _freeAllowanceWei - _amountWei; // Update remaining allowance
        emit Notification("Withdrawal", msg.sender, _beneficiaryAddress, _amountWei, _newBalanceWei);
        _beneficiaryAddress.transfer(_amountWei);
        return true;
    }
    
    // Function to withdraw funds to fallback address
    function invokeFallback() external returns (bool success) {
        uint _amountWei = vaults[msg.sender].balanceWei; // Get current balance
        require(_amountWei > 0); // Require that there are funds in the vault
        emit Warning("WARNING!", msg.sender, "Funds being withdrawn to fallback address.", _amountWei);
        vaults[msg.sender].balanceWei = 0; // Update new balance
        vaults[msg.sender].vaultActive = false; // Deactivate vault
        vaults[msg.sender].fallbackAddress.transfer(_amountWei);
        return true;
    }
    
    /** View functions **/
    function getIsActive() external view returns (bool isActive) {
        return vaults[msg.sender].vaultActive;
    }
    
    function getIsActive(address _vaultAddress) external view returns (bool isActive) {
        return vaults[_vaultAddress].vaultActive;
    }
    
    function getBalance() external view returns (uint balanceWei) {
        return vaults[msg.sender].balanceWei;
    }
    
    function getFallbackAddress() external view returns (address fallbackAddress) {
        return vaults[msg.sender].fallbackAddress;
    }
    
    function getFallbackDeposit() external view returns (uint fallbackDepositWei) {
        return vaults[msg.sender].fallbackDepositWei;
    }
    
    function getFallbackDepositPeriod() external view returns (uint fallbackDepositPeriodSec) {
        return vaults[msg.sender].fallbackDepositPeriodSec;
    }
    
    function getCumulativeAllowance() external view returns (uint cumulativeAllowanceWei) {
        return vaults[msg.sender].cumulativeAllowanceWei;
    }
    
    function getAllowancePeriod() external view returns (uint allowancePeriodSec) {
        return vaults[msg.sender].allowancePeriodSec;
    }
    
    function getFreeAllowance() external view returns (uint freeAllowanceWei) {
        return vaults[msg.sender].freeAllowanceWei;
    }
    
    function getAllowanceExpiration() external view returns (uint allowanceExpirationSec) {
        return vaults[msg.sender].allowanceExpirationSec;
    }
    
    function getNewAllowancesEffectuation() external view returns (uint newAllowancesEffectuationSec) {
        return vaults[msg.sender].newAllowancesEffectuationSec;
    }
    
    function getNewCumulativeAllowance() external view returns (uint newCumulativeAllowanceWei) {
        return vaults[msg.sender].newCumulativeAllowanceWei;
    }
    
    function getNewAllowancePeriod() external view returns (uint newAllowancePeriodSec) {
        return vaults[msg.sender].newAllowancePeriodSec;
    }
    
    function getNewFallbackDepositEffectuation() external view returns (uint newFallbackDepositEffectuationSec) {
        return vaults[msg.sender].newFallbackDepositEffectuationSec;
    }
    
    function getNewFallbackDeposit() external view returns (uint newFallbackDepositWei) {
        return vaults[msg.sender].newFallbackDepositWei;
    }
    
    function getNewFallbackDepositPeriod() external view returns (uint newFallbackDepositPeriodSec) {
        return vaults[msg.sender].newFallbackDepositPeriodSec;
    }
    
    function getVaultBalance() external view returns (uint vaultBalance) {
        return address(this).balance;
    }
    
    /** Helper functions **/
    // Update allowance parameters
    function updateAllowances() public {
        if (now >= vaults[msg.sender].newAllowancesEffectuationSec) {
            vaults[msg.sender].cumulativeAllowanceWei = vaults[msg.sender].newCumulativeAllowanceWei;
            vaults[msg.sender].allowancePeriodSec = vaults[msg.sender].newAllowancePeriodSec;
            vaults[msg.sender].freeAllowanceWei = vaults[msg.sender].cumulativeAllowanceWei;
        }
        if (now >= vaults[msg.sender].allowanceExpirationSec) {
            uint _newAllowanceExpirationSec = now + vaults[msg.sender].allowancePeriodSec;
            require(_newAllowanceExpirationSec >= now); // Avoid overflow
            vaults[msg.sender].allowanceExpirationSec = _newAllowanceExpirationSec;
            vaults[msg.sender].freeAllowanceWei = vaults[msg.sender].cumulativeAllowanceWei;
        }
    }
    
    function updateFallbackDeposit() public {
        if (now >= vaults[msg.sender].newFallbackDepositEffectuationSec) {
            vaults[msg.sender].fallbackDepositWei = vaults[msg.sender].newFallbackDepositWei;
            vaults[msg.sender].fallbackDepositPeriodSec = vaults[msg.sender].newFallbackDepositPeriodSec;
        }
    }
}