/**
 *Submitted for verification at BscScan.com on 2021-07-26
*/

/**
 *Submitted for verification at BscScan.com on 2021-07-24
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/**
 * WatchDog Whitelist
 * Amounts based on a 6/26 snapshot of MoonRetreiver ($FETCH) holders
 */

/**
 * Provides ownable & authorized contexts
 */
abstract contract Auth {
    address owner;
    mapping (address => bool) private authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    /**
     * Function modifier to require caller to be contract owner
     */
    modifier onlyOwner() {
        require(isOwner(msg.sender)); _;
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier authorized() {
        require(isAuthorized(msg.sender)); _;
    }

    /**
     * Authorize address. Any authorized address
     */
    function authorize(address adr) public authorized {
        authorizations[adr] = true;
        emit Authorized(adr);
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
        emit Unauthorized(adr);
    }

    /**
     * Check if address is owner
     */
    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    /**
     * Transfer ownership to new address. Caller must be owner.
     */
    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
    event Authorized(address adr);
    event Unauthorized(address adr);
}

interface IWhitelister {
    function amount(address account) external view returns (uint);
}

contract WatchDogWhitelist is Auth,IWhitelister {
    mapping(address => uint) public _whitelist;
    
    constructor() Auth(msg.sender) {}
    
    function amount(address account) external view override returns (uint) {
        return _whitelist[account];
    }

    function whitelist(address account, uint _amount) external authorized {
        _whitelist[account] = _amount;
    }
    
    function whitelistBatch(address[] calldata accounts, uint[] calldata amounts) external authorized {
        require(accounts.length == amounts.length, "accounts and amounts different length");

        for (uint i = 0; i < accounts.length; i++) {
            _whitelist[accounts[i]] = amounts[i];
        }
    }

}