// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import "./IdeaTokenFactoryAVM.sol";

/**
 * @title IdeaTokenFactoryStateTransferAVM
 * @author Alexander Schlindwein
 *
 * Replaces the L2 IdeaTokenFactory logic for the state transfer from L1.
 * Only allows the BridgeAVM to add tokens.
 */
contract IdeaTokenFactoryStateTransferAVM is IdeaTokenFactoryAVM {
    
    /**
     * Adds a check to the addToken function which only allows it to be called by the BridgeAVM.
     *
     * @param tokenName The name of the token to be listed
     * @param marketID The market's ID
     * @param lister The address which off-chain applications should see as lister of this token
     */
    function addToken(string calldata tokenName, uint marketID, address lister) external override onlyBridge {
        MarketInfo storage marketInfo = _markets[marketID];
        require(marketInfo.marketDetails.exists, "market-not-exist");
        require(isValidTokenName(tokenName, marketID), "invalid-name");

        IIdeaToken ideaToken = IIdeaToken(address(new MinimalProxy(_ideaTokenLogic)));
        ideaToken.initialize(string(abi.encodePacked(marketInfo.marketDetails.name, ": ", tokenName)), _ideaTokenExchange);

        uint tokenID = ++marketInfo.marketDetails.numTokens;
        TokenInfo memory tokenInfo = TokenInfo({
            exists: true,
            id: tokenID,
            name: tokenName,
            ideaToken: ideaToken
        });

        marketInfo.tokens[tokenID] = tokenInfo;
        marketInfo.tokenIDs[tokenName] = tokenID;
        marketInfo.tokenNameUsed[tokenName] = true;
        _tokenIDPairs[address(ideaToken)] = IDPair({
            exists: true,
            marketID: marketID,
            tokenID: tokenID
        });

        emit NewToken(tokenID, marketID, tokenName, address(ideaToken), lister);
    }
}