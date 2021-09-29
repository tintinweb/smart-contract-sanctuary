// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;

import "./IIdeaTokenExchangeStateTransfer.sol";
import "./IdeaTokenExchange.sol"; 
import "./IBridgeAVM.sol";
import "./IInbox.sol";

/**
 * @title IdeaTokenExchangeStateTransfer
 * @author Alexander Schlindwein
 *
 * Replaces the L1 IdeaTokenExchange logic for the state transfer to Arbitrum L2.
 * 
 * This implementation will disable all state-altering methods and adds state transfer
 * methods which can be called by a transfer manager EOA. State transfer methods will call 
 * Arbitrum's Inbox contract to execute a transaction on L2.
 */
contract IdeaTokenExchangeStateTransfer is IdeaTokenExchange, IIdeaTokenExchangeStateTransfer {

    uint __gapStateTransfer__;

    // EOA which is allowed to manage the state transfer
    address public _transferManager;
    // Address of the BridgeAVM contract on L2
    address public _l2Bridge;
    // Address of Arbitrum's Inbox contract on L1
    IInbox public _l1Inbox;
    // Switch to enable token transfers once the initial state transfer is complete
    bool public _tokenTransferEnabled;

    event StaticVarsTransferred();
    event PlatformVarsTransferred(uint marketID);
    event TokenVarsTransferred(uint marketID, uint tokenID);
    event TokensTransferred(uint marketID, uint tokenID, address user, uint amount, address recipient);
    event TokenTransferEnabled();

    modifier onlyTransferManager {
        require(msg.sender == _transferManager, "only-transfer-manager");
        _;
    }

    /**
     * Initializes the contract's variables.
     *
     * @param transferManager EOA which is allowed to manage the state transfer
     * @param l2Bridge Address of the BridgeAVM contract on L2
     * @param l1Inbox Address of Arbitrum's Inbox contract on L1
     */
    function initializeStateTransfer(address transferManager, address l2Bridge, address l1Inbox) external override {
        require(_transferManager == address(0), "already-init");
        require(transferManager != address(0) && l2Bridge != address(0) &&  l1Inbox != address(0), "invalid-args");

        _transferManager = transferManager;
        _l2Bridge = l2Bridge;
        _l1Inbox = IInbox(l1Inbox);
    }

    /**
     * Transfers _tradingFeeInvested to L2.
     *
     * @param l2GasPriceBid Gas price for the L2 tx
     *
     * @return L1 -> L2 tx ticket id
     */
    function transferStaticVars(uint gasLimit, uint maxSubmissionCost, uint l2GasPriceBid) external payable override onlyTransferManager returns (uint) {
        address l2Bridge = _l2Bridge;
        bytes4 selector = IBridgeAVM(l2Bridge).receiveExchangeStaticVars.selector;
        bytes memory cdata = abi.encodeWithSelector(selector, _tradingFeeInvested);
        
        uint ticketID = sendL2TxInternal(l2Bridge, msg.sender, gasLimit, maxSubmissionCost, l2GasPriceBid, cdata);

        emit StaticVarsTransferred();

        return ticketID;
    }

    /**
     * Transfers a market's state to L2.
     *
     * @param marketID The ID of the market
     * @param l2GasPriceBid Gas price for the L2 tx
     *
     * @return L1 -> L2 tx ticket id
     */
    function transferPlatformVars(uint marketID, uint gasLimit, uint maxSubmissionCost, uint l2GasPriceBid) external payable override onlyTransferManager returns (uint) {
        MarketDetails memory marketDetails = _ideaTokenFactory.getMarketDetailsByID(marketID);
        require(marketDetails.exists, "not-exist");

        ExchangeInfo memory exchangeInfo = _platformsExchangeInfo[marketID];

        address l2Bridge = _l2Bridge;
        bytes4 selector = IBridgeAVM(l2Bridge).receiveExchangePlatformVars.selector;
        bytes memory cdata = abi.encodeWithSelector(selector, marketID, exchangeInfo.dai, exchangeInfo.invested, _platformFeeInvested[marketID]);
        
        uint ticketID = sendL2TxInternal(l2Bridge, msg.sender, gasLimit, maxSubmissionCost, l2GasPriceBid, cdata);

        emit PlatformVarsTransferred(marketID);

        return ticketID;
    }

    /**
     * Transfers token's state to L2.
     *
     * @param marketID The ID of the tokens' market
     * @param tokenIDs The IDs of the tokens
     * @param l2GasPriceBid Gas price for the L2 tx
     *
     * @return L1 -> L2 tx ticket id
     */
    function transferTokenVars(uint marketID, uint[] calldata tokenIDs, uint gasLimit, uint maxSubmissionCost, uint l2GasPriceBid) external payable override onlyTransferManager returns (uint) {
        {
        MarketDetails memory marketDetails = _ideaTokenFactory.getMarketDetailsByID(marketID);
        require(marketDetails.exists, "market-not-exist");
        }

        (string[] memory names, uint[] memory supplies, uint[] memory dais, uint[] memory investeds) = makeTokenStateArraysInternal(marketID, tokenIDs);        

        address l2Bridge = _l2Bridge;
        bytes4 selector = IBridgeAVM(l2Bridge).receiveExchangeTokenVars.selector;
        bytes memory cdata = abi.encodeWithSelector(selector, marketID, tokenIDs, names, supplies, dais, investeds);

        return sendL2TxInternal(l2Bridge, msg.sender, gasLimit, maxSubmissionCost, l2GasPriceBid, cdata);
    }

    // Stack too deep
    function makeTokenStateArraysInternal(uint marketID, uint[] memory tokenIDs) internal returns (string[] memory, uint[] memory, uint[] memory, uint[] memory) {
        uint length = tokenIDs.length;
        require(length > 0, "length-0");

        string[] memory names = new string[](length);
        uint[] memory supplies = new uint[](length);
        uint[] memory dais = new uint[](length);
        uint[] memory investeds = new uint[](length);

        for(uint i = 0; i < length; i++) {

            uint tokenID = tokenIDs[i];
            {
            TokenInfo memory tokenInfo = _ideaTokenFactory.getTokenInfo(marketID, tokenID);
            require(tokenInfo.exists, "token-not-exist");

            IIdeaToken ideaToken = tokenInfo.ideaToken;
            ExchangeInfo memory exchangeInfo = _tokensExchangeInfo[address(ideaToken)];
            
            names[i] = tokenInfo.name;
            supplies[i] = ideaToken.totalSupply();
            dais[i] = exchangeInfo.dai;
            investeds[i] = exchangeInfo.invested;
            }

            emit TokenVarsTransferred(marketID, tokenID);
        }

        return (names, supplies, dais, investeds);
    }

    /**
     * Transfers an user's IdeaTokens to L2.
     *
     * @param marketID The ID of the token's market
     * @param tokenID The ID of the token
     * @param l2Recipient The address of the recipient on L2
     * @param l2GasPriceBid Gas price for the L2 tx
     *
     * @return L1 -> L2 tx ticket id
     */
    function transferIdeaTokens(uint marketID, uint tokenID, address l2Recipient, uint gasLimit, uint maxSubmissionCost, uint l2GasPriceBid) external payable override returns (uint) {
        
        require(_tokenTransferEnabled, "not-enabled");
        require(l2Recipient != address(0), "zero-addr");

        TokenInfo memory tokenInfo = _ideaTokenFactory.getTokenInfo(marketID, tokenID);
        require(tokenInfo.exists, "not-exists");

        IIdeaToken ideaToken = tokenInfo.ideaToken;
        uint balance = ideaToken.balanceOf(msg.sender);
        require(balance > 0, "no-balance");

        ideaToken.burn(msg.sender, balance);
        
        address l2Bridge = _l2Bridge;
        bytes4 selector = IBridgeAVM(l2Bridge).receiveIdeaTokenTransfer.selector;
        bytes memory cdata = abi.encodeWithSelector(selector, marketID, tokenID, balance, l2Recipient);
        
        uint ticketID = sendL2TxInternal(l2Bridge, l2Recipient, gasLimit, maxSubmissionCost, l2GasPriceBid, cdata);

        emitTokensTransferredEventInternal(marketID, tokenID, balance, l2Recipient);
    
        return ticketID;
    }

    // Stack too deep
    function emitTokensTransferredEventInternal(uint marketID, uint tokenID, uint balance, address l2Recipient) internal {
        emit TokensTransferred(marketID, tokenID, msg.sender, balance, l2Recipient); 
    }

    /**
     * Enables transferIdeaTokens to be called.
     */
    function setTokenTransferEnabled() external override onlyTransferManager {
        _tokenTransferEnabled = true;

        emit TokenTransferEnabled();
    }

    function sendL2TxInternal(address to, address refund, uint gasLimit, uint maxSubmissionCost, uint l2GasPriceBid, bytes memory cdata) internal returns (uint) {
        require(gasLimit > 0 && maxSubmissionCost > 0 && l2GasPriceBid > 0, "l2-gas");
        require(msg.value == maxSubmissionCost.add(gasLimit.mul(l2GasPriceBid)), "value");

        return _l1Inbox.createRetryableTicket{value: msg.value}(
            to,                     // L2 destination
            0,                      // value
            maxSubmissionCost,      // maxSubmissionCost
            refund,                 // submission refund address
            refund,                 // value refund address
            gasLimit,               // max gas
            l2GasPriceBid,          // gas price bid
            cdata                   // L2 calldata
        );
    }

    /* **********************************************
     * ************  Disabled functions  ************
     * ********************************************** 
     */

    function initialize(address owner, address authorizer, address tradingFeeRecipient, address interestManager, address dai) external override {
        owner; authorizer; tradingFeeRecipient; interestManager; dai;
        revert("x");
    }

    function sellTokens(address ideaToken, uint amount, uint minPrice, address recipient) external override {
        ideaToken; amount; minPrice; recipient;
        revert("x");
    }

    function getPriceForSellingTokens(address ideaToken, uint amount) external view override returns (uint) {
        ideaToken; amount;
        revert("x");
    }

    function getPricesForSellingTokens(MarketDetails memory marketDetails, uint supply, uint amount, bool feesDisabled) public pure override returns (CostAndPriceAmounts memory) {
        marketDetails; supply; amount; feesDisabled;
        revert("x");
    }

    function getRawPriceForSellingTokens(uint baseCost, uint priceRise, uint hatchTokens, uint supply, uint amount) internal pure override returns (uint) {
        baseCost; priceRise; hatchTokens; supply; amount;
        revert("x");
    }

    function buyTokens(address ideaToken, uint amount, uint fallbackAmount, uint cost, address recipient) external override {
        ideaToken; amount; fallbackAmount; cost; recipient;
        revert("x");
    }

    function getCostForBuyingTokens(address ideaToken, uint amount) external view override returns (uint) {
        ideaToken; amount;
        revert("x");
    }

    function getCostsForBuyingTokens(MarketDetails memory marketDetails, uint supply, uint amount, bool feesDisabled) public pure override returns (CostAndPriceAmounts memory) {
        marketDetails; supply; amount; feesDisabled;
        revert("x");
    }

    function getRawCostForBuyingTokens(uint baseCost, uint priceRise, uint hatchTokens, uint supply, uint amount) internal pure override returns (uint) {
        baseCost; priceRise; hatchTokens; supply; amount;
        revert("x");
    }

    function withdrawTokenInterest(address token) external override {
        token;
        revert("x");
    }

    function getInterestPayable(address token) public view override returns (uint) {
        token;
        revert("x");
    }

    function setTokenOwner(address token, address owner) external virtual override {
        token; owner;
        revert("x");
    }

    function withdrawPlatformInterest(uint marketID) external override {
        marketID;
        revert("x");
    }

    function getPlatformInterestPayable(uint marketID) public view override returns (uint) {
        marketID;
        revert("x");
    }

    function withdrawPlatformFee(uint marketID) external override {
        marketID;
        revert("x");
    }

    function getPlatformFeePayable(uint marketID) public view override returns (uint) {
        marketID;
        revert("x");
    }

    function setPlatformOwner(uint marketID, address owner) external override {
        marketID; owner;
        revert("x");
    }

    function withdrawTradingFee() external override {
        revert("x");
    }

    function getTradingFeePayable() public view override returns (uint) {
        revert("x");
    }

    function setAuthorizer(address authorizer) external override {
        authorizer;
        revert("x");
    }

    function isTokenFeeDisabled(address ideaToken) external view override returns (bool) {
        ideaToken;
        revert("x");
    }

    function setTokenFeeKillswitch(address ideaToken, bool set) external override {
        ideaToken; set;
        revert("x");
    }

    function setIdeaTokenFactoryAddress(address factory) external override {
        factory;
        revert("x");
    }
}