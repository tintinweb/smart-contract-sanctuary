pragma solidity ^0.4.25;
contract ERC20 {
    function balanceOf(address who) public view returns(uint);
    function transfer(address to, uint value) public returns(bool);
    event Transfer(address indexed _from, address indexed _to, uint _value);
}
contract WarmWallet {
    address public coldWallet;
    event WalletChanged(address indexed oldWallet, address indexed newWallet);
    event Sent(address indexed sender, address indexed receiver, address indexed token, uint amount);
    event BulkComplete(uint success, uint fail);
    constructor(address cold) public {
        coldWallet = cold;
        emit WalletChanged(address(0), cold);
    }
    modifier admin() {
        require(msg.sender == coldWallet);
        _;
    }
    function checkBalance(address token) internal view returns(uint) {
        if (token == address(0)) return address(this).balance;
        else return ERC20(token).balanceOf(address(this));
    }
    function checkAddress(address addr) internal view returns(bool) {
        if (addr != address(0) && address(this) != addr) return true;
        else return false;
    }
    function checkAmount(address token, uint amount) internal view returns(bool) {
        uint maxAmount = checkBalance(token);
        if (amount > 0 && amount <= maxAmount) return true;
        else return false;
    }
    function checkBool(bool[] z) internal pure returns(uint[] w) {
        uint x = 0;
        uint y = 0;
        while (x < z.length) {
            if (z[x]) y += 1;
            x++;
        }
        w[0] = z.length;
        w[1] = y;
        w[2] = z.length - y;
        return w;
    }
    function changeWallet(address newWallet) public admin returns(bool) {
        require(checkAddress(newWallet));
        coldWallet = newWallet;
        emit WalletChanged(msg.sender, newWallet);
        return true;
    }
    function () public payable {}
    function sendTo(address to, uint amount, address token) public admin returns(bool) {
        if (!checkAddress(to)) return false;
        if (!checkAmount(token, amount)) return false;
        if (token == address(0)) {
            to.transfer(amount);
        } else {
            if (!ERC20(token).transfer(to, amount)) return false;
        }
        emit Sent(address(this), to, token, amount);
        return true;
    }
    function multiSend(address[] dests, uint[] amounts, address[] tokens) public admin returns(bool[]) {
        require(dests.length == amounts.length && amounts.length == tokens.length);
        uint i = 0;
        bool[] memory o;
        uint[] memory n;
        while (i < dests.length) {
            if (!sendTo(dests[i], amounts[i], tokens[i])) o[i] = false;
            else o[i] = true;
            i++;
        }
        n = checkBool(o);
        emit BulkComplete(n[1], n[2]);
        return o;
    }
}