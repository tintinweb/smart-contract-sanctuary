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
        bytes32 _key = nameok(name);
        if (now < expirationDates[_key]){
            require(!names[_key].exist);
            require(!resolvers[_key].exist);
        }
        _;
    }

    modifier onlyNameOwner(string name) {
        bytes32 _key = nameok(name);
        require(names[_key].owner == msg.sender || !names[_key].exist);
        require(resolvers[_key].owner == msg.sender || !resolvers[_key].exist);
        _;
    }

    function nameok(string _label) internal pure returns (bytes32 _key) {
        if (bytes(_label).length > 0){
            _key = keccak256(bytes(_label));
        } else {
            _key = keccak256(&#39;.&#39;);
        }
    }

    function registerNameIP(string _subdomain, string _ipv6) public notRegistered(_subdomain) {
        bytes32 _key = nameok(_subdomain);
        names[_key] = Name(msg.sender, _ipv6, true);
        emit NameRegistered(_key);
        expirationDates[_key] = now + 1 years;
    }

    function registerNameResolver(string _subdomain, address _resolver) public notRegistered(_subdomain) {
        bytes32 _key = nameok(_subdomain);
        resolvers[_key] = Resolver(msg.sender, _resolver, true);
        emit NameRegistered(_key);
        expirationDates[_key] = now + 1 years;
    }

    function releaseName(string _subdomain) public onlyNameOwner(_subdomain) {
        bytes32 _key = nameok(_subdomain);
        delete names[_key];
        delete resolvers[_key];
        expirationDates[_key] = 0;
    }

    function updateNameResolver(string _subdomain, address _new_resolver) public onlyNameOwner(_subdomain) {
        bytes32 _key = nameok(_subdomain);
        require(resolvers[_key].exist);
        resolvers[_key].resolverAddress = _new_resolver;
        expirationDates[_key] = now + 1 years;
    }

    function updateNameIP(string _subdomain, string _new_ipv6) public onlyNameOwner(_subdomain) {
        bytes32 _key = nameok(_subdomain);
        require(names[_key].exist);
        names[_key].ipv6 = _new_ipv6;
        expirationDates[_key] = now + 1 years;
    }

    function getResolver(string _subdomain) public view returns (address _resolver, address _owner, bool _registered){
        bytes32 _key = nameok(_subdomain);
        Resolver memory resolver = resolvers[_key];
        _resolver = resolver.resolverAddress;
        _owner = resolver.owner;
        _registered = resolver.exist;
    }

    function resolveName(string _subdomain) public view returns (string _ipv6, address _owner, bool _registered){
        bytes32 _key = nameok(_subdomain);
        Name memory name = names[_key];
        _ipv6 = name.ipv6;
        _owner = name.owner;
        _registered = name.exist;
    }

    function useResolver(string _subdomain) public view returns (bool _use_resolver) {
        bytes32 _key = nameok(_subdomain);
        _use_resolver = !names[_key].exist && resolvers[_key].exist;
    }
}