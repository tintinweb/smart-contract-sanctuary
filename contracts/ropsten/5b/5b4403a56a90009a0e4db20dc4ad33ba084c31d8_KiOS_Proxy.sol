pragma solidity ^0.4.25;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
}
contract KiOS {
    function generate(address _reference) public payable returns(address);
    function changeAdmin(address newAdmin) public returns(bool);
    function payment() public payable returns(bool);
    function pay(address to, address token, uint value) public returns(bool);
    function setRate(address token, uint price) public returns(bool);
}
contract KiOS_Proxy {
    address owner;
    address public vault;
    address public factory;
    address kiosReference;
    address[] _forks;
    constructor(address _owner,address _vault) public {
        owner = _owner;
        vault = _vault;
        factory = address(0);
        kiosReference = address(0);
    }
    modifier restrict() {
        require(msg.sender == owner);
        _;
    }
    function exists(address who) internal view returns(bool) {
        uint a = 0;
        bool b = false;
        if (who != address(0) && address(this) != who) {
            while (a < _forks.length) {
                if (_forks[a] == who) {
                    break;
                    b = true;
                }
                a++;
            }
        }
        return b;
    }
    function getBalance(address who, address token) internal view returns(uint) {
        uint a = who.balance;
        if (token != address(0)) a = ERC20(token).balanceOf(who);
        return a;
    }
    function forkedAddresses() public view returns(address[]) {
        return _forks;
    }
    function setFactory(address newFactory) public restrict returns(bool) {
        require(newFactory != address(0) && newFactory != address(this) && !exists(newFactory) && newFactory != vault);
        factory = newFactory;
        return true;
    }
    function setVault(address newVault) public restrict returns(bool) {
        require(newVault != address(0) && address(this) != newVault && !exists(newVault) && newVault != factory);
        vault = newVault;
        return true;
    }
    function setOwner(address newOwner) public restrict returns(bool) {
        require(newOwner != address(this) && address(0) != newOwner && !exists(newOwner) && newOwner != vault);
        owner = newOwner;
        return true;
    }
    function setProxy(address newProxy) public restrict returns(bool) {
        require(newProxy != address(0) && !exists(newProxy) && vault != newProxy);
        if (!KiOS(vault).changeAdmin(newProxy)) revert();
        return true;
    }
    function setPrice(address token, uint price) public restrict returns(bool) {
        if (!KiOS(vault).setRate(token, price)) revert();
        return true;
    }
    function setReference(address newReference) public restrict returns(bool) {
        require(newReference != address(0));
        kiosReference = newReference;
        return true;
    }
    function fork() public restrict returns(bool) {
        address x = KiOS(factory).generate(kiosReference);
        require(x != address(0));
        _forks.push(x);
        return true;
    }
    function() public payable {
        payment();
    }
    function payment() public payable returns(bool) {
        require(msg.value > 0);
        if (!KiOS(vault).payment.value(msg.value)()) owner.transfer(msg.value);
        return true;
    }
    function pay(address to, address token, uint amount) public restrict returns(bool) {
        require(to != address(0) && to != address(this) && to != vault && to != factory);
        require(amount > 0 && amount <= getBalance(vault, token));
        if (!KiOS(vault).pay(to, token, amount)) revert();
        return true;
    }
    function collect(address token, uint startIndex, uint movement) public restrict returns(bool) {
        require(startIndex >= 0 && startIndex < _forks.length && movement > 0 && movement <= (_forks.length - startIndex));
        uint i = startIndex;
        uint j;
        uint k = movement;
        uint stopIndex = startIndex + movement;
        while (i < stopIndex) {
            j = getBalance(_forks[i], token);
            if (j > 0) {
                if (!KiOS(_forks[i]).pay(vault, token, j)) k -= 1;
            } else {
                k -= 1;
            }
            i++;
        }
        return true;
    }
}