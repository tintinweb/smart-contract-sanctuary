pragma solidity ^0.6.12;

import "./Context.sol";

contract Storage is Context {

  mapping (address => bool) public governance;
  mapping (address => bool) public controller;

  address immutable public owner;

  constructor() public {
    owner = _msgSender();
    governance[_msgSender()] = true;
    controller[_msgSender()] = true;
  }

  
  function setGovernance(address _governance, bool _isGovernance) external {
    require(_msgSender() == owner, "not an owner");
    require(_governance != _msgSender(), "governance cannot modify itself");
    governance[_governance] = _isGovernance;
  }

  function setController(address _controller, bool _isController) external {
    require(governance[_msgSender()], "not a governance");
    controller[_controller] = _isController;
  }
}

pragma solidity ^0.6.12;

// File: @openzeppelin/contracts/GSN/Context.sol

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}