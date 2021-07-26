pragma solidity ^0.4.13;

import "./erc20.sol";

/**
 * The BUX token was originally the BPT token on Ethereum (Ethereum contract: 0x327682779bAB2BF4d1337e8974ab9dE8275A7Ca8).
 * BPT originates from the Blockport Tokensale in 2018.
 * With permission from BUX and the collaboration between BUX and Blockport, it is now named the BUX Token on the Binance Smart Chain.
*/
contract BuxToken is CappedToken, PausableToken {
    string public constant name = "BUX Token";
    string public constant symbol = "BUX";
    uint256 public constant decimals = 18;

    function BuxToken() public CappedToken(76384000000000000000000000) {
        paused = true;
    }

    /**
     * @dev called by the owner to mint in batches
     */
    function mintBatch(address[] _to, uint256[] _amount)
    public
    onlyOwner
    canMint
    {
        require(_to.length == _amount.length);
        for (uint256 i = 0; i < _to.length; i++) {
            mint(_to[i], _amount[i]);
        }
    }
}