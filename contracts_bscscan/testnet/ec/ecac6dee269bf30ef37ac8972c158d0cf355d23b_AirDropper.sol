/**
 *Submitted for verification at BscScan.com on 2021-08-31
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
  function transfer(address recipient, uint256 amount) external returns (bool);
  function balanceOf(address account) external view returns (uint256);
}

contract AirDropper is Ownable {
  IERC20 token;

  constructor() {
    address _tokenAddr = 0x40e1A76833D5e2609b7FC0dD4E4db8f1E69d9Bbd;
    token = IERC20(_tokenAddr);
  }

  event TransferredToken(address indexed to, uint256 value);
  event FailedTransfer(address indexed to, uint256 value);

  modifier whenDropIsActive() {
    assert(isActive());
    _;
  }

  function multiTransfer(address[] memory _receivers, uint256[] memory _values) whenDropIsActive onlyOwner public returns (bool success) {
    require(_receivers.length <= 200, "Too many recipients");

    for(uint256 i = 0; i < _receivers.length; i++) {
      uint256 toSend = _values[i] * 10**18;
      sendInternally(_receivers[i], toSend, _values[i]);
    }

    return true;
  }

  function multiTransferSingleValue(address[] memory _receivers, uint256 _value) whenDropIsActive onlyOwner public returns (bool success) {
    uint256 toSend = _value * 10**18;
    require(_receivers.length <= 200, "Too many recipients");
    for(uint256 i = 0; i < _receivers.length; i++) {
      sendInternally(_receivers[i], toSend, _value);
    }

    return true;
  }

  function sendInternally(address _receiver, uint256 _value, uint256 _valueToPresent) internal {
    require(_receiver != address(0), "Cannot use zero address");
    require(_value > 0, "Cannot use zero value");

    if(tokensAvailable() >= _value) {
      token.transfer(_receiver, _value);
      emit TransferredToken(_receiver, _valueToPresent);
    } else {
      emit FailedTransfer(_receiver, _valueToPresent);
    }
  }

  function isActive() public view returns (bool) {
    return (tokensAvailable() > 0);
  }

  function tokensAvailable() public view returns (uint256) {
    return token.balanceOf(address(this));
  }
}