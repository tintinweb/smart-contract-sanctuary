//File: contracts/acl/IACL.sol
pragma solidity ^0.4.18;


interface IACL {
    function initialize(address permissionsCreator) public;
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);
}

//File: contracts/kernel/IKernel.sol
pragma solidity ^0.4.18;



interface IKernel {
    event SetApp(bytes32 indexed namespace, bytes32 indexed name, bytes32 indexed id, address app);

    function acl() public view returns (IACL);
    function hasPermission(address who, address where, bytes32 what, bytes how) public view returns (bool);

    function setApp(bytes32 namespace, bytes32 name, address app) public returns (bytes32 id);
    function getApp(bytes32 id) public view returns (address);
}
//File: contracts/apps/AppStorage.sol
pragma solidity ^0.4.18;




contract AppStorage {
    IKernel public kernel;
    bytes32 public appId;
    address internal pinnedCode; // used by Proxy Pinned
    uint256 internal initializationBlock; // used by Initializable
    uint256[95] private storageOffset; // forces App storage to start at after 100 slots
    uint256 private offset;
}

//File: contracts/common/Initializable.sol
pragma solidity ^0.4.18;




contract Initializable is AppStorage {
    modifier onlyInit {
        require(initializationBlock == 0);
        _;
    }

    /**
    * @return Block number in which the contract was initialized
    */
    function getInitializationBlock() public view returns (uint256) {
        return initializationBlock;
    }

    /**
    * @dev Function to be called by top level contract after initialization has finished.
    */
    function initialized() internal onlyInit {
        initializationBlock = getBlockNumber();
    }

    /**
    * @dev Returns the current block number.
    *      Using a function rather than `block.number` allows us to easily mock the block number in
    *      tests.
    */
    function getBlockNumber() internal view returns (uint256) {
        return block.number;
    }
}

//File: contracts/evmscript/IEVMScriptExecutor.sol
pragma solidity ^0.4.18;


interface IEVMScriptExecutor {
    function execScript(bytes script, bytes input, address[] blacklist) external returns (bytes);
}

//File: contracts/evmscript/IEVMScriptRegistry.sol
pragma solidity 0.4.18;


contract EVMScriptRegistryConstants {
    bytes32 constant public EVMSCRIPT_REGISTRY_APP_ID = keccak256("evmreg.aragonpm.eth");
    bytes32 constant public EVMSCRIPT_REGISTRY_APP = keccak256(keccak256("app"), EVMSCRIPT_REGISTRY_APP_ID);
}


interface IEVMScriptRegistry {
    function addScriptExecutor(address executor) external returns (uint id);
    function disableScriptExecutor(uint256 executorId) external;

    function getScriptExecutor(bytes script) public view returns (address);
}
//File: contracts/evmscript/ScriptHelpers.sol
pragma solidity 0.4.18;


