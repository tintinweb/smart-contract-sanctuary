//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "../inheritances/OwnableEnhanced.sol";
import "../interfaces/IEternalFactory.sol";
import "../interfaces/IEternalTreasury.sol";
import "../interfaces/IEternalStorage.sol";
import "../interfaces/ILoyaltyGage.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@traderjoe-xyz/core/contracts/traderjoe/interfaces/IJoeRouter02.sol";
import "@traderjoe-xyz/core/contracts/traderjoe/interfaces/IJoeFactory.sol";
import "@traderjoe-xyz/core/contracts/traderjoe/interfaces/IJoePair.sol";

/**
 * @title Contract for the Eternal Treasury
 * @author Nobody (me)
 * @notice The Eternal Treasury contract holds all treasury logic
 */
 contract EternalTreasury is IEternalTreasury, OwnableEnhanced {

/////–––««« Variables: Interfaces, Addresses and Hashes »»»––––\\\\\

    // The Trader Joe router interface
    IJoeRouter02 public immutable joeRouter;
    // The Trader Joe factory interface
    IJoeFactory public immutable joeFactory;
    // The Eternal shared storage interface
    IEternalStorage public immutable eternalStorage;
    // The Eternal factory interface
    IEternalFactory private eternalFactory;
    // The Eternal token interface
    IERC20 private eternal;
    // The address of the ETRNL/AVAX pair
    address private joePair;
    // The keccak256 hash of this contract's address
    bytes32 public immutable entity;

/////–––««« Variables: Hidden Mappings »»»––––\\\\\
/**
    // The amount of ETRNL staked by any given individual user, converted to the "reserve" number space for fee distribution
    mapping (address => uint256) reserveBalances

    // The amount of ETRNL staked by any given individual user, converted to the regular number space (raw number, no fees)
    mapping (address => uint256) stakedBalances

    // The amount of a given asset provided by a user in a liquid gage of said asset
    mapping (address => mapping (address => uint256)) amountProvided

    // The amount of liquidity tokens provided for a given ETRNL/Asset pair
    mapping (address => mapping (address => uint256)) liquidityProvided
*/

/////–––««« Variables: Automatic Liquidity Provision »»»––––\\\\\

    // Determines whether the contract is tasked with providing liquidity using part of the transaction fees
    bytes32 public immutable autoLiquidityProvision;
    // Determines whether an auto-liquidity provision process is undergoing
    bool private undergoingSwap;

/////–––««« Variables: Gaging & Staking »»»––––\\\\\

    // The total number of ETRNL staked by users 
    bytes32 public immutable totalStakedBalances;
    // Used to increase or decrease everyone's accumulated fees
    bytes32 public immutable reserveStakedBalances;
    // The (percentage) fee rate applied to any gage-reward computations not using ETRNL (x 10 ** 5)
    bytes32 public immutable feeRate;

    // Allows contract to receive AVAX tokens
    // solhint-disable-next-line no-empty-blocks
    receive() external payable {}

/////–––««« Constructors & Initializers »»»––––\\\\\

    constructor (address _eternalStorage, address _eternalFactory, address _eternal) {
        // Set initial Storage, Factory and Token addresses
        eternalStorage = IEternalStorage(_eternalStorage);
        eternalFactory = IEternalFactory(_eternalFactory);
        eternal = IERC20(_eternal);

        // Initialize the Trader Joe router
        IJoeRouter02 _joeRouter = IJoeRouter02(0x7E2528476b14507f003aE9D123334977F5Ad7B14);
        joeRouter = _joeRouter;
        IJoeFactory _joeFactory = IJoeFactory(_joeRouter.factory());
        joeFactory = _joeFactory;

        // Create pair address
        joePair = _joeFactory.createPair(address(eternal), _joeRouter.WAVAX());

        // Initialize keccak256 hashes
        entity = keccak256(abi.encodePacked(address(this)));
        autoLiquidityProvision = keccak256(abi.encodePacked("autoLiquidityProvision"));
        totalStakedBalances = keccak256(abi.encodePacked("totalStakedBalances"));
        reserveStakedBalances = keccak256(abi.encodePacked("reserveStakedBalances"));
        feeRate = keccak256(abi.encodePacked("feeRate"));
    }

    function initialize(address _fund) external onlyAdmin {
        // The largest possible number in a 256-bit integer 
        uint256 max = ~uint256(0);

        // Set initial staking balances
        uint256 totalStake = eternal.balanceOf(address(this));
        eternalStorage.setUint(entity, totalStakedBalances, totalStake);
        eternalStorage.setUint(entity, reserveStakedBalances, (max - 100 * (max % totalStake)));
        eternalStorage.setUint(entity, keccak256(abi.encodePacked("stakedBalances", address(this))), totalStake);
        eternalStorage.setUint(entity, keccak256(abi.encodePacked("reserveBalances", address(this))), max - 10 * (max % totalStake));
        eternalStorage.setBool(entity, autoLiquidityProvision, true);
        
        // Set initial feeRate
        eternalStorage.setUint(entity, feeRate, 500);

        attributeFundRights(_fund);
    }

/////–––««« Modifiers »»»––––\\\\\

    /**
     * Ensures the contract doesn't affect its AVAX balance when swapping (prevents it from getting caught in a circular liquidity event).
     */
    modifier haltsActivity() {
        undergoingSwap = true;
        _;
        undergoingSwap = false;
    }

    /**
     * Reverts if activity is halted (a liquidity swap is in progress)
     */
    modifier activityHalted() {
        require(!undergoingSwap, "A liquidity swap is in progress");
        _;
    }

/////–––««« Variable state-inspection functions »»»––––\\\\\

    /**
     * @notice View the address of the ETRNL/AVAX pair on Trader Joe.
     */
    function viewPair() external view override returns(address) {
        return joePair;
    }

    /**
     * @notice View whether a liquidity swap is currently in progress
     */
    function viewUndergoingSwap() external view override returns(bool) {
        return undergoingSwap;
    }

/////–––««« Reserve Utility functions »»»––––\\\\\

    /**
     * @notice Converts a given staked amount to the "reserve" number space
     * @param amount The specified staked amount
     * @return The reserve number space of the staked amount
     */
    function convertToReserve(uint256 amount) public view override returns(uint256) {
        uint256 currentRate = eternalStorage.getUint(entity, reserveStakedBalances) / eternalStorage.getUint(entity, totalStakedBalances);
        return amount * currentRate;
    }

    /**
     * @notice Converts a given reserve amount to the regular number space (staked)
     * @param reserveAmount The specified reserve amount
     * @return The regular number space value of the reserve amount
     */
    function convertToStaked(uint256 reserveAmount) public view override returns(uint256) {
        uint256 currentRate = eternalStorage.getUint(entity, reserveStakedBalances) / eternalStorage.getUint(entity, totalStakedBalances);
        return reserveAmount / currentRate;
    }

    /**
     * @notice Computes the equivalent of an asset to an other asset and the minimum amount of the two needed to provide liquidity
     * @param asset The first specified asset, which we want to convert 
     * @param otherAsset The other specified asset
     * @param amountAsset The amount of the first specified asset
     * @param uncertainty The minimum loss to deduct from each minimum in case of price changes
     * @return minOtherAsset The minimum amount of otherAsset needed to provide liquidity (not given if uncertainty = 0)
     * @return minAsset The minimum amount of Asset needed to provide liquidity (not given if uncertainty = 0)
     * @return amountOtherAsset The equivalent in otherAsset of the given amount of asset
     */
    function computeMinAmounts(address asset, address otherAsset, uint256 amountAsset, uint256 uncertainty) public view override returns(uint256 minOtherAsset, uint256 minAsset, uint256 amountOtherAsset) {
        // Get the reserve ratios for the Asset-otherAsset pair
        (uint256 reserveAsset, uint256 reserveOtherAsset) = _fetchPairReserves(asset, otherAsset);
        // Determine a reasonable minimum amount of asset and otherAsset based on current reserves (with a tolerance =  1 / uncertainty)
        amountOtherAsset = joeRouter.quote(amountAsset, reserveAsset, reserveOtherAsset);
        if (uncertainty != 0) {
            minAsset = joeRouter.quote(amountOtherAsset, reserveOtherAsset, reserveAsset);
            minAsset -= minAsset / uncertainty;
            minOtherAsset = amountOtherAsset - (amountOtherAsset / uncertainty);
        }
    }
    
    /**
     * @notice View the liquidity reserves of a given asset pair on Trader Joe
     * @param asset The first asset of the specified pair
     * @param otherAsset The second asset of the specified pair
     * @return reserveAsset The reserve amount of the first asset
     * @return reserveOtherAsset The reserve amount of the second asset
     */
    function _fetchPairReserves(address asset, address otherAsset) private view returns(uint256 reserveAsset, uint256 reserveOtherAsset) {
        (uint256 reserveA, uint256 reserveB,) = IJoePair(joeFactory.getPair(asset, otherAsset)).getReserves();
        (reserveAsset, reserveOtherAsset) = asset < otherAsset ? (reserveA, reserveB) : (reserveB, reserveA);
    }

    /**
     * @notice Removes liquidity provided by a liquid gage, for a given ETRNL-Asset pair
     * @param rAsset The address of the specified asset
     * @param providedAsset The amount of the asset which was provided as liquidity
     * @param receiver The address of the liquid gage's receiver
     * @return The amount of ETRNL and Asset obtained from removing liquidity
     */
    function _removeLiquidity(address rAsset, uint256 providedAsset, address receiver) private returns(uint256, uint256) {
        (uint256 minETRNL, uint256 minAsset,) = computeMinAmounts(rAsset, address(eternal), providedAsset, 100);
        uint256 liquidity = eternalStorage.getUint(entity, keccak256(abi.encodePacked("liquidity", receiver, rAsset)));
        return joeRouter.removeLiquidity(address(eternal), rAsset, liquidity, minETRNL/2, minAsset/2, address(this), block.timestamp);
    }

    /**
     * @notice Swap a given amount of tokens for ETRNL
     * @param amount The specified amount of tokens
     * @param asset The address of the asset being swapped
     * @return minAsset The minimum amount of tokens received from the swap with a 1% uncertainty
     */
    function _swapTokensForETRNL(uint256 amount, address asset) private returns(uint256 minAsset) {
        address[] memory path = new address[](2);
        path[0] = asset;
        path[1] = address(eternal);

        // Calculate the minimum amount of ETRNL to swap the asset for (with a tolerance of 1%)
        (uint256 reserveETRNL, uint256 reserveAsset) = _fetchPairReserves(address(eternal), asset);
        minAsset = _computeMinSwapAmount(amount, reserveAsset, reserveETRNL, 100);

        // Swap the asset for ETRNL
        require(IERC20(asset).approve(address(joeRouter), amount), "Approve failed");
        if (asset == joeRouter.WAVAX()) {
            joeRouter.swapExactAVAXForTokensSupportingFeeOnTransferTokens{value : amount}(minAsset, path, address(this), block.timestamp);
        } else {
            joeRouter.swapExactTokensForTokens(amount, minAsset, path, address(this), block.timestamp);
        }
    }

/////–––««« Gage-logic functions »»»––––\\\\\

    /**
     * @notice Funds a given liquidity gage with ETRNL, provides liquidity using ETRNL and the receiver's asset and transfers a bonus to the receiver
     * @param gage The address of the specified liquidity gage
     * @param receiver The address of the receiver
     * @param asset The address of the asset provided by the receiver
     * @param userAmount The amount of the asset provided by the receiver
     * @param rRisk The treasury's (distributor) risk percentage 
     * @param dRisk The receiver's bonus percentage
     * 
     * Requirements:
     *
     * - Only callable by the Eternal Platform
     */
    function fundEternalLiquidGage(address gage, address receiver, address asset, uint256 userAmount, uint256 rRisk, uint256 dRisk) external payable override {
        // Checks
        require(_msgSender() == address(eternalFactory), "msg.sender must be the platform");

        // Compute minimum amounts and the amount of ETRNL needed to provide liquidity
        uint256 providedETRNL;
        uint256 providedAsset;
        uint256 liquidity;
        (uint256 minETRNL, uint256 minAsset, uint256 amountETRNL) = computeMinAmounts(asset, address(eternal), userAmount, 100);
        
        // Add liquidity to the ETRNL/Asset pair
        require(eternal.approve(address(joeRouter), amountETRNL), "Approve failed");
        if (asset == joeRouter.WAVAX()) {
            (providedETRNL, providedAsset, liquidity) = joeRouter.addLiquidityAVAX{value: userAmount}(address(eternal), amountETRNL, minETRNL, minAsset, address(this), block.timestamp);
        } else {
            (providedETRNL, providedAsset, liquidity) = joeRouter.addLiquidity(address(eternal), asset, amountETRNL, userAmount, minETRNL, minAsset, address(this), block.timestamp);
        }
        
        // Save the true amount provided as liquidity by the receiver and the actual liquidity amount
        eternalStorage.setUint(entity, keccak256(abi.encodePacked("amountProvided", receiver, asset)), providedAsset);
        eternalStorage.setUint(entity, keccak256(abi.encodePacked("liquidity", receiver, asset)), liquidity);
        
        // Initialize the liquid gage and transfer the user's instant reward
        ILoyaltyGage(gage).initialize(asset, address(eternal), userAmount, providedETRNL, rRisk, dRisk);
        require(eternal.transfer(receiver, providedETRNL * dRisk / (10 ** 4)), "Failed to transfer bonus");
    }

    /**
     * @notice Settles a given ETRNL liquid gage
     * @param receiver The address of the receiver
     * @param id The id of the specified liquid gage
     * @param winner Whether the gage closed in favor of the receiver or not
     *
     * Requirements:
     *
     * - Only callable by an Eternal-deployed gage
     */
    function settleGage(address receiver, uint256 id, bool winner) external override activityHalted {
        // Checks
        bytes32 factory = keccak256(abi.encodePacked(address(eternalFactory)));
        address gageAddress = eternalStorage.getAddress(factory, keccak256(abi.encodePacked("gages", id)));
        require(_msgSender() == gageAddress, "msg.sender must be the gage");

        // Fetch the liquid gage data
        (address rAsset,, uint256 rRisk) = ILoyaltyGage(gageAddress).viewUserData(receiver);
        (,uint256 dAmount, uint256 dRisk) = ILoyaltyGage(gageAddress).viewUserData(address(this));
        uint256 providedAsset = eternalStorage.getUint(entity, keccak256(abi.encodePacked("amountProvided", receiver, rAsset)));

        // Remove the liquidity for this gage
        (uint256 amountETRNL, uint256 amountAsset) = _removeLiquidity(rAsset, providedAsset, receiver);

        // Compute and transfer the net gage deposit + any rewards due to the receiver
        uint256 eternalRewards = amountETRNL > dAmount ? amountETRNL - dAmount : 0;
        uint256 eternalFee = eternalStorage.getUint(entity, feeRate) * providedAsset / (10 ** 5);
        if (winner) {
            require(eternal.transfer(receiver, amountETRNL * dRisk / (10 ** 4)), "Failed to transfer ETRNL reward");
            // Compute the net liquidity rewards left to distribute to stakers
            //solhint-disable-next-line reentrancy
            eternalRewards = eternalRewards == 0 ? 0 : eternalRewards - (eternalRewards * dRisk / (10 ** 4));
        } else {
            eternalFee += amountAsset * rRisk / (10 ** 4);
            amountAsset -= amountAsset * rRisk / (10 ** 4);
            // Compute the net liquidity rewards + gage deposit left to distribute to staker
            //solhint-disable-next-line reentrancy
            eternalRewards = amountETRNL * rRisk / (10 ** 4);
        }
        require(IERC20(rAsset).transfer(receiver, amountAsset - eternalFee), "Failed to transfer ERC20 reward");

        // Update staker's fees w.r.t the gage fee, gage rewards and liquidity rewards and buy ETRNL with the fee
        // Fees and rewards are both calculated in terms of ETRNL
        {
        uint256 totalFee = eternalRewards + _swapTokensForETRNL(eternalFee, rAsset);
        eternalStorage.setUint(entity, reserveStakedBalances, eternalStorage.getUint(entity, reserveStakedBalances) - convertToReserve(totalFee));
        }
    }

/////–––««« Staking-logic functions »»»––––\\\\\

    /**
     * @notice Stakes a given amount of ETRNL into the treasury
     * @param amount The specified amount of ETRNL being staked
     * 
     * Requirements:
     * 
     * - Staked amount must be greater than 0
     */
    function stake(uint256 amount) external override {
        require(amount > 0, "Amount must be greater than 0");

        require(eternal.transferFrom(_msgSender(), address(this), amount), "Transfer failed");
        emit Stake(_msgSender(), amount);

        // Update user/total staked and reserve balances
        bytes32 reserveBalances = keccak256(abi.encodePacked("reserveBalances", _msgSender()));
        bytes32 stakedBalances = keccak256(abi.encodePacked("stakedBalances", _msgSender()));
        uint256 reserveAmount = convertToReserve(amount);
        uint256 reserveBalance = eternalStorage.getUint(entity, reserveBalances);
        uint256 stakedBalance = eternalStorage.getUint(entity, stakedBalances);
        eternalStorage.setUint(entity, reserveBalances, reserveBalance + reserveAmount);
        eternalStorage.setUint(entity, stakedBalances, stakedBalance + amount);
        eternalStorage.setUint(entity, reserveStakedBalances, eternalStorage.getUint(entity, reserveStakedBalances) + reserveAmount);
        eternalStorage.setUint(entity, totalStakedBalances, eternalStorage.getUint(entity, totalStakedBalances) + amount);
    }

    /**
     * @notice Unstakes a user's given amount of ETRNL and transfers the user's accumulated rewards proportional to that amount (in ETRNL)
     * @param amount The specified amount of ETRNL being unstaked
     * 
     * Requirements:
     *
     * - A liquidity swap should not be in progress
     */
    function unstake(uint256 amount) external override {
        bytes32 stakedBalances = keccak256(abi.encodePacked("stakedBalances", _msgSender()));
        uint256 stakedBalance = eternalStorage.getUint(entity, stakedBalances);
        require(amount <= stakedBalance , "Amount exceeds staked balance");
     
        emit Unstake(_msgSender(), amount);
        bytes32 reserveBalances = keccak256(abi.encodePacked("reserveBalances", _msgSender()));
        uint256 reserveBalance = eternalStorage.getUint(entity, reserveBalances);
        // Reward user with percentage of fees proportional to the amount he is withdrawing
        uint256 reserveAmount = amount * reserveBalance / stakedBalance;
        // Update user/total staked and reserve balances
        eternalStorage.setUint(entity, reserveBalances, reserveBalance - reserveAmount);
        eternalStorage.setUint(entity, stakedBalances, stakedBalance - amount);
        eternalStorage.setUint(entity, reserveStakedBalances, eternalStorage.getUint(entity, reserveStakedBalances) - reserveAmount);
        eternalStorage.setUint(entity, totalStakedBalances, eternalStorage.getUint(entity, totalStakedBalances) - amount);

        require(eternal.transfer(_msgSender(), convertToStaked(reserveAmount)), "Transfer failed");
    }

/////–––««« Automatic liquidity provision functions »»»––––\\\\\

    /**
     * @notice Computes the minimum amount to swap a given asset for another asset, with a given percentage uncertainty
     * @param amountAsset The specified asset being swapped
     * @param reserveAsset The reserve of the asset being swapped
     * @param reserveOtherAsset The reserve of the asset being swapped for
     * @param uncertainty The denominator of the percentage uncertainty if it were viewed as (1  / uncertainty)
     */
    function _computeMinSwapAmount(uint256 amountAsset, uint256 reserveAsset, uint256 reserveOtherAsset, uint256 uncertainty) private view returns(uint256 minOtherAsset) {
        uint256 amountOtherAsset = joeRouter.getAmountOut(amountAsset, reserveAsset, reserveOtherAsset);
        minOtherAsset = amountOtherAsset - (amountOtherAsset / uncertainty);
    }

    /**
     * @notice Swaps a given amount of ETRNL for AVAX using Trader Joe. (Used for auto-liquidity swaps)
     * @param amount The amount of ETRNL to be swapped for AVAX
     */
    function _swapETRNLForAVAX(uint256 amount, uint256 reserveETRNL, uint256 reserveAVAX) private {
        address[] memory path = new address[](2);
        path[0] = address(eternal);
        path[1] = joeRouter.WAVAX();

        // Calculate the minimum amount of AVAX to swap the ETRNL for (with a tolerance of 1%)
        uint256 minAVAX = _computeMinSwapAmount(amount, reserveETRNL, reserveAVAX, 100);

        // Swap the ETRNL for AVAX
        require(eternal.approve(address(joeRouter), amount), "Approve failed");
        joeRouter.swapExactTokensForAVAXSupportingFeeOnTransferTokens(amount, minAVAX, path, address(this), block.timestamp);
    }

    /**
     * @notice Provides liquidity to the ETRNL/AVAX pair on Trader Joe for the EternalToken contract.
     * @param contractBalance The contract's ETRNL balance
     *
     * Requirements:
     * 
     * - There cannot already be a liquidity swap in progress
     * - Automatic liquidity provision must be enabled
     * - Caller can only be the Eternal Token contract
     */
    function provideLiquidity(uint256 contractBalance) external override activityHalted {
        require(_msgSender() == address(eternal), "Only callable by ETRNL contract");
        require(eternalStorage.getBool(entity, autoLiquidityProvision), "Auto-liquidity is disabled");

        _provideLiquidity(contractBalance);
    } 

    /**
     * @notice Converts half the contract's balance to AVAX and adds liquidity to the ETRNL/AVAX pair.
     * @param contractBalance The contract's ETRNL balance
     */
    function _provideLiquidity(uint256 contractBalance) private haltsActivity {
        // Split the contract's balance into two halves
        uint256 half = contractBalance / 2;
        uint256 amountETRNL = contractBalance - half;

        // Get the reserve ratios for the ETRNL-AVAX pair
        (uint256 reserveETRNL, uint256 reserveAVAX) = _fetchPairReserves(address(eternal), joeRouter.WAVAX());
        // Capture the initial balance to later compute the difference
        uint256 initialBalance = address(this).balance;
        // Swap half the contract's ETRNL balance to AVAX
        _swapETRNLForAVAX(half, reserveETRNL, reserveAVAX);
        // Compute the amount of AVAX received from the swap
        uint256 amountAVAX = address(this).balance - initialBalance;
        
        // Determine a reasonable minimum amount of ETRNL and AVAX based on current reserves (with a tolerance of 1%)
        uint256 minAVAX = joeRouter.quote(amountETRNL, reserveETRNL, reserveAVAX);
        minAVAX -= minAVAX / 100;
        uint256 minETRNL = joeRouter.quote(amountAVAX, reserveAVAX, reserveETRNL);
        minETRNL -= minETRNL / 100;

        // Add liquidity to the ETRNL/AVAX pair
        emit AutomaticLiquidityProvision(amountETRNL, contractBalance, amountAVAX);
        eternal.approve(address(joeRouter), amountETRNL);
        // Update the total liquidity 
        (,,uint256 liquidity) = joeRouter.addLiquidityAVAX{value: amountAVAX}(address(eternal), amountETRNL, minETRNL, minAVAX, address(this), block.timestamp);
        bytes32 totalLiquidity = keccak256(abi.encodePacked("liquidityProvided", address(this), joeRouter.WAVAX()));
        uint256 currentLiquidity = eternalStorage.getUint(entity, totalLiquidity);
        eternalStorage.setUint(entity, totalLiquidity, currentLiquidity + liquidity);
    }

/////–––««« Fund-only functions »»»––––\\\\\

    /**
     * @notice Transfers a given amount of AVAX from the contract to an address. (Fund only)
     * @param recipient The address to which the AVAX is to be sent
     * @param amount The specified amount of AVAX to transfer
     * 
     * Requirements:
     * 
     * - Only callable by the Eternal Fund
     * - A liquidity swap should not be in progress
     * - The contract's balance must have enough funds to accomodate the withdrawal
     */
    function withdrawAVAX(address payable recipient, uint256 amount) external override onlyFund activityHalted {
        require(amount < address(this).balance, "Insufficient balance");

        emit AVAXTransferred(amount, recipient);
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Failed to transfer AVAX");
    }

    /**
     * @notice Transfers a given amount of a token from the contract to an address. (Fund only)
     * @param asset The address of the asset being withdrawn
     * @param recipient The address to which the ETRNL is to be sent
     * @param amount The specified amount of ETRNL to transfer
     *
     * Requirements:
     *
     * - Only callable by the Eternal Fund
     */
    function withdrawAsset(address asset, address recipient, uint256 amount) external override onlyFund {
        emit AssetTransferred(asset, amount, recipient);
        require(IERC20(asset).transfer(recipient, amount), "Asset withdrawal failed");
    }

    /**
     * @notice Updates the address of the Eternal Factory contract
     * @param newContract The new address for the Eternal Factory contract
     *
     * Requirements:
     *
     * - Only callable by the Eternal Fund
     */
    function setEternalFactory(address newContract) external onlyFund {
        eternalFactory = IEternalFactory(newContract);
    }

    /**
     * @notice Updates the address of the Eternal Token contract
     * @param newContract The new address for the Eternal Token contract
     *
     * Requirements:
     *
     * - Only callable by the Eternal Fund
     */
    function setEternalToken(address newContract) external onlyFund {
        eternal = IERC20(newContract);
    }
 }

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IJoePair {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(address indexed sender, uint256 amount0, uint256 amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to) external returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0;

interface IJoeFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function migrator() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;

    function setMigrator(address) external;
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

import "./IJoeRouter01.sol";

interface IJoeRouter02 is IJoeRouter01 {
    function removeLiquidityAVAXSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountAVAX);

    function removeLiquidityAVAXWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountAVAX);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./IGage.sol";

