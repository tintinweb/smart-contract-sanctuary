pragma solidity ^0.4.11;

/* The authentication manager details user accounts that have access to certain priviledges and keeps a permanent ledger of who has and has had these rights. */
contract AuthenticationManager {
    /* Map addresses to admins */
    mapping (address => bool) adminAddresses;

    /* Map addresses to account readers */
    mapping (address => bool) accountReaderAddresses;

    /* Details of all admins that have ever existed */
    address[] adminAudit;

    /* Details of all account readers that have ever existed */
    address[] accountReaderAudit;

    /* Fired whenever an admin is added to the contract. */
    event AdminAdded(address addedBy, address admin);

    /* Fired whenever an admin is removed from the contract. */
    event AdminRemoved(address removedBy, address admin);

    /* Fired whenever an account-reader contract is added. */
    event AccountReaderAdded(address addedBy, address account);

    /* Fired whenever an account-reader contract is removed. */
    event AccountReaderRemoved(address removedBy, address account);

    /* When this contract is first setup we use the creator as the first admin */    
    function AuthenticationManager() {
        /* Set the first admin to be the person creating the contract */
        adminAddresses[msg.sender] = true;
        AdminAdded(0, msg.sender);
        adminAudit.length++;
        adminAudit[adminAudit.length - 1] = msg.sender;
    }

    /* Gets the contract version for validation */
    function contractVersion() constant returns(uint256) {
        // Admin contract identifies as 100YYYYMMDDHHMM
        return 100201707171503;
    }

    /* Gets whether or not the specified address is currently an admin */
    function isCurrentAdmin(address _address) constant returns (bool) {
        return adminAddresses[_address];
    }

    /* Gets whether or not the specified address has ever been an admin */
    function isCurrentOrPastAdmin(address _address) constant returns (bool) {
        for (uint256 i = 0; i < adminAudit.length; i++)
            if (adminAudit[i] == _address)
                return true;
        return false;
    }

    /* Gets whether or not the specified address is currently an account reader */
    function isCurrentAccountReader(address _address) constant returns (bool) {
        return accountReaderAddresses[_address];
    }

    /* Gets whether or not the specified address has ever been an admin */
    function isCurrentOrPastAccountReader(address _address) constant returns (bool) {
        for (uint256 i = 0; i < accountReaderAudit.length; i++)
            if (accountReaderAudit[i] == _address)
                return true;
        return false;
    }

    /* Adds a user to our list of admins */
    function addAdmin(address _address) {
        /* Ensure we&#39;re an admin */
        if (!isCurrentAdmin(msg.sender))
            throw;

        // Fail if this account is already admin
        if (adminAddresses[_address])
            throw;
        
        // Add the user
        adminAddresses[_address] = true;
        AdminAdded(msg.sender, _address);
        adminAudit.length++;
        adminAudit[adminAudit.length - 1] = _address;
    }

    /* Removes a user from our list of admins but keeps them in the history audit */
    function removeAdmin(address _address) {
        /* Ensure we&#39;re an admin */
        if (!isCurrentAdmin(msg.sender))
            throw;

        /* Don&#39;t allow removal of self */
        if (_address == msg.sender)
            throw;

        // Fail if this account is already non-admin
        if (!adminAddresses[_address])
            throw;

        /* Remove this admin user */
        adminAddresses[_address] = false;
        AdminRemoved(msg.sender, _address);
    }

    /* Adds a user/contract to our list of account readers */
    function addAccountReader(address _address) {
        /* Ensure we&#39;re an admin */
        if (!isCurrentAdmin(msg.sender))
            throw;

        // Fail if this account is already in the list
        if (accountReaderAddresses[_address])
            throw;
        
        // Add the user
        accountReaderAddresses[_address] = true;
        AccountReaderAdded(msg.sender, _address);
        accountReaderAudit.length++;
        accountReaderAudit[adminAudit.length - 1] = _address;
    }

    /* Removes a user/contracts from our list of account readers but keeps them in the history audit */
    function removeAccountReader(address _address) {
        /* Ensure we&#39;re an admin */
        if (!isCurrentAdmin(msg.sender))
            throw;

        // Fail if this account is already not in the list
        if (!accountReaderAddresses[_address])
            throw;

        /* Remove this admin user */
        accountReaderAddresses[_address] = false;
        AccountReaderRemoved(msg.sender, _address);
    }
}

