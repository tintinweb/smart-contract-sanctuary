pragma solidity ^0.4.24;
import "./Default-erc20interface.sol";
import "./Default-safemath.sol";

contract Sender is SafeMath {

    Controller controller;

    modifier canWithdraw() {
        require(msg.sender == controller.owner());
        _;
    }

    constructor(address _controller) public {
        controller = Controller(_controller);
    }

    function withdraw(address _token, address _to, uint _amount, uint _fee, address _bank) canWithdraw public returns (bool) {

        ERC20Interface token = ERC20Interface(_token);

        require(safeAdd(_amount, _fee) <= token.balanceOf(this));

        bool result = token.transfer(_to, _amount);
        require(result == true);

        result = token.transfer(_bank, _fee);
        require(result == true);

        controller.logWithdraw(this, _to, _token, _amount, _fee);

        return true;
    }
}

contract UserWallet {

    AbstractController controller;

    constructor(address _controller) public {
        controller = AbstractController(_controller);
    }

    function withdraw(address _token, address _to, uint _amount, uint _fee, address _bank) public returns (bool) {
        (_token);
        (_to);
        (_amount);
        (_fee);
        (_bank);

        return controller.getSender().delegatecall(msg.data);
    }
}

contract AbstractController {
    function getSender() public returns (address);
}

contract Controller is AbstractController {
    address public owner;
    address sender;

    event LogNewWallet(uint indexed id, address indexed receiver);
    event LogWithdraw(address indexed from, address indexed to, address indexed token, uint amount, uint fee);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
        sender = address(new Sender(this));
    }

    function makeWallet(uint _id) onlyOwner public returns (address wallet)  {
        wallet = address(new UserWallet(this));
        emit LogNewWallet(_id, wallet);
    }

    function getSender() public returns (address) {
        return sender;
    }

    function logWithdraw(address _from, address _to, address _token, uint _amount, uint _fee) public {
        emit LogWithdraw(_from, _to, _token, _amount, _fee);
    }
}