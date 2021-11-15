pragma solidity 0.5.16;


contract Storage {

    address public governance;
    address public controller;
    address public dev;

    constructor() public {
        governance = msg.sender;
        dev = msg.sender;
    }

    modifier onlyGovernance() {
        require(isGovernance(msg.sender) || isDev(msg.sender), "S0");
        _;
    }

    function setGovernance(address _governance) public onlyGovernance {
        require(_governance != address(0), "S1");
        governance = _governance;
    }

    function setController(address _controller) public onlyGovernance {
        require(_controller != address(0), "S2");
        controller = _controller;
    }

    function isGovernance(address account) public view returns (bool) {
        return account == governance;
    }

    function isController(address account) public view returns (bool) {
        return account == controller;
    }

    function isDev(address account) public view returns (bool) {
        return account == dev;
    }
}

