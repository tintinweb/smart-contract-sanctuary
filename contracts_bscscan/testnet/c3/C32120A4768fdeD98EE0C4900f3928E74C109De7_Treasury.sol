// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

/*
 * ApeSwapFinance
 * App:             https://apeswap.finance
 * Medium:          https://ape-swap.medium.com/
 * Twitter:         https://twitter.com/ape_swap
 * Telegram:        https://t.me/ape_swap
 * Announcements:   https://t.me/ape_swap_news
 * GitHub:          https://github.com/ApeSwapFinance
 */

import "IERC20.sol";
import "SafeERC20.sol";
import "Ownable.sol";

/**
 * The Treasury contract holds GoldenBanana that can be bought with BANANA and later
 *  be redeemed for BANANA.
 *
 * To buy a GoldenBanana, a portion of the BANANA used will be burned in the process,
 *  while the remaining BANANA will be locked in the contract to be unlocked at any
 *  future time.
 */
contract Treasury is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    address constant burnAddress = address(0x000000000000000000000000000000000000dEaD);

    // The TOKEN to buy
    IERC20 public banana;
    // The TOKEN to sell
    IERC20 public goldenBanana;
    // adminAddress
    address public adminAddress;
    // buyFee, if decimal is not 18, please reset it
    uint256 public buyFee = 2857; // 28.57% or 0.2857 Banana
    // maxBuyFee, if decimal is not 18, please reset it
    uint256 public maxBuyFee = 6000; // 60% or 0.6 Banana

    // =================================

    event Buy(address indexed user, uint256 amount);
    event Sell(address indexed user, uint256 amount);
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event EmergencyWithdraw(address indexed receiver, uint256 amount);
    event UpdateBuyFee(uint256 previousBuyFee, uint256 newBuyFee);

    constructor(
        IERC20 _banana,
        IERC20 _goldenBanana
    ) public {
        banana = _banana;
        goldenBanana = _goldenBanana;
        adminAddress = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "admin: wut?");
        _;
    }

    bool private unlocked = true;
    modifier lock() {
        require(unlocked == true, 'ApeSwap: LOCKED');
        unlocked = false;
        _;
        unlocked = true;
    }

    /// @dev Buy Golden Banana with Banana. A potion of the Banana will be burned in the process.
    /// @param _amount Amount of Golden Banana to sell
    function buy(uint256 _amount) external lock {
        banana.safeTransferFrom(address(msg.sender), address(this), _amount);
        uint256 bananaToBurn = _amount.mul(buyFee).div(10000);
        uint256 goldenBananaToSend = _amount.sub(bananaToBurn);
        goldenBanana.transfer(address(msg.sender), goldenBananaToSend);
        _burnBananas(bananaToBurn);
        emit Buy(msg.sender, _amount);
    }

    /// @dev Sell Golden Banana to redeem for Banana
    /// @param _amount Amount of Golden Banana to sell
    function sell(uint256 _amount) external lock {
        uint256 preGoldenBananaReserves = goldenBananaReserves();
        goldenBanana.safeTransferFrom(address(msg.sender), address(this), _amount);
        // Because the Golden Banana is a reflect token, we need to find how much
        //  was transferred AFTER the reflect fee.
        uint256 amountIn = goldenBananaReserves().sub(preGoldenBananaReserves);
        banana.transfer(address(msg.sender), amountIn);
        emit Sell(msg.sender, _amount);
    }

    /// @dev Burns Banana by sending them to the burn address
    /// @param _amount Amount of Banana to burn
    function _burnBananas(uint256 _amount) internal {
        banana.transfer(burnAddress, _amount);
    }

    /// @dev Obtain the amount of Banana held by this contract
    function bananaReserves() public view returns (uint256) {
        return banana.balanceOf(address(this));
    }

    /// @dev Obtain the amount of Golden Banana held by this contract
    function goldenBananaReserves() public view returns (uint256) {
        return goldenBanana.balanceOf(address(this));
    }

    /* Owner Functions */

    /// @dev Use the owner address to update the admin
    function setAdmin(address _adminAddress) external onlyOwner {
        address previousAdmin = adminAddress;
        adminAddress = _adminAddress;
        emit AdminTransferred(previousAdmin, adminAddress);
    }

    /// @dev Incase of a problem with the treasury contract, the Golden Banana can be removed
    ///  and sent to a new treasury contract
    function emergencyWithdraw(uint256 _amount) external onlyOwner {
        goldenBanana.transferFrom(address(this), address(msg.sender), _amount);
        emit EmergencyWithdraw(msg.sender, _amount);
    }

    /* Admin Functions */

    /// @dev Set the fee that will be used to burn Banana on purchases
    /// @param _fee The fee used for burning. 10000 = 100%
    function setBuyFee(uint256 _fee) external onlyAdmin {
        require(_fee <= maxBuyFee, 'fee must be mess than maxBuyFee');
        uint256 previousBuyFee = buyFee;
        buyFee = _fee;
        emit UpdateBuyFee(previousBuyFee, buyFee);
    }
}