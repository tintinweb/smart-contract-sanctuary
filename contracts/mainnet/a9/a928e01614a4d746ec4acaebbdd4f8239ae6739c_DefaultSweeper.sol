/**
 *Submitted for verification at Etherscan.io on 2021-02-27
*/

pragma solidity ^0.4.24;

contract AbstractSweeper {
    function sweepAll(address token) public returns (bool);

    function() public { revert(); }

    Controller controller;

    constructor(address _controller) public {
        controller = Controller(_controller);
    }

    modifier canSweep() {
        if(msg.sender != controller.authorizedCaller() && msg.sender != controller.owner()){ revert(); }
        if(controller.halted()){ revert(); }
        _;
    }
}

contract Token {
    function balanceOf(address a) public pure returns (uint) {
        (a);
        return 0;
    }

    function transfer(address a, uint val) public pure returns (bool) {
        (a);
        (val);
        return false;
    }
}

contract DefaultSweeper is AbstractSweeper {
    constructor(address controller) AbstractSweeper(controller) public { }

    function sweepAll(address _token) public canSweep returns (bool) {
        bool success = false;
        address destination = controller.destination();

        if(_token != address(0)){
            Token token = Token(_token);
            success = token.transfer(destination, token.balanceOf(this));
        }else{
            success = destination.send(address(this).balance);
        }
        return success;
    }
}

contract UserWallet {
    AbstractSweeperList sweeperList;
    constructor(address _sweeperlist) public {
        sweeperList = AbstractSweeperList(_sweeperlist);
    }

    function() public payable { }

    function tokenFallback(address _from, uint _value, bytes _data) public pure {
        (_from);
        (_value);
        (_data);
    }

    function sweepAll(address _token) public returns (bool) {
        return sweeperList.sweeperOf(_token).delegatecall(msg.data);
    }
}

contract AbstractSweeperList {
    function sweeperOf(address _token) public returns (address);
}

contract Controller is AbstractSweeperList {
    address public owner;
    address public authorizedCaller;

    address public destination;

    bool public halted;

    event NewWalletCreated(address receiver);

    modifier onlyOwner() {
        if(msg.sender != owner){ revert(); }
        _;
    }

    modifier onlyAuthorizedCaller() {
        if(msg.sender != authorizedCaller){ revert(); }
        _;
    }

    modifier onlyAdmins() {
        if(msg.sender != authorizedCaller && msg.sender != owner){ revert(); } 
        _;
    }

    constructor() public {
        owner = msg.sender;
        destination = msg.sender;
        authorizedCaller = msg.sender;
    }

    function setAuthorizedCaller(address _newCaller) public onlyOwner {
        authorizedCaller = _newCaller;
    }

    function setDestination(address _dest) public onlyOwner {
        destination = _dest;
    }

    function setOwner(address _owner) public onlyOwner {
        owner = _owner;
    }

    function newWallet() public onlyAdmins returns (address wallet)  {
        wallet = address(new UserWallet(this));
        emit NewWalletCreated(wallet);
    }

    function halt() public onlyAdmins {
        halted = true;
    }

    function start() public onlyOwner {
        halted = false;
    }

    address public defaultSweeper = address(new DefaultSweeper(this));
    mapping (address => address) sweepers;

    function addSweeper(address _token, address _sweeper) public onlyOwner {
        sweepers[_token] = _sweeper;
    }

    function sweeperOf(address _token) public returns (address) {
        address sweeper = sweepers[_token];
        if(sweeper == 0){ sweeper = defaultSweeper; }
        return sweeper;
    }
}