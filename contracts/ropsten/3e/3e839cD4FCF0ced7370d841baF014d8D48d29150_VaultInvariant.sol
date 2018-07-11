pragma solidity ^0.4.24;

contract VaultInvariant {
    mapping(address => uint) public balances;
    uint totalBalance;

    /// @dev Store ETH in the contract.
    function store() payable public{
        balances[msg.sender]+=msg.value;
        totalBalance+=msg.value;
    }
    
    /// @dev Redeem your ETH.
    function redeem() public{
        uint toTranfer = balances[msg.sender];
        msg.sender.transfer(toTranfer);
        balances[msg.sender]=0;
        totalBalance-=toTranfer;
    }
    
    /// @dev Let a user get all funds if an invariant is broken.
    function invariantBroken() public{
        require(totalBalance!=this.balance);
        
        msg.sender.transfer(this.balance);
    }
    }