/**
 * @dev Loyalty Gage interface
 * @author Nobody (me)
 * @notice Methods are used for all loyalty gage contracts
 */
interface ILoyaltyGage is IGage {
    // Initializes the loyalty gage
    function initialize(address rAsset, address dAsset, uint256 rAmount, uint256 dAmount, uint256 rRisk, uint256 dRisk) external;
    // View the distributor of the loyalty gage (usually token distributor)
    function viewDistributor() external view returns (address);
    // View the receiver in the loyalty gage (usually the user)
    function viewReceiver() external view returns (address);
    // View the gage's percent change in supply condition
    function viewPercent() external view returns (uint256);
    // View the whether the gage's deposit is inflationary or deflationary
    function viewInflationary() external view returns (bool);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Eternal Storage interface
 * @author Nobody (me)
 * @notice Methods are used for all of Eternal's variable storage
 */
interface IEternalStorage {
    // Scalar setters
    function setUint(bytes32 entity, bytes32 key, uint256 value) external;
    function setInt(bytes32 entity, bytes32 key, int256 value) external;
    function setAddress(bytes32 entity, bytes32 key, address value) external;
    function setBool(bytes32 entity, bytes32 key, bool value) external;
    function setBytes(bytes32 entity, bytes32 key, bytes32 value) external;

