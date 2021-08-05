// SPDX-License-Identifier: UNLICENSED
// This code is the property of the Aardbanq DAO.
// The Aardbanq DAO is located at 0x829c094f5034099E91AB1d553828F8A765a3DaA1 on the Ethereum Main Net.
// It is the author's wish that this code should be open sourced under the MIT license, but the final 
// decision on this would be taken by the Aardbanq DAO with a vote once sufficient ABQ tokens have been 
// distributed.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity >=0.7.0;
import "./SafeMathTyped.sol";
import "./Erc20.sol";
import './Minter.sol';
import "./IPricer.sol";
import "./ILiquidityEstablisher.sol";

/// @notice Allow buying of tokens in batches of increasing price.
contract ScaleBuying is IPricer
{
    /// @notice The token to use for purchasing
    Erc20 public paymentAsset;
    /// @notice The token that is being bought
    Erc20 public boughtAsset;
    /// @notice The minter for the token being bought
    Minter public minter;
    /// @notice The date in unix timestamp (seconds) when the sale closes.
    uint64 public closingDate;
    /// @notice The address to which the funds should be sent to.
    address public treasury;
    /// @notice The location of the ILO, used to know when tokens can be claimed.
    ILiquidityEstablisher public liquidityEstablisher;
    /// @notice The amount that has been awarded so far.
    uint256 public amountAwarded;
    /// @notice The initial price for the sale.
    uint256 public initialPrice;
    /// @notice The price increase for each token block.
    uint256 public priceIncrease;
    /// @notice The amount of tokens per block.
    uint256 public tokensPerPriceBlock;
    /// @notice The number of blocks up for sale.
    uint256 public maxBlocks;

    /// @notice The amounts of tokens claimable by an address.
    mapping(address => uint256) public amountsClaimable;

    /// @notice Constructs a ScaleBuying
    /// @param _paymentAsset The token address to be used for payment.
    /// @param _boughtAsset The token address to be issued.
    /// @param _minter The minter for the issued token.
    /// @param _treasury The address to receive all funds.
    /// @param _initialPrice The initial price per token.
    /// @param _priceIncrease The increase of the price per token for each block.
    /// @param _tokensPerPriceBlock The tokens in each block.
    /// @param _maxBlocks The maximum number of blocks on sale.
    /// @param _closingDate The date in unix (seconds) timestamp that the sale will close.
    constructor (Erc20 _paymentAsset, Erc20 _boughtAsset, Minter _minter, address _treasury, uint256 _initialPrice, 
        uint256 _priceIncrease, uint256 _tokensPerPriceBlock, uint256 _maxBlocks, uint64 _closingDate)
    {
        paymentAsset = _paymentAsset;
        boughtAsset = _boughtAsset;
        minter = _minter;
        treasury = _treasury;
        amountAwarded = 0;
        initialPrice = _initialPrice;
        priceIncrease = _priceIncrease;
        tokensPerPriceBlock = _tokensPerPriceBlock;
        maxBlocks = _maxBlocks;
        closingDate = _closingDate;

        allocateTokensRaisedByAuction();
    }

    // CG: This allocates the amount of tokens that was already bought on auction before\
    //     switching over to this Scale Buying.
    function allocateTokensRaisedByAuction() 
        private
    {
        uint256 price = initialPrice;
        
        uint256 buyerAAmount = 7165 ether;
        amountsClaimable[0xEE779e4b3e7b11454ed80cFE12Cf48ee3Ff4579E] = buyerAAmount;
        emit Bought(0xEE779e4b3e7b11454ed80cFE12Cf48ee3Ff4579E, buyerAAmount, price);
        
        uint256 buyerBAmount = 4065 ether;
        amountsClaimable[0x6C4f3Db0E743A9e8f44A756b6585192B358D7664] = buyerBAmount;
        emit Bought(0x6C4f3Db0E743A9e8f44A756b6585192B358D7664, buyerAAmount, price);

        uint256 buyerCAmount = 355 ether;
        amountsClaimable[0x0FB79E6C0F5447ffe36a0050221275Da487b0E09] = buyerCAmount;
        emit Bought(0x0FB79E6C0F5447ffe36a0050221275Da487b0E09, buyerAAmount, price);

        amountAwarded = buyerAAmount + buyerBAmount + buyerCAmount;
    }

    /// @notice Set the ILO to use to track if liquidity has been astablished and thus claims can be allowed.
    /// @param _liquidityEstablisher The ILO.
    function setLiquidityEstablisher(ILiquidityEstablisher _liquidityEstablisher)
        external
    {
        require(address(liquidityEstablisher) == address(0), "ABQDAO/already-set");

        liquidityEstablisher = _liquidityEstablisher;
    }

    /// @notice The event emitted when a claim is executed.
    /// @param claimer The address the claim has been processed for.
    /// @param amount The amount that was claimed.
    event Claimed(address indexed claimer, uint256 amount);
    /// @notice Claim ABQ bought for the given address. Claims can only be processed after liquidity has been established.
    /// @param _target The address to process claims for.
    function claim(address _target)
        external
    {
        // CG: Claims cannot be executed before liquidity is established or closed more than a week ago.
        require(liquidityEstablisher.isLiquidityEstablishedOrExpired(), "ABQDAO/cannot-claim-yet");

        uint256 amountClaimable = amountsClaimable[_target];
        if (amountClaimable > 0)
        {
            bool isSuccess = boughtAsset.transfer(_target, amountClaimable);
            require(isSuccess, "ABQDAO/could-not-transfer-claim");
            amountsClaimable[_target] = 0;
            emit Claimed(_target, amountClaimable);
        }
    }

    /// @notice The event emitted when tokens are bought.
    /// @param buyer The address that may claim the tokens.
    /// @param amount The amount of token bought.
    /// @param pricePerToken The price per token that the tokens were bought for.
    event Bought(address indexed buyer, uint256 amount, uint256 pricePerToken);
    /// @notice Buy tokens in the current block.
    /// @param _paymentAmount The amount to spend. This will be transfered from msg.sender who should approved this amount first.
    /// @param _target The address that the amounts would be bought for. Tokens are distributed after calling the claim method.
    function buy(uint256 _paymentAmount, address _target) 
        external
        returns (uint256 _paymentLeft)
    {
        // CG: only allow buys before the ico closes.
        require(block.timestamp <= closingDate, "ABQDAO/ico-concluded");

        (uint256 paymentLeft, uint256 paymentDue) = buyInBlock(_paymentAmount, _target);
        // CG: transfer payment
        if (paymentDue > 0)
        {
            bool isSuccess = paymentAsset.transferFrom(msg.sender, treasury, paymentDue);
            require(isSuccess, "ABQDAO/could-not-pay");
        }
        return paymentLeft;
    }

    function buyInBlock(uint256 _paymentAmount, address _target)
        private
        returns (uint256 _paymentLeft, uint256 _paymentDue)
    {
        uint256 currentBlockIndex = currentBlock();
        uint256 tokensLeft = tokensLeftInBlock(currentBlockIndex);

        if (currentBlockIndex >= maxBlocks)
        {
            // CG: If all block are sold out, then amount bought should be zero.
            return (_paymentAmount, 0);
        }
        else
        {
            uint256 currentPriceLocal = currentPrice();
            uint256 tokensCanPayFor = _paymentAmount / currentPriceLocal;
            if (tokensCanPayFor == 0)
            {
                return (_paymentAmount, 0);
            }
            if (tokensCanPayFor > (tokensLeft / 1 ether))
            {
                tokensCanPayFor = tokensLeft / 1 ether;
            }

            // CG: Get the amount of tokens that can be bought in this block.
            uint256 paymentDue = SafeMathTyped.mul256(tokensCanPayFor, currentPriceLocal);
            tokensCanPayFor = SafeMathTyped.mul256(tokensCanPayFor, 1 ether);
            amountsClaimable[_target] = SafeMathTyped.add256(amountsClaimable[_target], tokensCanPayFor);
            amountAwarded = SafeMathTyped.add256(amountAwarded, tokensCanPayFor);
            minter.mint(address(this), tokensCanPayFor);
            emit Bought(_target, tokensCanPayFor, currentPriceLocal);
            uint256 paymentLeft = SafeMathTyped.sub256(_paymentAmount, paymentDue);
            
            if (paymentLeft <= currentPriceLocal)
            {
                return (paymentLeft, paymentDue);
            }
            else
            {
                // CG: should this block be sold out, buy the remainder in the next box.
                (uint256 subcallPaymentLeft, uint256 subcallPaymentDue) = buyInBlock(paymentLeft, _target);
                paymentDue = SafeMathTyped.add256(paymentDue, subcallPaymentDue);
                return (subcallPaymentLeft, paymentDue);
            }
        }
    }

    /// @notice Get the current price per token.
    /// @return _currentPrice The current price per token.
    function currentPrice()
        view
        public
        override
        returns (uint256 _currentPrice)
    {
        return SafeMathTyped.add256(initialPrice, SafeMathTyped.mul256(currentBlock(), priceIncrease));
    }

    /// @notice Get the current block number, starting at 0.
    function currentBlock() 
        view
        public
        returns (uint256 _currentBlock)
    {
        return amountAwarded / tokensPerPriceBlock;
    }

    /// @notice Get the amount of tokens left in a given block.
    /// @param _block The block to get the number of tokens left for.
    /// @return _tokensLeft The number of tokens left in the given _block.
    function tokensLeftInBlock(uint256 _block)
        view
        public
        returns (uint256 _tokensLeft)
    {
        uint256 currentBlockIndex = currentBlock();

        if (_block > maxBlocks || _block < currentBlockIndex)
        {
            return 0;
        }

        if (_block == currentBlockIndex)
        {
            //CG: non overflow code: return ((currentBlockIndex + 1) * tokensPerPriceBlock) - amountAwarded;
            return SafeMathTyped.sub256(SafeMathTyped.mul256(SafeMathTyped.add256(currentBlockIndex, 1), tokensPerPriceBlock), amountAwarded);
        }
        else
        {
            return tokensPerPriceBlock;
        }
    }
}