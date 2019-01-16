pragma solidity ^0.4.25;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
}
contract KiOS {
    function generate() public returns(address);
    function changeAdmin(address newAdmin) public returns(bool);
    function payment() public payable returns(bool);
    function pay(address dest, address token, uint amount) public returns(bool);
    function setRate(address token, uint price) public returns(bool);
    function changeOwner(address newOwner) public returns(bool);
    function sendTo(address dest, uint amount, address token) public returns(bool);
}
contract KiOS_Proxy {
    address manager;
    address factory; // 0x1449251381Dc0Fd244Ef7faB961D70837b1D4ACD
    address tokenBox; // 0xFD622eca963f30cBf1C88518f1F3eDDe755410D6
    address etherBox; // 0x540180C6C89Fa8803804322c27232b240Bfb6FF0
    address[] _wallets;
    uint maxWallet;
    constructor(address _manager, address _factory, address _tokenBox, address _etherBox, uint _maxWallet) public {
        manager = _manager;
        factory = _factory;
        tokenBox = _tokenBox;
        etherBox = _etherBox;
        maxWallet = _maxWallet;
    }
    modifier restrict() {
        require(msg.sender == manager);
        _;
    }
    function exists(address who) internal view returns(bool) {
        uint a = 0;
        bool b = false;
        if (who != address(0) && address(this) != who) {
            while (a < _wallets.length) {
                if (_wallets[a] == who) {
                    break;
                    b = true;
                }
                a++;
            }
        }
        return b;
    }
    function update(address newManager, address newTokenBox, address newEtherBox) public restrict returns(bool) {
        if (newManager != address(0) && address(this) != newManager) manager = newManager;
        if (newTokenBox != address(0) && address(this) != newTokenBox && newTokenBox != etherBox) tokenBox = newTokenBox;
        if (newEtherBox != address(0) && address(this) != newEtherBox && newEtherBox != tokenBox) etherBox = newEtherBox;
        return true;
    }
    function setTokenRate(address token, uint rate) public restrict returns(bool) {
        require(KiOS(tokenBox).setRate(token, rate));
        return true;
    }
    function getBalance(address who, address token) internal view returns(uint) {
        uint a = who.balance;
        if (token != address(0)) a = ERC20(token).balanceOf(who);
        return a;
    }
    function managedWallets() public view returns(uint) {
        return _wallets.length;
    }
    function() public payable {
        payment();
    }
    function payment() public payable returns(bool) {
        require(msg.value > 0);
        uint a = msg.value;
        if (!KiOS(etherBox).payment.value(a)()) manager.transfer(a);
        return true;
    }
    function create() public restrict returns(address) {
        require(_wallets.length < maxWallet);
        address newWallet = KiOS(factory).generate();
        _wallets.push(newWallet);
        return newWallet;
    }
    function collect(address token, uint start_ID, uint finish_ID) public restrict returns(uint) {
        require(start_ID >= 0 && start_ID <= finish_ID && finish_ID < _wallets.length);
        uint invalid = 0;
        uint a = start_ID;
        uint x;
        address recipient = tokenBox;
        if (token == address(0)) recipient = etherBox;
        if (start_ID == finish_ID) {
            x = getBalance(_wallets[start_ID], token);
            if (x > 0) {
                if (!KiOS(_wallets[start_ID]).pay(recipient, token, x)) invalid += 1;
            }
        } else {
            while (a < finish_ID) {
                x = getBalance(_wallets[a], token);
                if (x > 0) {
                    if (!KiOS(_wallets[a]).pay(recipient, token, x)) invalid += 1;
                }
                a++;
            }
        }
        return invalid;
    }
    function moveEther() public restrict returns(bool) {
        uint amount = getBalance(tokenBox, address(0));
        require(amount > 0);
        require(KiOS(tokenBox).pay(etherBox, address(0), amount));
        return true;
    }
    function moveToken(address token) public restrict returns(bool) {
        require(address(0) != token);
        uint amount = getBalance(etherBox, token);
        require(KiOS(etherBox).sendTo(tokenBox, amount, token));
        return true;
    }
    function transferTo(address dest, address token, uint amount) public restrict returns(bool) {
        require(dest != address(0) && dest != address(this) && dest != tokenBox && etherBox != dest && amount > 0);
        if (address(0) == token) {
            require(amount <= getBalance(etherBox, token));
            require(KiOS(etherBox).sendTo(dest, amount, token));
        } else {
            require(amount <= getBalance(tokenBox, token));
            require(KiOS(tokenBox).pay(dest, token, amount));
        }
        return true;
    }
    function withdraw(address token, uint amount) public restrict returns(bool) {
        require(transferTo(manager, token, amount));
        return true;
    }
}