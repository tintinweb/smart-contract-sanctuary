/**
 *Submitted for verification at polygonscan.com on 2021-07-02
*/

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


interface IRouter {
    struct RouteInfo {
        address router;
        address[] path;
    }

    function getSwapRoute(address _fromToken, address _toToken)
        external
        view
        returns (address _router, address[] memory _path);
}







contract Router is IRouter, Ownable {
    mapping(address => mapping(address => RouteInfo)) public routes;

    function addRoute(
        address _from,
        address _to,
        address _router,
        address[] calldata path
    ) external onlyOwner {
        require(_from != address(0), "Src token is invalid");
        require(_to != address(0), "Dst token is invalid");
        require(_from != _to, "Src token must be diff from Dst token");
        require(_router != address(0), "Router is invalid");
        require(path[0] == _from, "Route must start with src token");
        require(path[path.length - 1] == _to, "Route must end with dst token");
        RouteInfo memory _info = RouteInfo(_router, path);
        routes[_from][_to] = _info;
    }

    function removeRoute(address _from, address _to) external onlyOwner {
        address[] memory _empty;
        routes[_from][_to] = RouteInfo(address(0), _empty);
    }

    function getSwapRoute(address _fromToken, address _toToken)
        external
        view
        override
        returns (address _router, address[] memory _path)
    {
        RouteInfo storage _info = routes[_fromToken][_toToken];
        _router = _info.router;
        _path = _info.path;
    }
}