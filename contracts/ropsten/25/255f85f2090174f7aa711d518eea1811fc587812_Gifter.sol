pragma solidity ^0.5.1;
contract ERC20 {
    function balanceOf(address who) public view returns(uint256);
    function transfer(address to, uint256 value) public returns(bool);
}
contract Gifter {
    struct Details {
        address recipient;
        address token;
        uint256 value;
        bool claimed;
    }
    address public owner;
    mapping(bytes32 => Details) public gifts;
    event Gift(address indexed _recipient, bytes32 indexed _hash);
    event Claim(address indexed _recipient, address indexed _token, bytes32 indexed _hash);
    constructor() public {
        owner = msg.sender;
    }
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    modifier onlyRecipient(bytes32 _hash) {
        require(msg.sender == gifts[_hash].recipient);
        _;
    }
    function changeOwner(address _owner) public onlyOwner {
        require(_owner != address(0) && address(this) != _owner);
        owner = _owner;
    }
    function balanceOf(address _token) internal view returns(uint256) {
        if (address(0) == _token) return address(this).balance;
        else return ERC20(_token).balanceOf(address(this));
    }
    function () external payable {}
    function donation() public payable {
        require(msg.value > 0);
    }
    function gift(address _token, address _recipient, uint256 _amount) public onlyOwner {
        require(_recipient != address(0) && address(this) != _recipient);
        require(_amount > 0 && _amount <= balanceOf(_token));
        bytes32 data = keccak256(abi.encodeWithSignature("gift(address,address,uint256,uint256)", _token, _recipient, _amount, now));
        gifts[data].recipient = _recipient;
        gifts[data].token = _token;
        gifts[data].value = _amount;
        emit Gift(_recipient, data);
    }
    function claim(bytes32 _hash) public onlyRecipient(_hash) {
        Details memory data = gifts[_hash];
        require(!data.claimed);
        if (data.token == address(0)) {
            (bool success,) = msg.sender.call.gas(100000).value(data.value)("");
            if (!success) msg.sender.transfer(data.value);
        } else {
            if (!ERC20(data.token).transfer(msg.sender, data.value))
            revert();
        }
        gifts[_hash].claimed = true;
        emit Claim(msg.sender, data.token, _hash);
    }
    function externalGiftEth(address _recipient) public payable {
        require(_recipient != address(0) && address(this) != _recipient);
        require(msg.value >= 5 finney);
        bytes32 data = keccak256(abi.encodeWithSignature("gift(address,address,uint256,uint256)", address(0), _recipient, msg.value, now));
        gifts[data].recipient = _recipient;
        gifts[data].token = address(0);
        gifts[data].value = msg.value;
        emit Gift(_recipient, data);
    }
}