//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
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
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/// @title PrivateSaleDCIP Contract

interface IDCIP {
    function transfer(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function decimals() external pure returns (uint8);
}

contract OtcSale is Ownable {
    IDCIP public token;
    uint256 public totalBNBEarned;
    uint256 public minimumDepositBNBAmount = 1 wei;
    uint256 public maximumDepositBNBAmount = 100000000 ether;
    uint256 public tokenRate;
    address private updater;

    constructor(IDCIP _tokenAddress, address _updater) {
        token = _tokenAddress;
        tokenRate = 999999999999999;
        updater = _updater;
    }

    function buy() external payable returns (bool) {
        require(tokenRate > 1, 'Invalid tokenPrice');
        require(
            msg.value >= minimumDepositBNBAmount && msg.value <= maximumDepositBNBAmount,
            'Purchase is too small or big'
        );
        // _rate.mul(10**uint256(token.decimals())).div(10**18);
        uint256 tokenAmount = ((msg.value * tokenRate) / ((10**18))) * (10**9);

        require(tokenAmount > 0, 'You need to buy at least 1 DCIP');
        require(token.balanceOf(address(this)) >= tokenAmount, 'Not enough DCIP available for sale'); // Enough DCIP balance for sale

        totalBNBEarned = totalBNBEarned + msg.value;
        token.transfer(msg.sender, tokenAmount);
        emit Bought(msg.sender, tokenAmount);
        return true;
    }

    function getTokenRate() public view returns (uint256) {
        return tokenRate;
    }

    function setUpdateAccount(address _updater) public onlyOwner returns (bool) {
        updater = _updater;
        return true;
    }

    function setTokenPrice(uint256 _rate) public returns (uint256) {
        require(msg.sender == updater, 'Address is unauthorized');
        require(_rate > 0, 'Rate must be higher than 0');
        tokenRate = _rate;
        return tokenRate;
    }

    function withdrawDCIP() external onlyOwner {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }

    function withdrawBNB() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function getBNBEarnedAmount() external view returns (uint256) {
        return totalBNBEarned;
    }

    event Bought(address indexed user, uint256 amount);
}

