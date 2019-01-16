pragma solidity ^0.4.25;
contract ERC20 {
    function allowance(address tokenOwner, address tokenSpender) public view returns(uint256);
    function balanceOf(address who) public view returns(uint256);
    function approve(address tokenSpender, uint256 value) public returns(bool);
    function transfer(address to, uint256 value) public returns(bool);
    function transferFrom(address from, address to, uint256 value) public returns(bool);
}
contract Ownable {
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
contract MyTokenWallet is Ownable {
    address reference;
    constructor(address _owner, address _reference) public {
        owner = _owner;
        reference = _reference;
    }
    function() external payable {
        if (msg.value > 0)
        address(uint160(owner)).transfer(msg.value);
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
contract WalletFactory is Ownable {
    address contractReference;
    constructor(address _owner, address _contractReference) public {
        owner = _owner;
        contractReference = _contractReference;
    }
    function generate(address _owner) public returns(bool, address, address) {
        address x = address(new MyTokenWallet(_owner, contractReference));
        return (true, x, _owner);
    }
    function() external payable {
        require(msg.value > 0);
        owner.transfer(msg.value);
    }
}