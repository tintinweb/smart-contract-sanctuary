// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

interface IController {
    function harvestStrategy(address _strategy) external;
}

interface IStrategy {
    function harvest() external;
}

contract yAxisMetaVaultStrategists {
    address public governance;

    IController public controller;
    IStrategy public strategy;

    mapping(address => bool) public isStrategist;

    constructor() public {
        governance = msg.sender;
        isStrategist[governance] = true;
    }

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!governance");
        governance = _governance;
    }

    function addStrategist(address _strategist) public {
        require(msg.sender == governance, "!governance");
        isStrategist[_strategist] = true;
    }

    function removeStrategist(address _strategist) public {
        require(msg.sender == governance, "!governance");
        isStrategist[_strategist] = false;
    }

    function setController(IController _controller) external {
        require(msg.sender == governance, "!governance");
        controller = _controller;
    }

    function setStrategy(IStrategy _strategy) external {
        require(msg.sender == governance, "!governance");
        strategy = _strategy;
    }

    function harvestDefaultController() external {
        harvestController(controller, address(strategy));
    }

    function harvestController(IController _controller, address _strategy) public {
        require(isStrategist[msg.sender], "!strategist");
        _controller.harvestStrategy(_strategy);
    }

    function harvestDefaultStrategy() external {
        harvestStrategy(strategy);
    }

    function harvestStrategy(IStrategy _strategy) public {
        require(isStrategist[msg.sender], "!strategist");
        _strategy.harvest();
    }
}