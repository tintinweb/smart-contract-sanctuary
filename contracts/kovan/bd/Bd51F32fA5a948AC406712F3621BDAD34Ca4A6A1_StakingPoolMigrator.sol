// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "./interfaces/IStakingPoolMigrator.sol";
import "./interfaces/ISwapPair.sol";
import "./interfaces/ISwapFactory.sol";

contract StakingPoolMigrator is IStakingPoolMigrator {

    address public migrateFromFactory;
    address public migrateToFactory;
    address public stakingPools;
    uint256 public desiredLiquidity = uint256(-1);

    constructor(
        address _migrateFromFactory,
        address _migrateToFactory,
        address _stakingPools
    ) public {
        migrateFromFactory = _migrateFromFactory;
        migrateToFactory = _migrateToFactory;
        stakingPools = _stakingPools;
    }

    function migrate(
        uint256 poolId,
        address oldToken,
        uint256 amount
    ) external override returns (address){
        require(amount > 0, "StakingPoolMigrator: Zero amount to migrate");
        address _stakingPools = stakingPools;

        require(msg.sender == _stakingPools, "StakingPoolMigrator: Not from StakingPools");
        ISwapPair oldPair = ISwapPair(oldToken);
        require(oldPair.factory() == migrateFromFactory, "StakingPoolMigrator: Not migrating from Uniswap Factory");

        address token0 = oldPair.token0();
        address token1 = oldPair.token1();

        ISwapPair newPair = ISwapPair(ISwapFactory(migrateToFactory).getPair(token0, token1));

        desiredLiquidity = amount;
        oldPair.transferFrom(_stakingPools, address(oldPair), amount);
        oldPair.burn(address(newPair));
        newPair.mint(_stakingPools);
        desiredLiquidity = uint256(-1);
        return address(newPair);
    }


}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IStakingPoolMigrator {
    function migrate(
        uint256 poolId,
        address oldToken,
        uint256 amount
    ) external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ISwapPair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

interface ISwapFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function freezerSetter() external view returns (address);
    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
    function setFreezerSetter(address) external;
    function setMigrator(address) external;
}

{
  "optimizer": {
    "enabled": true,
    "runs": 999999
  },
  "evmVersion": "istanbul",
  "outputSelection": {
    "*": {
      "*": [
        "evm.bytecode",
        "evm.deployedBytecode",
        "abi"
      ]
    }
  },
  "metadata": {
    "useLiteralContent": true
  },
  "libraries": {}
}