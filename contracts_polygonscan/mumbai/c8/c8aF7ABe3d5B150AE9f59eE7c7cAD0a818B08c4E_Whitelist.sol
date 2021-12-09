// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.6;

import { Pausable } from "@openzeppelin/contracts/security/Pausable.sol";
import { Ownable } from '@openzeppelin/contracts/access/Ownable.sol';

/**
    @notice Whitelist for Days.WTF free fair mint.
    @dev Design goal: track the referrers for each account, and ability to overwrite the referrer count to intervene in case of abuse.
    @author @thesved https://days.wtf/
*/
contract Whitelist is Pausable, Ownable {
    struct WhitelistEntry {
        address referrer;   // who referred this address
        address[] referred; // list of addresses that were referred by this address
        int256 baseLevel;   // this will be added to the number of referred addresses
        bool active;        // is the whitelist active for this address
    }


    mapping (address => WhitelistEntry) private whitelistList;
    uint256 public whitelistLength;    // number of whitelisted addresses
    uint256 public maxWhitelistLength; // max number of whitelist entries, 0 means unlimited
    uint256 public whitelistEndDate;   // end date of the whitelist, 0 means no end date
    address public offchainSigner;     // address of the offchain signer


    event Modified(address indexed account, bool isActive, int256 baseLevel);
    event Activated(address indexed account, address indexed referrer);


    /**
        @notice When Whitelist is active.
        @dev Whitelist is active when it is not paused, not finished, nor full.
    */
    modifier whenWhitelistActive {
        require(whitelistEndDate == 0 || block.timestamp <= whitelistEndDate, "Whitelist is closed.");
        require(maxWhitelistLength == 0 || whitelistLength < maxWhitelistLength, "Whitelist is full.");
        require(paused() == false, "Whitelist is paused.");
        _;
    }

    /**
        @dev Constructor.
        @param _maxWhitelistLength The maximum number of addresses that can be whitelisted. 0 means no limit.
        @param _whitelistEndDate The date when the whitelist will end. 0 means no end date.
    */
    constructor(uint256 _maxWhitelistLength, uint256 _whitelistEndDate)
    {
        maxWhitelistLength = _maxWhitelistLength;
        whitelistEndDate = _whitelistEndDate;
        _pause(); // start paused
    }


    /** 
        @notice Pause or unpause the contract
        @param pause boolean true to pause, false to unpause
    */
    function setPause(bool pause) public onlyOwner {
        if (pause) {
            _pause();
        } else {
            _unpause();
        }
    }


    /**
        @notice Set whitelist parameters.
        @dev When paused and only the owner can change the whitelist parameters.
        @param _maxWhitelistLength The maximum number of addresses that can be whitelisted. 0 means no limit.
        @param _whitelistEndDate The date when the whitelist will end. 0 means no end date.
    */
    function setWhitelistParameters(uint256 _maxWhitelistLength, uint256 _whitelistEndDate) 
        public
        onlyOwner
        whenPaused
    {
        maxWhitelistLength = _maxWhitelistLength;
        whitelistEndDate = _whitelistEndDate;
    }


    /**
        @notice Is the whitelist finished?
        @return true if the whitelist is finished, false otherwise.
     */
    function isFinished() public view returns (bool) {
        return whitelistEndDate != 0 && block.timestamp >= whitelistEndDate 
            || maxWhitelistLength != 0 && whitelistLength >= maxWhitelistLength;
    }


    /** 
        @dev Returns whether the given account is whitelisted.
        @param _account The account to check.
    */
    function isWhitelisted(address _account)
        public
        view
        returns (bool)
    {
        return whitelistList[_account].active;
    }


    /** 
        @notice Returns the number of referred addresses for an account.
        @dev Uses baseLevel to offset the number of referred addresses. Used to whitelist friendly OG NFT projects.
        @param _account The address of the account.
        @return Referred addresses offset by baseLevel. Minimum level is 0.
    */
    function getReferredCount(address _account)
        public
        view
        returns (uint256)
    {
        int256 ret = whitelistList[_account].baseLevel + int256(whitelistList[_account].referred.length);

        if (ret <= 0)
            return 0;
        else
            return uint256(ret);
    }


    /**
        @notice Activate the whitelist for the _msgSender()
        @dev Activation can only be done if the whitelist is not full and the whitelist is not closed or not stopped.
        @param _referrer The referrer of the account
    */
    function activate(address _referrer)
        public 
        whenWhitelistActive
    {
        require(!whitelistList[_msgSender()].active, "Account already active");

        whitelistList[_msgSender()].active = true;
        whitelistLength++;

        // FIXME: change array to mapping, to avoid duplicate entries
        // CHECK: referrer can't be the same address as the account
        if (_referrer != address(0) && _referrer != _msgSender()) {
            whitelistList[_msgSender()].referrer = _referrer;
            whitelistList[_referrer].referred.push(_msgSender());
        }

        emit Activated(_msgSender(), _referrer);
    }

    /**
        @notice Alias for `activate(address _referrer)` function with zero address as referrer.
    */
    function activate()
        public
    {
        activate(address(0));
    }


    /**
        @notice Set offchain signer address.
        @dev Only the owner can set the offchain signer address.
    */
    function setOffchainSigner(address _offchainSigner)
        public
        onlyOwner
    {
        offchainSigner = _offchainSigner;
    }

    /**
        @notice Activate a whitelist account with offchain signature.
        @param _referrer The referrer of the account
        @param _baseLevel The base level of the account.
        @param _signature The offchain signature.
    */
    function activateOffchain(address _referrer, int256 _baseLevel, bytes memory _signature)
        public 
    {
        // validate offchain signature
        require(offchainSigner != address(0), "Offchain signer is not set.");
        require(offchainSigner == recover(keccak256(abi.encodePacked(_msgSender(), uint256(_baseLevel))), _signature), "Invalid signature.");

        // set base level for the account
        whitelistList[_msgSender()].baseLevel = _baseLevel;

        // activate the account
        activate(_referrer);
    }


    /**
        @notice Internal function to set the whitelist information for a given account.
        @param _address The account to set the whitelist information for. Shouldn't be 0 address.
        @param _active Whether the account is active.
        @param _baseLevel The base level of the account.
    */
    function _setWhitelist(address _address, bool _active, int256 _baseLevel)
        internal
    {
        whitelistList[_address].active = _active;
        whitelistList[_address].baseLevel = _baseLevel;

        emit Modified(_msgSender(), _active, _baseLevel);
    }


    /**
        @notice Set the whitelist information for a given account.
        @dev Only the owner can set the whitelist information for a given account.
        @param _address The account to set the whitelist information for.
        @param _active Whether the account is active.
        @param _baseLevel The base level of the account.
    */
    function setWhitelist(address _address, bool _active, int256 _baseLevel)
        external
        onlyOwner
    {
        require(_address != address(0), "Address cannot be 0");
        require(_active == false || maxWhitelistLength == 0 || whitelistLength < maxWhitelistLength, "Whitelist is full.");

        if (_active && !whitelistList[_address].active) whitelistLength++;
        else if (!_active && whitelistList[_address].active) whitelistLength--;

        _setWhitelist(_address, _active, _baseLevel);
    }


    /**
        @notice Sets the whitelist for multiple accounts.
        @dev Only the owner can set the whitelist for multiple accounts.
        @param _addresses The addresses to set the whitelist information for.
        @param _active The active status of the accounts.
        @param _baseLevel The base level of the accounts.
    */
    function setManyWhitelist(address[] calldata _addresses, bool _active, int256 _baseLevel)
        external
        onlyOwner
    {
        int256 delta = 0;

        for (uint256 i = 0; i < _addresses.length; i++) {
            if (_addresses[i] == address(0)) continue;

            if (_active && !whitelistList[_addresses[i]].active) delta++;
            else if (!_active && whitelistList[_addresses[i]].active) delta--;

            _setWhitelist(_addresses[i], _active, _baseLevel);
        }

        whitelistLength = uint256(int256(whitelistLength) + delta);
        require(maxWhitelistLength == 0 || whitelistLength <= maxWhitelistLength, "Whitelist is full.");
    }


    /**
    * @notice Recover signer address from a message by using its signature
    * @param _hash bytes32 message, the hash is the signed message. What is recovered is the signer address.
    * @param _sig bytes signature
    */
    function recover(bytes32 _hash, bytes memory _sig) public pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        //Check the signature length
        if (_sig.length != 65) {
            return (address(0));
        }

        // Divide the signature in r, s and v variables
        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }

        // Version of signature should be 27 or 28, but 0 and 1 are also possible versions
        if (v < 27) {
            v += 27;
        }

        // If the version is correct return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(_hash, v, r, s);
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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
        return msg.data;
    }
}