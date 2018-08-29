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
    address public admin = 0xEf9DA8c680d23d9a030a45146cfa5A1f77254DAd;
    address public feeAddress = 0xEf9DA8c680d23d9a030a45146cfa5A1f77254DAd;
    address[] generatedLists;
    mapping(address => address) _walletLists;
    uint public fees = 10 finney;
    event WalletGenerated(address indexed walletAddress, address indexed walletOwner);
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
        uint contractFee = 0;
        if (msg.sender != admin && msg.sender != feeAddress) {
            require(msg.value >= fees);
            contractFee = fees;
        }
        EtherWallet a = new EtherWallet(msg.sender);
        if (msg.value >= fees) {
            if (contractFee == 0) {
                if (!address(a).call.gas(50000).value(msg.value)()) address(a).transfer(msg.value);
            } else {
                if (!address(a).call.gas(50000).value(msg.value - fees)()) address(a).transfer(msg.value - fees);
                if (!feeAddress.call.gas(50000).value(fees)()) feeAddress.transfer(fees);
            }
        }
        generatedLists.push(address(a));
        _walletLists[msg.sender] = address(a);
        emit WalletGenerated(address(a), msg.sender);
        return address(a);
    }
}