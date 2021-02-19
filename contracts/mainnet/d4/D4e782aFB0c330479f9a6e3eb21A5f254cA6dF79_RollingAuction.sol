// SPDX-License-Identifier: UNLICENSED
// 13 February 2021
// This code is the property of the Aardbanq DAO.
// The Aardbanq DAO is located at 0x829c094f5034099E91AB1d553828F8A765a3DaA1 on the Ethereum Main Net.
// It is the author's wish that this code should be open sourced under the MIT license, but the final 
// decision on this would be taken by the Aardbanq DAO with a vote once sufficient ABQ tokens have been 
// distributed.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity ^0.7.0;
import "./Erc20.sol";
import "./SafeMathTyped.sol";

/// @notice The individual bid.
/// `pricePerToken` is the amount of DAI per ABQ for the bid.
/// `amountOfTokens` is the amount of ABQ tokens this bid is for.
/// `bidder` is the address that submitted (and thus owns) the bid.
/// The total DAI remaining for this bid would be `pricePerToken` * `amountOfTokens`
struct Bid
{
    // The amount of DAI per ABQ for the bid
    uint128 pricePerToken;
    // The amount of ABQ tokens that the bid is for.
    uint128 amountOfTokens;
    // The address that submitted (and thus owns) the bid.
    address bidder;
}

/// @notice The leaf node in the three level tree to represent bids.
/// `amountOfTokens` is the amount of ABQ tokens in this leaf node.
/// `startIndex` is the first index in the `bids` array that has not been fully processed yet.
/// `bids` is the array of bids that are in this node. 
struct LeafNode
{
    // The amount of ABQ tokens there is a bid for.
    uint256 amountOfTokens;
    // The first index in the `bids` array that has not been fully processed yet.
    uint256 startIndex;
    // The array of bids that are in this node.
    Bid[] bids;
}

