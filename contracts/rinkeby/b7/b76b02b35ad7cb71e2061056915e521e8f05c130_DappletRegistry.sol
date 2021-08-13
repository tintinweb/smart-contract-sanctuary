/**
 *Submitted for verification at Etherscan.io on 2021-08-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.4;
pragma experimental ABIEncoderV2;
contract DappletRegistry {

    event ModuleInfoAdded (
        string[] contextIds,
        bytes32 owner,
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
        bytes32 owner;
        string[] interfaces; //Exported interfaces in all versions. no duplicates.
        StorageRef icon;
        uint flags;
    }

    struct VersionInfo {
        uint  modIdx;
        string branch;
        uint8 major;
        uint8 minor;
        uint8 patch;
        uint8 flags;
        StorageRef binary;
        bytes32[] dependencies; // key of module 
        bytes32[] interfaces; //Exported interfaces. no duplicates.
    }
    
    struct VersionInfoDto {
        string branch;
        uint8 major;
        uint8 minor;
        uint8 patch;
        uint8 flags;
        StorageRef binary;
        DependencyDto[] dependencies; // key of module 
        DependencyDto[] interfaces; //Exported interfaces. no duplicates.
    }
    
    struct DependencyDto {
        string name;
        string branch;
        uint8 major;
        uint8 minor;
        uint8 patch;
    }

    mapping(bytes32 => bytes) versionNumbers; // keccak(name,branch) => <bytes4[]> versionNumbers
    mapping(bytes32 => VersionInfo) versions; // keccak(name,branch,major,minor,patch) => VersionInfo>
    mapping(bytes32 => uint32[]) modsByContextType; // key - keccak256(contextId, owner), value - index of element in "modules" array
    mapping(bytes32 => uint32) moduleIdxs;
    ModuleInfo[] modules;

    constructor() public {
        modules.push(); // Zero index is reserved
    }

    function getModuleInfoBatch(string[] memory ctxIds, bytes32[] memory users, uint32 maxBufLen) public view returns (ModuleInfo[][] memory mod_info) {
        mod_info = new ModuleInfo[][](ctxIds.length);
        for (uint i = 0; i < ctxIds.length; ++i) {
            mod_info[i] = getModuleInfo(ctxIds[i], users, maxBufLen);
        }
    }

    //Very naive impl.
    function getModuleInfo(string memory ctxId, bytes32[] memory users, uint32 maxBufLen) public view returns (ModuleInfo[] memory mod_info) {
        uint[] memory outbuf = new uint[]( maxBufLen > 0 ? maxBufLen : 1000 );
        uint bufLen = _fetchModulesByUsersTag(ctxId, users, outbuf, 0);
        mod_info = new ModuleInfo[](bufLen);
        for(uint i = 0; i < bufLen; ++i) {
            uint idx = outbuf[i];
            mod_info[i] = modules[idx]; // WARNING! indexes are started from 1.
            //ToDo: strip contentType indexes?
        }
    }

    function getModuleInfoByName(string memory mod_name) public view returns (ModuleInfo memory) {
        bytes32 mKey = keccak256(abi.encodePacked(mod_name));
        require(moduleIdxs[mKey] != 0, 'The module does not exist');
        return modules[moduleIdxs[mKey]];
    }
        
    function addModuleInfo(string[] memory contextIds, ModuleInfo memory mInfo, VersionInfoDto[] memory vInfos, bytes32 userId) public {
        require(_isEnsOwner(userId));
        bytes32 mKey = keccak256(abi.encodePacked(mInfo.name));
        require(moduleIdxs[mKey] == 0, 'The module already exists'); // module does not exist
        bytes32 owner = userId == 0 ? bytes32(uint(msg.sender)) : userId;
        
        // ModuleInfo adding
        mInfo.owner = owner;
        modules.push(mInfo);
        uint32 mIdx = uint32(modules.length - 1); // WARNING! indexes are started from 1.
        moduleIdxs[mKey] = mIdx;
        
        // ContextId adding
        for (uint i = 0; i < contextIds.length; ++i) {
            bytes32 key = keccak256(abi.encodePacked(contextIds[i], owner));
            modsByContextType[key].push(mIdx);
        }
        
        emit ModuleInfoAdded(contextIds, owner, mIdx);
        
        // Versions Adding
        for (uint i = 0; i < vInfos.length; ++i) {
            _addModuleVersionNoChecking(mIdx, mInfo.name, vInfos[i]);
        }
    }
    
    function addModuleVersion(string memory mod_name, VersionInfoDto memory vInfo, bytes32 userId) public {
        require(_isEnsOwner(userId));
        // ******** TODO: check existing versions and version sorting
        bytes32 owner = userId == 0 ? bytes32(uint(msg.sender)) : userId;
        bytes32 mKey = keccak256(abi.encodePacked(mod_name));
        uint32 moduleIdx = moduleIdxs[mKey];
        require(moduleIdx != 0, 'The module does not exist');
        ModuleInfo storage m = modules[moduleIdx]; // WARNING! indexes are started from 1.
        require(m.owner == owner, 'You are not the owner of this module');
        
        _addModuleVersionNoChecking(moduleIdx, mod_name, vInfo);
    }

    function addModuleVersionBatch(string[] memory mod_name, VersionInfoDto[] memory vInfo, bytes32[] memory userId) public {
        require(mod_name.length == vInfo.length && vInfo.length == userId.length, "Number of elements must be equal");
        for (uint i = 0; i < mod_name.length; ++i) {
            addModuleVersion(mod_name[i], vInfo[i], userId[i]);
        }
    }
    
    function getVersionNumbers(string memory name, string memory branch) public view returns (bytes memory) {
        bytes32 key = keccak256(abi.encodePacked(name, branch));
        return versionNumbers[key];
    } 
    
    // instead of resolveToManifest
    function getVersionInfo(string memory name, string memory branch, uint8 major, uint8 minor, uint8 patch) public view returns (VersionInfoDto memory dto, uint8 moduleType) {
        bytes32 key = keccak256(abi.encodePacked(name, branch, major, minor, patch));
        VersionInfo memory v = versions[key];
        require(v.modIdx != 0, "Version doesn't exist");
        
        DependencyDto[] memory deps = new DependencyDto[](v.dependencies.length);
        for (uint i = 0; i < v.dependencies.length; ++i) {
            VersionInfo memory depVi = versions[v.dependencies[i]];
            ModuleInfo memory depMod = modules[depVi.modIdx];
            deps[i] = DependencyDto(depMod.name, depVi.branch, depVi.major, depVi.minor, depVi.patch);
        }

        DependencyDto[] memory interfaces = new DependencyDto[](v.interfaces.length);
        for (uint i = 0; i < v.interfaces.length; ++i) {
            VersionInfo memory intVi = versions[v.interfaces[i]];
            ModuleInfo memory intMod = modules[intVi.modIdx];
            interfaces[i] = DependencyDto(intMod.name, intVi.branch, intVi.major, intVi.minor, intVi.patch);
        }
        
        dto = VersionInfoDto(v.branch, v.major, v.minor, v.patch, v.flags, v.binary, deps, interfaces);
        moduleType = modules[v.modIdx].moduleType;
    }
    
    // function getVersions(string memory name, string memory branch) public view returns (VersionInfo[] memory out) {
    //     bytes memory versionBytes = getVersionNumbers(name,branch);
    //     out = new VersionInfo[](versionBytes.length/4);
    //     for(uint i=0; i<versionBytes.length; i+=4){
    //        bytes32 key = keccak256(abi.encodePacked(name, branch, versionBytes[i], versionBytes[i+1], versionBytes[i+2]));  //OPTIMIZE IT! mit assebly?
    //        out[i>>2] = versions[key];
    //     }
    // }

    function transferOwnership(string memory mod_name, bytes32 oldUserId, bytes32 newUserId) public {
        require(_isEnsOwner(oldUserId));
        require(_isEnsOwner(newUserId));
        bytes32 oldOwnerId = oldUserId == 0 ? bytes32(uint(msg.sender)) : oldUserId;
        bytes32 mKey = keccak256(abi.encodePacked(mod_name));
        uint32 moduleIdx = moduleIdxs[mKey];
        require(moduleIdx != 0, 'The module does not exist');
        ModuleInfo storage m = modules[moduleIdx]; // WARNING! indexes are started from 1.
        require(m.owner == oldOwnerId, 'You are not the owner of this module');
        
        m.owner = newUserId;
    }

    function addContextId(string memory mod_name, string memory contextId, bytes32 userId) public {
        require(_isEnsOwner(userId));
        bytes32 owner = userId == 0 ? bytes32(uint(msg.sender)) : userId;
        bytes32 mKey = keccak256(abi.encodePacked(mod_name));
        uint32 moduleIdx = moduleIdxs[mKey];
        require(moduleIdx != 0, 'The module does not exist');
        ModuleInfo storage m = modules[moduleIdx]; // WARNING! indexes are started from 1.
        require(m.owner == owner, 'You are not the owner of this module');

        // ContextId adding
        bytes32 key = keccak256(abi.encodePacked(contextId, owner));
        modsByContextType[key].push(moduleIdx);
    }

    function removeContextId(string memory mod_name, string memory contextId, bytes32 userId) public {
        require(_isEnsOwner(userId));
        bytes32 owner = userId == 0 ? bytes32(uint(msg.sender)) : userId;
        bytes32 mKey = keccak256(abi.encodePacked(mod_name));
        uint32 moduleIdx = moduleIdxs[mKey];
        require(moduleIdx != 0, 'The module does not exist');
        ModuleInfo storage m = modules[moduleIdx]; // WARNING! indexes are started from 1.
        require(m.owner == owner, 'You are not the owner of this module');

        // ContextId adding
        bytes32 key = keccak256(abi.encodePacked(contextId, owner));
        uint32[] storage modules = modsByContextType[key];

        for (uint i = 0; i < modules.length; ++i) {
            if (modules[i] == moduleIdx) {
                modules[i] = modules[modules.length - 1];
                modules.pop();
                break;
            }
        }
    }

    function _fetchModulesByUsersTags(string[] memory interfaces, bytes32[] memory users, uint[] memory outbuf, uint _bufLen) internal view returns (uint) {
        uint bufLen = _bufLen;
        
        for (uint i = 0; i < interfaces.length; ++i) {
            bufLen = _fetchModulesByUsersTag(interfaces[i], users, outbuf, bufLen);
        }
        
        return bufLen;
    }

    // ctxId - URL or ContextType [IdentityAdapter]
    function _fetchModulesByUsersTag(string memory ctxId, bytes32[] memory users, uint[] memory outbuf, uint _bufLen) internal view returns (uint) {
        uint bufLen = _bufLen;
        for (uint i = 0; i < users.length; ++i) {
            bytes32 key = keccak256(abi.encodePacked(ctxId, users[i]));
            uint32[] memory modIdxs = modsByContextType[key];
            //add if no duplicates in buffer[0..nn-1]
            uint lastBufLen = bufLen;
            for(uint j = 0; j < modIdxs.length; ++j) {
                uint modIdx = modIdxs[j];
                uint k = 0;
                for(; k < lastBufLen; ++k) {
                    if (outbuf[k] == modIdx) break; //duplicate found
                }
                if (k == lastBufLen) { //no duplicates found  -- add the module's index
                    outbuf[bufLen++] = modIdx;
                    ModuleInfo memory m = modules[modIdx];
                    bufLen = _fetchModulesByUsersTag(m.name, users, outbuf, bufLen); // using index as a tag.
                    bufLen = _fetchModulesByUsersTags(m.interfaces, users, outbuf, bufLen);
                    //ToDo: what if owner changes? CREATE MODULE ENS  NAMES! on creating ENS  
                }
            }
        }
        return bufLen;
    }
    
    function _addModuleVersionNoChecking(uint moduleIdx, string memory mod_name, VersionInfoDto memory v) private {
        bytes32[] memory deps = new bytes32[](v.dependencies.length);
        for (uint i = 0; i < v.dependencies.length; ++i) {
            DependencyDto memory d = v.dependencies[i];
            bytes32 dKey = keccak256(abi.encodePacked(d.name, d.branch, d.major, d.minor, d.patch));
            require(versions[dKey].modIdx != 0, "Dependency doesn't exist");
            deps[i] = dKey;
        }

        bytes32[] memory interfaces = new bytes32[](v.interfaces.length);
        for (uint i = 0; i < v.interfaces.length; ++i) {
            DependencyDto memory interf = v.interfaces[i];
            bytes32 iKey = keccak256(abi.encodePacked(interf.name, interf.branch, interf.major, interf.minor, interf.patch));
            require(versions[iKey].modIdx != 0, "Interface doesn't exist");
            interfaces[i] = iKey;
            
            // add interface name to ModuleInfo if not exist
            bool isInterfaceExist = false;
            for (uint j = 0; j < modules[moduleIdx].interfaces.length; ++j) {
                if (keccak256(abi.encodePacked(modules[moduleIdx].interfaces[j])) == keccak256(abi.encodePacked(interf.name))) {
                    isInterfaceExist = true;
                    break;
                }
            }

            if (isInterfaceExist == false) {
                modules[moduleIdx].interfaces.push(interf.name);
            }
        }
        
        VersionInfo memory vInfo = VersionInfo(moduleIdx, v.branch, v.major, v.minor, v.patch, v.flags, v.binary, deps, interfaces);
        bytes32 vKey = keccak256(abi.encodePacked(mod_name, v.branch, v.major, v.minor, v.patch));
        versions[vKey] = vInfo;
        
        bytes32 nbKey = keccak256(abi.encodePacked(mod_name, vInfo.branch));
        versionNumbers[nbKey].push(byte(vInfo.major));
        versionNumbers[nbKey].push(byte(vInfo.minor));
        versionNumbers[nbKey].push(byte(vInfo.patch));
        versionNumbers[nbKey].push(byte(0x0));
    }
    
    function _isEnsOwner(bytes32 userId) private pure returns(bool) {
        return userId >= 0; //ToDo: NOT_IMPLEMENTED
    }

    /*
    
    FUNCTIONS TO BE IMPLEMENTED:
    
    +function getManifests(string memory location, bytes32[] memory users) public view returns (ModuleInfo[] memory) { } // for popup
    +function getModules(string memory location, bytes32[] memory users) public view returns (string[] memory) { }
    +function getVersions(string memory name, string memory branch) public view returns (string[] memory) { }
    +function resolveToManifest(string memory name, string memory branch, string memory version) public view returns (VersionInfo memory) { }
    +function addModule(Manifest memory manifest) public { }
    +function transferOwnership(string memory moduleName, address newOwner) public { }
    +function addLocation(string memory moduleName, string memory location) public { }
    +function removeLocation(string memory location, uint256 moduleNameIndex, string memory moduleName) public { }
    function addDistUri(string memory name, string memory branch, string memory version, string memory distUri) public { }
    function removeHashUri(string memory name, string memory branch, string memory version, string memory distUri) public { }
    
    */
}