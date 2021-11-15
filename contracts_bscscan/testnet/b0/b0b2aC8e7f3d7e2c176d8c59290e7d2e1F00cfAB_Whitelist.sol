// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    function _msgValue() internal view virtual returns (uint256) {
        return msg.value;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./Context.sol";

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
pragma solidity 0.8.7;

import "./Ownable.sol";
import "./Context.sol";

contract Curatable is Context, Ownable {
  address public curator;

  event CurationRightsTransferred(address indexed previousCurator, address indexed newCurator);

  /**
   * @dev The Curatable constructor sets the original `curator` of the contract to the sender
   * account.
   */
  constructor() {
    _setCurator(_msgSender());
  }


  /**
   * @dev Throws if called by any account other than the curator.
   */
  modifier onlyCurator() {
    require(_msgSender() == curator);
    _;
  }


  function setNewCurator(address newCurator) public onlyOwner returns (bool) {
    _setCurator(newCurator);
    return true;
  }

  function _setCurator(address newCurator) internal virtual {
    require(newCurator != address(0));
    emit CurationRightsTransferred(curator, newCurator);
    curator = newCurator;
  }

}

contract Whitelist is Curatable {
    mapping (address => bool) private _whitelist;

    constructor() {
    }


    function addInvestor(address investor) public onlyCurator returns (bool) {
        require(investor != address(0) && !_whitelist[investor]);
        _whitelist[investor] = true;
        return true;
    }


    function removeInvestor(address investor) public onlyCurator returns (bool) {
        require(investor != address(0) && _whitelist[investor]);
        _whitelist[investor] = false;
        return true;
    }


    function isWhitelisted(address investor) public view returns (bool) {
        return _whitelist[investor];
    }

}

