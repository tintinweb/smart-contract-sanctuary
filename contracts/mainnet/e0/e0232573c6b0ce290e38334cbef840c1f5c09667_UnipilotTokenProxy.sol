// SPDX-License-Identifier: MIT
pragma solidity >=0.7.6;

interface IERC20 {
    function mint(address to, uint256 value) external;
}



interface IUnipilotTokenProxy {
    event TimelockUpdated(address previousTimelock, address newTimelock);
    event MinterUpdated(address minter, bool status);

    function updateTimelock(address _timelock) external;

    function updateMinter(address _minter) external;

    function mint(address _to, uint256 _value) external;
}


contract UnipilotTokenProxy is IUnipilotTokenProxy {
    IERC20 private constant UNIPILOT = IERC20(0x37C997B35C619C21323F3518B9357914E8B99525);

    address public timelock;

    modifier onlyMinter() {
        require(minter[msg.sender], "PILOT_TOKEN_PROXY:: NOT_MINTER");
        _;
    }

    modifier onlyTimelock() {
        require(msg.sender == timelock, "PILOT_TOKEN_PROXY:: NOT_TIMELOCK");
        _;
    }

    mapping(address => bool) public minter;

    constructor(address _timelock) {
        timelock = _timelock;
    }

    function updateTimelock(address _timelock) external override onlyTimelock {
        emit TimelockUpdated(timelock, timelock = _timelock);
    }

    function updateMinter(address _minter) external override onlyTimelock {
        bool status = !minter[_minter];
        minter[_minter] = status;
        emit MinterUpdated(_minter, status);
    }

    function mint(address _to, uint256 _value) external override onlyMinter {
        UNIPILOT.mint(_to, _value);
    }
}