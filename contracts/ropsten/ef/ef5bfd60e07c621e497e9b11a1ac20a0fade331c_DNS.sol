pragma solidity ^0.4.24;

contract DNS {
    struct Name {
        address owner;
        string ipv6;
        bool exist;
    }

    struct Resolver {
        address owner;
        address resolverAddress;
        bool exist;
    }

    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    event NameRegistered(bytes32 indexed domain_hash);

    mapping(bytes32 => Name) public names;
    mapping(bytes32 => Resolver) public resolvers;
    mapping(bytes32 => uint) public expirationDates;

    modifier notRegistered(string name) {
        if (now > expirationDates[keccak256(bytes(name))]){
            require(!names[keccak256(bytes(name))].exist);
            require(!resolvers[keccak256(bytes(name))].exist);
        }
        _;
    }

    modifier onlyNameOwner(string name) {
        bytes memory _domain_bytes = bytes(name);
        bytes32 _key = keccak256(_domain_bytes);
        require(names[_key].owner == msg.sender || !names[_key].exist);
        require(resolvers[_key].owner == msg.sender || !resolvers[_key].exist);
        _;
    }

    function registerNameIP(string _domain, string _ipv6) public notRegistered(_domain) {
        bytes memory _domain_bytes = bytes(_domain);
        bytes32 _key = keccak256(_domain_bytes);
        names[_key] = Name(msg.sender, _ipv6, true);
        emit NameRegistered(_key);
        expirationDates[_key] = now + 1 years;
    }

    function registerNameResolver(string _domain, address _resolver) public notRegistered(_domain) {
        bytes memory _domain_bytes = bytes(_domain);
        bytes32 _key = keccak256(_domain_bytes);
        resolvers[_key] = Resolver(msg.sender, _resolver, true);
        emit NameRegistered(_key);
        expirationDates[_key] = now + 1 years;
    }

    function releaseName(string _domain) public onlyNameOwner(_domain) {
        bytes memory _domain_bytes = bytes(_domain);
        bytes32 _key = keccak256(_domain_bytes);
        delete names[_key];
        delete resolvers[_key];
        expirationDates[_key] = 0;
    }

    function updateNameResolver(string _domain, address _new_resolver) public onlyNameOwner(_domain) {
        bytes memory _domain_bytes = bytes(_domain);
        bytes32 _key = keccak256(_domain_bytes);
        require(resolvers[_key].exist);
        resolvers[_key].resolverAddress = _new_resolver;
        expirationDates[_key] = now + 1 years;
    }

    function updateNameIP(string _domain, string _new_ipv6) public onlyNameOwner(_domain) {
        bytes memory _domain_bytes = bytes(_domain);
        bytes32 _key = keccak256(_domain_bytes);
        require(names[_key].exist);
        names[_key].ipv6 = _new_ipv6;
        expirationDates[_key] = now + 1 years;
    }

    function getResolver(string _subdomain) public view returns (address _resolver, address _owner, bool _registered){
        bytes memory _domain_bytes = bytes(_subdomain);
        bytes32 _key = keccak256(_domain_bytes);
        Resolver memory resolver = resolvers[_key];
        _resolver = resolver.resolverAddress;
        _owner = resolver.owner;
        _registered = resolver.exist;
    }

    function resolveName(string _subdomain) public view returns (string _ipv6, address _owner, bool _registered){
        bytes memory _domain_bytes = bytes(_subdomain);
        bytes32 _key = keccak256(_domain_bytes);
        Name memory name = names[_key];
        _ipv6 = name.ipv6;
        _owner = name.owner;
        _registered = name.exist;
    }

    function useResolver(string _subdomain) public view returns (bool _use_resolver) {
        bytes memory _domain_bytes = bytes(_subdomain);
        bytes32 _key = keccak256(_domain_bytes);
        _use_resolver = !names[_key].exist && resolvers[_key].exist;
    }
}