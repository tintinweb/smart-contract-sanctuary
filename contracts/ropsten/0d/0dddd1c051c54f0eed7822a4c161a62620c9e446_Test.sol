pragma solidity ^0.4.24;

contract T1{
    address public c;
    uint256 public b;
    event Change(address indexed _c, uint256 _b);
    
    constructor()public {
        c = msg.sender;
        b = 7;
    }
    
    function change(uint256 _b) public {
        c = msg.sender;
        b = _b;
        emit Change(msg.sender, _b);
    }
}
contract Test is T1{
    uint256 public d;
    event ChangeTest(uint256 _d);
    
    constructor()public {
        d = 5;
    }
    
    function changeTest(uint256 _d) external {
        change(_d);
        d = _d;
        emit ChangeTest(_d);
    }
}