pragma solidity 0.5.16;
pragma experimental ABIEncoderV2;


interface MassetStructs {

    /** @dev Stores high level basket info */
    struct Basket {

        /** @dev Array of Bassets currently active */
        Basset[] bassets;

        /** @dev Max number of bAssets that can be present in any Basket */
        uint8 maxBassets;

        /** @dev Some bAsset is undergoing re-collateralisation */
        bool undergoingRecol;

        /**
         * @dev In the event that we do not raise enough funds from the auctioning of a failed Basset,
         * The Basket is deemed as failed, and is undercollateralised to a certain degree.
         * The collateralisation ratio is used to calc Masset burn rate.
         */
        bool failed;
        uint256 collateralisationRatio;

    }

    /** @dev Stores bAsset info. The struct takes 5 storage slots per Basset */
    struct Basset {

        /** @dev Address of the bAsset */
        address addr;

        /** @dev Status of the basset,  */
        BassetStatus status; // takes uint8 datatype (1 byte) in storage

        /** @dev An ERC20 can charge transfer fee, for example USDT, DGX tokens. */
        bool isTransferFeeCharged; // takes a byte in storage

        /**
         * @dev 1 Basset * ratio / ratioScale == x Masset (relative value)
         *      If ratio == 10e8 then 1 bAsset = 10 mAssets
         *      A ratio is divised as 10^(18-tokenDecimals) * measurementMultiple(relative value of 1 base unit)
         */
        uint256 ratio;

        /** @dev Target weights of the Basset (100% == 1e18) */
        uint256 maxWeight;

        /** @dev Amount of the Basset that is held in Collateral */
        uint256 vaultBalance;

    }

    /** @dev Status of the Basset - has it broken its peg? */
    enum BassetStatus {
        Default,
        Normal,
        BrokenBelowPeg,
        BrokenAbovePeg,
        Blacklisted,
        Liquidating,
        Liquidated,
        Failed
    }

    /** @dev Internal details on Basset */
    struct BassetDetails {
        Basset bAsset;
        address integrator;
        uint8 index;
    }

    /** @dev All details needed to Forge with multiple bAssets */
    struct ForgePropsMulti {
        bool isValid; // Flag to signify that forge bAssets have passed validity check
        Basset[] bAssets;
        address[] integrators;
        uint8[] indexes;
    }

    /** @dev All details needed for proportionate Redemption */
    struct RedeemPropsMulti {
        uint256 colRatio;
        Basset[] bAssets;
        address[] integrators;
        uint8[] indexes;
    }
}

contract IMasset is MassetStructs {

    /** @dev Calc interest */
    function collectInterest() external returns (uint256 massetMinted, uint256 newTotalSupply);

    /** @dev Minting */
    function mint(address _basset, uint256 _bassetQuantity)
        external returns (uint256 massetMinted);
    function mintTo(address _basset, uint256 _bassetQuantity, address _recipient)
        external returns (uint256 massetMinted);
    function mintMulti(address[] calldata _bAssets, uint256[] calldata _bassetQuantity, address _recipient)
        external returns (uint256 massetMinted);

    /** @dev Swapping */
    function swap( address _input, address _output, uint256 _quantity, address _recipient)
        external returns (uint256 output);
    function getSwapOutput( address _input, address _output, uint256 _quantity)
        external view returns (bool, string memory, uint256 output);

    /** @dev Redeeming */
    function redeem(address _basset, uint256 _bassetQuantity)
        external returns (uint256 massetRedeemed);
    function redeemTo(address _basset, uint256 _bassetQuantity, address _recipient)
        external returns (uint256 massetRedeemed);
    function redeemMulti(address[] calldata _bAssets, uint256[] calldata _bassetQuantities, address _recipient)
        external returns (uint256 massetRedeemed);
    function redeemMasset(uint256 _mAssetQuantity, address _recipient) external;

    /** @dev Setters for the Manager or Gov to update module info */
    function upgradeForgeValidator(address _newForgeValidator) external;

    /** @dev Setters for Gov to set system params */
    function setSwapFee(uint256 _swapFee) external;

    /** @dev Getters */
    function getBasketManager() external view returns(address);
    function forgeValidator() external view returns (address);
    function totalSupply() external view returns (uint256);
    function swapFee() external view returns (uint256);
}