/// @notice An action that will allow awarding lots at incremental times. Allows for bids per token of 1.00 to 9.99.
contract RollingAuction
{
    /// @notice The first amount of tokens that will be allocatable once the auction is first eligible to award tokens.
    uint128 public firstTokenAmountToAllocate;
    /// @notice The inclusive minimum amount in DAI cents that the price per token may be for bids.
    /// 100 indicate a value of 1 DAI.
    uint128 constant public minAmount = 100;
    /// @notice The inclusive maximum amount in DAI cents that the price per token may be for bids.
    /// Bids larger that this would be considered an outright buy instead of a bid.
    /// 999 indicate a value of 9.99 DAI.
    uint128 constant public maxAmount = 999;
    /// @notice The inclusive minimum amount of ABQ tokens that may be bid on at a time.
    uint128 constant public minTokensPerBid = 100;
    /// @notice The amount of ABQ tokens that would be eligible to be awarded to the highest bidders each time period.
    uint128 public tokensPerTimeslice;
    /// @notice A constant used to scale DAI cents to the smallest DAI unit required for interacting with the DAI token 
    /// contract.
    uint256 constant public bidAssetScaling = 10000000000000000;
    /// @notice A constant used to scale ABQ tokens to the smallest ABQ unit required for interacting with the ABQ token 
    /// contracts.
    uint256 constant public allocatingAssetDecimalsScaling = 1000000000000000000;
    /// @notice Used to manage partial distributions in a time window that is eligible to distribute tokens.
    uint128 public tokensLeftForCurrentTimeslice = 0;
    /// @notice The amount of ABQ tokens that are still left that may be distributed.
    uint128 public amountLeft;
    /// @notice The amount of ABQ tokens that have not received a bid when it was distributed. These tokens are sent back 
    /// to the `unclamedAddress` defined on this contract.
    uint128 public amountUnallocated = 0;
    /// @notice The ERC20 contract for the ABQ token.
    Erc20 public allocationAsset;
    /// @notice The ERC20 contract for the DAI token.
    Erc20 public bidAsset;
    /// @notice The address to wich all allocated bids' DAI funds are send to be managed by the DAO.
    address public fundAddress;
    /// @notice The address that ABQ tokens are sent, that did not get a bid during the lifetime of the auction should 
    /// there be any.
    address public unallocatedAddress;
    /// @notice The Unix time of when the the auction's first batch of ABQ tokens will be eligible to allocate.
    uint256 public startDate;
    /// @notice The amount of seconds describing how far apart token batches will become eligible. 
    /// If this is set to 1000 for example then every 1000 seconds after `startDate` another `tokensPerTimeslice` will be 
    /// allocatable.
    uint256 public timeWindow;
    /// @notice The Unix time for the latest eligible time that allocation of ABQ tokens has started.
    uint256 public lastAllocatedTimeslice;
    /// @notice The Bid Id to use for all outright buys.
    uint256 constant public outrightBuyId = type(uint256).max;
    

    /// @notice The mapping between bidder and the amount of ABQ tokens allocated to them that has not yet been claimed.
    mapping(address => uint128) public allocations;
    /// @notice The total amount of DAI cents a given price per token range. Level 1 specifically deals with the X.00 part
    /// of a DAI price per token.
    /// For example the sum (in DAI cents) for all open bids greater than 2.00 DAI (inclusive) but less than 3.00 DAI (exclusive)
    /// will be recorded at `level1[2]`.
    mapping(uint256 => uint256) public level1;  // X.00
    /// @notice The total amount of DAI cents a given price per token range. Level 2 specifically deals with the 0.X0 part
    /// of a DAI price per token.
    /// For example the sum (in DAI cents) for all open bids greater than 2.50 DAI (inclusive) but less than 3.60 DAI (exclusive)
    /// will be recorded at `level2[2][5]`.
    mapping(uint256 => mapping(uint256 => uint256)) public level2;  // 0.X0
    /// @notice The bids are stored in here using the price per token as index. For example all bids for 2.57 DAI will be 
    /// stored at `level3[2][5][7]` using the `LeafNode` structure.
    mapping(uint256 => mapping(uint256 => mapping(uint256 => LeafNode))) public level3; // 0.0X

    /// @notice Construct a RollingAuction.
    /// @param _amountLeft The amount of ABQ tokens that would be placed on auction.
    /// @param _allocationAsset The ERC20 contract address for the ABQ token.
    /// @param _bidAsset The ERC20 contract address for the DAI token.
    /// @param _fundAddress The address to which all all DAI raised auctioning off ABQ tokens will be sent.
    /// @param _unallocatedAddress The address that any ABQ tokens that could not be auctioned will be sent, should there be any.
    /// @param _startDate The date and time, in Unix time, that the auction will commence.
    /// @param _timeWindow The intervals in seconds that ABQ tokens would be eligible to be awarded after the `_startDate`.
    /// @param _firstTokenAmountToAllocate The amount of tokens eligible to be allocated at the `_startDate` of the auction.
    /// @param _tokensPerTimeslice The amount of tokens that becomes eligible to allocated with each `_timeWindow` period.
    constructor(
        uint128 _amountLeft, 
        Erc20 _allocationAsset, 
        Erc20 _bidAsset, 
        address _fundAddress, 
        address _unallocatedAddress, 
        uint256 _startDate, 
        uint256 _timeWindow, 
        uint128 _firstTokenAmountToAllocate, 
        uint128 _tokensPerTimeslice)
    {
        amountLeft = _amountLeft;
        allocationAsset = _allocationAsset;
        bidAsset = _bidAsset;
        fundAddress = _fundAddress;
        unallocatedAddress = _unallocatedAddress;
        startDate = _startDate;
        timeWindow = _timeWindow;
        firstTokenAmountToAllocate = _firstTokenAmountToAllocate;
        tokensPerTimeslice = _tokensPerTimeslice;
    }

    /// @notice Retrieves price per token in DAI cents for the highest open bid.
    /// @return _pricePerToken The price per token in DAI cents of the highest bid.
    function topBid()
        external
        view
        returns (uint128 _pricePerToken)
    {
        for (uint128 level1Index = 9; level1Index < 10; level1Index -= 1)
        {
            uint256 level1Amount = level1[level1Index];
            if (level1Amount > 0)
            {
                for (uint128 level2Index = 9; level2Index < 10; level2Index -= 1)
                {
                    uint256 level2Amount = level2[level1Index][level2Index];
                    if (level2Amount > 0)
                    {
                        for (uint128 level3Index = 9; level3Index < 10; level3Index -= 1)
                        {
                            LeafNode storage node = level3[level1Index][level2Index][level3Index];
                            if (node.amountOfTokens > 0)
                            {
                                return uint128((level1Index * 100) + (level2Index * 10) + level3Index);
                            }

                            if (level3Index == 0)
                            {
                                break;
                            }
                        }
                    }

                    if (level2Index == 0)
                    {
                        break;
                    }
                }
            }

            if (level1Index == 0)
            {
                break;
            }
        }
    }

    /// @notice Get the amount of ABQ tokens on open bids for a given price per token.
    /// @param _pricePerToken The price in DAI cents for the open bid. It should be between 0 to 999 inclusively.
    /// @return _amountOfTokens The amount of ABQ tokens for open bids with a price per token of `_pricePerToken`.
    function getTokensAmountForBid(uint128 _pricePerToken)
        external
        view
        returns (uint256 _amountOfTokens)
    {
        uint256 level1Index = getLevel1Index(_pricePerToken);
        uint256 level2Index = getLevel2Index(_pricePerToken);
        uint256 level3Index = getLevel3Index(_pricePerToken);
        
        LeafNode storage node = level3[level1Index][level2Index][level3Index];
        return node.amountOfTokens;
    }

    /// @notice Get the lowest price per token in DAI cents for a provide amount of ABQ tokens.
    /// For example if `_amountOfTokens` are set to 360 the higest open bids that would become eligible for the next 
    /// 360 ABQ tokens will be considered and the lowest of these specific open bids will then be used to return the 
    /// price per token.
    /// @param _amountOfTokens The amount of ABQ tokens that the top bids should be evaluated for.
    /// @return _pricePerToken The lowest bid's price per token in DAI cent, that with the current state of the would
    /// be eligible to be allocated at least some of the next `_amountOfTokens` ABQ tokens at the next allocation.
    function getBidForTokenDepth(uint128 _amountOfTokens)
        external
        view
        returns (uint128 _pricePerToken)
    {
        for (uint256 level1Index = 9; level1Index < 10; level1Index -= 1)
        {
            uint256 level1Amount = level1[level1Index];
            if (level1Amount > 0 && level1Amount >= _amountOfTokens)
            {
                for (uint256 level2Index = 9; level2Index < 10; level2Index -= 1)
                {
                    uint256 level2Amount = level2[level1Index][level2Index];
                    if (level2Amount > 0 && level2Amount >= _amountOfTokens)
                    {
                        for (uint256 level3Index = 9; level3Index < 10; level3Index -= 1)
                        {
                            LeafNode storage node = level3[level1Index][level2Index][level3Index];
                            if (node.amountOfTokens > 0 && node.amountOfTokens >= _amountOfTokens)
                            {
                                _pricePerToken = uint128((level1Index * 100) + (level2Index * 10) + level3Index);
                                _amountOfTokens = 0;
                            }
                            else
                            {
                                _amountOfTokens = _amountOfTokens - uint128(node.amountOfTokens);
                            }

                            if (level3Index == 0 || _amountOfTokens == 0)
                            {
                                break;
                            }
                        }
                    }
                    else
                    {
                        _amountOfTokens = _amountOfTokens - uint128(level2Amount);
                    }

                    if (level2Index == 0 || _amountOfTokens == 0)
                    {
                        break;
                    }
                }
            }
            else
            {
                _amountOfTokens = _amountOfTokens - uint128(level1Amount);
            }

            if (level1Index == 0 || _amountOfTokens == 0)
            {
                break;
            }
        }
    }

    /// @notice Transfer all ABQ tokens that have been allocated and not yet transfered to the caller.
    function claimAll()
        public
    {
        // CG: Scale the amount of ABQ tokens to the smallest unit required for interacting with the ERC20 contract.
        uint256 allocation = SafeMathTyped.mul256(allocations[msg.sender], allocatingAssetDecimalsScaling);
        // CG: Set the allocation for the sender to zero before sending to avoid re-entry attacks. Not that it is a major 
        // issue in this auction since the ERC20 contract for the ABQ token's code is known and trusted, but still it is 
        // good practice to adjust the balance before calling another contract.
        allocations[msg.sender] = 0;
        // CG: Transfer the ABQ tokens to the sender. We know that the ABQ ERC20 contract does return a bool, so we 
        // can set the wasTransfered variable here safely without having to support ERC20 contracts that does not return
        // anything during a transfer.
        bool wasTransfered = allocationAsset.transfer(msg.sender, allocation);
        // CG: We require that the ERC20 contract indicate that the transfer was successful.
        require(wasTransfered, "ABQDAO/could-not-transfer-allocatoin");
    }

    /// @notice Transfer all DAI for an open bid back to the sender once the auction's allocation has concluded.
    /// @param _bidId The id for the specific bid.
    /// @param _pricePerToken The price per ABQ token for the specific bid.
    function refund(uint256 _bidId, uint128 _pricePerToken)
        external
    {
        // CG: Validate that alloctation/distribution has concluded for the auction.
        require(amountLeft == 0, "ABQDAO/auction-not-yet-completed");
        // CG: Validate that the _pricePerToken is in bound (0 to 999 inclusive)
        require(_pricePerToken < 1000, "ABQDAO/price-per-token-invalid");

        // CG: get the indexes for the various levels for the bids storing structure.
        uint256 level1Index = getLevel1Index(_pricePerToken);
        uint256 level2Index = getLevel2Index(_pricePerToken);
        uint256 level3Index = getLevel3Index(_pricePerToken);
        
        // CG: get the leaf node that should contain the bid
        LeafNode storage node = level3[level1Index][level2Index][level3Index];
        
        // CG: Check for stack overflow attack
        require(_bidId < node.bids.length, "ABQDAO/bidId-does-not-exist");

        // CG: Get the specific bid and validate that it does belong to the sender.
        Bid storage bid = node.bids[_bidId];
        require(bid.bidder == msg.sender, "ABQDAO/only-bidder-may-request-refund");

        // CG: Should the bid still be open, refund the sender the DAI of the bid.
        if (bid.amountOfTokens > 0)
        {
            // CG: Scale the DAI cents amount of the open bid to the smallest DAI unit needed to interact with the DAI ERC20 contract.
            uint256 refundTotal = SafeMathTyped.mul256(SafeMathTyped.mul256(bid.pricePerToken, bid.amountOfTokens), bidAssetScaling);
            // CG: Close the bid.
            bid.amountOfTokens = 0;
            // CG: Refund the DAI to the sender and insure it was successful. The DAI ERC20 contract code is known and does return a 
            // bool value indicating success so we can safely assign couldTransfer here without having to cater for ERC20 contracts 
            // that does not return anything.
            bool couldTransfer = bidAsset.transfer(msg.sender, refundTotal);
            // CG: We require that the DAI contract indicate a successful transfer.
            require(couldTransfer, "ABQDAO/could-not-trasfer");
        }
    }

    /// @notice The event emitted when a bid is placed or increased. `isIncrease` would be true if the bid was an increase bid
    /// and false if it was a fresh bid.
    event BidPlaced(address indexed bidder, uint128 pricePerToken, uint128 amountOfTokens, uint256 bidId, bool isIncrease);

    /// @notice Place a bid for ABQ tokens with `_amountOfTokens` as the total amount of ABQ tokens of the bid and `_pricePerToken` the 
    /// amount of DAI cents per ABQ token the bid is for. To succesfully place a bid the sender must have enough DAI for the total bid and 
    /// they must have authorized this contract address to withdraw the DAI from the DAI ERC20 contract.
    /// Bids are allocated/owned to the sender for this method call.
    /// @param _pricePerToken The DAI cents amount the price the bidder is willing to pay per ABQ token. This must be 100 DAI or more (inclusive) 
    /// and any price of 10000 and above (inclusive) will be an outright buy instead of a bid.
    /// @param _amountOfTokens The amount of ABQ tokens the bidder is willing to buy. This must be 100 or more (inclusive).
    /// @return _bidId the id for the bid that was placed. If it wasn't an outright buy, then the `_bidId` and `_pricePerToken` forms the unique 
    /// identifier for the bid.
    function placeBid(uint128 _pricePerToken, uint128 _amountOfTokens)
        external
        returns (uint256 _bidId)
    {
        // CG: Make sure the auction isn't concluded yet.
        require(amountLeft > 0, "ABQDAO/already-concluded-distribution");
        // CG: check the minimum requirements for a bid.
        require(_amountOfTokens >= minTokensPerBid, "ABQDAO/too-few-tokens");
        require(_pricePerToken >= minAmount, "ABQDAO/bid-too-small");

        // CG: process any bids that might be an outright bid.
        if (_pricePerToken > maxAmount)
        {
            (_bidId, ) = outrightBuy(uint128(0), _pricePerToken, _amountOfTokens);
            return _bidId;
        }

        // CG: Hold the DAI for the bid in escrow in this contract.
        uint256 totalToTransfer = SafeMathTyped.mul256(SafeMathTyped.mul256(_pricePerToken, _amountOfTokens), bidAssetScaling);
        bool couldClaimFunds = bidAsset.transferFrom(msg.sender, address(this), totalToTransfer);
        require(couldClaimFunds, "ABQDAO/could-not-claim-bid-funds");

        // CG: Determine the indexes to access the bid and the rolling sums in the mapping structures.
        uint256 level1Index = getLevel1Index(_pricePerToken);
        uint256 level2Index = getLevel2Index(_pricePerToken);
        uint256 level3Index = getLevel3Index(_pricePerToken);

        // CG: Update the rolling sums for the bids on the auction.
        level1[level1Index] = SafeMathTyped.add256(level1[level1Index], _amountOfTokens);
        level2[level1Index][level2Index] = SafeMathTyped.add256(level2[level1Index][level2Index], _amountOfTokens);
        LeafNode storage node = level3[level1Index][level2Index][level3Index];
        node.amountOfTokens = SafeMathTyped.add256(node.amountOfTokens, _amountOfTokens);

        // CG: Add the bids to the other open bids.
        _bidId = node.bids.length;
        node.bids.push(Bid(_pricePerToken, _amountOfTokens, msg.sender));
        emit BidPlaced(msg.sender, _pricePerToken, _amountOfTokens, _bidId, false);
    }

    /// @notice calculate the first index of the three levels to store bids and rolling sums.
    /// Level 1 manages the X.00 part of the bid.
    /// If this provided price per token is 7.14 then this would return 7.
    /// This should not be used for prices per token 10.00 and greater, as these would be outright buys
    /// and are not persisted in the bids structure.
    /// @param _pricePerToken is the bid amount in DAI per ABQ token.
    /// @return _index the index of the first level in the structure for storing bids.
    function getLevel1Index(uint128 _pricePerToken)
        public
        pure
        returns (uint256 _index)
    {
        // Level 1 manages the X.00 part of the bid.
        return _pricePerToken / 100;
    }

    /// @notice calculate the second index of the three levels to store bids and rolling sums.
    /// Level 2 manages the 0.X0 part of the bid.
    /// If this provided price per token is 7.14 then this would return 1.
    /// This should not be used for prices per token 10.00 and greater, as these would be outright buys
    /// and are not not persisted in the bids structure.
    /// @param _pricePerToken is the bid amount in DAI per ABQ token.
    /// @return _index the index of the second level in the structure for storing bids.
    function getLevel2Index(uint128 _pricePerToken)
        public
        pure
        returns (uint256 _index)
    {
        // Level 2 manages the 0.X0 part of the bid
        return (_pricePerToken % 100) / 10;
    }

    /// @notice calculate the third index of the three levels to store bids and rolling sums.
    /// Level 3 manages the 0.0X part of the bid.
    /// If this provided price per token is 7.14 then this would return 4.
    /// This should not be used for prices per token 10.00 and greater, as these would be outright buys
    /// and are not not persisted in the bids structure.
    /// @param _pricePerToken is the bid amount in DAI per ABQ token.
    /// @return _index the index of the third level in the structure for storing bids.
    function getLevel3Index(uint128 _pricePerToken)
        public
        pure
        returns (uint256 _index)
    {
        // Level 3 manages the 0.0X part of the bid
        return _pricePerToken % 10;
    }

    /// @notice Get the specific bid for the given `_pricePerToken` and `_bidId`.
    /// @param _bidId The of the bid.
    /// @param _pricePerToken The price per ABQ token for the bid in DAI cents.
    /// @return _bidder The address that placed the bid.
    /// @return _amountOfTokensOutstanding The amount of ABQ tokens this bid still has an offer on.
    function getBid(uint256 _bidId, uint128 _pricePerToken)
        external
        view
        returns (address _bidder, uint128 _amountOfTokensOutstanding)
    {
        uint256 level1Index = getLevel1Index(_pricePerToken);
        uint256 level2Index = getLevel2Index(_pricePerToken);
        uint256 level3Index = getLevel3Index(_pricePerToken);
        
        LeafNode storage node = level3[level1Index][level2Index][level3Index];
        Bid storage bid = node.bids[_bidId];

        _bidder = bid.bidder;
        _amountOfTokensOutstanding = bid.amountOfTokens;
    }

    /// @notice Increase the `_bidId` that has a current DAI per ABQ price of `_oldPricePerToken` to a higher
    /// price per token of `_newPricePerToken`. Only the owner of the bid can do this.
    /// @param _bidId The id of the bid.
    /// @param _oldPricePerToken The current DAI per ABQ of the bid in DAI cents.
    /// @param _newPricePerToken the new DAI per ABQ of the bid in DAI cents. Must be more than `_oldPricePerToken`.
    /// @return _newBidId The id for the new bid that has the new DAI per ABQ price of `_newPricePerToken`.
    function increaseBid(uint256 _bidId, uint128 _oldPricePerToken, uint128 _newPricePerToken)
        external
        returns (uint256 _newBidId)
    {
        // CG: Ensure the auction isn't concluded yet
        require(amountLeft > 0, "ABQDAO/already-concluded-distribution");
        // CG: Ensure the new bid is larger than the previous bid
        require(_newPricePerToken > _oldPricePerToken, "ABQDAO/bid-too-small");
        // CG: Ensure the old price is less than the max price.
        require(_oldPricePerToken <= maxAmount, "ABQDAO/invalid-old-bid");
        // CG: The new price per token should be less than or equal to the max bid price.
        require(_newPricePerToken <= maxAmount, "ABQDAO/new-bid-too-large");

        // CG: Get the level 1 to level 3 indexes for the current bid.
        uint256 level1Index = getLevel1Index(_oldPricePerToken);
        uint256 level2Index = getLevel2Index(_oldPricePerToken);
        uint256 level3Index = getLevel3Index(_oldPricePerToken);

        // CG: Get the leaf node for the current bid
        LeafNode storage oldNode = level3[level1Index][level2Index][level3Index];

        // CG: Check for stack overflow attack
        require(_bidId < oldNode.bids.length, "ABQDAO/bidId-does-not-exist");

        // CG: Get the current bid
        Bid storage oldBid = oldNode.bids[_bidId];
        // CG: Make sure the current bid is owned by the sender
        require(oldBid.bidder == msg.sender, "ABQDAO/not-the-bidder");
        // CG: Make sure the current bid has not been executed yet
        require(oldBid.amountOfTokens > 0, "ABQDAO/bid-already-fully-processed");

        // CG: Remove the rolling sum for the current bid across level 1 to level 3
        uint128 tokenAmount = oldBid.amountOfTokens;
        level1[level1Index] = SafeMathTyped.sub256(level1[level1Index], tokenAmount);
        level2[level1Index][level2Index] = SafeMathTyped.sub256(level2[level1Index][level2Index], tokenAmount);
        oldNode.amountOfTokens == SafeMathTyped.sub256(oldNode.amountOfTokens, tokenAmount);
        // CG: Remove the current bet
        oldBid.amountOfTokens = 0;

        // CG: Transfer the increase bid ballance
        // CG: (_newPricePerToken - _oldPricePerToken) * tokenAmount * bidAssetScaling
        uint256 fundsToAddTotal = SafeMathTyped.mul256(SafeMathTyped.mul256(SafeMathTyped.sub256(_newPricePerToken, _oldPricePerToken), tokenAmount), bidAssetScaling);
        bool couldTransfer = bidAsset.transferFrom(msg.sender, address(this), fundsToAddTotal);
        require(couldTransfer, "ABQDAO/could-not-trasfer-funds");

        // CG: Get the new bid
        level1Index = getLevel1Index(_newPricePerToken);
        level2Index = getLevel2Index(_newPricePerToken);
        level3Index = getLevel3Index(_newPricePerToken);
        LeafNode storage node = level3[level1Index][level2Index][level3Index];

        level1[level1Index] = SafeMathTyped.add256(level1[level1Index], tokenAmount);
        level2[level1Index][level2Index] = SafeMathTyped.add256(level2[level1Index][level2Index], tokenAmount);
        node.amountOfTokens = SafeMathTyped.add256(node.amountOfTokens, tokenAmount);

        _newBidId = node.bids.length;
        node.bids.push(Bid(_newPricePerToken, tokenAmount, msg.sender));
        emit BidPlaced(msg.sender, _newPricePerToken, tokenAmount, _newBidId, true);
    }

    function outrightBuy(uint128 _oldPricePerToken, uint128 _pricePerToken, uint128 _amount)
        private
        returns (uint256 _bidId, uint128 _actualAmount)
    {
        // CG: If the amount of ABQ tokens being bought is greater than the amount left, then rather use the amount 
        // left.
        if (_amount > amountLeft)
        {
            _amount = amountLeft;
        }

        // CG: Transfer the amount of DAI for the outright buy to the fund address.
        uint256 bidFundsAdded = SafeMathTyped.mul256(SafeMathTyped.mul256(SafeMathTyped.sub256(_pricePerToken, _oldPricePerToken), _amount), bidAssetScaling);
        bool couldTransfer = bidAsset.transferFrom(msg.sender, address(this), bidFundsAdded);
        require(couldTransfer, "ABQDAO/could-not-pay-bid");
        uint256 bidFundsTotal = SafeMathTyped.mul256(SafeMathTyped.mul256(_pricePerToken, _amount), bidAssetScaling);
        couldTransfer = bidAsset.transfer(fundAddress, bidFundsTotal);
        require(couldTransfer, "ABQDAO/could-not-transfer-to-fund");

        emit BidPlaced(msg.sender, _pricePerToken, _amount, outrightBuyId, false);
        emit TokensAwarded(msg.sender, _amount);

        // CG: Allocate the ABQ to the sender and update the amount left on the auction.
        allocations[msg.sender] = allocations[msg.sender] + _amount;
        _bidId = outrightBuyId;
        _actualAmount = _amount;
        amountLeft = uint128(SafeMathTyped.sub256(amountLeft, _amount));
    }

    /// @notice Distribute ABQ tokens to the next eligible bids. 
    /// @param _maxNodesCount A parameter used throttle the maximum of nodes to evaluate. See the dev note for 
    /// more information.
    /// @dev The `_maxNodesCount` is used to throttle the 
    /// number of alloctaions to ensure the contract would not potentially run into an out of gas scenario, which
    /// could render the contract unable to be executed if such a throttle mechanism wasn't supplied.
    function distributeTimeslice(uint128 _maxNodesCount)
        external
    {
        /// CG: At least some nodes should be processed.
        require(_maxNodesCount > 0, "ABQDAO/max-nodes-count-may-not-be-zero");
        /// CG: Validate that the auction has not yet been fully allocated/distributed.
        require(amountLeft > 0, "ABQDAO/auction-concluded");
        /// CG: Validate that the auction has already started.
        require(startDate <= block.timestamp, "ABQDAO/not-started-yet");

        // CG: Of the current time slice being evaluated has already been fully allocated move on to the next timeslice.
        if (tokensLeftForCurrentTimeslice == 0)
        {
            if (lastAllocatedTimeslice == 0)
            {
                lastAllocatedTimeslice = startDate;
                tokensLeftForCurrentTimeslice = firstTokenAmountToAllocate;
            }
            else
            {
                lastAllocatedTimeslice = SafeMathTyped.add256(lastAllocatedTimeslice, timeWindow);
                if (amountLeft > tokensPerTimeslice)
                {
                    tokensLeftForCurrentTimeslice = tokensPerTimeslice;
                }
                else
                {
                    tokensLeftForCurrentTimeslice = tokensPerTimeslice;
                }
            }
        }

        // CG: If there are less ABQ tokens left on auction than is elligible for the current timeslice, then full amount of ABQ tokens left to do the allocation.
        if (tokensLeftForCurrentTimeslice > amountLeft)
        {
            tokensLeftForCurrentTimeslice = amountLeft;
        }

        // CG: Validate that the current tokens up for distribution may be distributed.
        require(block.timestamp >= lastAllocatedTimeslice, "ABQDAO/cannot-distribute-timeslice-yet");
        require(tokensLeftForCurrentTimeslice > 0, "ABQDAO/no-tokens-to-distribute");

        uint256 amountDistributed = 0;
        uint256 priceTotal = 0;
        uint128 maxAmountToDistribute = tokensLeftForCurrentTimeslice;
        bool hasValue = false;
        // CG: Evaluate the hist values for level 1 on the mapping structures first.
        for (uint128 level1Index = 9; level1Index < 10; level1Index -= 1)
        {
            uint256 level1Amount = level1[level1Index];
            if (level1Amount > 0)
            {
                hasValue = true;
                uint128 nodeAmountDistributed;
                uint256 priceAllocated;
                (_maxNodesCount, nodeAmountDistributed, priceAllocated) = distributeTimesliceForLevel1(level1Index, _maxNodesCount, maxAmountToDistribute);
                maxAmountToDistribute = uint128(SafeMathTyped.sub256(maxAmountToDistribute, nodeAmountDistributed));
                amountDistributed = amountDistributed + nodeAmountDistributed;
                priceTotal = SafeMathTyped.add256(priceTotal, priceAllocated);
            }

            if (level1Index == 0 || _maxNodesCount == 0 || maxAmountToDistribute == 0)
            {
                break;
            }
        }

        if (!hasValue)
        {
            // CG: No bids to fill the timeslice

            // CG: If no bids were allocated then move the ABQ tokens that was eligible to be allocated to the unallocatedAddress.
            amountLeft = uint128(SafeMathTyped.sub256(amountLeft, maxAmountToDistribute));
            amountUnallocated = amountUnallocated + maxAmountToDistribute;
            bool wasTransfered = allocationAsset.transfer(unallocatedAddress, SafeMathTyped.mul256(maxAmountToDistribute, allocatingAssetDecimalsScaling));
            require(wasTransfered, "ABQDAO/could-not-transfer-unallocated");
            tokensLeftForCurrentTimeslice = 0;
        }
        else
        {
            // CG: Update the amount of tokens left for hte auction and the current time period.
            amountLeft = uint128(SafeMathTyped.sub256(amountLeft, amountDistributed));
            tokensLeftForCurrentTimeslice = maxAmountToDistribute;
            // CG: Transfer the DAI for all ABQ sold to the treasury of the DAO.
            priceTotal = SafeMathTyped.mul256(priceTotal, bidAssetScaling);
            bool wasTransfered = bidAsset.transfer(fundAddress, priceTotal);
            require(wasTransfered, "ABQDAO/could-not-transfer-funds");
        }
    }

    function distributeTimesliceForLevel1(uint128 _level1Index, uint128 _nodesCount, uint128 _maxAmountToDistribute)
        private
        returns (uint128 _nodesCountLeft, uint128 _amountDistributed, uint256 _priceTotal)
    {
        _nodesCountLeft = _nodesCount;
        // CG: Find the highest level 2 bids for the provided _level1Index.
        for (uint128 level2Index = 9; level2Index < 10; level2Index -= 1)
        {
            uint256 level2Amount = level2[_level1Index][level2Index];
            if (level2Amount > 0)
            {
                uint128 nodeAmountDistributed;
                uint256 priceAllocated;
                (_nodesCountLeft, nodeAmountDistributed, priceAllocated) = distributeTimesliceForLevel2(_level1Index, level2Index, _nodesCountLeft, _maxAmountToDistribute);
                _maxAmountToDistribute = uint128(SafeMathTyped.sub256(_maxAmountToDistribute, nodeAmountDistributed));
                _amountDistributed = _amountDistributed + nodeAmountDistributed;
                _priceTotal = SafeMathTyped.add256(_priceTotal, priceAllocated);
            }

            if (level2Index == 0 || _nodesCountLeft == 0 || _maxAmountToDistribute == 0)
            {
                break;
            }
        }

        // CG: Update the level 1 rolling sum by subtracting the tokens allocated under this _level1Index.
        level1[_level1Index] = SafeMathTyped.sub256(level1[_level1Index], _amountDistributed);
    }

    function distributeTimesliceForLevel2(uint128 _level1Index, uint128 _level2Index, uint128 _nodesCount, uint128 _maxAmountToDistribute)
        private
        returns (uint128 _nodesCountLeft, uint128 _amountDistributed, uint256 _priceTotal)
    {
        _nodesCountLeft = _nodesCount;
        // CG: Find the highest level 3 bids for the provided _level1Index and _level2Index pairing.
        for (uint128 level3Index = 9; level3Index < 10; level3Index -= 1)
        {
            LeafNode storage node = level3[_level1Index][_level2Index][level3Index];
            if (node.amountOfTokens > 0)
            {
                uint128 nodeAmountDistributed;
                uint256 priceAllocated;
                (_nodesCountLeft, nodeAmountDistributed, priceAllocated) = distributeTimesliceForLevel3(node, _nodesCountLeft, _maxAmountToDistribute);
                _maxAmountToDistribute = uint128(SafeMathTyped.sub256(_maxAmountToDistribute, nodeAmountDistributed));
                _amountDistributed = _amountDistributed + nodeAmountDistributed;
                _priceTotal = SafeMathTyped.add256(_priceTotal, priceAllocated);
            }

            if (level3Index == 0 || _nodesCountLeft == 0 || _maxAmountToDistribute == 0)
            {
                break;
            }
        }

        // CG: Update the level 2 rolling sum by subtracting the tokens allocated under this _level1Index and _level2Index pairing.
        level2[_level1Index][_level2Index] = SafeMathTyped.sub256(level2[_level1Index][_level2Index], _amountDistributed);
    }

    function distributeTimesliceForLevel3(LeafNode storage _node, uint128 _nodesCount, uint128 _maxAmountToDistribute)
        private
        returns (uint128 _nodesCountLeft, uint128 _amountDistributed, uint256 _priceTotal)
    {
        _nodesCountLeft = _nodesCount;
        if (_node.amountOfTokens > 0)
        {
            uint256 currentIndex = _node.startIndex;
            while (_nodesCountLeft > 0 && currentIndex < _node.bids.length)
            {
                // CG: a uint128 minus a uint128 will always fit into a uint128 if overflow checking was done; overflow checking is done in SafeMathTyped.sub.
                uint128 distributionLeft = uint128(SafeMathTyped.sub256(uint256(_maxAmountToDistribute), uint256(_amountDistributed)));
                Bid storage currentBid = _node.bids[currentIndex];
                if (currentBid.amountOfTokens == 0)
                {
                    // no bid changes for zero bids just advance index

                    currentIndex = SafeMathTyped.add256(currentIndex, 1);
                    // CG: the while does check if _nodesCountLeft is greater than zero, so it is safe to subtract one here
                    _nodesCountLeft = _nodesCountLeft - 1;
                }
                else if (currentBid.amountOfTokens < distributionLeft)
                {
                    // Consume the full bid since the bid is less than the amount of distribution left.

                    // CG: this will fit into uint128 since _amountDistributed plus distributionLeft will be less than or equal to _maxAmountToDistribute, 
                    // which is a uint128. currentBid.amountOfTokens is capped by the if to be less than distributionLeft.
                    _amountDistributed = uint128(_amountDistributed + currentBid.amountOfTokens);
                    _priceTotal = SafeMathTyped.add256(_priceTotal, SafeMathTyped.mul256(currentBid.pricePerToken, currentBid.amountOfTokens));
                    allocateToBid(currentBid, currentBid.amountOfTokens);
                    
                    currentIndex = SafeMathTyped.add256(currentIndex, 1);
                    // CG: the while does check if _nodesCountLeft is greater than zero, so it is safe to subtract one here
                    _nodesCountLeft = _nodesCountLeft - 1;
                }
                else if (currentBid.amountOfTokens == distributionLeft)
                {
                    // Consume the full bid since the bid is the exact amount for the distributionLeft.

                    // CG: this will fit into uint128 since _amountDistributed plus distributionLeft will be less than or equal to _maxAmountToDistribute, 
                    // which is a uint128. currentBid.amountOfTokens is capped by the if to be equal to distributionLeft.
                    _amountDistributed = uint128(_amountDistributed + currentBid.amountOfTokens);
                    _priceTotal = SafeMathTyped.add256(_priceTotal, SafeMathTyped.mul256(currentBid.pricePerToken, currentBid.amountOfTokens));
                    allocateToBid(currentBid, currentBid.amountOfTokens);

                    currentIndex = SafeMathTyped.add256(currentIndex, 1);
                    // CG: the full allocation amount will be consumed so set nodesCountLeft to zero.
                    _nodesCountLeft = 0;
                }
                else if (currentBid.amountOfTokens > distributionLeft)
                {
                    // CG: Consume part of the bid since it is more that the distributionLeft.
                    _amountDistributed = uint128(SafeMathTyped.add256(_amountDistributed, distributionLeft));
                    _priceTotal = SafeMathTyped.add256(_priceTotal, SafeMathTyped.mul256(currentBid.pricePerToken, distributionLeft));
                    allocateToBid(currentBid, distributionLeft);

                    // CG: there is not enough left to allocate to fill the whole bid, so currentIndex doesn't move on.
                    // CG: the full allocation amount will be consumed so set nodesCountLeft to zero.
                    _nodesCountLeft = 0;
                }
            }
            _node.startIndex = currentIndex;
            // CG: Update the rolling sum for the level 3 total.
            _node.amountOfTokens = SafeMathTyped.sub256(_node.amountOfTokens, uint256(_amountDistributed));
        }
    }

    /// @notice The event emitted when ABQ tokens were awarded to a bidder.
    event TokensAwarded(address indexed bidder, uint128 amountOfTokens);
    function allocateToBid(Bid storage _bid, uint128 _amount)
        private
    {
        emit TokensAwarded(_bid.bidder, _amount);
        // CG: Remove the tokens from the bid
        _bid.amountOfTokens = uint128(SafeMathTyped.sub256(_bid.amountOfTokens, _amount));
        // CG: Add the tokens to the allocation for the bidder
        allocations[_bid.bidder] = allocations[_bid.bidder] + _amount;
    }

    /// @notice Return the about of ABQ tokens that have a bid for them.
    function totalTokensBiddedOn()
        public
        view
        returns (uint256 _total)
    {
        _total = level1[0];
        _total = SafeMathTyped.add256(_total, level1[1]);
        _total = SafeMathTyped.add256(_total, level1[2]);
        _total = SafeMathTyped.add256(_total, level1[3]);
        _total = SafeMathTyped.add256(_total, level1[4]);
        _total = SafeMathTyped.add256(_total, level1[5]);
        _total = SafeMathTyped.add256(_total, level1[6]);
        _total = SafeMathTyped.add256(_total, level1[7]);
        _total = SafeMathTyped.add256(_total, level1[8]);
        _total = SafeMathTyped.add256(_total, level1[9]);
    }
}