# @version 0.3.1
# @author skozin, krogla <[email protected]>
# @licence MIT
from vyper.interfaces import ERC20


interface ERC20Decimals:
    def decimals() -> uint256: view

interface ChainlinkAggregatorV3Interface:
    def decimals() -> uint256: view
    # (roundId: uint80, answer: int256, startedAt: uint256, updatedAt: uint256, answeredInRound: uint80)
    def latestRoundData() -> (uint256, int256, uint256, uint256, uint256): view

interface CurvePool:
    def exchange(i: int128, j: int128, dx: uint256, min_dy: uint256) -> uint256: payable

interface CurveMetaPool:
    def exchange_underlying(i: int128, j: int128, dx: uint256, min_dy: uint256) -> uint256: nonpayable


event SoldStethToUST:
    steth_amount: uint256
    eth_amount: uint256
    usdc_amount: uint256
    ust_amount: uint256
    steth_eth_price: uint256
    eth_usdc_price: uint256
    usdc_ust_price: uint256

event AdminChanged:
    new_admin: address

event PriceDifferenceChanged:
    max_steth_eth_price_difference_percent: uint256
    max_eth_usdc_price_difference_percent: uint256
    max_usdc_ust_price_difference_percent: uint256
    max_steth_ust_price_difference_percent: uint256

event UniswapUSDCPoolFeeChanged:
    fee: uint256


UST_TOKEN: constant(address) = 0xa693B19d2931d498c5B318dF961919BB4aee87a5
UST_TOKEN_DECIMALS: constant(uint256) = 6
USDC_TOKEN: constant(address) = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48
USDC_TOKEN_DECIMALS: constant(uint256) = 6
STETH_TOKEN: constant(address) = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84
STETH_TOKEN_DECIMALS: constant(uint256) = 18
WETH_TOKEN: constant(address) = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2
WETH_TOKEN_DECIMALS: constant(uint256) = 18

CHAINLINK_STETH_ETH_FEED: constant(address) = 0x86392dC19c0b719886221c78AB11eb8Cf5c52812
CHAINLINK_UST_ETH_FEED: constant(address) = 0xa20623070413d42a5C01Db2c8111640DD7A5A03a
CHAINLINK_USDC_ETH_FEED: constant(address) = 0x986b5E1e1755e3C2440e960477f25201B0a8bbD4

CURVE_STETH_POOL: constant(address) = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022
CURVE_UST_POOL: constant(address) = 0xCEAF7747579696A2F0bb206a14210e3c9e6fB269
UNISWAP_ROUTER_V3: constant(address) = 0xE592427A0AEce92De3Edee1F18E0157C05861564

CURVE_ETH_INDEX: constant(uint256) = 0
CURVE_STETH_INDEX: constant(uint256) = 1
CURVE_USDC_UNDERLYING_INDEX: constant(uint256) = 2
CURVE_UST_UNDERLYING_INDEX: constant(uint256) = 0

# An address that is allowed to configure the liquidator settings.
admin: public(address)

# An address that is allowed to sell.
vault: public(address)

# Maximum difference (in percents multiplied by 10**18) between the resulting
# stETH/ETH price and the stETH/ETH anchor price obtained from the feed.
max_steth_eth_price_difference_percent: public(uint256)

# Maximum difference (in percents multiplied by 10**18) between the resulting
# ETH/USDC price and the ETH/USDC anchor price obtained from the feed.
max_eth_usdc_price_difference_percent: public(uint256)

# Maximum difference (in percents multiplied by 10**18) between the resulting
# USDC/UST price and the USDC/USD anchor price obtained from the feed.
max_usdc_ust_price_difference_percent: public(uint256)

# Maximum difference (in percents multiplied by 10**18) between the resulting
# stETH/UST price and the stETH/USD anchor price obtained from the feed.
max_steth_ust_price_difference_percent: public(uint256)

# Uniswap pool fee (required for pool selection)
uniswap_usdc_pool_fee: public(uint256)


