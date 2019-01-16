pragma solidity ^0.5.2;
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
contract Proxy {
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
contract Generator {
    AlphaGenerator generator;
    event Generated(address indexed adminAddress, address indexed vaultAddress, address indexed proxyAddress);
    function setGenerator(address newGenerator) public {
        require(address(generator) == address(0));
        uint length;
        assembly { length := extcodesize(newGenerator) }
        require(length > 0);
        generator = AlphaGenerator(newGenerator);
    }
    function generate(address _admin, address _owner) public returns(address _vault, address _proxy) {
        _vault = generator.generate(address(this), _owner);
        _proxy = address(new Proxy(_admin, _vault));
        if (!Alpha(_vault).setting(_proxy, _owner)) revert();
        emit Generated(_admin, _vault, _proxy);
        return (_vault, _proxy);
    }
}