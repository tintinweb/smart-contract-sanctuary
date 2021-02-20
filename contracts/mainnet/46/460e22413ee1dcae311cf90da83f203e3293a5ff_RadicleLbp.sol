/**
 *Submitted for verification at Etherscan.io on 2021-02-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.4;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

struct PoolParams {
    string poolTokenSymbol;
    string poolTokenName;
    address[] constituentTokens;
    uint256[] tokenBalances;
    uint256[] tokenWeights;
    uint256 swapFee;
}

struct Rights {
    bool canPauseSwapping;
    bool canChangeSwapFee;
    bool canChangeWeights;
    bool canAddRemoveTokens;
    bool canWhitelistLPs;
    bool canChangeCap;
}

library BalancerConstants {
    uint256 public constant BONE = 10**18;
}

interface IConfigurableRightsPool is IERC20 {
    function whitelistLiquidityProvider(address provider) external;

    function setController(address newOwner) external;
    function getController() external returns (address);

    function createPool(
        uint256 initialSupply,
        uint256 minimumWeightChangeBlockPeriodParam,
        uint256 addTokenTimeLockInBlocksParam
    ) external;

    function updateWeightsGradually(
        uint256[] calldata newWeights,
        uint256 startBlock,
        uint256 endBlock
    ) external;

    function bPool() external view returns (address);
    function pokeWeights() external;
    function setPublicSwap(bool) external;
}

interface ICRPFactory {
    function newCrp(
        address factoryAddress,
        PoolParams calldata poolParams,
        Rights calldata rights
    ) external returns (IConfigurableRightsPool);
}

interface IERC20Decimal is IERC20 {
    function decimals() external view returns (uint8);
}

contract RadicleLbp {
    IERC20Decimal public immutable radToken;
    IERC20Decimal public immutable usdcToken;
    Sale public immutable sale;

    uint256 public constant RAD_BALANCE = 3750000e18; // 3.75 million RAD
    uint256 public constant USDC_BALANCE = 3500000e6; // 3.5 million USDC
    uint256 public constant RAD_WEIGHT = 37;
    uint256 public constant USDC_WEIGHT = 3;
    uint256 public constant SWAP_FEE = 5e15; // 0.5%

    constructor(
        address bFactory,
        address crpFactory,
        IERC20Decimal _radToken,
        IERC20Decimal _usdcToken,
        address lp
    ) {
        ICRPFactory factory = ICRPFactory(crpFactory);

        // RAD starting balance and weight.
        uint256 radTokenWeight = RAD_WEIGHT * BalancerConstants.BONE;

        // USDC starting balance and weight.
        uint256 usdcTokenWeight = USDC_WEIGHT * BalancerConstants.BONE;

        // Permissions on the pool.
        Rights memory rights;
        rights.canPauseSwapping = true;
        rights.canChangeSwapFee = false;
        rights.canChangeWeights = true;
        rights.canAddRemoveTokens = false;
        rights.canWhitelistLPs = true;
        rights.canChangeCap = false;

        // Pool parameters.
        PoolParams memory params;
        params.poolTokenSymbol = "RADP";
        params.poolTokenName = "RAD Pool Token";

        params.constituentTokens = new address[](2);
        params.tokenBalances = new uint256[](2);
        params.tokenWeights = new uint256[](2);

        params.constituentTokens[0] = address(_radToken);
        params.tokenBalances[0] = RAD_BALANCE;
        params.tokenWeights[0] = radTokenWeight;

        params.constituentTokens[1] = address(_usdcToken);
        params.tokenBalances[1] = USDC_BALANCE;
        params.tokenWeights[1] = usdcTokenWeight;
        params.swapFee = SWAP_FEE;

        IConfigurableRightsPool _crpPool = factory.newCrp(bFactory, params, rights);

        // Create the sale contract and transfer ownership of the CRP to the sale contract.
        Sale _sale = new Sale(_crpPool, _radToken, _usdcToken, RAD_BALANCE, USDC_BALANCE, lp);
        _crpPool.setController(address(_sale));

        sale = _sale;
        radToken = _radToken;
        usdcToken = _usdcToken;
    }
}

contract Sale {
    IConfigurableRightsPool public immutable crpPool;

    uint256 public immutable radTokenBalance;
    uint256 public immutable usdcTokenBalance;

    IERC20 public immutable radToken;
    IERC20 public immutable usdcToken;

    uint256 public constant RAD_END_WEIGHT = 20;
    uint256 public constant USDC_END_WEIGHT = 20;

    address lp;

    constructor(
        IConfigurableRightsPool _crpPool,
        IERC20 _radToken,
        IERC20 _usdcToken,
        uint256 _radTokenBalance,
        uint256 _usdcTokenBalance,
        address _lp
    ) {
        crpPool = _crpPool;
        radToken = _radToken;
        usdcToken = _usdcToken;
        radTokenBalance = _radTokenBalance;
        usdcTokenBalance = _usdcTokenBalance;
        lp = _lp;
    }

    /// Begin the sale. Transfers balances from the sender into the
    /// Balancer pool, and transfers the pool tokens to the sender.
    function begin(
        uint256 minimumWeightChangeBlockPeriod,
        uint256 weightChangeStartDelay,
        address controller
    ) public {
        require(
            msg.sender == lp,
            "Sale::begin: only the LP can call this function"
        );
        require(
            controller != address(0),
            "Sale::begin: the controller must be set"
        );
        require(
            radToken.transferFrom(msg.sender, address(this), radTokenBalance),
            "Sale::begin: transfer of RAD must succeed"
        );
        require(
            usdcToken.transferFrom(msg.sender, address(this), usdcTokenBalance),
            "Sale::begin: transfer of USDC must succeed"
        );
        require(
            crpPool.getController() == address(this),
            "Sale::begin: sale must be controller"
        );

        radToken.approve(address(crpPool), radTokenBalance);
        usdcToken.approve(address(crpPool), usdcTokenBalance);

        // How many pool tokens to mint.
        uint256 poolTokens = 100 * BalancerConstants.BONE;

        crpPool.createPool(
          poolTokens,
          minimumWeightChangeBlockPeriod,
          0
        );

        require(
            crpPool.totalSupply() == poolTokens,
            "Sale::begin: pool tokens must match total supply"
        );

        uint256[] memory endWeights = new uint256[](2);
        endWeights[0] = RAD_END_WEIGHT * BalancerConstants.BONE;
        endWeights[1] = USDC_END_WEIGHT * BalancerConstants.BONE;

        // Start and end of the weight/price curve.
        uint256 startBlock = block.number + weightChangeStartDelay;
        uint256 endBlock = startBlock + minimumWeightChangeBlockPeriod;

        // Kick-off the price curve.
        crpPool.updateWeightsGradually(endWeights, startBlock, endBlock);
        // Transfer ownership of the pool tokens to the sender.
        crpPool.transfer(msg.sender, poolTokens);
        // Set the pool controller, who can pause the sale.
        crpPool.setController(controller);
    }
}