pragma solidity ^0.7.4;
// "SPDX-License-Identifier: Apache License 2.0"

import "./IERC20.sol";
import "./SafeMath.sol";
import "./Ownable.sol";
import "./SafeERC20.sol";
import "./ReentrancyGuard.sol";
import "./iVotingEscrow.sol";
/**
 * @title BlankCrowdsale contract.
 */


contract PolarisCrowdsale is Ownable,ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

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

    function isWhiteListed(address _buyer) external view returns(bool) {
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
        saleToken.safeTransfer(address(msg.sender), amount);
    }

    /**
     * @notice Buy sell token all options.
     */
    function buy(uint256 paymentTokenAmount, uint8 sellOption) external nonReentrant {
        uint256 paymentPrice = paymentPrice1;
        uint256 unlockTime = unlockTime1;

        if(sellOption == 2) {
            paymentPrice = paymentPrice2;
            unlockTime = unlockTime2;
        } else if(sellOption == 3) {
            paymentPrice = paymentPrice3;
            unlockTime = unlockTime3;
        }

        require(whiteList[msg.sender],"is not available for this account");

        uint256 sellAmount = paymentTokenAmount.mul(SALE_TOKEN_PARTS).div(paymentPrice);
        require(maxSellQty >= sellAmount, "Amount exceeds maximum sell for address");

        uint256 balance = saleToken.balanceOf(address(this));

        if (balance < sellAmount) {
            sellAmount=balance;
            paymentTokenAmount=sellAmount.mul(paymentPrice).div(SALE_TOKEN_PARTS);
        }

        require(
            paymentToken.allowance(msg.sender, address(this)) >=
                paymentTokenAmount, "Increase the allowance first"
        );
        paymentToken.safeTransferFrom(
            address(msg.sender),
            finance,
            paymentTokenAmount
        );

        saleToken.safeTransfer(address(lockContract), sellAmount);
        lockContract.create_lock_for_origin(sellAmount, unlockTime);

        emit Buy(sellAmount, paymentTokenAmount, msg.sender);
    }

}