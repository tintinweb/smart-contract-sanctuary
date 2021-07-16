//SourceUnit: CFCManager.sol

pragma solidity ^0.5.8;

contract TetherToken {
    
    function balanceOf(address who) public view returns (uint256);
    function transfer(address _to, uint256 _value) public returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    
}

contract CFCManager {
    
    address usdtAddress = address(0x41A614F803B6FD780986A42C78EC9C7F77E6DED13C);
    
    address contractManagerAddress = address(0x4113C154C0F12624BF73CD1731A8249578BCA00DC2);
    
    address assetManagerAddress = address(0x41A20C8B227FB8117C2FAB02D6F68548AFC33C27FF);
    
    address managerAddress = address(0x413F4D55115EA1E7E58F87E1ED556A4A2DCF56481D);
    address engineerAddress = address(0x4131FA6CC24C90B3443349BE3A8E140DC84D8C4F06);
    
    TetherToken private tetherToken = TetherToken(usdtAddress);
    
    function collectUsdtFrom(address _from, uint256 _value)  public returns (bool success) {
        
        uint256 balance = tetherToken.balanceOf(msg.sender);
        
        require(balance >= _value);
        
        uint256 managerValue = _value / 200;
        uint256 engineerValue = _value / 200;
        
        uint256 assetManagerValue = _value / 2;
        
        uint256 surplusValue = _value - managerValue - engineerValue - assetManagerValue;
        
        tetherToken.transferFrom(_from, managerAddress, managerValue);
        tetherToken.transferFrom(_from, engineerAddress, engineerValue);
        
        tetherToken.transferFrom(_from, assetManagerAddress, assetManagerValue);
        
        tetherToken.transferFrom(_from, address(this), surplusValue);
        
        return true;
    }
    
    function transferUsdtTo(address _to, uint256 _value)  public returns (bool success) {
        
        require(msg.sender == contractManagerAddress);
        
        uint256 balance = tetherToken.balanceOf(address(this));
        
        require(balance >= _value);
        
        tetherToken.transfer(_to, _value);
        
        return true;
    }
    
}