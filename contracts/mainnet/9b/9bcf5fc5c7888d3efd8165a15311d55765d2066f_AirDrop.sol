pragma solidity ^0.4.18;

contract ERC20Interface {
    // Get the total token supply
    function totalSupply() public constant returns (uint256 supply);

    // Get the account balance of another a ccount with address _owner
    function balanceOf(address _owner) public constant returns (uint256 balance);

    // Send _value amount of tokens to address _to
    function transfer(address _to, uint256 _value) public returns (bool success);

    // Send _value amount of tokens from address _from to address _to
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);

    // Allow _spender to withdraw from your account, multiple times, up to the _value amount.
    // If this function is called again it overwrites the current allowance with _value.
    // this function is required for some DEX functionality
    function approve(address _spender, uint256 _value) public returns (bool success);

    // Returns the amount which _spender is still allowed to withdraw from _owner
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);

    // Triggered when tokens are transferred.
    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    // Triggered whenever approve(address _spender, uint256 _value) is called.
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract AirDrop
{
    address public owner;
    address public executor;
    
    // Constructor
    function AirDrop() public {
        owner = msg.sender;
        executor = msg.sender;
    }
    
    // Functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferExecutor(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        executor = newOwner;
    }
    
    // Functions with this modifier can only be executed by the owner
    modifier onlyExecutor() {
        require(msg.sender == executor || msg.sender == owner);
        _;
    }
    
    function MultiTransfer(address _tokenAddr, address[] dests, uint256[] values) public onlyExecutor
    {
        uint256 i = 0;
        ERC20Interface T = ERC20Interface(_tokenAddr);
        while (i < dests.length) {
            T.transfer(dests[i], values[i]);
            i += 1;
        }
    }
}