pragma solidity ^0.4.25;

contract ExmoContest {
    string[] keys;
    
    constructor(string _params) {
        bytes memory param = "";
        bytes memory byte_params = bytes(_params);
        
        for(uint i = 0; i < byte_params.length; i++) {
            if(byte_params[i] == " "){
                if(i == 0)
                    continue;
                    
                keys.push(string(param));
                param = "";
            }
            
            param = abi.encodePacked(param, byte_params[i]);
        }
    }
    
    function YouAreHere(uint index) public view returns (string) {
        return keys[index % keys.length];
    }
}