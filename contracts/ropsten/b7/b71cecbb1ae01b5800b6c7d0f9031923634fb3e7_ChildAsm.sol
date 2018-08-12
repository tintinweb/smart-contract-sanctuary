pragma solidity >0.4.23 <0.5.0;

contract Parent {
    int value;

    function setValue(int v) public {
        value = v;
    }

    function getValue() external view returns (int) {
        return value;
    }

    function getSender() external view returns (address) {
        return msg.sender;
    }
}

contract ChildAsm {
    Parent parent;

    function setParent(address a) public {
        parent = Parent(a);
    }

    function getValue() external view returns (int value) {
    address addr = address(parent);
    bytes4 sig = bytes4(keccak256("getValue()"));

    assembly {
       let o := mload(0x40) // Empty storage pointer
       mstore(o,sig)        // Push function signature to memory (function signature is 4 bytes/0x04)
       //mstore(add(ptr,0x40), someInt32Argument); // Append function argument after signature
       // From here, the call data size (input) would be functiona signature size + sum(argument size)
       //   4bytes + 0 in this case, or 4bytes + 32bytes in the above commented `mstore`

       let success := call(
           15000,           // Gas limit
           addr,            // To address
           0,               // No ether to transfer
           o,               // Input location ptr
           0x04,            // Input size (0)
           o,               // Store oputput over input
           0x20)            // Output size (32 bytes)

       value := mload(o)
       mstore(0x40,add(o,0x04))
    }
}

function getSender() external view returns (address value) {
    address addr = address(parent);
    bytes4 sig = bytes4(keccak256("getSender()"));

    assembly {
       let o := mload(0x40) // Empty storage pointer
       mstore(o,sig)        // Push function signature to memory (function signature is 4 bytes/0x04)
       //mstore(add(ptr,0x40), someInt32Argument); // Append function argument after signature
       // From here, the call data size (input) would be functiona signature size + sum(argument size)
       //   4bytes + 0 in this case, or 4bytes + 32bytes in the above commented `mstore`

       let success := call(
           15000,           // Gas limit
           addr,            // To address
           0,               // No ether to transfer
           o,               // Input location ptr
           0x04,            // Input size (0)
           o,               // Store oputput over input
           0x20)            // Output size (32 bytes)

       value := mload(o)
       mstore(0x40,add(o,0x04))
    }
}
}