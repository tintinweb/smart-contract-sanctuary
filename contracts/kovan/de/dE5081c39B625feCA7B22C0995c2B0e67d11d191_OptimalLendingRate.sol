/**
 *Submitted for verification at Etherscan.io on 2021-08-23
*/

// "SPDX-License-Identifier: <SPDX-License>"

pragma solidity ^0.8.7;
library DataTypes {
    // refer to the whitepaper, section 1.1 basic concepts for a formal description of these properties.
    struct ReserveData {
        //stores the reserve configuration
        ReserveConfigurationMap configuration;
        //the liquidity index. Expressed in ray
        uint128 liquidityIndex;
        //variable borrow index. Expressed in ray
        uint128 variableBorrowIndex;
        //the current supply rate. Expressed in ray
        uint128 currentLiquidityRate;
        //the current variable borrow rate. Expressed in ray
        uint128 currentVariableBorrowRate;
        //the current stable borrow rate. Expressed in ray
        uint128 currentStableBorrowRate;
        uint40 lastUpdateTimestamp;
        //tokens addresses
        address aTokenAddress;
        address stableDebtTokenAddress;
        address variableDebtTokenAddress;
        //address of the interest rate strategy
        address interestRateStrategyAddress;
        //the id of the reserve. Represents the position in the list of the active reserves
        uint8 id;
    }

    struct ReserveConfigurationMap {
        //bit 0-15: LTV
        //bit 16-31: Liq. threshold
        //bit 32-47: Liq. bonus
        //bit 48-55: Decimals
        //bit 56: Reserve is active
        //bit 57: reserve is frozen
        //bit 58: borrowing is enabled
        //bit 59: stable rate borrowing enabled
        //bit 60-63: reserved
        //bit 64-79: reserve factor
        uint256 data;
    }

    struct UserConfigurationMap {
        uint256 data;
    }

    enum InterestRateMode {NONE, STABLE, VARIABLE}
}

library DSMath {
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function mul(uint x, uint y) internal pure returns (uint z) {
        require(y == 0 || (z = x * y) / y == x, "ds-math-mul-overflow");
    }

    function min(uint x, uint y) internal pure returns (uint z) {
        return x <= y ? x : y;
    }
    function max(uint x, uint y) internal pure returns (uint z) {
        return x >= y ? x : y;
    }
    function imin(int x, int y) internal pure returns (int z) {
        return x <= y ? x : y;
    }
    function imax(int x, int y) internal pure returns (int z) {
        return x >= y ? x : y;
    }

    uint constant WAD = 10 ** 18;
    uint constant RAY = 10 ** 27;

    //rounds to zero if x*y < WAD / 2
    function wmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), WAD / 2) / WAD;
    }
    //rounds to zero if x*y < WAD / 2
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, y), RAY / 2) / RAY;
    }
    //rounds to zero if x*y < WAD / 2
    function wdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, WAD), y / 2) / y;
    }
    //rounds to zero if x*y < RAY / 2
    function rdiv(uint x, uint y) internal pure returns (uint z) {
        z = add(mul(x, RAY), y / 2) / y;
    }

    // This famous algorithm is called "exponentiation by squaring"
    // and calculates x^n with x as fixed-point and n as regular unsigned.
    //
    // It's O(log n), instead of O(n) for naive repeated multiplication.
    //
    // These facts are why it works:
    //
    //  If n is even, then x^n = (x^2)^(n/2).
    //  If n is odd,  then x^n = x * x^(n-1),
    //   and applying the equation for even x gives
    //    x^n = x * (x^2)^((n-1) / 2).
    //
    //  Also, EVM division is flooring and
    //    floor[(n-1) / 2] = floor[n / 2].
    //
    function rpow(uint x, uint n) internal pure returns (uint z) {
        z = n % 2 != 0 ? x : RAY;

        for (n /= 2; n != 0; n /= 2) {
            x = rmul(x, x);

            if (n % 2 != 0) {
                z = rmul(z, x);
            }
        }
    }
}

interface IAaveLendingPool {

    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;    

    function getReserveData(
        address asset
    ) external view returns (DataTypes.ReserveData memory); 
}


interface IAaveAToken{ 
    function balanceOf(address account) external view returns (uint256);
}

interface IcDAI {
        function mint(uint mintAmount) external returns (uint);
        function supplyRatePerBlock() external view returns (uint);
}


interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address who) external view returns (uint256);

  function allowance(address owner, address spender)
    external view returns (uint256);

  function transfer(address to, uint256 value) external returns (bool);

  function approve(address spender, uint256 value)
    external returns (bool);

  function transferFrom(address from, address to, uint256 value)
    external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


contract OptimalLendingRate{

    uint128 internal constant RAY = 1e27;
    uint64 internal constant WAD = 1e18;
    uint32 internal constant WADtoRAY = 1e9;
    uint16 internal constant daysPerYear = 365;
    uint16 internal constant blocksPerDay = 6570;

    address constant AaveLendingPoolAddr = 0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe;
    address constant cDAIAddr = 0xF0d0EB522cfa50B716B3b1604C4F0fA6f04376AD;
    address constant DAIAddr = 0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD;


    IAaveLendingPool AaveLendingPool = IAaveLendingPool(AaveLendingPoolAddr);
    IcDAI cDAI = IcDAI(cDAIAddr);
    IERC20 DAI =  IERC20(DAIAddr);

    event ApprovedTrue(address indexed account);
    // external - funciton can only be accessed externally not internally
    function deposit(uint256 amount) external {
        // determining highest rate between aave and compound and deposit accordingly
        // if(getAaveLendingRate(asset)>getCompLendingRate()){
        //     require(DAI.allowance(tx.origin, AaveLendingPoolAddr) >= amount, "User needs to approve to spend Token on his behalf");
        //     emit ApprovedTrue(tx.origin);
        //     AaveLendingPool.deposit(DAIAddr, amount, tx.origin, 0);
        // } else {
            require(DAI.allowance(tx.origin, cDAIAddr) >= amount, "User needs to approve to spend Token on his behalf");
            cDAI.mint(amount);
        // 
    }

    function getAaveLendingRate(address token) public view returns (uint128 aaveDaiRate) {
        DataTypes.ReserveData memory reserveData = AaveLendingPool.getReserveData(token);
        // return rate in RAY, decimal with 27 digits of precision
        aaveDaiRate = reserveData.currentLiquidityRate;
    }

    function getCompLendingRate() public view returns(uint apy){
        // rate in RAY
        uint compRate = cDAI.supplyRatePerBlock() * WADtoRAY;
        // apy = (((rate * blocksPerDay + 1)^daysPerYear)-1);
        apy = DSMath.rpow(DSMath.add(DSMath.rmul(compRate, blocksPerDay*RAY), RAY), daysPerYear) - RAY;
    }

}