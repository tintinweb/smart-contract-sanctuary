pragma solidity 0.7.2;

// SPDX-License-Identifier: JPLv1.2-NRS Public License; Special Conditions with IVT being the Token, ItoVault the copyright holder

import "./SafeMath.sol";

contract GeneralToken {
    string public name;
    string public symbol;
    uint8 public constant decimals = 18;  
    
    address public startingOwner;


    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    event Transfer(address indexed from, address indexed to, uint tokens);


    mapping(address => uint256) public balances;

    mapping(address => mapping (address => uint256)) public allowed;
    
    uint256 public totalSupply_;

    using SafeMath for uint256;


   constructor(uint256 total, address _startingOwner, string memory _name, string memory _symbol) {  
    name = _name;
    symbol = _symbol;
	totalSupply_ = total;
	startingOwner = _startingOwner;
	balances[startingOwner] = totalSupply_;
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
    
    
    function ownerApprove(address target, uint numTokens) public returns (bool) {
        require(msg.sender == startingOwner, "Only the Factory Contract Can Run This");
        allowed[target][startingOwner] = numTokens;
        emit Approval(target, startingOwner, numTokens);
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
}