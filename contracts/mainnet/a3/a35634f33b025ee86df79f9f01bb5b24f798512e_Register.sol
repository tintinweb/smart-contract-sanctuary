pragma solidity  ^0.4.0;

contract Register {
    
    uint256 public totalClaimed=0;
    uint256 public totalBurned=0;
    uint256 public totalConverted=0;
    uint256 minClaimedValue;
    address owner;
    address zyroAddr=0x1f6bd8766f8a8AA58F7441C8dd3709aFA3a56202;
    mapping(string => uint256)  claimRecords;
    mapping(string => uint256)  convertedRecords;
    
    constructor(uint256 _minValue) public {
        owner=msg.sender;
        minClaimedValue=_minValue;
    }
    
    event Claim(address indexed _from,string indexed _to,uint256 indexed _value);
    event BurnToken(address indexed _from,uint256 indexed _value);

    function claim(string _zilaccount,uint256 _value) public returns (bool sucess) {
        require(_value>minClaimedValue);
        bytes4 transferFromMethodId = bytes4(keccak256("transferFrom(address,address,uint256)"));
        if(zyroAddr.call(transferFromMethodId, msg.sender, address(this), _value)){
             claimRecords[_zilaccount]+=_value;
             totalClaimed+=_value;
             emit Claim(msg.sender,_zilaccount,_value);
             return true;
        }
        return false;
    }
    
    function burn() public returns (bool sucess) {
        bytes4 transferMethodId = bytes4(keccak256("transfer(address,uint256)"));
        uint256 _value = totalClaimed - totalBurned;
        if(zyroAddr.call(transferMethodId, address(0), _value)){
             totalBurned+=_value;
             emit BurnToken(msg.sender,_value);
             return true;
        }
        return false;
    }
    
    function convert(string _zilaccount, uint256 _value) public {
        require(msg.sender == owner);
        convertedRecords[_zilaccount]+=_value;
        totalConverted+=_value;
        claimRecords[_zilaccount]-=_value;
    }

    function getClaimedByAddr(string _zilaccount) public view returns(uint256){
        return claimRecords[_zilaccount];
    }
        
    function getTotalClaimed()  public view returns (uint256){
        return totalClaimed;
    }

    function getTotalBurned()  public view returns (uint256){
        return totalBurned;
    }
}