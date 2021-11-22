/**
 *Submitted for verification at BscScan.com on 2021-11-22
*/

// File: BWT/Ownable.sol

pragma solidity ^0.7.4;
// "SPDX-License-Identifier: Apache License 2.0"

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
abstract contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * @notice Renouncing to ownership will leave the contract without an owner.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
// File: BWT/IERC20.sol

pragma solidity ^0.7.4;


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
// File: BWT/DirectSwap.sol

pragma solidity ^0.7.6;




contract DirectSwap is Ownable {
    
    IERC20 public _oldToken;
    IERC20 public _newToken;
    address public _finance;

    constructor(address oldTokenAdddress, 
                address newTokenAddress,
                address finance) {
        _oldToken = IERC20(oldTokenAdddress);
        _newToken = IERC20(newTokenAddress);
        _finance = finance;
    }

    function upgradeTokens() external {
        require(_oldToken.balanceOf(msg.sender) > 0, "No tokens to swap on user balance");
        require(_oldToken.balanceOf(msg.sender) <= _oldToken.allowance(msg.sender, address(this)));
        uint256 userBalance = _oldToken.balanceOf(msg.sender);
        _oldToken.transferFrom(msg.sender, _finance, userBalance);
        _newToken.transfer(msg.sender, userBalance);
    }
    
    function withdrawNew(uint256 amount) external onlyOwner {
        _newToken.transfer(_finance, amount);
    }
}