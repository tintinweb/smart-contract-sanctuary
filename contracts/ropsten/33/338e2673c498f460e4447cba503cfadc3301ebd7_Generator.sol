pragma solidity ^0.5.2;
contract Construction {
    constructor() public {}
}
contract Alpha {
    function forward() public payable returns(bool);
    function deposit(address token, address from, uint amount) public returns(bool);
    function withdraw(address token, uint amount) public returns(bool);
    function setting(address newAdmin, address newOwner) public returns(bool);
}
contract ERC20 {
    function totalSupply() public view returns(uint);
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint amount) public returns(bool);
}
contract Proxy is Construction {
    address payable vault;
    address admin;
    constructor(address _admin, address _vault) public {
        vault = address(uint160(_vault));
        admin = _admin;
    }
    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }
    function changeAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0) && address(this) != newAdmin);
        admin = newAdmin;
    }
    function changeVault(address newVault) public onlyAdmin {
        uint length;
        assembly { length := extcodesize(newVault) }
        require(length > 0);
        vault = address(uint160(newVault));
    }
    function setting(address newAdmin, address newOwner) public onlyAdmin {
        if (!Alpha(vault).setting(newAdmin, newOwner))
        revert();
    }
    function deposit(address token, address from, uint amount) public onlyAdmin {
        if (!Alpha(vault).deposit(token, from, amount))
        revert();
    }
    function tokenFallback(address from, uint amount, bytes memory extraData) public {
        uint length;
        address token = msg.sender;
        address sender;
        bytes memory _extra;
        assembly { length := extcodesize(token) }
        require(length > 0 && ERC20(token).totalSupply() > 0);
        _extra = extraData;
        sender = from;
        if (!ERC20(token).transfer(vault, amount))
        revert();
    }
    function withdraw(address token, uint amount) public onlyAdmin {
        if (!Alpha(vault).withdraw(token, amount))
        revert();
    }
    function transfer(ERC20 token) public onlyAdmin {
        require(token.balanceOf(address(this)) > 0);
        if (!token.transfer(vault, token.balanceOf(address(this))))
        revert();
    }
    function forward() public payable {
        if (!Alpha(vault).forward.value(msg.value)())
        revert();
    }
}
contract AlphaGenerator {
    function generate(address _admin, address _owner) public returns(address);
}
contract Generator is Construction {
    AlphaGenerator generator;
    event Generated(address indexed _adminAddress, address indexed _vaultAddress, address indexed _proxyAddress);
    constructor(address _generator) public {
        generator = AlphaGenerator(_generator);
    }
    function generate(address _admin, address _owner) public returns(address _vault, address _proxy) {
        Proxy _xtraProxy = new Proxy(address(this), _vault);
        _proxy = address(_xtraProxy);
        _vault = generator.generate(_proxy, _owner);
        _xtraProxy.changeVault(_vault);
        _xtraProxy.changeAdmin(_admin);
        emit Generated(_admin, _vault, _proxy);
        return (_vault, _proxy);
    }
}