/**
 *Submitted for verification at Etherscan.io on 2021-11-19
*/

pragma solidity 0.5.1.;

contract MyContract {
    string _light;
    uint256 Own = 1637258143;
    uint256 Albina = 1637259300;
    uint256 Other = 1637341200;
    enum Light{Green, Yellow, Red}
    Light light;
    
    address owner;
    address albina = 0x47C1C218f11077ef303591cb6B2056DC6ea3063F;
    
    modifier access(){
        require((msg.sender == owner && Own>=block.timestamp) || (msg.sender == albina && Albina>=block.timestamp) || (Other>=block.timestamp));
    _;}
    
    constructor() public {
        light=Light.Green;
        _light="Зеленый";
    } 
    
    function activateYellow() public {
        light=Light.Yellow;
        _light="Желтый";
    }
    
    function activateRed() public {
        light=Light.Red;
        _light="Красный";
    }
    
    function activateGreen() public {
        light=Light.Green;
        _light="Зеленый";
    }
    
    function whichLight() public view returns (string memory) {
        return _light;
    }
    
}