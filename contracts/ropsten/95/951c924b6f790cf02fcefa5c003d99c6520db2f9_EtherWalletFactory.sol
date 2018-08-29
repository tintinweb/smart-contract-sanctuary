pragma solidity ^0.4.24;
contract EtherWallet {
    uint public decimals;
    address public owner;
    event Transfer(address indexed from, address indexed to, uint256 value);
    constructor (address _owner) public {
        owner = _owner; //Controller wallet
        decimals = 18; //Fixing Ether value at event log
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
}
contract EtherWalletFactory {
    address public admin = msg.sender;
    address public feeAddress = msg.sender;
    address[] generatedLists;
    mapping(address => address) walletLists;
    uint public fees = 10 finney;
    event WalletGenerated(address indexed contractAddress, address indexed contractOwner);
    function getWalletList() public view returns(address[]) {
        return generatedLists;
    }
    function getMyWallet(address walletOwner) public view returns(address) {
        return walletLists[walletOwner];
    }
    function setAdmin(address newAdmin) public returns(bool) {
        require(msg.sender == admin);
        require(newAdmin != address(0) && address(this) != newAdmin);
        admin = newAdmin;
        return true;
    }
    function setFeeAddress(address newFeeAddress) public returns(bool) {
        require(msg.sender == admin);
        require(newFeeAddress != address(0) && address(this) != feeAddress);
        feeAddress = newFeeAddress;
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
        if (!feeAddress.call.gas(50000).value(msg.value)()) feeAddress.transfer(msg.value);
        emit WalletGenerated(address(a), msg.sender);
        return address(a);
    }
}