library ScriptHelpers {
    // To test with JS and compare with actual encoder. Maintaining for reference.
    // t = function() { return IEVMScriptExecutor.at(&#39;0x4bcdd59d6c77774ee7317fc1095f69ec84421e49&#39;).contract.execScript.getData(...[].slice.call(arguments)).slice(10).match(/.{1,64}/g) }
    // run = function() { return ScriptHelpers.new().then(sh => { sh.abiEncode.call(...[].slice.call(arguments)).then(a => console.log(a.slice(2).match(/.{1,64}/g)) ) }) }
    // This is truly not beautiful but lets no daydream to the day solidity gets reflection features

    function abiEncode(bytes _a, bytes _b, address[] _c) public pure returns (bytes d) {
        return encode(_a, _b, _c);
    }

    function encode(bytes memory _a, bytes memory _b, address[] memory _c) internal pure returns (bytes memory d) {
        // A is positioned after the 3 position words
        uint256 aPosition = 0x60;
        uint256 bPosition = aPosition + 32 * abiLength(_a);
        uint256 cPosition = bPosition + 32 * abiLength(_b);
        uint256 length = cPosition + 32 * abiLength(_c);

        d = new bytes(length);
        assembly {
            // Store positions
            mstore(add(d, 0x20), aPosition)
            mstore(add(d, 0x40), bPosition)
            mstore(add(d, 0x60), cPosition)
        }

        // Copy memory to correct position
        copy(d, getPtr(_a), aPosition, _a.length);
        copy(d, getPtr(_b), bPosition, _b.length);
        copy(d, getPtr(_c), cPosition, _c.length * 32); // 1 word per address
    }

    function abiLength(bytes memory _a) internal pure returns (uint256) {
        // 1 for length +
        // memory words + 1 if not divisible for 32 to offset word
        return 1 + (_a.length / 32) + (_a.length % 32 > 0 ? 1 : 0);
    }

    function abiLength(address[] _a) internal pure returns (uint256) {
        // 1 for length + 1 per item
        return 1 + _a.length;
    }

    function copy(bytes _d, uint256 _src, uint256 _pos, uint256 _length) internal pure {
        uint dest;
        assembly {
            dest := add(add(_d, 0x20), _pos)
        }
        memcpy(dest, _src, _length + 32);
    }

    function getPtr(bytes memory _x) internal pure returns (uint256 ptr) {
        assembly {
            ptr := _x
        }
    }

    function getPtr(address[] memory _x) internal pure returns (uint256 ptr) {
        assembly {
            ptr := _x
        }
    }

    function getSpecId(bytes _script) internal pure returns (uint32) {
        return uint32At(_script, 0);
    }

    function uint256At(bytes _data, uint256 _location) internal pure returns (uint256 result) {
        assembly {
            result := mload(add(_data, add(0x20, _location)))
        }
    }

    function addressAt(bytes _data, uint256 _location) internal pure returns (address result) {
        uint256 word = uint256At(_data, _location);

        assembly {
            result := div(and(word, 0xffffffffffffffffffffffffffffffffffffffff000000000000000000000000),
            0x1000000000000000000000000)
        }
    }

    function uint32At(bytes _data, uint256 _location) internal pure returns (uint32 result) {
        uint256 word = uint256At(_data, _location);

        assembly {
            result := div(and(word, 0xffffffff00000000000000000000000000000000000000000000000000000000),
            0x100000000000000000000000000000000000000000000000000000000)
        }
    }

    function locationOf(bytes _data, uint256 _location) internal pure returns (uint256 result) {
        assembly {
            result := add(_data, add(0x20, _location))
        }
    }

    function toBytes(bytes4 _sig) internal pure returns (bytes) {
        bytes memory payload = new bytes(4);
        payload[0] = bytes1(_sig);
        payload[1] = bytes1(_sig << 8);
        payload[2] = bytes1(_sig << 16);
        payload[3] = bytes1(_sig << 24);
        return payload;
    }

    function memcpy(uint _dest, uint _src, uint _len) public pure {
        uint256 src = _src;
        uint256 dest = _dest;
        uint256 len = _len;

        // Copy word-length chunks while possible
        for (; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }
}
//File: contracts/evmscript/EVMScriptRunner.sol
pragma solidity ^0.4.18;








contract EVMScriptRunner is AppStorage, EVMScriptRegistryConstants {
    using ScriptHelpers for bytes;

    function runScript(bytes _script, bytes _input, address[] _blacklist) protectState internal returns (bytes output) {
        // TODO: Too much data flying around, maybe extracting spec id here is cheaper
        address executorAddr = getExecutor(_script);
        require(executorAddr != address(0));

        bytes memory calldataArgs = _script.encode(_input, _blacklist);
        bytes4 sig = IEVMScriptExecutor(0).execScript.selector;

        require(executorAddr.delegatecall(sig, calldataArgs));

        return returnedDataDecoded();
    }

    function getExecutor(bytes _script) public view returns (IEVMScriptExecutor) {
        return IEVMScriptExecutor(getExecutorRegistry().getScriptExecutor(_script));
    }

    // TODO: Internal
    function getExecutorRegistry() internal view returns (IEVMScriptRegistry) {
        address registryAddr = kernel.getApp(EVMSCRIPT_REGISTRY_APP);
        return IEVMScriptRegistry(registryAddr);
    }

    /**
    * @dev copies and returns last&#39;s call data. Needs to ABI decode first
    */
    function returnedDataDecoded() internal view returns (bytes ret) {
        assembly {
            let size := returndatasize
            switch size
            case 0 {}
            default {
                ret := mload(0x40) // free mem ptr get
                mstore(0x40, add(ret, add(size, 0x20))) // free mem ptr set
                returndatacopy(ret, 0x20, sub(size, 0x20)) // copy return data
            }
        }
        return ret;
    }

    modifier protectState {
        address preKernel = kernel;
        bytes32 preAppId = appId;
        _; // exec
        require(kernel == preKernel);
        require(appId == preAppId);
    }
}
//File: contracts/acl/ACLSyntaxSugar.sol
pragma solidity 0.4.18;


contract ACLSyntaxSugar {
    function arr() internal pure returns (uint256[] r) {}

    function arr(bytes32 _a) internal pure returns (uint256[] r) {
        return arr(uint256(_a));
    }

    function arr(bytes32 _a, bytes32 _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a) internal pure returns (uint256[] r) {
        return arr(uint256(_a));
    }

    function arr(address _a, address _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a, uint256 _b, uint256 _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), _b, _c);
    }

    function arr(address _a, uint256 _b) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b));
    }

    function arr(address _a, address _b, uint256 _c, uint256 _d, uint256 _e) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), _c, _d, _e);
    }

    function arr(address _a, address _b, address _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), uint256(_c));
    }

    function arr(address _a, address _b, uint256 _c) internal pure returns (uint256[] r) {
        return arr(uint256(_a), uint256(_b), uint256(_c));
    }

    function arr(uint256 _a) internal pure returns (uint256[] r) {
        r = new uint256[](1);
        r[0] = _a;
    }

    function arr(uint256 _a, uint256 _b) internal pure returns (uint256[] r) {
        r = new uint256[](2);
        r[0] = _a;
        r[1] = _b;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c) internal pure returns (uint256[] r) {
        r = new uint256[](3);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c, uint256 _d) internal pure returns (uint256[] r) {
        r = new uint256[](4);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
        r[3] = _d;
    }

    function arr(uint256 _a, uint256 _b, uint256 _c, uint256 _d, uint256 _e) internal pure returns (uint256[] r) {
        r = new uint256[](5);
        r[0] = _a;
        r[1] = _b;
        r[2] = _c;
        r[3] = _d;
        r[4] = _e;
    }
}


