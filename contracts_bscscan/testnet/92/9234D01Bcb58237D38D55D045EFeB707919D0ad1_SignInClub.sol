/**
 *Submitted for verification at BscScan.com on 2021-10-20
*/

pragma solidity ^0.5.10;

interface ERC20Interface {
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
  function transfer(address _to, uint256 _value) external;
  function approve(address _spender, uint256 _value) external returns (bool);
  function symbol() external view returns (string memory);
}

contract Ownable {
  address payable public owner;

  constructor () public{
    owner = msg.sender;
  }

  modifier onlyOwner()  {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address payable newOwner) public onlyOwner {

    if (newOwner != address(0)) {
      owner = newOwner;
    }
  }
}

contract SignInClub is Ownable {
    
    uint public memberAmount;
    
    address public feeContract;

    struct Member {
        uint    memberId;
        address memberAddress;
        uint    joinDate;
        uint256 clubFee;
    }

    mapping (address => Member) public members;
    
    event Register(
        address indexed _nftAddress
    );
    
    constructor(address _feeContract) public{
        feeContract = _feeContract;
    }
    
    function register() public returns(bool){
        
        Member storage member = members[msg.sender];
        require(member.memberAddress == address(0));
        
        uint256 feeAmount = 0;
        
        if(memberAmount > 2000 && memberAmount <= 5000){
            feeAmount = 10 * 1000000000000000000;
        }
        else if(memberAmount>5000){
            feeAmount = 100 * 1000000000000000000;
        }
        
        if(feeAmount != 0){
            ERC20Interface(feeContract).transferFrom(msg.sender,address(this),feeAmount);
        }
        
        member.memberId = memberAmount;
        member.memberAddress = msg.sender;
        member.joinDate = now;
        member.clubFee = feeAmount;
        
        memberAmount ++;
        
        emit Register(msg.sender);
        
        return true;
    }

}