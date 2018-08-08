pragma solidity ^0.4.11;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
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

contract IcoPhaseManagement {
    using SafeMath for uint256;
    
    /* Defines whether or not we are in the ICO phase */
    bool public icoPhase = true;

    /* Defines whether or not the ICO has been abandoned */
    bool public icoAbandoned = false;

    /* Defines whether or not the SIFT contract address has yet been set.  */
    bool siftContractDefined = false;
    
    /* Defines the sale price during ICO */
    uint256 constant icoUnitPrice = 10 finney;

    /* If an ICO is abandoned and some withdrawals fail then this map allows people to request withdrawal of locked-in ether. */
    mapping(address => uint256) public abandonedIcoBalances;

    /* Defines our interface to the SIFT contract. */
    SmartInvestmentFundToken smartInvestmentFundToken;

    /* Defines the admin contract we interface with for credentails. */
    AuthenticationManager authenticationManager;

    /* Defines the time that the ICO starts. */
    uint256 constant public icoStartTime = 1501545600; // August 1st 2017 at 00:00:00 UTC

    /* Defines the time that the ICO ends. */
    uint256 constant public icoEndTime = 1505433600; // September 15th 2017 at 00:00:00 UTC

    /* Defines our event fired when the ICO is closed */
    event IcoClosed();

    /* Defines our event fired if the ICO is abandoned */
    event IcoAbandoned(string details);
    
    /* Ensures that once the ICO is over this contract cannot be used until the point it is destructed. */
    modifier onlyDuringIco {
        bool contractValid = siftContractDefined && !smartInvestmentFundToken.isClosed();
        if (!contractValid || (!icoPhase && !icoAbandoned)) throw;
        _;
    }

    /* This modifier allows a method to only be called by current admins */
    modifier adminOnly {
        if (!authenticationManager.isCurrentAdmin(msg.sender)) throw;
        _;
    }

    /* Create the ICO phase managerment and define the address of the main SIFT contract. */
    function IcoPhaseManagement(address _authenticationManagerAddress) {
        /* A basic sanity check */
        if (icoStartTime >= icoEndTime)
            throw;

        /* Setup access to our other contracts and validate their versions */
        authenticationManager = AuthenticationManager(_authenticationManagerAddress);
        if (authenticationManager.contractVersion() != 100201707171503)
            throw;
    }

    /* Set the SIFT contract address as a one-time operation.  This happens after all the contracts are created and no
       other functionality can be used until this is set. */
    function setSiftContractAddress(address _siftContractAddress) adminOnly {
        /* This can only happen once in the lifetime of this contract */
        if (siftContractDefined)
            throw;

        /* Setup access to our other contracts and validate their versions */
        smartInvestmentFundToken = SmartInvestmentFundToken(_siftContractAddress);
        if (smartInvestmentFundToken.contractVersion() != 500201707171440)
            throw;
        siftContractDefined = true;
    }

    /* Gets the contract version for validation */
    function contractVersion() constant returns(uint256) {
        /* ICO contract identifies as 300YYYYMMDDHHMM */
        return 300201707171440;
    }

    /* Close the ICO phase and transition to execution phase */
    function close() adminOnly onlyDuringIco {
        // Forbid closing contract before the end of ICO
        if (now <= icoEndTime)
            throw;

        // Close the ICO
        icoPhase = false;
        IcoClosed();

        // Withdraw funds to the caller
        if (!msg.sender.send(this.balance))
            throw;
    }
    
    /* Handle receiving ether in ICO phase - we work out how much the user has bought, allocate a suitable balance and send their change */
    function () onlyDuringIco payable {
        // Forbid funding outside of ICO
        if (now < icoStartTime || now > icoEndTime)
            throw;

        /* Determine how much they&#39;ve actually purhcased and any ether change */
        uint256 tokensPurchased = msg.value / icoUnitPrice;
        uint256 purchaseTotalPrice = tokensPurchased * icoUnitPrice;
        uint256 change = msg.value.sub(purchaseTotalPrice);

        /* Increase their new balance if they actually purchased any */
        if (tokensPurchased > 0)
            smartInvestmentFundToken.mintTokens(msg.sender, tokensPurchased);

        /* Send change back to recipient */
        if (change > 0 && !msg.sender.send(change))
            throw;
    }

    /* Abandons the ICO and returns funds to shareholders.  Any failed funds can be separately withdrawn once the ICO is abandoned. */
    function abandon(string details) adminOnly onlyDuringIco {
        // Forbid closing contract before the end of ICO
        if (now <= icoEndTime)
            throw;

        /* If already abandoned throw an error */
        if (icoAbandoned)
            throw;

        /* Work out a refund per share per share */
        uint256 paymentPerShare = this.balance / smartInvestmentFundToken.totalSupply();

        /* Enum all accounts and send them refund */
        uint numberTokenHolders = smartInvestmentFundToken.tokenHolderCount();
        uint256 totalAbandoned = 0;
        for (uint256 i = 0; i < numberTokenHolders; i++) {
            /* Calculate how much goes to this shareholder */
            address addr = smartInvestmentFundToken.tokenHolder(i);
            uint256 etherToSend = paymentPerShare * smartInvestmentFundToken.balanceOf(addr);
            if (etherToSend < 1)
                continue;

            /* Allocate appropriate amount of fund to them */
            abandonedIcoBalances[addr] = abandonedIcoBalances[addr].add(etherToSend);
            totalAbandoned = totalAbandoned.add(etherToSend);
        }

        /* Audit the abandonment */
        icoAbandoned = true;
        IcoAbandoned(details);

        // There should be no money left, but withdraw just incase for manual resolution
        uint256 remainder = this.balance.sub(totalAbandoned);
        if (remainder > 0)
            if (!msg.sender.send(remainder))
                // Add this to the callers balance for emergency refunds
                abandonedIcoBalances[msg.sender] = abandonedIcoBalances[msg.sender].add(remainder);
    }

    /* Allows people to withdraw funds that failed to send during the abandonment of the ICO for any reason. */
    function abandonedFundWithdrawal() {
        // This functionality only exists if an ICO was abandoned
        if (!icoAbandoned || abandonedIcoBalances[msg.sender] == 0)
            throw;
        
        // Attempt to send them to funds
        uint256 funds = abandonedIcoBalances[msg.sender];
        abandonedIcoBalances[msg.sender] = 0;
        if (!msg.sender.send(funds))
            throw;
    }
}

