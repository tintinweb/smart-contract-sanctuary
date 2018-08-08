pragma solidity 0.4.24;
pragma experimental "v0.5.0";


contract SRNTPriceOracle {
    // If SRNT becomes more expensive than ETH, we will have to reissue smart-contracts
    uint256 public SRNT_per_ETH = 10000;

    address internal serenity_wallet = 0x47c8F28e6056374aBA3DF0854306c2556B104601;

    function update_SRNT_price(uint256 new_SRNT_per_ETH) external {
        require(msg.sender == serenity_wallet);

        SRNT_per_ETH = new_SRNT_per_ETH;
    }
}