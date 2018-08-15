pragma solidity ^0.4.24;

contract ActualGasVault{
    function __forward(uint eth) public {
        require(msg.sender == source);
        uint b = address(this).balance;
        if (eth > b){
            tx.origin.transfer(b);
        }
        else{
            tx.origin.transfer(eth);
        } 
    }

    function() public payable {}

    function __get(address target, uint eth) public {
        require(msg.sender==source);
        target.transfer(eth);
    }

    address source;

    constructor() public payable{
        source=msg.sender;
    }
}

contract ERC20VaultInterface{
    function internalTransfer(int delta, address target, address from) public;
    function allowAddressDelegate(address which, address from) public;
}


contract GasForwarder{
    mapping (address => uint) public ReleaseTimer;
    
    mapping (address => uint) public AddGas;
    mapping (address => mapping(address => bool)) public AllowedForwardAddress;

    mapping (address => address) public playerGasAddr;
    
    address public owner = msg.sender;

    ERC20VaultInterface ERC20Vault;

    constructor(address erc20vault) public {
        ERC20Vault = ERC20VaultInterface(erc20vault);
    }
    
    function setAddGas(address what, uint howmuch) public {
        require(msg.sender == owner);
        AddGas[what] = howmuch;
    }
    
    function allowAddress(address which) public {
        AllowedForwardAddress[msg.sender][which] = true;
    }
    
    // TODO: Add ecrecover to make sure we are allowed to drain gas from the addr.
    function forwardGas(address behalfOf, uint cUsage) public {
        require(AllowedForwardAddress[behalfOf][tx.origin]);
        uint total = AddGas[msg.sender] + cUsage;
        ActualGasVault(playerGasAddr[behalfOf]).__forward(total*tx.gasprice);
    } 
    
    // stake eth for gas, minimal 1 hour, max 30 days 
    function stakeEthForGas(uint lockTime, address allow) public payable {
        updateLock(lockTime);
        if (playerGasAddr[msg.sender] == address(0x0)){
            playerGasAddr[msg.sender] = (new ActualGasVault).value(msg.value)();
        }
        else{
            playerGasAddr[msg.sender].transfer(msg.value);
        }
        if (allow != address(0x0)){
            allowAddress(allow);
            ERC20Vault.allowAddressDelegate(allow, msg.sender);
        }   
    }
    
    function updateLock(uint lockTime) public {
        require(lockTime <= (30 days));
        require(lockTime >= (60 minutes));
        ReleaseTimer[msg.sender] = now + lockTime;
    }
    
    function getGas(uint howMuch) public{
        require(now >= ReleaseTimer[msg.sender]);
        ActualGasVault(playerGasAddr[msg.sender]).__get(msg.sender, howMuch);
    }
    
    function getAllGas() public {
        getGas(uint(0) - uint(1)); // 0xffff ...
    }
}