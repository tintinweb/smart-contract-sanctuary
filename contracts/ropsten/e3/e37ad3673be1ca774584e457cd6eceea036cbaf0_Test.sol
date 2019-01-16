pragma solidity ^0.4.24;

contract T1{
    event Change(address indexed _c);
}
contract Test is T1{
    address public c;
    event Change(address _c);
    constructor()public {
        c = msg.sender;
    }
    
    function change(address _c) external {
        c = _c;
        
        emit Change(_c);
    }
}