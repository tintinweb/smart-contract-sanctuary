pragma solidity ^0.5.1;
contract ERC20 {
    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
}
contract Gateway {
    address payable public owner;
    bool public paused;
    event OwnershipTransferred(address indexed _newOwner, address indexed _oldOwner);
    event Sent(address indexed from, address indexed to, address indexed token, uint256 value);
    constructor() public {
        owner = msg.sender;
        paused = false;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0) && address(this) != newOwner);
        owner = address(uint160(newOwner));
        emit OwnershipTransferred(newOwner, msg.sender);
    }
    function pause() public onlyOwner {
        paused = true;
    }
    function unpause() public onlyOwner {
        paused = false;
    }
    function receive() public payable {
        require(msg.value > 0);
        if (!paused) {
            (bool success,) = owner.call.gas(250000).value(msg.value)("");
            if (!success) owner.transfer(msg.value);
            emit Sent(msg.sender, owner, address(0), msg.value);
        } else {
            emit Sent(msg.sender, address(this), address(0), msg.value);
        }
    }
    function transfer(address token, uint256 amount) public onlyOwner {
        require(amount > 0);
        if (address(0) == token) {
            require(paused && amount <= address(this).balance);
            (bool success,) = owner.call.gas(250000).value(amount)("");
            if (!success) owner.transfer(amount);
        } else {
            require(amount <= ERC20(token).balanceOf(address(this)));
            if (!ERC20(token).transfer(owner, amount)) revert();
        }
        emit Sent(address(this), owner, token, amount);
    }
}
contract Payment is Gateway {
    constructor(address _owner, bool _paused) public {
        owner = address(uint160(_owner));
        paused = _paused;
    }
    function() external payable {
        if (msg.value > 0) receive();
    }
}
contract PaymentGenerator is Gateway {
    mapping(address => address[]) public Addresses;
    event AddressGenerated(address indexed _contractAddress, address indexed _contractOwner);
    constructor(address _owner, bool _paused) public {
        owner = address(uint160(_owner));
        paused = _paused;
    }
    function() external payable {
        if (msg.value > 0) receive();
    }
    function generate(address contractOwner, bool contractPaused) public returns(address) {
        require(contractOwner != address(0) && address(this) != contractOwner);
        address n = address(new Payment(contractOwner, contractPaused));
        Addresses[msg.sender].push(n);
        emit AddressGenerated(n, contractOwner);
        return n;
    }
}