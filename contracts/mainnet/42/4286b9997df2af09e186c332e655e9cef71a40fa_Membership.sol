pragma solidity ^0.4.24;

//Slightly modified SafeMath library - includes a min function
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

  function min(uint a, uint b) internal pure returns (uint256) {
    return a < b ? a : b;
  }
}


/**
*This contract allows users to sign up for the DDA Cooperative Membership.
*To complete membership DDA will provide instructions to complete KYC/AML verification
*through a system external to this contract.
*/
contract Membership {
    using SafeMath for uint256;
    
    /*Variables*/
    address public owner;
    //Memebership fees
    uint public memberFee;

    /*Structs*/
    /**
    *@dev Keeps member information 
    */
    struct Member {
        uint memberId;
        uint membershipType;
    }
    
    /*Mappings*/
    //Members information
    mapping(address => Member) public members;
    address[] public membersAccts;

    /*Events*/
    event UpdateMemberAddress(address _from, address _to);
    event NewMember(address _address, uint _memberId, uint _membershipType);
    event Refund(address _address, uint _amount);

    /*Modifiers*/
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    /*Functions*/
    /**
    *@dev Constructor - Sets owner
    */
     constructor() public {
        owner = msg.sender;
    }

    /*
    *@dev Updates the fee amount
    *@param _memberFee fee amount for member
    */
    function setFee(uint _memberFee) public onlyOwner() {
        //define fee structure for the three membership types
        memberFee = _memberFee;
    }
    
    /**
    *@notice Allows a user to become DDA members if they pay the fee. However, they still have to complete
    *complete KYC/AML verification off line
    *@dev This creates and transfers the token to the msg.sender
    */
    function requestMembership() public payable {
        Member storage sender = members[msg.sender];
        require(msg.value >= memberFee && sender.membershipType == 0 );
        membersAccts.push(msg.sender);
        sender.memberId = membersAccts.length;
        sender.membershipType = 1;
        emit NewMember(msg.sender, sender.memberId, sender.membershipType);
    }
    
    /**
    *@dev This updates/transfers the member address 
    *@param _from is the current member address
    *@param _to is the address the member would like to update their current address with
    */
    function updateMemberAddress(address _from, address _to) public onlyOwner {
        require(_to != address(0));
        Member storage currentAddress = members[_from];
        Member storage newAddress = members[_to];
        require(newAddress.memberId == 0);
        newAddress.memberId = currentAddress.memberId;
        newAddress.membershipType = currentAddress.membershipType;
		membersAccts[currentAddress.memberId - 1] = _to;
        currentAddress.memberId = 0;
        currentAddress.membershipType = 0;
        emit UpdateMemberAddress(_from, _to);
    }

    /**
    *@dev Use this function to set membershipType for the member
    *@param _memberAddress address of member that we need to update membershipType
    *@param _membershipType type of membership to assign to member
    */
    function setMembershipType(address _memberAddress,  uint _membershipType) public onlyOwner{
        Member storage memberAddress = members[_memberAddress];
        memberAddress.membershipType = _membershipType;
    }

    /**
    *@dev getter function to get all membersAccts
    */
    function getMembers() view public returns (address[]){
        return membersAccts;
    }
    
    /**
    *@dev Get member information
    *@param _memberAddress address to pull the memberId, membershipType and membership
    */
    function getMember(address _memberAddress) view public returns(uint, uint) {
        return(members[_memberAddress].memberId, members[_memberAddress].membershipType);
    }

    /**
    *@dev Gets length of array containing all member accounts or total supply
    */
    function countMembers() view public returns(uint) {
        return membersAccts.length;
    }

    /**
    *@dev Gets membership type
    *@param _memberAddress address to view the membershipType
    */
    function getMembershipType(address _memberAddress) public constant returns(uint){
        return members[_memberAddress].membershipType;
    }
    
    /**
    *@dev Allows the owner to set a new owner address
    *@param _new_owner the new owner address
    */
    function setOwner(address _new_owner) public onlyOwner() { 
        owner = _new_owner; 
    }

    /**
    *@dev Refund money if KYC/AML fails
    *@param _to address to send refund
    *@param _amount to refund. If no amount  is specified the current memberFee is refunded
    */
    function refund(address _to, uint _amount) public onlyOwner {
        require (_to != address(0));
        if (_amount == 0) {_amount = memberFee;}
        Member storage currentAddress = members[_to];
        membersAccts[currentAddress.memberId-1] = 0;
        currentAddress.memberId = 0;
        currentAddress.membershipType = 0;
        _to.transfer(_amount);
        emit Refund(_to, _amount);
    }

    /**
    *@dev Allow owner to withdraw funds
    *@param _to address to send funds
    *@param _amount to send
    */
    function withdraw(address _to, uint _amount) public onlyOwner {
        _to.transfer(_amount);
    }    
}