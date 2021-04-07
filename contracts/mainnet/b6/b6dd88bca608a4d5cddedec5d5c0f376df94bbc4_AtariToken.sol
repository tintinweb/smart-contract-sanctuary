/**
 *Submitted for verification at Etherscan.io on 2021-04-06
*/

/**
 *Submitted for verification at Etherscan.io on 2020-07-05
*/
// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.0 <0.7.0;
// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
interface ERC20Interface {
    function totalSupply() external view returns (uint256);
    function balanceOf(address tokenOwner) external view returns (uint balance);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
contract AtariToken is ERC20Interface {
    
    string public constant name = "ATARI";
    string public constant symbol = "ATARI";
    uint8 public constant decimals = 18;
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event RegistrationSuccessful(uint256 nonce);
    event RegistrationFailed(uint256 nonce);
    
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    
    uint256 totalSupply_ = 7771000000000000000000000000;
    
    mapping (string => address) addressTable;
    using SafeMath for uint256;
    
    constructor() public{
        balances[msg.sender] = totalSupply_;
    }
    
    function totalSupply() public override view returns (uint256) {
        return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public override view returns (uint) {
        return balances[tokenOwner];
    }
    
    function balanceOf(string memory tokenOwner) public view returns (uint) {
        address userAddress;
        userAddress = addressTable[tokenOwner];
        return balances[userAddress];
    }
    
    function transfer(address receiver, uint numTokens) public override returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }
    
    function transfer(string memory receiver, uint numTokens) public returns (bool) {
        address receiverAddress;
        receiverAddress = addressTable[receiver];
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiverAddress] = balances[receiverAddress].add(numTokens);
        emit Transfer(msg.sender, receiverAddress, numTokens);
        return true;
    }
    
    function approve(address delegate, uint numTokens) public override returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }
    
    function approve(string memory delegate, uint numTokens) public returns (bool) {
        address delegateAddress;
        delegateAddress = addressTable[delegate];
        allowed[msg.sender][delegateAddress] = numTokens;
        emit Approval(msg.sender, delegateAddress, numTokens);
        return true;
    }
    
    function allowance(address owner, address delegate) public override view returns (uint) {
        return allowed[owner][delegate];
    }
    
    function allowance(string memory owner, string memory delegate) public view returns (uint) {
        address ownerAddress;
        ownerAddress = addressTable[owner];
        address delegateAddress;
        delegateAddress = addressTable[delegate];
        return allowed[ownerAddress][delegateAddress];
    }
    
     function transferFrom(address owner, address buyer, uint numTokens) public override returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    function transferFrom(string memory owner, string memory buyer, uint numTokens) public returns (bool) {
        address ownerAddress;
        ownerAddress = addressTable[owner];
        address buyerAddress;
        buyerAddress = addressTable[buyer];
        
        require(numTokens <= balances[ownerAddress]);    
        require(numTokens <= allowed[ownerAddress][msg.sender]);
    
        balances[ownerAddress] = balances[ownerAddress].sub(numTokens);
        allowed[ownerAddress][msg.sender] = allowed[ownerAddress][msg.sender].sub(numTokens);
        balances[buyerAddress] = balances[buyerAddress].add(numTokens);
        emit Transfer(ownerAddress, buyerAddress, numTokens);
        return true;
    }
    
    function registerUser(string memory user, uint256 nonce) public returns (bool) {
        if (addressTable[user] == address(0)) {
            addressTable[user] = msg.sender;
            emit RegistrationSuccessful(nonce);
            return true;
        } else {
            emit RegistrationFailed(nonce);
            return false;
        }
    }
}
library SafeMath { 
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}