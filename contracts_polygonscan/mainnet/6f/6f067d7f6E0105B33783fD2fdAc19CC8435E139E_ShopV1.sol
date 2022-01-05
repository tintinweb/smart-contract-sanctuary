// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/Beneficiary.sol";

interface FadalgiaInterface {
  function mint(address account, uint id, uint amount) external;
}

contract ShopV1 is Ownable, Beneficiary {
  FadalgiaInterface immutable public target;

  uint public sold;
  uint public supply;
  uint public price;
  bool public pause;

  uint8[] private _stock;

  constructor(uint startId, uint8[] memory count, address[] memory beneficiaries_, uint[] memory ratio_, address target_) Beneficiary(beneficiaries_, ratio_) {
    target = FadalgiaInterface(target_);

    // stock
    for (uint i = 0; i < count.length; ++i) {
      supply += count[i];
      for (uint c = 0; c < count[i]; ++c) {
        _stock.push(uint8(startId + i));
      }
    }

    require(_stock.length <= 2048);
  }

  event SetPrice(uint);

  function setPrice(uint price_) external onlyOwner {
    price = price_;
    emit SetPrice(price_);
  }

  function setPause(bool pause_) external onlyOwner {
    pause = pause_;
  }

  function stock() external view returns (uint8[] memory) {
    return _stock;
  }

  uint private _seed;

  function open(uint count, address account) external payable {
    require(msg.value >= price * count, "bad price");
    require(!pause, "pause");
    sold += count;
    require(sold <= supply, "no supply");

    require(count <= 23, "bad count"); // random 11-bits each -> stock <= 2048
    uint256 r = uint256(keccak256(abi.encodePacked(_seed, block.coinbase, account)));
    _seed = r;
    for (uint i = 0; i < count; ++i) {
      uint p = r % _stock.length;
      target.mint(account, _stock[p], 1);
      _stock[p] = _stock[_stock.length - 1];
      _stock.pop();
      r >>= 11;
    }

    _transferValue(msg.value);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

abstract contract Beneficiary {
  address[] internal _beneficiaries;
  uint[] internal _ratio;

  constructor(address[] memory beneficiaries_, uint[] memory ratio_) {
    require(beneficiaries_.length > 0, "no beneficiaries");
    require(beneficiaries_.length == ratio_.length, "invalid ratio length");
    uint total = 0;
    for (uint i = 0; i < ratio_.length; ++i) {
      total += ratio_[i];
    }
    require(total == 1000, "invalid total ratio");

    _beneficiaries = beneficiaries_;
    _ratio = ratio_;
  }

  function beneficiaries() external view returns (address[] memory) {
    return _beneficiaries;
  }

  function beneficiaryRatios() external view returns (uint[] memory) {
    return _ratio;
  }

  event TransferValue(uint);

  function transferValue() external {
    emit TransferValue(address(this).balance);
    _transferValue(address(this).balance);
  }

  function _transferValue(uint amount) internal {
    uint part = amount / 1000;
    for (uint i = 0; i < _ratio.length; ++i) {
      _sendValue(payable(_beneficiaries[i]), part * _ratio[i]);
    }
  }

  function _sendValue(address payable recipient, uint256 amount) internal {
    require(address(this).balance >= amount, "insufficient balance");

    (bool success, ) = recipient.call{value: amount}("");
    require(success, "unable to send value");
  }
}