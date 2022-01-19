contract testChar {

    function readChar(string memory charCode) external view returns (string memory) {
        return string(abi.encodePacked(charCode));
    }


}