/**
 *Submitted for verification at Etherscan.io on 2021-05-21
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7.0;

contract CodeModules {
    struct Module {
        address owner;
        string name;
        string[] dependencies;
        string code;
        bool isSet;
    }

    mapping (string => Module) modules;
    
    function createModule(string memory name, string[] memory dependencies, string memory code) external {
        for (uint i = 0; i < dependencies.length; i++) {
            require(modules[dependencies[i]].isSet, "all dependencies must exist");
        }
        
        require(!modules[name].isSet, "module with this name already exists");
        
        modules[name] = Module({
            owner: msg.sender,
            name: name,
            dependencies: dependencies,
            code: code,
            isSet: true
        });
    }
    
    function strConcat(string memory _a, string memory _b)
    internal pure
    returns(string memory result) {
        result = string(abi.encodePacked(bytes(_a), bytes(_b)));
    }
    
    function strConcatArr(string[] memory arr) 
    internal pure
    returns(string memory result) {
        for (uint i = 0; i < arr.length; i++) {
            result = strConcat(result, arr[i]);
        }
    }
    
    function moduleToJSON(Module memory m)
    internal pure
    returns(string memory result) {
        string[] memory arr = new string[](8);
        arr[0] = '{\n';
        arr[1] = '  "name": "'; arr[2] = m.name; arr[3] = '",\n';
        arr[4] = '  "code": "'; arr[5] = m.code; arr[6] = '",\n';
        arr[7] = '}\n';
        
        result = strConcatArr(arr);
    }
    
    function getHtml(string memory name)
    external view
    returns(string memory result) {
        require(modules[name].isSet, "module with this name doesn't exist");
        
        string[128] memory stack;
        stack[0] = name;
        uint8 i_stack = 1;
        
        Module[128] memory res;
        uint8 i_res = 0;
        
        while (i_stack > 0) {
            i_stack--;
            Module memory m = modules[stack[i_stack]];
            res[i_res] = m;
            i_res++;
            
            for (uint i = 0; i < m.dependencies.length; i++) {
                stack[i_stack] = m.dependencies[i];
                i_stack++;
            }
        }
        
        string[] memory arr = new string[](res.length + 2);
        arr[0] = "[";
        for (uint i = 0; i < res.length - 1; i++) {
            arr[1 + i] = strConcat(moduleToJSON(res[i]), ", ");
        }
        arr[res.length] = moduleToJSON(res[res.length - 1]);
        arr[res.length + 1] = "]";
        
        string memory modules_JSON = strConcatArr(arr);
        
        return modules_JSON;
    }

    constructor() {
    }
}