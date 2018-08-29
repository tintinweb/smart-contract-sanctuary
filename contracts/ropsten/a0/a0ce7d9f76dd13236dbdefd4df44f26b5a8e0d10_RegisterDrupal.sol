pragma solidity ^0.4.24;

contract RegisterDrupal {

    // Mapping that matches Drupal generated hash with Ethereum Account address.
    mapping (bytes32 => address) _accounts;

    // Event allowing listening to newly signed Accounts (?)
    event AccountCreated (address indexed from, bytes32 hash);

    address _registryAdmin;

    // Allowed to administrate accounts only, not everything
    address _accountAdmin;

    // If a newer version of this registry is available, force users to use it
    bool _registrationDisabled;

    // Register Account
    function newUser(bytes32 hash) public {

        if (_accounts[hash] == msg.sender) {
            // Hash all ready registered to address.
            revert(&#39;Hash all ready registered to address.&#39;);
        }
        else if (_accounts[hash] > 0) {
            // Hash all ready registered to different address.
            revert(&#39;Hash all ready registered to different address.&#39;);
        }
        else if (hash.length > 32) {
            // Hash too long
            revert(&#39;Hash too long.&#39;);

        }
        else if (_registrationDisabled){
            // Registry is disabled because a newer version is available
            revert(&#39;Registry is disabled because a newer version is available.&#39;);
        }
        else {
            _accounts[hash] = msg.sender;
            emit AccountCreated(msg.sender, hash);
        }
    }

    // Validate Account
    // This function is actually not necessary if you implement Event handling in PHP.
    function validateUserByHash (bytes32 hash) public constant returns (address result) {
        return _accounts[hash];
    }

    function contractExists () public pure returns (bool result){
        return true;
    }

    // Administrative below
    constructor() public {
        _registryAdmin = msg.sender;
        _accountAdmin = msg.sender; // can be changed later
        _registrationDisabled = false;
    }

    function adminSetRegistrationDisabled(bool registrationDisabled) public {
        // currently, the code of the registry can not be updated once it is
        // deployed. if a newer version of the registry is available, account
        // registration can be disabled
        if (msg.sender == _registryAdmin) {
            _registrationDisabled = registrationDisabled;
        }
    }

    function adminSetAccountAdministrator(address accountAdmin) public {
        if (msg.sender == _registryAdmin) {
            _accountAdmin = accountAdmin;
        }
    }

    function adminRetrieveDonations() public {
        if (msg.sender == _registryAdmin) {
            _registryAdmin.transfer(address(this).balance);
        }
    }

    function adminDeleteRegistry() public {
        if (msg.sender == _registryAdmin) {
            selfdestruct(_registryAdmin); // this is a predefined function, it deletes the contract and returns all funds to the admin&#39;s address
        }
    }

}