    // Scalar getters
    function getUint(bytes32 entity, bytes32 key) external view returns(uint256);
    function getInt(bytes32 entity, bytes32 key) external view returns(int256);
    function getAddress(bytes32 entity, bytes32 key) external view returns(address);
    function getBool(bytes32 entity, bytes32 key) external view returns(bool);
    function getBytes(bytes32 entity, bytes32 key) external view returns(bytes32);

    // Array setters
    function setUintArrayValue(bytes32 key, uint256 index, uint256 value) external;
    function setIntArrayValue(bytes32 key, uint256 index, int256 value) external;
    function setAddressArrayValue(bytes32 key, uint256 index, address value) external;
    function setBoolArrayValue(bytes32 key, uint256 index, bool value) external;
    function setBytesArrayValue(bytes32 key, uint256 index, bytes32 value) external;

    // Array getters
    function getUintArrayValue(bytes32 key, uint256 index) external view returns (uint256);
    function getIntArrayValue(bytes32 key, uint256 index) external view returns (int256);
    function getAddressArrayValue(bytes32 key, uint256 index) external view returns (address);
    function getBoolArrayValue(bytes32 key, uint256 index) external view returns (bool);
    function getBytesArrayValue(bytes32 key, uint256 index) external view returns (bytes32);

    //Array Deleters
    function deleteUint(bytes32 key, uint256 index) external;
    function deleteInt(bytes32 key, uint256 index) external;
    function deleteAddress(bytes32 key, uint256 index) external;
    function deleteBool(bytes32 key, uint256 index) external;
    function deleteBytes(bytes32 key, uint256 index) external;

