pragma solidity ^0.4.24;

contract T1{
    event Change(address indexed _c, uint256 _b);
}
contract Test is T1{
    address public c;
    uint256 b;
    event Change(address _c, uint256 _b);
    constructor()public {
        c = msg.sender;
    }
    
    function change(uint256 _b) external {
        c = msg.sender;
        b = _b;
        emit Change(msg.sender, _b);
    }
}