/**
 *Submitted for verification at polygonscan.com on 2021-09-29
*/

/**
 *Submitted for verification at polygonscan.com on 2021-09-29
*/

// Sources flattened with hardhat v2.6.4 https://hardhat.org

// File contracts/libs/Math.sol


pragma solidity ^0.8.8;


library Math {
  function min(uint256 _a, uint256 _b) internal pure returns (uint256) {
    return _a < _b ? _a : _b;
  }
}


// File contracts/libs/Bytecode.sol


pragma solidity ^0.8.8;


library Bytecode {
  function creationCodeFor(bytes memory _code) internal pure returns (bytes memory) {
    /*
      63 PUSH4 <CODE_SIZE>
      80 DUP1
      60 PUSH1 <PREFIX_SIZE> (0x0e - 14)
      60 PUSH1 00
      39 CODECOPY
      60 PUSH1 00
      F3 RETURN
      <CODE>
    */

    return abi.encodePacked(
      hex"63",
      uint32(_code.length),
      hex"80_60_0E_60_00_39_60_00_F3",
      _code
    );
  }

  // Credit: https://gist.github.com/KardanovIR/fe98661df9338c842b4a30306d507fbd
  function at(address _addr) internal view returns (bytes memory oCode) {
    assembly {
      // retrieve the size of the code, this needs assembly
      let size := extcodesize(_addr)
      // allocate output byte array - this could also be done without assembly
      // by using o_code = new bytes(size)
      oCode := mload(0x40)
      // new "memory end" including padding
      mstore(0x40, add(oCode, and(add(add(size, 0x20), 0x1f), not(0x1f))))
      // store length in memory
      mstore(oCode, size)
      // actually retrieve the code, this needs assembly
      extcodecopy(_addr, add(oCode, 0x20), 0, size)
    }
  }
}


// File contracts/libs/Bytes.sol


pragma solidity ^0.8.8;


library Bytes {
  /**
   * @dev Reads an address value from a position in a byte array.
   * @param data Byte array to be read.
   * @param index Index in byte array of address value.
   * @return a address value of data at given index.
   * @return newIndex Updated index after reading the value.
   */
  function readAddress(
    bytes memory data,
    uint256 index
  ) internal pure returns (
    address a,
    uint256 newIndex
  ) {
    assembly {
      let word := mload(add(index, add(32, data)))
      a := and(shr(96, word), 0xffffffffffffffffffffffffffffffffffffffff)
      newIndex := add(index, 20)
    }

    require(newIndex <= data.length, "LibBytes#readAddress: OUT_OF_BOUNDS");
  }
}


// File contracts/Funder.sol


pragma solidity ^0.8.8;



contract Funder {
  uint256 private constant ADDRESS_SIZE = 20;

  address private immutable recipientsSource;
  string public name;

  error ErrorDeployingContract();
  error ErrorSendingTo(address _to);
  error ErrorSendingRemaining();

  constructor(address[] memory _recipients, string memory _name) {
    // Create a contract will the list of recipients as it's bytecode
    // Start the bytecode with the STOP OPCODE, so it we can't risk random contract execution based on contract address
    bytes memory code = hex'00';
    for (uint256 i = 0; i < _recipients.length; i++) {
      code = abi.encodePacked(code, _recipients[i]);
    }

    code = Bytecode.creationCodeFor(code);

    // Create a contract with that information
    address res; assembly { res := create(0, add(code, 32), mload(code)) }
    if (res == address(0)) revert ErrorDeployingContract();

    // Store the recipients and name
    recipientsSource = res;

    if (bytes(_name).length > 0) {
      name = _name;
    }
  }

  function recipients() public view returns (address[] memory) {
    unchecked {
      bytes memory code = Bytecode.at(recipientsSource);
      uint256 total = code.length / ADDRESS_SIZE;

      address[] memory rec = new address[](total);

      // Skip the first byte, read until end of code
      for (uint256 i = 1; i < code.length;) {
        (rec[i / ADDRESS_SIZE], i) = Bytes.readAddress(code, i);
      }

      return rec;
    }
  }

  receive() external payable {
    // Read all recipients
    address[] memory _recipients = recipients();
    uint256 recipientsCount = _recipients.length;

    // Get all current balances
    uint256 totalBalance = 0;
    uint256[] memory balances = new uint256[](recipientsCount);
    for (uint256 i = 0; i < recipientsCount; i++) {
      uint256 balance = _recipients[i].balance;
      totalBalance += balance;
      balances[i] = balance;
    }

    // Old avg and new avg
    uint256 newAvg = (totalBalance + msg.value) / recipientsCount;

    // Fill each address until we reach the new average

    uint256 sent = 0;
    for (uint256 i = 0; i < recipientsCount; i++) {
      {
        uint256 remaining = (msg.value - sent);
        if (balances[i] < newAvg) {
          uint256 diff = newAvg - balances[i];
          uint256 send = Math.min(diff, remaining);
          if (send == 0) break;

          (bool succeed,) = _recipients[i].call{ value: send }("");
          if (!succeed) revert ErrorSendingTo(_recipients[i]);
          sent += send;
        }
      }
    }

    // Send reaining back to caller

    {
      uint256 remaining = address(this).balance;
      if (remaining > 0) {
        (bool succeed,) = msg.sender.call{ value: remaining }("");
        if (!succeed) revert ErrorSendingRemaining();
      }
    }
  }
}


// File contracts/Factory.sol


pragma solidity ^0.8.8;

contract FunderFactory {
  Funder[] public funders;

  event Created(uint256 i);

  error RefundTooHigh();
  error ErrorFunding();

  function create(
    address[] calldata _addresses,
    string calldata _name
  ) external {
    uint256 id = funders.length;
    funders.push(new Funder(_addresses, _name));
    emit Created(id);
  }

  function info(uint256 _id) external view returns (string memory, address[] memory) {
    Funder funder = funders[_id];
    return (funder.name(), funder.recipients());
  }

  function fund(uint256 _id) external payable {
    (bool succeed,) = address(funders[_id]).call{ value: address(this).balance }("");
    if (!succeed) revert ErrorFunding();
  }

  receive() external payable {
    if (msg.value > 0.001 ether) revert RefundTooHigh();
  }
}