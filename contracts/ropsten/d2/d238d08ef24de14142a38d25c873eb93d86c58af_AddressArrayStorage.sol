// Integer array storage.
contract IntArrayStorage {

    uint256[] arr;

    function getArrLength()
    returns (uint256)
    {
        return arr.length;
    }

    function setIntArr(uint256 _index, uint256 _value)
    {
        arr[_index] = _value;
    }


    // Convenient function for out of evm world.
    function getAsBytes(uint256 _from, uint256 _to)
    public
    constant
    returns (bytes)
    {
        require(_from >= 0 && _to >= _from && arr.length >= _to);
      
        // Size of bytes
        uint256 size = 32 * (_to - _from + 1);
        uint256 counter = 0;
        bytes memory b = new bytes(size);
        for (uint256 x = _from; x < _to + 1; x++) {
            uint256 elem = arr[x];
            for (uint y = 0; y < 32; y++) {
                b[counter] = byte(uint8(elem / (2 ** (8 * (31 - y)))));
                counter++;
            }
        }
        return b;
    }
}
// address array storage.
contract AddressArrayStorage {

    address[] arr;

    function getArrLength()
    returns (uint256)
    {
        return arr.length;
    }

    function setIntArr(uint256 _index, address _value)
    {
        arr[_index] = _value;
    }


    // Convenient function for out of evm world.
    function getAsBytes(uint256 _from, uint256 _to)
    public
    constant
    returns (bytes)
    {
   	require(_from >= 0 && _to >= _from && arr.length >= _to);
        
        // Size of bytes
        uint256 size = 20 * (_to - _from + 1);
        uint256 counter = 0;
        bytes memory b = new bytes(size);
        for (uint256 x = _from; x < _to + 1; x++) {
            bytes memory elem = toBytes(arr[x]);
            for (uint y = 0; y < 20; y++) {
                b[counter] = elem[y];
                counter++;
            }
        }
        return b;
    }

    // from: https://ethereum.stackexchange.com/questions/884/how-to-convert-an-address-to-bytes-in-solidity
    function toBytes(address a) constant returns (bytes b){
        assembly {
            let m := mload(0x40)
            mstore(add(m, 20), xor(0x140000000000000000000000000000000000000000, a))
            mstore(0x40, add(m, 52))
            b := m
        }
    }
}