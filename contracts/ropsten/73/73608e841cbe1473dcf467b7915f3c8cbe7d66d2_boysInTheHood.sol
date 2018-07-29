pragma solidity ^0.4.20;

contract boysInTheHood {
    
    struct Pedro{
        uint coolness;
        uint powerLevel;
        bool isAFool;
        address owner;
        }
        
    Pedro thePedrito;
    
    function customPedro(uint _coolness, uint _powerLevel, bool _isAFool) public {
        
        thePedrito.coolness = _coolness;
        thePedrito.powerLevel = _powerLevel;
        thePedrito.isAFool = _isAFool;
        thePedrito.owner = msg.sender;
    }
    
    function printStats() public view returns(uint, uint, bool, address){
        return (thePedrito.coolness, thePedrito.powerLevel, thePedrito.isAFool, thePedrito.owner);
    }
    
}