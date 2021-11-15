pragma solidity 0.5.16;

import "./Governable.sol";

contract Controllable is Governable {
    constructor(address _storage) public Governable(_storage) {}

    modifier onlyController() {
        require(store.isController(msg.sender), "Not a controller");
        _;
    }

    modifier onlyControllerOrGovernance() {
        require(
            (store.isController(msg.sender) || store.isGovernance(msg.sender)),
            "The caller must be controller or governance"
        );
        _;
    }

    function controller() public view returns (address) {
        return store.controller();
    }
}

pragma solidity 0.5.16;

import "./Storage.sol";

contract Governable {
    Storage public store;

    constructor(address _store) public {
        require(_store != address(0), "new storage shouldn't be empty");
        store = Storage(_store);
    }

    modifier onlyGovernance() {
        require(store.isGovernance(msg.sender), "Not governance");
        _;
    }

    function setStorage(address _store) public onlyGovernance {
        require(_store != address(0), "new storage shouldn't be empty");
        store = Storage(_store);
    }

    function governance() public view returns (address) {
        return store.governance();
    }
}

pragma solidity 0.5.16;

contract Storage {
    address public governance;
    address public controller;

    constructor() public {
        governance = msg.sender;
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
}

