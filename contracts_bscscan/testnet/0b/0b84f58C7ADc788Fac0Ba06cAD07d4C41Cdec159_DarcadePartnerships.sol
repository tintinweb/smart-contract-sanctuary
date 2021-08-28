/**
 *Submitted for verification at BscScan.com on 2021-08-27
*/

// File: @openzeppelin/contracts/GSN/Context.sol

pragma solidity ^0.5.0;

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
contract Context {
    // Empty internal constructor, to prevent people from mistakenly deploying
    // an instance of this contract, which should be used via inheritance.
    constructor () internal { }
    // solhint-disable-previous-line no-empty-blocks

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// File: @openzeppelin/contracts/ownership/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
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
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: blockchain/contracts/DarcadePartnerships.sol

pragma solidity ^0.5.0;


contract DarcadePartnerships is Ownable {

    mapping (string => address) private partnerVanityToAddress;
    mapping (address => bool) private token;
    mapping (string => bool) private vanityURL;
    mapping (address => address) private tokenOwner;

    event PartnerActivated(address, string);
    event PartnerDeactivated(address, string);


    /**
     * @dev Creates a new partner
     */
    function createPartner(address _token, string memory _vanityURL, address _tokenOwner) public onlyOwner {
        _preValidateToken(_token);
        _preValidateVanityURL(_vanityURL);

        partnerVanityToAddress[_vanityURL] = _token;
        tokenOwner[_token] = _tokenOwner;

        token[_token] = true;
        vanityURL[_vanityURL] = true;

        emit PartnerActivated(_token, _vanityURL);
    }

    /**
     * @dev Deactivates a partner
     */
    function deactivatePartner(address _token, string memory _vanityURL) public onlyOwner {
        token[_token] = false;
        vanityURL[_vanityURL] = false;
        emit PartnerDeactivated(_token, _vanityURL);
    }

    function getTokenOwner(address _token) public view returns (address) {
        return tokenOwner[_token];
    }

    function getPartnerByVanityURL(string memory _vanityURL) public view returns (address) {
        return partnerVanityToAddress[_vanityURL];
    }

    /**
     * @dev Checks if the partner is currenlty active
     */
    function isPartnerActive(address _token) public view returns (bool) {
        return token[_token];
    }

    function _preValidateToken(address _token) private view {
        require(token[_token] != true, "This Partner is already active!");
    }

    function _preValidateVanityURL(string memory _vanityURL) private view {
        require(vanityURL[_vanityURL] != true, "The Vanity URL already Exists!");
    }

    function doesVanityURLExist(string memory _vanityURL) public view returns (bool) {
        return vanityURL[_vanityURL];
    }

}