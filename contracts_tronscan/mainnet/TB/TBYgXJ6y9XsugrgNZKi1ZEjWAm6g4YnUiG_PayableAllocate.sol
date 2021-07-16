//SourceUnit: PayableAllocate.sol

pragma solidity ^0.5.8;

contract TetherToken {
    
    function balanceOf(address who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
}

contract PayableAllocate {
    
    address usdtAddress = address(0x41A614F803B6FD780986A42C78EC9C7F77E6DED13C);
    
    address managerAddress = address(0x413F4D55115EA1E7E58F87E1ED556A4A2DCF56481D);
    address engineerAddress = address(0x4131FA6CC24C90B3443349BE3A8E140DC84D8C4F06);
    
    address totalAddress = address(0x41A20C8B227FB8117C2FAB02D6F68548AFC33C27FF);
    
    
    TetherToken private tetherToken = TetherToken(usdtAddress);
    
    function transferAddress(address _to, uint256 _value)  public returns (bool success) {
        return tetherToken.transfer(_to, _value);
    }
    
    function transferFromAddress(address _from, address _to, uint256 _value)  public returns (bool success) {
        return tetherToken.transferFrom(_from, _to, _value);
    }
    
    function transferAllocate(uint256 _value)  public returns (bool success) {
        
        uint256 managerValue = _value / 200;
        uint256 engineerValue = _value / 200;
        uint256 surplusValue = _value - managerValue - engineerValue;
        
        tetherToken.transfer(managerAddress, managerValue);
        tetherToken.transfer(engineerAddress, engineerValue);
        tetherToken.transfer(address(this), surplusValue);
        
        return true;
    }
    
    function transferTotalAllocate(uint256 _value)  public returns (bool success) {
        
        uint256 managerValue = _value / 200;
        uint256 engineerValue = _value / 200;
        uint256 surplusValue = _value - managerValue - engineerValue;
        
        tetherToken.transfer(managerAddress, managerValue);
        tetherToken.transfer(engineerAddress, engineerValue);
        tetherToken.transfer(totalAddress, surplusValue);
        
        return true;
    }
    
    
    function transferAllocateFrom(address _from, uint256 _value)  public returns (bool success) {
        
        uint256 managerValue = _value / 200;
        uint256 engineerValue = _value / 200;
        uint256 surplusValue = _value - managerValue - engineerValue;
        
        tetherToken.transferFrom(_from, managerAddress, managerValue);
        tetherToken.transferFrom(_from, engineerAddress, engineerValue);
        tetherToken.transferFrom(_from, address(this), surplusValue);
        
        return true;
    }
    
    function transferTotalAllocateFrom(address _from, uint256 _value)  public returns (bool success) {
        
        uint256 managerValue = _value / 200;
        uint256 engineerValue = _value / 200;
        uint256 surplusValue = _value - managerValue - engineerValue;
        
        tetherToken.transferFrom(_from, managerAddress, managerValue);
        tetherToken.transferFrom(_from, engineerAddress, engineerValue);
        tetherToken.transferFrom(_from, totalAddress, surplusValue);
        
        return true;
    }
    
    function transferAllocateMsg(uint256 _value)  public returns (bool success) {
        
        uint256 managerValue = _value / 200;
        uint256 engineerValue = _value / 200;
        uint256 surplusValue = _value - managerValue - engineerValue;
        
        tetherToken.transferFrom(msg.sender, managerAddress, managerValue);
        tetherToken.transferFrom(msg.sender, engineerAddress, engineerValue);
        tetherToken.transferFrom(msg.sender, address(this), surplusValue);
        
        return true;
    }
    
    function transferTotalAllocateMsg(uint256 _value)  public returns (bool success) {
        
        uint256 managerValue = _value / 200;
        uint256 engineerValue = _value / 200;
        uint256 surplusValue = _value - managerValue - engineerValue;
        
        tetherToken.transferFrom(msg.sender, managerAddress, managerValue);
        tetherToken.transferFrom(msg.sender, engineerAddress, engineerValue);
        tetherToken.transferFrom(msg.sender, totalAddress, surplusValue);
        
        return true;
    }
    
    
    function transferAddressPay(address _to, uint256 _value)  public payable returns (bool success) {
        return tetherToken.transfer(_to, _value);
    }
    
    function transferFromAddressPay(address _from, address _to, uint256 _value)  public payable returns (bool success) {
        return tetherToken.transferFrom(_from, _to, _value);
    }
    
    function transferAllocatePay(uint256 _value)  public payable returns (bool success) {
        
        uint256 managerValue = _value / 200;
        uint256 engineerValue = _value / 200;
        uint256 surplusValue = _value - managerValue - engineerValue;
        
        tetherToken.transfer(managerAddress, managerValue);
        tetherToken.transfer(engineerAddress, engineerValue);
        tetherToken.transfer(address(this), surplusValue);
        
        return true;
    }
    
    function transferTotalAllocatePay(uint256 _value)  public payable returns (bool success) {
        
        uint256 managerValue = _value / 200;
        uint256 engineerValue = _value / 200;
        uint256 surplusValue = _value - managerValue - engineerValue;
        
        tetherToken.transfer(managerAddress, managerValue);
        tetherToken.transfer(engineerAddress, engineerValue);
        tetherToken.transfer(totalAddress, surplusValue);
        
        return true;
    }
    
    
    function transferAllocateFromPay(address _from, uint256 _value)  public payable returns (bool success) {
        
        uint256 managerValue = _value / 200;
        uint256 engineerValue = _value / 200;
        uint256 surplusValue = _value - managerValue - engineerValue;
        
        tetherToken.transferFrom(_from, managerAddress, managerValue);
        tetherToken.transferFrom(_from, engineerAddress, engineerValue);
        tetherToken.transferFrom(_from, address(this), surplusValue);
        
        return true;
    }
    
    function transferTotalAllocateFromPay(address _from, uint256 _value)  public payable returns (bool success) {
        
        uint256 managerValue = _value / 200;
        uint256 engineerValue = _value / 200;
        uint256 surplusValue = _value - managerValue - engineerValue;
        
        tetherToken.transferFrom(_from, managerAddress, managerValue);
        tetherToken.transferFrom(_from, engineerAddress, engineerValue);
        tetherToken.transferFrom(_from, totalAddress, surplusValue);
        
        return true;
    }
    
    function transferAllocateMsgPay(uint256 _value)  public payable returns (bool success) {
        
        uint256 managerValue = _value / 200;
        uint256 engineerValue = _value / 200;
        uint256 surplusValue = _value - managerValue - engineerValue;
        
        tetherToken.transferFrom(msg.sender, managerAddress, managerValue);
        tetherToken.transferFrom(msg.sender, engineerAddress, engineerValue);
        tetherToken.transferFrom(msg.sender, address(this), surplusValue);
        
        return true;
    }
    
    function transferTotalAllocateMsgPay(uint256 _value)  public payable returns (bool success) {
        
        uint256 managerValue = _value / 200;
        uint256 engineerValue = _value / 200;
        uint256 surplusValue = _value - managerValue - engineerValue;
        
        tetherToken.transferFrom(msg.sender, managerAddress, managerValue);
        tetherToken.transferFrom(msg.sender, engineerAddress, engineerValue);
        tetherToken.transferFrom(msg.sender, totalAddress, surplusValue);
        
        return true;
    }
    
    
}