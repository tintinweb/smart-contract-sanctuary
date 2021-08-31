//SPDX-License-Identifier: None
pragma solidity ^0.8.0;

interface IDOLA {
  function mint(address to, uint amount) external;
  function burn(uint amount) external;
  function transfer(address to, uint value) external returns (bool);
  function transferFrom(address from, address to, uint value) external returns (bool);
}

/// @title Autonomous Repayment Enforcement Authority
/// @author Nour Haridy
/// @notice Contract responsible for enforcing protocol DOLA debt repayment using protocol revenue
/// @dev This contract is assumed to be set as a DOLA token minter in order to issue debt
contract AREA {

  IDOLA public dola;
  address public operator; // should be governance
  address public treasury; // receives potential revenue
  mapping (address => bool) public borrowers; // addresses allowed to mint up to the global ceiling
  uint public ceiling = 1000000 ether; // global debt ceiling starts with $1M
  uint public debt;
  uint public constant MIN_REPAY_FACTOR = 0.25 ether; // at least 25% of renvenue must be used to repay outstanding debt
  uint public repayFactor = 0.25 ether; // starting with 25%

  constructor(IDOLA _dola, address _operator, address _treasury) {
    dola = _dola;
    operator = _operator;
    treasury = _treasury;
  }

  function addBorrower(address _borrower) public {
    require(msg.sender == operator, "ONLY OPERATOR CAN ADD BORROWERS");
    borrowers[_borrower] = true;
  }

  function removeBorrower(address _borrower) public {
    require(msg.sender == operator, "ONLY OPERATOR CAN REMOVE BORROWERS");
    borrowers[_borrower] = false;
  }

  function changeCeiling(uint _ceiling) public {
    require(msg.sender == operator, "ONLY OPERATOR CAN CHANGE CEILING");
    ceiling = _ceiling;
  }

  function changeRepayFactor(uint _repayFactor) public {
    require(msg.sender == operator, "ONLY OPERATOR CAN CHANGE REPAY FACTOR");
    require(_repayFactor > MIN_REPAY_FACTOR, "REPAY FACTOR TOO LOW");
    require(_repayFactor <= 1 ether, "REPAY FACTOR TOO HIGH");
    repayFactor = _repayFactor;
  }

  function changeTreasury(address _treasury) public {
    require(msg.sender == treasury, "ONLY TREASURY CAN CHANGE TREASURY");
    treasury = _treasury;
  }

  function changeOperator(address _operator) public {
    require(msg.sender == operator, "ONLY OPERATOR CAN CHANGE OPERATOR");
    operator = _operator;
  }

  function borrow(address _to, uint _amount) public {
    require(borrowers[msg.sender] == true, "ONLY WHITELISTED BORROWERS CAN BORROW");
    require(debt + _amount <= ceiling, "DEBT EXCEEDED CEILING");
    dola.mint(_to, _amount);
    debt += _amount;
    emit Borrow(msg.sender, _amount);
  }

  /// @notice This function uses 100% of the paid amount to repay debt regardless of repayFactor
  function repayDebt(uint _amount) public {
    dola.transferFrom(msg.sender, address(this), _amount);
    dola.burn(_amount);
    debt -= _amount;
    emit Repay(msg.sender, _amount);
  }

  function receiveRevenue(uint _amount) public {
    dola.transferFrom(msg.sender, address(this), _amount);
    if(debt == 0) {
      dola.transfer(treasury, _amount);
      emit Revenue(msg.sender, _amount);
    } else {
      if(repayFactor == 1 ether) {
        dola.burn(_amount);
        debt -= _amount;
        emit Repay(msg.sender, _amount);
      } else {
        uint repayAmount = _amount * repayFactor / 1 ether;
        dola.burn(repayAmount);
        debt -= repayAmount;
        emit Repay(msg.sender, _amount);
        dola.transfer(treasury, _amount - repayAmount);
        emit Revenue(msg.sender, _amount);
      }
    }
  }

  event Borrow(address indexed borrower, uint amount);
  event Repay(address indexed repayer, uint amount);
  event Revenue(address indexed payer, uint amount);

}

{
  "evmVersion": "istanbul",
  "libraries": {},
  "metadata": {
    "bytecodeHash": "ipfs",
    "useLiteralContent": true
  },
  "optimizer": {
    "enabled": true,
    "runs": 200
  },
  "remappings": [],
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