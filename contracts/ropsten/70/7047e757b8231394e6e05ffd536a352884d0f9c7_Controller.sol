pragma solidity ^0.4.24;
import "./ERC20Interface.sol";
import "./SafeMath.sol";

contract Sender is SafeMath {

    Controller controller;

    modifier canWithdraw() {
        require(msg.sender == controller.owner());
        _;
    }

    constructor(address _controller) public {
        controller = Controller(_controller);
    }

    function withdraw(address _token, address _to, uint _amount) canWithdraw public returns (bool) {

        controller.logWithdraw(this, _to, _token, _amount);

        return true;
    }
}

contract UserWallet {

    AbstractController controller;

    constructor(address _controller) public {
        controller = AbstractController(_controller);
    }

    function withdraw(address _token, address _to, uint _amount) external returns (bool) {
        (_token);
        (_to);
        (_amount);

        return controller.getSender().delegatecall(msg.data);
    }
}

contract AbstractController {
    function getSender() external returns (address);
}

contract Controller is AbstractController {
    address public owner;
    address sender;

    event LogWallet(address indexed receiver);
    event LogWithdraw(address indexed from, address indexed to, address indexed token, uint amount);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
        sender = address(new Sender(this));
    }

    function makeWallet() onlyOwner external returns (address wallet)  {
        wallet = address(new UserWallet(this));
        emit LogWallet(wallet);
    }

    function getSender() external returns (address) {
        return sender;
    }

    function logWithdraw(address _from, address _to, address _token, uint _amount) external {
        emit LogWithdraw(_from, _to, _token, _amount);
    }
}