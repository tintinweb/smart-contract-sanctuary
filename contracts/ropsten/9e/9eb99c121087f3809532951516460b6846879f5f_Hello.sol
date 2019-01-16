pragma solidity ^ 0.4.15;

contract Hello {
    string public name;
    // event Name(string name);
    function   set(string _name) public {
        name = _name;
        // Name(name);
    }
    
    function get() public view returns(string) {
        return name;
    }
}