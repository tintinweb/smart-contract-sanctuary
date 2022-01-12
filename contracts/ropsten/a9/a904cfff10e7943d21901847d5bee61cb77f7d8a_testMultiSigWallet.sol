/**
 *Submitted for verification at Etherscan.io on 2022-01-12
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.4.15;

interface IMultiSigWallet {
    function addOwner(address _owner) public;

      
}
contract testMultiSigWallet{
    function addMultiSigWalletOwner(address newowner,address MultisigwalletAddress) public {
        IMultiSigWallet(MultisigwalletAddress).addOwner(newowner);
    }
}