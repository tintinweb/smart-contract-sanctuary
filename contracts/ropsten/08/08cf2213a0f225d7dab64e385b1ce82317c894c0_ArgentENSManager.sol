// Copyright (C) 2018  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.12;

import "./Owned.sol";

/**
 * @title Managed
 * @notice Basic contract that defines a set of managers. Only the owner can add/remove managers.
 * @author Julien Niset, Olivier VDB - <[email protected]>, <[email protected]>
 */
contract Managed is Owned {

    // The managers
    mapping (address => bool) public managers;

    /**
     * @notice Throws if the sender is not a manager.
     */
    modifier onlyManager {
        require(managers[msg.sender] == true, "M: Must be manager");
        _;
    }

    event ManagerAdded(address indexed _manager);
    event ManagerRevoked(address indexed _manager);

    /**
    * @notice Adds a manager.
    * @param _manager The address of the manager.
    */
    function addManager(address _manager) external onlyOwner {
        require(_manager != address(0), "M: Address must not be null");
        if (managers[_manager] == false) {
            managers[_manager] = true;
            emit ManagerAdded(_manager);
        }
    }

    /**
    * @notice Revokes a manager.
    * @param _manager The address of the manager.
    */
    function revokeManager(address _manager) external virtual onlyOwner {
        require(managers[_manager] == true, "M: Target must be an existing manager");
        delete managers[_manager];
        emit ManagerRevoked(_manager);
    }
}

// Copyright (C) 2018  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.5.4 <0.7.0;

/**
 * @title Owned
 * @notice Basic contract to define an owner.
 * @author Julien Niset - <[email protected]>
 */
contract Owned {

    // The owner
    address public owner;

    event OwnerChanged(address indexed _newOwner);

    /**
     * @notice Throws if the sender is not the owner.
     */
    modifier onlyOwner {
        require(msg.sender == owner, "Must be owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
    }

    /**
     * @notice Lets the owner transfer ownership of the contract to a new owner.
     * @param _newOwner The new owner.
     */
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Address must not be null");
        owner = _newOwner;
        emit OwnerChanged(_newOwner);
    }
}

// Copyright (C) 2018  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.6.12;
import "../../../lib/ens/ENS.sol";
import "../../modules/common/Utils.sol";
import "./IENSManager.sol";
import "./IENSResolver.sol";
import "./IReverseRegistrar.sol";
import "../base/Managed.sol";

/**
 * @title ArgentENSManager
 * @notice Implementation of an ENS manager that orchestrates the complete registration of subdomains for a single root (e.g. argent.eth).
 * The contract defines a manager role who is the only role that can trigger the registration of a new subdomain.
 * @author Julien Niset - <[email protected]>
 */
