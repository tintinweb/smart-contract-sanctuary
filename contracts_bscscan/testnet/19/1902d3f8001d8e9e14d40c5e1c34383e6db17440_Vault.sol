/**
 *Submitted for verification at BscScan.com on 2021-08-11
*/

contract Vault {
    event Param(uint256 id, address worker, uint256 principalAmount, uint256 borrowAmount, uint256 maxReturn, bytes data);
    event Worker(address strat, bytes ext);
    event Strategy(address baseToken, address farmingToken, uint256 farmingTokenAmount, uint256 minLPAmount);

    function work(
        uint256 id,
        address worker,
        uint256 principalAmount,
        uint256 borrowAmount,
        uint256 maxReturn,
        bytes memory data
    ) public {
        emit Param(id, worker, principalAmount, borrowAmount, maxReturn, data);
        (address strat, bytes memory ext) = abi.decode(data, (address, bytes));
        emit Worker(strat, ext);
        (uint256 farmingTokenAmount, uint256 minLPAmount) = abi.decode(ext, (uint256, uint256));
        emit Strategy(address(0), address(0), farmingTokenAmount, minLPAmount);
    }
}