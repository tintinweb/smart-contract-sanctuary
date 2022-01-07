// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Attestations is Ownable {
    uint256 MAX_INT = 2**256 - 1;

    struct Provider {
        address addr;
        string name;
        string did;
        string endpoint;
        bool suspended;
    }

    struct Attestation {
        address provider;
        string did;
        uint256 block;
        uint256 timestamp;
    }

    mapping (address => Provider) public providers;
    mapping (address => Attestation[]) public attestations;

    mapping (address => mapping (address => Attestation)) private pending;

    event UpdateProvider(address indexed provider);
    event Issue(address indexed user, address indexed provider);
    event Revoke(address indexed user, address indexed provider);

    modifier onlyProvider() {
        require(providers[msg.sender].addr != address(0), "caller is not a provider");
        require(!providers[msg.sender].suspended, "provider is suspended");
        _;
    }

    constructor() {}

    function indexOf(address _user, address _provider) internal view returns(uint256) {
        uint256 length = attestations[_user].length;

        for (uint256 i = 0; i < length; ++i) {
            if (attestations[_user][i].provider == _provider) return i;
        }

        return MAX_INT;
    }

    function exists(address _user, address _provider) public view returns(bool) {
        return indexOf(_user, _provider) != MAX_INT;
    }

    function isPending(address _user, address _provider) public view returns(bool) {
        return pending[_user][_provider].provider != address(0);
    }

    function issue(address _user, address _provider) internal {
        require(isPending(_user, _provider), "no pending attestation");

        attestations[_user].push(pending[_user][_provider]);
        delete pending[_user][_provider];

        emit Issue(_user, _provider);
    }

    function revoke(address _user, address _provider) internal {
        if (isPending(_user, _provider)) {
            delete pending[_user][_provider];
            return;
        }

        uint256 index = indexOf(_user, _provider);
        require(index != MAX_INT, "attestation does not exist");

        delete attestations[_user][index];

        emit Revoke(_user, _provider);
    }

    // ChainLink AnyApi call
    // function callVerification(address _user) internal {
    function callVerification() internal pure {
        // @todo: implement chainlink verification
        //        - add `address _user` as input variable
        //        - remove `pure` from function keywords
        revert("ChainLink verification not implemented yet");
    }

    // Add or modify an identity provider
    function registerProvider(
        address _addr,
        string calldata _name,
        string calldata _did,
        string calldata _endpoint
    ) external onlyOwner {
        providers[_addr] = Provider({
            addr: _addr,
            name: _name,
            did: _did,
            endpoint: _endpoint,
            suspended: false
        });

        emit UpdateProvider(_addr);
    }

    function suspendProvider(address _addr) external onlyOwner {
        require(providers[_addr].addr == _addr, "provider not registered");
        providers[_addr].suspended = true;

        emit UpdateProvider(_addr);
    }

    // Register attestation
    function register(address _user, string calldata _did, bool _verify) external onlyProvider {
        require(!exists(_user, msg.sender), "attestation already exists");
        require(!isPending(_user, msg.sender), "attestation already pending");

        pending[_user][msg.sender] = Attestation({
            provider: msg.sender,
            did: _did,
            block: block.number,
            timestamp: block.timestamp
        });

        if (_verify) callVerification();
    }

    // Revoke attestation by identity provider
    function unregister(address _user) external onlyProvider {
        revoke(_user, msg.sender);
    }

    // Verify attestation using ChainLink
    function verify(address _user) public view onlyProvider {
        require(isPending(_user, msg.sender), "no pending attestation");
        callVerification();
    }

    // Confirm attestation by user
    function confirm(address _provider) external {
        issue(msg.sender, _provider);
    }

    // Revoke attestation by user
    function revoke(address _provider) external {
        revoke(msg.sender, _provider);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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