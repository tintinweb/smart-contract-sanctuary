pragma solidity 0.6.10;

abstract contract YPool {
    function get_virtual_price() external view virtual returns (uint256);
}

contract APYOracle {
    YPool public pool;
    uint256 public poolDeployBlock;
    uint256 constant blocksPerYear = 242584;
    
    constructor(YPool _pool, uint256 _poolDeployBlock) public {
        pool = _pool;
        poolDeployBlock = _poolDeployBlock;
    }
    
    function getAPY() external view returns (uint256) {
        uint256 blocks = block.number - poolDeployBlock;
		uint256 price = pool.get_virtual_price() - 1e18;
        return price * blocksPerYear / blocks;
    }
}