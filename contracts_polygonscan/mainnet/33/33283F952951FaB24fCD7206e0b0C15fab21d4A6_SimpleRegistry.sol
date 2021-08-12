pragma solidity 0.8.0;

contract SimpleRegistry {
    mapping (string => string) public _registry;

    address public _admin;

    constructor() {
        _admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == _admin, "onlyAdmin: Only admin");
        _;
    }

    function setAdmin(address admin) public onlyAdmin() {
        _admin = admin;
    }

    function resolve(string memory name) public view returns (string memory) {
        return _registry[name];
    }

    function set(string memory name, string memory record) public onlyAdmin() {
        _registry[name] = record;
    }
}