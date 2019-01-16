pragma solidity ^0.5.0;
contract ERC20 {
    function allowance(address tokenOwner, address tokenSpender) public view returns(uint256);
    function balanceOf(address who) public view returns(uint256);
    function approve(address tokenSpender, uint256 value) public returns(bool);
    function transfer(address to, uint256 value) public returns(bool);
    function transferFrom(address from, address to, uint256 value) public returns(bool);
}
contract Ownable {
    address public owner;
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
contract Wallet is Ownable {
    constructor(address _owner) public {
        owner = _owner;
    }
    function sum(uint256[] memory a) internal pure returns(uint256) {
        uint b = 0;
        uint c = 0;
        while (b < a.length) {
            c += a[b];
            b++;
        }
        return c;
    }
    function() external payable {}
    function receive() public payable returns(bool) {
        require(msg.value > 0);
        return true;
    }
    function send(address to, uint256 amount, uint256 gaslimit, bytes memory data) public onlyOwner returns(bool) {
        require(to != address(0) && address(this) != to);
        require(amount > 0 && amount <= address(this).balance);
        if (gaslimit < 25000 && gaslimit > 4700000) gaslimit = 250000;
        address payable dest = address(uint160(to));
        (bool success,) = dest.call.gas(gaslimit).value(amount)(data);
        if (!success) dest.transfer(amount);
        return true;
    }
    function approve(address token, address spender, uint256 amount) public onlyOwner returns(bool) {
        require(token != address(0) && spender != address(0) && address(this) != spender);
        require(amount > 0 && amount <= ERC20(token).balanceOf(address(this)));
        if (!ERC20(token).approve(spender, amount)) revert();
        return true;
    }
    function transfer(address token, address to, uint256 amount) public onlyOwner returns(bool) {
        require(token != address(0) && address(0) != to && address(this) != to);
        require(amount > 0 && amount <= ERC20(token).balanceOf(address(this)));
        if (!ERC20(token).transfer(to, amount)) revert();
        return true;
    }
    function transferFrom(address token, address from, address to, uint256 amount) public onlyOwner returns(bool) {
        require(token != address(0) && address(0) != to);
        require(from != address(0) && address(this) != from);
        require(amount > 0 && amount <= ERC20(token).allowance(from, address(this)));
        if (!ERC20(token).transferFrom(from, to, amount)) revert();
        return true;
    }
}
contract Factory is Ownable {
    constructor() public {
        owner = msg.sender;
    }
    function create() public returns(address) {
        return address(new Wallet(msg.sender));
    }
    function() external payable {
        require(msg.value == 0);
        create();
    }
}