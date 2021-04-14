// SPDX-License-Identifier: UNLICENSED
// This code is the property of the Aardbanq DAO.
// The Aardbanq DAO is located at 0x829c094f5034099E91AB1d553828F8A765a3DaA1 on the Ethereum Main Net.
// It is the author's wish that this code should be open sourced under the MIT license, but the final 
// decision on this would be taken by the Aardbanq DAO with a vote once sufficient ABQ tokens have been 
// distributed.
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

pragma solidity >=0.7.0;
import "./Minter.sol";
import "./Erc20.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";
import "./IUniswapV2Pair.sol";
import "./IPricer.sol";
import "./SafeMathTyped.sol";
import "./ILiquidityEstablisher.sol";

/// @notice A contract to offer initial liquidity purchase and an reward.
contract InitialLiquidityOffering is ILiquidityEstablisher
{
    /// @notice The time in unix (seconds) timestamp that the offer closes.
    uint64 public offerCloseTime;
    /// @notice The address funds are sent to.
    address public treasury;
    /// @notice The token that is offered.
    Erc20 public tokenOffer;
    /// @notice The time in unix (seconds) timestamp that the liquidity may be claimed.
    uint64 public liquidityReleaseTime;
    /// @notice The token liquidity will be established with.
    Erc20 public liquidityToken;
    /// @notice Flag to indicate if liquidity has been established.
    bool public isLiquidityEstablished;
    /// @notice The minter of the token on offer.
    Minter public minter;
    /// @notice The uniswap router used to establish liquidity.
    IUniswapV2Router02 public uniswapRouter;
    /// @notice The ICO used to establish the price at which liquidity will be established.
    IPricer public pricer;
    /// @notice The maximum liquidity (priced in liquidityToken) up for sale.
    uint256 public maxLiquidityAllowed;
    /// @notice The total liquidity sold so far.
    uint256 public totalLiquidityProvided;

    /// @notice The total liquidity provided by each address (priced in liquidityToken).
    mapping(address => uint256) public liquidityBalances;

    /// @notice Constructs an initial liquidity token offering.
    /// @param _offerCloseTime The time in unix (seconds) timestamp that the offer closes.
    /// @param _tokenOffer The token on offer.
    /// @param _liquidityReleaseTime The time in unix (secods) timestamp that the liquidity will be released.
    /// @param _liquidityToken The token liquidity will be sold in. (like DAI)
    /// @param _minter The minter that can mint _tokenOffer tokens.
    /// @param _uniswapRouter The uniswap router to use.
    /// @param _maxLiquidityAllowed The maximum liquidity (priced in _liquidityToken) on sale.
    constructor (uint64 _offerCloseTime, address _treasury, Erc20 _tokenOffer, uint64 _liquidityReleaseTime, Erc20 _liquidityToken, 
        Minter _minter, IUniswapV2Router02 _uniswapRouter, uint256 _maxLiquidityAllowed)
    {
        offerCloseTime = _offerCloseTime;
        treasury = _treasury;
        tokenOffer = _tokenOffer;
        liquidityReleaseTime = _liquidityReleaseTime;
        liquidityToken = _liquidityToken;
        minter = _minter;
        uniswapRouter = _uniswapRouter;
        maxLiquidityAllowed = _maxLiquidityAllowed;
    }

    /// @notice Returns true if either liquidity has been established or the ILO has been closed for more than 7 days. False otherwise.
    /// @return _isEstablishedOrExpired True if either liquidity has been established or the ILO has been closed for more than 7 days. False otherwise.
    function isLiquidityEstablishedOrExpired()
        external
        override
        view
        returns (bool _isEstablishedOrExpired)
    {
        return isLiquidityEstablished || (offerCloseTime + 7 days <= block.timestamp); 
    }

    /// @notice Set the ICO address to use to establish the price of the token on offer.
    function setPricer(IPricer _pricer) 
        external
    {
        require(address(pricer) == address(0), "ABQICO/pricer-already-set");
        pricer = _pricer;
    }

    /// @notice Event emitted when liquidity was provided.
    /// @param to The address that provided the liquidity.
    /// @param amount The amount of liquidity (priced in liquidityToken) that was provided.
    event LiquidityOfferReceipt(address to, uint256 amount);
    /// @notice Provide liquidity. Liquidity is paid for from the msg.sender.
    /// @param _target The address that will own and receive the liquidity pool tokens and reward.
    /// @param _amount The amount of liquidity to offer (priced in liquidityToken).
    function provideLiquidity(address _target, uint256 _amount)
        external
    {
        require(offerCloseTime >= block.timestamp && maxLiquidityAllowed > totalLiquidityProvided, "ABQILO/offer-closed");

        // CG: ensure only whole token amounts have no values in the last 18 places
        _amount = (_amount / 1 ether) * 1 ether;
        require(_amount >= 1 ether, "ABQILO/amount-too-small");

        // CG: ensure amounts don't go above max allowed
        uint256 amountLeft = SafeMathTyped.sub256(maxLiquidityAllowed, totalLiquidityProvided);
        if (_amount > amountLeft)
        {
            _amount = amountLeft;
        }

        // CG: transfer funds
        bool couldTransfer = liquidityToken.transferFrom(msg.sender, address(this), _amount);
        require(couldTransfer, "ABQILO/could-not-transfer");

        // CG: account for funds
        totalLiquidityProvided = SafeMathTyped.add256(totalLiquidityProvided, _amount);
        liquidityBalances[_target] = SafeMathTyped.add256(liquidityBalances[_target], _amount);

        emit LiquidityOfferReceipt(_target, _amount);
    }

    /// @notice Event emitted when liquidity is established.
    /// @param liquidityAssetAmount The amount of liquidityToken that was contributed.
    /// @param offerTokenAmount The amount of the token on offer that was added as liquidity.
    /// @param liquidityTokenAmount The amount of liquidity pool tokens that was minted.
    event LiquidityEstablishment(uint256 liquidityAssetAmount, uint256 offerTokenAmount, uint256 liquidityTokenAmount);
    /// @notice Establish liquidity if the sale period ended or the liquidity sale has been sold out.
    function establishLiquidity()
        external
    {
        require(offerCloseTime < block.timestamp || maxLiquidityAllowed == totalLiquidityProvided, "ABQILO/offer-still-open");
        require(!isLiquidityEstablished, "ABQILO/liquidity-already-established");

        if (totalLiquidityProvided > 0)
        {
            uint256 currentPrice = pricer.currentPrice();
            if (currentPrice > 10 ether)
            {
                // CG: in the event the ICO was sold out.
                currentPrice = 10 ether;
            }
            uint256 totalOfferProvided = SafeMathTyped.mul256(totalLiquidityProvided / currentPrice, 1 ether);
            minter.mint(address(this), totalOfferProvided);

            bool isOfferApproved = tokenOffer.approve(address(uniswapRouter), totalOfferProvided);
            require(isOfferApproved, "ABQICO/could-not-approve-offer");
            bool isLiquidityApproved = liquidityToken.approve(address(uniswapRouter), totalLiquidityProvided);
            require(isLiquidityApproved, "ABQICO/could-not-approve-liquidity");

            (, , uint256 liquidityTokensCount) = uniswapRouter.addLiquidity(address(liquidityToken), address(tokenOffer), totalLiquidityProvided, totalOfferProvided, 0, 0, address(this), block.timestamp);

            IUniswapV2Factory factory = IUniswapV2Factory(uniswapRouter.factory());
            IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(address(tokenOffer), address(liquidityToken)));
            require(address(pair) != address(0), "ABQILO/pair-not-created");
            bool couldSendDaoShare = pair.transfer(treasury, liquidityTokensCount / 2);
            require(couldSendDaoShare, "ABQILO/could-not-send");

            emit LiquidityEstablishment(totalLiquidityProvided, totalOfferProvided, liquidityTokensCount);
        }

        isLiquidityEstablished = true;
    }

    /// @notice Event emitted when liquidity pool tokens are claimed.
    /// @param to The address the claim was for.
    /// @param amount The amount of liquidity pool tokens that was claimed.
    /// @param reward The reward (in the token on offer) that was also claimed.
    event Claim(address to, uint256 amount, uint256 reward);
    /// @notice Claim liquidity pool tokens and the reward after liquidity has been released.
    /// @param _for The address to release the liquidity pool tokens and the reward for.
    function claim(address _for)
        external
    {
        require(liquidityReleaseTime <= block.timestamp, "ABQILO/liquidity-locked");
        require(isLiquidityEstablished, "ABQILO/liquidity-not-established");

        // CG: we can divide be 1 ether since we made sure values does not include any values in the last 18 decimals. See the provideLiquidity token.
        uint256 claimShareFull = liquidityBalances[_for];
        if (claimShareFull == 0)
        {
            return;
        }
        uint256 claimShare = (claimShareFull / 1 ether);
        uint256 claimPool = (totalLiquidityProvided / 1 ether);

        // CG: remove claim share from accounts
        totalLiquidityProvided = SafeMathTyped.sub256(totalLiquidityProvided, claimShareFull);
        liquidityBalances[_for] = 0;

        // CG: get uniswap pair
        IUniswapV2Factory factory = IUniswapV2Factory(uniswapRouter.factory());
        IUniswapV2Pair pair = IUniswapV2Pair(factory.getPair(address(tokenOffer), address(liquidityToken)));
        require(address(pair) != address(0), "ABQILO/pair-not-created");
        uint256 pairBalance = pair.balanceOf(address(this));

        // CG: transfer claim
        uint256 claimTotal = SafeMathTyped.mul256(pairBalance, claimShare) / claimPool;
        bool couldTransfer = pair.transfer(_for, claimTotal);
        require(couldTransfer, "ABQILO/could-not-transfer");

        // CG: mint reward: 25% of original contribution as reward tokens.
        uint256 reward = SafeMathTyped.mul256(claimShareFull, 25) / 100;
        minter.mint(_for, reward);

        emit Claim(_for, claimTotal, reward);
    }
}