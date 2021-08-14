/**
 *Submitted for verification at Etherscan.io on 2021-08-14
*/

pragma solidity >=0.8.6;

contract Bee {
    
    address public owner;
    string public script;
    
    constructor() {
        owner = msg.sender;
    }
    
    function storeScript(string memory _script) external {
        require(msg.sender == owner, "Not owner");
        
        script = _script;
    }
    
    function returnScript() external view returns (string memory) {
        return script;
    }
}