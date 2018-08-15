pragma solidity ^0.4.24;

/**
 * @title Teambrella Approver
 */

interface IApprover {
    function isAllowed(address _addr) external returns (bool);
}

contract Approver is IApprover {
    
    address public m_owner;
    mapping (address => bool) allowed;
    
    modifier onlyOwner {
        require(msg.sender == m_owner);
        _; 
    }
    
    constructor() public payable {
		m_owner = msg.sender;
    }
    
    function allow(address _addr, bool _allow) onlyOwner external {
        allowed[_addr] = _allow;
    }
    
    function isAllowed(address _addr) public constant returns (bool) {
        return allowed[_addr];
    }
}