pragma solidity ^0.7.4;
// "SPDX-License-Identifier: Apache License 2.0"

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./iVotingEscrow.sol";
/**
 * @title BlankCrowdsale contract.
 */


contract PolarisCrowdsale is Ownable,ReentrancyGuard {
    using SafeMath for uint256;

    IERC20  public saleToken;
    IERC20  public paymentToken;
    uint256 public paymentPrice1;
    uint256 public paymentPrice2;
    uint256 public paymentPrice3;
    uint256 public unlockTime1;
    uint256 public unlockTime2;
    uint256 public unlockTime3;
    uint256 public maxSellQty = 1e21;  //1000 tokens
    uint256 constant public SALE_TOKEN_PARTS = 1e18;
    mapping(address => bool) internal whiteList;
    address public finance;
    iVotingEscrow lockContract;

    event Buy(uint256 amount, uint256 price, address buyer);

    constructor(
        address _lockContract,
        address _saleToken,
        address _paymentToken,
        address[] memory _whiteAddresses,
        uint256 _maxSellQty,
        uint256 _paymentPrice1,
        uint256 _paymentPrice2,
        uint256 _paymentPrice3,
        uint256 _unlockTime1,
        uint256 _unlockTime2,
        uint256 _unlockTime3
        )
    {
        finance=msg.sender;
        saleToken = IERC20(_saleToken);
        paymentToken = IERC20(_paymentToken);
        maxSellQty = _maxSellQty;
        paymentPrice1 = _paymentPrice1;
        paymentPrice2 = _paymentPrice2;
        paymentPrice3 = _paymentPrice3;
        lockContract = iVotingEscrow(_lockContract);
        unlockTime1 = _unlockTime1;
        unlockTime2 = _unlockTime2;
        unlockTime3 = _unlockTime3;
        for (uint256 i = 0; i < _whiteAddresses.length; i++) {
            whiteList[_whiteAddresses[i]] = true;
        }
    }

    function isWhiteListed(address _buyer) external view returns(bool){
        return whiteList[_buyer];
    }

    function addToWhiteList(address _newBuyer) external onlyOwner {
        whiteList[_newBuyer] = true;
    }

    function addToWhiteList(address[] calldata _newBuyers) external onlyOwner {
        for (uint256 i = 0; i < _newBuyers.length; i++) {
            whiteList[_newBuyers[i]]=true;
        }     
    }

    function available() public view returns(uint256){
        return saleToken.balanceOf(address(this));
    }

    /**
     * @notice Set DAO finance.
     * @param financeAddr The DAO finance's address.
     */
    function setFinance(address financeAddr) external onlyOwner {
        finance = financeAddr;
    }

    function withdrawSaleToken(uint256 amount) external onlyOwner {
        require(amount>0 && amount<=available(),"amount is incorrect!");
        saleToken.transfer(address(msg.sender), amount);
    }

    /**
     * @notice Buy sell token all options.
     */
    function buy(uint256 _payment, uint8 _sellOption) external nonReentrant {
        require(whiteList[msg.sender],"is not available for this account");
        uint256 payment = _payment;

        uint256 paymentPrice_ = paymentPrice1;
        uint256 unlockTime_ = unlockTime1;

        if(_sellOption == uint8(2)) {
            paymentPrice_ = paymentPrice2;
            unlockTime_ = unlockTime2;
        } 
        
        if(_sellOption == uint8(3)) {
            paymentPrice_ = paymentPrice3;
            unlockTime_ = unlockTime3;
        }

        uint256 sellAmount = payment.mul(SALE_TOKEN_PARTS).div(paymentPrice_);
        require(maxSellQty >= sellAmount, "Amount exceeds maximum sell for address");

        uint256 balance = saleToken.balanceOf(address(this));
        require(balance > 0, "No tokens to sale");
        
        if (balance < sellAmount) {
            sellAmount=balance;
            payment=sellAmount.mul(paymentPrice_).div(SALE_TOKEN_PARTS);
        }

        require(
            paymentToken.allowance(msg.sender, address(this)) >=
                payment, "Increase the allowance first"
        );
        paymentToken.transferFrom(
            address(msg.sender),
            finance,
            payment
        );

        saleToken.transfer(address(lockContract), sellAmount);
        lockContract.create_lock_for_origin(sellAmount, unlockTime_);

        emit Buy(sellAmount, payment, msg.sender);
    }

}