// SPDX-License-Identifier: MPL-2.0
pragma solidity >=0.6.2;

interface IERC20 {
  function balanceOf (address account) external view returns (uint256);

  function transfer (address to, uint256 value) external returns (bool);
}

contract Dispenser {
  uint256 public lastUpdate;

  event NewDispenser (address contractAddress);

  /// @notice Creates a new contract.
  function create (
    address token,
    address payer,
    uint256 startTime,
    address[] calldata payees,
    uint256[] calldata ratesPerHour
  ) external returns (address addr) {
    uint256 len = payees.length;
    require(len > 0 && len == ratesPerHour.length);

    uint256 totalRatePerHour = 0;
    for (uint256 i = 0; i < len; i++) {
      uint256 tmp = totalRatePerHour + ratesPerHour[i];
      // overflow + zero -check
      require(tmp > totalRatePerHour);

      totalRatePerHour = tmp;
    }

    addr = _createSimpleProxy();
    // setup the dispenser
    Dispenser(addr).setup();
    emit NewDispenser(addr);
  }

  /// @notice Returns the metadata of this contract.
  /// Only relevant with contracts created via the function `create()`.
  function getMetadata ()
  public view returns (
    address token,
    address payer,
    uint256 startTime,
    address[] memory payees,
    uint256[] memory ratesPerHour
  ) {
    assembly {
      let x := sub(calldatasize(), 32)
      let size := calldataload(x)
      let ptr := sub(x, size)
      calldatacopy(0, ptr, size)
      return(0, size)
    }
  }

  /// @notice Setup this contract.
  function setup (
  ) external {
    require(lastUpdate == 0);

    (,,uint256 startTime,,) = Dispenser(this).getMetadata();
    require(startTime > 0);
    lastUpdate = startTime;
  }

  /// @notice Drips `ratesPerHour` to each payee since the last drip
  /// and then returns any remaining balance to the `payer`.
  function drain (
  ) external {
    (
      address token,
      address payer,
      uint256 startTime,
      address[] memory payees,
      uint256[] memory ratesPerHour
    ) = Dispenser(this).getMetadata();

    require(msg.sender == payer);

    // drip any accumulated debt first
    _update(token, payer, startTime, payees, ratesPerHour);

    IERC20 tokenContract = IERC20(token);
    uint256 balance = tokenContract.balanceOf(address(this));

    // any remaining balance can go back to the payer
    if (balance > 0) {
      require(tokenContract.transfer(payer, balance));
    }
  }

  /// @notice Drips `ratesPerHour` for each `payees` from `token` since the last drip.
  /// Returns Satisfaction.
  function drip (
  ) external {
    (
      address token,
      address payer,
      uint256 startTime,
      address[] memory payees,
      uint256[] memory ratesPerHour
    ) = Dispenser(this).getMetadata();

    _update(token, payer, startTime, payees, ratesPerHour);
  }

  /// @notice Allows to recover `lostToken` other than the intended `token`.
  /// Transfers `lostToken` to the first payee.
  function recoverLostTokens (
    address lostToken
  ) external {
    (address token, , , address[] memory payees,) = Dispenser(this).getMetadata();
    require(token != lostToken);

    IERC20 tokenContract = IERC20(lostToken);
    uint256 balance = tokenContract.balanceOf(address(this));
    // lost tokens go to the first payee
    tokenContract.transfer(payees[0], balance);
  }

  /// @dev The dripping logic.
  function _update (
    address token,
    address payer,
    uint256 startTime,
    address[] memory payees,
    uint256[] memory ratesPerHour
  ) internal {
    uint256 lastDrip = lastUpdate;

    if (block.timestamp < lastDrip) {
      return;
    }

    uint256 len = payees.length;
    uint256 totalRatePerHour = 0;
    for (uint256 i = 0; i < len; i++) {
      totalRatePerHour += ratesPerHour[i];
    }

    IERC20 tokenContract = IERC20(token);
    uint256 availableBalance = tokenContract.balanceOf(address(this));
    uint256 availableHours = availableBalance / totalRatePerHour;
    uint256 maxHours = (block.timestamp - lastDrip) / 3600;

    if (availableHours > maxHours) {
      // clamp
      availableHours = maxHours;
    }

    if (availableHours > 0) {
      // update
      lastUpdate = lastDrip + (availableHours * 3600);

      // transfer to payees
      for (uint256 i = 0; i < len; i++) {
        uint256 rate = ratesPerHour[i];
        uint256 amount = rate * availableHours;

        availableBalance -= amount;
        require(tokenContract.transfer(payees[i], amount));
      }
    }

    // drip any dust to the payer
    if (availableBalance > 0 && availableBalance < totalRatePerHour) {
      // dust
      require(tokenContract.transfer(payer, availableBalance));
    }
  }

  function _createSimpleProxy () internal returns (address addr) {
    // the following assembly code (init code + contract code) is a simple proxy.
    assembly {
      // # deploy code
      // PUSH1 11;
      // CODESIZE;
      // SUB;
      // DUP1;
      // PUSH1 11;
      // CALLDATASIZE;
      // CODECOPY;
      // CALLDATASIZE;
      // RETURN; (contract bytecode is everything after this return opcode)
      mstore(128, 0x600b380380600b363936f3000000000000000000000000000000000000000000)

      // # contract code
      // RETURNDATASIZE; push `0` on stack
      // RETURNDATASIZE; 0 outSize
      // RETURNDATASIZE; 0 outOffset

      // copy args
      // CALLDATASIZE;
      // RETURNDATASIZE;
      // RETURNDATASIZE;
      // CALLDATACOPY; (0, 0, calldatasize())

      // PUSH1 55;
      // DUP1; 55, 55
      // CODESIZE;
      // SUB; size, 55
      // DUP1; size ,size, 55
      // SWAP2; 55, size, size
      // CALLDATASIZE;
      // CODECOPY; (calldatasize(), 55, size)

      // CALLDATASIZE;
      // ADD; size+calldatasize
      // RETURNDATASIZE; 0 inOffset
      // PUSH20 0; zero is replaced with shl(96, address())
      // GAS;
      // DELEGATECALL; (gas, addr, 0, calldatasize() + metadata, 0, 0) delegatecall to this Dispenser contract;
      //
      // RETURNDATASIZE;
      // DUP3; 0
      // DUP1; 0
      // RETURNDATACOPY; (0, 0, returndatasize) - Copy everything into memory that the call returned
      //
      // # this is for either revert(0, returndatasize()) or return (0, returndatasize())
      // RETURNDATASIZE;
      // DUP3; 0
      //
      // DUP3; copy retCode from delegatecall() - 0 fail, 1 success
      // PUSH1 _SUCCESS_; push jumpdest of _SUCCESS_
      // JUMPI; jump if delegatecall returned `1`
      // REVERT; (0, returndatasize()) if delegatecall returned `0`
      // JUMPDEST _SUCCESS_;
      // RETURN; (0, returndatasize()) if delegatecall returned non-zero (1)

      // the bytecode from the above statements
      mstore(139, 0x3d3d3d363d3d3760378038038091363936013d73000000000000000000000000)
      mstore(159, shl(96, address()))
      // 15 bytes
      mstore(179, 0x5af43d82803e3d8282603557fd5bf30000000000000000000000000000000000)

      let size := sub(calldatasize(), 4)
      calldatacopy(194, 4, size)
      let ptr := add(194, size)
      mstore(ptr, size)

      // The size is deploy code + contract code + calldatasize - 4 + 32.
      // Subtract 96 instead of 128 because the `ptr` is not increased after the last `mstore`.
      addr := create(0, 128, sub(ptr, 96))
    }
  }
}
