// SPDX-License-Identifier: MIT

pragma solidity 0.7.3;
import { IERC20, ISafeMath, IKladeDiffToken } from './Interfaces.sol';

// ----------------------------------------------------------------------------
// This contract is used to "manage" Klade Tokens. Specifically you can use
// it to mint tokens for any quarter and it holds the collateral you send over
// until payouts are taken, at which point the Klade Tokens can take the collateral
// and send it to the token holders as payout.
// ----------------------------------------------------------------------------
contract TokenManager {
    address public immutable KladeAddress1;
    address public immutable KladeAddress2;
    ISafeMath public immutable safemath;
    IERC20 public immutable wbtc;

    uint public uncollected_fees = 0;
    uint public constant fee = 640; // Fee per 0.1 pairs minted in satoshis

    struct quarter_data_component {
        address AlphaToken;
        address OmegaToken;
        uint required_collateral; // Required Collateral for 0.1 pairs minted in satoshis
        uint total_collateral_backing;
    }

    mapping(string => quarter_data_component) public quarter_data;
    mapping(string => bool) public quarter_set;

    constructor(address klade_address1, address klade_address2, ISafeMath safemath_contract, IERC20 wbtc_contract) {
        KladeAddress1 = klade_address1;
        KladeAddress2 = klade_address2;
        safemath = safemath_contract;
        wbtc = wbtc_contract;
    }


    /**
     * Adds token data for a quarter.
     * Require #1: Ensures that once a quarter's data is set, it cannot be changed.
     * Require #2: Function can only be called by Klade
     * The quarter string will follow the format "Q12021".
     * required_collateral should be the required collateral for 0.1 pairs of Klade Tokens in WBTC units
     * @param quarter string - String representing Quarter that token will be added for - ie Q12021 for Quarter 1 of 2021
     * @param alpha_token_address address - Address of Klade Alpha Token
     * @param omega_token_address address - Address of Klade Omega Token
     * @param required_collateral uint - Required collateral to mint one pair of Klade Alpha/Omega Token
     */
    function add_new_token_pair(string calldata quarter, address alpha_token_address, address omega_token_address, uint required_collateral) external {
        require(!quarter_set[quarter], "Quarter Already Set");
        require(msg.sender == KladeAddress1 || msg.sender == KladeAddress2, "Only Klade can add token pairs");
        quarter_data[quarter] = quarter_data_component(alpha_token_address, omega_token_address, required_collateral, 0);
        quarter_set[quarter] = true;
    }



    /**
     *  This function requires the user to send over wBTC in order to mint (_numToMint/10) pairs of tokens for the given
     * quarter. Ex. _numPairsToMint is set to 100, the recipients will each be credited with 10 alpha and omega tokens respectively.
     * @param quarter string - String representing Quarter that token will be added for - ie Q12021 for Quarter 1 of 2021
     * @param _alpha_token_recipient address - Address of Klade Alpha Token receiver
     * @param _omega_token_recipient address - Address of Klade Omega Token receiver
     * @param _numPairsToMint uint - Number of Klade Alpha/Omega pairs to mint
     */
    function mint_tokens(string calldata quarter, address _alpha_token_recipient, address _omega_token_recipient, uint256 _numPairsToMint) external {
        require(quarter_set[quarter], "Quarter not set");

        uint collateral = safemath.mul(_numPairsToMint, quarter_data[quarter].required_collateral);
        uint minting_fees = safemath.mul(_numPairsToMint, fee);

        require(wbtc.transferFrom(msg.sender, address(this), safemath.add(collateral, minting_fees)));
        quarter_data[quarter].total_collateral_backing = safemath.add(collateral, quarter_data[quarter].total_collateral_backing);

        IKladeDiffToken alpha_token = IKladeDiffToken(quarter_data[quarter].AlphaToken);
        IKladeDiffToken omega_token = IKladeDiffToken(quarter_data[quarter].OmegaToken);

        // if either mint fails then the whole transaction is reverted
        uint units_to_mint = safemath.mul(10**17, _numPairsToMint);
        require(alpha_token.mint_tokens(_alpha_token_recipient, units_to_mint));
        require(omega_token.mint_tokens(_omega_token_recipient, units_to_mint));
        uncollected_fees = safemath.add(uncollected_fees, minting_fees);
    }



    /**
     * This function can only be called by a registered Klade Token
     * The payout will be sent to payout_recipient
     * impossible that a token can claim collateral from another quarter. 
     * Line 100 reverts if amount > quarter_data[quarter].total_collateral_backing
     * @param quarter string - String representing Quarter that token will be added for - ie Q12021 for Quarter 1 of 2021
     * @param recipient address - The recipient of the WBTC payout
     * @param amount uint - amount of WBTC to payout
     */
    function payout(string calldata quarter, address recipient, uint amount) external returns (bool success) {
        require(quarter_set[quarter], "Quarter not set");
        require(quarter_data[quarter].AlphaToken == msg.sender || quarter_data[quarter].OmegaToken == msg.sender, "Only Alpha and Omega can transfer payout");
        quarter_data[quarter].total_collateral_backing = safemath.sub(quarter_data[quarter].total_collateral_backing, amount);
        require(wbtc.transfer(recipient, amount));
        return true;
    }


    // Klade can collect fees
    function collect_fees() external {
        require(msg.sender == KladeAddress1 || msg.sender == KladeAddress2, "Only Klade wallets can collect minting fees");
        uint to_pay = uncollected_fees;
        uncollected_fees = 0;
        require(wbtc.transfer(msg.sender, to_pay), "Failed to send minting fees");
    }


    // ------------------------------------------------------------------------
    // Don't accept ETH
    // ------------------------------------------------------------------------
    fallback () external payable {
        revert();
    }
}