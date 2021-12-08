/**
 *Submitted for verification at Etherscan.io on 2021-12-08
*/

// AAVE
// DAI - AAVE - 0xff795577d9ac8bd7d90ee22b6c1703490b6512fd 
// aDAI - 0xdCf0aF9e59C002FA3AA091a46196b37530FD48a8
// 100 DAI - 100000000000000000000

// COMPOUND
// DAI - compound - 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa
// cDAI - 0xf0d0eb522cfa50b716b3b1604c4f0fa6f04376ad


//deploy -  0x88757f2f99175387ab4c6a4b3067c77a695b0349, 0xf0d0eb522cfa50b716b3b1604c4f0fa6f04376ad

// COMPOUND
// compoundDeposit - 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa, 10000000000000000000
// compoundWithdrawal - 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa

// AAVE
// aaveDeposit - 0xff795577d9ac8bd7d90ee22b6c1703490b6512fd, 10000000000000000000
// aaveWithdraw - 0xff795577d9ac8bd7d90ee22b6c1703490b6512fd

pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

// // AAVE
// import "https://github.com/aave/protocol-v2/blob/ice/mainnet-deployment-03-12-2020/contracts/protocol/lendingpool/LendingPool.sol";
// import "https://github.com/aave/protocol-v2/blob/ice/mainnet-deployment-03-12-2020/contracts/protocol/configuration/LendingPoolAddressesProvider.sol";
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// // COMPOUND

interface CErc20 {
  function balanceOf(address) external view returns (uint);
  function mint(uint) external returns (uint);
  function exchangeRateCurrent() external returns (uint);
  function supplyRatePerBlock() external returns (uint);
  function redeem(uint) external returns (uint);
}

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

interface LendingPool {
    function getReserveData(address asset) external view returns (DataTypes.ReserveData memory);
    function deposit(address asset, uint256 amount, address onBehalfOf, uint16 referralCode) external;
    function withdraw(address asset, uint256 amount, address to) external returns (uint256);
}

interface LendingPoolAddressesProvider {
    function getLendingPool() external view returns (address);
}

contract FinVault {
    LendingPool public lendingPool; // 0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe - proxy
    LendingPoolAddressesProvider public lendingPoolAddressesProvider; //0x88757f2f99175387ab4c6a4b3067c77a695b0349
    
    CErc20 public cToken;

    constructor(address _poolProvider, address _cToken) public {
        lendingPoolAddressesProvider = LendingPoolAddressesProvider(_poolProvider);
        cToken = CErc20(_cToken);
        setLendingPool();
    }

    // AAVE

    function setLendingPool() public {
        lendingPool = LendingPool(lendingPoolAddressesProvider.getLendingPool());
    }

    function getReservedData(address _asset) internal view returns (DataTypes.ReserveData memory) {
        return lendingPool.getReserveData(_asset);
    }

    function aaveDeposit(address _asset, uint256 _amount) public {
        IERC20(_asset).approve(address(lendingPool), _amount);
        lendingPool.deposit(_asset, _amount, msg.sender, 0);
    }

    function aaveWithdraw(address _asset) public {
        DataTypes.ReserveData memory reservedData = getReservedData(_asset);
        uint256 assetBalance = IERC20(reservedData.aTokenAddress).balanceOf(address(this));
        lendingPool.withdraw(_asset, assetBalance, msg.sender);
    }

    // COMPOUND

    function compoundDeposit(address _asset, uint _amount) external {
        IERC20(_asset).approve(address(cToken), _amount);
        require(cToken.mint(_amount) == 0, "mint failed");
        uint amount = this.getCTokenBalance();
        IERC20(address(cToken)).transfer(msg.sender, amount);
    }
    function getCTokenBalance() external view returns (uint _amount) {
        return cToken.balanceOf(address(this));
    }
    function compoundWithdrawal(address _asset) external {
        uint amount = this.getCTokenBalance();
        require(cToken.redeem(amount) == 0, "redeem failed");
        uint tokenBalance = IERC20(_asset).balanceOf(address(this));
        IERC20(_asset).transfer(msg.sender, tokenBalance);
    }

}