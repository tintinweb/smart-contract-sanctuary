//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Factory.sol";
import "./MultiSigWalletWithDailyLimit.sol";


/// @title Multisignature wallet factory for daily limit version - Allows creation of multisig wallet.
/// @author Stefan George - <[email protected]>
contract MultiSigWalletWithDailyLimitFactory is Factory {

    MultiSigWallet multiSigWallet;

    /*
     * Public functions
     */
    // @dev Allows verified creation of multisignature wallet.
    // @param _owners List of initial owners.
    // @param _required Number of required confirmations.
    // @param _dailyLimit Amount in wei, which can be withdrawn without confirmations on a daily basis.
    // @return Returns wallet address.
    function create(address[] memory _owners, uint8 _group, uint8 _required, uint _dailyLimit)
    public
    returns (address)
    {
        multiSigWallet = new MultiSigWalletWithDailyLimit(_owners, _group, _required, _dailyLimit);
        register(address(multiSigWallet));
        return address(multiSigWallet);
    }
}