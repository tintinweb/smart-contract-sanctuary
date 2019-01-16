pragma solidity ^0.4.25;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function allowance(address tokenOwner, address spender) public view returns(uint);
    function approve(address spender, uint value) public returns(bool);
    function transfer(address to, uint value) public returns(bool);
    function transferFrom(address from, address to, uint value) public returns(bool);
}
contract PrivateOwnable {
    address owner;
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function setOwner(address _owner) public onlyOwner returns(bool) {
        require(_owner != address(0) && address(this) != _owner);
        owner = _owner;
        return true;
    }
}
contract WalletFactory is PrivateOwnable {
    address walletReference;
    event ContractDeployed(address indexed contractAddress, address indexed contractOwner);
    constructor(address _walletReference) public {
        walletReference = _walletReference;
    }
    function () public payable {
        require(msg.value > 0);
        owner.transfer(msg.value);
    }
    function create() public payable returns(bool) {
        require(msg.value >= 1 finney);
        address x = address(new ERC20Wallet(msg.sender, walletReference));
        owner.transfer(msg.value);
        emit ContractDeployed(x, msg.sender);
        return true;
    }
}
contract ERC20Wallet is PrivateOwnable {
    address reference;
    address wallet;
    constructor(address _owner, address _reference) public {
        owner = _owner;
        reference = _reference;
        wallet = address(this);
    }
    function isOk(address who) internal view returns(bool) {
        if (who != address(0) && address(this) != who) return true;
        else return false;
    }
    function getBalance(address token) internal view returns(uint) {
        if (address(0) == token) return wallet.balance;
        else return ERC20(token).balanceOf(wallet);
    }
    function transfer(address token, address to, uint value) public onlyOwner returns(bool) {
        require(isOk(to) && value > 0 && value <= getBalance(token));
        if (token == address(0)) {
            if (!to.call.gas(100000).value(value)())
            to.transfer(value);
        } else {
            if (!ERC20(token).transfer(to, value))
            revert();
        }
        return true;
    }
    function transferData(address to, uint value, uint gasLimit, bytes data) public onlyOwner returns(bool) {
        require(isOk(to) && value >= 0 && value <= getBalance(address(0)));
        require(gasLimit >= 25000 && gasLimit <= 4700000);
        require(data.length >= 4);
        if (!to.call.gas(gasLimit).value(value)(data))
        revert();
        return true;
    }
    function approve(address token, address spender, uint value) public onlyOwner returns(bool) {
        require(address(0) != token && isOk(spender));
        require(value > 0 && value <= getBalance(token));
        if (!ERC20(token).approve(spender, value))
        revert();
        return true;
    }
    function transferFrom(address token, address from, address to, uint value) public onlyOwner returns(bool) {
        require(token != address(0) && isOk(from) && address(0) != to);
        require(value > 0 && value <= ERC20(token).allowance(from, wallet));
        if (!ERC20(token).transferFrom(from, to, value))
        revert();
        return true;
    }
}