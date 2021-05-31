/**
 *Submitted for verification at Etherscan.io on 2021-05-31
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract CodeModules {
    struct Module {
        address owner;
        string name;
        string[] dependencies;
        string code;
        bool isSet;
    }

    struct ModuleBrief {
        address owner;
        string name;
        string[] dependencies;
    }

    address internal owner;

    mapping(string => Module) internal modules;
    string[] internal moduleNames;

    string internal templateBefore;
    string internal templateAfter;

    uint8 internal constant FEATURED_UNKNOWN = 0;
    uint8 internal constant FEATURED_SET = 1;
    uint8 internal constant FEATURED_UNSET = 2;
    string[] internal probablyFeaturedList;
    mapping(string => uint8) internal featuredState;

    modifier onlyOwner {
        require(msg.sender == owner, "only owner");
        _;
    }

    function setFeatured(string memory name) external onlyOwner {
        require(modules[name].isSet, "module must exist");
        if (featuredState[name] == FEATURED_SET) {
            return;
        }

        if (featuredState[name] == FEATURED_UNKNOWN) {
            probablyFeaturedList.push(name);
        }

        featuredState[name] = FEATURED_SET;
    }

    function unsetFeatured(string memory name) external onlyOwner {
        require(modules[name].isSet, "module must exist");
        if (featuredState[name] == FEATURED_UNSET) {
            return;
        }

        if (featuredState[name] == FEATURED_SET) {
            featuredState[name] = FEATURED_UNSET;
        }
    }

    function getAllFeatured()
        external
        view
        returns (ModuleBrief[] memory result)
    {
        string[] memory featuredList =
            new string[](probablyFeaturedList.length);
        uint256 featuredListLength = 0;

        for (uint256 i = 0; i < probablyFeaturedList.length; i++) {
            if (featuredState[probablyFeaturedList[i]] == FEATURED_SET) {
                featuredList[featuredListLength] = probablyFeaturedList[i];
                featuredListLength++;
            }
        }

        result = new ModuleBrief[](featuredListLength);

        for (uint256 i = 0; i < featuredListLength; i++) {
            Module storage m = modules[featuredList[i]];

            result[i] = toBriefModule(m);
        }

        return result;
    }

    function setTemplate(string memory beforeStr, string memory afterStr)
        external
        onlyOwner
    {
        templateBefore = beforeStr;
        templateAfter = afterStr;
    }

    function setBefore(string memory str) external onlyOwner {
        templateBefore = str;
    }

    function setAfter(string memory str) external onlyOwner {
        templateAfter = str;
    }

    function exists(string memory name) external view returns (bool result) {
        return modules[name].isSet;
    }

    function getModule(string memory name)
        external
        view
        returns (Module memory result)
    {
        require(modules[name].isSet, "module must exist");

        return modules[name];
    }

    function toBriefModule(Module storage m)
        internal
        view
        returns (ModuleBrief memory result)
    {
        return
            ModuleBrief({
                owner: m.owner,
                name: m.name,
                dependencies: m.dependencies
            });
    }

    function getAllModules()
        external
        view
        returns (ModuleBrief[] memory result)
    {
        result = new ModuleBrief[](moduleNames.length);

        for (uint256 i = 0; i < moduleNames.length; i++) {
            Module storage m = modules[moduleNames[i]];

            result[i] = toBriefModule(m);
        }

        return result;
    }

    function createModule(
        string memory name,
        string[] memory dependencies,
        string memory code
    ) external {
        for (uint256 i = 0; i < dependencies.length; i++) {
            require(
                modules[dependencies[i]].isSet,
                "all dependencies must exist"
            );
        }

        require(!modules[name].isSet, "module already exists");

        modules[name] = Module({
            owner: msg.sender,
            name: name,
            dependencies: dependencies,
            code: code,
            isSet: true
        });
        moduleNames.push(name);
    }

    function updateModule(
        string memory name,
        string[] memory dependencies,
        string memory code
    ) external {
        require(modules[name].isSet, "module must exist");
        require(
            modules[name].owner == msg.sender,
            "only module owner can update it"
        );

        modules[name].dependencies = dependencies;
        modules[name].code = code;
    }

    function strConcat(string memory _a, string memory _b)
        internal
        pure
        returns (string memory result)
    {
        result = string(abi.encodePacked(bytes(_a), bytes(_b)));
    }

    function strConcat3(
        string memory s1,
        string memory s2,
        string memory s3
    ) internal pure returns (string memory result) {
        result = string(abi.encodePacked(bytes(s1), bytes(s2), bytes(s3)));
    }

    function strConcat4(
        string memory s1,
        string memory s2,
        string memory s3,
        string memory s4
    ) internal pure returns (string memory result) {
        result = string(
            abi.encodePacked(bytes(s1), bytes(s2), bytes(s3), bytes(s4))
        );
    }

    function strConcatArr(string[] memory arr)
        internal
        pure
        returns (string memory result)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            result = strConcat(result, arr[i]);
        }
    }

    function join(string[] memory arr, string memory sep)
        internal
        pure
        returns (string memory result)
    {
        if (arr.length == 0) {
            return "";
        }

        for (uint256 i = 0; i < arr.length - 1; i++) {
            result = strConcat3(result, arr[i], sep);
        }

        result = strConcat(result, arr[arr.length - 1]);
    }

    function stringToJSON(string memory str)
        internal
        pure
        returns (string memory result)
    {
        return strConcat3('"', str, '"');
    }

    function dictToJSON(string[] memory keys, string[] memory values)
        internal
        pure
        returns (string memory result)
    {
        assert(keys.length == values.length);

        string[] memory arr = new string[](keys.length);

        for (uint256 i = 0; i < keys.length; i++) {
            arr[i] = strConcat3(stringToJSON(keys[i]), ": ", values[i]);
        }

        return strConcat3("{", join(arr, ", "), "}");
    }

    function arrToJSON(string[] memory arr)
        internal
        pure
        returns (string memory result)
    {
        return strConcat3("[", join(arr, ", "), "]");
    }

    function strArrToJSON(string[] memory arr)
        internal
        pure
        returns (string memory result)
    {
        if (arr.length == 0) {
            return "[]";
        }

        return strConcat3('["', join(arr, '", "'), '"]');
    }

    function moduleToJSON(Module memory m)
        internal
        pure
        returns (string memory result)
    {
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
        external
        view
        returns (string memory result)
    {
        require(modules[name].isSet, "module doesn't exist");

        string[128] memory stack;
        stack[0] = name;
        uint8 iStack = 1;

        Module[128] memory res;
        uint8 iRes = 0;

        while (iStack > 0) {
            iStack--;
            Module memory m = modules[stack[iStack]];
            res[iRes] = m;
            iRes++;

            for (uint256 i = 0; i < m.dependencies.length; i++) {
                stack[iStack] = m.dependencies[i];
                iStack++;
            }
        }

        string[] memory arr = new string[](iRes);
        for (uint256 i = 0; i < iRes; i++) {
            arr[i] = moduleToJSON(res[i]);
        }

        string memory modulesJSON = arrToJSON(arr);

        return strConcat3(templateBefore, modulesJSON, templateAfter);
    }

    constructor() {
        owner = msg.sender;
    }
}