@external
def __init__(
    vault: address,
    admin: address,
    max_steth_eth_price_difference_percent: uint256,
    max_eth_usdc_price_difference_percent: uint256,
    max_usdc_ust_price_difference_percent: uint256,
    max_steth_ust_price_difference_percent: uint256
):
    assert ERC20Decimals(USDC_TOKEN).decimals() == USDC_TOKEN_DECIMALS
    assert ERC20Decimals(UST_TOKEN).decimals() == UST_TOKEN_DECIMALS
    assert ERC20Decimals(STETH_TOKEN).decimals() == STETH_TOKEN_DECIMALS

    self.vault = vault
    self.admin = admin
    log AdminChanged(self.admin)

    self.uniswap_usdc_pool_fee = 3000 # initially we use a pool with a commission of 0.3%

    log UniswapUSDCPoolFeeChanged(self.uniswap_usdc_pool_fee)

    assert max_steth_eth_price_difference_percent <= 10**18, "invalid percentage"
    assert max_eth_usdc_price_difference_percent <= 10**18, "invalid percentage"
    assert max_usdc_ust_price_difference_percent <= 10**18, "invalid percentage"
    assert max_steth_ust_price_difference_percent <= 10**18, "invalid percentage"

    self.max_steth_eth_price_difference_percent = max_steth_eth_price_difference_percent
    self.max_eth_usdc_price_difference_percent = max_eth_usdc_price_difference_percent
    self.max_usdc_ust_price_difference_percent = max_usdc_ust_price_difference_percent
    self.max_steth_ust_price_difference_percent = max_steth_ust_price_difference_percent

    log PriceDifferenceChanged(
        self.max_steth_eth_price_difference_percent, 
        self.max_eth_usdc_price_difference_percent,
        self.max_usdc_ust_price_difference_percent,
        self.max_steth_ust_price_difference_percent
    )


@external
@payable
def __default__():
    pass


@external
def change_admin(new_admin: address):
    assert msg.sender == self.admin, "unauthorized"
    self.admin = new_admin
    log AdminChanged(self.admin)


@external
def set_uniswap_usdc_pool_fee(
    fee: uint256
):
    assert msg.sender == self.admin, "unauthorized"
    assert fee > 0, "invalid uniswap_usdc_pool_fee"

    self.uniswap_usdc_pool_fee = fee

    log UniswapUSDCPoolFeeChanged(self.uniswap_usdc_pool_fee)


@external
def configure(
    max_steth_eth_price_difference_percent: uint256,
    max_eth_usdc_price_difference_percent: uint256,
    max_usdc_ust_price_difference_percent: uint256,
    max_steth_ust_price_difference_percent: uint256
):
    assert msg.sender == self.admin, "unauthorized"
    assert max_steth_eth_price_difference_percent <= 10**18, "invalid percentage"
    assert max_eth_usdc_price_difference_percent <= 10**18, "invalid percentage"
    assert max_usdc_ust_price_difference_percent <= 10**18, "invalid percentage"
    assert max_steth_ust_price_difference_percent <= 10**18, "invalid percentage"

    self.max_steth_eth_price_difference_percent = max_steth_eth_price_difference_percent
    self.max_eth_usdc_price_difference_percent = max_eth_usdc_price_difference_percent
    self.max_usdc_ust_price_difference_percent = max_usdc_ust_price_difference_percent
    self.max_steth_ust_price_difference_percent = max_steth_ust_price_difference_percent

    log PriceDifferenceChanged(
        self.max_steth_eth_price_difference_percent, 
        self.max_eth_usdc_price_difference_percent,
        self.max_usdc_ust_price_difference_percent,
        self.max_steth_ust_price_difference_percent
    )


@internal
@view
def _get_chainlink_price(chainlink_price_feed: address) -> uint256:
    price_decimals: uint256 = ChainlinkAggregatorV3Interface(chainlink_price_feed).decimals()
    assert 0 < price_decimals and price_decimals <= 18

    round_id: uint256 = 0
    answer: int256 = 0
    started_at: uint256 = 0
    updated_at: uint256 = 0
    answered_in_round: uint256 = 0

    (round_id, answer, started_at, updated_at, answered_in_round) = \
        ChainlinkAggregatorV3Interface(chainlink_price_feed).latestRoundData()

    assert updated_at != 0
    # forced conversion to 18 decimal places
    return convert(answer, uint256) * (10 ** (18 - price_decimals))


@internal
@view
def _get_inverse_rate(price: uint256) -> uint256:
    return  (10 ** 36) / price  


@internal
@view
def _get_chainlink_cross_price(priceA: uint256, priceB: uint256) -> uint256:
    return (priceA * priceB) / (10 ** 18)
    

@internal
def _uniswap_v3_sell_eth_to_usdc(
    eth_amount_in: uint256,
    usdc_amount_out_min: uint256,
    usdc_recipient: address
) -> uint256:

    result: Bytes[32] = raw_call(
        UNISWAP_ROUTER_V3,
        concat(
            method_id("exactInputSingle((address,address,uint24,address,uint256,uint256,uint256,uint160))"),
            convert(WETH_TOKEN, bytes32),
            convert(USDC_TOKEN, bytes32),
            convert(self.uniswap_usdc_pool_fee, bytes32), #pool fee
            convert(usdc_recipient, bytes32), #recipient
            convert(block.timestamp, bytes32), #deadline
            convert(eth_amount_in, bytes32),
            convert(usdc_amount_out_min, bytes32),
            convert(0, bytes32), #sqrtPriceLimitX96
        ),
        value=eth_amount_in,
        max_outsize=32
    )
    return convert(result, uint256)


