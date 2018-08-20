pragma solidity ^0.4.24;

pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error.
 */
library SafeMath {
    // Multiplies two numbers, throws on overflow./
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) return 0;
        c = a * b;
        assert(c / a == b);
        return c;
    }
    // Integer division of two numbers, truncating the quotient.
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    // Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    // Adds two numbers, throws on overflow.
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


/**
 * @title _1010_Mining_ distribution-contract (50/25/25)
 */
contract _1010_Mining_ {
    using SafeMath for uint256;
    
    // -------------------------------------------------------------------------
    // Variables
    // -------------------------------------------------------------------------
    
    struct Member {
        uint256 share;                               // Percent of mining profits
        uint256 unpaid;                              // Available Wei for withdrawal, + 1 in storage for gas optimization
    }                                              
    mapping (address => Member) public members;      // All contract members as &#39;Member&#39;-struct
    
    uint16    public memberCount;                    // Count of all members
    address[] public memberIndex;                    // Lookuptable of all member addresses to iterate on deposit over and assign unpaid Ether to members
    
    
    // -------------------------------------------------------------------------
    // Private functions, can only be called by this contract
    // -------------------------------------------------------------------------
    
    function _addMember (address _member, uint256 _share) private {
        emit AddMember(_member, _share);
        members[_member].share = _share;
        members[_member].unpaid = 1;
        memberIndex.push(_member);
        memberCount++;
    }
    
    
    // -------------------------------------------------------------------------
    // Constructor
    // -------------------------------------------------------------------------
    
    constructor () public {
        // Initialize members with their share (total 100) and trigger &#39;AddMember&#39;-event
        _addMember(0xd2Ce719a0d00f4f8751297aD61B0E936970282E1, 50);
        _addMember(0xE517CB63e4dD36533C26b1ffF5deB893E63c3afA, 25);
        _addMember(0x430e1dd1ab2E68F201B53056EF25B9e116979D9b, 25);
    }
    
    
    // -------------------------------------------------------------------------
    // Events
    // -------------------------------------------------------------------------
    
    event AddMember(address indexed member, uint256 share);
    event Withdraw(address indexed member, uint256 value);
    event Deposit(address indexed from, uint256 value);
    
    
    // -------------------------------------------------------------------------
    // Public external interface
    // -------------------------------------------------------------------------
    
    function () external payable {
        // Distribute deposited Ether to all members related to their profit-share
        for (uint i=0; i<memberIndex.length; i++) {
            members[memberIndex[i]].unpaid = 
                // Adding current deposit to members unpaid Wei amount
                members[memberIndex[i]].unpaid.add(
                    // MemberShare * DepositedWei / 100 = WeiAmount of member-share to be added to members unpaid holdings
                    members[memberIndex[i]].share.mul(msg.value).div(100)
                );
        }
        
        // Trigger &#39;Deposit&#39;-event
        emit Deposit(msg.sender, msg.value);
    }
    
    function withdraw () external { 
        // Pre-validate withdrawal
        require(members[msg.sender].unpaid > 1, "No unpaid balance or not a member account");
        
        // Remember members unpaid amount but remove it from his contract holdings before initiating the withdrawal for security reasons
        uint256 unpaid = members[msg.sender].unpaid.sub(1);
        members[msg.sender].unpaid = 1;
        
        // Trigger &#39;Withdraw&#39;-event
        emit Withdraw(msg.sender, unpaid);
        
        // Transfer the unpaid Wei amount to member address
        msg.sender.transfer(unpaid);
    }
    
    function unpaid () public view returns (uint256) {
        // Get unpaid Wei amount of member
        return members[msg.sender].unpaid.sub(1);
    }
    
    function member () public view returns (bool) {
        // Get member-state (true or false)
        return members[msg.sender].unpaid >= 1;
    }
    
    
}