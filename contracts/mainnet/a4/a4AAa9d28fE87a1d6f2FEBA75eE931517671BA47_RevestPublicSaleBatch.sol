// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * Batch sale means that all tokens will be divided proportionally among all contributors.
 * Price is determined by the amount of ETH sent, therefore no need to set price variable here
 */
contract RevestPublicSaleBatch is Ownable {

    address public token; // RVST
    uint public tokenAmount; // How much is being sold
    uint public startTimestamp; // When to open the public sale
    uint public earlybirdTimestamp; // When the early bird discount ends
    uint public endTimestamp; // When to close it
    uint public earlybirdBonus; // How much of a premium to apply to early bird contributions
    uint public earlybirdDenominator = 100;

    mapping(address => uint) public allocs; // Maps addresses to contribution amounts
    uint public totalAlloc;

    constructor(uint _startTimestamp, uint _endTimestamp, uint _earlybirdTimestamp, uint _earlybirdBonus) Ownable() {
        require(
            block.timestamp < _startTimestamp
            && _startTimestamp < _earlybirdTimestamp
            && _earlybirdTimestamp < _endTimestamp,
            "E061"
        );
        require(_earlybirdBonus > earlybirdDenominator, "E062");

        startTimestamp = _startTimestamp;
        endTimestamp = _endTimestamp;
        earlybirdTimestamp = _earlybirdTimestamp;
        earlybirdBonus = _earlybirdBonus;
    }

    receive() external payable {
        require(startTimestamp <= block.timestamp && block.timestamp <= endTimestamp, "E063");

        uint amount = msg.value;
        uint effective = block.timestamp <= earlybirdTimestamp ? amount * earlybirdBonus / earlybirdDenominator : amount;
        allocs[msg.sender] += effective;
        totalAlloc += effective;
    }

    function claim() external {
        _claim(msg.sender);
    }

    function claimOnBehalf(address user) external onlyOwner {
        _claim(user);
    }

    function _claim(address user) internal claimable {
        require(allocs[user] > 0, "E064");

        // Calculate amount claimable - this changes based on batch auction, Dutch auction, or crowdsale
        uint amount = claimableTokens(user);
        allocs[user] = 0; // Prevent re-entrancy by updating balances before any external calls

        // Simple implementation: send tokens to users directly
        IERC20(token).transfer(user, amount);

        // Advanced implementation: wrap tokens in FNFTs before sending to users. We need to handle staking cases, not sure that logic belongs here
    }

    function claimableTokens(address user) public view claimable returns (uint) {
        return allocs[user] * tokenAmount / totalAlloc;
    }

    modifier claimable() {
        require(block.timestamp > endTimestamp, "E065");
        require(token != address(0x0), "E066");
        _;
    }

    /**
    * ADMIN FUNCTIONS
    */

    function setTokenAddress(address _tokenAddress) external onlyOwner {
        token = _tokenAddress;
    }

    function setTokenAmount(uint _tokenAmount) external onlyOwner {
        // Add some checks here to ensure the contract has the proper amount
        tokenAmount = _tokenAmount;
    }

    //Manual function to map seed round allocations
    function manualMapAllocation(address[] memory users, uint[] memory etherAlloc) external onlyOwner {
        uint len = users.length;
        require(len == etherAlloc.length, "E067");
        for(uint iter = 0; iter < len; iter++) {
            uint ethAll = etherAlloc[iter];

            allocs[users[iter]] += ethAll;
            totalAlloc += ethAll;
        }
    }

    function withdraw() public onlyOwner {
        uint amount = address(this).balance;
        (bool success,) = owner().call{value: amount}("");
        require(success, "E068");
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
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
        return msg.data;
    }
}

{
  "optimizer": {
    "enabled": true,
    "runs": 10000
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
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}