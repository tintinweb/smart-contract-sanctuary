# @version 0.2.11
"""
@title Curve aETH Pool Rate Calculator 
@author Curve.Fi
@license Copyright (c) Curve.Fi, 2021 - all rights reserved
@notice Logic for calculating exchange rate between aETH -> ETH
"""

interface aETH:
    def ratio() -> uint256: view


@view
@external
def get_rate(_coin: address) -> uint256:
    """
    @notice Calculate the exchange rate for 1 aETH -> ETH
    @param _coin The aETH contract address
    @return The exchange rate of 1 aETH in ETH
    """
    result: uint256 = aETH(_coin).ratio()
    return 10 ** 36 / result