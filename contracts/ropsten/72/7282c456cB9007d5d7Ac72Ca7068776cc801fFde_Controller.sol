// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../library/Owned.sol";
import "../library/Finalizable.sol";
import "../ledger/Ledger.sol";

contract Controller is Owned, Finalizable {
    Ledger public ledger;
    address public token;

    function setToken(address _token) public onlyOwner {
        token = _token;
    }

    function setLedger(address _ledger) public onlyOwner {
        ledger = Ledger(_ledger);
    }

    modifier onlyToken() {
        require(msg.sender == token);
        _;
    }

    function totalSupply() public view returns (uint256) {
        return ledger.totalSupply();
    }

    function balanceOf(address _a) public view onlyToken returns (uint256) {
        return Ledger(ledger).balanceOf(_a);
    }

    function allowance(address _owner, address _spender)
        public
        view
        onlyToken
        returns (uint256)
    {
        return ledger.allowance(_owner, _spender);
    }

    function transfer(
        address _from,
        address _to,
        uint256 _value
    ) public onlyToken returns (bool success) {
        return ledger.transfer(_from, _to, _value);
    }

    function transferFrom(
        address _spender,
        address _from,
        address _to,
        uint256 _value
    ) public onlyToken returns (bool success) {
        return ledger.transferFrom(_spender, _from, _to, _value);
    }

    function approve(
        address _owner,
        address _spender,
        uint256 _value
    ) public onlyToken returns (bool success) {
        return ledger.approve(_owner, _spender, _value);
    }

    function increaseApproval(
        address _owner,
        address _spender,
        uint256 _addedValue
    ) public onlyToken returns (bool success) {
        return ledger.increaseApproval(_owner, _spender, _addedValue);
    }

    function decreaseApproval(
        address _owner,
        address _spender,
        uint256 _subtractedValue
    ) public onlyToken returns (bool success) {
        return ledger.decreaseApproval(_owner, _spender, _subtractedValue);
    }

    function burn(address _owner, uint256 _amount) public onlyToken {
        ledger.burn(_owner, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../library/Owned.sol";
import "../library/Finalizable.sol";

contract Ledger is Owned, Finalizable {
    address public controller;
    bool public mintingStopped;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    uint256 public totalSupply;

    event LogMint(address indexed owner, uint256 amount);
    event LogMintingStopped();

    function setController(address _controller) public onlyOwner notFinalized {
        controller = _controller;
    }

    modifier onlyController() {
        require(msg.sender == controller);
        _;
    }

    function transfer(
        address _from,
        address _to,
        uint256 _value
    ) public onlyController returns (bool success) {
        if (balanceOf[_from] < _value) return false;

        balanceOf[_from] = balanceOf[_from] - _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        return true;
    }

    function transferFrom(
        address _spender,
        address _from,
        address _to,
        uint256 _value
    ) public onlyController returns (bool success) {
        if (balanceOf[_from] < _value) return false;

        uint256 allowed = allowance[_from][_spender];
        if (allowed < _value) return false;

        balanceOf[_to] = balanceOf[_to] + _value;
        balanceOf[_from] = balanceOf[_from] - _value;
        allowance[_from][_spender] = allowed - _value;
        return true;
    }

    function approve(
        address _owner,
        address _spender,
        uint256 _value
    ) public onlyController returns (bool success) {
        //require user to set to zero before resetting to nonzero
        if ((_value != 0) && (allowance[_owner][_spender] != 0)) {
            return false;
        }

        allowance[_owner][_spender] = _value;
        return true;
    }

    function increaseApproval(
        address _owner,
        address _spender,
        uint256 _addedValue
    ) public onlyController returns (bool success) {
        uint256 oldValue = allowance[_owner][_spender];
        allowance[_owner][_spender] = oldValue + _addedValue;
        return true;
    }

    function decreaseApproval(
        address _owner,
        address _spender,
        uint256 _subtractedValue
    ) public onlyController returns (bool success) {
        uint256 oldValue = allowance[_owner][_spender];
        if (_subtractedValue > oldValue) {
            allowance[_owner][_spender] = 0;
        } else {
            allowance[_owner][_spender] = oldValue - _subtractedValue;
        }
        return true;
    }

    function mint(address _a, uint256 _amount) public onlyOwner mintingActive {
        balanceOf[_a] += _amount;
        totalSupply += _amount;
        emit LogMint(_a, _amount);
    }

    function stopMinting() public onlyOwner {
        mintingStopped = true;
        emit LogMintingStopped();
    }

    modifier mintingActive() {
        require(!mintingStopped);
        _;
    }

    function burn(address _owner, uint256 _amount) public onlyController {
        balanceOf[_owner] = balanceOf[_owner] - _amount;
        totalSupply = totalSupply - _amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Owned.sol";

contract Finalizable is Owned {
    bool public finalized;

    constructor() {
        finalized = false;
    }

    function finalize() public onlyOwner {
        finalized = true;
    }

    modifier notFinalized() {
        require(!finalized,"Finalized yet");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

contract Owned {
    constructor() {
        owner = msg.sender;
    }

    address private owner;
    address private newOwner;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function changeOwner(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

{
  "remappings": [],
  "optimizer": {
    "enabled": false,
    "runs": 200
  },
  "evmVersion": "berlin",
  "libraries": {},
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  }
}