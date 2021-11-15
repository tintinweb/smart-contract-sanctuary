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
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/access/Ownable.sol';

contract DarcadePartnerships is Ownable {

    mapping (string => address) private partnerVanityToAddress;
    mapping (address => bool) private token;
    mapping (string => bool) private vanityURL;
    mapping (address => address) private tokenOwner;
    mapping (address => bool) private partnerOwner;
    mapping (address => string) private partnerLogo;

    event PartnerActivated(address token, string vanityURL);
    event PartnerDeactivated(address token, string vanityURL);


    /**
     * @dev Creates a new partner
     */
    function createPartner(address _token, string memory _vanityURL, string memory _logoURL, address _tokenOwner) public onlyOwner {
        _preValidateToken(_token);
        _preValidateVanityURL(_vanityURL);

        partnerVanityToAddress[_vanityURL] = _token;
        tokenOwner[_token] = _tokenOwner;

        //partner-logo
        partnerLogo[_token] = _logoURL;

        token[_token] = true;
        vanityURL[_vanityURL] = true;
        partnerOwner[_tokenOwner] = true;

        emit PartnerActivated(_token, _vanityURL);
    }

    /**
     * @dev Deactivates a partner
     */
    function deactivatePartner(address _token, string memory _vanityURL) public onlyOwner {
        partnerOwner[getTokenOwner(_token)] = false;
        token[_token] = false;
        vanityURL[_vanityURL] = false;
        emit PartnerDeactivated(_token, _vanityURL);
    }

    function getTokenOwner(address _token) public view returns (address) {
        return tokenOwner[_token];
    }

    function setPartnerLogo(address _token, string memory _logoURL) public onlyOwner {
        partnerLogo[_token] = _logoURL;
    }

    function getPartnerLogo(address _token) public view returns (string memory) {
        return partnerLogo[_token];
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

    function isPartnerOwner(address _owner) public view returns (bool) {
        return partnerOwner[_owner];
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