contract ArgentENSManager is IENSManager, Owned, Managed {

    // The managed root name
    string public rootName;
    // The managed root node
    bytes32 public rootNode;

    ENS public ensRegistry;
    IENSResolver public ensResolver;

    // namehash('addr.reverse')
    bytes32 constant public ADDR_REVERSE_NODE = 0x91d1777781884d03a6757a803996e38de2a42967fb37eeaca72729271025a9e2;


   modifier validateENSLabel(string memory _label) {
      bytes memory labelBytes = bytes(_label);
      require(labelBytes.length != 0, "AEM: ENS label must be defined");
      _;
    }

    // *************** Constructor ********************** //

    /**
     * @notice Constructor that sets the ENS root name and root node to manage.
     * @param _rootName The root name (e.g. argentx.eth).
     * @param _rootNode The node of the root name (e.g. namehash(argentx.eth)).
     * @param _ensRegistry The address of the ENS registry
     * @param _ensResolver The address of the ENS resolver
     */
    constructor(string memory _rootName, bytes32 _rootNode, address _ensRegistry, address _ensResolver) public {
        rootName = _rootName;
        rootNode = _rootNode;
        ensRegistry = ENS(_ensRegistry);
        ensResolver = IENSResolver(_ensResolver);
    }

    // *************** External Functions ********************* //

    /**
     * @notice This function must be called when the ENS Manager contract is replaced and the address of the new Manager should be provided.
     * @param _newOwner The address of the new ENS manager that will manage the root node.
     */
    function changeRootnodeOwner(address _newOwner) external override onlyOwner {
        ensRegistry.setOwner(rootNode, _newOwner);
        emit RootnodeOwnerChange(rootNode, _newOwner);
    }

    /**
     * @notice Lets the owner change the address of the ENS resolver contract.
     * @param _ensResolver The address of the ENS resolver contract.
     */
    function changeENSResolver(address _ensResolver) external onlyOwner {
        require(_ensResolver != address(0), "WF: address cannot be null");
        ensResolver = IENSResolver(_ensResolver);
        emit ENSResolverChanged(_ensResolver);
    }

    /**
    * @notice Lets the manager assign an ENS subdomain of the root node to a target address.
    * Registers both the forward and reverse ENS.
    * @param _label The subdomain label.
    * @param _owner The owner of the subdomain.
    * @param _managerSignature The manager signature of the hash of _owner and _label.
    */
    function register(string calldata _label, address _owner, bytes calldata _managerSignature) external override validateENSLabel(_label) {
        bytes32 signedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", keccak256(abi.encodePacked(_owner, _label))));
        validateManagerSignature(signedHash, _managerSignature);

        bytes32 labelNode = keccak256(abi.encodePacked(_label));
        bytes32 node = keccak256(abi.encodePacked(rootNode, labelNode));
        address currentOwner = ensRegistry.owner(node);
        require(currentOwner == address(0), "AEM: label is already owned");

        // Forward ENS
        ensRegistry.setSubnodeRecord(rootNode, labelNode, _owner, address(ensResolver), 0);
        ensResolver.setAddr(node, _owner);

        string memory name = string(abi.encodePacked(_label, ".", rootName));

        // Optionally set the reverse ENS
        bytes32 reverseNode = IReverseRegistrar(_getENSReverseRegistrar()).node(_owner);

        if(ensRegistry.resolver(reverseNode) == address(ensResolver)) {
            ensResolver.setName(reverseNode, name);
        }

        emit Registered(_owner, name);
    }

    /**
     * @notice Throws if the sender is not a manager and the manager's signature for the creation of the new wallet is invalid.
     * @param _signedHash The signed hash
     * @param _managerSignature The manager's signature
     */
    function validateManagerSignature(bytes32 _signedHash, bytes memory _managerSignature) internal view {
        address user;
        if(_managerSignature.length != 65) {
            user = msg.sender;
        } else {
            user = Utils.recoverSigner(_signedHash, _managerSignature, 0);
        }
        require(managers[user], "AEM: user is not manager");
    }

    /**
    * @notice Gets the official ENS reverse registrar.
    * @return Address of the ENS reverse registrar.
    */
    function getENSReverseRegistrar() external view override returns (address) {
        return _getENSReverseRegistrar();
    }

    // *************** Public Functions ********************* //

    /**
     * @notice Returns true is a given subnode is available.
     * @param _subnode The target subnode.
     * @return true if the subnode is available.
     */
    function isAvailable(bytes32 _subnode) public view override returns (bool) {
        bytes32 node = keccak256(abi.encodePacked(rootNode, _subnode));
        address currentOwner = ensRegistry.owner(node);
        if (currentOwner == address(0)) {
            return true;
        }
        return false;
    }

    function _getENSReverseRegistrar() internal view returns (address) {
        return ensRegistry.owner(ADDR_REVERSE_NODE);
    }
}

// Copyright (C) 2018  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.12;

/**
 * @notice Interface for an ENS Mananger.
 */
interface IENSManager {
    event RootnodeOwnerChange(bytes32 indexed _rootnode, address indexed _newOwner);
    event ENSResolverChanged(address addr);
    event Registered(address indexed _owner, string _ens);
    event Unregistered(string _ens);

    /**
     * @notice This function must be called when the ENS Manager contract is replaced
     * and the address of the new Manager should be provided.
     * @param _newOwner The address of the new ENS manager that will manage the root node.
     */
    function changeRootnodeOwner(address _newOwner) external;

    /**
    * @notice Lets the manager assign an ENS subdomain of the root node to a target address.
    * Registers both the forward and reverse ENS.
    * @param _label The subdomain label.
    * @param _owner The owner of the subdomain.
    * @param _managerSignature The manager signature of the hash of _owner and _label.
    */
    function register(string calldata _label, address _owner, bytes calldata _managerSignature) external;

