// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.6.12;


interface IWSProxy {
    function initialize(address _implementation, address _admin, bytes calldata _data) external;
    function upgradeTo(address _proxy) external;
    function upgradeToAndCall(address _proxy, bytes calldata data) external payable;
    function changeAdmin(address newAdmin) external;
    function admin() external returns (address);
    function implementation() external returns (address);
}

interface IWSController {
    function getLogicForPair() external view returns(address);
    function getCurrentAdmin() external view returns(address);
    function updatePairLogic(address _logic) external;
    function updateCurrentAdmin(address _newAdmin) external;
    function updateProxyPair(address _proxy) external;
    function setAdminForProxy(address _proxy) external;
}

interface IWSImplementation {
	function getImplementationType() external pure returns(uint256);
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
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
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
        require(_owner == msg.sender, "Ownable: caller is not the owner");
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

contract WSController is Ownable, IWSController {
    address public pairLogic;
    address public currentAdmin;

    /*
    * @dev Type variable:
    * 2 - Pair
    */
    uint256 constant public PAIR_TYPE = 2;

    event NewPairLogic(address indexed logic);
    event NewAdmin(address indexed adminAddress);
    event UpdateProxy(address indexed proxyAddress, address newLogic);
    event ChangeAdmin(address indexed proxyAddress, address newAdmin);

    constructor(address _pairLogic) public {
        require(_pairLogic != address(0), "WSController: Wrong pair logic address");
        currentAdmin = address(this);
        pairLogic = _pairLogic;
    }


    function updatePairLogic(address _logic) external override onlyOwner {
        pairLogic = _logic;
        emit NewPairLogic(_logic);
    }

    function updateCurrentAdmin(address _newAdmin) external override onlyOwner {
        currentAdmin = _newAdmin;
        emit NewAdmin(_newAdmin);
    }

    function updateProxyPair(address _proxy) external override {
        require(IWSImplementation(IWSProxy(_proxy).implementation()).getImplementationType() == PAIR_TYPE, "WSController: Wrong pair proxy for update.");
        IWSProxy(_proxy).upgradeTo(pairLogic);
        emit UpdateProxy(_proxy, pairLogic);
    }

    function setAdminForProxy(address _proxy) external override {
        IWSProxy(_proxy).changeAdmin(currentAdmin);
        emit ChangeAdmin(_proxy, currentAdmin);
    }

    function getLogicForPair() external view override returns(address) {
        return pairLogic;
    }

    function getCurrentAdmin() external view override returns(address){
        return currentAdmin;
    }

}