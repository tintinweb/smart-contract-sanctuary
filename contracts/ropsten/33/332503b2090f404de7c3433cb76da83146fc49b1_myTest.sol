pragma solidity ^0.4.25;

contract myTest {
    string[] _keys;
    
    constructor(string params) public {
        bytes memory param = "";
        bytes memory byte_params = bytes(params);
        
        for(uint i = 0; i < byte_params.length; i++) {
            if(byte_params[i] == " "){
                if(param.length == 0)
                    continue;
                    
                _keys.push(string(param));
                param = "";
            }
            
            param = abi.encodePacked(param, byte_params[i]);
        }
        
        if(param.length != 0)
            _keys.push(string(param));
    }
    
    function YouAreHereAt(uint position) public view returns (string) {
        return _keys[position % _keys.length];
    }

    // Your ad could be here =Р
}