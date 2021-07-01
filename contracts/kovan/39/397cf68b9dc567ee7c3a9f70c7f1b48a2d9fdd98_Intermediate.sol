// SPDX-License-Identifier: No License (None)
pragma solidity ^0.8.0;

import "./TransferHelper.sol";
import "./Ownable.sol";


interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface ISmartSwap {
    function isSystem(address caller) external returns(bool);   // check if caller is system wallet.
    function decimals(address token) external returns(uint256);   // token address => token decimals
    function processingFee() external returns(uint256); // Processing fee
    function swap(
        address tokenA,
        address tokenB, 
        address receiver,
        uint256 amountA,
        address licensee,
        bool isInvestment,
        uint128 minimumAmountToClaim,   // do not claim on user behalf less of this amount. Only exception if order fulfilled.
        uint128 limitPice   // Do not match user if token A price less this limit
    )
        external
        payable
        returns (bool);

    function cancel(
        address tokenA,
        address tokenB, 
        address receiver,
        uint256 amountA    //amount of tokenA to cancel
    )
        external
        payable
        returns (bool);

    function claimTokenBehalf(
        address tokenA, // foreignToken
        address tokenB, // nativeToken
        address sender,
        address receiver,
        bool isInvestment,
        uint128 amountA,    //amount of tokenA that has to be swapped
        uint128 currentRate,     // rate with 18 decimals: tokenA price / tokenB price
        uint256 foreignBalance  // total tokens amount sent by user to pair on other chain
    )   
        external
        returns (bool);
/*
    // add liquidity to counterparty 
    function addLiquidityAndClaimBehalf(
        address tokenA, // Native token
        address tokenB, // Foreign token
        address receiver,
        bool isInvestment,
        uint128 amountA,    //amount of tokenA that has to be swapped
        uint128 currentRate,     // rate with 18 decimals: tokenB price / tokenA price
        uint256 foreignBalance,  // total tokens amount sent by user to pair on other chain
        address senderCounterparty,
        address receiverCounterparty
    )
        external
        payable
        returns (bool);
*/
}

contract Intermediate is Ownable {
    struct Tokens {
        address nativeToken;
        address foreignToken;
        uint8 nativeDecimals;
        uint8 foreignDecimals;        
    }
    Tokens public tokensData;
    address public nativeTokenReceiver;
    address public foreignTokenReceiver;
    //uint256 public feeAmount;  // amount of processing fee that should be transferred to system wallet

    ISmartSwap public smartSwap; // assign SmartSwap address here
    uint256 public companyFee = 0; // the fee (in percent wih 2 decimals) that received by company. 30 - means 0.3%

    //mapping(address => bool) public isSystem;  // system address mey change fee amount

    //event SetSystem(address indexed system, bool active);
    event FeeTransfer(address indexed systemWallet, uint256 fee);


    constructor (
        address _nativeToken, // native token that will be send to SmartSwap
        address _foreignToken, // foreign token that has to be received from SmartSwap (on foreign chain)
        address _nativeTokenReceiver, // address on Binance to deposit native token
        address _foreignTokenReceiver // address on Binance to deposit foreign token
    )
    {
        require(
            _nativeToken != address(0)
            && _foreignToken != address(0)
            && _nativeTokenReceiver != address(0)
            && _foreignTokenReceiver != address(0)
        );
        tokensData.nativeToken = _nativeToken;
        tokensData.foreignToken = _foreignToken;
        nativeTokenReceiver = _nativeTokenReceiver;
        foreignTokenReceiver = _foreignTokenReceiver;
    }

    receive() external payable {

    }

    /**
    * @dev Throws if called by any account other than the system.
    */
    modifier onlySystem() {
        require(smartSwap.isSystem(msg.sender), "Caller is not the system");
        _;
    }

    //the fee (in percent wih 2 decimals) that received by company. 30 - means 0.3%
    function setCompanyFee(uint256 _fee) external onlyOwner returns(bool) {
        require(_fee < 10000, "too big fee");    // fee should be less then 100%
        companyFee = _fee;
        return true;
    }

    function setSmartSwap(address _smartSwap) external onlyOwner {
        require(_smartSwap != address(0));
        smartSwap = ISmartSwap(_smartSwap);
        tokensData.nativeDecimals = uint8(smartSwap.decimals(tokensData.nativeToken));
        tokensData.foreignDecimals = uint8(smartSwap.decimals(tokensData.foreignToken));
    }

    function cancel(uint256 amount) external onlySystem {
        smartSwap.cancel(tokensData.nativeToken, tokensData.foreignToken, foreignTokenReceiver, amount);
    }
/*
    function swap(uint256 amount) external onlySystem {
        smartSwap.swap(nativeToken, foreignToken, foreignTokenReceiver, amount, address(0), false)
    }
*/
    function withdraw(uint256 amount) external onlyOwner {
        if (tokensData.nativeToken < address(9))
            TransferHelper.safeTransferETH(nativeTokenReceiver, amount);
        else
            TransferHelper.safeTransfer(tokensData.nativeToken, nativeTokenReceiver, amount);
    }


    // add liquidity to counterparty 
    function addLiquidityAndClaimBehalf(
        uint128 amount,    //amount of native token that has to be swapped (amount of provided liquidity)
        uint128 currentRate,     // rate with 18 decimals: tokenB price / tokenA price
        uint128[] memory claimAmount, // claim amount (in foreign tokens).
        uint256[] memory foreignBalance,  // total tokens amount sent by user to pair on other chain
        address[] memory senderCounterparty, // correspondent value from SwapRequest event
        address[] memory receiverCounterparty    // correspondent value from SwapRequest event
    ) 
        external 
        onlySystem 
    {
        Tokens memory t = tokensData;
        //uint256 decimalsConverter =  10**(18+t.foreignDecimals-t.nativeDecimals);

        require(claimAmount.length == foreignBalance.length &&
            senderCounterparty.length == receiverCounterparty.length &&
            foreignBalance.length == senderCounterparty.length,
            "Wrong length"
        );
        //payable(msg.sender).transfer(feeAmount);
        //emit FeeTransfer(msg.sender, feeAmount);
        if (t.nativeToken > address(9)) {
            uint256 fee = smartSwap.processingFee();
            // add company fee
            IERC20(t.nativeToken).approve(address(smartSwap), uint256(amount));
            smartSwap.swap{value: fee}(
                t.nativeToken, 
                t.foreignToken,
                foreignTokenReceiver, 
                amount, 
                address(0),
                false, 
                0,
                0
            );            
        } else {    // native coin (ETH, BNB)
            uint256 fee = uint256(amount)*companyFee/10000; // 0.3%
            smartSwap.swap{value: uint256(amount) + fee}(
                t.nativeToken, 
                t.foreignToken,
                foreignTokenReceiver, 
                amount, 
                address(0),
                false, 
                0,
                0
            );
        }
        uint256 sum;
        for (uint256 i=0; i<claimAmount.length; i++) {
            sum += claimAmount[i];
            smartSwap.claimTokenBehalf(
                t.foreignToken,
                t.nativeToken,
                senderCounterparty[i],
                receiverCounterparty[i],
                false,
                //uint128(claimAmount[i] * decimalsConverter / currentRate),
                claimAmount[i],
                currentRate, 
                foreignBalance[i]
            );
        }
        require(sum * currentRate / (10**(18+t.foreignDecimals-t.nativeDecimals)) <= uint256(amount), "Insuficiant amount");
    }

}