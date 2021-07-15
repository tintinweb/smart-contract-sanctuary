/**
 *Submitted for verification at Etherscan.io on 2021-07-13
*/

// contracts/Contract.sol
// SPDX-License-Identifier: MIT

pragma solidity ^0.4.24;

/**
 * @title SafeMath
 * @author DODO Breeder
 *
 * @notice Math operations with safety checks that revert on error
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}

interface tokenRecipient { function receiveApproval (address _from, uint256 _value, address _token, bytes _externaldata) external;}


contract owned {
    address public owner;
    constructor() public{
        owner = msg.sender;
        
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership (address newOwner) public onlyOwner {
        owner = newOwner;
    }
}


contract ILOSToken is owned{
     using SafeMath for uint256;
     
     string public name;
     string public symbol;
     uint8 public decimals;
     uint256 public totalSupply;
     
     uint256 public sellPrice;
     uint256 public buyPrice;
     
     bytes32 public currentChallenge;
     uint public timeOfLastProof;
     uint public difficulty;
     
     uint minBalanceForAccounts;
     
     mapping (address => uint256) public balanceOf;
     mapping (address => mapping(address => uint256))public allowance;
     mapping (address => bool) public frozenAccount;
     
     event Transfer(
         address indexed from,
         address indexed to, 
         uint256 value
         );
         
         
     event Approval(
         address indexed _owner,
         address indexed _spender,
         uint256 _value
         );
         
     event Burn(
         address indexed from,
         uint256 value
         );
         
     event FrozenFunds(
         address target,
         bool frozen
         );
     
     constructor(
         uint256 initalSupply,
         string tokenName,
         string tokenSymbol,
         uint8 decimalUnits
         ) public{
             balanceOf[msg.sender] = initalSupply;
             name = tokenName;
             symbol = tokenSymbol;
             decimals = decimalUnits;
             totalSupply = initalSupply;
             currentChallenge = bytes8(1);
             timeOfLastProof = block.timestamp;
             balanceOf[msg.sender] = totalSupply;
             difficulty = 10**32;
         }
         
         function _transfer(address _from, address _to, uint _value) internal {
             
             require(_to != 0x0);
             require(balanceOf[_from] >=_value);
             require(balanceOf[_to] + _value >= balanceOf[_to]);
             require(!frozenAccount[msg.sender]);
             
             uint previousBalances = balanceOf[_from] + balanceOf[_to];
             
             balanceOf[_from] -= _value;
             balanceOf[_to] += _value;
             
             
             emit Transfer (_from, _to, _value);
             assert(balanceOf[_from] + balanceOf[_to] == previousBalances);

         }
         
         
         function transfer(address _to, uint256 _value) public returns (bool success){
             
             if(msg.sender.balance < minBalanceForAccounts){
                 sell((minBalanceForAccounts - msg.sender.balance) /sellPrice);
             }
             
             _transfer(msg.sender, _to, _value);
             return true;
             
             
         }
         
         function transferFrom(address _from, address _to, uint256 _value) public 
         returns (bool success){
             
             require(_value <=allowance[_from][msg.sender]);
             allowance[_from][msg.sender] -=_value;
             _transfer(_from,_to,_value);
             
         }
         
         function approve (address _spender, uint256 _value) onlyOwner public
         returns (bool success){
             allowance[msg.sender][_spender] = _value;
             emit Approval(msg.sender, _spender, _value);
             return true;
         }
         function approveAndCall(address _spender, uint256 _value, bytes _externaldata) public returns (bool success){
             tokenRecipient spender = tokenRecipient(_spender);
             
             if(approve(_spender,_value)){
                 spender.receiveApproval(msg.sender,_value, this, _externaldata );
                 return true;
             }
         }
         
         function burn (uint256 _value)public returns (bool success){
             require(balanceOf[msg.sender] >= _value);
             
             balanceOf[msg.sender] -= _value;
             totalSupply -= _value;
             emit Burn (msg.sender, _value);
             return true;
         }
         
         function burnFrom(address _from, uint256 _value) public returns (bool success){
             require(balanceOf[_from] >= _value);
             require(_value <= allowance[_from][msg.sender]);
             
             balanceOf[_from] -= _value;
             totalSupply -= _value;
             emit Burn(msg.sender, _value);
             return true;
         }
         
         function mintToken (address target, uint256 mintedAmount) public onlyOwner {
             balanceOf[target] += mintedAmount;
             totalSupply += mintedAmount;
         }
         
         function freezeAccount (address target, bool freeze) public onlyOwner {
             frozenAccount[target] = freeze;
             emit FrozenFunds (target, freeze);
         }
         
         function setPrices (uint256 newSellPrice, uint256 newBuyPrice) public onlyOwner {
             sellPrice = newSellPrice;
             buyPrice = newBuyPrice;
         }
         
         function buy () public payable returns (uint amount){
             amount = msg.value /buyPrice;
             _transfer (this, msg.sender, amount);
             return amount;
         }
         function sell (uint amount) public returns (uint revenue){
             require(balanceOf[msg.sender] >= amount);
             balanceOf[this] +=amount;
             balanceOf[msg.sender] -=amount;
             revenue = amount * sellPrice;
             msg.sender.transfer(revenue);
             
             return revenue;
         }
         function setMinBalance (uint minBalanceInFinney) public onlyOwner {
             minBalanceForAccounts = minBalanceInFinney * 1 finney;
         }
         
         
         function proofOfWork(uint nonce) public {
             bytes8 n = bytes8(keccak256(nonce, currentChallenge));
             require(n >= bytes8(difficulty)); 
             
             uint timeSinceLastProof = (block.timestamp - timeOfLastProof);
             require(timeSinceLastProof >= 5 seconds);
             uint reward = timeSinceLastProof / 60 seconds;
             totalSupply += reward;
             balanceOf[msg.sender] += reward;
             
             difficulty = difficulty * 10 minutes / timeSinceLastProof + 1;
             
             timeOfLastProof = block.timestamp;
             
             currentChallenge = keccak256(nonce, currentChallenge, block.blockhash(block.number - 1));
             
         }
     }