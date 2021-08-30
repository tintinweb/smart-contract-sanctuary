// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Utils/Ownable.sol";
import "./Interfaces/IMyobuDistributor.sol";
import "./Utils/DistributorLib.sol";

// import "hardhat/console.sol";

contract MyobuDistributor is IMyobuDistributor, Ownable {
    mapping(uint256 => DistributeTo) private distributeTo_;

    function distributeTo(uint256 index)
        external
        view
        override
        returns (DistributeTo memory)
    {
        return distributeTo_[index];
    }

    uint256 public override distributeToCount;

    function addArrayToMapping(DistributeTo[] memory array) private {
        distributeToCount = array.length;
        for (uint256 i; i < array.length; i++) {
            distributeTo_[i] = array[i];
        }
    }

    function setDistributeTo(DistributeTo[] calldata toDistributeTo)
        external
        onlyOwner
    {
        if (distributeToCount != 0) distribute();
        uint256 totalPercentage;
        for (uint256 i; i < toDistributeTo.length; i++) {
            totalPercentage += toDistributeTo[i].percentage;
        }
        require(totalPercentage == 100, "Total percentage must equal to 100");

        addArrayToMapping(toDistributeTo);
        emit DistributeToChanged(toDistributeTo);
    }

    function distribute() public override {
        require(distributeToCount != 0, "Must have distribution set");
        if (address(this).balance == 0) return;
        uint256 totalBalance = address(this).balance;

        for (uint256 i; i < distributeToCount; i++) {
            DistributorLib.transferOrWrapETH(
                distributeTo_[i].addr,
                (totalBalance * distributeTo_[i].percentage) / 100
            );
        }
        emit Distributed(totalBalance, _msgSender());
    }

    // solhint-disable-next-line
    receive() external payable {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "../Interfaces/IWETH.sol";

library DistributorLib {
    IWETH internal constant WETH =
        IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    /**
     * @dev Attempt to transfer ETH, if failed wrap the ETH and send WETH. So that the
     * transfer always succeeds
     * @param to: The address to send ETH to
     * @param amount: The amount to send
     */
    function transferOrWrapETH(address to, uint256 amount) internal {
        // solhint-disable-next-line
        if (!payable(to).send(amount)) {
            WETH.deposit{value: amount}();
            WETH.transfer(to, amount);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IMyobuDistributor {
    struct DistributeTo {
        address addr;
        uint256 percentage;
    }
    event DistributeToChanged(DistributeTo[] _distributeTo);

    function distributeTo(uint256 index)
        external
        view
        returns (DistributeTo memory);

    function distributeToCount() external view returns (uint256);

    event Distributed(uint256 amount, address sender);

    function distribute() external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Context.sol";

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);
}

{
  "optimizer": {
    "enabled": true,
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
  }
}