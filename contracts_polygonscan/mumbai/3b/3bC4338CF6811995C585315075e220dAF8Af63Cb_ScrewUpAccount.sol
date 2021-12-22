// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Interfaces/IScrewUpAccount.sol";

contract ScrewUpAccount is Ownable ,IScrewUpAccount {

    mapping (address => address) private _links;
    string private _VaultName;

    //Event when personal account link to game account.
    event OnAccountLinked(address indexed inDappAddress, address indexed personalAddress);

    //Event when personal account unlink from game account.
    event OnAccountUnlinked(address indexed inDappAddress, address indexed personalAddress);

    constructor(string memory _name) {
        _VaultName = _name;
    }
    function getVaultName() external view virtual override returns (string memory) {
        return _VaultName;
    }
    function linkedAddressOf(address _inDappAddr) external view virtual override returns (address){
        require(_links[_inDappAddr] != address(0),"No address link to account");
        return _links[_inDappAddr];
    }
    function hasLinkAddressOf(address _inDappAddr) external view virtual override returns (bool){
         return _links[_inDappAddr] != address(0);
    }
    function isAccountLinked(address _inDappAddr,address _personalAddr) external view virtual override returns (bool){
        require(_personalAddr != address(0),"Zero or Null address is not allowed.");
        return _links[_inDappAddr] == _personalAddr;
    }

    function linkToAddress(address _inDappAddr) external virtual override {
        require(_links[_inDappAddr] == address(0),"Account already linked");
        require(msg.sender != address(0),"Zero or Null address is not allowed.");
        _links[_inDappAddr] = msg.sender;
         emit OnAccountLinked(_inDappAddr,msg.sender);
    }

    function unlinkFromAddress(address _inDappAddr) external virtual override {
        require(_links[_inDappAddr] == msg.sender,"Linked account mismatch can't unlink");
        require(msg.sender != address(0),"Zero or Null address is not allowed.");
        _links[_inDappAddr] = address(0);
        emit OnAccountUnlinked(_inDappAddr,msg.sender);
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Interface of use for all of ScrewUp NFT token.
 */
interface IScrewUpAccount {
   
    //Get real personal address by in-app address.
    function linkedAddressOf(address _inDappAddr) external view returns (address);

    //Check in-dapp address has any address linked with.
    function hasLinkAddressOf(address _inDappAddr) external view returns (bool);
   
    //Check in-dapp address has any address linked with.
    function isAccountLinked(address _inDappAddr,address _personalAddr) external view returns (bool);
   
    //Get real personal address by in-app address. Link sender address with _inDappAddr
    function linkToAddress(address _inDappAddr) external;

    //Get real personal address by in-app address. Link sender address with _inDappAddr
    function unlinkFromAddress(address _inDappAddr) external;

    //Get Vault name
    function getVaultName() external view returns (string memory);
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