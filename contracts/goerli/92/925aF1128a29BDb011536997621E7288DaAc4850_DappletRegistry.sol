/**
 *Submitted for verification at Etherscan.io on 2021-11-14
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.4;
pragma experimental ABIEncoderV2;

contract DappletRegistry {
    event ModuleInfoAdded(
        string[] contextIds,
        address owner,
        uint32 moduleIndex
    );

    struct StorageRef {
        bytes32 hash;
        bytes[] uris; //use 2 leading bytes as prefix
    }

    // ToDo: introduce mapping for alternative sources,
    struct ModuleInfo {
        uint8 moduleType;
        string name;
        string title;
        string description;
        StorageRef icon;
        address owner;
        string[] interfaces; //Exported interfaces in all versions. no duplicates.
        uint256 flags;
    }

    struct VersionInfo {
        uint256 modIdx;
        string branch;
        uint8 major;
        uint8 minor;
        uint8 patch;
        StorageRef binary;
        bytes32[] dependencies; // key of module
        bytes32[] interfaces; //Exported interfaces. no duplicates.
        uint8 flags;
    }

    struct VersionInfoDto {
        string branch;
        uint8 major;
        uint8 minor;
        uint8 patch;
        StorageRef binary;
        DependencyDto[] dependencies; // key of module
        DependencyDto[] interfaces; //Exported interfaces. no duplicates.
        uint8 flags;
    }

    struct DependencyDto {
        string name;
        string branch;
        uint8 major;
        uint8 minor;
        uint8 patch;
    }

    mapping(bytes32 => bytes) public versionNumbers; // keccak(name,branch) => <bytes4[]> versionNumbers
    mapping(bytes32 => VersionInfo) public versions; // keccak(name,branch,major,minor,patch) => VersionInfo>
    mapping(bytes32 => uint32[]) public modsByContextType; // key - keccak256(contextId, owner), value - index of element in "modules" array
    mapping(bytes32 => uint32) public moduleIdxs;
    mapping(address => uint32[]) public modsByOwner; // key - userId => module indexes
    ModuleInfo[] public modules;

    constructor() public {
        modules.push(); // Zero index is reserved
    }

    // -------------------------------------------------------------------------
    // View functions
    // -------------------------------------------------------------------------

    function getModuleInfoBatch(
        string[] memory ctxIds,
        address[] memory users,
        uint32 maxBufLen
    ) public view returns (ModuleInfo[][] memory mod_info) {
        mod_info = new ModuleInfo[][](ctxIds.length);
        for (uint256 i = 0; i < ctxIds.length; ++i) {
            mod_info[i] = getModuleInfo(ctxIds[i], users, maxBufLen);
        }
    }

    // Very naive impl.
    function getModuleInfo(
        string memory ctxId,
        address[] memory users,
        uint32 maxBufLen
    ) public view returns (ModuleInfo[] memory mod_info) {
        uint256[] memory outbuf = new uint256[](
            maxBufLen > 0 ? maxBufLen : 1000
        );
        uint256 bufLen = _fetchModulesByUsersTag(ctxId, users, outbuf, 0);
        mod_info = new ModuleInfo[](bufLen);
        for (uint256 i = 0; i < bufLen; ++i) {
            uint256 idx = outbuf[i];
            mod_info[i] = modules[idx]; // WARNING! indexes are started from 1.
            //ToDo: strip contentType indexes?
        }
    }

    function getModuleInfoByName(string memory mod_name)
        public
        view
        returns (ModuleInfo memory)
    {
        bytes32 mKey = keccak256(abi.encodePacked(mod_name));
        require(moduleIdxs[mKey] != 0, "The module does not exist");
        return modules[moduleIdxs[mKey]];
    }

    function getModuleInfoByOwner(address userId)
        public
        view
        returns (ModuleInfo[] memory mods)
    {
        uint32[] memory _moduleIdxs = modsByOwner[userId];
        mods = new ModuleInfo[](_moduleIdxs.length);
        for (uint256 i = 0; i < _moduleIdxs.length; ++i) {
            mods[i] = modules[_moduleIdxs[i]];
        }
    }

    function getVersionNumbers(string memory name, string memory branch)
        public
        view
        returns (bytes memory)
    {
        bytes32 key = keccak256(abi.encodePacked(name, branch));
        return versionNumbers[key];
    }

    function getVersionInfo(
        string memory name,
        string memory branch,
        uint8 major,
        uint8 minor,
        uint8 patch
    ) public view returns (VersionInfoDto memory dto, uint8 moduleType) {
        bytes32 key = keccak256(
            abi.encodePacked(name, branch, major, minor, patch)
        );
        VersionInfo memory v = versions[key];
        require(v.modIdx != 0, "Version doesn't exist");

        DependencyDto[] memory deps = new DependencyDto[](
            v.dependencies.length
        );
        for (uint256 i = 0; i < v.dependencies.length; ++i) {
            VersionInfo memory depVi = versions[v.dependencies[i]];
            ModuleInfo memory depMod = modules[depVi.modIdx];
            deps[i] = DependencyDto(
                depMod.name,
                depVi.branch,
                depVi.major,
                depVi.minor,
                depVi.patch
            );
        }

        DependencyDto[] memory interfaces = new DependencyDto[](
            v.interfaces.length
        );
        for (uint256 i = 0; i < v.interfaces.length; ++i) {
            VersionInfo memory intVi = versions[v.interfaces[i]];
            ModuleInfo memory intMod = modules[intVi.modIdx];
            interfaces[i] = DependencyDto(
                intMod.name,
                intVi.branch,
                intVi.major,
                intVi.minor,
                intVi.patch
            );
        }

        dto = VersionInfoDto(
            v.branch,
            v.major,
            v.minor,
            v.patch,
            v.binary,
            deps,
            interfaces,
            v.flags
        );
        moduleType = modules[v.modIdx].moduleType;
    }

    // -------------------------------------------------------------------------
    // State modifying functions
    // -------------------------------------------------------------------------

    function addModuleInfo(
        string[] memory contextIds,
        ModuleInfo memory mInfo,
        VersionInfoDto[] memory vInfos
    ) public {
        bytes32 mKey = keccak256(abi.encodePacked(mInfo.name));
        require(moduleIdxs[mKey] == 0, "The module already exists"); // module does not exist

        address owner = msg.sender;

        // ModuleInfo adding
        mInfo.owner = owner;
        modules.push(mInfo);
        uint32 mIdx = uint32(modules.length - 1); // WARNING! indexes are started from 1.
        moduleIdxs[mKey] = mIdx;
        modsByOwner[owner].push(mIdx);

        // ContextId adding
        for (uint256 i = 0; i < contextIds.length; ++i) {
            bytes32 key = keccak256(abi.encodePacked(contextIds[i], owner));
            modsByContextType[key].push(mIdx);
        }

        emit ModuleInfoAdded(contextIds, owner, mIdx);

        // Versions Adding
        for (uint256 i = 0; i < vInfos.length; ++i) {
            _addModuleVersionNoChecking(mIdx, mInfo.name, vInfos[i]);
        }
    }

    function editModuleInfo(
        uint32 moduleIdx,
        string memory title,
        string memory description,
        StorageRef memory icon
    ) public {
        ModuleInfo storage m = modules[moduleIdx]; // WARNING! indexes are started from 1.
        require(m.owner == msg.sender, "You are not the owner of this module");
        
        m.title = title;
        m.description = description;
        m.icon = icon;
    }

    function addModuleVersion(
        string memory mod_name,
        VersionInfoDto memory vInfo
    ) public {
        // ******** TODO: check existing versions and version sorting
        bytes32 mKey = keccak256(abi.encodePacked(mod_name));
        uint32 moduleIdx = moduleIdxs[mKey];
        require(moduleIdx != 0, "The module does not exist");
        ModuleInfo storage m = modules[moduleIdx]; // WARNING! indexes are started from 1.
        require(m.owner == msg.sender, "You are not the owner of this module");

        _addModuleVersionNoChecking(moduleIdx, mod_name, vInfo);
    }

    function addModuleVersionBatch(
        string[] memory mod_name,
        VersionInfoDto[] memory vInfo
    ) public {
        require(
            mod_name.length == vInfo.length,
            "Number of elements must be equal"
        );
        for (uint256 i = 0; i < mod_name.length; ++i) {
            addModuleVersion(mod_name[i], vInfo[i]);
        }
    }

    function transferOwnership(
        string memory mod_name,
        address newUserId,
        uint256 oldOwnerMapIdx
    ) public {
        bytes32 mKey = keccak256(abi.encodePacked(mod_name));
        uint32 moduleIdx = moduleIdxs[mKey];
        require(moduleIdx != 0, "The module does not exist");
        ModuleInfo storage m = modules[moduleIdx]; // WARNING! indexes are started from 1.
        require(m.owner == msg.sender, "You are not the owner of this module");
        uint32[] storage oldOwnerModules = modsByOwner[m.owner];
        require(
            oldOwnerModules[oldOwnerMapIdx] == moduleIdx,
            "Invalid index of old owner map"
        );

        // Remove module idx from old owner
        oldOwnerModules[oldOwnerMapIdx] = oldOwnerModules[
            oldOwnerModules.length - 1
        ];
        oldOwnerModules.pop();

        // Change owner
        m.owner = newUserId;

        // Add module idx to new owner
        modsByOwner[newUserId].push(moduleIdx);
    }

    function addContextId(string memory mod_name, string memory contextId)
        public
    {
        bytes32 mKey = keccak256(abi.encodePacked(mod_name));
        uint32 moduleIdx = moduleIdxs[mKey];
        require(moduleIdx != 0, "The module does not exist");

        // ContextId adding
        address userId = msg.sender;
        bytes32 key = keccak256(abi.encodePacked(contextId, userId));
        modsByContextType[key].push(moduleIdx);
    }

    function removeContextId(string memory mod_name, string memory contextId)
        public
    {
        bytes32 mKey = keccak256(abi.encodePacked(mod_name));
        uint32 moduleIdx = moduleIdxs[mKey];
        require(moduleIdx != 0, "The module does not exist");

        // ContextId adding
        address userId = msg.sender;
        bytes32 key = keccak256(abi.encodePacked(contextId, userId));
        uint32[] storage _modules = modsByContextType[key];

        for (uint256 i = 0; i < modules.length; ++i) {
            if (_modules[i] == moduleIdx) {
                _modules[i] = _modules[modules.length - 1];
                _modules.pop();
                break;
            }
        }
    }

    // -------------------------------------------------------------------------
    // Internal functions
    // -------------------------------------------------------------------------

    function _fetchModulesByUsersTags(
        string[] memory interfaces,
        address[] memory users,
        uint256[] memory outbuf,
        uint256 _bufLen
    ) internal view returns (uint256) {
        uint256 bufLen = _bufLen;

        for (uint256 i = 0; i < interfaces.length; ++i) {
            bufLen = _fetchModulesByUsersTag(
                interfaces[i],
                users,
                outbuf,
                bufLen
            );
        }

        return bufLen;
    }

    // ctxId - URL or ContextType [IdentityAdapter]
    function _fetchModulesByUsersTag(
        string memory ctxId,
        address[] memory users,
        uint256[] memory outbuf,
        uint256 _bufLen
    ) internal view returns (uint256) {
        uint256 bufLen = _bufLen;
        for (uint256 i = 0; i < users.length; ++i) {
            bytes32 key = keccak256(abi.encodePacked(ctxId, users[i]));
            uint32[] memory modIdxs = modsByContextType[key];
            //add if no duplicates in buffer[0..nn-1]
            uint256 lastBufLen = bufLen;
            for (uint256 j = 0; j < modIdxs.length; ++j) {
                uint256 modIdx = modIdxs[j];
                uint256 k = 0;
                for (; k < lastBufLen; ++k) {
                    if (outbuf[k] == modIdx) break; //duplicate found
                }
                if (k == lastBufLen) {
                    //no duplicates found  -- add the module's index
                    outbuf[bufLen++] = modIdx;
                    ModuleInfo memory m = modules[modIdx];
                    bufLen = _fetchModulesByUsersTag(
                        m.name,
                        users,
                        outbuf,
                        bufLen
                    ); // using index as a tag.
                    bufLen = _fetchModulesByUsersTags(
                        m.interfaces,
                        users,
                        outbuf,
                        bufLen
                    );
                    //ToDo: what if owner changes? CREATE MODULE ENS  NAMES! on creating ENS
                }
            }
        }
        return bufLen;
    }

    function _addModuleVersionNoChecking(
        uint256 moduleIdx,
        string memory mod_name,
        VersionInfoDto memory v
    ) private {
        bytes32[] memory deps = new bytes32[](v.dependencies.length);
        for (uint256 i = 0; i < v.dependencies.length; ++i) {
            DependencyDto memory d = v.dependencies[i];
            bytes32 dKey = keccak256(
                abi.encodePacked(d.name, d.branch, d.major, d.minor, d.patch)
            );
            require(versions[dKey].modIdx != 0, "Dependency doesn't exist");
            deps[i] = dKey;
        }

        bytes32[] memory interfaces = new bytes32[](v.interfaces.length);
        for (uint256 i = 0; i < v.interfaces.length; ++i) {
            DependencyDto memory interf = v.interfaces[i];
            bytes32 iKey = keccak256(
                abi.encodePacked(
                    interf.name,
                    interf.branch,
                    interf.major,
                    interf.minor,
                    interf.patch
                )
            );
            require(versions[iKey].modIdx != 0, "Interface doesn't exist");
            interfaces[i] = iKey;

            // add interface name to ModuleInfo if not exist
            bool isInterfaceExist = false;
            for (uint256 j = 0; j < modules[moduleIdx].interfaces.length; ++j) {
                if (
                    keccak256(
                        abi.encodePacked(modules[moduleIdx].interfaces[j])
                    ) == keccak256(abi.encodePacked(interf.name))
                ) {
                    isInterfaceExist = true;
                    break;
                }
            }

            if (isInterfaceExist == false) {
                modules[moduleIdx].interfaces.push(interf.name);
            }
        }

        VersionInfo memory vInfo = VersionInfo(
            moduleIdx,
            v.branch,
            v.major,
            v.minor,
            v.patch,
            v.binary,
            deps,
            interfaces,
            v.flags
        );
        bytes32 vKey = keccak256(
            abi.encodePacked(mod_name, v.branch, v.major, v.minor, v.patch)
        );
        versions[vKey] = vInfo;

        bytes32 nbKey = keccak256(abi.encodePacked(mod_name, vInfo.branch));
        versionNumbers[nbKey].push(bytes1(vInfo.major));
        versionNumbers[nbKey].push(bytes1(vInfo.minor));
        versionNumbers[nbKey].push(bytes1(vInfo.patch));
        versionNumbers[nbKey].push(bytes1(0x0));
    }
}