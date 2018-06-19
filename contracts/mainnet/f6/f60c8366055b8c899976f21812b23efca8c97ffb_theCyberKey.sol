pragma solidity ^0.4.19;

contract theCyberGatekeeperInterface {
    function enter(bytes32 _passcode, bytes8 _gateKey) public returns (bool);
}

contract theCyberKey {
    address private gatekeeperAddress = 0x44919b8026f38D70437A8eB3BE47B06aB1c3E4Bf;

    function setGatekeeperAddress(address gatekeeper) public {
        gatekeeperAddress = gatekeeper;
    }

    function enter(bytes32 passcode) public returns (bool) {
        bytes8 key = generateKey();
        return theCyberGatekeeperInterface(gatekeeperAddress).enter(passcode, key);
    }

    function generateKey() private returns (bytes8 key) {
        // Below are the checks:
        // require(uint32(_gateKey) == uint16(_gateKey));
        // require(uint32(_gateKey) != uint64(_gateKey));
        // require(uint32(_gateKey) == uint16(tx.origin));

        // Check 1:
        //   the lower 4 bytes equal the lower 2 bytes; this can be implemented by padding the lower 2 bytes
        //   with 0&#39;s for the upper 2 bytes: 00 00 XX XX
        //   we&#39;ll start with initializing lower 4 to 0 to accomplish this;
        uint32 lower4Bytes = 0;

        // Check 2:
        //   Lower 4 bytes can&#39;t equal all bytes (which means upper 4 cannot equal 0)
        //   Set upper 4 to 1
        uint32 upper4Bytes = 1;

        // Check 3:
        //  The lower 2 bytes of the original transmitter should equal to the lower 4 bytes of the key
        //  This checks out with check 1 which says lower 4 bytes should have 2 upper zero bytes
        uint16 lower2Bytes = uint16(tx.origin);

        // Assemble key
        lower4Bytes |= lower2Bytes;
        uint64 allBytes = lower4Bytes;
        allBytes |= uint64(upper4Bytes) << 32;
        key = bytes8(allBytes);

        return key;
    }
}