contract IBasketManager is MassetStructs {

    /** @dev Setters for mAsset to update balances */
    function increaseVaultBalance(
        uint8 _bAsset,
        address _integrator,
        uint256 _increaseAmount) external;
    function increaseVaultBalances(
        uint8[] calldata _bAsset,
        address[] calldata _integrator,
        uint256[] calldata _increaseAmount) external;
    function decreaseVaultBalance(
        uint8 _bAsset,
        address _integrator,
        uint256 _decreaseAmount) external;
    function decreaseVaultBalances(
        uint8[] calldata _bAsset,
        address[] calldata _integrator,
        uint256[] calldata _decreaseAmount) external;
    function collectInterest() external
        returns (uint256 interestCollected, uint256[] memory gains);

    /** @dev Setters for Gov to update Basket composition */
    function addBasset(
        address _basset,
        address _integration,
        bool _isTransferFeeCharged) external returns (uint8 index);
    function setBasketWeights(address[] calldata _bassets, uint256[] calldata _weights) external;
    function setTransferFeesFlag(address _bAsset, bool _flag) external;

    /** @dev Getters to retrieve Basket information */
    function getBasket() external view returns (Basket memory b);
    function prepareForgeBasset(address _token, uint256 _amt, bool _mint) external
        returns (bool isValid, BassetDetails memory bInfo);
    function prepareSwapBassets(address _input, address _output, bool _isMint) external view
        returns (bool, string memory, BassetDetails memory, BassetDetails memory);
    function prepareForgeBassets(address[] calldata _bAssets, uint256[] calldata _amts, bool _mint) external
        returns (ForgePropsMulti memory props);
    function prepareRedeemMulti() external view
        returns (RedeemPropsMulti memory props);
    function getBasset(address _token) external view
        returns (Basset memory bAsset);
    function getBassets() external view
        returns (Basset[] memory bAssets, uint256 len);
    function paused() external view returns (bool);

    /** @dev Recollateralisation */
    function handlePegLoss(address _basset, bool _belowPeg) external returns (bool actioned);
    function negateIsolation(address _basset) external;
}

interface ISavingsContract {

    /** @dev Manager privs */
    function depositInterest(uint256 _amount) external;

    /** @dev Saver privs */
    function depositSavings(uint256 _amount) external returns (uint256 creditsIssued);
    function redeem(uint256 _amount) external returns (uint256 massetReturned);

    /** @dev Getters */
    function exchangeRate() external view returns (uint256);
    function creditBalances(address) external view returns (uint256);
}

interface IMStableHelper {

    /**
     * @dev Returns a valid bAsset with which to mint
     * @param _mAsset Masset addr
     * @return valid bool
     * @return string message
     * @return address of bAsset to mint
     */
    function suggestMintAsset(
        address _mAsset
    )
        external
        view
        returns (
            bool,
            string memory,
            address
        );

    /**
     * @dev Gets the maximum input for a valid swap pair
     * @param _mAsset mAsset address (e.g. mUSD)
     * @param _input Asset to input only bAssets accepted
     * @param _output Either a bAsset or the mAsset
     * @return valid
     * @return validity reason
     * @return max input units (in native decimals)
     * @return how much output this input would produce (in native decimals, after any fee)
     */
    function getMaxSwap(
        address _mAsset,
        address _input,
        address _output
    )
        external
        view
        returns (
            bool,
            string memory,
            uint256,
            uint256
        );


    /**
     * @dev Returns a valid bAsset to redeem
     * @param _mAsset Masset addr
     * @return valid bool
     * @return string message
     * @return address of bAsset to redeem
     */
    function suggestRedeemAsset(
        address _mAsset
    )
        external
        view
        returns (
            bool,
            string memory,
            address
        );

    /**
     * @dev Determines if a given Redemption is valid
     * @param _mAsset Address of the given mAsset (e.g. mUSD)
     * @param _mAssetQuantity Amount of mAsset to redeem (in mUSD units)
     * @param _outputBasset Desired output bAsset
     * @return valid
     * @return validity reason
     * @return output in bAsset units
     * @return bAssetQuantityArg - required input argument to the 'redeem' call
     */
    function getRedeemValidity(
        address _mAsset,
        uint256 _mAssetQuantity,
        address _outputBasset
    )
        external
        view
        returns (
            bool,
            string memory,
            uint256 output,
            uint256 bassetQuantityArg
        );

    /**
     * @dev Gets the users savings balance in Masset terms
     * @param _save SAVE contract address
     * @param _user Address of the user
     * @return balance in Masset units
     */
    function getSaveBalance(
        ISavingsContract _save,
        address _user
    )
        external
        view
        returns (
            uint256
        );

