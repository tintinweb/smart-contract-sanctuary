pragma solidity ^0.4.18;

    /// @title Ownable

contract Ownable {
    address public owner;
    address public newOwnerCandidate;

    event OwnershipRequested(address indexed _by, address indexed _to);
    event OwnershipTransferred(address indexed _from, address indexed _to);

    /// @dev The Ownable constructor sets the original `owner` of the contract to the sender account.
    function Ownable() {
        owner = msg.sender;
    }

    /// @dev Throws if called by any account other than the owner.
    modifier onlyOwner() {
        if (msg.sender != owner) {
            throw;
        }
        _;
    }

    /// @dev Proposes to transfer control of the contract to a newOwnerCandidate.
    /// @param _newOwnerCandidate address The address to transfer ownership to.
    function transferOwnership(address _newOwnerCandidate) onlyOwner {
        require(_newOwnerCandidate != address(0));

        newOwnerCandidate = _newOwnerCandidate;

        OwnershipRequested(msg.sender, newOwnerCandidate);
    }

    /// @dev Accept ownership transfer. This method needs to be called by the perviously proposed owner.
    function acceptOwnership() {
        if (msg.sender == newOwnerCandidate) {
            owner = newOwnerCandidate;
            newOwnerCandidate = address(0);

            OwnershipTransferred(owner, newOwnerCandidate);
        }
    }
}

interface token {
    function transfer(address _to, uint256 _amount);
}

contract SafeTimeLock is Ownable {
    
    token public epm;
    
    uint256 public constant DURATION = 2 years;
    uint256 public startTime = 0;
    uint256 public endTime = 0;
    uint256 public remaining = 0;
    
    /**
     * Constructor function
     *
     */

    function SafeTimeLock() {
        epm = token(0xc5594d84B996A68326d89FB35E4B89b3323ef37d);
        startTime = now;
        endTime = startTime + DURATION;
    }
    
    function getRemainTime() public constant returns (uint256 remaining) {
        remaining = endTime - now;
    }
    
    modifier onlyOutTimeLock() {
        if (now < startTime || now <= endTime) {
            throw;
        }
        _;
    }
    
    function Withdrawal(uint amount) onlyOutTimeLock {
        epm.transfer(msg.sender, amount*10**18);
    }
}