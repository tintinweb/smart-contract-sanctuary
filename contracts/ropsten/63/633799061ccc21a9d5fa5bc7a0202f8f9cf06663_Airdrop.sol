/**
 *Submitted for verification at Etherscan.io on 2021-09-14
*/

/**
 *Submitted for verification at Etherscan.io on 2021-09-08
*/

// File: @openzeppelin/contracts/GSN/Context.sol
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


pragma solidity ^0.6.0;

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
contract Ownable is Context {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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



pragma solidity ^0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.6.12;

contract Airdrop is Ownable {
    // Set initial variables
    uint256 private _totalClaimed = 0;
    mapping (address => uint256) private _claimedTokens;

    // Token Address
    IERC20 beastToken  = IERC20(0xf5e929bDF7d2A4616896d80Be59724cEa46e82c7);

    function getClaimedTokens(address account) public view returns(uint256) {
        return _claimedTokens[account];
    }
    function getTotalClaimed() public view returns(uint256) {
        return _totalClaimed;
    }

    function claimTokens(address account, uint256 claimed) public onlyOwner {
        require(IERC20(beastToken).balanceOf(address(this)) >= claimed,"Insufficient Funds in claim pool wallet");
        uint256 previousClaimed = getClaimedTokens(account);
        uint256 accountClaimed = claimed + previousClaimed;
        IERC20(beastToken).transfer(account, claimed);
        _claimedTokens[account] = accountClaimed;
        _totalClaimed = _totalClaimed + accountClaimed;
    }
    
    function withdrawToken(uint amount) public {
        require(msg.sender == _owner, "Can not send without owner");
        IERC20(beastToken).transferFrom(address(this),msg.sender, amount);
    }
    
}