    //Array Length
    function lengthUint(bytes32 key) external view returns (uint256);
    function lengthInt(bytes32 key) external view returns (uint256);
    function lengthAddress(bytes32 key) external view returns (uint256);
    function lengthBool(bytes32 key) external view returns (uint256);
    function lengthBytes(bytes32 key) external view returns (uint256);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Eternal Treasury interface
 * @author Nobody (me)
 * @notice Methods are used for all treasury functions
 */
interface IEternalTreasury {
    // Provides liquidity for a given liquid gage and transfers instantaneous rewards to the receiver
    function fundEternalLiquidGage(address _gage, address user, address asset, uint256 amount, uint256 risk, uint256 bonus) external payable;
    // Used by gages to compute and distribute ETRNL liquid gage rewards appropriately
    function settleGage(address receiver, uint256 id, bool winner) external;
    // Stake a given amount of ETRNL
    function stake(uint256 amount) external;
    // Unstake a given amount of ETRNL and withdraw staking rewards proportional to the amount (in ETRNL)
    function unstake(uint256 amount) external;
    // View the ETRNL/AVAX pair address
    function viewPair() external view returns(address);
    // View whether a liquidity swap is in progress
    function viewUndergoingSwap() external view returns(bool);
    // Provides liquidity for the ETRNL/AVAX pair for the ETRNL token contract
    function provideLiquidity(uint256 contractBalance) external;
    // Computes the minimum amount of two assets needed to provide liquidity given one asset amount
    function computeMinAmounts(address asset, address otherAsset, uint256 amountAsset, uint256 uncertainty) external view returns(uint256 minOtherAsset, uint256 minAsset, uint256 amountOtherAsset);
    // Converts a given staked amount into the reserve number space
    function convertToReserve(uint256 amount) external view returns(uint256);
    // Converts a given reserve amount into the regular number space (staked)
    function convertToStaked(uint256 reserveAmount) external view returns(uint256);
    // Allows the withdrawal of AVAX in the contract
    function withdrawAVAX(address payable recipient, uint256 amount) external;
    // Allows the withdrawal of an asset present in the contract
    function withdrawAsset(address asset, address recipient, uint256 amount) external;

