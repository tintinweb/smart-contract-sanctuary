/**
 *Submitted for verification at Etherscan.io on 2021-11-30
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

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

interface ITokenMover {
    function isOperator(address _operator) external view returns(bool);
    function transferERC20(address currency, address from, address to, uint amount) external;
    function transferERC721(address currency, address from, address to, uint tokenId) external;
}

contract AppRole is Ownable {
    address[] private _apps;
    mapping(address => bool) internal _isApp;

    modifier onlyApp() {
        require(_isApp[_msgSender()], "Caller is not the app");
        _;
    }

    function getAllApps() public view returns(address[] memory) {
        return _apps;
    }

    function isApp(address _app) public view returns(bool) {
        return _isApp[_app];
    }

    function addApp(address _app) public onlyOwner {
        require(!_isApp[_app], "Address already added as app");
        _apps.push(_app);
        _isApp[_app] = true;
    }

    function removeApp(address _app) public onlyOwner {
        require(_isApp[_app], "Address is not added as app");
        _isApp[_app] = false;
        for (uint256 i = 0; i < _apps.length; i++) {
            if (_apps[i] == _app) {
                _apps[i] = _apps[_apps.length - 1];
                _apps.pop();
                break;
            }
        }
    }
}

// This contract enables users to tip their preferred creators
contract TipManagerv2 is Ownable, AppRole {

    ITokenMover public immutable tokenMover;
    address public immutable PKN;
    address public pokmiWallet;

    event tipSent(address user, address creator, uint256 amount, uint256 creatorFeeBIPS);

    constructor(address _PKN, ITokenMover _tokenMover, address _pokmiWallet) {
        PKN = _PKN;
        tokenMover = _tokenMover;
        pokmiWallet = _pokmiWallet;
    }

    function payTip(address user, address creator, uint256 amount, uint256 creatorFeeBIPS) external onlyApp() {
        uint256 amountForCreator = (amount * creatorFeeBIPS) / 10000;

        tokenMover.transferERC20(PKN, user, creator, amountForCreator);
        tokenMover.transferERC20(PKN, user, pokmiWallet, amount - amountForCreator);

        emit tipSent(user, creator, amount, creatorFeeBIPS);
    }

    function updatePokmiWallet(address newWallet) external onlyOwner() {
        pokmiWallet = newWallet;
    }
}