    /**
     * @dev Returns the 'credit' units required to withdraw a certain
     * amount of Masset from the SAVE contract
     * @param _save SAVE contract address
     * @param _amount Amount of mAsset to redeem from SAVE
     * @return input for the redeem function (ie. credit units to redeem)
     */
    function getSaveRedeemInput(
        ISavingsContract _save,
        uint256 _amount
    )
        external
        view
        returns (
            uint256
        );
}

contract IForgeValidator is MassetStructs {
    function validateMint(uint256 _totalVault, Basset calldata _basset, uint256 _bAssetQuantity)
        external pure returns (bool, string memory);
    function validateMintMulti(uint256 _totalVault, Basset[] calldata _bassets, uint256[] calldata _bAssetQuantities)
        external pure returns (bool, string memory);
    function validateSwap(uint256 _totalVault, Basset calldata _inputBasset, Basset calldata _outputBasset, uint256 _quantity)
        external pure returns (bool, string memory, uint256, bool);
    function validateRedemption(
        bool basketIsFailed,
        uint256 _totalVault,
        Basset[] calldata _allBassets,
        uint8[] calldata _indices,
        uint256[] calldata _bassetQuantities) external pure returns (bool, string memory, bool);
    function calculateRedemptionMulti(
        uint256 _mAssetQuantity,
        Basset[] calldata _allBassets) external pure returns (bool, string memory, uint256[] memory);
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library StableMath {

    using SafeMath for uint256;

    /**
     * @dev Scaling unit for use in specific calculations,
     * where 1 * 10**18, or 1e18 represents a unit '1'
     */
    uint256 private constant FULL_SCALE = 1e18;

    /**
     * @notice Token Ratios are used when converting between units of bAsset, mAsset and MTA
     * Reasoning: Takes into account token decimals, and difference in base unit (i.e. grams to Troy oz for gold)
     * @dev bAsset ratio unit for use in exact calculations,
     * where (1 bAsset unit * bAsset.ratio) / ratioScale == x mAsset unit
     */
    uint256 private constant RATIO_SCALE = 1e8;

    /**
     * @dev Provides an interface to the scaling unit
     * @return Scaling unit (1e18 or 1 * 10**18)
     */
    function getFullScale() internal pure returns (uint256) {
        return FULL_SCALE;
    }

    /**
     * @dev Provides an interface to the ratio unit
     * @return Ratio scale unit (1e8 or 1 * 10**8)
     */
    function getRatioScale() internal pure returns (uint256) {
        return RATIO_SCALE;
    }

    /**
     * @dev Scales a given integer to the power of the full scale.
     * @param x   Simple uint256 to scale
     * @return    Scaled value a to an exact number
     */
    function scaleInteger(uint256 x)
        internal
        pure
        returns (uint256)
    {
        return x.mul(FULL_SCALE);
    }

    /***************************************
              PRECISE ARITHMETIC
    ****************************************/

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncate(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return mulTruncateScale(x, y, FULL_SCALE);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the given scale. For example,
     * when calculating 90% of 10e18, (10e18 * 9e17) / 1e18 = (9e36) / 1e18 = 9e18
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @param scale Scale unit
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit
     */
    function mulTruncateScale(uint256 x, uint256 y, uint256 scale)
        internal
        pure
        returns (uint256)
    {
        // e.g. assume scale = fullScale
        // z = 10e18 * 9e17 = 9e36
        uint256 z = x.mul(y);
        // return 9e38 / 1e18 = 9e18
        return z.div(scale);
    }

    /**
     * @dev Multiplies two precise units, and then truncates by the full scale, rounding up the result
     * @param x     Left hand input to multiplication
     * @param y     Right hand input to multiplication
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              scale unit, rounded up to the closest base unit.
     */
    function mulTruncateCeil(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        // e.g. 8e17 * 17268172638 = 138145381104e17
        uint256 scaled = x.mul(y);
        // e.g. 138145381104e17 + 9.99...e17 = 138145381113.99...e17
        uint256 ceil = scaled.add(FULL_SCALE.sub(1));
        // e.g. 13814538111.399...e18 / 1e18 = 13814538111
        return ceil.div(FULL_SCALE);
    }

    /**
     * @dev Precisely divides two units, by first scaling the left hand operand. Useful
     *      for finding percentage weightings, i.e. 8e18/10e18 = 80% (or 8e17)
     * @param x     Left hand input to division
     * @param y     Right hand input to division
     * @return      Result after multiplying the left operand by the scale, and
     *              executing the division on the right hand input.
     */
    function divPrecisely(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        // e.g. 8e18 * 1e18 = 8e36
        uint256 z = x.mul(FULL_SCALE);
        // e.g. 8e36 / 10e18 = 8e17
        return z.div(y);
    }


    /***************************************
                  RATIO FUNCS
    ****************************************/

    /**
     * @dev Multiplies and truncates a token ratio, essentially flooring the result
     *      i.e. How much mAsset is this bAsset worth?
     * @param x     Left hand operand to multiplication (i.e Exact quantity)
     * @param ratio bAsset ratio
     * @return      Result after multiplying the two inputs and then dividing by the ratio scale
     */
    function mulRatioTruncate(uint256 x, uint256 ratio)
        internal
        pure
        returns (uint256 c)
    {
        return mulTruncateScale(x, ratio, RATIO_SCALE);
    }

    /**
     * @dev Multiplies and truncates a token ratio, rounding up the result
     *      i.e. How much mAsset is this bAsset worth?
     * @param x     Left hand input to multiplication (i.e Exact quantity)
     * @param ratio bAsset ratio
     * @return      Result after multiplying the two inputs and then dividing by the shared
     *              ratio scale, rounded up to the closest base unit.
     */
    function mulRatioTruncateCeil(uint256 x, uint256 ratio)
        internal
        pure
        returns (uint256)
    {
        // e.g. How much mAsset should I burn for this bAsset (x)?
        // 1e18 * 1e8 = 1e26
        uint256 scaled = x.mul(ratio);
        // 1e26 + 9.99e7 = 100..00.999e8
        uint256 ceil = scaled.add(RATIO_SCALE.sub(1));
        // return 100..00.999e8 / 1e8 = 1e18
        return ceil.div(RATIO_SCALE);
    }


    /**
     * @dev Precisely divides two ratioed units, by first scaling the left hand operand
     *      i.e. How much bAsset is this mAsset worth?
     * @param x     Left hand operand in division
     * @param ratio bAsset ratio
     * @return      Result after multiplying the left operand by the scale, and
     *              executing the division on the right hand input.
     */
    function divRatioPrecisely(uint256 x, uint256 ratio)
        internal
        pure
        returns (uint256 c)
    {
        // e.g. 1e14 * 1e8 = 1e22
        uint256 y = x.mul(RATIO_SCALE);
        // return 1e22 / 1e12 = 1e10
        return y.div(ratio);
    }

    /***************************************
                    HELPERS
    ****************************************/

    /**
     * @dev Calculates minimum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Minimum of the two inputs
     */
    function min(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return x > y ? y : x;
    }

    /**
     * @dev Calculated maximum of two numbers
     * @param x     Left hand input
     * @param y     Right hand input
     * @return      Maximum of the two inputs
     */
    function max(uint256 x, uint256 y)
        internal
        pure
        returns (uint256)
    {
        return x > y ? x : y;
    }

    /**
     * @dev Clamps a value to an upper bound
     * @param x           Left hand input
     * @param upperBound  Maximum possible value to return
     * @return            Input x clamped to a maximum value, upperBound
     */
    function clamp(uint256 x, uint256 upperBound)
        internal
        pure
        returns (uint256)
    {
        return x > upperBound ? upperBound : x;
    }
}

/**
 * @title   MStableHelper
 * @author  Stability Labs Pty. Ltd.
 * @notice  Returns the validity and output of a given redemption
 * @dev     VERSION: 1.0
 *          DATE:    2020-06-18
 */
contract MStableHelper is IMStableHelper, MassetStructs {

    using StableMath for uint256;
    using SafeMath for uint256;


    /***************************************
                MINT/SWAP/REDEEM
    ****************************************/

    /**
     * @dev Returns a valid bAsset with which to mint
     * @param _mAsset Masset addr
     * @return valid bool
     * @return string message
     * @return address of bAsset to mint
     */
    function suggestMintAsset(
        address _mAsset
    )
        external
        view
        returns (
            bool,
            string memory,
            address
        )
    {
        require(_mAsset != address(0), "Invalid mAsset");
        // Get the data
        IBasketManager basketManager = IBasketManager(
            IMasset(_mAsset).getBasketManager()
        );
        Basket memory basket = basketManager.getBasket();
        uint256 totalSupply = IMasset(_mAsset).totalSupply();

        // Calc the max weight delta (i.e is X% away from Max weight)
        uint256 len = basket.bassets.length;
        uint256[] memory maxWeightDelta = new uint256[](len);
        for(uint256 i = 0; i < len; i++){
            Basset memory bAsset = basket.bassets[i];
            uint256 scaledBasset = bAsset.vaultBalance.mulRatioTruncate(bAsset.ratio);
            // e.g. (1e21 * 1e18) / 1e23 = 1e16 or 1%
            uint256 weight = scaledBasset.divPrecisely(totalSupply);
            maxWeightDelta[i] = weight > bAsset.maxWeight ? 0 : bAsset.maxWeight.sub(weight);
            if(bAsset.status != BassetStatus.Normal){
                return (false, "No assets available", address(0));
            }
        }
        // Ideal delta is the bAsset > 10 but closest
        uint256 idealMaxWeight = 0;
        address selected = address(0);
        for(uint256 j = 0; j < len; j++){
            uint256 bAssetDelta = maxWeightDelta[j];
            if(bAssetDelta >= 1e17){
                if(selected == address(0) || bAssetDelta < idealMaxWeight){
                    idealMaxWeight = bAssetDelta;
                    selected = basket.bassets[j].addr;
                }
            }
        }
        if(selected == address(0)){
            return (false, "No assets available", address(0));
        }
        return (true, "", selected);
    }


    /**
     * @dev Gets the maximum input for a valid swap pair
     * @param _mAsset mAsset address (e.g. mUSD)
     * @param _input Asset to input only bAssets accepted
     * @param _output Either a bAsset or the mAsset
     * @return valid
     * @return validity reason
     * @return max input units (in native decimals)
     * @return how much output this input would produce (in native decimals, after any fee)
     */
    function getMaxSwap(
        address _mAsset,
        address _input,
        address _output
    )
        external
        view
        returns (
            bool,
            string memory,
            uint256,
            uint256
        )
    {
        Data memory data = _getData(_mAsset, _input, _output);
        if(!data.isValid) {
          return (false, data.reason, 0, 0);
        }
        uint256 inputMaxWeightUnits = data.totalSupply.mulTruncate(data.input.maxWeight);
        uint256 inputVaultBalanceScaled = data.input.vaultBalance.mulRatioTruncate(
            data.input.ratio
        );
        if (data.isMint) {
            // M = ((t * maxW) - c)/(1-maxW)
            // M = max mint (scaled)
            // t = totalSupply before
            // maxW = max weight %
            // c = vault balance (scaled)
            // num = (t * maxW) - c
            // e.g. 1e22 - 1e21 = 9e21
            uint256 num = inputMaxWeightUnits.sub(inputVaultBalanceScaled);
            // den = 1e18 - maxW
            // e.g. 1e18 - 75e16 = 25e16
            uint256 den = StableMath.getFullScale().sub(data.input.maxWeight);
            uint256 maxMintScaled = den > 0 ? num.divPrecisely(den) : num;
            uint256 maxMint = maxMintScaled.divRatioPrecisely(data.input.ratio);
            maxMintScaled = maxMint.mulRatioTruncate(data.input.ratio);
            return (true, "", maxMint, maxMintScaled);
        } else {
            // get max input
            uint256 maxInputScaled = inputMaxWeightUnits.sub(inputVaultBalanceScaled);
            // get max output
            uint256 outputMaxWeight = data.totalSupply.mulTruncate(data.output.maxWeight);
            uint256 outputVaultBalanceScaled = data.output.vaultBalance.mulRatioTruncate(data.output.ratio);
            // If maxInput = 2, outputVaultBalance = 1, then clamp to 1
            uint256 clampedMax = maxInputScaled > outputVaultBalanceScaled ? outputVaultBalanceScaled : maxInputScaled;
            // if output is overweight, no fee, else fee
            bool applyFee = outputVaultBalanceScaled < outputMaxWeight;
            uint256 maxInputUnits = clampedMax.divRatioPrecisely(data.input.ratio);
            uint256 outputUnitsIncFee = maxInputUnits.mulRatioTruncate(data.input.ratio).divRatioPrecisely(data.output.ratio);

            uint256 fee = applyFee ? data.mAsset.swapFee() : 0;
            uint256 outputFee = outputUnitsIncFee.mulTruncate(fee);
            return (true, "", maxInputUnits, outputUnitsIncFee.sub(outputFee));
        }
    }

    /**
     * @dev Returns a valid bAsset to redeem
     * @param _mAsset Masset addr
     * @return valid bool
     * @return string message
     * @return address of bAsset to redeem
     */
    function suggestRedeemAsset(
        address _mAsset
    )
        external
        view
        returns (
            bool,
            string memory,
            address
        )
    {
        require(_mAsset != address(0), "Invalid mAsset");
        // Get the data
        IBasketManager basketManager = IBasketManager(
            IMasset(_mAsset).getBasketManager()
        );
        Basket memory basket = basketManager.getBasket();
        uint256 totalSupply = IMasset(_mAsset).totalSupply();

        // Calc the max weight delta (i.e is X% away from Max weight)
        uint256 len = basket.bassets.length;
        uint256 overweightCount = 0;
        uint256[] memory maxWeightDelta = new uint256[](len);
        
        for(uint256 i = 0; i < len; i++){
            Basset memory bAsset = basket.bassets[i];
            uint256 scaledBasset = bAsset.vaultBalance.mulRatioTruncate(bAsset.ratio);
            // e.g. (1e21 * 1e18) / 1e23 = 1e16 or 1%
            uint256 weight = scaledBasset.divPrecisely(totalSupply);
            if(weight > bAsset.maxWeight) {
                overweightCount++;
            }
            maxWeightDelta[i] = weight > bAsset.maxWeight ? uint256(-1) : bAsset.maxWeight.sub(weight);
            if(bAsset.status != BassetStatus.Normal){
                return (false, "No assets available", address(0));
            }
        }

        // if > 1 overweight, fail
        if(overweightCount > 1) {
            return (false, "No assets available", address(0));
        } else if(overweightCount == 1){
            // if 1 overweight, choose asset
            for(uint256 j = 0; j < len; j++){
                if(maxWeightDelta[j] == uint256(-1)){
                    return (true, "", basket.bassets[j].addr);
                }
            }
        }
        // else choose highest %
        uint256 lowestDelta = uint256(-1);
        address selected = address(0);
        for(uint256 k = 0; k < len; k++){
            if(maxWeightDelta[k] < lowestDelta) {
                selected = basket.bassets[k].addr;
                lowestDelta = maxWeightDelta[k];
            }
        }
        return (true, "", selected);
    }

    /**
     * @dev Determines if a given Redemption is valid
     * @param _mAsset Address of the given mAsset (e.g. mUSD)
     * @param _mAssetQuantity Amount of mAsset to redeem (in mUSD units)
     * @param _outputBasset Desired output bAsset
     * @return valid
     * @return validity reason
     * @return output in bAsset units
     * @return bAssetQuantityArg - required input argument to the 'redeem' call
     */
    function getRedeemValidity(
        address _mAsset,
        uint256 _mAssetQuantity,
        address _outputBasset
    )
        external
        view
        returns (
            bool,
            string memory,
            uint256 output,
            uint256 bassetQuantityArg
        )
    {
        // Convert the `mAssetQuantity` (input) into bAsset units
        IBasketManager basketManager = IBasketManager(
            IMasset(_mAsset).getBasketManager()
        );
        Basset memory bAsset = basketManager.getBasset(_outputBasset);
        uint256 bAssetQuantity = _mAssetQuantity.divRatioPrecisely(
            bAsset.ratio
        );

        // Prepare params for internal validity
        address[] memory bAssets = new address[](1);
        uint256[] memory quantities = new uint256[](1);
        bAssets[0] = _outputBasset;
        quantities[0] = bAssetQuantity;
        (
            bool valid,
            string memory reason,
            uint256 bAssetOutput
        ) = _getRedeemValidity(_mAsset, bAssets, quantities);
        return (valid, reason, bAssetOutput, bAssetQuantity);
    }


    /***************************************
                    SAVE
    ****************************************/

    /**
     * @dev Gets the users savings balance in Masset terms
     * @param _save SAVE contract address
     * @param _user Address of the user
     * @return balance in Masset units
     */
    function getSaveBalance(
        ISavingsContract _save,
        address _user
    )
        external
        view
        returns (
            uint256
        )
    {
        require(address(_save) != address(0), "Invalid contract");
        require(_user != address(0), "Invalid user");

        uint256 credits = _save.creditBalances(_user);
        uint256 rate = _save.exchangeRate();
        require(rate > 0, "Invalid rate");

        return credits.mulTruncate(rate);
    }

    /**
     * @dev Returns the 'credit' units required to withdraw a certain
     * amount of Masset from the SAVE contract
     * @param _save SAVE contract address
     * @param _mAssetUnits Amount of mAsset to redeem from SAVE
     * @return input for the redeem function (ie. credit units to redeem)
     */
    function getSaveRedeemInput(
        ISavingsContract _save,
        uint256 _mAssetUnits
    )
        external
        view
        returns (
            uint256
        )
    {
        require(address(_save) != address(0), "Invalid contract");

        uint256 rate = _save.exchangeRate();
        require(rate > 0, "Invalid rate");

        uint256 credits = _mAssetUnits.divPrecisely(rate);

        // Add 1 because the amounts always round down
        // e.g. i have 51 credits, e4 10 = 20.4
        // to withdraw 20 i need 20*10/4 = 50 + 1
        return credits + 1;
    }


    /***************************************
                    INTERNAL
    ****************************************/

    struct Data {
        bool isValid;
        string reason;
        IMasset mAsset;
        IBasketManager basketManager;
        bool isMint;
        uint256 totalSupply;
        Basset input;
        Basset output;
    }

    function _getData(address _mAsset, address _input, address _output) internal view returns (Data memory) {
        bool isMint = _output == _mAsset;
        IMasset mAsset = IMasset(_mAsset);
        IBasketManager basketManager = IBasketManager(
            mAsset.getBasketManager()
        );
        (bool isValid, string memory reason, ) = mAsset
            .getSwapOutput(_input, _output, 1);
        uint256 totalSupply = mAsset.totalSupply();
        Basset memory input = basketManager.getBasset(_input);
        Basset memory output = !isMint ? basketManager.getBasset(_output) : Basset({
            addr: _output,
            ratio: StableMath.getRatioScale(),
            maxWeight: 0,
            vaultBalance: 0,
            status: BassetStatus.Normal,
            isTransferFeeCharged: false
        });
        return Data({
            isValid: isValid,
            reason: reason,
            mAsset: mAsset,
            basketManager: basketManager,
            isMint: isMint,
            totalSupply: totalSupply,
            input: input,
            output: output
        });
    }


    function _getRedeemValidity(
        address _mAsset,
        address[] memory _bAssets,
        uint256[] memory _bAssetQuantities
    )
        internal
        view
        returns (
            bool,
            string memory,
            uint256 output
        )
    {
        uint256 bAssetCount = _bAssetQuantities.length;
        require(
            bAssetCount == 1 && bAssetCount == _bAssets.length,
            "Input array mismatch"
        );

        IMasset mAsset = IMasset(_mAsset);
        IBasketManager basketManager = IBasketManager(
            mAsset.getBasketManager()
        );

        Basket memory basket = basketManager.getBasket();

        if (basket.undergoingRecol || basketManager.paused()) {
            return (false, "Invalid basket state", 0);
        }

        (
            bool redemptionValid,
            string memory reason,
            bool applyFee
        ) = _validateRedeem(
            mAsset,
            _bAssetQuantities,
            _bAssets[0],
            basket.failed,
            mAsset.totalSupply(),
            basket.bassets
        );
        if (!redemptionValid) {
            return (false, reason, 0);
        }
        uint256 fee = applyFee ? mAsset.swapFee() : 0;
        uint256 feeAmount = _bAssetQuantities[0].mulTruncate(fee);
        uint256 outputMinusFee = _bAssetQuantities[0].sub(feeAmount);
        return (true, "", outputMinusFee);
    }


    function _validateRedeem(
        IMasset mAsset,
        uint256[] memory quantities,
        address bAsset,
        bool failed,
        uint256 supply,
        Basset[] memory allBassets
    )
        internal
        view
        returns (
            bool,
            string memory,
            bool
        )
    {
        IForgeValidator forgeValidator = IForgeValidator(
            mAsset.forgeValidator()
        );
        uint8[] memory bAssetIndexes = new uint8[](1);
        for (uint8 i = 0; i < uint8(allBassets.length); i++) {
            if (allBassets[i].addr == bAsset) {
                bAssetIndexes[0] = i;
                break;
            }
        }
        return
            forgeValidator.validateRedemption(
                failed,
                supply,
                allBassets,
                bAssetIndexes,
                quantities
            );
    }

}