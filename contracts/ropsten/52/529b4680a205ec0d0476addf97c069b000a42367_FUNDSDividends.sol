pragma solidity ^0.4.24;

contract FUNDS {
    function buy(address _referredBy) public payable returns(uint256);
    function exit() public;
}

contract FUNDSDividends {
    FUNDS fundsContract = FUNDS(0x7E0529Eb456a7C806B5Fe7B3d69a805339A06180);
    
    /// @notice Any funds sent here are for dividend payment.
    function () public payable {
    }
    
    /// @notice Distribute dividends to the Funds contract. Can be called
    ///     repeatedly until practically all dividends have been distributed.
    /// @param rounds How many rounds of dividend distribution do we want?
    function distribute(uint256 rounds) external {
        for (uint256 i = 0; i < rounds; i++) {
            if (address(this).balance < 0.001 ether) {
                // Balance is very low. Not worth the gas to distribute.
                break;
            }
            
            fundsContract.buy.value(address(this).balance)(0x0);
            fundsContract.exit();
        }
    }
}