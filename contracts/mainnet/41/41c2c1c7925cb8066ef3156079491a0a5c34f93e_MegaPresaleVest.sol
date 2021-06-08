/**
 *Submitted for verification at Etherscan.io on 2021-06-07
*/

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// File: contracts/MegaPresaleVest.sol

pragma solidity ^0.8.0;



contract MegaPresaleVest is Ownable {
    address public megaToken;
    address public contributionToken;
    uint public contributionDeadline;
    uint public vestingDeadline;

    struct Contributor {
        address contributor;
        uint contributionAmount;
        uint maxContributionAmount;
        uint rate;
        bool withdrawn;
    }

    Contributor[] public contributors;

    event Registration(address contributor, uint maxContributionAmount, uint rate, uint timestamp);
    event Adjustment(address contributor, uint maxContributionAmount, uint rate, uint timestamp);
    event Contribution(address contributor, uint amount, uint timestamp);
    event Withdrawal(address contributor, uint withdrawnAmount, uint timestamp);

    constructor(address _megaToken, address _contributionToken, uint _contributionDeadline, uint _vestingDeadline) {
        megaToken = _megaToken;
        contributionToken = _contributionToken;
        contributionDeadline = _contributionDeadline;
        vestingDeadline = _vestingDeadline;
    }

    function getContributors() external view returns (Contributor[] memory) {
        return contributors;
    }

    function usdcToMega(uint usdcAmt, uint rate) pure internal returns (uint) {
        return (usdcAmt / rate) * 1e18;
    }

    function addContributor(address contributor, uint maxContributionAmount, uint rate) onlyOwner external {
        require(rate > 0, "The rate must be non-zero");
        require((maxContributionAmount % rate == 0) || (maxContributionAmount == 0), "Contribution amount must be a multiple of the rate and non-zero");

        uint allocationTotal;
        for(uint i; i < contributors.length; i++) {
            require(contributors[i].contributor != contributor, "Contributor already present");
            allocationTotal += contributors[i].maxContributionAmount;
        }

        uint loadedMega = IERC20(megaToken).balanceOf(address(this));
        uint availableMegaForPurchase = usdcToMega(allocationTotal + maxContributionAmount, rate);
        require(loadedMega >= availableMegaForPurchase, "maxContributionAmount across all contributors exceeds available Mega balance");
        contributors.push(Contributor(contributor, 0, maxContributionAmount, rate, false));
        emit Registration(contributor, maxContributionAmount, rate, block.timestamp);
    }

    function setContributionParams(address contributor, uint maxContributionAmount, uint rate) onlyOwner external {
        require(rate > 0, "The rate must be non-zero");
        require((maxContributionAmount % rate == 0) || (maxContributionAmount == 0), "Contribution amount must be a multiple of the rate");

        uint allocationTotal;
        bool contributorPresent;
        for(uint i; i < contributors.length; i++) {
            if(contributors[i].contributor == contributor) {
                contributorPresent = true;
                if(rate != contributors[i].rate) {
                    require(contributors[i].contributionAmount == 0, "Rate cannot be altered after initial purchase");
                }
                require(contributors[i].contributionAmount <= maxContributionAmount, "Contributor already bought more than new maxContributionAmount");
                contributors[i].maxContributionAmount = maxContributionAmount;
                contributors[i].rate = rate;
            }

            allocationTotal += contributors[i].maxContributionAmount;
        }

        uint loadedMega = IERC20(megaToken).balanceOf(address(this));
        uint availableMegaForPurchase = usdcToMega(allocationTotal, rate);

        require(contributorPresent, "Contributor not present");
        require(loadedMega >= availableMegaForPurchase, "maxContributionAmount across all contributors exceeds available Mega balance");
        emit Adjustment(contributor, maxContributionAmount, rate, block.timestamp);
    }

    function contribute(uint contribution) external {
        require(block.timestamp <= contributionDeadline, "Contribution deadline has passed");
        require(IERC20(contributionToken).transferFrom(msg.sender, owner(), contribution), "ERC20 transferFrom failed");

        bool contributorPresent;
        for(uint i; i < contributors.length; i++) {
            if(contributors[i].contributor == msg.sender) {
                contributorPresent = true;
                require(contribution % contributors[i].rate == 0, "Contribution amount must be a multiple of the rate");
                require((contributors[i].contributionAmount + contribution) <= contributors[i].maxContributionAmount, "Contribution cumulative exceeds maxContributionAmount");
                contributors[i].contributionAmount += contribution;
            }
        }

        require(contributorPresent, "Contributor not present");
        emit Contribution(msg.sender, contribution, block.timestamp);
    }

    function withdraw() external {
        require(block.timestamp > vestingDeadline, "Vesting deadline has not yet passed");

        bool contributorPresent;
        uint contributionAmount;
        uint rate;
        for(uint i; i < contributors.length; i++) {
            if(contributors[i].contributor == msg.sender) {
                contributorPresent = true;
                require(!contributors[i].withdrawn, "MEGA already withdrawn");
                contributionAmount = contributors[i].contributionAmount;
                rate = contributors[i].rate;
                contributors[i].withdrawn = true;
            }
        }

        uint withdrawnAmount = usdcToMega(contributionAmount, rate);
        require(contributorPresent, "Contributor not present");
        require(IERC20(megaToken).transfer(msg.sender, withdrawnAmount), "MEGA transfer failed");
        emit Withdrawal(msg.sender, withdrawnAmount, block.timestamp);
    }

    function withdrawOverallocation() onlyOwner external {
        require(block.timestamp > contributionDeadline, "Contribution deadline has not yet passed");

        uint contributionAmount;
        for(uint i; i < contributors.length; i++) {
            contributionAmount += usdcToMega(contributors[i].contributionAmount, contributors[i].rate);
        }

        uint overallocation = IERC20(megaToken).balanceOf(address(this)) - contributionAmount;
        require(IERC20(megaToken).transfer(owner(), overallocation), "MEGA transfer failed");
    }

    function setContributionDeadline(uint newContributionDeadline) onlyOwner external {
        require(block.timestamp < contributionDeadline, 'Cannot restart the sale after the contribution deadline');
        uint sixMonths = 15780000;
        contributionDeadline = newContributionDeadline;
        vestingDeadline = contributionDeadline + sixMonths;
    }

    function releaseVestLock() onlyOwner external {
        require(block.timestamp < vestingDeadline, 'Vesting lock is already released');
        vestingDeadline = block.timestamp;
    }

    function sweepErc(address erc) onlyOwner external {
        uint twoWeeks = 1209600;
        require((erc != megaToken) || block.timestamp > (vestingDeadline + twoWeeks), "Mega cannot be swept prematurely and is subject to the contract agreement");
        IERC20(erc).transfer(owner(), IERC20(erc).balanceOf(address(this)));
    }

    function sweepEth() onlyOwner external {
        payable(owner()).transfer(address(this).balance);
    }

    receive() external payable {}
}