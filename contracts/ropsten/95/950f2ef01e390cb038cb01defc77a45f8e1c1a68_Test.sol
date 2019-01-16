pragma solidity ^0.4.24;

contract Test{
    uint public c;
    event Change();
    constructor()public {
        c = 7;
    }
    
    function change(uint256 _c) external {
        c = _c;
        
        emit Change();
    }
}