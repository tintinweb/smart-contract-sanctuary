//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./BodyswapRoyaltiesSplit.sol";
import "./IBodyswapPayout.sol";

contract BodyswapRoyalties is BodyswapRoyaltiesSplit {
    event Blah(uint256);

    // only allow this once from owner
    function initialize(
        address artistAdress,
        uint256 artistRoyalty,
        address bodyswapAddress,
        uint256 bodyswapRoyalty
    ) public {
        if (_artistAddress != address(0) || _bodyswapAddress != address(0)) {
            revert("Already initialized");
        }
        _artistAddress = artistAdress;
        _artistSplit = artistRoyalty;
        _bodyswapAddress = bodyswapAddress;
        _bodyswapSplit = bodyswapRoyalty;
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

// TODO: Possibly use PaymentSplitter https://docs.openzeppelin.com/contracts/2.x/api/payment

pragma solidity ^0.8.0;

struct Payout {
    uint256 artistAmount;
    uint256 bodyswapAmount;
}

abstract contract BodyswapRoyaltiesSplit {
    address _artistAddress;
    uint256 _artistSplit;
    address _bodyswapAddress;
    uint256 _bodyswapSplit;

    event PayedOut(Payout);
    event PaymentReceived(address, uint256);

    receive() external payable {
        emit PaymentReceived(msg.sender, msg.value);
    }

    function balanceFor(address receiver) public view returns (uint256) {
        uint256 total = _artistSplit + _bodyswapSplit;
        uint256 balance = address(this).balance;
        uint256 bodyswapCut = _calculateOwed(_bodyswapSplit, total, balance);
        if (receiver == _artistAddress) {
            return balance - bodyswapCut;
        } else if (receiver == _bodyswapAddress) {
            return bodyswapCut;
        }
        revert("Unknown address");
    }

    /**
     * @dev Payout balance to parties based on royalty split.
     */
    function claimBalance() public virtual returns (uint256, uint256) {
        Payout memory payout = Payout(
            balanceFor(_artistAddress),
            balanceFor(_bodyswapAddress)
        );
        require(_artistAddress != address(0), "Artist address not found");
        require(_bodyswapAddress != address(0), "Bodyswap address not found");

        if (payout.artistAmount > 0) {
            payable(_artistAddress).transfer(payout.artistAmount);
        }

        if (payout.bodyswapAmount > 0) {
            payable(_bodyswapAddress).transfer(payout.bodyswapAmount);
        }
        emit PayedOut(payout);

        return (payout.artistAmount, payout.bodyswapAmount);
    }

    function _calculateOwed(
        uint256 percent,
        uint256 totalPercent,
        uint256 totalBalance
    ) private pure returns (uint256) {
        return (totalBalance * percent) / totalPercent;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBodyswapPayout1 {
    receive() external payable;

    function balanceFor(address receiver) external view returns (uint256);

    function claimBalance() external returns (uint256, uint256);

    // function initialize(
    //     address artistAdress,
    //     uint256 artistRoyalty,
    //     address bodyswapAddress,
    //     uint256 bodyswapRoyalty
    // ) external;
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

{
  "optimizer": {
    "enabled": false,
    "runs": 200
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