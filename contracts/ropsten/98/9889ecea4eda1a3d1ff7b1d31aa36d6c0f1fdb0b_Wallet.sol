pragma solidity ^0.5.2;
contract ERC20 {
    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
}
contract Tools {
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}
contract Account is Tools {
    address owner;
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function changeOwner(address newOwner) public onlyOwner {
        require(newOwner != address(0) && address(this) != newOwner);
        owner = newOwner;
    }
    function balanceOf(address token) internal view returns(uint256) {
        if (address(0) == token) return address(this).balance;
        else return ERC20(token).balanceOf(address(this));
    }
    function () external payable {}
    function receive() public payable {
        require(msg.value > 0);
    }
    function transfer(address token, address payable to, uint256 amount) public onlyOwner {
        require(to != address(0) && address(this) != to);
        require(amount > 0 && amount <= balanceOf(token));
        if (address(0) == token) {
            if (isContract(to)) {
                (bool success,) = to.call.gas(250000).value(amount)("");
                if (!success) revert();
            } else {
                to.transfer(amount);
            }
        } else {
            if (!ERC20(token).transfer(to, amount))
            revert();
        }
    }
    function call(address to, uint256 amount, uint gaslimit, bytes memory data) public onlyOwner {
        require(isContract(to) && address(this) != to);
        require(amount <= address(this).balance);
        if (gaslimit < 50000) gaslimit = 50000;
        (bool success,) = to.call.gas(gaslimit).value(amount)(data);
        if (!success) revert();
    }
}
contract Wallet is Account {
    function generate() public payable returns(address) {
        address x = address(new HotWallet(msg.sender));
        if (msg.value > 0) address(uint160(x)).transfer(msg.value);
        return x;
    }
}
contract HotWallet is Account {
    constructor(address _owner) public {
        owner = _owner;
    }
}