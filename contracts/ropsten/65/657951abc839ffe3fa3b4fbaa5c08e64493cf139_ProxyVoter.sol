pragma solidity ^0.4.0;

contract TrustGraph {
    
    struct VoterInfo {
        bool exists;
        uint8 vote;
        string explanation;
        /// You can trust up to 5 people.
        string[5] trusted;
        /// An index into trusted.
        uint8 trusted_index;
    }
    
    struct VoterName {
        bool exists;
        string name;
    }
    
    /// The name of the issue (e.g., &quot;SenateBill123&quot;).
    string m_issueName;
    /// The creator of the issue.
    address m_creator;
    /// A mapping from name to information for a given voter.
    mapping(string => VoterInfo) m_voters;
    /// A mapping from address to name.
    mapping (address => VoterName) m_names;

    constructor(string issueName) public {
        m_issueName = issueName;
        m_creator = msg.sender;
    }

    /// Register to vote, and indicate who you trust.
    function register(string name) public {
        VoterInfo storage sender = m_voters[name];
        if (sender.exists) {
            revert();
        }
        
        VoterName storage voter_name = m_names[msg.sender];
        if (voter_name.exists) {
            revert();
        }
        
        voter_name.exists = true;
        voter_name.name = name;
        
        sender.exists = true;
        sender.vote = 0;
    }
    
    function addToTrusted(string trustee) public {
        VoterName storage voter_name = m_names[msg.sender];
        VoterInfo storage sender = m_voters[voter_name.name];
        if (!voter_name.exists) {
            revert();
        }
        
        if (sender.trusted_index >= 5) {
            revert();
        }
        
        sender.trusted[sender.trusted_index] = trustee;
        sender.trusted_index += 1;
    }
    
    function vote(uint8 choice) public {
        VoterName storage voter_name = m_names[msg.sender];
        VoterInfo storage sender = m_voters[voter_name.name];
        if (!voter_name.exists) {
            revert();
        }
        
        sender.vote = choice;
    }
    
    function getVote(string name) public constant returns (uint8 _vote) {
        VoterInfo storage sender = m_voters[name];
        if (!sender.exists) {
            revert();
        }
        
        if (sender.vote != 0) {
            _vote = sender.vote;
            return _vote;
        }
        
        if (sender.trusted_index == 0) {
            revert();
        }
        
        return getVote(sender.trusted[sender.trusted_index - 1]);
    }
}

contract ProxyVoter {
    TrustGraph tg;
    
    constructor(address _t) public {
        tg = TrustGraph(_t);
    }
    
    function register(string name) public {
        return tg.register(name);
    }
    
    function addToTrusted(string trustee) public {
        return tg.addToTrusted(trustee);
    }
    
    function vote(uint8 choice) public {
        return tg.vote(choice);
    }
}