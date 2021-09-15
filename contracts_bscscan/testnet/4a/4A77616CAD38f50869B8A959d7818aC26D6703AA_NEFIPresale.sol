// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

// extensions
import "./ReentrancyGuard.sol";
import "./Ownable.sol";

// utils
import "./SafeERC20.sol";
import "./SafeMath.sol";

contract NEFIPresale is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    IERC20 public nefi;
    IERC20 public busd;

    bool public isPreSale = false;
    bool public isClaimPreSale = false;

    uint256 public nefiPerUsd = 40;
    uint256 constant MIN_STAKE_BUSD = 50 * 1e18;
    uint256 constant MAX_STAKE_BUSD = 500 * 1e18;

    uint256 remainNEFIQuota = 11650485 * 1e18;

    mapping(address => uint256) buyerAmount;
    mapping(address => bool) buyerReferralAdded;
    mapping(address => uint256) referralAmount;

    event LogEnablePreSale(bool status);
    event LogEnableClaimPreSale(bool status);
    event LogClaimBuyer(address buyer, uint256 neifAmount, uint256 datetime);
    event LogClaimReferral(
        address referral,
        uint256 neifAmount,
        uint256 datetime
    );
    event LogAddReferral(
        address buyer,
        address referral,
        uint256 nefiAmount,
        uint256 datetime
    );
    event LogRejectReferral(
        address buyer,
        address referral,
        uint256 nefiAmount,
        uint256 datetime
    );
    event LogBuyWithBUSD(
        address buyer,
        uint256 amountInBUSD,
        uint256 updatedRemainNEFIQuota,
        uint256 datetime
    );

    constructor(IERC20 _nefi, IERC20 _busd) {
        require(
            address(_busd) != address(0) && address(_nefi) != address(0),
            "zero address in constructor"
        );
        busd = _busd;
        nefi = _nefi;
    }

    modifier onlyBuyer() {
        require(buyerAmount[msg.sender] > 0, "Only buyer");
        _;
    }

    modifier onlyReferral() {
        require(referralAmount[msg.sender] > 0, "Only referral");
        _;
    }

    function buyWithBUSD(uint256 amount) external nonReentrant {
        require(
            isPreSale == true && isClaimPreSale == false,
            "Not Open Pre Sale"
        );
        require(
            amount >= MIN_STAKE_BUSD && amount <= MAX_STAKE_BUSD,
            "amount required >= 50 BUSD && <= 500 BUSD"
        );
        require(buyerAmount[msg.sender] == 0, "Limit 1 transation per address");
        require(amount <= busd.balanceOf(msg.sender), "BUSD is not enough");

        uint256 nefiToReceived = amount.mul(nefiPerUsd);
        require(nefiToReceived <= remainNEFIQuota, "over max sale amount");
        remainNEFIQuota = remainNEFIQuota.sub(nefiToReceived);
        buyerAmount[msg.sender] = nefiToReceived;

        busd.safeTransferFrom(msg.sender, address(this), amount);
        emit LogBuyWithBUSD(
            msg.sender,
            amount,
            remainNEFIQuota,
            block.timestamp
        );
    }

    function claimFromBuyer() external onlyBuyer {
        require(isClaimPreSale == true, "Not open claim yet");
        uint256 amount = buyerAmount[msg.sender];
        buyerAmount[msg.sender] = 0;

        nefi.safeTransfer(msg.sender, amount);
        emit LogClaimBuyer(msg.sender, amount, block.timestamp);
    }

    function claimFromReferral() external onlyReferral {
        require(isClaimPreSale == true, "Not open claim yet");
        uint256 amount = referralAmount[msg.sender];
        referralAmount[msg.sender] = 0;

        nefi.safeTransfer(msg.sender, amount);
        emit LogClaimReferral(msg.sender, amount, block.timestamp);
    }

    /**
    /// @dev must add referral before cliam start
     */
    function addReferral(address buyerAddress, address referralAddress)
        external
        onlyOwner
    {
        require(referralAddress != address(0), "Invalid referral address");
        require(buyerAddress != address(0), "Invalid buyer address");
        require(
            buyerReferralAdded[buyerAddress] == false,
            "Has duplicated buyer"
        );
        buyerReferralAdded[buyerAddress] = true;
        uint256 nefiAmount = uint256(3).mul(buyerAmount[buyerAddress]).div(100);
        referralAmount[referralAddress] = referralAmount[referralAddress].add(
            nefiAmount
        );

        emit LogAddReferral(
            buyerAddress,
            referralAddress,
            nefiAmount,
            block.timestamp
        );
    }

    function rejectReferral(address buyerAddress, address referralAddress)
        external
        onlyOwner
    {
        require(referralAddress != address(0), "Invalid referral address");
        require(buyerAddress != address(0), "Invalid buyer address");
        require(
            buyerReferralAdded[buyerAddress] == true,
            "Has duplicated buyer"
        );
        buyerReferralAdded[buyerAddress] = false;
        uint256 nefiAmount = uint256(3).mul(buyerAmount[buyerAddress]).div(100);
        referralAmount[referralAddress] = referralAmount[referralAddress].sub(
            nefiAmount
        );

        emit LogRejectReferral(
            buyerAddress,
            referralAddress,
            nefiAmount,
            block.timestamp
        );
    }

    function withdrawBUSD(uint256 amount) external onlyOwner {
        busd.safeTransfer(msg.sender, amount);
    }

    function withdrawNEFI(uint256 amount) external onlyOwner {
        nefi.safeTransfer(msg.sender, amount);
    }

    function setEnablePreSale(bool state) external onlyOwner {
        isPreSale = state;
        emit LogEnablePreSale(isPreSale);
    }

    function setEnableClaimPreSale(bool state) external onlyOwner {
        isClaimPreSale = state;
        emit LogEnableClaimPreSale(isClaimPreSale);
    }

    function isEnablePresale() external view returns (bool) {
        return isPreSale;
    }

    function isEnableClaimPreSale() external view returns (bool) {
        return isClaimPreSale;
    }

    function amountOfBuyer() external view returns (uint256) {
        return buyerAmount[msg.sender];
    }

    function amountOfReferral() external view returns (uint256) {
        return referralAmount[msg.sender];
    }

    function balanceRemainNEFIQuota() external view returns (uint256) {
        return remainNEFIQuota;
    }

    function balanceOfNefi() external view returns (uint256) {
        return nefi.balanceOf(address(this));
    }

    function balanceOfBusd() external view returns (uint256) {
        return busd.balanceOf(address(this));
    }
}