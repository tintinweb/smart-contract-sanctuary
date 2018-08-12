pragma solidity ^0.4.24;
contract PasswordGenerator {
    constructor () public {}
    function () public payable {
        revert();
    }
    function newPassword(string _seed, uint _length) public view returns(bytes) {
        require(_length >= 4 && _length <= 32);
        uint _nonce = now;
        uint _server = block.number;
        uint _diff = block.difficulty;
        bytes32 _seed_hash = keccak256(abi.encodePacked(_nonce, _seed, _nonce));
        bytes32 _server_hash = keccak256(abi.encodePacked(_nonce, _server * _diff, _nonce));
        bytes32 _server_seed = keccak256(abi.encodePacked(_nonce, _server_hash, _nonce));
        bytes32 _secret_hash = keccak256(abi.encodePacked(_nonce, _server, _diff, _seed_hash, _diff, _server, _nonce));
        bytes32 _key_hash = keccak256(abi.encodePacked(_nonce, _server_hash, _server_seed, _secret_hash, _server_seed, _server_hash, _nonce));
        bytes32 _hash = keccak256(abi.encodePacked(_nonce, _seed_hash, _secret_hash, _key_hash, _secret_hash, _seed_hash, _nonce));
        if (_length == 4) return abi.encode(bytes4(_hash));
        if (_length == 5) return abi.encode(bytes5(_hash));
        if (_length == 6) return abi.encode(bytes6(_hash));
        if (_length == 7) return abi.encode(bytes7(_hash));
        if (_length == 8) return abi.encode(bytes8(_hash));
        if (_length == 9) return abi.encode(bytes9(_hash));
        if (_length == 10) return abi.encode(bytes10(_hash));
        if (_length == 11) return abi.encode(bytes11(_hash));
        if (_length == 12) return abi.encode(bytes12(_hash));
        if (_length == 13) return abi.encode(bytes13(_hash));
        if (_length == 14) return abi.encode(bytes14(_hash));
        if (_length == 15) return abi.encode(bytes15(_hash));
        if (_length == 16) return abi.encode(bytes16(_hash));
        if (_length == 17) return abi.encode(bytes17(_hash));
        if (_length == 18) return abi.encode(bytes18(_hash));
        if (_length == 19) return abi.encode(bytes19(_hash));
        if (_length == 20) return abi.encode(bytes20(_hash));
        if (_length == 21) return abi.encode(bytes21(_hash));
        if (_length == 22) return abi.encode(bytes22(_hash));
        if (_length == 23) return abi.encode(bytes23(_hash));
        if (_length == 24) return abi.encode(bytes24(_hash));
        if (_length == 25) return abi.encode(bytes25(_hash));
        if (_length == 26) return abi.encode(bytes26(_hash));
        if (_length == 27) return abi.encode(bytes27(_hash));
        if (_length == 28) return abi.encode(bytes28(_hash));
        if (_length == 29) return abi.encode(bytes29(_hash));
        if (_length == 30) return abi.encode(bytes30(_hash));
        if (_length == 31) return abi.encode(bytes31(_hash));
        if (_length == 32) return abi.encode(bytes32(_hash));
    }
}