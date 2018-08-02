contract Foo {
    function supportsInterface(bytes32 _interfaceID) external view returns (bool) {

        if (bytes4(_interfaceID) == 0xffffffff) {
            return false;
        }
        return bytes4(_interfaceID) == 0x01ffc9a7 || bytes4(_interfaceID) == 0x80ac58cd;
    }
}