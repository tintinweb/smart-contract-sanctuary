pragma solidity ^0.4.19;

contract Readings {
    
    address private owner;
    mapping (bytes32 => MeterInfo) private meters;
    bool private enabled;
    
    struct MeterInfo {
        uint32 meterId;
        string serialNumber;
        string meterType;
        string latestReading;
    }
    
    function Readings() public {
        owner = msg.sender;
        enabled = true;
    }
 
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    
    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }
    
    function enable() public onlyOwner {
        enabled = true;
    }
    
    function disable() public onlyOwner {
        enabled = false;
    }
    
    function addMeter(uint32 meterId, string serialNumber, string meterType) public onlyOwner {
        require(enabled && meterId > 0);
        meters[keccak256(serialNumber)] = 
            MeterInfo({meterId: meterId, serialNumber:serialNumber, meterType:meterType, latestReading:&quot;&quot;});
    }
    
    function getMeter(string serialNumber) public view onlyOwner returns(string, uint32, string, string, string, string) {
        bytes32 serialK = keccak256(serialNumber);
        require(enabled && meters[serialK].meterId > 0);
        
        return (&quot;Id:&quot;, meters[serialK].meterId, &quot;Серийный номер:&quot;, meters[serialK].serialNumber, &quot;Тип счетчика:&quot;, meters[serialK].meterType);
    }
    
    function saveReading(string serialNumber, string reading) public onlyOwner {
        bytes32 serialK = keccak256(serialNumber);
        require (enabled && meters[serialK].meterId > 0);
        meters[serialK].latestReading = reading;
    }
    
    function getLatestReading(string serialNumber) public view returns (string, string, string, string, string, string) {
        bytes32 serialK = keccak256(serialNumber);
        require(enabled && meters[serialK].meterId > 0);
        
        return (
            &quot;Тип счетчика:&quot;, meters[serialK].meterType,
            &quot;Серийный номер:&quot;, meters[serialK].serialNumber,
            &quot;Показания:&quot;, meters[serialK].latestReading
        );
    }
}