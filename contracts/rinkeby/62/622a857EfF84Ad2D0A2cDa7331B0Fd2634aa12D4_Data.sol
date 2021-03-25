/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

// File: contracts\Ownable.sol

pragma solidity ^0.5.16;


contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


  
  constructor (address _owner) public {
    require(_owner != address(0));
    owner = _owner;
  }

  
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0),"invalid address");
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}

library SafeMath {

  
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
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
}

contract Data is Ownable{
    using SafeMath for uint256;
    
    uint256 public reward = 50000000000000000000;
    uint256 reduction = 5000000000000000;
    address[] platformUsers;
    
    address public DAFIContract;
    
    mapping (address => Users) public User; 
    mapping (bytes32 => dTokenRecord) public demandFactorHistory;
    mapping (address => DAFIReward) public DAFIRewardDetail;

    event DAFIContractChange(address indexed oldAddress, address indexed newAddress);
    
    struct Users{
        address userAddress;
        mapping(bytes32 => dTokenType) tokenType;
    }
    
    struct dTokenType{
        bool isMinted;
        uint256 time;
    }
    
    struct dTokenRecord{
        uint256 day1;
        uint256 time1;
        uint256 day2;
        uint256 time2;
        uint256 day3;
        uint256 time3;
        uint256 day4;
        uint256 time4;
        uint256 day5;
        uint256 time5;
    }
    
    struct DAFIReward{
        uint256 rewardValue;
        bool given;
    }
    
    modifier onlyDAFI{
        require(msg.sender == DAFIContract, "Not Authorized address");
        _;
    }
    
    constructor() public Ownable(msg.sender) {
        
    }
    
    function userReward(address _address) external onlyDAFI{
        
        DAFIRewardDetail[_address].rewardValue = reward;
        DAFIRewardDetail[_address].given = true;
        reward = reward.sub(reduction);
        platformUsers.push(_address);
    }
    
    function userDAFIReward(address _address) external view returns(uint256){
        return DAFIRewardDetail[_address].rewardValue;
    }
    
    function userRewardGiven(address _address) external view returns(bool){
        return DAFIRewardDetail[_address].given;
    }
    
    function userCount() external view returns(uint256 _count){
        _count = platformUsers.length;
    }
    
    function isTokenMinted(address _beneficiary, bytes32 _type) external view returns(bool){
        return User[_beneficiary].tokenType[_type].isMinted;
    }
    
    function setIfTokenMinted(address _beneficiary, bytes32 _type) external onlyDAFI {
        User[_beneficiary].tokenType[_type].isMinted = true;
        User[_beneficiary].tokenType[_type].time = uint256(now);
    }
    
    function updateDemandFactorHistory(bytes32 _type, uint256 _supply, uint256 _time) external onlyDAFI{
        demandFactorHistory[_type].day5 = demandFactorHistory[_type].day4;
        demandFactorHistory[_type].day4 = demandFactorHistory[_type].day3;
        demandFactorHistory[_type].day3 = demandFactorHistory[_type].day2;
        demandFactorHistory[_type].day2 = demandFactorHistory[_type].day1;
        demandFactorHistory[_type].day1 = _supply;
        
        demandFactorHistory[_type].time5 = demandFactorHistory[_type].time4;
        demandFactorHistory[_type].time4 = demandFactorHistory[_type].time3;
        demandFactorHistory[_type].time3 = demandFactorHistory[_type].time2;
        demandFactorHistory[_type].time2 = demandFactorHistory[_type].time1;
        demandFactorHistory[_type].time1 = _time;
    }
    
    function getDemandFactorHistory(bytes32 _type, address _beneficiary) external view returns(uint256 _day1, uint256 _day2, uint256 _day3, uint256 _day4, uint256 _day5){
        if (User[_beneficiary].tokenType[_type].time<= demandFactorHistory[_type].time1){
            _day1 = demandFactorHistory[_type].day1;
        }
        if (User[_beneficiary].tokenType[_type].time<= demandFactorHistory[_type].time2){
            _day2 = demandFactorHistory[_type].day2;
        }
        if (User[_beneficiary].tokenType[_type].time<= demandFactorHistory[_type].time3){
            _day3 = demandFactorHistory[_type].day3;
        }
        if (User[_beneficiary].tokenType[_type].time<= demandFactorHistory[_type].time4){
            _day4 = demandFactorHistory[_type].day4;
        }
        if (User[_beneficiary].tokenType[_type].time<= demandFactorHistory[_type].time5){
            _day5 = demandFactorHistory[_type].day5;
        }
        
    }
    
    function setDAFIContractAddress(address _address) public onlyOwner {
        require(_address != address(0),"invalid address");
        emit DAFIContractChange(DAFIContract,_address);
        DAFIContract = _address;
    }
}