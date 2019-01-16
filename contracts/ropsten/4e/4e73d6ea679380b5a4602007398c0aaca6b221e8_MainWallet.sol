pragma solidity ^0.5.2;
contract Wallet {
    address owner;
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function changeOwner(address newOwner) public onlyOwner returns(bool) {
        require(newOwner != address(0) && address(this) != newOwner);
        owner = newOwner;
    }
    function () external payable {}
    function receive() public payable returns(bool) {
        require(msg.value > 0);
    }
    function transfer(address token, address dest, uint256 amount) public onlyOwner returns(bool) {
        require(dest != address(0) && address(this) != dest);
        require(amount > 0);
        if (address(0) == token) {
            require(amount <= address(this).balance);
            address(uint160(dest)).transfer(amount);
        } else {
            require(amount <= ERC20(token).balanceOf(address(this)));
            if (!ERC20(token).transfer(dest, amount)) revert();
        }
    }
    function call(address contractAddr, uint256 amount, uint gaslimit, bytes memory data) public onlyOwner returns(bool) {
        require(contractAddr != address(0) && address(this) != contractAddr);
        require(amount <= address(this).balance);
        if (gaslimit < 50000) gaslimit = 50000;
        bool success;
        if (amount > 0) {
            (success,) = address(uint160(contractAddr)).call.gas(gaslimit).value(amount)(data);
        } else {
            (success,) = contractAddr.call.gas(gaslimit).value(amount)(data);
        }
        if (!success) revert();
    }
    function send(address[] memory tokens, address[] memory dests, uint256[] memory amounts) public onlyOwner returns(uint) {
        require(tokens.length == dests.length && dests.length == amounts.length);
        require(dests.length < 256);
        uint i;
        uint o = tokens.length;
        while (i < dests.length) {
            if (!transfer(tokens[i], dests[i], amounts[i])) o -= 1;
            i++;
        }
        return o;
    }
}
contract ERC20 {
    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
}
contract SubWallet is Wallet {
    constructor(address _owner) public {
        owner = _owner;
    }
}
contract MainWallet is Wallet {
    constructor(address _owner) public {
        owner = _owner;
    }
    function fork() public payable {
        address x = address(new SubWallet(msg.sender));
        if (msg.value > 0) address(uint160(x)).transfer(msg.value);
    }
}