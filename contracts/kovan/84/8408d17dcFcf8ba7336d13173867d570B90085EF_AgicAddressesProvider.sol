// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "./interface/IAgicAddressesProvider.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
@title AgicAddressesProvider interface
@notice provides the interface to fetch the Agic address
 */

contract AgicAddressesProvider is IAgicAddressesProvider, Ownable {

    address payable private _agicFundPool;

    address private _agic;

    address private _agicInterestCard;

    address private _extendAddressesProvider;

    mapping(address => uint256) private _whiteListIndex;

    address[] private _whiteList;

    constructor() {
        _whiteList.push();
    }

    function getAgicFundPoolWhiteList() public view override returns (address[] memory){
        return _whiteList;
    }

    function verifyFundPoolWhiteList(address aicAddress) override public view returns (bool){
        return _whiteListIndex[aicAddress] != 0;
    }

    function addAgicFundPoolWhiteList(address aicAddress) public override onlyOwner {
        require(_whiteListIndex[aicAddress] == 0, "Address already exists");
        _whiteListIndex[aicAddress] = _whiteList.length;
        _whiteList.push(aicAddress);
    }

    function subAgicFundPoolWhiteList(address aicAddress) public override onlyOwner {
        uint256 index = _whiteListIndex[aicAddress];
        if (index != 0) {
            delete _whiteList[index];
            delete _whiteListIndex[aicAddress];
            _whiteList.pop();
        }
    }

    function getAgicFundPool() public view override returns (address payable){
        return _agicFundPool;
    }

    function setAgicFundPool(address payable pool) public override onlyOwner {
        _agicFundPool = pool;
    }

    function getAgic() public view override returns (address){
        return _agic;
    }

    function setAgic(address agic) public override onlyOwner {
        _agic = agic;
    }

    function getAgicInterestCard() public view override returns (address){
        return _agicInterestCard;
    }

    function setAgicInterestCard(address agicInterestCard) public override onlyOwner {
        _agicInterestCard = agicInterestCard;
    }

    //Not used yet
    function getExtendAddressesProvider() public view override returns (address){
        return _extendAddressesProvider;
    }

    //Not used yet
    function setExtendAddressesProvider(address extend) public override onlyOwner {
        _extendAddressesProvider = extend;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

/**
@title AgicAddressesProvider interface
@notice provides the interface to fetch the Agic address
 */

interface IAgicAddressesProvider {

    function getAgicFundPoolWhiteList() external view returns (address[] memory);

    function verifyFundPoolWhiteList(address) external view returns (bool);

    function addAgicFundPoolWhiteList(address) external;

    function subAgicFundPoolWhiteList(address) external;

    function getAgicFundPool() external view returns (address payable);

    function setAgicFundPool(address payable pool) external;

    function getAgic() external view returns (address);

    function setAgic(address agic) external;

    function getAgicInterestCard() external view returns (address);

    function setAgicInterestCard(address agicInterestCard) external;

    //Not used yet
    function getExtendAddressesProvider() external view returns (address);

    //Not used yet
    function setExtendAddressesProvider(address extend) external;


}

// SPDX-License-Identifier: MIT

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