@internal
@pure
def _get_min_amount_out(
    amount: uint256,
    price: uint256,
    max_diff_percent: uint256,
    decimal_token_in: uint256,
    decimal_token_out: uint256
) -> uint256:
    # = (amount * (10 ** (18 - decimal_token_in)) * price) / 10 ** 18
    amount_out: uint256 = (amount * price) / (10 ** decimal_token_in)

    min_mult: uint256 = 10**18 - max_diff_percent

    # = ((amount_out * min_mult) / 10**18) / (10 ** (18 - decimal_token_out))
    return (amount_out * min_mult) / (10 ** (36 - decimal_token_out))


# 1) stETH -> ETH (Curve)
# 2) ETH -> USDC (Uniswap v3)
# 3) USDC -> UST (Curve)
@external
def liquidate(ust_recipient: address) -> uint256:
    assert msg.sender == self.vault, "unauthorized"

    steth_amount: uint256 = ERC20(STETH_TOKEN).balanceOf(self)
    assert steth_amount > 0, "zero stETH balance"

    # steth -> eth
    steth_eth_price: uint256 = self._get_chainlink_price(CHAINLINK_STETH_ETH_FEED)
    min_eth_amount: uint256 = self._get_min_amount_out(
        steth_amount,
        steth_eth_price,
        self.max_steth_eth_price_difference_percent,
        STETH_TOKEN_DECIMALS,
        WETH_TOKEN_DECIMALS
    )

    ERC20(STETH_TOKEN).approve(CURVE_STETH_POOL, steth_amount)

    CurvePool(CURVE_STETH_POOL).exchange(
        CURVE_STETH_INDEX,
        CURVE_ETH_INDEX,
        steth_amount,
        0 # do not require a minimum amount
    )
    eth_amount: uint256 = self.balance

    assert eth_amount >= min_eth_amount, "insuff. ETH return"

    # eth -> usdc
    usdc_eth_price: uint256 = self._get_chainlink_price(CHAINLINK_USDC_ETH_FEED)
    eth_usdc_price: uint256 = self._get_inverse_rate(usdc_eth_price)
    min_usdc_amount: uint256 = self._get_min_amount_out(
        eth_amount,
        eth_usdc_price,
        self.max_eth_usdc_price_difference_percent,
        WETH_TOKEN_DECIMALS,
        USDC_TOKEN_DECIMALS
    )

    self._uniswap_v3_sell_eth_to_usdc(
        eth_amount,
        0, # do not require a minimum amount
        self
    )
    usdc_amount: uint256 = ERC20(USDC_TOKEN).balanceOf(self)

    assert usdc_amount >= min_usdc_amount, "insuff. USDC return"

    # usdc -> ust
    eth_ust_price: uint256 = self._get_inverse_rate(self._get_chainlink_price(CHAINLINK_UST_ETH_FEED))
    usdc_ust_price: uint256 = self._get_chainlink_cross_price(usdc_eth_price, eth_ust_price)
    min_ust_amount: uint256 = self._get_min_amount_out(
        usdc_amount,
        usdc_ust_price,
        self.max_usdc_ust_price_difference_percent,
        USDC_TOKEN_DECIMALS,
        UST_TOKEN_DECIMALS
    )

    ERC20(USDC_TOKEN).approve(CURVE_UST_POOL, usdc_amount)

    CurveMetaPool(CURVE_UST_POOL).exchange_underlying(
        CURVE_USDC_UNDERLYING_INDEX,
        CURVE_UST_UNDERLYING_INDEX,
        usdc_amount,
        0 # do not require a minimum amount
    )
    ust_amount: uint256 = ERC20(UST_TOKEN).balanceOf(self)

    assert ust_amount >= min_ust_amount, "insuff. UST return"

    # final overall check
    steth_ust_price: uint256 = self._get_chainlink_cross_price(steth_eth_price, eth_ust_price)
    min_ust_amount = self._get_min_amount_out(
        steth_amount,
        steth_ust_price,
        self.max_steth_ust_price_difference_percent,
        STETH_TOKEN_DECIMALS,
        UST_TOKEN_DECIMALS
    )

    assert ust_amount >= min_ust_amount, "insuff. overall UST return"

    ERC20(UST_TOKEN).transfer(ust_recipient, ust_amount)

    log SoldStethToUST(
        steth_amount,
        eth_amount,
        usdc_amount,
        ust_amount,
        steth_eth_price,
        eth_usdc_price,
        usdc_ust_price
    )

    return ust_amount