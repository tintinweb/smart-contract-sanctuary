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

    address owner;

    mapping (string => Module) modules;

    string template_before;
    string template_after;

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

    function setTemplate(string memory beforeStr, string memory afterStr) external onlyOwner {
        template_before = beforeStr;
        template_after = afterStr;
    }

    function setBefore(string memory str) external onlyOwner {
        template_before = str;
    }

    function setAfter(string memory str) external onlyOwner {
        template_after = str;
    }

    function exists(string memory name)
    external view
    returns(bool result) {
        return modules[name].isSet;
    }

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

    function updateModule(string memory name, string[] memory dependencies, string memory code) external {
        require(modules[name].isSet, "module must exist");
        require(modules[name].owner == msg.sender, "only module owner can update it");

        modules[name].dependencies = dependencies;
        modules[name].code = code;
    }

    function strConcat(string memory _a, string memory _b)
    internal pure
    returns(string memory result) {
        result = string(abi.encodePacked(bytes(_a), bytes(_b)));
    }

    function strConcat3(string memory s1, string memory s2, string memory s3)
    internal pure
    returns(string memory result) {
        result = string(abi.encodePacked(bytes(s1), bytes(s2), bytes(s3)));
    }

    function strConcat4(string memory s1, string memory s2, string memory s3, string memory s4)
    internal pure
    returns(string memory result) {
        result = string(abi.encodePacked(bytes(s1), bytes(s2), bytes(s3), bytes(s4)));
    }

    function strConcatArr(string[] memory arr)
    internal pure
    returns(string memory result) {
        for (uint i = 0; i < arr.length; i++) {
            result = strConcat(result, arr[i]);
        }
    }

    function join(string[] memory arr, string memory sep)
    internal pure
    returns(string memory result) {
        if (arr.length == 0) { return ""; }

        for (uint i = 0; i < arr.length - 1; i++) {
            result = strConcat3(result, arr[i], sep);
        }

        result = strConcat(result, arr[arr.length - 1]);
    }

    function stringToJSON(string memory str)
    internal pure
    returns(string memory result) {
        return strConcat3('"', str, '"');
    }

    function dictToJSON(string[] memory keys, string[] memory values)
    internal pure
    returns(string memory result) {
        assert(keys.length == values.length);

        string[] memory arr = new string[](keys.length);

        for (uint i = 0; i < keys.length; i++) {
            arr[i] = strConcat3(stringToJSON(keys[i]), ': ', values[i]);
        }

        return strConcat3("{", join(arr, ", "), "}");
    }

    function arrToJSON(string[] memory arr)
    internal pure
    returns(string memory result) {
        return strConcat3("[", join(arr, ", "), "]");
    }

    function strArrToJSON(string[] memory arr)
    internal pure
    returns(string memory result) {
        if (arr.length == 0) { return "[]"; }

        return strConcat3('["', join(arr, '", "'), '"]');
    }

    function moduleToJSON(Module memory m)
    internal pure
    returns(string memory result) {
        string[] memory keys = new string[](3);
        keys[0] = "name";
        keys[1] = "code";
        keys[2] = "dependencies";

        string[] memory values = new string[](3);
        values[0] = stringToJSON(m.name);
        values[1] = stringToJSON(m.code);
        values[2] = strArrToJSON(m.dependencies);

        return dictToJSON(keys, values);
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

        string[] memory arr = new string[](i_res);
        for (uint i = 0; i < i_res; i++) {
            arr[i] = moduleToJSON(res[i]);
        }

        string memory modules_JSON = arrToJSON(arr);

        return strConcat3(template_before, modules_JSON, template_after);
    }

    constructor() {
        owner = msg.sender;
    }
}