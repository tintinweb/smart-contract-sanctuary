// SPDX-License-Identifier: AGPLv3
pragma solidity 0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IToken {
    function mint(address _receiver, uint256 _amount) external;

    function burn(address _receiver, uint256 _amount) external;
}

contract GRODistributer is Ownable {
    uint256 public immutable LBP_QUOTA;
    uint256 public immutable INVESTOR_QUOTA;
    uint256 public immutable TEAM_QUOTA;
    uint256 public immutable COMMUNITY_QUOTA;

    IToken public immutable govToken; // 0x44e9EDA64DA8f61C68c7322E8Ee3F14c73DbFb29
    mapping(address => bool) public vesters;
    mapping(address => uint256) public mintedAmount;

    constructor(
        address token,
        uint256 lbpQuota,
        uint256 communityQuota,
        uint256 investorQuota,
        uint256 teamQuota,
        address dao
    ) {
        govToken = IToken(token);
        LBP_QUOTA = lbpQuota;
        COMMUNITY_QUOTA = communityQuota;
        INVESTOR_QUOTA = investorQuota;
        TEAM_QUOTA = teamQuota;
        IToken(token).mint(dao, lbpQuota);
    }

    function setVester(address vester, bool status) external onlyOwner {
        vesters[vester] = status;
    }

    function mint(address account, uint256 amount) external {
        require(vesters[msg.sender], "mint: !caller");
        govToken.mint(account, amount);
        mintedAmount[msg.sender] = mintedAmount[msg.sender] + amount;
    }

    function burn(address account, uint256 amount) external {
        require(vesters[msg.sender], "mint: !caller");
        govToken.burn(account, amount);
        mintedAmount[msg.sender] = mintedAmount[msg.sender] - amount;
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
  "metadata": {
    "useLiteralContent": true
  },
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