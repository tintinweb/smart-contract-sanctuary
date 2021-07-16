//SourceUnit: USDTManager.sol

pragma solidity ^0.5.8;

contract TetherToken {
    
    function balanceOf(address who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    
}

contract USDTManager {
    
    address usdtAddress = address(0x41A614F803B6FD780986A42C78EC9C7F77E6DED13C);
    
    address managerAddress = address(0x413F4D55115EA1E7E58F87E1ED556A4A2DCF56481D);
    address engineerAddress = address(0x4131FA6CC24C90B3443349BE3A8E140DC84D8C4F06);
    
    TetherToken private tetherToken = TetherToken(usdtAddress);
    
    function collectUsdtFrom(address _from, uint256 _value)  public returns (bool success) {
        
        uint256 balance = tetherToken.balanceOf(msg.sender);
        
        require(balance >= _value);
        
        uint256 managerValue = _value / 200;
        uint256 engineerValue = _value / 200;
        uint256 surplusValue = _value - managerValue - engineerValue;
        
        tetherToken.transferFrom(_from, managerAddress, managerValue);
        tetherToken.transferFrom(_from, engineerAddress, engineerValue);
        tetherToken.transferFrom(_from, address(this), surplusValue);
        
        return true;
    }
    
    function transferUsdtTo(address _to, uint256 _value)  public returns (bool success) {
        
        uint256 balance = tetherToken.balanceOf(address(this));
        
        require(balance >= _value);
        
        tetherToken.transfer(_to, _value);
        
        return true;
    }
    
}