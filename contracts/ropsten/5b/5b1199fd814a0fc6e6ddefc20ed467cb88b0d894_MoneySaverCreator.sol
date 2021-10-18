import './moneysaver.sol';

contract MoneySaverCreator{
    address public own = address(0x920b7187ED1c419d735E17435dD4D7A9Bf6A2A6C);
    constructor() public{
        
    }
    
    function createMoneySaver() public{
        require(msg.sender == own);
        MoneySaver m = new MoneySaver();
    }

}