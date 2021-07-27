// SPDX-License-Identifier: MIT

pragma solidity ^0.7.6;

import "./Ownable.sol";
import "./Safemath.sol";
import "./ReentrancyGuard.sol";

/**
 * @title Sale
 * @dev Contract that allows the users to deposit balance and
 * win rewards through referrals. The amount collected above.
 * The targeted amount gets refunded to the respective participant.
 */
contract Sale is Ownable, ReentrancyGuard {
    using Safemath for uint256;

    /*=====================================
    =            CONFIGURABLES            =
    =====================================*/
    uint256 public REFERRAL_FEE = 0; // 0%
    bool public saleStarted = false;

    // This is the total amount collected minus the amount to be refunded
    uint256 public totalAmountCollected;

    mapping(address => uint256) public balanceLedger;

    /*==============================
    =            EVENTS            =
    ==============================*/
    event OnSaleStart();
    event OnSaleEnd();
    event OnWithdraw(uint256 amount);
    event OnBuy(
        address indexed buyer,
        uint256 amount,
        address referredBy,
        uint256 referralFee
    );

    /*==============================
    =           FUNCTIONS          =
    ==============================*/

    /**
     * @notice Function to buy funds.
     * @param referredBy Referral address
     */
    function buy(address referredBy)
        external
        payable
        nonReentrant()
        returns (uint256 amount)
    {
        require(saleStarted, "Sale is not live");

        amount = msg.value;

        // Update total amount
        totalAmountCollected += amount;

        // Update user's balance ledger
        balanceLedger[msg.sender] += amount;

        // Transfer referralFee
        uint256 referralFee = 0;
        if (REFERRAL_FEE > 0) {
            referralFee = mulDiv(amount, REFERRAL_FEE, 100);
            payable(referredBy).transfer(referralFee);
        }

        emit OnBuy(msg.sender, amount, referredBy, referralFee);
    }

    /**
     * @notice Function to withdraw all the funds.
     */
    function withdraw() external onlyOwner returns (uint256 balance) {
        balance = address(this).balance;
        require(balance > 0, "Not enough balance");

        address ownerAddress = owner();

        // Tranfer all the amount to the owner
        payable(ownerAddress).transfer(balance);

        emit OnWithdraw(balance);
    }

    /**
     * @notice Function to reset REFERRAL_FEE.
     */
    function resetReferralFee(uint256 referralFee) external onlyOwner {
        REFERRAL_FEE = referralFee;
    }

    /**
     * @notice Function to start the sale.
     */
    function startSale() external onlyOwner {
        saleStarted = true;
        emit OnSaleStart();
    }

    /**
     * @notice Function to end the sale.
     */
    function endSale() external onlyOwner {
        saleStarted = false;
        emit OnSaleEnd();
    }

    /*==============================
    =      HELPER FUNCTIONS        =
    ==============================*/
    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    /**
     * @dev calculates x*y and outputs a emulated 512bit number as l being the lower 256bit half and h the upper 256bit half.
     */
    function fullMul(uint256 x, uint256 y)
        public
        pure
        returns (uint256 l, uint256 h)
    {
        uint256 mm = mulmod(x, y, uint256(-1));
        l = x * y;
        h = mm - l;
        if (mm < l) h -= 1;
    }

    /**
     * @dev calculates x*y/z taking care of phantom overflows.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 z
    ) public pure returns (uint256) {
        (uint256 l, uint256 h) = fullMul(x, y);
        require(h < z);
        uint256 mm = mulmod(x, y, z);
        if (mm > l) h -= 1;
        l -= mm;
        uint256 pow2 = z & -z;
        z /= pow2;
        l /= pow2;
        l += h * ((-pow2) / pow2 + 1);
        uint256 r = 1;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        r *= 2 - z * r;
        return l * r;
    }
}