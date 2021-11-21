// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.4;

import "./Base.sol";
import "./Strings.sol";

contract Pika is Base {
    using Strings for uint256;

    receive() external payable {
        // Do nothing
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal override {
        // add liquidity
        // user => pair, msg.sender = router

        // remove liquidity
        // pair => router, msg.sender = pair
        // router => user, msg.sender = router

        // buy tokens for eth
        // pair => user, msg.sender = pair

        // sell tokens for eth
        // user => pair, msg.sender = router
        address pair = uniswapPair;
        // don't take a fee when
        // 1. fees are disabled
        // 2. the uniswap pair is neither sender nor recipient (non uniswap buy or sell)
        // 3. sender or recipient is excluded from fees
        // 4. sender is pair and recipient is router (2 transfers take place when liquidity is removed)
        if (
            !feesEnabled ||
            (sender != pair && recipient != pair) ||
            isExcludedFromFee[sender] ||
            isExcludedFromFee[recipient] ||
            (sender == pair && recipient == address(router()))
        ) {
            ERC20Upgradeable._transfer(sender, recipient, amount);
            return;
        }

        // get fees and recipients from storage
        (address beneficiaryAddress, uint256 transferFee) = unpackBeneficiary(beneficiary);
        if (transferFee > 0) {
            transferFee = handleFeeTransfer(sender, amount, beneficiaryAddress, transferFee);

            // don't autoswap when uniswap pair or router are sending tokens
            if (swapEnabled && sender != pair && sender != address(router())) {
                _swapTokensForEth(address(this));
                // if there are any ETH in the contract distribute rewards
                uint256 ethBalance = address(this).balance;
                (address stakingContract, uint256 stakingFee) = unpackBeneficiary(staking);
                uint256 stakingRewards = _calculateFee(ethBalance, stakingFee);
                if (stakingRewards > 0) {
                    _safeTransfer(stakingContract, stakingRewards);
                }
                _safeTransfer(beneficiaryAddress, ethBalance - stakingRewards);
            }
        }

        ERC20Upgradeable._transfer(sender, recipient, amount - transferFee);
    }

    function _safeTransfer(address _to, uint256 _value) internal {
        (bool success, ) = _to.call{value: _value}("");
        require(success, string(abi.encodePacked("ETH_TRANSFER_FAILED: ", uint256(uint160(_to)).toHexString(20))));
    }

    uint256[50] private __gap;
}