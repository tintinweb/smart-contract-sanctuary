pragma solidity ^0.4.24;
// Spielley&#39;s King of the crypto hill beta Coallition expansion v1.01
// Coallition owner sets shares for the alliance, alliance members send in their eth winnings to share among the group
// Coallition owner can increase or decrease members and shares
// this is not a trustless situation, alliance owner can screw everyone over, only join an alliance you trust

// play at https://kotch.dvx.me/# 
// 28/08/2018

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}
// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}
contract Coallition is Owned {
     using SafeMath for uint;
     
     mapping(uint256 => address) public members;
     mapping(address => uint256) public shares;
     
     uint256 public total;
     constructor () public {
         
    }
     function addmember(uint256 index , address newmember) public onlyOwner  {
   members[index] = newmember;
}
     function addshares(uint256 sharestoadd , address member) public onlyOwner  {
shares[member] += sharestoadd;
}
function deductshares(uint256 sharestoadd , address member) public onlyOwner  {
   shares[member] -= sharestoadd;
}
function setshares(uint256 sharestoadd , address member) public onlyOwner  {
   shares[member] = sharestoadd;
}
// set total number of members
function settotal(uint256 set) public onlyOwner  {
   total = set;
}
    function payout() public payable {
        
   for(uint i=0; i< total; i++)
        {
            uint256 totalshares;
            totalshares += shares[members[i]];
        }
        uint256 base = msg.value.div(totalshares);
    for(i=0; i< total; i++)
        {
            
            uint256 amounttotransfer = base.mul(shares[members[i]]);
            members[i].transfer(amounttotransfer);
            
        }
}
function collectdustatcontract() public payable {
        
   for(uint i=0; i< total; i++)
        {
            uint256 totalshares;
            totalshares += shares[members[i]];
        }
       
        uint256 base = address(this).balance.div(totalshares);
    for(i=0; i< total; i++)
        {
            
            uint256 amounttotransfer = base.mul(shares[members[i]]);
            members[i].transfer(amounttotransfer);
            
        }
}
 function () external payable{payout();}     
}