/**
 *Submitted for verification at Etherscan.io on 2021-08-18
*/

pragma solidity 0.6.12;

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

abstract contract Context {
     function _msgSender() internal view returns (address) {
         return msg.sender;
     }
 }

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
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface ISPAMintAdapter {
    event AuthorizeAddress(address addressToAdd);
    event DeauthorizeAddress(address addressToBan);

    function isAuthorized(address addressToTest) external view returns (bool);
    function authorizeAddress(address addressToAdd) external;
    function deauthorizeAddress(address addresstoBan) external;

}


contract SPAMintAdapter is Ownable, ISPAMintAdapter {

    mapping(address => bool) public authorizedToMint;

    event AuthorizeAddress(address addressToAdd);
    event DeauthorizeAddress(address addressToBan);

    constructor(address initUSDsAddr) public {
        authorizedToMint[initUSDsAddr] = true;
    }


    function isAuthorized(address addressToTest) public view override returns (bool) {
        return authorizedToMint[addressToTest];
    }


    function authorizeAddress(address addressToAdd) public override onlyOwner {
        require(authorizedToMint[addressToAdd] == false, "SPAMintAdapter: address has been autthorized");
        authorizedToMint[addressToAdd] = true;
    }

    function deauthorizeAddress(address addresstoBan) public override onlyOwner {
        require(authorizedToMint[addresstoBan] == true, "SPAMintAdapter: address is not autthorized");
        authorizedToMint[addresstoBan] = false;
    }

}