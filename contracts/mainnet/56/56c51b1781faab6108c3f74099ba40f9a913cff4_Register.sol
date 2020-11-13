pragma solidity  ^0.4.0;

contract Register {
    
    uint256 public totalDeposit=0;
    uint256 public burnedTokens=0;
    uint256 minDepositValue;
    address owner;
    address cTokenAddr=0x1f6bd8766f8a8AA58F7441C8dd3709aFA3a56202;
    mapping(address => uint256)  registerRecords;
    
    constructor(uint256 _minValue) public {
        owner=msg.sender;
        minDepositValue=_minValue;
    }
    
    event RegisterToken(address indexed _from,address indexed _to,uint256 indexed _value);
    event BurnToken(address indexed _from,uint256 indexed _value);

    function registerToken(address _to,uint256 _value) public returns (bool sucess) {
        require(_value>minDepositValue);
        bytes4 transferFromMethodId = bytes4(keccak256("transferFrom(address,address,uint256)"));
        if(cTokenAddr.call(transferFromMethodId,msg.sender,_to, _value)){
             registerRecords[msg.sender]+=_value;
             totalDeposit+=_value;
             emit RegisterToken(msg.sender,_to,_value);
             return true;
        }
        return false;
    }
    
    function burn() public returns (bool sucess) {
        bytes4 transferMethodId = bytes4(keccak256("transfer(address(0),uint256)"));
        uint256 _value = totalDeposit - burnedTokens;
        if(cTokenAddr.call(transferMethodId, address(0), _value)){
             burnedTokens+=_value;
             emit BurnToken(msg.sender,_value);
             return true;
        }
        return false;
    }

    function getDeposit() public view returns (uint256){
        return registerRecords[msg.sender];
    }
    
    function getDepositByAddr(address addr) public view returns(uint256){
        return registerRecords[addr];
    }
        
    function getTotalDeposit()  public view returns (uint256){
        return totalDeposit;
    }

    function getTotalBurned()  public view returns (uint256){
        return burnedTokens;
    }
}