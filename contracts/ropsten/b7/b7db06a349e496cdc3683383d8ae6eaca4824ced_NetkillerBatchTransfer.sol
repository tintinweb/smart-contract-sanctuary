pragma solidity ^0.4.24;

contract ERC20 {
    uint256 public totalSupply;
    uint public decimals;
    function balanceOf(address _owner) constant public returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
}

contract NetkillerBatchTransfer {
    address public owner;
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    constructor() public {
        owner = msg.sender;
        //address _contractAddress
    }
    
    function transferOwnership(address newOwner) onlyOwner public {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
    
    function batchTransfer(address _token, address[] _to, uint256 _value) onlyOwner public returns (bool success){
        
        ERC20 token = ERC20(_token);
        uint256 value = _value * 10**uint256(token.decimals());
        
        uint count = _to.length;
        uint256 amount = value * uint256(count);
        
        require(value > 0 && token.balanceOf(this) >= amount);
        
        for (uint i=0; i<_to.length; i++) {
            token.transfer(_to[i], value);
        }
        
        return true;
    }
}