// SPDX-License-Identifier: MIT
pragma solidity =0.7.4;

import "LibBaseAuth.sol";
import "LibIVokenAudit.sol";


/**
 * @dev Voken2.0 Audit
 */
contract Voken2Audit is BaseAuth, IVokenAudit {
    struct Account {
        uint72 wei_purchased;
        uint72 wei_rewarded;
        uint72 wei_audit;
        uint16 txs_in;
        uint16 txs_out;
    }

    mapping (address => Account) _accounts;

    function setAccounts(
        address[] memory accounts,
        uint72[] memory wei_purchased,
        uint72[] memory wei_rewarded,
        uint72[] memory wei_audit,
        uint16[] memory txs_in,
        uint16[] memory txs_out
    )
        external
        onlyAgent
    {
        for (uint8 i = 0; i < accounts.length; i++) {
            _accounts[accounts[i]] = Account(wei_purchased[i], wei_rewarded[i], wei_audit[i], txs_in[i], txs_out[i]);
        }
    }

    function removeAccounts(address[] memory accounts)
        external
        onlyAgent
    {
        for (uint8 i = 0; i < accounts.length; i++) {
            delete _accounts[accounts[i]];
        }
        
    }

    function getAccount(address account)
        public
        override
        view
        returns (uint72 wei_purchased, uint72 wei_rewarded, uint72 wei_audit, uint16 txs_in, uint16 txs_out)
    {
        wei_purchased = _accounts[account].wei_purchased;
        wei_rewarded = _accounts[account].wei_rewarded;
        wei_audit = _accounts[account].wei_audit;
        txs_in = _accounts[account].txs_in;
        txs_out = _accounts[account].txs_out;
    }
}

