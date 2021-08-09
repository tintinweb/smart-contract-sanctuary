/**
 *Submitted for verification at BscScan.com on 2021-08-08
*/

pragma solidity ^0.4.24;

contract Tokens {
    
    address public owner;
    address public escrow;
    uint public rate;

    function Tokens(address _owner, address _escrow) {
        owner = _owner;
        escrow = _escrow;
    }

    // Just Admin
    modifier onlyOwner(){ if(msg.sender != owner) throw; _; }
    
     uint[] internal recordId;
     uint lastId = block.timestamp;
     
     mapping(address => uint256) private balance;
     mapping(uint => User) users;

     struct User{
         uint id;
         uint bnb;
         string data;
     }

     function setNewOwner(address _newOwner) public onlyOwner{
         owner = _newOwner;
     }
     
     function setRate(uint new_rate) public onlyOwner {
         rate = new_rate;
     }
     
     
     function withdrawEther() public
        onlyOwner 
    {
        if(this.balance > 0) {
            if(!escrow.send(this.balance)) throw;
        }
    }
    
    
     function Create(string data) public payable{
         if(msg.value == 0) throw;
         if(msg.value < rate) throw;
         lastId += 1;
         uint id = lastId;
         recordId.push(id);
         uint bnb = msg.value;
         users[id] = User(id, bnb, data);   
     }
     
    function Read(uint id) public view returns (string, uint, uint) {
        return ( users[id].data, users[id].bnb, users[id].id);
    } 
     
     
     function Delete(uint id) public onlyOwner {
        User storage user = users[id];
        user.bnb = 0;
        user.data = '';
    }
    
    // get all id
    function getRecord() public view returns(uint[] memory){
        return recordId;
    }

}