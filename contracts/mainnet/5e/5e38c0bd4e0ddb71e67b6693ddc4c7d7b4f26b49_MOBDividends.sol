pragma solidity ^0.4.24;

contract MOB {
    function buy(address _referredBy) public payable returns(uint256);
    function exit() public;
}

contract MOBDividends {
    MOB MOBContract = MOB(0x81b88b12CD8e228e976DF92bB6aD2E74ECCa1d08);
    
    /// @notice Any funds sent here are for dividend payment.
    function () public payable {
    }
    
    /// @notice Distribute dividends to the MOB contract. Can be called
    ///     repeatedly until practically all dividends have been distributed.
    /// @param rounds How many rounds of dividend distribution do we want?
    function distribute(uint256 rounds) external {
        for (uint256 i = 0; i < rounds; i++) {
            if (address(this).balance < 0.001 ether) {
                // Balance is very low. Not worth the gas to distribute.
                break;
            }
            
            MOBContract.buy.value(address(this).balance)(0x0);
            MOBContract.exit();
        }
    }
}