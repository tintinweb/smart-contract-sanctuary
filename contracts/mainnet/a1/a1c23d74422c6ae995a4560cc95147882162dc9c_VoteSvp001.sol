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
contract VotingBase {
    using SafeMath for uint256;

    /* Map all our our balances for issued tokens */
    mapping (address => uint256) public voteCount;

    /* List of all token holders */
    address[] public voterAddresses;

    /* Defines the admin contract we interface with for credentails. */
    AuthenticationManager internal authenticationManager;

    /* Unix epoch voting starts at */
    uint256 public voteStartTime;

    /* Unix epoch voting ends at */
    uint256 public voteEndTime;

    /* This modifier allows a method to only be called by current admins */
    modifier adminOnly {
        if (!authenticationManager.isCurrentAdmin(msg.sender)) throw;
        _;
    }

    function setVoterCount(uint256 _count) adminOnly {
        // Forbid after voting has started
        if (now >= voteStartTime)
            throw;

        /* Clear existing voter count */
        for (uint256 i = 0; i < voterAddresses.length; i++) {
            address voter = voterAddresses[i];
            voteCount[voter] = 0;
        }

        /* Set the count accordingly */
        voterAddresses.length = _count;
    }

    function setVoter(uint256 _position, address _voter, uint256 _voteCount) adminOnly {
        // Forbid after voting has started
        if (now >= voteStartTime)
            throw;

        if (_position >= voterAddresses.length)
            throw;
            
        voterAddresses[_position] = _voter;
        voteCount[_voter] = _voteCount;
    }
}

contract VoteSvp001 is VotingBase {
    using SafeMath for uint256;

    /* Votes for SVP001-01.  0 = not votes, 1 = Yes, 2 = No */
     mapping (address => uint256) vote01;
     uint256 public vote01YesCount;
     uint256 public vote01NoCount;

    /* Votes for SVP001-02.  0 = not votes, 1 = Yes, 2 = No */
     mapping (address => uint256) vote02;
     uint256 public vote02YesCount;
     uint256 public vote02NoCount;

    /* Create our contract with references to other contracts as required. */
    function VoteSvp001(address _authenticationManagerAddress, uint256 _voteStartTime, uint256 _voteEndTime) {
        /* Setup access to our other contracts and validate their versions */
        authenticationManager = AuthenticationManager(_authenticationManagerAddress);
        if (authenticationManager.contractVersion() != 100201707171503)
            throw;

        /* Store start/end times */
        if (_voteStartTime >= _voteEndTime)
            throw;
        voteStartTime = _voteStartTime;
        voteEndTime = _voteEndTime;
    }

     function voteSvp01(bool vote) {
        // Forbid outside of voting period
        if (now < voteStartTime || now > voteEndTime)
            throw;

         /* Ensure they have voting rights first */
         uint256 voteWeight = voteCount[msg.sender];
         if (voteWeight == 0)
            throw;
        
        /* Set their vote */
        uint256 existingVote = vote01[msg.sender];
        uint256 newVote = vote ? 1 : 2;
        if (newVote == existingVote)
            /* No change so just return */
            return;
        vote01[msg.sender] = newVote;

        /* If they had voted previous first decrement previous vote count */
        if (existingVote == 1)
            vote01YesCount -= voteWeight;
        else if (existingVote == 2)
            vote01NoCount -= voteWeight;
        if (vote)
            vote01YesCount += voteWeight;
        else
            vote01NoCount += voteWeight;
     }

     function voteSvp02(bool vote) {
        // Forbid outside of voting period
        if (now < voteStartTime || now > voteEndTime)
            throw;

         /* Ensure they have voting rights first */
         uint256 voteWeight = voteCount[msg.sender];
         if (voteWeight == 0)
            throw;
        
        /* Set their vote */
        uint256 existingVote = vote02[msg.sender];
        uint256 newVote = vote ? 1 : 2;
        if (newVote == existingVote)
            /* No change so just return */
            return;
        vote02[msg.sender] = newVote;

        /* If they had voted previous first decrement previous vote count */
        if (existingVote == 1)
            vote02YesCount -= voteWeight;
        else if (existingVote == 2)
            vote02NoCount -= voteWeight;
        if (vote)
            vote02YesCount += voteWeight;
        else
            vote02NoCount += voteWeight;
     }
}