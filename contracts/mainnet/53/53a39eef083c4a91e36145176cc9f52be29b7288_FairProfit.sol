pragma solidity ^0.4.25;

contract FairExchange {
    function buy(address _referredBy) public payable returns(uint256);
    function exit() public;
}

contract FairProfit {
    FairExchange fairContract = FairExchange(0xdE2b11b71AD892Ac3e47ce99D107788d65fE764e);
    
    /// @notice Any funds sent here are for dividend payment.
    function () public payable {
    }
    
    /// @notice Distribute dividends to the FairExchange contract. Can be called
    ///     repeatedly until practically all dividends have been distributed.
    /// @param rounds How many rounds of dividend distribution do we want?
    function distribute(uint256 rounds) external {
        for (uint256 i = 0; i < rounds; i++) {
            if (address(this).balance < 0.001 ether) {
                // Balance is very low. Not worth the gas to distribute.
                break;
            }
            
            fairContract.buy.value(address(this).balance)(0x0);
            fairContract.exit();
        }
    }
}