    /**
     * @notice Returns true is a given subnode is available.
     * @param _subnode The target subnode.
     * @return true if the subnode is available.
     */
    function isAvailable(bytes32 _subnode) external view returns(bool);

    /**
    * @notice Gets the official ENS reverse registrar.
    * @return Address of the ENS reverse registrar.
    */
    function getENSReverseRegistrar() external view returns (address);
}

// Copyright (C) 2018  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.6.12;

/**
 * @notice ENS Resolver interface.
 */
interface IENSResolver {
    event AddrChanged(bytes32 indexed _node, address _addr);
    event NameChanged(bytes32 indexed _node, string _name);

    function addr(bytes32 _node) external view returns (address);
    function setAddr(bytes32 _node, address _addr) external;
    function name(bytes32 _node) external view returns (string memory);
    function setName(bytes32 _node, string memory _name) external;
}

// Copyright (C) 2018  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.6.12;

/**
 * @notice ENS Reverse Registrar interface.
 */
interface IReverseRegistrar {
    function claim(address _owner) external returns (bytes32);
    function claimWithResolver(address _owner, address _resolver) external returns (bytes32);
    function setName(string memory _name) external returns (bytes32);
    function node(address _addr) external pure returns (bytes32);
}

// Copyright (C) 2020  Argent Labs Ltd. <https://argent.xyz>

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.6.12;

/**
 * @title Utils
 * @notice Common utility methods used by modules.
 */
library Utils {

    /**
    * @notice Helper method to recover the signer at a given position from a list of concatenated signatures.
    * @param _signedHash The signed hash
    * @param _signatures The concatenated signatures.
    * @param _index The index of the signature to recover.
    */
    function recoverSigner(bytes32 _signedHash, bytes memory _signatures, uint _index) internal pure returns (address) {
        uint8 v;
        bytes32 r;
        bytes32 s;
        // we jump 32 (0x20) as the first slot of bytes contains the length
        // we jump 65 (0x41) per signature
        // for v we load 32 bytes ending with v (the first 31 come from s) then apply a mask
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(_signatures, add(0x20,mul(0x41,_index))))
            s := mload(add(_signatures, add(0x40,mul(0x41,_index))))
            v := and(mload(add(_signatures, add(0x41,mul(0x41,_index)))), 0xff)
        }
        require(v == 27 || v == 28);

        address recoveredAddress = ecrecover(_signedHash, v, r, s);
        require(recoveredAddress != address(0), "Utils: ecrecover returned 0");
        return recoveredAddress;
    }

    /**
    * @notice Helper method to parse data and extract the method signature.
    */
    function functionPrefix(bytes memory _data) internal pure returns (bytes4 prefix) {
        require(_data.length >= 4, "RM: Invalid functionPrefix");
        // solhint-disable-next-line no-inline-assembly
        assembly {
            prefix := mload(add(_data, 0x20))
        }
    }

    /**
    * @notice Returns ceil(a / b).
    */
    function ceil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        if (a % b == 0) {
            return c;
        } else {
            return c + 1;
        }
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a < b) {
            return a;
        }
        return b;
    }

    function safe128(uint256 _num) internal pure returns (uint128) {
        require(_num < 2**128, "LU: more then 128 bits");
        return uint128(_num);
    }

    function safe64(uint256 _num) internal pure returns (uint64) {
        require(_num < 2**64, "LU: more then 64 bits");
        return uint64(_num);
    }
}

pragma solidity >=0.4.24;

/**
 * ENS Registry interface.
 * Reference: https://github.com/ensdomains/ens/blob/master/contracts/ENS.sol
 */

interface ENS {

    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function setRecord(bytes32 node, address owner, address resolver, uint64 ttl) external;
    function setSubnodeRecord(bytes32 node, bytes32 label, address owner, address resolver, uint64 ttl) external;
    function setSubnodeOwner(bytes32 node, bytes32 label, address owner) external returns(bytes32);
    function setResolver(bytes32 node, address resolver) external;
    function setOwner(bytes32 node, address owner) external;
    function setTTL(bytes32 node, uint64 ttl) external;
    function setApprovalForAll(address operator, bool approved) external;
    function owner(bytes32 node) external view returns (address);
    function resolver(bytes32 node) external view returns (address);
    function ttl(bytes32 node) external view returns (uint64);
    function recordExists(bytes32 node) external view returns (bool);
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}