// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;

import "IInterestManager.sol";
import "Ownable.sol";
import "ICToken.sol";
import "IComptroller.sol";
import "IERC20.sol";
import "Initializable.sol";
import "SafeMath.sol";

/**
 * @title InterestManagerCompound
 * @author Alexander Schlindwein
 * 
 * Invests DAI into Compound to generate interest
 * Sits behind an AdminUpgradabilityProxy 
 */
contract InterestManagerCompound is Ownable, Initializable {

    using SafeMath for uint;

    // Dai contract
    IERC20 private _dai;
    // cDai contract
    ICToken private _cDai;
    // COMP contract
    IERC20 private _comp;
    // Address which is allowed to withdraw accrued COMP tokens
    address private _compRecipient;

    /**
     * Initializes the contract with all required values
     *
     * @param owner The owner of the contract
     * @param dai The Dai token address
     * @param cDai The cDai token address
     * @param comp The Comp token address
     * @param compRecipient The address of the recipient of the Comp tokens
     */
    function initialize(address owner, address dai, address cDai, address comp, address compRecipient) external initializer {
        require(dai != address(0) &&
                cDai != address(0) && 
                comp != address(0) &&
                compRecipient != address(0),
                "invalid-params");

        setOwnerInternal(owner); // Checks owner to be non-zero
        _dai = IERC20(dai);
        _cDai = ICToken(cDai);
        _comp = IERC20(comp);
        _compRecipient = compRecipient;
    }

    /**
     * Invests a given amount of Dai into Compound
     * The Dai have to be transfered to this contract before this function is called
     *
     * @param amount The amount of Dai to invest
     *
     * @return The amount of minted cDai
     */
    function invest(uint amount) external onlyOwner returns (uint) {
        uint balanceBefore = _cDai.balanceOf(address(this));
        require(_dai.balanceOf(address(this)) >= amount, "insufficient-dai");
        require(_dai.approve(address(_cDai), amount), "dai-cdai-approve");
        require(_cDai.mint(amount) == 0, "cdai-mint");
        uint balanceAfter = _cDai.balanceOf(address(this));
        return balanceAfter.sub(balanceBefore);
    }

    /**
     * Redeems a given amount of Dai from Compound and sends it to the recipient
     *
     * @param recipient The recipient of the redeemed Dai
     * @param amount The amount of Dai to redeem
     *
     * @return The amount of burned cDai
     */
    function redeem(address recipient, uint amount) external onlyOwner returns (uint) {
        uint balanceBefore = _cDai.balanceOf(address(this));
        require(_cDai.redeemUnderlying(amount) == 0, "redeem");
        uint balanceAfter = _cDai.balanceOf(address(this));
        require(_dai.transfer(recipient, amount), "dai-transfer");
        return balanceBefore.sub(balanceAfter);
    }

    /**
     * Redeems a given amount of cDai from Compound and sends Dai to the recipient
     *
     * @param recipient The recipient of the redeemed Dai
     * @param amount The amount of cDai to redeem
     *
     * @return The amount of redeemed Dai
     */
    function redeemInvestmentToken(address recipient, uint amount) external onlyOwner returns (uint) {
        uint balanceBefore = _dai.balanceOf(address(this));
        require(_cDai.redeem(amount) == 0, "redeem");
        uint redeemed = _dai.balanceOf(address(this)).sub(balanceBefore);
        require(_dai.transfer(recipient, redeemed), "dai-transfer");
        return redeemed;
    }

    /**
     * Updates accrued interest on the invested Dai
     */
    function accrueInterest() external {
        require(_cDai.accrueInterest() == 0, "accrue");
    }

    /**
     * Withdraws the generated Comp tokens to the Comp recipient
     */
    function withdrawComp() external {
        address addr = address(this);
        IComptroller(_cDai.comptroller()).claimComp(addr);
        require(_comp.transfer(_compRecipient, _comp.balanceOf(addr)), "comp-transfer");
    }

    /**
     * Converts an amount of underlying tokens to an amount of investment tokens
     *
     * @param underlyingAmount The amount of underlying tokens
     *
     * @return The amount of investment tokens
     */
    function underlyingToInvestmentToken(uint underlyingAmount) external view returns (uint) {
        return divScalarByExpTruncate(underlyingAmount, _cDai.exchangeRateStored());
    }

    /**
     * Converts an amount of investment tokens to an amount of underlying tokens
     *
     * @param investmentTokenAmount The amount of investment tokens
     *
     * @return The amount of underlying tokens
     */
    function investmentTokenToUnderlying(uint investmentTokenAmount) external view returns (uint) {
        return mulScalarTruncate(investmentTokenAmount, _cDai.exchangeRateStored());
    }

    // ====================================== COMPOUND MATH ======================================
    // https://github.com/compound-finance/compound-protocol/blob/master/contracts/Exponential.sol
    //
    // Modified to revert instead of returning an error code

    function mulScalarTruncate(uint a, uint scalar) pure internal returns (uint) {
        uint product = mulScalar(a, scalar);
        return truncate(product);
    }

    function mulScalar(uint a, uint scalar) pure internal returns (uint) {
        return a.mul(scalar);
    }

    function divScalarByExpTruncate(uint scalar, uint divisor) pure internal returns (uint) {
        uint fraction = divScalarByExp(scalar, divisor);
        return truncate(fraction);
    }

    function divScalarByExp(uint scalar, uint divisor) pure internal returns (uint) {
        uint numerator = uint(10**18).mul(scalar);
        return getExp(numerator, divisor);
    }

    function getExp(uint num, uint denom) pure internal returns (uint) {
        uint scaledNumerator = num.mul(10**18);
        return scaledNumerator.div(denom);
    }

    function truncate(uint num) pure internal returns (uint) {
        return num / 10**18;
    }

}