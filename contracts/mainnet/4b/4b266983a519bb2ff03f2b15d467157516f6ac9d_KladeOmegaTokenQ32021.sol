// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;
import { ITokenManager, ISafeMath } from './Interfaces.sol';
import { ERC20 } from './ERC20.sol';

// ----------------------------------------------------------------------------
// Klade Omega Tokens-Difficulty Derivative
// ----------------------------------------------------------------------------
contract KladeOmegaTokenQ32021 is ERC20 {
    uint public constant expiration = 1632960000;
    uint public constant required_collateral = 127000;

    uint public omega_token_payout;
    bool public payout_set;

    address immutable public KladeAddress1;
    address immutable public KladeAddress2;
    address immutable public ChainlinkReceiverAddress;
    address immutable public TokenManagerAddress;

    constructor(address klade_address1, address klade_address2, ISafeMath safemath_contract, address receiver_address, address manager_address)
        ERC20("KOTQ32021", "KOmegaQ32021", 18, 0, safemath_contract) public {
        KladeAddress1 = klade_address1;
        KladeAddress2 = klade_address2;

        ChainlinkReceiverAddress = receiver_address;
        TokenManagerAddress = manager_address;
    }

    /**
     * Mints Klade Omega tokens
     * @param omega_token_recipient address - The owner of the newly minted alpha token(s)
     * @param numToMint uint256 - The number of alpha tokens minted in this transactions in base units(_decimals)
     */
    function mint_tokens(address omega_token_recipient, uint256 numToMint) external returns (bool success) {
        require(msg.sender == TokenManagerAddress, "Only the tokenmanager contract can mint Klade tokens");
        _totalSupply = safemath.add(numToMint, _totalSupply);
        balances[omega_token_recipient] = safemath.add(balances[omega_token_recipient], numToMint);
        return true;
    }


    /**
     * If an address owns omega tokens, after expiry that address can
     * call this function to claim the WBTC payout it is entitled to for these tokens.
     * The omega tokens for which payout is claimed are burned afterward.
     * @param payout_recipient address - The recipient of the WBTC payout
     * @param num uint - Number of tokens to burn and get payout for
     */
    function payout(address payout_recipient, uint num) external {
        require(block.timestamp > expiration, "Tokens have not reached expiration, please wait until after expiration for payouts");
        require(payout_set, "Payouts have not been set");

        balances[msg.sender] = safemath.sub(balances[msg.sender], num); // reverts if msg.sender does not own at least num tokens
        _totalSupply = safemath.sub(_totalSupply, num);

        emit Transfer(msg.sender, address(0), num); //Burn tokens after payout
        uint payout_amount = safemath.div(safemath.mul(num, omega_token_payout), 10**18);
        require(ITokenManager(TokenManagerAddress).payout("Q32021", payout_recipient, payout_amount));
    }


    /**
     * set_payout should be called by the ChainlinkReceiver
     * when the quarter is over and the payout has been calculated
     * @param payout_amount uint - The payout amount in WBTC base units for a single alpha token
     */
    function set_payout(uint payout_amount) external {
        require(msg.sender == ChainlinkReceiverAddress, "Only the ChainlinkReceiver can set the payouts");
        require(!payout_set, "Payouts have already been set");
        require(required_collateral >= payout_amount, "1 token's payout is higher than 1 token pair's required collateral");
        require(block.timestamp > expiration, "Tokens have not reached expiration, please wait until after expiration to set payouts");
        
        omega_token_payout = payout_amount;
        payout_set = true;
    }

    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    fallback () external payable {
        revert();
    }
}