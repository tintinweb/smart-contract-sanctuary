pragma solidity ^0.4.7.;

contract UptimeContract {
    
    struct iotDevice {
        uint16 deviceId;
        uint16[] monthlyReport;
        address payoutAddress;
    }
    
    mapping(uint16 => iotDevice) private _registeredDevices;
    uint8 private _currentMonth = 6; /// @dev take now month;
    uint private monthlyCompensation = 0.01 ether;
    uint private hoursInMonth = 730;
    
    ///@dev needed to make contract pay out
    constructor() public payable{}
    
    ///@dev needed to fund the contract
    function() public payable {
    // nothing to do
    }
    
    modifier onlyBy(uint16 _deviceId) {
        require(msg.sender == _registeredDevices[_deviceId].payoutAddress, &quot;Sender is not authorized&quot;);
        _;
    }
    
    modifier enoughBalance() {
        require(address(this).balance >= monthlyCompensation, &quot;Contract does not contain enough funds please contact owner&quot;);
        _;
    }
    
    function report(uint16 _deviceId, uint16 uptime) public {
        iotDevice memory deviceToReport = _registeredDevices[_deviceId];
        if(deviceToReport.deviceId == 0) {
            deviceToReport = iotDevice(_deviceId, new uint16[](12), msg.sender);
        }
        require(msg.sender == deviceToReport.payoutAddress, &quot;Sender is not authorized&quot;);
        deviceToReport.monthlyReport[_currentMonth] += uptime;
        _registeredDevices[_deviceId] = deviceToReport;
    }
    
    function withdrawFunds(uint16 _deviceId) external onlyBy(_deviceId) enoughBalance() payable {
        msg.sender.transfer(0.01 ether);///@dev improve with payout logic
    }
    
    function showReportForMonth(uint16 _deviceId, uint8 _month) external view returns(uint16) {
        return _registeredDevices[_deviceId].monthlyReport[_month-1];
    }
    
    function showReportForDevice(uint16 _deviceId) external view returns(uint16[]) {
        return _registeredDevices[_deviceId].monthlyReport;
    }
    
    function showContractBalance() external view returns(uint) {
        return address(this).balance;
    }
    
    function addFunds() public payable {
        address(this).transfer(msg.value);
    }
    
}