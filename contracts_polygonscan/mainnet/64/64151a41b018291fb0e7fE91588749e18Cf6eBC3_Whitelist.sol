/**
 *Submitted for verification at polygonscan.com on 2021-09-23
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
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
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

/**
* @title Whitelist that grants access to no cooldown on {TokenSale.sol}
*/
contract Whitelist is Ownable {
    
    // Cap stuff
    uint256 internal constant CAP = 10_000;
    uint256 public counter;

    address tokenSale;
    
    mapping(address => bool) whitelist;
    
    event AddedToWhitelist(address indexed account);
    event AddedToWhitelistInBatch(address[] indexed accounts);
    event RemovedFromWhitelist(address indexed account);
    event RemovedFromWhitelistInBatch(address[] indexed accounts);

    modifier onlySaleOrOwner() {
        require(msg.sender == tokenSale || msg.sender == owner());
        _;
    }

    function setTokenSale(address _tokenSale) external onlyOwner() {
        tokenSale = _tokenSale;
    }

    function addToWhitelist(address _address) external onlyOwner() {
        require(counter < CAP);
        require(_address != address(0), "ERR_INVALID_ADDRESS");
        whitelist[_address] = true;
        counter++;
        emit AddedToWhitelist(_address);
    }

    function addToWhitelistBatch(address[] memory _addresses)
        external
        onlyOwner()
    {
        require(counter + _addresses.length <= CAP);
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = true;
        }
        counter += _addresses.length;
        emit AddedToWhitelistInBatch(_addresses);
    }

    function removeFromWhitelist(address _address) external onlySaleOrOwner() {
        require(_address != address(0), "ERR_INVALID_ADDRESS");
        whitelist[_address] = false;
        emit RemovedFromWhitelist(_address);
    }

    function removeFromWhitelistBatch(address[] memory _addresses)
        external
        onlyOwner()
    {
        for (uint256 i = 0; i < _addresses.length; i++) {
            whitelist[_addresses[i]] = false;
        }
        emit RemovedFromWhitelistInBatch(_addresses);
    }

    function isWhitelisted(address _address) external view returns (bool) {
        return whitelist[_address];
    }
}