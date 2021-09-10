/**
 *Submitted for verification at BscScan.com on 2021-09-10
*/

// SPDX-License-Identifier: GPL-3.0-or-later

// File: @sansfinance\sans-core\contracts\interfaces\ISansPair.sol

pragma solidity >=0.5.0;

interface ISansPair {
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

// File: contracts\SansLiquidityLocker.sol

pragma solidity =0.6.6;


contract SansLiquidityLocker {
    address public sansBnbPairAddress;
    address public sansAddress;
    address public sansManagerAddress;
    address public owner;
    address[] public registeredLockerList;
    uint256 public lastLockSansManagerBalance;
    uint256 public lastLockTimestamp;

    event Lock(address indexed user, uint256 amount, uint256 sansManagerBalance);

    constructor(
        address _sansBnbPairAddress,
        address _sansAddress,
        address _sansManagerAddress
    ) public {
        sansBnbPairAddress = _sansBnbPairAddress;
        sansAddress = _sansAddress;
        sansManagerAddress = _sansManagerAddress;
        owner = msg.sender;
    }

    function lock(uint256 _amount) external {
        bool isRegisteredLocker = false;

        for (uint256 i = 0; i < registeredLockerList.length; i++) {
            if (msg.sender == registeredLockerList[i]) {
                isRegisteredLocker = true;
                break;
            }
        }

        ISansPair(sansBnbPairAddress).transferFrom(msg.sender, address(this), _amount);

        if (isRegisteredLocker) {
            lastLockSansManagerBalance = ISansPair(sansAddress).balanceOf(sansManagerAddress);
            lastLockTimestamp = block.timestamp;

            emit Lock(msg.sender, _amount, lastLockSansManagerBalance);
        }
    }

    function getLockedAmount() external view returns (uint256) {
        return ISansPair(sansBnbPairAddress).balanceOf(address(this));
    }

    function addRegisteredLocker(address _locker) external {
        require(msg.sender == owner, 'SansLiquidityLocker: NOT_ALLOWED');

        registeredLockerList.push(_locker);
    }
}