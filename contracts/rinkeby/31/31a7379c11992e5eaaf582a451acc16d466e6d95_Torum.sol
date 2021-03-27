/**
 *Submitted for verification at Etherscan.io on 2021-03-26
*/

pragma solidity ^0.4.24;


contract EternalStorage {

    mapping(bytes32 => uint256) internal uintStorage;
    mapping(bytes32 => string) internal stringStorage;
    mapping(bytes32 => address) internal addressStorage;
    mapping(bytes32 => bytes) internal bytesStorage;
    mapping(bytes32 => bool) internal boolStorage;
    mapping(bytes32 => int256) internal intStorage;

}

contract Ownable is EternalStorage {
    
    event OwnershipTransferred(address previousOwner, address newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner());
        _;
    }

    function owner() public view returns (address) {
        return addressStorage[keccak256(abi.encodePacked("owner"))];
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        setOwner(newOwner);
    }

    function setOwner(address newOwner) internal {
        emit OwnershipTransferred(owner(), newOwner);
        addressStorage[keccak256(abi.encodePacked("owner"))] = newOwner;
    }
}



contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}


contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}


contract Torum is ERC20Interface, SafeMath, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals; 
    
    uint256 public _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    struct OffchainMetaData {
        address offChainAddress;
        uint tokenAmount;
    }
    
    uint public index;
    address public onChainBridge;
    
    mapping(address => OffchainMetaData) public offchainMetaData;
    
    
    constructor() public {
        name = "TTT";
        symbol = "TTT";
        decimals = 18;
        _totalSupply = 1000000000000000000000000000;
        
        balances[msg.sender] = _totalSupply;
        index = 0;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }
    
    function totalSupply() public view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }
    
    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }
    
    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function approve(address spender, uint tokens) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    
    function transfer(address to, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }
    
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function setOnChainBridge(address onChainBridgeAddress) public onlyOwner returns (bool success) {
        onChainBridge = onChainBridgeAddress;
        return true;
    }
    
    function createMetaData(address offChainAddress, uint tokenAmount) public {
        OffchainMetaData memory offchainMetaDataSample  = OffchainMetaData(offChainAddress, tokenAmount);
        offchainMetaData[msg.sender] = offchainMetaDataSample;
        index++;
    }
    
    function getMetaData(address inputAddress) public view returns (address, uint) {
        return (offchainMetaData[inputAddress].offChainAddress, offchainMetaData[inputAddress].tokenAmount);
    }
    
    function transferToBridge(address offChainAddress, uint tokens) public returns (bool success) {
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[onChainBridge] = safeAdd(balances[onChainBridge], tokens);
        createMetaData(offChainAddress, tokens);
        emit Transfer(msg.sender, onChainBridge, tokens);
        return true;
    }
}