contract ACLHelpers {
    function decodeParamOp(uint256 _x) internal pure returns (uint8 b) {
        return uint8(_x >> (8 * 30));
    }

    function decodeParamId(uint256 _x) internal pure returns (uint8 b) {
        return uint8(_x >> (8 * 31));
    }

    function decodeParamsList(uint256 _x) internal pure returns (uint32 a, uint32 b, uint32 c) {
        a = uint32(_x);
        b = uint32(_x >> (8 * 4));
        c = uint32(_x >> (8 * 8));
    }
}

//File: contracts/apps/AragonApp.sol
pragma solidity ^0.4.18;







contract AragonApp is AppStorage, Initializable, ACLSyntaxSugar, EVMScriptRunner {
    modifier auth(bytes32 _role) {
        require(canPerform(msg.sender, _role, new uint256[](0)));
        _;
    }

    modifier authP(bytes32 _role, uint256[] params) {
        require(canPerform(msg.sender, _role, params));
        _;
    }

    function canPerform(address _sender, bytes32 _role, uint256[] params) public view returns (bool) {
        bytes memory how; // no need to init memory as it is never used
        if (params.length > 0) {
            uint256 byteLength = params.length * 32;
            assembly {
                how := params // forced casting
                mstore(how, byteLength)
            }
        }
        return address(kernel) == 0 || kernel.hasPermission(_sender, address(this), _role, how);
    }
}

