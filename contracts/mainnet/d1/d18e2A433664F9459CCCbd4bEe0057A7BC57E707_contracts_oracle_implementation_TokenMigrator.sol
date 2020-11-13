pragma solidity ^0.6.0;

pragma experimental ABIEncoderV2;

import "../../common/implementation/FixedPoint.sol";
import "../../common/interfaces/ExpandedIERC20.sol";
import "./VotingToken.sol";


/**
 * @title Migration contract for VotingTokens.
 * @dev Handles migrating token holders from one token to the next.
 */
contract TokenMigrator {
    using FixedPoint for FixedPoint.Unsigned;

    /****************************************
     *    INTERNAL VARIABLES AND STORAGE    *
     ****************************************/

    VotingToken public oldToken;
    ExpandedIERC20 public newToken;

    uint256 public snapshotId;
    FixedPoint.Unsigned public rate;

    mapping(address => bool) public hasMigrated;

    /**
     * @notice Construct the TokenMigrator contract.
     * @dev This function triggers the snapshot upon which all migrations will be based.
     * @param _rate the number of old tokens it takes to generate one new token.
     * @param _oldToken address of the token being migrated from.
     * @param _newToken address of the token being migrated to.
     */
    constructor(
        FixedPoint.Unsigned memory _rate,
        address _oldToken,
        address _newToken
    ) public {
        // Prevents division by 0 in migrateTokens().
        // Also it doesn’t make sense to have “0 old tokens equate to 1 new token”.
        require(_rate.isGreaterThan(0), "Rate can't be 0");
        rate = _rate;
        newToken = ExpandedIERC20(_newToken);
        oldToken = VotingToken(_oldToken);
        snapshotId = oldToken.snapshot();
    }

    /**
     * @notice Migrates the tokenHolder's old tokens to new tokens.
     * @dev This function can only be called once per `tokenHolder`. Anyone can call this method
     * on behalf of any other token holder since there is no disadvantage to receiving the tokens earlier.
     * @param tokenHolder address of the token holder to migrate.
     */
    function migrateTokens(address tokenHolder) external {
        require(!hasMigrated[tokenHolder], "Already migrated tokens");
        hasMigrated[tokenHolder] = true;

        FixedPoint.Unsigned memory oldBalance = FixedPoint.Unsigned(oldToken.balanceOfAt(tokenHolder, snapshotId));

        if (!oldBalance.isGreaterThan(0)) {
            return;
        }

        FixedPoint.Unsigned memory newBalance = oldBalance.div(rate);
        require(newToken.mint(tokenHolder, newBalance.rawValue), "Mint failed");
    }
}
