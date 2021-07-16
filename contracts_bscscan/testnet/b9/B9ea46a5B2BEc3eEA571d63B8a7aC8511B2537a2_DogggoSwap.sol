// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IBEP20 {
	function balanceOf(address account) external view returns (uint256);

	function transfer(address recipient, uint256 amount) external returns (bool);

	function allowance(address _owner, address spender) external view returns (uint256);

	function transferFrom(
		address sender,
		address recipient,
		uint256 amount
	) external returns (bool);
}

contract DogggoSwap is Ownable {
	IBEP20 private oldDogggo;
	IBEP20 private newDogggo;
	uint256 public deadline;
	mapping(address => uint256) public beneficiariesAmountsAlreadySwapped;
	mapping(address => uint256) public beneficiaryAmounts;
	bool public isSwapEnabled = false;

	event Swap(address, uint256);
	event Withdraw(address, uint256);

	constructor(
		address _oldDogggo,
		address _newDogggo,
		uint256 _deadline
	) {
		oldDogggo = IBEP20(_oldDogggo);
		newDogggo = IBEP20(_newDogggo);
		deadline = _deadline;
	}

	function swap(uint256 amount) external {
		require(isSwapEnabled, "Too early to swap");
		require(block.number <= deadline, "Too late to swap");
		require(beneficiaryAmounts[msg.sender] > 0, "No new Dogggo reserved for this address");
		require(beneficiariesAmountsAlreadySwapped[msg.sender] + amount < beneficiaryAmounts[msg.sender], "Claim exceeds Dogggo reserved for this address");
		require(amount <= oldDogggo.allowance(msg.sender, address(this)), "Increase allowance");

		uint256 oldDogggoBalance = oldDogggo.balanceOf(msg.sender);
		require(oldDogggoBalance >= amount, "Cannot swap more than what you have");
		oldDogggo.transferFrom(msg.sender, address(this), amount);
		beneficiariesAmountsAlreadySwapped[msg.sender] += amount;
		uint256 oldDogggoNewBalance = oldDogggo.balanceOf(msg.sender);
		require(oldDogggoNewBalance == oldDogggoBalance - amount, "Not enough old Dogggo");

		newDogggo.transfer(msg.sender, amount);
		emit Swap(msg.sender, amount);
	}

	function addToWhitelist(address[] memory _beneficiaries, uint256[] memory _balances) external onlyOwner {
		require(!isSwapEnabled, "Too late to add beneficiaries");
		require(_beneficiaries.length == _balances.length, "Arrays length not equal");

		for (uint256 i = 0; i < _beneficiaries.length; i++) {
			beneficiaryAmounts[_beneficiaries[i]] = _balances[i];
		}
	}

	function startSwap() external onlyOwner {
		isSwapEnabled = true;
	}

	function withdraw() external onlyOwner {
		require(block.number > deadline, "Too early to withdraw");
		uint256 balance = newDogggo.balanceOf(address(this));
		newDogggo.transfer(owner(), balance);
		emit Withdraw(owner(), balance);
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