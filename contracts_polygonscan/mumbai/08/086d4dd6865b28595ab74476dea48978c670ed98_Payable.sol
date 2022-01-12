/**
 *Submitted for verification at polygonscan.com on 2022-01-11
*/

// File: src/Payable.sol


pragma solidity ^0.8.11;


// OpenZeppelin Contracts v4.4.0 (utils/Strings.sol)

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = '0123456789abcdef';

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return '0';
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

contract Payable {

  address internal owner;

  constructor() { owner = msg.sender; }

  function deposit() public payable {}

  function transfer(address payable to, uint256 amount) public onlyOwner {
    require(msg.sender == owner, 'Only owner can call this.');
    require(address(this).balance >= amount, concat('There is only ', str(address(this).balance), ' left.'));
    require(address(this).balance > 0, 'Balance is already withdrawn.');
    payable(to).transfer(amount);
  }

  function getBalance(uint256 value) public view onlyOwner returns (string memory, uint, string memory, uint) {
    return ('balance:', address(this).balance, 'value:', value);
  }

  // INTERNAL & UTILS ----------------------------------------------------------------------------------------------------

  modifier onlyOwner() {
    require(msg.sender == owner, 'Only owner can call this.');
    _;
  }

  function str(uint number) internal pure returns (string memory) { return Strings.toString(number); }
  function concat(string memory a, string memory b, string memory c) internal pure returns (string memory) { return string(abi.encodePacked(a, b, c)); }

}