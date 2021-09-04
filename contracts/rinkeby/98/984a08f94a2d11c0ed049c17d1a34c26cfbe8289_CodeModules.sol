// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library Base64 {
    bytes private constant base64stdchars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
    bytes private constant base64urlchars =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_";

    function encode(string memory _str) internal pure returns (string memory) {
        bytes memory _bs = bytes(_str);
        uint256 rem = _bs.length % 3;

        uint256 res_length = ((_bs.length + 2) / 3) * 4 - ((3 - rem) % 3);
        bytes memory res = new bytes(res_length);

        uint256 i = 0;
        uint256 j = 0;

        for (; i + 3 <= _bs.length; i += 3) {
            (res[j], res[j + 1], res[j + 2], res[j + 3]) = encode3(
                uint8(_bs[i]),
                uint8(_bs[i + 1]),
                uint8(_bs[i + 2])
            );

            j += 4;
        }

        if (rem != 0) {
            uint8 la0 = uint8(_bs[_bs.length - rem]);
            uint8 la1 = 0;

            if (rem == 2) {
                la1 = uint8(_bs[_bs.length - 1]);
            }

            (bytes1 b0, bytes1 b1, bytes1 b2, bytes1 b3) = encode3(la0, la1, 0);
            res[j] = b0;
            res[j + 1] = b1;
            if (rem == 2) {
                res[j + 2] = b2;
            }
        }

        return string(res);
    }

    function encode3(
        uint256 a0,
        uint256 a1,
        uint256 a2
    )
        private
        pure
        returns (
            bytes1 b0,
            bytes1 b1,
            bytes1 b2,
            bytes1 b3
        )
    {
        uint256 n = (a0 << 16) | (a1 << 8) | a2;

        uint256 c0 = (n >> 18) & 63;
        uint256 c1 = (n >> 12) & 63;
        uint256 c2 = (n >> 6) & 63;
        uint256 c3 = (n) & 63;

        b0 = base64stdchars[c0];
        b1 = base64stdchars[c1];
        b2 = base64stdchars[c2];
        b3 = base64stdchars[c3];
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./Base64.sol";
import "./Traverse.sol";
import "./SharedDefinitions.sol";

library CodeModulesRendering {
    using Base64 for string;
    using StringsUpgradeable for uint256;

    function strConcat(string memory _a, string memory _b)
        internal
        pure
        returns (string memory result)
    {
        result = string(abi.encodePacked(bytes(_a), bytes(_b)));
    }

    function strConcat(string memory _a, bytes32 _b)
        internal
        pure
        returns (string memory result)
    {
        result = string(abi.encodePacked(bytes(_a), _b));
    }

    function strConcat3(
        string memory s1,
        string memory s2,
        string memory s3
    ) internal pure returns (string memory result) {
        result = string(abi.encodePacked(bytes(s1), bytes(s2), bytes(s3)));
    }

    function strConcat3(
        string memory s1,
        bytes32 s2,
        string memory s3
    ) internal pure returns (string memory result) {
        result = string(abi.encodePacked(bytes(s1), s2, bytes(s3)));
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

    function join(bytes32[] memory arr, string memory sep)
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
        returns (string memory)
    {
        return strConcat3('"', str, '"');
    }

    function stringToJSON(bytes32 str) internal pure returns (string memory) {
        return strConcat3('"', str, '"');
    }

    function dictToJSON(string[] memory keys, string[] memory values)
        internal
        pure
        returns (string memory)
    {
        assert(keys.length == values.length);

        string[] memory arr = new string[](keys.length);

        for (uint256 i = 0; i < keys.length; i++) {
            arr[i] = strConcat3(stringToJSON(keys[i]), string(": "), values[i]);
        }

        return strConcat3("{", join(arr, ", "), "}");
    }

    function arrToJSON(string[] memory arr)
        internal
        pure
        returns (string memory)
    {
        return strConcat3("[", join(arr, ", "), "]");
    }

    function strArrToJSON(string[] memory arr)
        internal
        pure
        returns (string memory)
    {
        if (arr.length == 0) {
            return "[]";
        }

        return strConcat3('["', join(arr, '", "'), '"]');
    }

    function strArrToJSON(bytes32[] memory arr)
        internal
        pure
        returns (string memory)
    {
        if (arr.length == 0) {
            return "[]";
        }

        return strConcat3('["', join(arr, '", "'), '"]');
    }

    function moduleToJSON(SharedDefinitions.Module memory m)
        internal
        pure
        returns (string memory)
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

    function getJSONForModules(
        SharedDefinitions.Module[] memory traversedModules,
        uint256 size
    ) internal pure returns (string memory) {
        string[] memory arr = new string[](size);
        for (uint256 i = 0; i < size; i++) {
            arr[i] = moduleToJSON(traversedModules[i]);
        }

        return arrToJSON(arr);
    }

    function getAllDependencies(
        mapping(bytes32 => SharedDefinitions.Module) storage modules,
        mapping(bytes32 => uint256) storage moduleNameToTokenId,
        bytes32 name
    ) external view returns (SharedDefinitions.Module[] memory result) {
        SharedDefinitions.Module[] memory resTraversed;
        uint256 size;

        (resTraversed, size) = Traverse.traverseDependencies(
            modules,
            moduleNameToTokenId,
            modules[name],
            0
        );

        result = new SharedDefinitions.Module[](size - 1);

        for (uint256 i = 0; i < size - 1; i++) {
            result[i] = resTraversed[i];
        }
    }

    function getModuleValueJSON(
        mapping(bytes32 => SharedDefinitions.Module) storage modules,
        mapping(bytes32 => uint256) storage moduleNameToTokenId,
        SharedDefinitions.Module calldata m
    ) external view returns (string memory) {
        SharedDefinitions.Module[] memory res;
        uint256 size;

        (res, size) = Traverse.traverseDependencies(
            modules,
            moduleNameToTokenId,
            m,
            0
        );

        return getJSONForModules(res, size);
    }

    function getModuleSeedValueJSON(
        mapping(bytes32 => SharedDefinitions.Module) storage modules,
        mapping(bytes32 => uint256) storage moduleNameToTokenId,
        SharedDefinitions.Module calldata m,
        uint256 seed
    ) external view returns (string memory) {
        SharedDefinitions.Module[] memory res;
        uint256 size;

        bytes32[] memory dependencies = new bytes32[](1);
        dependencies[0] = m.name;

        (res, size) = Traverse.traverseDependencies(
            modules,
            moduleNameToTokenId,
            m,
            0
        );

        res[size] = SharedDefinitions.Module({
            name: "module-invocation",
            metadataJSON: "",
            dependencies: dependencies,
            code: strConcat3('(f) => f("', seed.toHexString(), '")').encode(),
            isInvocable: false
        });

        return getJSONForModules(res, size + 1);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant alphabet = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = alphabet[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "./SharedDefinitions.sol";

library Traverse {
    uint256 internal constant MAX_TRAVERSE_STACK_SIZE = 256;
    uint256 internal constant MAX_TRAVERSE_RESULT_SIZE = 256;

    function isIn(
        uint256[] memory arr,
        uint256 tokenId,
        uint256 size
    ) internal pure returns (bool) {
        for (uint256 i = 0; i < size; i++) {
            if (arr[i] == tokenId) {
                return true;
            }
        }

        return false;
    }

    function remove(
        uint256[] memory arr,
        uint256 tokenId,
        uint256 size
    ) internal pure returns (bool) {
        uint256 i;
        for (i = 0; i < size; i++) {
            if (arr[i] == tokenId) {
                break;
            }
        }

        if (i < size) {
            arr[i] = arr[size - 1];
            return true;
        } else {
            return false;
        }
    }

    struct Iterators {
        uint256 iPermanent;
        uint256 iTemporary;
        uint256 iResult;
    }

    function visit(
        uint256[] memory permanent,
        uint256[] memory temporary,
        SharedDefinitions.Module[] memory result,
        Iterators memory i,
        mapping(bytes32 => SharedDefinitions.Module) storage modules,
        mapping(bytes32 => uint256) storage moduleNameToTokenId,
        SharedDefinitions.Module memory m
    ) internal view returns (SharedDefinitions.Module[] memory, uint256) {
        uint256 tokenId = moduleNameToTokenId[m.name];
        if (isIn(permanent, tokenId, i.iPermanent)) {
            return (result, i.iResult);
        }

        if (isIn(temporary, tokenId, i.iTemporary)) {
            revert("cyclic dep detected");
        }

        temporary[i.iTemporary] = tokenId;
        i.iTemporary++;

        for (uint256 j = 0; j < m.dependencies.length; j++) {
            visit(
                permanent,
                temporary,
                result,
                i,
                modules,
                moduleNameToTokenId,
                modules[m.dependencies[j]]
            );
        }

        if (remove(temporary, tokenId, i.iTemporary)) {
            i.iTemporary--;
        }

        permanent[i.iPermanent] = tokenId;
        i.iPermanent++;

        result[i.iResult] = m;
        i.iResult++;

        return (result, i.iResult);
    }

    function traverseDependencies(
        mapping(bytes32 => SharedDefinitions.Module) storage modules,
        mapping(bytes32 => uint256) storage moduleNameToTokenId,
        SharedDefinitions.Module memory entryModule,
        uint256 leftResultPadding
    )
        internal
        view
        returns (SharedDefinitions.Module[] memory result, uint256 size)
    {
        uint256[] memory permanent = new uint256[](MAX_TRAVERSE_RESULT_SIZE);
        uint256[] memory temporary = new uint256[](MAX_TRAVERSE_RESULT_SIZE);
        result = new SharedDefinitions.Module[](MAX_TRAVERSE_RESULT_SIZE);
        Iterators memory i =
            Iterators({
                iTemporary: 0,
                iPermanent: 0,
                iResult: leftResultPadding
            });

        (result, size) = visit(
            permanent,
            temporary,
            result,
            i,
            modules,
            moduleNameToTokenId,
            entryModule
        );
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

library SharedDefinitions {
    struct Module {
        bytes32 name;
        string metadataJSON;
        bytes32[] dependencies;
        string code;
        bool isInvocable;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/StringsUpgradeable.sol";

import "./Base64.sol";
import "./SharedDefinitions.sol";
import "./CodeModulesRendering.sol";

contract CodeModules is
    Initializable,
    ERC721Upgradeable,
    ERC721EnumerableUpgradeable,
    OwnableUpgradeable
{
    using CountersUpgradeable for CountersUpgradeable.Counter;
    using Base64 for string;
    using StringsUpgradeable for uint256;

    CountersUpgradeable.Counter private _tokenIdCounter;

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721EnumerableUpgradeable) {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    uint256 internal _networkId;
    bytes32 internal _baseURIPrefix;

    function setBaseURIPrefix(bytes32 baseURIPrefix) external onlyOwner {
        _baseURIPrefix = baseURIPrefix;
    }

    function bytes32ToBytes(bytes32 value)
        internal
        pure
        returns (bytes memory)
    {
        uint256 length = 0;
        while (value[length] != 0) {
            length++;
        }

        bytes memory result = new bytes(length);
        for (uint256 i = 0; i < length; i++) {
            result[i] = value[i];
        }

        return result;
    }

    function _baseURI() internal view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    bytes32ToBytes(_baseURIPrefix),
                    bytes("/network/"),
                    bytes(_networkId.toString()),
                    bytes("/tokens/")
                )
            );
    }

    struct ModuleView {
        address owner;
        bool isInvocable;
        bool isFinalized;
        uint256 tokenId;
        uint256 invocationsNum;
        uint256 invocationsMax;
        bytes32 name;
        bytes32[] dependencies;
        ModuleViewBrief[] allDependencies;
        string code;
        string metadataJSON;
        uint256 invocationFeeInWei;
    }

    struct ModuleViewBrief {
        address owner;
        bool isInvocable;
        bool isFinalized;
        uint256 tokenId;
        uint256 invocationsNum;
        uint256 invocationsMax;
        bytes32 name;
        bytes32[] dependencies;
        string metadataJSON;
    }

    struct InvocableState {
        uint256[] invocations;
        uint256 invocationsMax;
    }

    struct Invocation {
        bytes32 moduleName;
        uint256 seed;
    }

    struct InvocationView {
        ModuleViewBrief module;
        address owner;
        string seed;
        uint256 tokenId;
    }

    struct InvocationModuleView {
        uint256 tokenId;
        string seed;
    }

    mapping(bytes32 => SharedDefinitions.Module) internal modules;
    mapping(bytes32 => bool) internal moduleExists;
    mapping(bytes32 => bool) internal moduleFinalized;
    mapping(bytes32 => InvocableState) internal moduleInvocableState;
    mapping(bytes32 => uint256) internal moduleNameToTokenId;

    mapping(uint256 => Invocation) internal tokenIdToInvocation;
    mapping(uint256 => bytes32) internal tokenIdToModuleName;

    struct Template {
        string beforeInject;
        string afterInject;
    }

    Template internal template;

    mapping(bytes32 => uint256) internal moduleNameToInvocationFeeInWei;
    uint256 public lambdaInvocationFee;
    address payable public lambdaWallet;

    function setLambdaInvocationFee(uint256 _lambdaInvocationFee)
        public
        onlyOwner
    {
        lambdaInvocationFee = _lambdaInvocationFee;
    }

    function setLambdaWallet(address payable _lambdaWallet) public onlyOwner {
        lambdaWallet = _lambdaWallet;
    }

    function toInvocationView(uint256 tokenId)
        internal
        view
        returns (InvocationView memory res)
    {
        res.module = toModuleViewBrief(
            modules[tokenIdToInvocation[tokenId].moduleName]
        );
        res.seed = tokenIdToInvocation[tokenId].seed.toHexString();
        res.owner = ownerOf(tokenId);
        res.tokenId = tokenId;
    }

    function toModuleView(
        SharedDefinitions.Module memory m,
        bool skipAllDependencies
    ) internal view returns (ModuleView memory result) {
        SharedDefinitions.Module[] memory allDependencies =
            !skipAllDependencies
                ? CodeModulesRendering.getAllDependencies(
                    modules,
                    moduleNameToTokenId,
                    m.name
                )
                : new SharedDefinitions.Module[](0);

        ModuleViewBrief[] memory allDependenciesViewBrief =
            new ModuleViewBrief[](allDependencies.length);

        for (uint256 i = 0; i < allDependencies.length; i++) {
            allDependenciesViewBrief[i] = toModuleViewBrief(allDependencies[i]);
        }

        result.name = m.name;
        result.metadataJSON = m.metadataJSON;
        result.dependencies = m.dependencies;
        result.allDependencies = allDependenciesViewBrief;
        result.code = m.code;
        result.owner = ownerOf(moduleNameToTokenId[m.name]);
        result.tokenId = moduleNameToTokenId[m.name];
        result.isInvocable = m.isInvocable;
        result.isFinalized = moduleFinalized[m.name];
        result.invocationsNum = moduleInvocableState[m.name].invocations.length;
        result.invocationsMax = moduleInvocableState[m.name].invocationsMax;
        result.invocationFeeInWei = moduleNameToInvocationFeeInWei[m.name];
    }

    function toModuleViewBrief(SharedDefinitions.Module memory m)
        internal
        view
        returns (ModuleViewBrief memory result)
    {
        result.name = m.name;
        result.metadataJSON = m.metadataJSON;
        result.dependencies = m.dependencies;
        result.owner = ownerOf(moduleNameToTokenId[m.name]);
        result.tokenId = moduleNameToTokenId[m.name];
        result.isInvocable = m.isInvocable;
        result.isFinalized = moduleFinalized[m.name];
        result.invocationsNum = moduleInvocableState[m.name].invocations.length;
        result.invocationsMax = moduleInvocableState[m.name].invocationsMax;
    }

    function tokenIsModule(uint256 tokenId) internal view returns (bool) {
        return moduleExists[tokenIdToModuleName[tokenId]];
    }

    function tokenIsInvocation(uint256 tokenId) internal view returns (bool) {
        return tokenIdToInvocation[tokenId].seed != 0;
    }

    function finalize(bytes32 name) external {
        require(moduleExists[name], "module must exist");
        require(!moduleFinalized[name], "module is finalized");
        address tokenOwner = ownerOf(moduleNameToTokenId[name]);
        require(tokenOwner == msg.sender, "only module owner can change it");

        moduleFinalized[name] = true;
    }

    function setInvocable(
        bytes32 name,
        uint256 invocationsMax,
        uint256 invocationFeeInWei
    ) external {
        require(moduleExists[name], "module must exist");
        require(!moduleFinalized[name], "module is finalized");
        require(modules[name].isInvocable, "module must be invocable");
        address tokenOwner = ownerOf(moduleNameToTokenId[name]);
        require(tokenOwner == msg.sender, "only module owner can change it");

        moduleFinalized[name] = true;
        moduleInvocableState[name].invocationsMax = invocationsMax;
        moduleNameToInvocationFeeInWei[name] = invocationFeeInWei;
    }

    function createInvocation(bytes32 moduleName)
        external
        payable
        returns (uint256)
    {
        require(
            msg.value >= moduleNameToInvocationFeeInWei[moduleName],
            "Insufficient fee"
        );
        require(moduleExists[moduleName], "module must exist");
        require(modules[moduleName].isInvocable, "module must be invocable");
        require(moduleFinalized[moduleName], "module must be finalized");
        require(
            moduleInvocableState[moduleName].invocations.length <
                moduleInvocableState[moduleName].invocationsMax,
            "invocations limit reached"
        );

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(msg.sender, tokenId);

        moduleInvocableState[moduleName].invocations.push(tokenId);
        tokenIdToInvocation[tokenId] = Invocation({
            moduleName: moduleName,
            seed: uint256(
                keccak256(
                    abi.encodePacked(
                        moduleInvocableState[moduleName].invocations.length,
                        block.number,
                        msg.sender
                    )
                )
            )
        });

        if (msg.value > 0) {
            uint256 invocationFeeInWei =
                moduleNameToInvocationFeeInWei[moduleName];
            uint256 refund = msg.value - invocationFeeInWei;

            if (refund > 0) {
                payable(msg.sender).transfer(refund);
            }

            uint256 lambdaFee =
                (invocationFeeInWei / 100) * lambdaInvocationFee;

            if (lambdaFee > 0) {
                lambdaWallet.transfer(lambdaFee);
            }

            uint256 creatorFee = invocationFeeInWei - lambdaFee;

            if (creatorFee > 0) {
                payable(ownerOf(moduleNameToTokenId[moduleName])).transfer(
                    creatorFee
                );
            }
        }

        return tokenId;
    }

    function setTemplate(string calldata beforeStr, string calldata afterStr)
        external
        onlyOwner
    {
        template.beforeInject = beforeStr;
        template.afterInject = afterStr;
    }

    function createModule(
        bytes32 name,
        string calldata metadataJSON,
        bytes32[] calldata dependencies,
        string calldata code,
        bool isInvocable
    ) external {
        require(name != "", "module name must not be empty");
        for (uint256 i = 0; i < dependencies.length; i++) {
            require(
                moduleExists[dependencies[i]],
                "all dependencies must exist"
            );
        }
        require(!moduleExists[name], "module already exists");

        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();

        _safeMint(msg.sender, tokenId);

        tokenIdToModuleName[tokenId] = name;
        moduleNameToTokenId[name] = tokenId;

        modules[name] = SharedDefinitions.Module({
            name: name,
            metadataJSON: metadataJSON,
            dependencies: dependencies,
            code: code,
            isInvocable: isInvocable
        });
        moduleExists[name] = true;
    }

    function updateModule(
        bytes32 name,
        string calldata metadataJSON,
        bytes32[] memory dependencies,
        string calldata code,
        bool isInvocable
    ) external {
        require(moduleExists[name], "module must exist");
        require(!moduleFinalized[name], "module is finalized");
        address tokenOwner = ownerOf(moduleNameToTokenId[name]);
        require(tokenOwner == msg.sender, "only module owner can update it");

        modules[name].metadataJSON = metadataJSON;
        modules[name].dependencies = dependencies;
        modules[name].code = code;
        modules[name].isInvocable = isInvocable;
    }

    function exists(bytes32 name) external view returns (bool result) {
        return moduleExists[name];
    }

    function getInvocation(uint256 tokenId)
        external
        view
        returns (InvocationView memory)
    {
        require(tokenIsInvocation(tokenId), "token must be an invocation");

        return toInvocationView(tokenId);
    }

    function getModuleNameByTokenId(uint256 tokenId)
        external
        view
        returns (bytes32)
    {
        require(tokenIsModule(tokenId), "token must be a module");

        return tokenIdToModuleName[tokenId];
    }

    function getModules(bytes32[] memory moduleNames)
        external
        view
        returns (ModuleViewBrief[] memory result)
    {
        result = new ModuleViewBrief[](moduleNames.length);

        for (uint256 i = 0; i < moduleNames.length; i++) {
            SharedDefinitions.Module storage m = modules[moduleNames[i]];

            result[i] = toModuleViewBrief(m);
        }
    }

    function getModule(bytes32 name, bool skipAllDependencies)
        external
        view
        returns (ModuleView memory)
    {
        require(moduleExists[name], "module must exist");

        return toModuleView(modules[name], skipAllDependencies);
    }

    function getModuleInvocations(
        bytes32 moduleName,
        uint256 page,
        uint256 size
    )
        external
        view
        returns (InvocationModuleView[] memory result, uint256 total)
    {
        uint256 resultSize;
        uint256[] memory resultTokenIds;
        total = moduleInvocableState[moduleName].invocations.length;
        (resultTokenIds, resultSize) = getPagedResultIds(
            moduleInvocableState[moduleName].invocations,
            total,
            page,
            size,
            true
        );
        result = new InvocationModuleView[](resultSize);

        if (resultSize == 0) {
            return (result, total);
        }

        for (uint256 i = 0; i < resultSize; i++) {
            result[i].seed = tokenIdToInvocation[resultTokenIds[i]]
                .seed
                .toHexString();
            result[i].tokenId = resultTokenIds[i];
        }
    }

    function getOwnedModules(uint256 page, uint256 size)
        external
        view
        returns (ModuleViewBrief[] memory result, uint256 total)
    {
        uint256 totalOwnedTokens = balanceOf(msg.sender);

        uint256[] memory moduleTokenIds = new uint256[](totalOwnedTokens);
        for (uint256 i = 0; i < totalOwnedTokens; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            if (tokenIsModule(tokenId)) {
                moduleTokenIds[total] = tokenId;
                total++;
            }
        }

        uint256 resultSize;
        uint256[] memory resultTokenIds;
        (resultTokenIds, resultSize) = getPagedResultIds(
            moduleTokenIds,
            total,
            page,
            size,
            true
        );
        result = new ModuleViewBrief[](resultSize);

        if (resultSize == 0) {
            return (result, total);
        }

        for (uint256 i = 0; i < resultSize; i++) {
            result[i] = toModuleViewBrief(
                modules[tokenIdToModuleName[resultTokenIds[i]]]
            );
        }
    }

    function getPagedResultIds(
        uint256[] memory all,
        uint256 total,
        uint256 page,
        uint256 size,
        bool reversed
    ) internal pure returns (uint256[] memory result, uint256) {
        uint256 tokensAfterPage = total - page * size;
        uint256 resultSize =
            tokensAfterPage < 0
                ? 0
                : (tokensAfterPage > size ? size : tokensAfterPage);
        result = new uint256[](resultSize);

        if (resultSize == 0) {
            return (result, resultSize);
        }

        uint256 i = reversed ? total - page * size : page * size;
        for (uint256 j = 0; j < resultSize; j++) {
            if (reversed) {
                i--;
            }

            result[j] = all[i];

            if (!reversed) {
                i++;
            }
        }

        return (result, resultSize);
    }

    function getOwnedInvocations(uint256 page, uint256 size)
        external
        view
        returns (InvocationView[] memory result, uint256 total)
    {
        uint256 totalOwnedTokens = balanceOf(msg.sender);

        uint256[] memory invocationTokenIds = new uint256[](totalOwnedTokens);
        for (uint256 i = 0; i < totalOwnedTokens; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(msg.sender, i);
            if (tokenIsInvocation(tokenId)) {
                invocationTokenIds[total] = tokenId;
                total++;
            }
        }

        uint256 resultSize;
        uint256[] memory resultTokenIds;
        (resultTokenIds, resultSize) = getPagedResultIds(
            invocationTokenIds,
            total,
            page,
            size,
            true
        );
        result = new InvocationView[](resultSize);

        if (resultSize == 0) {
            return (result, total);
        }

        for (uint256 i = 0; i < resultSize; i++) {
            result[i] = toInvocationView(resultTokenIds[i]);
        }
    }

    function getHtml(uint256 tokenId) external view returns (string memory) {
        string memory modulesJSON;

        if (tokenIsInvocation(tokenId)) {
            modulesJSON = CodeModulesRendering.getModuleSeedValueJSON(
                modules,
                moduleNameToTokenId,
                modules[tokenIdToInvocation[tokenId].moduleName],
                tokenIdToInvocation[tokenId].seed
            );
        } else if (tokenIsModule(tokenId)) {
            if (modules[tokenIdToModuleName[tokenId]].isInvocable) {
                modulesJSON = CodeModulesRendering.getModuleSeedValueJSON(
                    modules,
                    moduleNameToTokenId,
                    modules[tokenIdToModuleName[tokenId]],
                    0
                );
            } else {
                modulesJSON = CodeModulesRendering.getModuleValueJSON(
                    modules,
                    moduleNameToTokenId,
                    modules[tokenIdToModuleName[tokenId]]
                );
            }
        } else {
            revert("token does not exist");
        }

        return
            CodeModulesRendering.strConcat3(
                template.beforeInject,
                modulesJSON,
                template.afterInject
            );
    }

    function getHtmlPreview(
        bytes32[] calldata dependencies,
        string calldata code,
        bool isInvocable
    ) external view returns (string memory result) {
        for (uint256 i = 0; i < dependencies.length; i++) {
            require(
                moduleExists[dependencies[i]],
                "all dependencies must exist"
            );
        }

        string memory modulesJSON;
        SharedDefinitions.Module memory preview;

        preview.name = "module-preview";
        preview.metadataJSON = "";
        preview.dependencies = dependencies;
        preview.code = code;

        if (!isInvocable) {
            preview.isInvocable = false;
            modulesJSON = CodeModulesRendering.getModuleValueJSON(
                modules,
                moduleNameToTokenId,
                preview
            );
        } else {
            preview.isInvocable = true;
            modulesJSON = CodeModulesRendering.getModuleSeedValueJSON(
                modules,
                moduleNameToTokenId,
                preview,
                0
            );
        }

        return
            CodeModulesRendering.strConcat3(
                template.beforeInject,
                modulesJSON,
                template.afterInject
            );
    }

    function initialize(uint256 networkId, bytes32 baseURIPrefix)
        public
        initializer
    {
        __ERC721_init("lambdaNFT", "LNFT");
        __Ownable_init();

        _networkId = networkId;
        _baseURIPrefix = baseURIPrefix;

        moduleNameToTokenId["module-preview"] = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        moduleNameToTokenId["module-invocation"] = _tokenIdCounter.current();
        _tokenIdCounter.increment();
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC721Upgradeable.sol";
import "./IERC721ReceiverUpgradeable.sol";
import "./extensions/IERC721MetadataUpgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../utils/StringsUpgradeable.sol";
import "../../utils/introspection/ERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721Upgradeable is Initializable, ContextUpgradeable, ERC165Upgradeable, IERC721Upgradeable, IERC721MetadataUpgradeable {
    using AddressUpgradeable for address;
    using StringsUpgradeable for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping (uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping (address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping (uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping (address => mapping (address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    function __ERC721_init(string memory name_, string memory symbol_) internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721_init_unchained(name_, symbol_);
    }

    function __ERC721_init_unchained(string memory name_, string memory symbol_) internal initializer {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165Upgradeable, IERC165Upgradeable) returns (bool) {
        return interfaceId == type(IERC721Upgradeable).interfaceId
            || interfaceId == type(IERC721MetadataUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0
            ? string(abi.encodePacked(baseURI, tokenId.toString()))
            : '';
    }

    /**
     * @dev Base URI for computing {tokenURI}. Empty by default, can be overriden
     * in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(_msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        require(operator != _msgSender(), "ERC721: approve to caller");

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(address from, address to, uint256 tokenId) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(address from, address to, uint256 tokenId, bytes memory _data) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721Upgradeable.ownerOf(tokenId);
        return (spender == owner || getApproved(tokenId) == spender || isApprovedForAll(owner, spender));
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(address to, uint256 tokenId, bytes memory _data) internal virtual {
        _mint(to, tokenId);
        require(_checkOnERC721Received(address(0), to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721Upgradeable.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(address from, address to, uint256 tokenId) internal virtual {
        require(ERC721Upgradeable.ownerOf(tokenId) == from, "ERC721: transfer of token that is not own");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721Upgradeable.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(address from, address to, uint256 tokenId, bytes memory _data)
        private returns (bool)
    {
        if (to.isContract()) {
            try IERC721ReceiverUpgradeable(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721ReceiverUpgradeable(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    // solhint-disable-next-line no-inline-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual { }
    uint256[44] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../ERC721Upgradeable.sol";
import "./IERC721EnumerableUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721EnumerableUpgradeable is Initializable, ERC721Upgradeable, IERC721EnumerableUpgradeable {
    function __ERC721Enumerable_init() internal initializer {
        __Context_init_unchained();
        __ERC165_init_unchained();
        __ERC721Enumerable_init_unchained();
    }

    function __ERC721Enumerable_init_unchained() internal initializer {
    }
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165Upgradeable, ERC721Upgradeable) returns (bool) {
        return interfaceId == type(IERC721EnumerableUpgradeable).interfaceId
            || super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721Upgradeable.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;
    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721EnumerableUpgradeable.totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
        super._beforeTokenTransfer(from, to, tokenId);

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721Upgradeable.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721Upgradeable.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }
    uint256[46] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity ^0.8.0;

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented or decremented by one. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library CountersUpgradeable {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 tokenId) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
      * @dev Safely transfers `tokenId` token from `from` to `to`.
      *
      * Requirements:
      *
      * - `from` cannot be the zero address.
      * - `to` cannot be the zero address.
      * - `tokenId` token must exist and be owned by `from`.
      * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
      * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
      *
      * Emits a {Transfer} event.
      */
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721ReceiverUpgradeable {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {

    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal initializer {
        __ERC165_init_unchained();
    }

    function __ERC165_init_unchained() internal initializer {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {
    "contracts/CodeModulesRendering.sol": {
      "CodeModulesRendering": "0x24FD2D899CA86b54F8A64EC30d07c1554aa6CdD1"
    }
  }
}