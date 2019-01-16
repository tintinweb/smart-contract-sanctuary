/**
 */
pragma solidity ^0.4.25;

contract Casino {
    mapping(address => bool) public authorized;
}
contract Token {
	function transferFrom(address sender, address receiver, uint amount) public returns(bool success);
	function transfer(address receiver, uint amount) public returns(bool success);
	function balanceOf(address holder) public view returns(uint);
}
 
contract AbstractSweeper {
    function sweep(address _token, uint _amount) public returns (bool);

    function () public { revert(); }

    EdgelessBank public controller;

    constructor(address _controller) public {
        controller = EdgelessBank(_controller);
    }

    modifier canSweep() {
        require(controller.isAuthorized(msg.sender) || msg.sender == controller.owner());
        require(!controller.halted());
        _;
    }
}

contract DefaultSweeper is AbstractSweeper {
    constructor(address _controller) AbstractSweeper(_controller) public {}

    function sweep(address _token, uint _amount) public canSweep returns (bool) {
        bool success = false;
        address destination = address(controller);

        if (_token != address(0)) {
            Token token = Token(_token);
            if (_amount > token.balanceOf(address(this))) {
                return false;
            }

            success = token.transfer(destination, _amount);
        } else {
            if (_amount > address(this).balance) {
                return false;
            }

            success = destination.send(_amount);
        }

        if (success) {
            controller.logSweep(address(this), destination, _token, _amount);
        }
        return success;
    }
}

contract UserWallet {
    AbstractSweeperList sweeperList;
    EdgelessBank controller;
    constructor(address _sweeperlist, address _controller) public {
        sweeperList = AbstractSweeperList(_sweeperlist);
        controller = EdgelessBank(_controller);
    }

    function () public payable {
        controller.logEthDeposit(msg.sender, address(this), msg.value);
    }

    function tokenFallback(address _from, uint _value, bytes _data) {
        (_from);
        (_value);
        (_data);
    }

    function sweep(address _token, uint _amount) public returns (bool) {
        (_amount);
        return sweeperList.sweeperOf(_token).delegatecall(msg.data);
    }
}

contract AbstractSweeperList {
    function sweeperOf(address _token) public returns (address);
    function logEthDeposit(address from, address to, uint amount) public;
}

contract EdgelessBank is AbstractSweeperList {
    Casino public casino;
    Token public token;
    address public owner;
    bool public halted;
    address public defaultSweeper = address(new DefaultSweeper(this));
    mapping (address => address) sweepers;

    event LogNewWallet(address receiver);
    event LogSweep(address from, address to, address token, uint amount);
    event LogEthDeposit(address from, address to, uint amount);

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAuthorized() {
        require(casino.authorized(msg.sender));
        _;
    }

    modifier onlyAdmins() {
        require(casino.authorized(msg.sender) || msg.sender == owner);
        _;
    }

    constructor(address _casino, address _token) public {
        owner = msg.sender;
        casino = Casino(_casino);
        token = Token(_token);
    }

    function changeOwner(address _owner) public onlyOwner {
        owner = _owner;
    }
    
    function setCasino(address _casino) public onlyOwner {
        casino = Casino(_casino);
    }

    function makeWallet() public onlyAdmins returns (address wallet)  {
        wallet = address(new UserWallet(this, this));
        emit LogNewWallet(wallet);
    }

    function halt() public onlyAdmins {
        halted = true;
    }

    function start() public onlyOwner {
        halted = false;
    }

    function addSweeper(address _token, address _sweeper) public onlyOwner {
        sweepers[_token] = _sweeper;
    }

    function sweeperOf(address _token) public returns (address) {
        address sweeper = sweepers[_token];
        if (sweeper == 0) sweeper = defaultSweeper;
        return sweeper;
    }

    function logSweep(address _from, address _to, address _token, uint _amount) public {
        emit LogSweep(_from, _to, _token, _amount);
    }
    
    function logEthDeposit(address from, address to, uint amount) public {
        emit LogEthDeposit(from, to, amount);
    }
    
    function isAuthorized(address _address) public view returns(bool) {
        return casino.authorized(_address);
    }
}