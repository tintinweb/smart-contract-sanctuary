// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "./SafeMath.sol";
import "./Math.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";

import "./ido.sol";

interface IStaking {
    function stake(uint256 _amount, address _recipient) external returns (bool);

    function claim(address _recipient) external;
}

contract IDO is IIDO, Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    //start of Private Sale
    uint256 public startOfSale;

    //start of Public Sale
    uint256 public startOfPublicSale;

    // Assumes a reserve token with 18 decimals MIM
    address public immutable override reserve =
        0xc6672Fc5be39CEdb6a9992d7Ae76b0bBfD2B72E4;
    address public staking;

    // Amount (in wei) that can be purchased during the public sale
//    uint256 public immutable publicSaleAmount;
    // Total amount of native tokens for purchase
    uint256 public immutable override totalAmount;
    // Reserve (in wei) per 1e9 native IE 100*1e18 is 100 reserve for 1 native

    uint256 public privateSalePrice;
    uint256 public publicSalePrice;

    address public immutable alphaToken = 0x7B2856E20afbD5d86F7f78050D9ceA116B6524F9;

    uint256 public override amountRemaining;
    // Total number of addresses in the whitelist
    uint256 public totalWhiteListed;
    uint256 public claimedAmount;
    uint256 public numBuyers;
    uint256 public maxLimitPerBuyer;
    uint256 public maxLimitPerPublicBuyer;

    bool public initialized;
    bool public whiteListEnabled;
    bool public cancelled;
    bool public finalized;
    bool public saleClosed;

    mapping(address => bool) public bought;
    mapping(address => bool) public whiteListed;

    address[] public buyers;
    mapping(address => uint256) public purchasedAmounts;

    constructor(
        uint256 totalAmount_,
        uint256 privateSalePrice_,
        uint256 maxLimitPerBuyer_
    ) {

        totalAmount = totalAmount_;
        amountRemaining = totalAmount_;
        privateSalePrice = privateSalePrice_;
        maxLimitPerBuyer = maxLimitPerBuyer_;

//        IERC20(alphaToken).approve(owner(), totalAmount);
    }

    /// @dev Only Emergency Use
    /// cancel the IDO and return the funds to all buyers
    function cancel() external onlyOwner {
        require(!saleClosed);
        cancelled = true;
    }

    function whiteListBuyers(address[] memory buyers_)
        external
        onlyOwner
        returns (bool)
    {
        require(!saleStarted(), "Already started");

        totalWhiteListed = totalWhiteListed.add(buyers_.length);

        for (uint256 i = 0; i < buyers_.length; i++) {
            whiteListed[buyers_[i]] = true;
        }

        return true;
    }

    // onlyFinalizer

    function finalize() external override onlyOwner {
        require(saleClosed, "Sale must be closed");
        require(!finalized, "Already finalized");
        finalized = true;

/*        require(
            IERC20(native).balanceOf(address(this)) ==
                (totalAmount - amountRemaining),
            "Did not receive the correct number of native tokens"
        );*/
    }

    function closeSale() external override onlyOwner {
        closeSaleRequirements();
        require(!saleClosed, "Sale already closed");
        saleClosed = true;

        IERC20(reserve).safeTransfer(
            msg.sender,
            IERC20(reserve).balanceOf(address(this))
        );
    }

    // public or external view

    function saleStarted() public view returns (bool) {
        return initialized;
    }

    function getAllotmentPerBuyer() public view returns (uint256) {
        /*        if (whiteListEnabled) {
            return amountRemaining.div(totalWhiteListed);
        } else {
            return Math.min(publicSaleAmount, amountRemaining);
        }*/
        if (whiteListEnabled) {
            return maxLimitPerBuyer;
        } else {
            return maxLimitPerPublicBuyer;
        }
    }

    function setWhitelistBuyLimit(uint256 limitPerBuyer) external onlyOwner {
        maxLimitPerPublicBuyer = limitPerBuyer;
    }

    function setPublicBuyLimit(uint256 limitPerBuyer) external onlyOwner {
        maxLimitPerPublicBuyer = limitPerBuyer;
    }

    function setWhitelistPrice(uint256 whiteSalePrice) external onlyOwner {
        privateSalePrice = whiteSalePrice;
    }

    function setPublicPrice(uint256 publicSalePrice_) external onlyOwner {
        publicSalePrice = publicSalePrice_;
    }

    function setStakingAddress(address stakingAddress_) external onlyOwner {
        staking = stakingAddress_;
    }

    function calculateSaleQuote(uint256 paymentAmount_)
        external
        view
        returns (uint256)
    {
        return _calculateSaleQuote(paymentAmount_);
    }

    // public or external

    // Start the private sale
    function startPrivateSale() external onlyOwner {
        require(startOfSale == 0, "Cannot start sale yet");
        startOfSale = block.timestamp;
        cancelled = false;
        finalized = false;
        initialized = true;
        whiteListEnabled = true;
    }

    // Start the public sale
    function disableWhiteList() external {
        require(
            block.timestamp >= (startOfSale),
            "Cannot start public sale yet"
        );
        whiteListEnabled = false;
        startOfPublicSale = block.timestamp;
    }

    function purchase(uint256 amount) external returns (bool) {
        require(saleStarted(), "Not started");
        require(!saleClosed, "Sale is closed");
        require(
            !whiteListEnabled || whiteListed[msg.sender],
            "Not whitelisted"
        );
        require(!bought[msg.sender], "Already participated");
        require(amount > 0, "Amount must be > 0");
        uint256 purchaseAmount = _calculateSaleQuote(amount);
        require(purchaseAmount <= getAllotmentPerBuyer(), "More than allotted");

        bought[msg.sender] = true;

        if (whiteListEnabled) {
            totalWhiteListed = totalWhiteListed.sub(1);
        }

        amountRemaining = amountRemaining.sub(purchaseAmount);

        purchasedAmounts[msg.sender] = purchaseAmount;

        IERC20(alphaToken).safeTransferFrom(owner(), msg.sender, purchaseAmount);

        buyers.push(msg.sender);
        numBuyers = buyers.length;

        IERC20(reserve).safeTransferFrom(msg.sender, address(this), amount);

        return true;
    }

    // internal view

    function _calculateSaleQuote(uint256 paymentAmount_)
        internal
        view
        returns (uint256)
    {
        return uint256(1e9).mul(paymentAmount_).div(salePrice());
    }

    function salePrice() public view override returns (uint256) {
        if (startOfPublicSale > 0) return publicSalePrice;
        else return privateSalePrice;
    }

    function closeSaleRequirements() internal view {
        require(startOfPublicSale > 0, "Public sale not started");
    }

    // internal

    function approveIfNeeded(
        address token,
        address spender,
        uint256 amount
    ) internal {
        if (IERC20(token).allowance(address(this), spender) < amount) {
            assert(IERC20(token).approve(spender, amount));
        }
    }
}