// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
import "../utils/ITopPlayers.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Statistics is Ownable {
    uint256 onePromo; //%20
    uint256 twoPromo; //%10
    uint256 threePromo; //%5

    ITopPlayers topPlayers;

    function setTopPlayerAddress(address _topPlayers) external onlyOwner {
        topPlayers = ITopPlayers(_topPlayers);
    }

    function getPlayerPromo(address player) external view returns (uint256) {
        userInfo[3] memory users;

        users = topPlayers.getTopPlayers();

        if (users[0].user == player) {
            return onePromo;
        } else if (users[1].user == player) {
            return twoPromo;
        } else if (users[2].user == player) {
            return threePromo;
        }
        //1 ether neutral element for partition
        return 1;
    }

    /**@notice _setPromo  all parameters should be 1-100 range */
    function setPromo(
        uint256 _onePromo,
        uint256 _twoPromo,
        uint256 _threePromo
    ) external onlyOwner {
        onePromo = _onePromo;
        twoPromo = _twoPromo;
        threePromo = _threePromo;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;
struct userInfo {
    address user;
    uint256 totalBetAmount;
}

interface ITopPlayers {
    function getTopPlayers() external view returns (userInfo[3] memory);

    function update(address user, uint256 amount) external;
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