pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2; // Maybe change this

import "./Ownable.sol";

interface RolesUsers {
    function hasEndUserAdminRights(address addr) external view returns (bool);
}

contract Whitelisted is Ownable {
    mapping(bytes32 => bool) _whitelistedUsers;
    mapping(address => bytes32) _walletToUser;

    RolesUsers private _roles;

    event AddedWhitelisted(bytes32 indexed userBytes, string user);
    event AddedWallet(bytes32 indexed user, address wallet);
    event RemovedWhitelisted(bytes32 indexed user);
    event RemovedWallet(bytes32 indexed user, address wallet);

    modifier onlyEndUserAdmin {
        require(_roles.hasEndUserAdminRights(msg.sender), "Whitelisted: You need to have end user admin rights!");
        _;
    }

    constructor(address roles) public {
        _roles = RolesUsers(roles);
    }

    function changeRolesAddress(address newRoles) public onlyOwner {
        _roles = RolesUsers(newRoles);
    }

    function _addWhitelisted(string memory user) private {
        bytes32 userBytes = getUserBytes(user);
        _whitelistedUsers[userBytes] = true;
        emit AddedWhitelisted(userBytes, user);
    }

    function _removeWhitelisted(string memory user) private {
        bytes32 userBytes = getUserBytes(user);
        _whitelistedUsers[userBytes] = false;
        emit RemovedWhitelisted(userBytes);
    }

    function _addWallet(string memory user, address wallet) private {
        bytes32 userBytes = getUserBytes(user);
        _walletToUser[wallet] = userBytes;
        emit AddedWallet(userBytes, wallet);
    }

    function _removeWallet(address wallet) private {
        bytes32 userBytes = getUserBytesFromWallet(wallet);
        delete _walletToUser[wallet];
        emit RemovedWallet(userBytes, wallet);
    }

    function addWhitelistedList(string[] memory users) public onlyEndUserAdmin {
        for (uint i = 0; i < users.length; i++) {
            _addWhitelisted(users[i]);
        }
    }


    function removeWhitelistedList(string[] memory users) public onlyEndUserAdmin {
        for (uint i = 0; i < users.length; i++) {
            _removeWhitelisted(users[i]);
        }
    }

    function addWalletList(string[] memory users, address[] memory wallets) public onlyEndUserAdmin {
        require(users.length == wallets.length, "Whitelisted: User and wallet lists must be of same length!");
        for (uint i = 0; i < wallets.length; i++) {
            _addWallet(users[i], wallets[i]);
        }
    }

    function removeWalletList(address[] memory wallets) public onlyEndUserAdmin {
        for (uint i = 0; i < wallets.length; i++) {
            _removeWallet(wallets[i]);
        }
    }

    function addWalletAndWhitelistList(string[] memory users, address[] memory wallets) public onlyEndUserAdmin {
        require(users.length == wallets.length, "Whitelisted: User and wallet lists must be of same length!");
        for (uint i = 0; i < wallets.length; i++) {
            _addWhitelisted(users[i]);
            _addWallet(users[i], wallets[i]);
        }
    }

    function getUserBytesFromWallet(address wallet) public view returns (bytes32) {
        return _walletToUser[wallet];
    }

    function getUserBytes(string memory user) public pure returns (bytes32) {
        return keccak256(abi.encode(user));
    }

    function isWhitelisted(address wallet) public view returns (bool) {
        return _whitelistedUsers[_walletToUser[wallet]];
    }

    function isWhitelistedUser(string memory user) public view returns (bool) {
        bytes32 userBytes = getUserBytes(user);
        return _whitelistedUsers[userBytes];
    }
}