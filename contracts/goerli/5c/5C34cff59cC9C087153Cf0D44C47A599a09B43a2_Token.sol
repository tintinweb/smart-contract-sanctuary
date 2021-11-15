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

    function totalSupply() public view returns (uint) {
        return ledger.totalSupply();
    }

    function balanceOf(address _a) public view onlyToken returns (uint) {
        return Ledger(ledger).balanceOf(_a);
    }

    function allowance(address _owner, address _spender) public view onlyToken returns (uint) {
        return ledger.allowance(_owner, _spender);
    }

    function transfer(address _from, address _to, uint _value) public onlyToken returns (bool success) {
        return ledger.transfer(_from, _to, _value);
    }

    function transferFrom(address _spender, address _from, address _to, uint _value) public onlyToken returns (bool success) {
        return ledger.transferFrom(_spender, _from, _to, _value);
    }

    function approve(address _owner, address _spender, uint _value) public onlyToken returns (bool success) {
        return ledger.approve(_owner, _spender, _value);
    }

    function increaseApproval (address _owner, address _spender, uint _addedValue) public onlyToken returns (bool success) {
        return ledger.increaseApproval(_owner, _spender, _addedValue);
    }

    function decreaseApproval (address _owner, address _spender, uint _subtractedValue) public onlyToken returns (bool success) {
        return ledger.decreaseApproval(_owner, _spender, _subtractedValue);
    }

    function burn(address _owner, uint _amount) public onlyToken {
        ledger.burn(_owner, _amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

interface IToken {
    function transfer(address _to, uint _value) external returns (bool);
    function balanceOf(address owner) external returns(uint);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../library/Owned.sol";
import "../library/Finalizable.sol";

contract Ledger is Owned, Finalizable {
    address public controller;
    bool public mintingStopped;
    mapping(address => uint) public balanceOf;
    mapping (address => mapping (address => uint)) public allowance;
    uint public totalSupply;

    event LogMint(address indexed owner, uint amount);
    event LogMintingStopped();

    function setController(address _controller) public onlyOwner notFinalized {
        controller = _controller;
    }

    modifier onlyController() {
        require(msg.sender == controller);
        _;
    }

    function transfer(address _from, address _to, uint _value) public onlyController returns (bool success) {
        if (balanceOf[_from] < _value) return false;

        balanceOf[_from] = balanceOf[_from] - _value;
        balanceOf[_to] = balanceOf[_to] + _value;
        return true;
    }

    function transferFrom(address _spender, address _from, address _to, uint _value) public onlyController returns (bool success) {
        if (balanceOf[_from] < _value) return false;

        uint256 allowed = allowance[_from][_spender];
        if (allowed < _value) return false;

        balanceOf[_to] = balanceOf[_to] + _value;
        balanceOf[_from] = balanceOf[_from] - _value;
        allowance[_from][_spender] = allowed - _value;
        return true;
    }

    function approve(address _owner, address _spender, uint _value) public onlyController returns (bool success) {
        //require user to set to zero before resetting to nonzero
        if ((_value != 0) && (allowance[_owner][_spender] != 0)) {
            return false;
        }

        allowance[_owner][_spender] = _value;
        return true;
    }

    function increaseApproval (address _owner, address _spender, uint _addedValue) public onlyController returns (bool success) {
        uint oldValue = allowance[_owner][_spender];
        allowance[_owner][_spender] = oldValue + _addedValue;
        return true;
    }

    function decreaseApproval (address _owner, address _spender, uint _subtractedValue) public onlyController returns (bool success) {
        uint oldValue = allowance[_owner][_spender];
        if (_subtractedValue > oldValue) {
            allowance[_owner][_spender] = 0;
        } else {
            allowance[_owner][_spender] = oldValue - _subtractedValue;
        }
        return true;
    }  

    function mint(address _a, uint _amount) public onlyOwner mintingActive {
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

    function burn(address _owner, uint _amount) public onlyController {
        balanceOf[_owner] = balanceOf[_owner] - _amount;
        totalSupply = totalSupply - _amount;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Owned.sol";

contract Finalizable is Owned {
    bool public finalized;

    function finalize() public onlyOwner {
        finalized = true;
    }

    modifier notFinalized() {
        require(finalized);
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

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Owned.sol";
import "../interface/IToken.sol";

contract TokenReceivable is Owned {
    event logTokenTransfer(address token, address to, uint amount);

    function claimTokens(address _token, address _to) public onlyOwner returns (bool) {
        IToken token = IToken(_token);
        uint balance = token.balanceOf(address(this));
        if (token.transfer(_to, balance)) {
            emit logTokenTransfer(_token, _to, balance);
            return true;
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "../library/Finalizable.sol";
import "../library/TokenReceivable.sol";
import "../controller/Controller.sol";

contract EventDefinitions {
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract Token is Finalizable, TokenReceivable, EventDefinitions {

    string public name = "FunFair";
    uint8 public decimals = 8;
    string public symbol = "XFUN";
    string public motd;    

    Controller controller;
    address payable owner;
    address escrow; // reference to escrow contract for transaction and authorization

    event Motd(string message);

    modifier onlyController() {
        require(msg.sender == address(controller));
        _;
    }

    modifier onlyEscrow() {
        require(msg.sender == escrow);
        _;
    }

    function setController(address _c) external onlyOwner notFinalized {
        controller = Controller(_c);
    }


    function balanceOf(address a) public view returns (uint) {
        return controller.balanceOf(a);
    }

    function totalSupply() public view returns (uint) {
        return controller.totalSupply();
    }

    function allowance(address _owner, address _spender) public view returns (uint) {
        return controller.allowance(_owner, _spender);
    }

    function transfer(address _to, uint _value) public returns (bool success) {
       success = controller.transfer(msg.sender, _to, _value);
        if (success) {
            emit Transfer(msg.sender, _to, _value);
        }
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
       success = controller.transferFrom(msg.sender, _from, _to, _value);
        if (success) {
            emit Transfer(_from, _to, _value);
        }
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        //promote safe user behavior
        require(controller.allowance(msg.sender, _spender) == 0);

        success = controller.approve(msg.sender, _spender, _value);
        if (success) {
            emit Approval(msg.sender, _spender, _value);
        }
    }

    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        success = controller.increaseApproval(msg.sender, _spender, _addedValue);
        if (success) {
            uint newval = controller.allowance(msg.sender, _spender);
            emit Approval(msg.sender, _spender, newval);
        }
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        success = controller.decreaseApproval(msg.sender, _spender, _subtractedValue);
        if (success) {
            uint newval = controller.allowance(msg.sender, _spender);
            emit Approval(msg.sender, _spender, newval);
        }
    }

    function burn(uint _amount) public {
        controller.burn(msg.sender, _amount);
        emit Transfer(msg.sender, address(0x0), _amount);
    }

    function controllerTransfer(address _from, address _to, uint _value) external onlyController {
        emit Transfer(_from, _to, _value);
    }

    function controllerApprove(address _owner, address _spender, uint _value) external onlyController {
        emit Approval(_owner, _spender, _value);
    }

    // multi-approve, multi-transfer

    bool public multilocked;

    modifier notMultilocked {
        assert(!multilocked);
        _;
    }

    //do we want lock permanent? I think so.
    function lockMultis() public onlyOwner {
        multilocked = true;
    }
    
    function setMotd(string memory _m) public onlyOwner {
        motd = _m;
        emit Motd(_m);
    }
}

