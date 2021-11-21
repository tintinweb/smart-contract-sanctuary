pragma solidity 0.8.6;

//SPDX-License-Identifier: MIT

import "./IERC20.sol";
import "./Ownable.sol";
import "./Context.sol";

/**
 * @dev Token Offering, including token Offering and sale withdrawal:
 *
 */

contract CitizenChatOffering is Context, Ownable {
    bool public isSaleActive;
    bool public isWithdrawalEnabled;
    IERC20 token;
    uint256 public subscriberRate; // tokens per ether
    uint256 public premiumSubscriberRate; // tokens per ether
    uint256 public withdrawalRate; // tokens per ether
    uint256 public raisedAmount; // in wei

    constructor(
        address _token,
        uint256 _subscriberRate,
        uint256 _premiumSubscriberRate
    ) {
        token = IERC20(_token);
        subscriberRate = _subscriberRate;
        premiumSubscriberRate = _premiumSubscriberRate;
        isSaleActive = true;
    }

    modifier activeSale() {
        require(isSaleActive == true, "Sale is over");
        _;
    }

    /**
     * BoughtTokens
     * @dev Log tokens bought on the blockchain
     */
    event BoughtTokens(address indexed buyer, uint256 value);

    /**
     * SoldTokens
     * @dev Log tokens sold on the blockchain
     */
    event SoldTokens(address indexed seller, uint256 value);

    /**
     * buyTokens
     * @dev function that sells owner approved tokens
     */
    function buyTokens(bool isPremium) public payable activeSale {
        uint256 weiAmount = msg.value;
        uint256 rate;

        if (isPremium == true) {
            rate = premiumSubscriberRate;
        } else {
            rate = subscriberRate;
        }

        uint256 tokens = weiAmount * rate;

        emit BoughtTokens(_msgSender(), tokens);

        raisedAmount = raisedAmount + msg.value;

        require(
            token.transferFrom(owner(), _msgSender(), tokens),
            "Sale: TokenTransfer failed"
        );

        payable(owner()).transfer(msg.value);
    }

    /**
     * updateSaleStatus
     * @dev function that starts/ends token sale
     */
    function updateSaleStatus(bool status) public onlyOwner {
        isSaleActive = status;
    }

    /**
     * updateWithdrawal
     * @dev function that enables/disables and sets withdrawal price
     */
    function updateWithdrawal(bool status, uint256 _withdrawalRate)
        public
        onlyOwner
    {
        isWithdrawalEnabled = status;
        withdrawalRate = _withdrawalRate;
    }

    /**
     * setSubscriberRate
     * @dev function that sets subscriberRate
     */
    function setSubscriberRate(uint256 rate) public onlyOwner {
        subscriberRate = rate;
    }

    /**
     * setpremiumSubscriberRate
     * @dev function that sets premiumSubscriberRate
     */
    function setpremiumSubscriberRate(uint256 rate) public onlyOwner {
        premiumSubscriberRate = rate;
    }

    /**
     * withdrawETH
     * @dev function that lets user withdrwa ETH for tokens
     */
    function withdrawETH(uint256 amount) public {
        require(isWithdrawalEnabled == true, "User cannot sell tokens");

        uint256 weiReturn = amount / withdrawalRate;
        payable(_msgSender()).transfer(weiReturn);

        emit SoldTokens(_msgSender(), amount);
        require(token.transferFrom(_msgSender(), owner(), amount));
    }

    /**
     * receive
     * @dev to enable contract to receive ether
     *
     */
    receive() external payable {}

    /**
     * ownerWithdrawEther
     * @dev owner will be able to withdraw any remaining ether
     *
     */
    function ownerWithdrawEther() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(_msgSender()).transfer(balance);
    }
}