/**
 *Submitted for verification at Etherscan.io on 2021-03-13
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.7.4;

contract ERC20Basic {

    string public constant name = "DxProof";
    string public constant symbol = "DXP";
    uint8 public constant decimals = 4;  


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event DocumentEvent(uint blockNumber, bytes32 indexed hash, address indexed from, address indexed to);

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(uint => DocumentTransfer) public history;
    mapping(bytes32 => bool) public usedHashes;
    mapping(bytes32 => address) public documentHashMap;
    
    uint256 totalSupply_;
    uint latestDocument;

    using SafeMath for uint256;


   constructor(uint256 total) {  
	totalSupply_ = total;
	balances[msg.sender] = totalSupply_;
    }  

    function totalSupply() public view returns (uint256) {
	return totalSupply_;
    }
    
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }

    function transfer(address receiver, uint numTokens) public returns (bool) {
        require(numTokens <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(numTokens);
        balances[receiver] = balances[receiver].add(numTokens);
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    function approve(address delegate, uint numTokens) public returns (bool) {
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    function allowance(address owner, address delegate) public view returns (uint) {
        return allowed[owner][delegate];
    }

    function transferFrom(address owner, address buyer, uint numTokens) public returns (bool) {
        require(numTokens <= balances[owner]);    
        require(numTokens <= allowed[owner][msg.sender]);
    
        balances[owner] = balances[owner].sub(numTokens);
        allowed[owner][msg.sender] = allowed[owner][msg.sender].sub(numTokens);
        balances[buyer] = balances[buyer].add(numTokens);
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
    
    function newDocument(bytes32 hash) public returns (bool success) {
        if (documentExists(hash)) {
            success = false;
        } else {
            createHistory(hash, msg.sender, msg.sender);
            usedHashes[hash] = true;
            success = true;
        }
        return success;
    }
    
    function createHistory (bytes32 hash, address from, address to) internal {
            ++latestDocument;
            documentHashMap[hash] = to;
            usedHashes[hash] = true;
            history[latestDocument] = DocumentTransfer(block.number, hash, from, to);
            emit DocumentEvent(block.number, hash, from,to);
    }
    
    function transferDocument(bytes32 hash, address recipient) public returns (bool success){
        success = false;
           
        if (documentExists(hash)){
            if (documentHashMap[hash] == msg.sender){
                createHistory(hash, msg.sender, recipient);
                success = true;
            }
        }
         
        return success;
    }
    
    function documentExists(bytes32 hash) view public returns (bool exists){
        if (usedHashes[hash]) {
            exists = true;
        }else{
            exists= false;
        }
        return exists;
    }
    
    function getDocument(uint docId) view public returns (uint blockNumber, bytes32 hash, address from, address to){
        DocumentTransfer storage doc = history[docId];
        blockNumber = doc.blockNumber;
        hash = doc.hash;
        from = doc.from;
        to = doc.to;
    }
    
    struct DocumentTransfer {
        uint blockNumber;
        bytes32 hash;
        address from;
        address to;
    }
    
    function getLatest() view public returns (uint latest){
        return latestDocument;
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