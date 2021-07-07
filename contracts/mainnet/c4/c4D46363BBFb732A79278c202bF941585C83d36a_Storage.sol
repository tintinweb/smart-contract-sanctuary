pragma solidity 0.7.3;

contract Storage {

  address public governance;
  address public controller;
  address[] public underlyings;
  address public mainUnderlying;
  mapping (address => bool) public underlyingEnabled;
  mapping (address => address[]) public mainUnderlyingRoutes;
  address public usdc = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
  address public usdt = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
  address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
  address public routerAddress = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F; // sushi router

  constructor() public {
    governance = msg.sender;
    addUnderlying(usdc);
    addUnderlying(usdt);
    addUnderlying(dai);
    mainUnderlying = dai;
    mainUnderlyingRoutes[usdc] = [usdc, dai];
    mainUnderlyingRoutes[usdt] = [usdt, dai];
  }

  modifier onlyGovernance() {
    require(isGovernance(msg.sender), "Not governance");
    _;
  }

  function setGovernance(address _governance) public onlyGovernance {
    require(_governance != address(0), "new governance shouldn't be empty");
    governance = _governance;
  }

  function setController(address _controller) public onlyGovernance {
    require(_controller != address(0), "new controller shouldn't be empty");
    controller = _controller;
  }

  function isGovernance(address account) public view returns (bool) {
    return account == governance;
  }

  function isController(address account) public view returns (bool) {
    return account == controller;
  }

  function addUnderlying(address _underlying) public onlyGovernance {
    require(_underlying != address(0), "_underlying must be defined");
    underlyings.push(_underlying);
    underlyingEnabled[_underlying] = true;
  }

  function enableUnderlying(address _underlying) public onlyGovernance {
    require(_underlying != address(0), "_underlying must be defined");
    underlyingEnabled[_underlying] = true;
  }

  function disableUnderlying(address _underlying) public onlyGovernance {
    require(_underlying != address(0), "_underlying must be defined");
    underlyingEnabled[_underlying] = false;
  }

  function setMainUnderlyingRoute(address _underlying, address[] memory route) public onlyGovernance {
    require(_underlying != address(0), "_underlying must be defined");
    mainUnderlyingRoutes[_underlying] = route;
  }

  function setMainUnderlying(address _underlying) public onlyGovernance {
    require(_underlying != address(0), "_underlying must be defined");
    mainUnderlying = _underlying;
  }

  function setRouter(address _router) public onlyGovernance {
    require(_router != address(0), "_router must be defined");
    routerAddress = _router;
  }
}

{
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}