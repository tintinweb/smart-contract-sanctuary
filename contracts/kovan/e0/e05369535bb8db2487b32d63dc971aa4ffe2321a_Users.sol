pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2; // Maybe change this

import "./Ownable.sol";

interface RolesUsers {
    function hasEndUserAdminRights(address addr) external view returns (bool);
}

contract Users is Ownable {
    mapping(address => bytes32) _walletToUser;

    RolesUsers private _roles;

    event AddedWallet(bytes32 indexed userBytes, address wallet, string user);
    event RemovedWallet(bytes32 indexed userBytes, address wallet);

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

    function _addWallet(string memory user, address wallet) private {
        bytes32 userBytes = getUserBytes(user);
        _walletToUser[wallet] = userBytes;
        emit AddedWallet(userBytes, wallet, user);
    }

    function _removeWallet(address wallet) private {
        bytes32 userBytes = getUserBytesFromWallet(wallet);
        delete _walletToUser[wallet];
        emit RemovedWallet(userBytes, wallet);
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

    function getUserBytesFromWallet(address wallet) public view returns (bytes32) {
        return _walletToUser[wallet];
    }

    function getUserBytes(string memory user) public pure returns (bytes32) {
        return keccak256(abi.encode(user));
    }
}