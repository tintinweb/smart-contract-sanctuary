/**
 *Submitted for verification at snowtrace.io on 2021-12-13
*/

// Sources flattened with hardhat v2.6.8 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]

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


// File @openzeppelin/contracts/access/[email protected]

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


// File contracts/PangolinVoteCalculator.sol

pragma solidity 0.8.0;
interface IMiniChefV2 {
    struct UserInfo {
        uint256 amount;
        int256 rewardDebt;
    }

    function lpTokens() external view returns (address[] memory);
    function userInfo(uint pid, address user) external view returns (IMiniChefV2.UserInfo memory);
}

interface IPangolinPair {
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
}

interface IPangolinERC20 {
    function balanceOf(address owner) external view returns (uint);
    function getCurrentVotes(address account) external view returns (uint);
    function delegates(address account) external view returns (address);
}

interface IStakingRewards {
    function stakingToken() external view returns (address);
    function balanceOf(address owner) external view returns (uint);
}

// SPDX-License-Identifier: MIT
contract PangolinVoteCalculator is Ownable {

    IPangolinERC20 png;
    IMiniChefV2 miniChef;

    constructor(address _png, address _miniChef) {
        png = IPangolinERC20(_png);
        miniChef = IMiniChefV2(_miniChef);
    }

    function getVotesFromFarming(address voter, uint[] calldata pids) external view returns (uint votes) {
        address[] memory lpTokens = miniChef.lpTokens();

        for (uint i; i<pids.length; i++) {
            // Skip invalid pids
            if (pids[i] >= lpTokens.length) continue;

            address pglAddress = lpTokens[pids[i]];
            IPangolinPair pair = IPangolinPair(pglAddress);

            uint pair_total_PNG = png.balanceOf(pglAddress);
            uint pair_total_PGL = pair.totalSupply(); // Could initially be 0 in rare pre-mint situations

            uint PGL_hodling = pair.balanceOf(voter);
            uint PGL_staking = miniChef.userInfo(pids[i], voter).amount;

            votes += ((PGL_hodling + PGL_staking) * pair_total_PNG) / pair_total_PGL;
        }
    }

    function getVotesFromStaking(address voter, address[] calldata stakes) external view returns (uint votes) {
        for (uint i; i<stakes.length; i++) {
            IStakingRewards staking = IStakingRewards(stakes[i]);

            // Safety check to ensure staking token is PNG
            if (staking.stakingToken() == address(png)) {
                votes += staking.balanceOf(voter);
            }
        }
    }

    function getVotesFromWallets(address voter) external view returns (uint votes) {
        // Votes delegated to the voter
        votes += png.getCurrentVotes(voter);

        // Voter has never delegated
        if (png.delegates(voter) == address(0)) {
            votes += png.balanceOf(voter);
        }
    }

}