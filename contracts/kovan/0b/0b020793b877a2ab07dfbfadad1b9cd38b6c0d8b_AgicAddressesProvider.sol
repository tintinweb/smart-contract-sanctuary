/**
 *Submitted for verification at Etherscan.io on 2021-04-15
*/

// SPDX-License-Identifier: MIT
// File: contracts/interface/IAgicAddressesProvider.sol



pragma solidity ^0.6.8;

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

    function getAgicEquityCard() external view returns (address);

    function setAgicEquityCard(address agicEquityCard) external;

    //Not used yet
    function getExtendAddressesProvider() external view returns (address);

    //Not used yet
    function setExtendAddressesProvider(address extend) external;


}

// File: @openzeppelin/contracts/GSN/Context.sol



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

// File: @openzeppelin/contracts/access/Ownable.sol



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
    address private _owner;

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

// File: contracts/support/AgicAddressesProvider.sol


pragma solidity ^0.6.8;



/**
@title AgicAddressesProvider interface
@notice provides the interface to fetch the Agic address
 */

contract AgicAddressesProvider is IAgicAddressesProvider, Ownable {

    address payable private _agicFundPool;

    address private _agic;

    address private _agicEquityCard;

    address private _extendAddressesProvider;

    mapping(address => uint256) private _whiteListIndex;

    address[] private _whiteList;

    constructor() public {
        _whiteList.push(address(0));
    }

    function getAgicFundPoolWhiteList() public view override returns (address[] memory){
        return _whiteList;
    }

    function verifyFundPoolWhiteList(address aecAddress) override public view returns (bool){
        return _whiteListIndex[aecAddress] != 0;
    }

    function addAgicFundPoolWhiteList(address aecAddress) public override onlyOwner {
        require(_whiteListIndex[aecAddress] != 0, "Address already exists");
        _whiteListIndex[aecAddress] = _whiteList.length;
        _whiteList.push(aecAddress);
    }

    function subAgicFundPoolWhiteList(address aecAddress) public override onlyOwner {
        uint256 index = _whiteListIndex[aecAddress];
        if (index != 0) {
            delete _whiteList[index];
            delete _whiteListIndex[aecAddress];
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

    function getAgicEquityCard() public view override returns (address){
        return _agicEquityCard;
    }

    function setAgicEquityCard(address agicEquityCard) public override onlyOwner {
        subAgicFundPoolWhiteList(_agicEquityCard);
        addAgicFundPoolWhiteList(agicEquityCard);
        _agicEquityCard = agicEquityCard;
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