/**
 *Submitted for verification at BscScan.com on 2021-07-29
*/

// SPDX-License-Identifier: No License (None)
pragma solidity ^0.8.0;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface ISmartSwap {
    function isSystem(address caller) external returns(bool);   // check if caller is system wallet.
    function decimals(address token) external returns(uint256);   // token address => token decimals
    function processingFee() external returns(uint256); // Processing fee
    function companyFee() external returns(uint256); // Company fee
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
}

contract SPImplementation{
    struct Tokens {
        address nativeToken;
        address foreignToken;
        uint8 nativeDecimals;
        uint8 foreignDecimals;        
    }
    Tokens public tokensData;
    address public nativeTokenReceiver;
    address public foreignTokenReceiver;
    address public owner;

    ISmartSwap public smartSwap; // assign SmartSwap address here
    uint256 private feeAmountLimit; // limit of amount that System withdraw for fee reimbursement
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event FeeTransfer(address indexed systemWallet, uint256 fee);
    event Deposit(uint256 value);

    // run only once from proxy
    function initialize(
        address _owner,     // contract owner
        address _nativeToken, // native token that will be send to SmartSwap
        address _foreignToken, // foreign token that has to be received from SmartSwap (on foreign chain)
        address _nativeTokenReceiver, // address on Binance to deposit native token
        address _foreignTokenReceiver, // address on Binance to deposit foreign token
        uint256 _feeAmountLimit // limit of amount that System may withdraw for fee reimbursement
    )
        external
    {
        require(owner == address(0)); // run only once
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
        feeAmountLimit = _feeAmountLimit;
        smartSwap = ISmartSwap(msg.sender);
        tokensData.nativeDecimals = uint8(smartSwap.decimals(tokensData.nativeToken));
        tokensData.foreignDecimals = uint8(smartSwap.decimals(tokensData.foreignToken));
        owner = _owner;
        emit OwnershipTransferred(address(0), _owner);
    }

    receive() external payable {
        emit Deposit(msg.value);
    }

    /**
    * @dev Throws if called by any account other than the system.
    */
    modifier onlySystem() {
        require(smartSwap.isSystem(msg.sender), "Caller is not the system");
        _;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    // set limit of amount that System withdraw for fee reimbursement
    function setFeeAmountLimit(uint256 amount) external onlyOwner {
        feeAmountLimit = amount;
    }

    // get limit of amount that System withdraw for fee reimbursement
    function getFeeAmountLimit() external view returns(uint256) {
        return feeAmountLimit;
    }

    function cancel(uint256 amount) external onlySystem {
        smartSwap.cancel(tokensData.nativeToken, tokensData.foreignToken, foreignTokenReceiver, amount);
    }

    // Allow owner withdraw tokens from contract
    function withdraw(address token, uint256 amount) external onlyOwner {
        if (token < address(9))
            safeTransferETH(msg.sender, amount);
        else
            safeTransfer(token, msg.sender, amount);
    }



    // add liquidity to counterparty 
    function addLiquidityAndClaimBehalf(
        uint128 amount,    //amount of native token that has to be swapped (amount of provided liquidity)
        uint128 currentRate,     // rate with 18 decimals: tokenB price / tokenA price
        uint128[] memory claimAmount, // claim amount (in foreign tokens).
        uint256[] memory foreignBalance,  // total tokens amount sent by user to pair on other chain
        address[] memory senderCounterparty, // correspondent value from SwapRequest event
        address[] memory receiverCounterparty,    // correspondent value from SwapRequest event
        uint256 feeAmount   // processing fee amount to reimburse system wallet.
    ) 
        external 
        onlySystem 
    {
        require(feeAmountLimit >= feeAmount, "Fee limit exceeded");
        feeAmountLimit -= feeAmount;
        Tokens memory t = tokensData;
        require(claimAmount.length == foreignBalance.length &&
            senderCounterparty.length == receiverCounterparty.length &&
            foreignBalance.length == senderCounterparty.length,
            "Wrong length"
        );
        
        {
        uint256 processingFee = smartSwap.processingFee();
        if (t.nativeToken > address(9)) {
            // can't get company fee amount
            IERC20(t.nativeToken).approve(address(smartSwap), uint256(amount));
            smartSwap.swap{value: processingFee}(
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
            processingFee = uint256(amount)*smartSwap.companyFee()/10000 + processingFee;
            smartSwap.swap{value: uint256(amount) + processingFee}(
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
        require(processingFee <= feeAmount, "Insuficiant fee");
        feeAmount -= processingFee; // we already paid processing fee to SmartSwap contract
        if (feeAmount != 0) {
            payable(msg.sender).transfer(feeAmount);
            emit FeeTransfer(msg.sender, feeAmount);
        }        
        }
        {
        feeAmount = 0;  // reuse variable to avoid `Stack too deep` issue
        for (uint256 i = 0; i < claimAmount.length; i++) {
            feeAmount += claimAmount[i];
            smartSwap.claimTokenBehalf(
                t.foreignToken,
                t.nativeToken,
                senderCounterparty[i],
                receiverCounterparty[i],
                false,
                claimAmount[i],
                currentRate, 
                foreignBalance[i]
            );
        }
        require(feeAmount * currentRate / (10**(18+t.foreignDecimals-t.nativeDecimals)) <= uint256(amount), "Insuficiant amount");
        }
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TRANSFER_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'ETH_TRANSFER_FAILED');
    }
}