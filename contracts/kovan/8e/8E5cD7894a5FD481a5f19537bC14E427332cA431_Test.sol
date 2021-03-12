/**
 *Submitted for verification at Etherscan.io on 2021-03-12
*/

contract Test {
    
    uint public value;
    
    function  getValue() view public returns(uint256) {
        return value;
    }
    
    
    function setValue(uint _value) external {
        value = _value;
    }
    
}