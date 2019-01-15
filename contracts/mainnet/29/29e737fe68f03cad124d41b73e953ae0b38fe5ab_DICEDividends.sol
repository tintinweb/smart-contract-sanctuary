pragma solidity ^0.4.25;

contract Exchange {
    function buy(address _referredBy) public payable returns(uint256);
    function exit() public;
}

contract DICEDividends {
    Exchange diceContract = Exchange(0xdEB2AA0478b2758e81d75A896E1257d3984D30D5);

    /// @notice Any funds sent here are for dividend payment.
    function () public payable {
    }

    /// @notice Distribute dividends to the exchange. Can be called
    ///     repeatedly until practically all dividends have been distributed.
    /// @param rounds How many rounds of dividend distribution do we want?
    function distribute(uint256 rounds) external {
        for (uint256 i = 0; i < rounds; i++) {
            if (address(this).balance < 0.001 ether) {
                // Balance is very low. Not worth the gas to distribute.
                break;
            }

            diceContract.buy.value(address(this).balance)(0x0);
            diceContract.exit();
        }
    }
}