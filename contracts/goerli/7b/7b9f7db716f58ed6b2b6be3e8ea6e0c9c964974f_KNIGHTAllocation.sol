/**
 *Submitted for verification at Etherscan.io on 2021-09-21
*/

/**
 *Submitted for verification at Etherscan.io on 2021-07-12
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/******************************************/
/*       IERC20 starts here               */
/******************************************/

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol

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

/******************************************/
/*       Context starts here              */
/******************************************/

// File: @openzeppelin/contracts/GSN/Context.sol

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

/******************************************/
/*       Ownable starts here              */
/******************************************/

// File: @openzeppelin/contracts/access/Ownable.sol

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

/******************************************/
/*       KnightAllocation Starting below      */
/******************************************/

contract KNIGHTAllocation is Ownable {

    IERC20 public KNIGHT; 

    uint256 public startBlock;
    uint256 public endBlock;
    bool initialized;

    mapping (address => Allocation) public allocations;

    struct Allocation {
        uint256 sharePerBlock;
        uint256 lastWithdrawalBlock;
        bool friendlyKnight;
    }

    /**
     * @dev Populate allocations.
     */
    constructor()
    {
        address[30] memory shareHolders = [0xeea9f6E6E2893963f9Ef3BabE649AeC458891B60,
            0x4C800D9A4DB1A92c9835F39648fcf87E0163c556,
            0xE1476C3dD4BE8C160636e68094D235922B9Cdf14,
            0x530588ECE1281D1dBe1691F18eD8472Bb898f815,
            0xF5bC8bb5FA79B608f55AfbE002884f736dAf11ee,
            0x1Fea39EFC76aef6495804Ef648008a183e64450B,
            0x3b1358Fb498FfDB89A0D1A265D3C13365B1F9f96,
            0x3870edA39536c95CD2C6370464E0C0d619e198f7,
            0x8888888888E9997E64793849389a8Faf5E8e547C,
            0x1f2ac9F2686fBFf594E3aaa9AfC9ec9AEeBbc820,
            0x647e778aD23b5b22D188e8d664fA4fEEc259385C,
            0xcAb6d7B72E8046a036Be68796b0954b5f9e24695,
            0xEcBBE9aed91361Ea5747FA6a9e816156D2a67015,
            0x07c02E53F05Dae5B9317ad179181e0a2d931f057,
            0x9A52120fC23606E40caC53abc7a2af857c357408,
            0x9e67D018488aD636B538e4158E9e7577F2ECac12,
            0xDa4f84247Bd3aC0705757267Ab2742Aa3bEb84F3,
            0x4AcA1BB479Fa8B229d7B2D51f6BD75962D5e45EC,
            0xCA63CD425d0e78fFE05a84c330Bfee691242113d,
            0x128f0081Fdcb8b902fF0f45Ae90bBE93d87dF47b,
            0xd4BAE583B857EaC6bA205bbC863369CfE4B813F5,
            0x82Ba7508f7F1995AB1623258D66Cb4E2B2b8F467,
            0x3EB377Be158C4F0b409B917c10D163dFF8b5C9F3,
            0x8CD649c1bCEcf0A2F2cdFe23d9a75E4cB69c9AE6,
            0x529C9428572fFd389b031f7bd5bdC44b3F471D8e,
            0x3C80D903d94f50dBc2a609631557EFAfC50FeE9b,
            0x54B626f9fec0c83f2282Dd293B195Dc7EDfe5FF1,
            0x1dBAc441b975c9497667DA662207326a15A1C795,
            0x66122f79Ff0e852Db68EAd808D773f51f934Ee07,
            0xE984cDA2f65323cC1EC4011CA5D282a5a819D9fA];

        uint256[30] memory sharesPerBlock =[uint256(178165621784979000),305426954732510000,50904594264403300,50904594264403300,25452144418724300,63630513760288100,25452144418724300,38178369341563800,101808883101852000,127261332947531000,25452144418724300,76356738683127600,63630513760288100,254522360468107000,12726224922839500,76356738683127600,50904594264403300,127261332947531000,12726224922839500,38178369341563800,12726224922839500,12726224922839500,12726224922839500,2545122813786010,12726224922839500,2545122813786010,2545122813786010,6362959747942390,7635673868312760,5090551054526750];
        // Team Draft
        for (uint256 index = 0; index < shareHolders.length; index++) {
            allocations[shareHolders[index]] = Allocation({
            sharePerBlock: sharesPerBlock[index],
            lastWithdrawalBlock: block.number,
            friendlyKnight: true  
            });
        }
       
        startBlock = block.number;
        endBlock = block.number + 3110400; //5760 blocks per day * 30 days * 18 months
    }

    function initialize(IERC20 _KNIGHT) external onlyOwner
    {
        require(initialized == false, "Already initialized.");
        initialized = true;
        KNIGHT = _KNIGHT;
    }

    /**
     * @dev Withdraw all unlocked shares.
     */
    function withdrawShare() external
    {
        require(allocations[msg.sender].lastWithdrawalBlock < endBlock, "All shares have already been claimed.");
        uint256 unlockedBlock;
        if (block.number > endBlock) {
            unlockedBlock = endBlock;
        } else {
            unlockedBlock = block.number;
        }
        uint256 tempLastWithdrawalBlock = allocations[msg.sender].lastWithdrawalBlock;
        allocations[msg.sender].lastWithdrawalBlock = unlockedBlock;                    // Avoid reentrancy
        uint256 unlockedShares = allocations[msg.sender].sharePerBlock * (unlockedBlock - tempLastWithdrawalBlock);
        KNIGHT.transfer(msg.sender, unlockedShares);
    }

    /**
     * @dev Get the remaining balance of a shareholder's total outstanding shares.
     */
    function getOutstandingShares() external view returns(uint256)
    {
        return allocations[msg.sender].sharePerBlock * (endBlock - allocations[msg.sender].lastWithdrawalBlock);
    }

    /**
     * @dev Get the balance of a shareholder's claimable shares.
     */
    function getUnlockedShares() external view returns(uint256)
    {
        uint256 unlockedBlock;
        if (block.number > endBlock) {
            unlockedBlock = endBlock;
        } else {
            unlockedBlock = block.number;
        }
        return allocations[msg.sender].sharePerBlock * (unlockedBlock - allocations[msg.sender].lastWithdrawalBlock);
    }

    /**
     * @dev Get the withdrawn shares of a shareholder.
     */
    function getWithdrawnShares() external view returns(uint256)
    {
        return allocations[msg.sender].sharePerBlock * (allocations[msg.sender].lastWithdrawalBlock - startBlock);
    }

    /**
     * @dev Get the total shares of shareholder.
     */
    function getTotalShares(address shareholder) external view returns(uint256)
    {
        return allocations[shareholder].sharePerBlock * 2372500;
    }

    /**
     * @dev Emergency function to change allocations.
     */
    function emergencyChangeAllocation(address _allocation, uint256 _newSharePerBlock) external onlyOwner 
    {
        require (allocations[_allocation].friendlyKnight == false, "Can't change allocations of team members.");
        allocations[_allocation].sharePerBlock = _newSharePerBlock;
    }

}