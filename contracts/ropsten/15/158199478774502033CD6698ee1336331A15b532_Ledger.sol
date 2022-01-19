// SPDX-License-Identifier: MIT
pragma solidity =0.4.11;

import "../library/Finalizable.sol";
import "../library/TokenReceivable.sol";
import "../library/SafeMath.sol";
import "../controller/Controller.sol";
import "../library/IToken.sol";

contract EventDefinitions {
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}

contract Token is IToken, Finalizable, TokenReceivable, SafeMath, EventDefinitions {

  string public name = "FunFair";
  uint8 public decimals = 8;
  string public symbol = "FUN";

  Controller controller;
  address owner;

  modifier onlyController() {
    assert(msg.sender == address(controller));
    _;
  }

  function setController(address _c) onlyOwner notFinalized {
    controller = Controller(_c);
  }

  function balanceOf(address owner) constant returns (uint256) {
    return controller.balanceOf(owner);
  }

  function totalSupply() constant returns (uint) {
    return controller.totalSupply();
  }

  function allowance(address _owner, address _spender) constant returns (uint) {
    return controller.allowance(_owner, _spender);
  }

  function transfer(address _to, uint256 _value)  returns (bool) {
    require(controller.transfer(msg.sender, _to, _value));
    Transfer(msg.sender, _to, _value);
    return true;
  }

  function transferFrom(address _from, address _to, uint _value) returns (bool success) {
    require(controller.transferFrom(msg.sender, _from, _to, _value));
    Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint _value)
  onlyPayloadSize(2)
  returns (bool success) {
    //promote safe user behavior
    if (controller.allowance(msg.sender, _spender) > 0) throw;

    success = controller.approve(msg.sender, _spender, _value);
    if (success) {
      Approval(msg.sender, _spender, _value);
    }
  }

  function increaseApproval(address _spender, uint _addedValue)
  onlyPayloadSize(2)
  returns (bool success) {
    success = controller.increaseApproval(msg.sender, _spender, _addedValue);
    if (success) {
      uint newval = controller.allowance(msg.sender, _spender);
      Approval(msg.sender, _spender, newval);
    }
  }

  function decreaseApproval(address _spender, uint _subtractedValue)
  onlyPayloadSize(2)
  returns (bool success) {
    success = controller.decreaseApproval(msg.sender, _spender, _subtractedValue);
    if (success) {
      uint newval = controller.allowance(msg.sender, _spender);
      Approval(msg.sender, _spender, newval);
    }
  }

  modifier onlyPayloadSize(uint numwords) {
    assert(msg.data.length >= numwords * 32 + 4);
    _;
  }

  function burn(uint _amount) {
    controller.burn(msg.sender, _amount);
    Transfer(msg.sender, 0x0, _amount);
  }

  function controllerTransfer(address _from, address _to, uint _value)
  onlyController {
    Transfer(_from, _to, _value);
  }

  function controllerApprove(address _owner, address _spender, uint _value)
  onlyController {
    Approval(_owner, _spender, _value);
  }

  // multi-approve, multi-transfer

  bool public multilocked;

  modifier notMultilocked {
    assert(!multilocked);
    _;
  }

  //do we want lock permanent? I think so.
  function lockMultis() onlyOwner {
    multilocked = true;
  }

  // multi functions just issue events, to fix initial event history

  function multiTransfer(uint[] bits) onlyOwner notMultilocked {
    if (bits.length % 3 != 0) throw;
    for (uint i = 0; i < bits.length; i += 3) {
      address from = address(bits[i]);
      address to = address(bits[i + 1]);
      uint amount = bits[i + 2];
      Transfer(from, to, amount);
    }
  }

  function multiApprove(uint[] bits) onlyOwner notMultilocked {
    if (bits.length % 3 != 0) throw;
    for (uint i = 0; i < bits.length; i += 3) {
      address owner = address(bits[i]);
      address spender = address(bits[i + 1]);
      uint amount = bits[i + 2];
      Approval(owner, spender, amount);
    }
  }

  string public motd;

  event Motd(string message);

  function setMotd(string _m) onlyOwner {
    motd = _m;
    Motd(_m);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.4.11;

interface IToken {
  function transfer(address _to, uint256 _value) returns (bool);
  function balanceOf(address owner) constant returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.4.11;

import "../library/Owned.sol";
import "../library/Finalizable.sol";
import "../ledger/Ledger.sol";

contract Controller is Owned, Finalizable {
    Ledger public ledger;
    address public token;

    function setToken(address _token) onlyOwner notFinalized {
        token = _token;
    }

    function setLedger(address _ledger) onlyOwner notFinalized {
        ledger = Ledger(_ledger);
    }

    modifier onlyToken() {
        if (msg.sender != token) throw;
        _;
    }

    function totalSupply() constant returns (uint) {
        return ledger.totalSupply();
    }

    function balanceOf(address _a) onlyToken constant returns (uint) {
        return Ledger(ledger).balanceOf(_a);
    }

    function allowance(address _owner, address _spender)
    onlyToken constant returns (uint) {
        return ledger.allowance(_owner, _spender);
    }

    function transfer(address _from, address _to, uint _value)
    onlyToken
    returns (bool success) {
        return ledger.transfer(_from, _to, _value);
    }

    function transferFrom(address _spender, address _from, address _to, uint _value)
    onlyToken
    returns (bool success) {
        return ledger.transferFrom(_spender, _from, _to, _value);
    }

    function approve(address _owner, address _spender, uint _value)
    onlyToken
    returns (bool success) {
        return ledger.approve(_owner, _spender, _value);
    }

    function increaseApproval (address _owner, address _spender, uint _addedValue)
    onlyToken
    returns (bool success) {
        return ledger.increaseApproval(_owner, _spender, _addedValue);
    }

    function decreaseApproval (address _owner, address _spender, uint _subtractedValue)
    onlyToken
    returns (bool success) {
        return ledger.decreaseApproval(_owner, _spender, _subtractedValue);
    }


    function burn(address _owner, uint _amount) onlyToken {
        ledger.burn(_owner, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.4.11;

contract SafeMath {
    function safeMul(uint a, uint b) internal returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function assert(bool assertion) internal {
        if (!assertion) throw;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.4.11;

import "./Owned.sol";
import "./IToken.sol";

contract TokenReceivable is Owned {
  event logTokenTransfer(address token, address to, uint amount);

  function claimTokens(address _token, address _to) onlyOwner returns (bool) {
    IToken token = IToken(_token);
    uint balance = token.balanceOf(this);
    if (token.transfer(_to, balance)) {
      logTokenTransfer(_token, _to, balance);
      return true;
    }
    return false;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.4.11;

import "./Owned.sol";

contract Finalizable is Owned {
  bool public finalized;

  modifier notFinalized() {
    require(!finalized);
    _;
  }

  function Finalizable() {
    finalized = false;
  }

  function finalize() public onlyOwner {
    finalized = true;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity =0.4.11;

contract Owned {
  address private owner;
  address private newOwner;

  modifier onlyOwner() {
    require(owner == msg.sender);
    _;
  }

  function Owned() {
    owner = msg.sender;
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

// SPDX-License-Identifier: MIT
pragma solidity =0.4.11;

import "../library/Owned.sol";
import "../library/Finalizable.sol";
import "../library/SafeMath.sol";

contract Ledger is Owned, SafeMath, Finalizable {
    address public controller;
    mapping(address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    uint public totalSupply;

    function setController(address _controller) onlyOwner notFinalized {
        controller = _controller;
    }

    modifier onlyController() {
        if (msg.sender != controller) throw;
        _;
    }

    function transfer(address _from, address _to, uint _value)
    onlyController
    returns (bool success) {
        if (balanceOf[_from] < _value) return false;

        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        return true;
    }

    function transferFrom(address _spender, address _from, address _to, uint _value)
    onlyController
    returns (bool success) {
        if (balanceOf[_from] < _value) return false;

        var allowed = allowance[_from][_spender];
        if (allowed < _value) return false;

        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        allowance[_from][_spender] = safeSub(allowed, _value);
        return true;
    }

    function approve(address _owner, address _spender, uint _value)
    onlyController
    returns (bool success) {
        //require user to set to zero before resetting to nonzero
        if ((_value != 0) && (allowance[_owner][_spender] != 0)) {
            return false;
        }

        allowance[_owner][_spender] = _value;
        return true;
    }

    function increaseApproval (address _owner, address _spender, uint _addedValue)
    onlyController
    returns (bool success) {
        uint oldValue = allowance[_owner][_spender];
        allowance[_owner][_spender] = safeAdd(oldValue, _addedValue);
        return true;
    }

    function decreaseApproval (address _owner, address _spender, uint _subtractedValue)
    onlyController
    returns (bool success) {
        uint oldValue = allowance[_owner][_spender];
        if (_subtractedValue > oldValue) {
            allowance[_owner][_spender] = 0;
        } else {
            allowance[_owner][_spender] = safeSub(oldValue, _subtractedValue);
        }
        return true;
    }

    event LogMint(address indexed owner, uint amount);
    event LogMintingStopped();

    function mint(address _a, uint _amount) onlyOwner mintingActive {
        balanceOf[_a] += _amount;
        totalSupply += _amount;
        LogMint(_a, _amount);
    }

    function multiMint(uint[] bits) onlyOwner mintingActive {
        for (uint i=0; i<bits.length; i++) {
            address a = address(bits[i]>>96);
            uint amount = bits[i]&((1<<96) - 1);
            mint(a, amount);
        }
    }

    bool public mintingStopped;

    function stopMinting() onlyOwner {
        mintingStopped = true;
        LogMintingStopped();
    }

    modifier mintingActive() {
        if (mintingStopped) throw;
        _;
    }

    function burn(address _owner, uint _amount) onlyController {
        balanceOf[_owner] = safeSub(balanceOf[_owner], _amount);
        totalSupply = safeSub(totalSupply, _amount);
    }
}