pragma solidity 0.4.24;

interface ERC820ImplementerInterface {
    /// @notice Contracts that implement an interferce in behalf of another contract must return true
    /// @param addr Address that the contract woll implement the interface in behalf of
    /// @param interfaceHash keccak256 of the name of the interface
    /// @return ERC820_ACCEPT_MAGIC if the contract can implement the interface represented by
    ///  `&#236;nterfaceHash` in behalf of `addr`
    function canImplementInterfaceForAddress(address addr, bytes32 interfaceHash) view public returns(bytes32);
}

contract ERC820Registry {
    bytes4 constant InvalidID = 0xffffffff;
    bytes4 constant ERC165ID = 0x01ffc9a7;
    bytes32 constant ERC820_ACCEPT_MAGIC = keccak256("ERC820_ACCEPT_MAGIC");

    mapping (address => mapping(bytes32 => address)) interfaces;
    mapping (address => address) managers;
    mapping (address => mapping(bytes4 => bool)) erc165Cache;

    event InterfaceImplementerSet(address indexed addr, bytes32 indexed interfaceHash, address indexed implementer);
    event ManagerChanged(address indexed addr, address indexed newManager);

    /// @notice Query the hash of an interface given a name
    /// @param interfaceName Name of the interfce
    function interfaceHash(string interfaceName) public pure returns(bytes32) {
        return keccak256(interfaceName);
    }

    /// @notice GetManager
    function getManager(address addr) public view returns(address) {
        // By default the manager of an address is the same address
        if (managers[addr] == 0) {
            return addr;
        } else {
            return managers[addr];
        }
    }

    /// @notice Sets an external `manager` that will be able to call `setInterfaceImplementer()`
    ///  on behalf of the address.
    /// @param _addr Address that you are defining the manager for. (0x0 if is msg.sender)
    /// @param newManager The address of the manager for the `addr` that will replace
    ///  the old one.  Set to 0x0 if you want to remove the manager.
    function setManager(address _addr, address newManager) public {
        address addr = _addr == 0 ? msg.sender : _addr;
        require(getManager(addr) == msg.sender);
        managers[addr] = newManager == addr ? 0 : newManager;
        ManagerChanged(addr, newManager);
    }

    /// @notice Query if an address implements an interface and thru which contract
    /// @param _addr Address that is being queried for the implementation of an interface
    ///  (if _addr == 0 them `msg.sender` is assumed)
    /// @param iHash SHA3 of the name of the interface as a string
    ///  Example `web3.utils.sha3(&#39;ERC777Token`&#39;)`
    /// @return The address of the contract that implements a specific interface
    ///  or 0x0 if `addr` does not implement this interface
    function getInterfaceImplementer(address _addr, bytes32 iHash) constant public returns (address) {
        address addr = _addr == 0 ? msg.sender : _addr;
        if (isERC165Interface(iHash)) {
            bytes4 i165Hash = bytes4(iHash);
            return erc165InterfaceSupported(addr, i165Hash) ? addr : 0;
        }
        return interfaces[addr][iHash];
    }

    /// @notice Sets the contract that will handle a specific interface; only
    ///  a `manager` defined for that address can set it.
    ///  ( Each address is the manager for itself until a new manager is defined)
    /// @param _addr Address that you want to define the interface for
    ///  (if _addr == 0 them `msg.sender` is assumed)
    /// @param iHash SHA3 of the name of the interface as a string
    ///  For example `web3.utils.sha3(&#39;Ierc777&#39;)` for the Ierc777
    function setInterfaceImplementer(address _addr, bytes32 iHash, address implementer) public  {
        address addr = _addr == 0 ? msg.sender : _addr;
        require(getManager(addr) == msg.sender);

        require(!isERC165Interface(iHash));
        if ((implementer != 0) && (implementer!=msg.sender)) {
            require(ERC820ImplementerInterface(implementer).canImplementInterfaceForAddress(addr, iHash)
                        == ERC820_ACCEPT_MAGIC);
        }
        interfaces[addr][iHash] = implementer;
        InterfaceImplementerSet(addr, iHash, implementer);
    }


/// ERC165 Specific

    function isERC165Interface(bytes32 iHash) internal pure returns (bool) {
        return iHash & 0x00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF == 0;
    }

    function erc165InterfaceSupported(address _contract, bytes4 _interfaceId) constant public returns (bool) {
        if (!erc165Cache[_contract][_interfaceId]) {
            erc165UpdateCache(_contract, _interfaceId);
        }
        return interfaces[_contract][_interfaceId] != 0;
    }

    function erc165UpdateCache(address _contract, bytes4 _interfaceId) public {
        interfaces[_contract][_interfaceId] =
            erc165InterfaceSupported_NoCache(_contract, _interfaceId) ? _contract : 0;
        erc165Cache[_contract][_interfaceId] = true;
    }

    function erc165InterfaceSupported_NoCache(address _contract, bytes4 _interfaceId) public constant returns (bool) {
        uint256 success;
        uint256 result;

        (success, result) = noThrowCall(_contract, ERC165ID);
        if ((success==0)||(result==0)) {
            return false;
        }

        (success, result) = noThrowCall(_contract, InvalidID);
        if ((success==0)||(result!=0)) {
            return false;
        }

        (success, result) = noThrowCall(_contract, _interfaceId);
        if ((success==1)&&(result==1)) {
            return true;
        }
        return false;
    }

    function noThrowCall(address _contract, bytes4 _interfaceId) constant internal returns (uint256 success, uint256 result) {
        bytes4 erc165ID = ERC165ID;

        assembly {
                let x := mload(0x40)               // Find empty storage location using "free memory pointer"
                mstore(x, erc165ID)                // Place signature at begining of empty storage
                mstore(add(x, 0x04), _interfaceId) // Place first argument directly next to signature

                success := staticcall(
                                    30000,         // 30k gas
                                    _contract,     // To addr
                                    x,             // Inputs are stored at location x
                                    0x08,          // Inputs are 8 bytes long
                                    x,             // Store output over input (saves space)
                                    0x20)          // Outputs are 32 bytes long

                result := mload(x)                 // Load the result
        }
    }
}