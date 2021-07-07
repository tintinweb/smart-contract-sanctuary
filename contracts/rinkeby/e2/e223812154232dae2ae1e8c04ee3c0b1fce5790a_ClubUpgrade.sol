/**
 *Submitted for verification at Etherscan.io on 2021-07-07
*/

// SPDX-License-Identifier: Mchaves

pragma solidity ^0.8.0;

contract Owner {

    address internal owner;
    
    event SetOwner(address oldOwner, address newOwner);
    
    modifier isOwner() {
        require(msg.sender == owner, "You are not the Owner");
        _;
    }
    constructor() {
        owner = msg.sender;
        emit SetOwner(address(0), owner);
    }
    
    function SetNewOwner(address newOwner) public isOwner {
        emit SetOwner(owner, newOwner);
        owner = newOwner;
    }
    
}

contract Proyects is Owner{
   
    struct Proyect {
        address payable proyectOwner;
        string proyectName;
        uint256 proyectBudget;
        uint256 proyectBalance;
    }

    uint256 proyectQuantity = 1;
    mapping (uint=>Proyect) proyect;

//  This function is used by the owner of the contract to creat new proposals
//  so the members can vote and assign money into into it
    function NewProyect (address payable _proyectOwner,string memory _proyectName, uint256 _proyectBudget) public isOwner returns (uint256 proyectID) {
        proyectID = proyectQuantity++;
        proyect[proyectID] = Proyect(_proyectOwner,_proyectName, _proyectBudget, 0);
    }
    
// This function was created to check the status of different proposals by the members of the club
    function ProyectGoal (uint256 _proyectID) public view returns (uint256) {
        Proyect storage p = proyect[_proyectID];
        return p.proyectBudget - p.proyectBalance;
    }
//    
    function ProyectName (uint256 _proyectID) public view returns (string memory) {
        Proyect storage p = proyect[_proyectID];
        return p.proyectName;
    }

    function ProyectBalance (uint256 _proyectID) public view returns (uint256 _contractBalance) {
        Proyect storage p = proyect[_proyectID];
        _contractBalance = p.proyectOwner.balance;
    }
    
}

contract ClubUpgrade is Proyects {
    
    address payable memberAddress;
    mapping (address=>uint256) memberBalance;
    mapping (address=> uint256) freeBalance;
/*    struct Member {
        address payable memberAddress;
        string memberFirstName;
        string memberLastName;
        mapping (address=>bool) canVote;
        mapping (address=>uint256) memberBalance;
    }
*/    
//    mapping (uint=>Member) member;    
    uint memberQuantity = 0;
    constructor () {
    }

/*    function newMember (address payable _memberAddress, string memory _mFN, string memory _mLN) public returns (uint256 memberID) {
        memberID = memberQuantity++;
        member[memberID] = Member(_memberAddress,_mFN, _mLN, false, 0);
    }
*/    
  
    function TransferToClub () public payable {
        memberBalance[msg.sender] += msg.value;
    }
   
    function ClubBalance () public view returns (uint256 _contractBalance) {
        _contractBalance = address(this).balance;
    }
    
    function MyBalance () public view returns (uint256 _memberBalance) {
        return _memberBalance = memberBalance[msg.sender];
    }

    function FreeBalance () public view returns (uint256 _freeBalance) {
        return _freeBalance = freeBalance[address(this)];
    }

    function ClaimBalance () public payable {
       payable(msg.sender).transfer(memberBalance[msg.sender]);
       memberBalance[msg.sender] = 0;
    }
    
    function AssignToProyect (uint256 _proyectID, uint256 _ammount) public payable {
        Proyect storage p = proyect[_proyectID];
/*      if (msg.sender == owner){
            require (freeBalance[address(this)] >= _ammount, "You don't have that ammount in your Balance");
            require(p.proposalBalance < p.proposalBudget, "Ammount excedes Budget. Check proyect balance for maximum allowed" );
            p.proposalBalance += _ammount;
            p.proposalOwner.transfer(_ammount);
            freeBalance[address(this)] -= _ammount;
        }
        
        else
*/      require (memberBalance[msg.sender] >= _ammount, "You don't have that ammount in your Balance");
        require(p.proyectBalance < p.proyectBudget, "Ammount excedes Budget. Check proyect balance for maximum allowed" );
        p.proyectBalance += _ammount;
        p.proyectOwner.transfer(_ammount);
        memberBalance[msg.sender] -= _ammount;
    }
    
    function Delegate (uint256 _ammount) public {
        require (memberBalance[msg.sender] >= _ammount, "You don't have that ammount in your Balance");
        memberBalance[msg.sender] -= _ammount;
        freeBalance[address(this)] += _ammount;
    }
    
    function UseFreeBalance (uint256 _proyectID, uint256 _ammount) public isOwner payable {
        Proyect storage p = proyect[_proyectID];
        require (freeBalance[address(this)] >= _ammount, "You don't have that ammount in your Balance");
        require(p.proyectBalance < p.proyectBudget, "Ammount excedes Budget. Check proyect balance for maximum allowed" );
        p.proyectBalance += _ammount;
        p.proyectOwner.transfer(_ammount);
        freeBalance[address(this)] -= _ammount;
    }
    
}