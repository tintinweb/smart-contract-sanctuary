pragma solidity ^0.4.24;

// ----------------------------------------------------------------------------
// &#39;BBT&#39; &#39;International Blockchain Bank & Trust&#39;  Blockchain Vault Contract
// Working Version
// (c) by A. Valamontes with doecoins / Geopay.me Inc 2018. The MIT Licence.
// ----------------------------------------------------------------------------
// Use SafeMath to protect from overflows
// ----------------------------------------------------------------------------
// A common problem when dealing with numeric operations is the risk of overflow.
// An overflow/underflow happens when an arithmetic operation reach the maximum 
// or minimum size of the type. For example if you store your number in the uint256
// type, it means your number will be stored in a 256 bits unsigned number ranging 
// from 0 to 2^256. In computer programming, an integer overflow occurs when an 
// arithmetic operation attempts to create a numeric value that is outside of the 
// range that can be represented with a given number of bits – either larger than 
// the maximum or lower than the minimum representable value.
// ----------------------------------------------------------------------------
// This could happen whenever you are doing arithmetic operations such as [+], [-], [*].
// When using the SafeMath library, the results of this operations will be checked 
// and an error will be thrown stopping the execution of your smart contract.
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


contract BlockchainBank is SafeMath {

/* -------- State data -------- */

// Owner
    address private _owner;
    uint256 private _bankDonationsBalance = 0;
    bool private _connectBankAccountToNewOwnerAddressEnabled = true;

// Bank accounts    
    struct BankAccount
    {
// Members placed in order for optimization, not readability
        bool passwordSha3HashSet;
        uint32 number; 
        uint32 passwordAttempts;
        uint256 balance;
        address owner;       
        bytes32 passwordSha3Hash;   
        mapping(bytes32 => bool) passwordSha3HashesUsed;
    }   

    struct BankAccountAddress
    {
        bool accountSet;
        uint32 accountNumber; // accountNumber member is used to index the bank accounts array
    }
 
    uint32 private _totalBankAccounts = 0;
    BankAccount[] private _bankAccountsArray; 
    mapping(address => BankAccountAddress) private _bankAccountAddresses;  


/* -------- Constructor -------- */

    constructor() public
    {
// Set the contract owner
        _owner = msg.sender; 
    }


/* -------- Events -------- */

// Donation
    event event_donationMadeToBank_ThankYou(uint256 donationAmount);
    event event_getBankDonationsBalance(uint256 donationBalance);
    event event_bankDonationsWithdrawn(uint256 donationsAmount);

// General banking
    event event_bankAccountOpened_Successful(address indexed bankAccountOwner, uint32 indexed bankAccountNumber, uint256 indexed depositAmount);
    event event_getBankAccountNumber_Successful(uint32 indexed bankAccountNumber);
    event event_getBankAccountBalance_Successful(uint32 indexed bankAccountNumber, uint256 indexed balance);
    event event_depositMadeToBankAccount_Successful(uint32 indexed bankAccountNumber, uint256 indexed depositAmount); 
    event event_depositMadeToBankAccount_Failed(uint32 indexed bankAccountNumber, uint256 indexed depositAmount); 
    event event_depositMadeToBankAccountFromDifferentAddress_Successful(uint32 indexed bankAccountNumber, address indexed addressFrom, uint256 indexed depositAmount);
    event event_depositMadeToBankAccountFromDifferentAddress_Failed(uint32 indexed bankAccountNumber, address indexed addressFrom, uint256 indexed depositAmount);
    event event_withdrawalMadeFromBankAccount_Successful(uint32 indexed bankAccountNumber, uint256 indexed withdrawalAmount); 
    event event_withdrawalMadeFromBankAccount_Failed(uint32 indexed bankAccountNumber, uint256 indexed withdrawalAmount); 
    event event_transferMadeFromBankAccountToAddress_Successful(uint32 indexed bankAccountNumber, uint256 indexed transferalAmount, address indexed destinationAddress); 
    event event_transferMadeFromBankAccountToAddress_Failed(uint32 indexed bankAccountNumber, uint256 indexed transferalAmount, address indexed destinationAddress); 

// Security
    event event_securityConnectingABankAccountToANewOwnerAddressIsDisabled();
    event event_securityHasPasswordSha3HashBeenAddedToBankAccount_Yes(uint32 indexed bankAccountNumber);
    event event_securityHasPasswordSha3HashBeenAddedToBankAccount_No(uint32 indexed bankAccountNumber);
	event event_securityPasswordSha3HashAddedToBankAccount_Successful(uint32 indexed bankAccountNumber);
    event event_securityPasswordSha3HashAddedToBankAccount_Failed_PasswordHashPreviouslyUsed(uint32 indexed bankAccountNumber);
    event event_securityBankAccountConnectedToNewAddressOwner_Successful(uint32 indexed bankAccountNumber, address indexed newAddressOwner);
    event event_securityBankAccountConnectedToNewAddressOwner_Failed_PasswordHashHasNotBeenAddedToBankAccount(uint32 indexed bankAccountNumber);
    event event_securityBankAccountConnectedToNewAddressOwner_Failed_SentPasswordDoesNotMatchAccountPasswordHash(uint32 indexed bankAccountNumber, uint32 indexed passwordAttempts);
    event event_securityGetNumberOfAttemptsToConnectBankAccountToANewOwnerAddress(uint32 indexed bankAccountNumber, uint32 indexed attempts);


/* -------- Modifiers -------- */

    modifier modifier_isContractOwner()
    { 
        // Contact owner?
        if (msg.sender != _owner)
        {
            revert();       
        }
    _;
    }

    modifier modifier_doesSenderHaveABankAccount() 
    { 
// Does this sender have a bank account?
        if (_bankAccountAddresses[msg.sender].accountSet == false)
        {
            revert();
        }
        else
        {
// Does the bank account owner address match the sender address?
            uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber;
            if (msg.sender != _bankAccountsArray[accountNumber_].owner)
            {
// Sender address previously had a bank account that was transfered to a new owner address
                revert();        
            }
        _;
        }
    }

    modifier modifier_wasValueSent()
    {        
// Value sent?
        if (msg.value > 0)
        {
// Prevent users from sending value accidentally
            revert();        
        }
    _;
    }
/* -------- Contract owner functions -------- */

    function Donate() public payable
    {
        if (msg.value > 0)
        {
            _bankDonationsBalance += msg.value;
            emit event_donationMadeToBank_ThankYou(msg.value);
        }
    }

    function BankOwner_GetDonationsBalance() public      
        modifier_isContractOwner()
        modifier_wasValueSent()
        returns (uint256)
    {
        emit event_getBankDonationsBalance(_bankDonationsBalance);
  	    return _bankDonationsBalance;
    }

    function BankOwner_WithdrawDonations() public
        modifier_isContractOwner()
        modifier_wasValueSent()
    { 
        if (_bankDonationsBalance > 0)
        {
            uint256 amount_ = _bankDonationsBalance;
            _bankDonationsBalance = 0;

// Check if using send() is successful
            if (msg.sender.send(amount_))
            {
                emit event_bankDonationsWithdrawn(amount_);
            }
// Check if using call.value() is successful
            else if (msg.sender.call.value(amount_)())
            {  
                emit event_bankDonationsWithdrawn(amount_);
            }
            else
            {
// Set the previous balance
                _bankDonationsBalance = amount_;
            }
        }
    }

    function BankOwner_EnableConnectBankAccountToNewOwnerAddress() public
        modifier_isContractOwner()
    { 
        if (_connectBankAccountToNewOwnerAddressEnabled == false)
        {
            _connectBankAccountToNewOwnerAddressEnabled = true;
        }
    }

    function  BankOwner_DisableConnectBankAccountToNewOwnerAddress() public
        modifier_isContractOwner()
    { 
        if (_connectBankAccountToNewOwnerAddressEnabled)
        {
            _connectBankAccountToNewOwnerAddressEnabled = false;
        }
    }


/* -------- General bank account functions -------- */

// Open bank account
    function OpenBankAccount() public payable
        returns (uint32 newBankAccountNumber) 
    {
// Does this sender already have a bank account or a previously used address for a bank account?
        if (_bankAccountAddresses[msg.sender].accountSet)
        {
            revert();
        }

// Assign the new bank account number
        newBankAccountNumber = _totalBankAccounts;

// Add new bank account to the array
        _bankAccountsArray.push( 
            BankAccount(
            {
                passwordSha3HashSet: false,
                passwordAttempts: 0,
                number: newBankAccountNumber,
                balance: 0,
                owner: msg.sender,
                passwordSha3Hash: 0
            }
            ));

// Prevent people using "password" or "Password" sha3 hash for the Security_AddPasswordSha3HashToBankAccount() function
        bytes32 passwordHash_ = keccak256("password");
        _bankAccountsArray[newBankAccountNumber].passwordSha3HashesUsed[passwordHash_] = true;
        passwordHash_ = keccak256("Password");
        _bankAccountsArray[newBankAccountNumber].passwordSha3HashesUsed[passwordHash_] = true;

// Add the new account
        _bankAccountAddresses[msg.sender].accountSet = true;
        _bankAccountAddresses[msg.sender].accountNumber = newBankAccountNumber;

// Value sent?
        if (msg.value > 0)
        {         
            _bankAccountsArray[newBankAccountNumber].balance += msg.value;
        }

// Move to the next bank account
        _totalBankAccounts++;

// Event
        emit event_bankAccountOpened_Successful(msg.sender, newBankAccountNumber, msg.value);
        return newBankAccountNumber;
    }

// Get account number from a owner address
    function GetBankAccountNumber() public      
        modifier_doesSenderHaveABankAccount()
        modifier_wasValueSent()
        returns (uint32)
    {
        emit event_getBankAccountNumber_Successful(_bankAccountAddresses[msg.sender].accountNumber);
	    return _bankAccountAddresses[msg.sender].accountNumber;
    }

    function GetBankAccountBalance() public
        modifier_doesSenderHaveABankAccount()
        modifier_wasValueSent()
        returns (uint256)
    {   
        uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber;
        emit event_getBankAccountBalance_Successful(accountNumber_, _bankAccountsArray[accountNumber_].balance);
        return _bankAccountsArray[accountNumber_].balance;
    }


/* -------- Deposit functions -------- */

    function DepositToBankAccount() public payable
        modifier_doesSenderHaveABankAccount()
        returns (bool)
    {
        // Value sent?
        if (msg.value > 0)
        {
            uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber; 

// Check for overflow  
            if ((_bankAccountsArray[accountNumber_].balance + msg.value) < _bankAccountsArray[accountNumber_].balance)
            {
                revert();
            }

            _bankAccountsArray[accountNumber_].balance += msg.value; 
            emit event_depositMadeToBankAccount_Successful(accountNumber_, msg.value);
            return true;
        }
        else
        {
            emit event_depositMadeToBankAccount_Failed(accountNumber_, msg.value);
            return false;
        }
    }

    function DepositToBankAccountFromDifferentAddress(uint32 bankAccountNumber) public payable
        returns (bool)
    {
// Check if bank account number is valid
        if (bankAccountNumber >= _totalBankAccounts)
        {
           emit event_depositMadeToBankAccountFromDifferentAddress_Failed(bankAccountNumber, msg.sender, msg.value);
           return false;     
        }    
            
// Value sent?
        if (msg.value > 0)
        {   
 // Check for overflow  
            if ((_bankAccountsArray[bankAccountNumber].balance + msg.value) < _bankAccountsArray[bankAccountNumber].balance)
            {
                revert();
            }

            _bankAccountsArray[bankAccountNumber].balance += msg.value; 
            emit event_depositMadeToBankAccountFromDifferentAddress_Successful(bankAccountNumber, msg.sender, msg.value);
            return true;
        }
        else
        {
            emit event_depositMadeToBankAccountFromDifferentAddress_Failed(bankAccountNumber, msg.sender, msg.value);
            return false;
        }
    }
    

/* -------- Withdrawal / transfer functions -------- */

    function WithdrawAmountFromBankAccount(uint256 amount) public
        modifier_doesSenderHaveABankAccount()
        modifier_wasValueSent()
        returns (bool)
    {
        bool withdrawalSuccessful_ = false;
        uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber; 

// Bank account has value that can be withdrawn?
        if (amount > 0 && _bankAccountsArray[accountNumber_].balance >= amount)
        {
// Reduce the account balance 
            _bankAccountsArray[accountNumber_].balance -= amount;

// Check if using send() is successful
            if (msg.sender.send(amount))
            {
 	            withdrawalSuccessful_ = true;
            }
// Check if using call.value() is successful
            else if (msg.sender.call.value(amount)())
            {  
                withdrawalSuccessful_ = true;
            }  
            else
            {
// Set the previous balance
                _bankAccountsArray[accountNumber_].balance += amount;
            }
        }

        if (withdrawalSuccessful_)
        {
            emit event_withdrawalMadeFromBankAccount_Successful(accountNumber_, amount); 
            return true;
        }
        else
        {
            emit event_withdrawalMadeFromBankAccount_Failed(accountNumber_, amount); 
            return false;
        }
    }

    function WithdrawFullBalanceFromBankAccount() public
        modifier_doesSenderHaveABankAccount()
        modifier_wasValueSent()
        returns (bool)
    {
        bool withdrawalSuccessful_ = false;
        uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber; 
        uint256 fullBalance_ = 0;

// Bank account has value that can be withdrawn?
        if (_bankAccountsArray[accountNumber_].balance > 0)
        {
            fullBalance_ = _bankAccountsArray[accountNumber_].balance;

// Reduce the account balance 
            _bankAccountsArray[accountNumber_].balance = 0;

// Check if using send() is successful
            if (msg.sender.send(fullBalance_))
            {
 	            withdrawalSuccessful_ = true;
            }
// Check if using call.value() is successful
            else if (msg.sender.call.value(fullBalance_)())
            {  
                withdrawalSuccessful_ = true;
            }  
            else
            {
// Set the previous balance
                _bankAccountsArray[accountNumber_].balance = fullBalance_;
            }
        }  

        if (withdrawalSuccessful_)
        {
            emit event_withdrawalMadeFromBankAccount_Successful(accountNumber_, fullBalance_); 
            return true;
        }
        else
        {
            emit event_withdrawalMadeFromBankAccount_Failed(accountNumber_, fullBalance_); 
            return false;
        }
    }

    function TransferAmountFromBankAccountToAddress(uint256 amount, address destinationAddress) public
        modifier_doesSenderHaveABankAccount()
        modifier_wasValueSent()
        returns (bool)
    {
        bool transferSuccessful_ = false; 
        uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber; 

// Bank account has value that can be transfered?
        if (amount > 0 && _bankAccountsArray[accountNumber_].balance >= amount)
        {
// Reduce the account balance 
            _bankAccountsArray[accountNumber_].balance -= amount; 

// Check if using send() is successful
            if (destinationAddress.send(amount))
            {
 	            transferSuccessful_ = true;
            }
// Check if using call.value() is successful
            else if (destinationAddress.call.value(amount)())
            {  
                transferSuccessful_ = true;
            }  
            else
            {
// Set the previous balance
                _bankAccountsArray[accountNumber_].balance += amount;
            }
        }  

        if (transferSuccessful_)
        {
            emit event_transferMadeFromBankAccountToAddress_Successful(accountNumber_, amount, destinationAddress); 
            return true;
        }
        else
        {
            emit event_transferMadeFromBankAccountToAddress_Failed(accountNumber_, amount, destinationAddress); 
            return false;
        }
    }


/* -------- Security functions -------- */

    function Security_HasPasswordSha3HashBeenAddedToBankAccount() public
        modifier_doesSenderHaveABankAccount()
        modifier_wasValueSent()
        returns (bool)
    {
        uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber; 

// Password sha3 hash added to the account?
        if (_bankAccountsArray[accountNumber_].passwordSha3HashSet)
        {
            emit event_securityHasPasswordSha3HashBeenAddedToBankAccount_Yes(accountNumber_);
            return true;
        }
        else
        {
            emit event_securityHasPasswordSha3HashBeenAddedToBankAccount_No(accountNumber_);
            return false;
        }
    }

    function Security_AddPasswordSha3HashToBankAccount(bytes32 sha3Hash) public
        modifier_doesSenderHaveABankAccount()
        modifier_wasValueSent()
        returns (bool)
    {
// VERY IMPORTANT -
// 
// Ethereum uses KECCAK256. It should be noted that it does not follow the FIPS-202 based standard (a.k.a SHA-3), 
// which was finalized in August 2015.
// 
// Keccak256 generator link (produces same output as solidity sha3()) 
// Encrypt the plain password -> http://emn178.github.io/online-tools/keccak_256.html
            
        uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber; 

// Has this password hash been used before for this account?
        if (_bankAccountsArray[accountNumber_].passwordSha3HashesUsed[sha3Hash] == true)
        {
            emit event_securityPasswordSha3HashAddedToBankAccount_Failed_PasswordHashPreviouslyUsed(accountNumber_);
            return false;        
        }

// Set the account password sha3 hash
        _bankAccountsArray[accountNumber_].passwordSha3HashSet = true;
        _bankAccountsArray[accountNumber_].passwordSha3Hash = sha3Hash;
        _bankAccountsArray[accountNumber_].passwordSha3HashesUsed[sha3Hash] = true;

// Reset password attempts
        _bankAccountsArray[accountNumber_].passwordAttempts = 0;

        emit event_securityPasswordSha3HashAddedToBankAccount_Successful(accountNumber_);
        return true;
    }

    function Security_ConnectBankAccountToNewOwnerAddress(uint32 bankAccountNumber, string password) public
        modifier_wasValueSent()
        returns (bool)
    {
// VERY IMPORTANT -
// 
// Ethereum uses KECCAK-256. It should be noted that it does not follow the FIPS-202 based standard (a.k.a SHA-3), 
// which was finalized in August 2015.
// 
// Keccak-256 generator link (produces same output as solidity sha3()) - http://emn178.github.io/online-tools/keccak_256.html

// Can bank accounts be connected to a new owner address?
        if (_connectBankAccountToNewOwnerAddressEnabled == false)
        {
            emit event_securityConnectingABankAccountToANewOwnerAddressIsDisabled();
            return false;        
        }

// Check if bank account number is valid
        if (bankAccountNumber >= _totalBankAccounts)
        {
            return false;     
        }    

// Does the sender already have a bank account?
        if (_bankAccountAddresses[msg.sender].accountSet)
        {
// A owner address can only have one bank account
            return false;
        }

// Has password sha3 hash been set?
        if (_bankAccountsArray[bankAccountNumber].passwordSha3HashSet == false)
        {
            emit event_securityBankAccountConnectedToNewAddressOwner_Failed_PasswordHashHasNotBeenAddedToBankAccount(bankAccountNumber);
            return false;           
        }

// Check if the password sha3 hash matches.
        bytes memory passwordString = bytes(password);
        if (keccak256(passwordString) != _bankAccountsArray[bankAccountNumber].passwordSha3Hash)
        {
// Keep track of the number of attempts to connect a bank account to a new owner address
            _bankAccountsArray[bankAccountNumber].passwordAttempts++;  
            emit event_securityBankAccountConnectedToNewAddressOwner_Failed_SentPasswordDoesNotMatchAccountPasswordHash(bankAccountNumber, _bankAccountsArray[bankAccountNumber].passwordAttempts); 
            return false;        
        }

// Set new bank account address owner and the update the owner address details 
        _bankAccountsArray[bankAccountNumber].owner = msg.sender;
        _bankAccountAddresses[msg.sender].accountSet = true;
        _bankAccountAddresses[msg.sender].accountNumber = bankAccountNumber;

// Reset password sha3 hash
        _bankAccountsArray[bankAccountNumber].passwordSha3HashSet = false;
        _bankAccountsArray[bankAccountNumber].passwordSha3Hash = "0";
       
// Reset password attempts
        _bankAccountsArray[bankAccountNumber].passwordAttempts = 0;

        emit event_securityBankAccountConnectedToNewAddressOwner_Successful(bankAccountNumber, msg.sender);
        return true;
    }

    function Security_GetNumberOfAttemptsToConnectBankAccountToANewOwnerAddress() public
        modifier_doesSenderHaveABankAccount()
        modifier_wasValueSent()
        returns (uint64)
    {
        uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber; 
        emit event_securityGetNumberOfAttemptsToConnectBankAccountToANewOwnerAddress(accountNumber_, _bankAccountsArray[accountNumber_].passwordAttempts);
        return _bankAccountsArray[accountNumber_].passwordAttempts;
    }


/* -------- Default function -------- */

    function() public payable 
    {    
// Does this sender have a bank account?
        if (_bankAccountAddresses[msg.sender].accountSet)
        {
 // Does the bank account owner address match the sender address?
            uint32 accountNumber_ = _bankAccountAddresses[msg.sender].accountNumber;
            address accountOwner_ = _bankAccountsArray[accountNumber_].owner;
            if (msg.sender == accountOwner_) 
            {
// Value sent?
                if (msg.value > 0)
                {                
// Check for overflow
                    if ((_bankAccountsArray[accountNumber_].balance + msg.value) < _bankAccountsArray[accountNumber_].balance)
                    {
                        revert();
                    }
 
// Update the bank account balance
                    _bankAccountsArray[accountNumber_].balance += msg.value;
                    emit event_depositMadeToBankAccount_Successful(accountNumber_, msg.value);
                }
                else
                {
                    revert();
                }
            }
            else
            {
// Sender address previously had a bank account that was transfered to a new owner address
                revert();
            }
        }
        else
        {
// Open a new bank account for the sender address - this function will also add any value sent to the bank account balance
            OpenBankAccount();
        }
    }
}