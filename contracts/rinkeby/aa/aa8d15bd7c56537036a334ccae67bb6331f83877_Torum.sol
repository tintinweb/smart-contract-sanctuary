/**
 *Submitted for verification at Etherscan.io on 2021-03-27
*/

pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;


contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }
    
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
    function safeAdd(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    
    function safeSub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a); c = a - b; 
        
    } 
    
    function safeMul(uint a, uint b) internal pure returns (uint c) { 
        c = a * b; require(a == 0 || c / a == b); 
        
    } 
    
    function safeDiv(uint a, uint b) internal pure returns (uint c) { 
        require(b > 0);
        c = a / b;
    }
}


contract Torum is ERC20Interface, SafeMath, Ownable {
    string public name;
    string public symbol;
    uint8 public decimals; 
    
    uint256 internal _totalSupply;
    
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    struct OffchainMetaData {
        address[] offChainToAddress;
        uint256[] tokenAmount;
    }
    
    address public onChainBridgeAddress;
    mapping(address => OffchainMetaData) metaData;
    
    constructor() public {
        name = "Torum";
        symbol = "XTM";
        decimals = 18;
        _totalSupply = 1000000000000000000000000000;
        balances[msg.sender] = _totalSupply;
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
    
    function setOnChainBridgeAddress(address _onChainBridgeAddress) public onlyOwner returns (bool success) {
        require(_onChainBridgeAddress != address(0));
        onChainBridgeAddress = _onChainBridgeAddress;
        return true;
    }
    
    function createMetaData(address _offChainToAddress, uint256 _tokenAmount) internal returns(bool) {
        metaData[msg.sender].offChainToAddress.push(_offChainToAddress);
        metaData[msg.sender].tokenAmount.push(_tokenAmount);
        return true;
    }
    
    function getMetaData(address inputAddress) public view returns (OffchainMetaData memory) {
        return (metaData[inputAddress]);
    }
    
    function transferToBridge(address _offChainToAddress, uint256 _tokenAmount) public returns (bool success) {
        require(onChainBridgeAddress != address(0));
        balances[msg.sender] = safeSub(balances[msg.sender], _tokenAmount);
        balances[onChainBridgeAddress] = safeAdd(balances[onChainBridgeAddress], _tokenAmount);
        createMetaData(_offChainToAddress, _tokenAmount);
        emit Transfer(msg.sender, onChainBridgeAddress, _tokenAmount);
        return true;
    }
}