/* The transparency relayer contract is responsible for keeping an immutable ledger of account balances that can be audited at a later time .*/
contract TransparencyRelayer {
    /* Represents what SIFT administration report the fund as being worth at a snapshot moment in time. */
    struct FundValueRepresentation {
        uint256 usdValue;
        uint256 etherEquivalent;
        uint256 suppliedTimestamp;
        uint256 blockTimestamp;
    }

    /* Represents a published balance of a particular account at a moment in time. */
    struct AccountBalanceRepresentation {
        string accountType; /* Bitcoin, USD, etc. */
        string accountIssuer; /* Kraken, Bank of America, etc. */
        uint256 balance; /* Rounded to appropriate for balance - i.e. full USD or full BTC */
        string accountReference; /* Could be crypto address, bank account number, etc. */
        string validationUrl; /* Some validation URL - i.e. base64 encoded notary */
        uint256 suppliedTimestamp;
        uint256 blockTimestamp;
    }

    /* An array defining all the fund values as supplied by SIFT over the time of the contract. */
    FundValueRepresentation[] public fundValues;
    
    /* An array defining the history of account balances over time. */
    AccountBalanceRepresentation[] public accountBalances;

    /* Defines the admin contract we interface with for credentails. */
    AuthenticationManager authenticationManager;

    /* Fired when the fund value is updated by an administrator. */
    event FundValue(uint256 usdValue, uint256 etherEquivalent, uint256 suppliedTimestamp, uint256 blockTimestamp);

    /* Fired when an account balance is being supplied in some confirmed form for future validation on the blockchain. */
    event AccountBalance(string accountType, string accountIssuer, uint256 balance, string accountReference, string validationUrl, uint256 timestamp, uint256 blockTimestamp);

    /* This modifier allows a method to only be called by current admins */
    modifier adminOnly {
        if (!authenticationManager.isCurrentAdmin(msg.sender)) throw;
        _;
    }

    /* Create our contract and specify the location of other addresses */
    function TransparencyRelayer(address _authenticationManagerAddress) {
        /* Setup access to our other contracts and validate their versions */
        authenticationManager = AuthenticationManager(_authenticationManagerAddress);
        if (authenticationManager.contractVersion() != 100201707171503)
            throw;
    }

    /* Gets the contract version for validation */
    function contractVersion() constant returns(uint256) {
        /* Transparency contract identifies as 200YYYYMMDDHHMM */
        return 200201707071127;
    }

    /* Returns how many fund values are present in the market. */
    function fundValueCount() constant returns (uint256 _count) {
        _count = fundValues.length;
    }

    /* Returns how account balances are present in the market. */
    function accountBalanceCount() constant returns (uint256 _count) {
        _count = accountBalances.length;
    }

    /* Defines the current value of the funds assets in USD and ETHER */
    function fundValuePublish(uint256 _usdTotalFund, uint256 _etherTotalFund, uint256 _definedTimestamp) adminOnly {
        /* Store values */
        fundValues.length++;
        fundValues[fundValues.length - 1] = FundValueRepresentation(_usdTotalFund, _etherTotalFund, _definedTimestamp, now);

        /* Audit this */
        FundValue(_usdTotalFund, _etherTotalFund, _definedTimestamp, now);
    }

    function accountBalancePublish(string _accountType, string _accountIssuer, uint256 _balance, string _accountReference, string _validationUrl, uint256 _timestamp) adminOnly {
        /* Store values */
        accountBalances.length++;
        accountBalances[accountBalances.length - 1] = AccountBalanceRepresentation(_accountType, _accountIssuer, _balance, _accountReference, _validationUrl, _timestamp, now);

        /* Audit this */
        AccountBalance(_accountType, _accountIssuer, _balance, _accountReference, _validationUrl, _timestamp, now);
    }
}