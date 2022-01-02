//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "../interfaces/ILoyaltyGage.sol";
import "../gages/LoyaltyGage.sol";
import "@traderjoe-xyz/core/contracts/traderjoe/interfaces/IJoeRouter02.sol";
import "@traderjoe-xyz/core/contracts/traderjoe/interfaces/IJoeFactory.sol";
import "@traderjoe-xyz/core/contracts/traderjoe/interfaces/IJoePair.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title Contract for the Eternal gaging platform
 * @author Nobody (me)
 * @notice The Eternal contract holds all user-data and gage logic.
 */
contract EternalOffering {

/////–––««« Variables: Events, Interfaces and Addresses »»»––––\\\\\

    // Signals the deployment of a new gage
    event NewGage(uint256 id, address indexed gageAddress);

    // The Joe router interface
    IJoeRouter02 public immutable joeRouter;
    // The Joe factory interface
    IJoeFactory public immutable joeFactory;
    // The Eternal token interface
    IERC20 public immutable eternal;

    // The address of the Eternal Treasury
    address public immutable treasury;
    // The address of the ETRNL-MIM pair
    address public immutable mimPair;
    // The address of the ETRNL-AVAX pair
    address public immutable avaxPair;

/////–––««« Variables: Mappings »»»––––\\\\\

    // Keeps track of the respective gage tied to any given ID
    mapping (uint256 => address) private gages;
    // Keeps track of whether a user is in a loyalty gage or has provided liquidity for this offering
    mapping (address => bool) private participated;
    // Keeps track of the amount of ETRNL the user has used in liquidity provision
    mapping (address => uint256) private liquidityOffered;

/////–––««« Variables: Constants and factors »»»––––\\\\\

    // The holding time constant used in the percent change condition calculation (decided by the Eternal Fund) (x 10 ** 6)
    uint256 public constant TIME_FACTOR = 2 * (10 ** 6);
    // The average amount of time that users provide liquidity for
    uint256 public constant TIME_CONSTANT = 15;
    // The minimum token value estimate of transactions in 24h, used in case the alpha value is not determined yet
    uint256 public constant BASELINE = 10 ** 6;
    // The number of ETRNL allocated
    uint256 public constant LIMIT = 425 * (10 ** 7);
    // The MIM address
    address public constant MIM = 0x130966628846BFd36ff31a822705796e8cb8C18D;

/////–––««« Variables: Gage/Liquidity bookkeeping »»»––––\\\\\

    // Keeps track of the latest Gage ID
    uint256 private lastId;
    // The total number of ETRNL dispensed in this offering thus far
    uint256 private totalETRNLOffered;
    // The total number of MIM-ETRNL lp tokens acquired
    uint256 private totalLpMIM;
    // The total number of AVAX-ETRNL lp tokens acquired
    uint256 private totalLpAVAX;
    // The blockstamp at which this contract will cease to offer
    uint256 private offeringEnds;

/////–––««« Constructor »»»––––\\\\\

    constructor (address _eternal, address _treasury) {
        // Set the initial Eternal token and storage interfaces
        eternal = IERC20(_eternal);
        IJoeRouter02 _joeRouter = IJoeRouter02(0x7E2528476b14507f003aE9D123334977F5Ad7B14);
        IJoeFactory _joeFactory = IJoeFactory(_joeRouter.factory());
        joeRouter = _joeRouter;
        joeFactory = _joeFactory;

        // Create the pairs
        avaxPair = _joeFactory.getPair(_eternal, _joeRouter.WAVAX());
        mimPair = _joeFactory.createPair(_eternal, MIM);
        treasury = _treasury;
        offeringEnds = block.timestamp + 1 days;
    }

/////–––««« Variable state-inspection functions »»»––––\\\\\

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
    function computeMinAmounts(address asset, address otherAsset, uint256 amountAsset, uint256 uncertainty) public view returns(uint256 minOtherAsset, uint256 minAsset, uint256 amountOtherAsset) {
        // Get the reserve ratios for the Asset-otherAsset pair
        (uint256 reserveA, uint256 reserveB,) = IJoePair(joeFactory.getPair(asset, otherAsset)).getReserves();
        (uint256 reserveAsset, uint256 reserveOtherAsset) = asset < otherAsset ? (reserveA, reserveB) : (reserveB, reserveA);

        // Determine a reasonable minimum amount of asset and otherAsset based on current reserves (with a tolerance =  1 / uncertainty)
        amountOtherAsset = joeRouter.quote(amountAsset, reserveAsset, reserveOtherAsset);
        if (uncertainty != 0) {
            minAsset = joeRouter.quote(amountOtherAsset, reserveOtherAsset, reserveAsset);
            minAsset -= minAsset / uncertainty;
            minOtherAsset = amountOtherAsset - (amountOtherAsset / uncertainty);
        }
    }

    /**
     * @notice View the total ETRNL offered in this IGO
     * @return  The total ETRNL distributed in this offering
     */
    function viewTotalETRNLOffered() external view returns(uint256) {
        return totalETRNLOffered;
    }

    /**
     * @notice View the total number of MIM-ETRNL and AVAX-ETRNL lp tokens earned in this IGO
     * @return The total number of lp tokens for the MIM-ETRNl and AVAX-ETRNL pair in this contract
     */
    function viewTotalLp() external view returns (uint256, uint256) {
        return (totalLpMIM, totalLpAVAX);
    }

    /**
     * @notice View the amount of ETRNL a given user has been offered in total
     * @param user The specified user
     * @return  The total amount of ETRNL offered for the user
     */
    function viewLiquidityOffered(address user) external view returns (uint256) {
        return liquidityOffered[user];
    }
    
/////–––««« Gage-logic functions »»»––––\\\\\

    /**
     * @notice Creates an ETRNL loyalty gage contract for a given user and amount
     * @param asset The address of the asset being deposited in the loyalty gage by the receiver
     * @param amount The amount of the asset being deposited in the loyalty gage by the receiver
     * @return The id of the gage created
     *
     * Requirements:
     * 
     * - The offering must be ongoing
     * - Only MIM or AVAX loyalty gages are offered
     * - There can not have been more than 4 250 000 000 ETRNL offered in total
     * - A user can only participate in a maximum of one loyalty gage
     * - A user can not send money to gages/provide liquidity for more than 10 000 000 ETRNL 
     * - The sum of the new amount provided and the previous amounts provided by a user can not exceed the equivalent of 10 000 000 ETRNL
     */
    function initiateEternalLoyaltyGage(address asset, uint256 amount) external payable returns(uint256) {
        // Checks
        require(block.timestamp < offeringEnds, "Offering is over");
        require(asset == MIM || msg.value > 0, "Only MIM or AVAX");
        require(totalETRNLOffered < LIMIT, "ETRNL offering limit is reached");
        require(!participated[msg.sender], "User gage limit reached");
        require(liquidityOffered[msg.sender] < (10 ** 7) * (10 ** 18), "Limit for this user reached");

        uint256 providedETRNL;
        uint256 providedAsset;
        uint256 liquidity;
        // Compute the minimum amounts needed to provide liquidity and the equivalent of the asset in ETRNL
        (uint256 minETRNL, uint256 minAsset, uint256 amountETRNL) = computeMinAmounts(asset, address(eternal), amount, 200);
        require(amountETRNL + liquidityOffered[msg.sender] <= (10 ** 7) * (10 ** 18), "Amount exceeds the user limit");

        // Compute the percent change condition
        uint256 percent = 500 * BASELINE * (10 ** 18) * TIME_CONSTANT * TIME_FACTOR / eternal.totalSupply();

        // Incremement the lastId tracker and increase the total ETRNL count
        lastId += 1;
        participated[msg.sender] = true;

        // Deploy a new Gage
        LoyaltyGage newGage = new LoyaltyGage(lastId, percent, 2, false, address(this), msg.sender, address(this));
        emit NewGage(lastId, address(newGage));
        gages[lastId] = address(newGage);

        //Transfer the deposit
        if (msg.value == 0) {
            require(IERC20(asset).transferFrom(msg.sender, address(this), amount), "Failed to deposit asset");
        } else {
            asset = joeRouter.WAVAX();
        }

        // Calculate risk and join the gage for the user and the Eternal Offering contract
        uint256 rRisk = totalETRNLOffered < LIMIT / 4 ? 3100 : (totalETRNLOffered < LIMIT / 2 ? 2600 : (totalETRNLOffered < LIMIT * 3 / 4 ? 2100 : 1600));

        // Add liquidity to the ETRNL/Asset pair
        require(eternal.approve(address(joeRouter), amountETRNL), "Approve failed");
        if (asset == joeRouter.WAVAX()) {
            (providedETRNL, providedAsset, liquidity) = joeRouter.addLiquidityAVAX{value: amount}(address(eternal), amountETRNL, minETRNL, minAsset, address(this), block.timestamp);
            totalLpAVAX += liquidity;
        } else {
            (providedETRNL, providedAsset, liquidity) = joeRouter.addLiquidity(address(eternal), asset, amountETRNL, amount, minETRNL, minAsset, address(this), block.timestamp);
            totalLpMIM += liquidity;
        }
        // Calculate the difference in asset given vs asset provided
        providedETRNL += (amount - providedAsset) * providedETRNL / amount;

        // Update the offering variables
        liquidityOffered[msg.sender] += providedETRNL + (providedETRNL * (rRisk - 100) / (10 ** 4));
        totalETRNLOffered += providedETRNL + (providedETRNL * (rRisk - 100) / (10 ** 4));

        // Initialize the loyalty gage and transfer the user's instant reward
        newGage.initialize(asset, address(eternal), amount, providedETRNL, rRisk, 1000);
        require(eternal.transfer(msg.sender, providedETRNL * (rRisk - 100) / (10 ** 4)), "Failed to transfer bonus");

        return lastId;
    }

    /**
     * @notice Settles a given loyalty gage closed by a given receiver
     * @param receiver The specified receiver 
     * @param id The specified id of the gage
     * @param winner Whether the gage closed in favour of the receiver
     *
     * Requirements:
     * 
     * - Only callable by a loyalty gage
     */
    function settleGage(address receiver, uint256 id, bool winner) external {
        // Checks
        address _gage = gages[id];
        require(msg.sender == _gage, "msg.sender must be the gage");

        // Load all gage data
        ILoyaltyGage gage = ILoyaltyGage(_gage);
        (,, uint256 rRisk) = gage.viewUserData(receiver);
        (,uint256 dAmount, uint256 dRisk) = gage.viewUserData(address(this));

        // Compute and transfer the net gage deposit due to the receiver
        if (winner) {
            dAmount += dAmount * dRisk / (10 ** 4);
        } else {
            dAmount -= dAmount * rRisk / (10 ** 4);
        }
        require(eternal.transfer(receiver, dAmount), "Failed to transfer ETRNL");
    }

/////–––««« Liquidity Provision functions »»»––––\\\\\

    /**
     * @notice Provides liquidity to either the MIM-ETRNL or AVAX-ETRNL pairs and sends ETRNL the msg.sender
     * @param amount The amount of the asset being provided
     * @param asset The address of the asset being provided
     *
     * Requirements:
     * 
     * - The offering must be ongoing
     * - Only MIM or AVAX can be used in providing liquidity
     * - There can not have been more than 4 250 000 000 ETRNL offered in total
     * - A user can not send money to gages/provide liquidity for more than 10 000 000 ETRNL 
     * - The sum of the new amount provided and the previous amounts provided by a user can not exceed the equivalent of 10 000 000 ETRNL
     */
    function provideLiquidity(uint256 amount, address asset) external payable {
        // Checks
        require(block.timestamp < offeringEnds, "Offering is over");
        require(asset == MIM || msg.value > 0, "Only MIM or AVAX");
        require(liquidityOffered[msg.sender] < (10 ** 7) * (10 ** 18), "Limit for this user reached");
        require(totalETRNLOffered < LIMIT, "ETRNL offering limit is reached");


        uint256 providedETRNL;
        uint256 providedAsset;
        uint256 liquidity;
        // Compute the minimum amounts needed to provide liquidity and the equivalent of the asset in ETRNL
        (uint256 minETRNL, uint256 minAsset, uint256 amountETRNL) = computeMinAmounts(asset, address(eternal), amount, 200);
        require(amountETRNL + liquidityOffered[msg.sender] <= (10 ** 7) * (10 ** 18), "Amount exceeds the user limit");

        // Transfer user's funds to this contract if it's not already done
        if (msg.value == 0) {
            require(IERC20(asset).transferFrom(msg.sender, address(this), amount), "Failed to deposit funds");
        } else {
            asset = joeRouter.WAVAX();
        }

        // Add liquidity to the ETRNL/Asset pair
        require(eternal.approve(address(joeRouter), amountETRNL), "Approve failed");
        if (asset == joeRouter.WAVAX()) {
            (providedETRNL, providedAsset, liquidity) = joeRouter.addLiquidityAVAX{value: amount}(address(eternal), amountETRNL, minETRNL, minAsset, address(this), block.timestamp);
            totalLpAVAX += liquidity;
        } else {
            (providedETRNL, providedAsset, liquidity) = joeRouter.addLiquidity(address(eternal), asset, amountETRNL, amount, minETRNL, minAsset, address(this), block.timestamp);
            totalLpMIM += liquidity;
        }

        // Calculate and add the difference in asset given vs asset provided
        providedETRNL += (amount - providedAsset) * providedETRNL / amount;

        // Update the offering variables
        liquidityOffered[msg.sender] += providedETRNL;
        totalETRNLOffered += providedETRNL;

        // Transfer ETRNL to the user
        require(eternal.transfer(msg.sender, providedETRNL), "ETRNL transfer failed");
    }

/////–––««« Post-Offering functions »»»––––\\\\\

    /**
     * @notice Transfer all lp tokens, leftover ETRNL and any dust present in this contract, to the Eternal Treasury
     * 
     * Requirements:
     *
     * - Either the time or ETRNL limit must be met
     */
    function sendLPToTreasury() external {
        // Checks
        require(totalETRNLOffered == LIMIT || offeringEnds < block.timestamp, "Offering not over yet");

        uint256 mimBal = IERC20(MIM).balanceOf(address(this));
        uint256 etrnlBal = eternal.balanceOf(address(this));
        uint256 avaxBal = address(this).balance;
        // Send the MIM and AVAX balance of this contract to the Eternal Treasury if there is any dust leftover
        if (mimBal > 0) {
            require(IERC20(MIM).transfer(treasury, mimBal), "MIM Transfer failed");
        }
        if (avaxBal > 0) {
            (bool success,) = treasury.call{value: avaxBal}("");
            require(success, "AVAX transfer failed");
        }

        // Send any leftover ETRNL from this offering to the Eternal Treasury
        if (etrnlBal > 0) {
            require(eternal.transfer(treasury, etrnlBal), "ETRNL transfer failed");
        }

        // Send the lp tokens earned from this offering to the Eternal Treasury
        require(IERC20(avaxPair).transfer(treasury, totalLpAVAX), "Failed to transfer AVAX lp");
        require(IERC20(mimPair).transfer(treasury, totalLpMIM), "Failed to transfer MIM lp");
    }
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "./Gage.sol";
import "../interfaces/ILoyaltyGage.sol";

/**
 * @title Loyalty Gage contract
 * @author Nobody (me)
 * @notice A loyalty gage creates a healthy, symbiotic relationship between a distributor and a receiver
 */
contract LoyaltyGage is Gage, ILoyaltyGage {

/////–––««« Variables: Addresses and Interfaces »»»––––\\\\\

    // Address of the stakeholder which pays the discount in a loyalty gage
    address private immutable distributor;
    // Address of the stakeholder which benefits from the discount in a loyalty gage
    address private immutable receiver;
    // The asset used in the condition
    IERC20 private assetOfReference;

/////–––««« Variables: Condition computation »»»––––\\\\\

    // The percentage change condition for the total token supply (x 10 ** 11)
    uint256 private immutable percent;
    // The total supply at the time of the deposit
    uint256 private totalSupply;
    // Whether the token's supply is inflationary or deflationary
    bool private immutable inflationary;

/////–––««« Constructors & Initializers »»»––––\\\\\

    constructor(uint256 _id, uint256 _percent, uint256 _users, bool _inflationary, address _distributor, address _receiver, address _storage) Gage(_id, _users, _storage, true) {
        distributor = _distributor;
        receiver = _receiver;
        percent = _percent;
        inflationary = _inflationary;
    }
/////–––««« Variable state-inspection functions »»»––––\\\\\

    /**
     * @notice View the address of the creator
     * @return The address of the creator
     */
    function viewDistributor() external view override returns (address){
        return distributor;
    }

    /**
     * @notice View the address of the buyer
     * @return The address of the buyer
     */
    function viewReceiver() external view override returns (address) {
        return receiver;
    }

    /**
     * @notice View the percent change condition for the total token supply of the deposit
     * @return The percent change condition for the total token supply
     */
    function viewPercent() external view override returns (uint256) {
        return percent;
    }

    /**
     * @notice View whether the deposited token suppply is inflationary or deflationary
     * @return True if the token is inflationary, False if it is deflationary
     */
    function viewInflationary() external view override returns (bool) {
        return inflationary;
    }
    
/////–––««« Gage-logic functions »»»––––\\\\\
    /**
     * @notice Initializes a loyalty gage for the receiver and distributor
     * @param rAsset The address of the asset used as deposit by the receiver
     * @param dAsset The address of the asset used as deposit by the distributor
     * @param rAmount The receiver's chosen deposit amount 
     * @param dAmount The distributor's chosen deposit amount
     * @param rRisk The receiver's risk
     * @param dRisk The distributor's risk
     *
     * Requirements:
     *
     * - Only callable by an Eternal contract
     */
    function initialize(address rAsset, address dAsset, uint256 rAmount, uint256 dAmount, uint256 rRisk, uint256 dRisk) external override {
        bytes32 entity = keccak256(abi.encodePacked(address(eternalStorage)));
        bytes32 sender = keccak256(abi.encodePacked(_msgSender()));
        require(_msgSender() == eternalStorage.getAddress(entity, sender), "msg.sender must be from Eternal");

        treasury = IEternalTreasury(_msgSender());

        // Save receiver parameters and data
        userData[receiver].inGage = true;
        userData[receiver].amount = rAmount;
        userData[receiver].asset = rAsset;
        userData[receiver].risk = rRisk;

        // Save distributor parameters and data
        userData[distributor].inGage = true;
        userData[distributor].amount = dAmount;
        userData[distributor].asset = dAsset;
        userData[distributor].risk = dRisk;

        // Save liquid gage parameters
        assetOfReference = IERC20(dAsset);
        totalSupply = assetOfReference.totalSupply();

        users = 2;

        status = Status.Active;
        emit GageInitiated(id);
    }

    /**
     * @notice Closes this gage and determines the winner
     *
     * Requirements:
     *
     * - Only callable by the receiver
     */
    function exit() external override {
        require(_msgSender() == receiver, "Only the receiver may exit");
        // Remove user from the gage first (prevent re-entrancy)
        userData[receiver].inGage = false;
        userData[distributor].inGage = false;
        // Calculate the change in total supply of the asset of reference
        uint256 deltaSupply = inflationary ? (assetOfReference.totalSupply() - totalSupply) : (totalSupply - assetOfReference.totalSupply());
        uint256 percentChange = deltaSupply * (10 ** 11) / totalSupply;
        // Determine whether the user is the winner
        bool winner = percentChange >= percent;
        emit GageClosed(id, winner);
        status = Status.Closed;
        // Communicate with an external treasury which offers gages
        treasury.settleGage(receiver, id, winner);
    }
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

//SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../interfaces/IEternalStorage.sol";
import "../interfaces/IEternalTreasury.sol";
import "../interfaces/IGage.sol";

/**
 * @title Gage contract 
 * @author Nobody (me)
 * @notice Implements the basic necessities for any gage
 */
abstract contract Gage is Context, IGage {

/////–––««« Variables: Addresses and Interfaces »»»––––\\\\\

    // The Eternal Storage
    IEternalStorage public immutable eternalStorage;
    // The Eternal Treasury
    IEternalTreasury internal treasury;

/////–––««« Variables: Gage data »»»––––\\\\\

    // Holds all users' information in the gage
    mapping (address => UserData) internal userData;
    // The id of the gage
    uint256 internal immutable id;  
    // The maximum number of users in the gage
    uint256 internal immutable capacity; 
    // Keeps track of the number of users left in the gage
    uint256 internal users;
    // The state of the gage       
    Status internal status;
    // Determines whether the gage is a loyalty gage or not       
    bool private immutable loyalty;

/////–––««« Constructor »»»––––\\\\\
    
    constructor (uint256 _id, uint256 _users, address _eternalStorage, bool _loyalty) {
        require(users > 1, "Gage needs at least two users");
        id = _id;
        capacity = _users;
        loyalty = _loyalty;
        eternalStorage = IEternalStorage(_eternalStorage);
    }   

/////–––««« Variable state-inspection functions »»»––––\\\\\

    /**
     * @notice View the number of stakeholders in the gage (if it isn't yet active)
     * @return The number of stakeholders in the selected gage
     */
    function viewGageUserCount() external view override returns (uint256) {
        return users;
    }

    /**
     * @notice View the total user capacity of the gage
     * @return The total user capacity
     */
    function viewCapacity() external view override returns(uint256) {
        return capacity;
    }

    /**
     * @notice View the status of the gage
     * @return An integer indicating the status of the gage
     */
    function viewStatus() external view override returns (uint256) {
        return uint256(status);
    }

    /**
     * @notice View whether the gage is a loyalty gage or not
     * @return True if the gage is a loyalty gage, else false
     */
    function viewLoyalty() external view override returns (bool) {
        return loyalty;
    }

    /**
     * @notice View a given user's gage data 
     * @param user The address of the specified user
     * @return The asset, amount and risk for this user 
     */
    function viewUserData(address user) external view override returns (address, uint256, uint256){
        UserData storage data = userData[user];
        return (data.asset, data.amount, data.risk);
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
    // Unstake a given amount of ETRNL and withdraw any associated rewards in terms of the desired reserve asset
    function unstake(uint256 amount, address asset) external;
    // View the ETRNL/AVAX pair address
    function viewPair() external view returns(address);
    // View whether a liquidity swap is in progress
    function viewUndergoingSwap() external view returns(bool);
    // Provides liquidity for the ETRNL/AVAX pair for the ETRNL token contract
    function provideLiquidity(uint256 contractBalance) external;
    // Allows the withdrawal of AVAX in the contract
    function withdrawAVAX(address payable recipient, uint256 amount) external;
    // Allows the withdrawal of an asset present in the contract
    function withdrawAsset(address asset, address recipient, uint256 amount) external;
    // Sets the address of the Eternal Factory contract
    function setEternalFactory(address newContract) external;
    // Sets the address of the Eternal Token contract
    function setEternalToken(address newContract) external;

    // Signals a disabling/enabling of the automatic liquidity provision
    event AutomaticLiquidityProvisionUpdated(bool value);
    // Signals that liquidity has been added to the ETRNL/WAVAX pair 
    event AutomaticLiquidityProvision(uint256 amountETRNL, uint256 totalSwappedETRNL, uint256 amountAVAX);
    // Signals that part of the locked AVAX balance has been cleared to a given address by decision of the DAO
    event AVAXTransferred(uint256 amount, address recipient);
    // Signals that some of an asset balance has been sent to a given address by decision of the DAO
    event AssetTransferred(address asset, uint256 amount, address recipient);
    // Signals that a user staked a given amount of ETRNL 
    event Stake(address user, uint256 amount);
    // Signals that a user unstaked a given amount of ETRNL
    event Unstake(address user, uint256 amount);
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
    function setAddress(bytes32 entity, bytes32 key, address value) external;
    function setBool(bytes32 entity, bytes32 key, bool value) external;
    function setBytes(bytes32 entity, bytes32 key, bytes32 value) external;

    // Scalar getters
    function getUint(bytes32 entity, bytes32 key) external view returns(uint256);
    function getAddress(bytes32 entity, bytes32 key) external view returns(address);
    function getBool(bytes32 entity, bytes32 key) external view returns(bool);
    function getBytes(bytes32 entity, bytes32 key) external view returns(bytes32);

    // Array setters
    function setUintArrayValue(bytes32 key, uint256 index, uint256 value) external;
    function setAddressArrayValue(bytes32 key, uint256 index, address value) external;
    function setBoolArrayValue(bytes32 key, uint256 index, bool value) external;
    function setBytesArrayValue(bytes32 key, uint256 index, bytes32 value) external;

    // Array getters
    function getUintArrayValue(bytes32 key, uint256 index) external view returns (uint256);
    function getAddressArrayValue(bytes32 key, uint256 index) external view returns (address);
    function getBoolArrayValue(bytes32 key, uint256 index) external view returns (bool);
    function getBytesArrayValue(bytes32 key, uint256 index) external view returns (bytes32);

    //Array Deleters
    function deleteUint(bytes32 key, uint256 index) external;
    function deleteAddress(bytes32 key, uint256 index) external;
    function deleteBool(bytes32 key, uint256 index) external;
    function deleteBytes(bytes32 key, uint256 index) external;

    //Array Length
    function lengthUint(bytes32 key) external view returns (uint256);
    function lengthAddress(bytes32 key) external view returns (uint256);
    function lengthBool(bytes32 key) external view returns (uint256);
    function lengthBytes(bytes32 key) external view returns (uint256);
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