// SPDX-License-Identifier: GPL-3.0-only

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface TransferFromAndBurnFrom {
    function burnFrom(address account, uint256 amount) external;

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external;
}

contract Opener is Ownable {
    TransferFromAndBurnFrom private _pmonToken;
    address public _stakeAddress;
    address public _feeAddress;
    address public _swapBackAddress;

    event Opening(address indexed from, uint256 amount, uint256 openedBoosters);

    uint256 public _burnShare = 75;
    uint256 public _stakeShare = 0;
    uint256 public _feeShare = 25;
    uint256 public _swapBackShare = 0;

    bool public _closed = false;

    uint256 public _openedBoosters = 0;

    constructor(
        TransferFromAndBurnFrom pmonToken,
        address stakeAddress,
        address feeAddress,
        address swapBackAddress
    ) public {
        _pmonToken = pmonToken;
        _stakeAddress = stakeAddress;
        _feeAddress = feeAddress;
        _swapBackAddress = swapBackAddress;
    }

    function openBooster(uint256 amount) public {
        require(!_closed, "Opener is locked");
        address from = msg.sender;
        require(
            _numOfBoosterIsInteger(amount),
            "Only integer numbers of booster allowed"
        );
        _distributeBoosterShares(from, amount);

        emit Opening(from, amount, _openedBoosters);
        _openedBoosters = _openedBoosters + (amount / 10**uint256(18));
    }

    function _numOfBoosterIsInteger(uint256 amount) private returns (bool) {
        return (amount % 10**uint256(18) == 0);
    }

    function _distributeBoosterShares(address from, uint256 amount) private {
        //transfer of fee share
        _pmonToken.transferFrom(from, _feeAddress, (amount * _feeShare) / 100);

        //transfer of stake share
        _pmonToken.transferFrom(
            from,
            _stakeAddress,
            (amount * _stakeShare) / 100
        );

        //transfer of swapBack share
        _pmonToken.transferFrom(
            from,
            _swapBackAddress,
            (amount * _swapBackShare) / 100
        );

        //burning of the burn share
        _pmonToken.burnFrom(from, (amount * _burnShare) / 100);
    }

    function setShares(
        uint256 burnShare,
        uint256 stakeShare,
        uint256 feeShare,
        uint256 swapBackShare
    ) public onlyOwner {
        require(
            burnShare + stakeShare + feeShare + swapBackShare == 100,
            "Doesn't add up to 100"
        );

        _burnShare = burnShare;
        _stakeShare = stakeShare;
        _feeShare = feeShare;
        _swapBackShare = swapBackShare;
    }

    function setStakeAddress(address stakeAddress) public onlyOwner {
        _stakeAddress = stakeAddress;
    }

    function setFeeAddress(address feeAddress) public onlyOwner {
        _feeAddress = feeAddress;
    }

    function setSwapBackAddress(address swapBackAddress) public onlyOwner {
        _swapBackAddress = swapBackAddress;
    }

    function lock() public onlyOwner {
        _closed = true;
    }

    function unlock() public onlyOwner {
        _closed = false;
    }
}

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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 1000
  },
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "libraries": {}
}