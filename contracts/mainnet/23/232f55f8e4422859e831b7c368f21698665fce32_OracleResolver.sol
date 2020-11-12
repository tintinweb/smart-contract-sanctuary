pragma solidity 0.6.6;


/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solium-disable-next-line security/no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }
}


interface Aggregator {
    function latestAnswer() external view returns(uint256);
    function latestTimestamp() external view returns(uint256);
}


contract OracleResolver {
    using Address for address;

    Aggregator aggr;

    uint256 internal constant expiration = 3 hours;

    constructor() public {
        if (address(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419).isContract()) {
            // mainnet
            aggr = Aggregator(0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419);
        } else revert();
    }

    function ethUsdPrice() public view returns (uint256) {
        require(now < aggr.latestTimestamp() + expiration, "Oracle data are outdated");
        return aggr.latestAnswer() / 1000;
    }
}