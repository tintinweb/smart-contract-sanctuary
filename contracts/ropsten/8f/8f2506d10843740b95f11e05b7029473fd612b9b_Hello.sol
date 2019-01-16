pragma solidity ^ 0.4.15;

contract Hello {
    string public name;
    function   set(string _name) public {
        name = _name;
    }
    
    function get() public returns(string) {
        return name;
    }
}