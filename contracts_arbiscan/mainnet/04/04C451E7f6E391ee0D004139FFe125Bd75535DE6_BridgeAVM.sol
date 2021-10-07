// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import "./IIdeaTokenExchangeStateTransferAVM.sol";
import "./IArbSys.sol";
import "./IIdeaTokenFactory.sol";
import "./IBridgeAVM.sol";
import "./Ownable.sol";
import "./Initializable.sol";

/**
 * @title BridgeAVM
 * @author Alexander Schlindwein
 *
 * This contract is the target of all L1 -> L2 calls originating from
 * the `IdeaTokenExchange` on L1. 
 * 
 */
contract BridgeAVM is Ownable, Initializable, IBridgeAVM {

    // Struct to temporarily store state from L1
    struct TMPTokenInfo {
        uint tokenID;
        string name;
        uint supply;
        uint dai;
        uint invested;
    }

    event TokensRedeemed(uint marketID, uint tokenID, uint amount, address to);

    // Address of the IdeaTokenExchange on L1
    address public _l1Exchange;
    // Address of the IdeaTokenExchange on L2
    IIdeaTokenExchangeStateTransferAVM public _l2Exchange;
    // Address of the IdeaTokenFactory on L2
    IIdeaTokenFactory public _l2Factory;

    // Stores if the static vars have been set already
    bool public _exchangeStaticVarsSet;
    // Stores if platform vars have been set already
    mapping(uint => bool) public _exchangePlatformVarsSet;
    // Stores token vars per market
    mapping(uint => TMPTokenInfo[]) public _tmpTokenInfos;
    // Stores the array lengths of the above mapping
    mapping(uint => uint) public _numTokensInMarket;

    modifier onlyL1Exchange {
        require(IArbSys(100).isTopLevelCall() && msg.sender == _l1Exchange, "only-l1-exchange");
        _;
    } 

    /**
     * Initializes the contract
     *
     * @param l1Exchange The address of the IdeaTokenExchange on L1
     * @param l2Exchange The address of the IdeaTokenExchange on L2
     * @param l2Factory The address of the IdeaTokenFactory on L2
     */
    function initialize(address l1Exchange, address l2Exchange, address l2Factory) external override initializer {
        require(l1Exchange != address(0) && l2Exchange != address(0) && l2Factory != address(0), "invalid-args");
        setOwnerInternal(msg.sender);
        _l1Exchange = address(uint160(l1Exchange) + uint160(0x1111000000000000000000000000000000001111));
        _l2Exchange = IIdeaTokenExchangeStateTransferAVM(l2Exchange);
        _l2Factory = IIdeaTokenFactory(l2Factory);
    }

    /**
     * Receives static vars from the IdeaTokenExchange on L1 and sets them on the L2 IdeaTokenExchange.
     *
     * @param tradingFeeInvested The tradingFeeInvested on L1
     */
    function receiveExchangeStaticVars(uint tradingFeeInvested) external override onlyL1Exchange {
        require(!_exchangeStaticVarsSet, "already-set");
        _exchangeStaticVarsSet = true;
        _l2Exchange.setStaticVars(tradingFeeInvested);
    }

    /**
     * Receives platform vars from the IdeaTokenExchange on L1 and sets them on the L2 IdeaTokenExchange.
     *
     * @param marketID The market's ID
     * @param dai The dai on L1
     * @param invested The invested on L1
     * @param platformFeeInvested The platformFeeInvested
     */
    function receiveExchangePlatformVars(uint marketID, uint dai, uint invested, uint platformFeeInvested) external override onlyL1Exchange {
        require(!_exchangePlatformVarsSet[marketID], "already-set");
        _exchangePlatformVarsSet[marketID] = true;
        _l2Exchange.setPlatformVars(marketID, dai, invested, platformFeeInvested);
    }

    /**
     * Receives token vars from the IdeaTokenExchange on L1.
     * The vars are not immediately set, but instead stored until setTokenVars is called.
     * Ensures that the token vars are received in the correct order.
     *
     * @param marketID The market's ID
     * @param tokenIDs The IDs of the tokens
     * @param names The names of the tokens
     * @param supplies The supplies of the tokens
     * @param dais The dais of the tokens
     * @param investeds The investeds of the tokens
     */
    function receiveExchangeTokenVars(uint marketID,
                                      uint[] calldata tokenIDs,
                                      string[] calldata names,
                                      uint[] calldata supplies,
                                      uint[] calldata dais,
                                      uint[] calldata investeds) external override onlyL1Exchange {
        {
        uint length = tokenIDs.length;
        require(length > 0, "length-0");
        require(length == names.length && length == dais.length && length == investeds.length && length == supplies.length, "length-mismatch");
        }

        TMPTokenInfo[] storage tmpTokenInfos = _tmpTokenInfos[marketID];
        uint prevID = tmpTokenInfos.length;

        for(uint i = 0; i < tokenIDs.length; i++) {
            require(tokenIDs[i] == prevID + 1, "id-gap");
            pushTMPTokenInfoInternal(tmpTokenInfos, tokenIDs[i], names[i], supplies[i], dais[i], investeds[i]);
            prevID = tokenIDs[i];
        }

        // `tokenID`s being an array makes this safe from overflowing
        _numTokensInMarket[marketID] += tokenIDs.length;
    }

    /// Using seperate function due to stack too deep
    function pushTMPTokenInfoInternal(TMPTokenInfo[] storage tmpTokenInfos, uint tokenID, string memory name, uint supply, uint dai, uint invested) internal {
        tmpTokenInfos.push(TMPTokenInfo({
            tokenID: tokenID,
            name: name,
            supply: supply,
            dai: dai,
            invested: invested
        }));
    }

    /**
     * Sets previously received token vars on L2.
     * May only be called by the owner.
     * Ensures that the token vars are received in the correct order.
     * 
     * @param marketID The market's ID
     * @param tokenIDs The IDs of the tokens
     */
    function setTokenVars(uint marketID, uint[] calldata tokenIDs) external override onlyOwner {
        uint length = tokenIDs.length;
        require(length > 0, "zero-length");
        require(tokenIDs[0] > 0, "tokenid-0");

        MarketDetails memory marketDetails = _l2Factory.getMarketDetailsByID(marketID);
        require(marketDetails.exists, "invalid-market");
        uint numTokens = marketDetails.numTokens;

        for(uint i = 0; i < length; i++) {
            uint tokenID = tokenIDs[i];
            require(numTokens + i + 1 == tokenID, "gap");

            TMPTokenInfo memory tmpTokenInfo = _tmpTokenInfos[marketID][tokenID - 1];
            _l2Factory.addToken(tmpTokenInfo.name, marketID, address(this));
            _l2Exchange.setTokenVarsAndMint(marketID, tmpTokenInfo.tokenID, tmpTokenInfo.supply, tmpTokenInfo.dai, tmpTokenInfo.invested);
        }
    }

    /**
     * Transfers a user's IdeaTokens from L1 to L2.
     *
     * @param marketID The market ID of the token
     * @param tokenID The token ID of the token
     * @param amount The amount to transfer
     * @param to The recipient
     */
    function receiveIdeaTokenTransfer(uint marketID, uint tokenID, uint amount, address to) external override onlyL1Exchange {
        TokenInfo memory tokenInfo = _l2Factory.getTokenInfo(marketID, tokenID);
        require(tokenInfo.exists, "not-exist");
        require(tokenInfo.ideaToken.transfer(to, amount), "transfer");
        
        emit TokensRedeemed(marketID, tokenID, amount, to);
    }
}