//File: contracts/apm/Repo.sol
pragma solidity ^0.4.15;




contract Repo is AragonApp {
    struct Version {
        uint16[3] semanticVersion;
        address contractAddress;
        bytes contentURI;
    }

    Version[] versions;
    mapping (bytes32 => uint256) versionIdForSemantic;
    mapping (address => uint256) latestVersionIdForContract;

    bytes32 constant public CREATE_VERSION_ROLE = bytes32(1);

    event NewVersion(uint256 versionId, uint16[3] semanticVersion);

    /**
    * @notice Create new version for repo
    * @param _newSemanticVersion Semantic version for new repo version
    * @param _contractAddress address for smart contract logic for version (if set to 0, it uses last versions&#39; contractAddress)
    * @param _contentURI External URI for fetching new version&#39;s content
    */
    function newVersion(
        uint16[3] _newSemanticVersion,
        address _contractAddress,
        bytes _contentURI
    ) auth(CREATE_VERSION_ROLE) public
    {
        address contractAddress = _contractAddress;
        if (versions.length > 0) {
            Version storage lastVersion = versions[versions.length - 1];
            require(isValidBump(lastVersion.semanticVersion, _newSemanticVersion));
            if (contractAddress == 0) {
                contractAddress = lastVersion.contractAddress;
            }
            // Only allows smart contract change on major version bumps
            require(lastVersion.contractAddress == contractAddress || _newSemanticVersion[0] > lastVersion.semanticVersion[0]);
        } else {
            versions.length += 1;
            uint16[3] memory zeroVersion;
            require(isValidBump(zeroVersion, _newSemanticVersion));
        }

        uint versionId = versions.push(Version(_newSemanticVersion, contractAddress, _contentURI)) - 1;
        versionIdForSemantic[semanticVersionHash(_newSemanticVersion)] = versionId;
        latestVersionIdForContract[contractAddress] = versionId;

        NewVersion(versionId, _newSemanticVersion);
    }

    function getLatest() public view returns (uint16[3] semanticVersion, address contractAddress, bytes contentURI) {
        return getByVersionId(versions.length - 1);
    }

    function getLatestForContractAddress(address _contractAddress) public view returns (uint16[3] semanticVersion, address contractAddress, bytes contentURI) {
        return getByVersionId(latestVersionIdForContract[_contractAddress]);
    }

    function getBySemanticVersion(uint16[3] _semanticVersion) public view returns (uint16[3] semanticVersion, address contractAddress, bytes contentURI) {
        return getByVersionId(versionIdForSemantic[semanticVersionHash(_semanticVersion)]);
    }

    function getByVersionId(uint _versionId) public view returns (uint16[3] semanticVersion, address contractAddress, bytes contentURI) {
        require(_versionId > 0);
        Version storage version = versions[_versionId];
        return (version.semanticVersion, version.contractAddress, version.contentURI);
    }

    function getVersionsCount() public view returns (uint256) {
        uint256 len = versions.length;
        return len > 0 ? len - 1 : 0;
    }

    function isValidBump(uint16[3] _oldVersion, uint16[3] _newVersion) public pure returns (bool) {
        bool hasBumped;
        uint i = 0;
        while (i < 3) {
            if (hasBumped) {
                if (_newVersion[i] != 0) {
                    return false;
                }
            } else if (_newVersion[i] != _oldVersion[i]) {
                if (_oldVersion[i] > _newVersion[i] || _newVersion[i] - _oldVersion[i] != 1) {
                    return false;
                }
                hasBumped = true;
            }
            i++;
        }
        return hasBumped;
    }

    function semanticVersionHash(uint16[3] version) internal pure returns (bytes32) {
        return keccak256(version[0], version[1], version[2]);
    }
}