    // Signals a disabling/enabling of the automatic liquidity provision
    event AutomaticLiquidityProvisionUpdated(bool value);
    // Signals that liquidity has been added to the ETRNL/WAVAX pair 
    event AutomaticLiquidityProvision(uint256 amountETRNL, uint256 totalSwappedETRNL, uint256 amountAVAX);
    // Signals that part of the locked AVAX balance has been cleared to a given address by decision of the DAO
    event AVAXTransferred(uint256 amount, address recipient);
    // Signals that some of an asset balance has been sent to a given address by decision of the DAO
    event AssetTransferred(address asset, uint256 amount, address recipient);
    // Signals that a user staked a given amount of ETRNL 
    event Stake(address indexed user, uint256 amount);
    // Signals that a user unstaked a given amount of ETRNL
    event Unstake(address indexed user, uint256 amount);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Eternal interface
 * @author Nobody (me)
 * @notice Methods are used for all gage-related functioning
 */
interface IEternalFactory {
    // Initiates a liquid gage involving an ETRNL liquidity pair
    function initiateEternalLiquidGage(address asset, uint256 amount) external payable returns(uint256);
    // Updates the 24h counters for the treasury and token
    function updateCounters(uint256 amount) external;
    
    // Signals the deployment of a new gage
    event NewGage(uint256 id, address indexed gageAddress);
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an admin) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the admin account will be the one that deploys the contract. This
 * can later be changed with {transferAdminRights}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyAdmin`, which can be applied to your functions to restrict their use to
 * the admin.
 *
 * @notice This is a modified version of Openzeppelin's Ownable.sol, made to add certain functionalities
 * such as different modifiers (onlyFund and onlyAdminAndFund) and locking/unlocking
 */
abstract contract OwnableEnhanced is Context {

/////–––««« Variables: Addresses, Events and Locking »»»––––\\\\\

    address private _admin;
    address private _fund;

    event FundRightsAttributed(address indexed newFund);

    uint256 private _lockPeriod;

    // Used in preventing the admin from using functions a maximum of 2 weeks and 1 day after contract creation
    uint256 public immutable ownershipDeadline;

/////–––««« Constructor »»»––––\\\\\

    /**
     * @dev Initializes the contract setting the deployer as the initial admin.
     */
    constructor () {
        address msgSender = _msgSender();
        _admin = msgSender;
        _fund = msgSender;
        ownershipDeadline = block.timestamp + 3 days;
    }

/////–––««« Modifiers »»»––––\\\\\
    /**
     * @dev Throws if called by any account other than the admin.
     */
    modifier onlyAdmin() {
        require(admin() == _msgSender(), "Caller is not the admin");
        require(ownershipDeadline > block.timestamp, "Admin's rights are over");
        _;
    }

    /**
     * @dev Throws if called by any account other than the fund.
     */
    modifier onlyFund() {
        require(_msgSender() == fund(), "Caller is not the fund");
        _;
    }

/////–––««« Variable state-inspection functions »»»––––\\\\\

    /**
     * @dev Returns the address of the current admin.
     */
    function admin() public view virtual returns (address) {
        return _admin;
    }

    /**
     * @dev Returns the address of the current fund.
     */
    function fund() public view virtual returns (address) {
        return _fund;
    }

/////–––««« Ownable-logic functions »»»––––\\\\\

    /**
     * @dev Attributes fund-rights for the Eternal Fund to a given address.
     * @param newFund The address of the new fund 
     *
     * Requirements:
     *
     * - New admin cannot be the zero address
     */
    function attributeFundRights(address newFund) public virtual onlyFund {
        require(newFund != address(0), "New fund is the zero address");
        _fund = newFund;
        emit FundRightsAttributed(newFund);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

/**
 * @dev Gage interface
 * @author Nobody (me)
 * @notice Methods are used for all gage contracts
 */
interface IGage {
    // Holds all possible statuses for a gage
    enum Status {
        Open,
        Active,
        Closed
    }

    // Holds user-specific information with regards to the gage
    struct UserData {
        address asset;                       // The address of the asset used as deposit     
        uint256 amount;                      // The entry deposit (in tokens) needed to participate in this gage        
        uint256 risk;                        // The percentage (in decimal form) that is being risked in this gage (x 10 ** 4) 
        bool inGage;                         // Keeps track of whether the user is in the gage or not
    }         

    // Removes a user from the gage
    function exit() external;
    // View the user count in the gage whilst it is not Active
    function viewGageUserCount() external view returns (uint256);
    // View the total user capacity of the gage
    function viewCapacity() external view returns (uint256);
    // View the gage's status
    function viewStatus() external view returns (uint);
    // View whether the gage is a loyalty gage or not
    function viewLoyalty() external view returns (bool);
    // View a given user's gage data
    function viewUserData(address user) external view returns (address, uint256, uint256);

    // Signals the transition from 'Open' to 'Active for a given gage
    event GageInitiated(uint256 id);
    // Signals the transition from 'Active' to 'Closed' for a given gage
    event GageClosed(uint256 id, bool winner); 
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.2;

interface IJoeRouter01 {
    function factory() external pure returns (address);

    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityAVAX(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountAVAX,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAX(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityAVAXWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountAVAXMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountAVAX);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactAVAXForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactAVAX(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapAVAXForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path) external view returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path) external view returns (uint256[] memory amounts);
}