contract AddVariable {
    bool private initialized;
    uint256 private value;

    modifier initializer(){
        require(initialized == false, "Required initialized = false");
        initialized = true;
        _;
    }

    function initialize(uint256 _name) public  initializer {
        value = _name;
    }

    function store(uint256 newValue) public {
        value = newValue;
    }

    function retrieve() public view returns (uint256) {
        return value;
    }

    function getInitialized() public view returns (bool) {
        return initialized;
    }
}

contract AddVariableV2 {
    bool private initialized;
    uint256 private value;
    uint256 private bonus;

    modifier initializer(){
        require(initialized == false, "Required initialized = false");
        initialized = true;
        _;
    }

    function initialize(uint256 _name) public  initializer {
        value = _name;
    }

    function store(uint256 newValue) public {
        value = newValue;
    }

    function retrieve() public view returns (uint256) {
        return value;
    }

    function getInitialized() public view returns (bool) {
        return initialized;
    }

    function setBonus(uint256 _bonus) public {
        bonus = _bonus;
    }

    function getBonus() public view returns (uint256) {
        return bonus;
    }

    function accumulate() public {
        value = value + bonus;
    }
}

{
  "optimizer": {
    "enabled": true,
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