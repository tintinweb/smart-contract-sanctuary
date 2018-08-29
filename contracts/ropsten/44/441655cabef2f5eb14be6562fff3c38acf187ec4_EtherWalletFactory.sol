pragma solidity ^0.4.24;
contract EtherWallet {
    address factoryAddress;
    uint public decimals;
    uint public totalSupply;
    address public owner;
    string public name;
    string public symbol;
    uint gateGas;
    event Transfer(address indexed from, address indexed to, uint256 value);
    constructor (address _owner) public {
        owner = _owner; //Controller wallet
        decimals = 18; //Fixing Ether value at event log
        name = "Ethereum Wallet";
        symbol = "ETH";
        totalSupply = 1e26;
        factoryAddress = msg.sender;
        gateGas = 200000;
    }
    function () public payable {
        require(msg.data.length == 0);
        deposit();
    }
    function deposit() public payable returns(bool) {
        require(msg.value > 0);
        emit Transfer(msg.sender, address(this), msg.value);
        return true;
    }
    function sendTo(address to, uint amount) public returns(bool) {
        require(msg.sender == owner);
        require(to != address(0) && address(this) != address(this));
        require(amount > 0 && amount <= address(this).balance);
        if (!to.call.gas(100000).value(amount)()) to.transfer(amount);
        emit Transfer(address(this), to, amount);
        return true;
    }
    function setOwner(address newOwner) public returns(bool) {
        require(msg.sender == owner);
        require(newOwner != address(0) && newOwner != address(this));
        owner = newOwner;
        return true;
    }
    function setGateGas(uint newGas) public returns(bool) {
        require(msg.sender == owner && newGas >= 180000);
        gateGas = newGas;
        return true;
    }
    function newGateway() public returns(bool) {
        if (!factoryAddress.call.gas(230400).value(0)(0x09bb7162)) revert();
        return true;
    }
}
contract EtherGateway {
    address public dest;
    constructor(address _dest) public {
        dest = _dest;
    }
    function () public payable {
        require(msg.data.length == 0 && msg.value > 0);
        if (!dest.call.gas(50000).value(msg.value)()) dest.transfer(msg.value);
    }
}
contract EtherWalletFactory {
    address public admin = msg.sender;
    address public _claimer = msg.sender;
    address[] generatedLists;
    mapping(address => address) _walletLists;
    mapping(address => address) _ownedWallets;
    uint public fees = 10 finney;
    event WalletGenerated(address indexed walletAddress, address indexed walletOwner);
    event GatewayGenerated(address indexed gatewayAddress, address indexed beneficiaryAddress);
    function walletLists() public view returns(address[]) {
        return generatedLists;
    }
    function walletOf(address walletOwner) public view returns(address) {
        return _walletLists[walletOwner];
    }
    function setAdmin(address newAdmin) public returns(bool) {
        require(msg.sender == admin);
        require(newAdmin != address(0) && address(this) != newAdmin);
        admin = newAdmin;
        return true;
    }
    function setFee(uint newFee) public returns(bool) {
        require(msg.sender == admin);
        require(newFee >= 1 szabo);
        fees = newFee;
        return true;
    }
    function generate() public payable returns(address) {
        if (msg.sender != admin) require(msg.value >= fees);
        EtherWallet a = new EtherWallet(msg.sender);
        generatedLists.push(address(a));
        _walletLists[msg.sender] = address(a);
        _ownedWallets[address(a)] = msg.sender;
        emit WalletGenerated(address(a), msg.sender);
        return address(a);
    }
    function _isProduct(address addr) internal view returns(bool) {
        if (_ownedWallets[addr] == address(0)) return false;
        else return true;
    }
    function createGateway() public returns(bool) {
        require(_isProduct(msg.sender));
        EtherGateway b = new EtherGateway(msg.sender);
        emit GatewayGenerated(address(b), msg.sender);
        return true;
    }
    function claim() public returns(bool) {
        require(msg.sender == _claimer && address(this).balance > 0);
        _claimer.transfer(address(this).balance);
        return true;
    }
    function setClaimer(address newClaimer) public returns(bool) {
        require(msg.sender == admin);
        _claimer = newClaimer;
        return true;
    }
}