/* The SIFT itself is a simple extension of the ERC20 that allows for granting other SIFT contracts special rights to act on behalf of all transfers. */
contract SmartInvestmentFundToken {
    using SafeMath for uint256;

    /* Map all our our balances for issued tokens */
    mapping (address => uint256) balances;

    /* Map between users and their approval addresses and amounts */
    mapping(address => mapping (address => uint256)) allowed;

    /* List of all token holders */
    address[] allTokenHolders;

    /* The name of the contract */
    string public name;

    /* The symbol for the contract */
    string public symbol;

    /* How many DPs are in use in this contract */
    uint8 public decimals;

    /* Defines the current supply of the token in its own units */
    uint256 totalSupplyAmount = 0;

    /* Defines the address of the ICO contract which is the only contract permitted to mint tokens. */
    address public icoContractAddress;

    /* Defines whether or not the fund is closed. */
    bool public isClosed;

    /* Defines the contract handling the ICO phase. */
    IcoPhaseManagement icoPhaseManagement;

    /* Defines the admin contract we interface with for credentails. */
    AuthenticationManager authenticationManager;

    /* Fired when the fund is eventually closed. */
    event FundClosed();
    
    /* Our transfer event to fire whenever we shift SMRT around */
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    /* Our approval event when one user approves another to control */
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /* Create a new instance of this fund with links to other contracts that are required. */
    function SmartInvestmentFundToken(address _icoContractAddress, address _authenticationManagerAddress) {
        // Setup defaults
        name = "Smart Investment Fund Token";
        symbol = "SIFT";
        decimals = 0;

        /* Setup access to our other contracts and validate their versions */
        icoPhaseManagement = IcoPhaseManagement(_icoContractAddress);
        if (icoPhaseManagement.contractVersion() != 300201707171440)
            throw;
        authenticationManager = AuthenticationManager(_authenticationManagerAddress);
        if (authenticationManager.contractVersion() != 100201707171503)
            throw;
        
        /* Store our special addresses */
        icoContractAddress = _icoContractAddress;
    }

    modifier onlyPayloadSize(uint numwords) {
        assert(msg.data.length == numwords * 32 + 4);
        _;
    } 

    /* This modifier allows a method to only be called by account readers */
    modifier accountReaderOnly {
        if (!authenticationManager.isCurrentAccountReader(msg.sender)) throw;
        _;
    }

    modifier fundSendablePhase {
        // If it&#39;s in ICO phase, forbid it
        if (icoPhaseManagement.icoPhase())
            throw;

        // If it&#39;s abandoned, forbid it
        if (icoPhaseManagement.icoAbandoned())
            throw;

        // We&#39;re good, funds can now be transferred
        _;
    }

    /* Gets the contract version for validation */
    function contractVersion() constant returns(uint256) {
        /* SIFT contract identifies as 500YYYYMMDDHHMM */
        return 500201707171440;
    }
    
    /* Transfer funds between two addresses that are not the current msg.sender - this requires approval to have been set separately and follows standard ERC20 guidelines */
    function transferFrom(address _from, address _to, uint256 _amount) fundSendablePhase onlyPayloadSize(3) returns (bool) {
        if (balances[_from] >= _amount && allowed[_from][msg.sender] >= _amount && _amount > 0 && balances[_to].add(_amount) > balances[_to]) {
            bool isNew = balances[_to] == 0;
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            if (isNew)
                tokenOwnerAdd(_to);
            if (balances[_from] == 0)
                tokenOwnerRemove(_from);
            Transfer(_from, _to, _amount);
            return true;
        }
        return false;
    }

    /* Returns the total number of holders of this currency. */
    function tokenHolderCount() accountReaderOnly constant returns (uint256) {
        return allTokenHolders.length;
    }

    /* Gets the token holder at the specified index. */
    function tokenHolder(uint256 _index) accountReaderOnly constant returns (address) {
        return allTokenHolders[_index];
    }
 
    /* Adds an approval for the specified account to spend money of the message sender up to the defined limit */
    function approve(address _spender, uint256 _amount) fundSendablePhase onlyPayloadSize(2) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

    /* Gets the current allowance that has been approved for the specified spender of the owner address */
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    /* Gets the total supply available of this token */
    function totalSupply() constant returns (uint256) {
        return totalSupplyAmount;
    }

    /* Gets the balance of a specified account */
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    /* Transfer the balance from owner&#39;s account to another account */
    function transfer(address _to, uint256 _amount) fundSendablePhase onlyPayloadSize(2) returns (bool) {
        /* Check if sender has balance and for overflows */
        if (balances[msg.sender] < _amount || balances[_to].add(_amount) < balances[_to])
            return false;

        /* Do a check to see if they are new, if so we&#39;ll want to add it to our array */
        bool isRecipientNew = balances[_to] < 1;

        /* Add and subtract new balances */
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);

        /* Consolidate arrays if they are new or if sender now has empty balance */
        if (isRecipientNew)
            tokenOwnerAdd(_to);
        if (balances[msg.sender] < 1)
            tokenOwnerRemove(msg.sender);

        /* Fire notification event */
        Transfer(msg.sender, _to, _amount);
        return true;
    }

    /* If the specified address is not in our owner list, add them - this can be called by descendents to ensure the database is kept up to date. */
    function tokenOwnerAdd(address _addr) internal {
        /* First check if they already exist */
        uint256 tokenHolderCount = allTokenHolders.length;
        for (uint256 i = 0; i < tokenHolderCount; i++)
            if (allTokenHolders[i] == _addr)
                /* Already found so we can abort now */
                return;
        
        /* They don&#39;t seem to exist, so let&#39;s add them */
        allTokenHolders.length++;
        allTokenHolders[allTokenHolders.length - 1] = _addr;
    }

    /* If the specified address is in our owner list, remove them - this can be called by descendents to ensure the database is kept up to date. */
    function tokenOwnerRemove(address _addr) internal {
        /* Find out where in our array they are */
        uint256 tokenHolderCount = allTokenHolders.length;
        uint256 foundIndex = 0;
        bool found = false;
        uint256 i;
        for (i = 0; i < tokenHolderCount; i++)
            if (allTokenHolders[i] == _addr) {
                foundIndex = i;
                found = true;
                break;
            }
        
        /* If we didn&#39;t find them just return */
        if (!found)
            return;
        
        /* We now need to shuffle down the array */
        for (i = foundIndex; i < tokenHolderCount - 1; i++)
            allTokenHolders[i] = allTokenHolders[i + 1];
        allTokenHolders.length--;
    }

    /* Mint new tokens - this can only be done by special callers (i.e. the ICO management) during the ICO phase. */
    function mintTokens(address _address, uint256 _amount) onlyPayloadSize(2) {
        /* Ensure we are the ICO contract calling */
        if (msg.sender != icoContractAddress || !icoPhaseManagement.icoPhase())
            throw;

        /* Mint the tokens for the new address*/
        bool isNew = balances[_address] == 0;
        totalSupplyAmount = totalSupplyAmount.add(_amount);
        balances[_address] = balances[_address].add(_amount);
        if (isNew)
            tokenOwnerAdd(_address);
        Transfer(0, _address, _amount);
    }
}