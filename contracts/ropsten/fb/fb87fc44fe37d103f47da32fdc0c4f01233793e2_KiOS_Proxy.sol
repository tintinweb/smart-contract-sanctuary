pragma solidity ^0.4.25;
contract Wallet {
    function giftMe() public payable returns(bool);
    function sendTo(address dest, address token, uint value) public returns(bool);
}
contract Vault is Wallet {
    address owner;
    constructor() public {
        owner = msg.sender;
    }
    modifier exclusive() {
        require(msg.sender == owner);
        _;
    }
    function() public payable {}
    function giftMe() public payable returns(bool) {
        require(msg.value > 0);
        return true;
    }
    function sendTo(address dest, address token, uint value) public exclusive returns(bool) {
        require(dest != address(0) && address(this) != dest);
        require(value > 0);
        if (token == address(0)) {
            require(value <= address(this).balance);
            if (!dest.call.gas(250000).value(value)())
            dest.transfer(value);
        } else {
            bytes memory tokenData = abi.encodeWithSignature("transfer(address,uint256)", dest, value);
            if (!token.call.gas(250000).value(0)(tokenData))
            revert();
        }
        return true;
    }
}
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function transfer(address dest, uint value) public view returns(bool);
}
contract KiOS_Proxy {
    address admin = msg.sender;
    address[] _wallets;
    uint maximumWallet = 255;
    modifier restrict() {
        require(msg.sender == admin);
        _;
    }
    function exists(address who) public view returns(bool) {
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
    function setAdmin(address newAdmin) public restrict returns(bool) {
        require(newAdmin != address(0) && address(this) != newAdmin);
        admin = newAdmin;
        return true;
    }
    function getBalance(address who, address token) internal view returns(uint) {
        uint a = who.balance;
        if (token != address(0)) a = ERC20(token).balanceOf(who);
        return a;
    }
    function wallet_lists() public view returns(address[]) {
        return _wallets;
    }
    function() public payable {}
    function payment() public payable returns(bool) {
        require(msg.value > 0);
        return true;
    }
    function create() public restrict returns(address) {
        require(_wallets.length < maximumWallet);
        address newWallet = address(new Vault());
        _wallets.push(newWallet);
        return newWallet;
    }
    function collectPayment(address token, uint start_ID, uint finish_ID) public restrict returns(uint) {
        require(start_ID >= 0 && start_ID <= finish_ID && finish_ID < _wallets.length);
        uint invalid = 0;
        uint a = start_ID;
        uint x;
        if (start_ID == finish_ID) {
            x = getBalance(_wallets[start_ID], token);
            if (x > 0) {
                if (!Wallet(_wallets[start_ID]).sendTo(address(this), token, x))
                invalid += 1;
            }
        } else {
            while (a < finish_ID) {
                x = getBalance(_wallets[a], token);
                if (x > 0) {
                    if (!Wallet(_wallets[a]).sendTo(address(this), token, x))
                    invalid += 1;
                }
                a++;
            }
        }
        return invalid;
    }
    function pay(address dest, address token, uint amount) public restrict returns(bool) {
        require(dest != address(0) && address(this) != dest);
        require(amount > 0 && amount <= getBalance(address(this), token));
        if (address(0) == token) {
            if (!dest.call.gas(250000).value(amount)())
            dest.transfer(amount);
        } else {
            if (!ERC20(token).transfer(dest, amount))
            revert();
        }
        return true;
    }
    function payFrom(address contractWallet, address dest, address token, uint amount) public restrict returns(bool) {
        require(exists(contractWallet) && !exists(dest));
        require(dest != address(0) && address(this) != dest);
        require(amount > 0 && amount <= getBalance(contractWallet, token));
        require(Wallet(contractWallet).sendTo(dest, token, amount));
        return true;
    }
}