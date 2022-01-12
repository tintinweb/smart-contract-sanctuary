// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./MultiSignWallet.sol";

contract MultiSignWalletFactory {
    event NewWallet(address indexed wallet);

    function create(address[] calldata _owners, uint _required, bytes32 salt, bool _securitySwitch, uint _inactiveInterval) public returns (address) {
        MultiSignWallet wallet = new MultiSignWallet{salt: salt}();
        wallet.initialize(_owners, _required, _securitySwitch, _inactiveInterval);
        emit NewWallet(address(wallet));
        return address(wallet);
    }
}