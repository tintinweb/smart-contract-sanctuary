pragma solidity ^0.4.24;

contract T1{
    event Change(uint256 _c);
}
contract Test is T1{
    uint public c;
    
    constructor()public {
        c = 7;
    }
    
    function change(uint256 _c) external {
        c = _c;
        
        emit Change(_c);
    }
}