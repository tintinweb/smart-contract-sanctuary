pragma solidity 0.5.17;


interface IPriceFeedsExt {
  function latestAnswer() external view returns (uint256);
}

contract USDOracle is IPriceFeedsExt {

    uint256 private constant USDT_RATE = 1 ether;

    /**
      * @dev returns the trivial USDT/USDT rate
      *
      * @return always returns the trivial rate of 1
    */
    function latestAnswer() external view returns (uint256) {
        return USDT_RATE;
    }

    /**
      * @dev returns the update time
      *
      * @return always returns current block's timestamp
    */
    function latestTimestamp() external view returns (uint256) {
        return now; 
    }

}