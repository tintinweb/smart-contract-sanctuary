contract Identity {
    function name() public view returns (string);
    function ethAddress() public view returns (address);
    function favoriteNumber() public view returns (uint);
    function koreanCitizen() public view returns (bool);
}

contract Junyeong is Identity {
    function name() public view returns (string) {
        return "Junyeong";
    }
    function ethAddress() public view returns (address) {
        return 0x2caCBe568E220D6cC7D4995455e1e1616b830bD0;
    }
    function favoriteNumber() public view returns (uint) {
        return 97;
    }
    function koreanCitizen() public view returns (bool) {
        return true;
    }
}