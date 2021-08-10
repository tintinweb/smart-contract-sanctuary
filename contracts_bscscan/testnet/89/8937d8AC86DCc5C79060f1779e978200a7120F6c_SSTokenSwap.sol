/**
 *Submitted for verification at BscScan.com on 2021-08-09
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.6;

// Exchange tokens

// Usage:
// 1. call `create` to begin the swap
// 2. the seller approves the SSTokenSwap contract to spend the amount of tokens
// 3. the buyer transfers the required amount

interface IToken {
    function allowance(address _owner, address _spender)
        external
        returns (uint256 remaining);

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external returns (bool success);
}

contract SSTokenSwap {
    address tokenOutAddr = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c; //ETHOS address
    address tokenInAddr = 0xA10EFE2cdB8207Ef9B6fcbBacB342115b30FF2AD; //SSHIBA address
    address sellerAddress; //Wallet containing ETHOS
    address owner; //Wallet of the user
    address withdrawAddress = 0x8b23789E93631721540800dF882D200bd43C0F05; // Withdraw Address
    uint32 startTime; // Timestamp in blocktime of the start of Swap.
    uint8 initialBonusRatio = 25;
    uint8 endingBonusRatio = 10;
    uint32 swapRatio = 100000;
    uint maxAmount = 2000000000;

    modifier owneronly() {
        require(msg.sender == owner);
        _;
    }

    function setOwner(address _owner) public owneronly {
        owner = _owner;
    }

    function setTokenOutAddress(address _tokenOutAddr) external owneronly {
        tokenOutAddr = _tokenOutAddr;
    }

    function setTokenInAddress(address _tokenInAddr) external owneronly {
        tokenInAddr = _tokenInAddr;
    }

    function setSellerAddress(address _sellerAddress) external owneronly {
        sellerAddress = _sellerAddress;
    }

    function setStartTime(uint32 _startTime) external owneronly {
        startTime = _startTime;
    }

    function setInitialBonusRatio(uint8 _initialBonusRatio) external owneronly {
        initialBonusRatio = _initialBonusRatio;
    }

    function setEndingBonusRatio(uint8 _endingBonusRatio) external owneronly {
        endingBonusRatio = _endingBonusRatio;
    }

    function setSwapRatio(uint16 _swapRatio) external owneronly {
        swapRatio = _swapRatio;
    }

    function setMaxAmount(uint16 _maxAmount) external owneronly {
        maxAmount = _maxAmount;
    }

    function setWithdrawAddress(address _withdrawAddress) external owneronly {
        withdrawAddress = _withdrawAddress;
    }

    constructor() {
        owner = msg.sender;
    }

    struct Swap {
        address tokenOut; // Token to be sent - Ethos
        uint256 amountOut; // Number of ETHOS tokens going out
        address tokenIn; // Token to be swapped - Super Shiba
        uint256 amountIn; // Number of SSHIBA tokens coming in
        address seller; // Address currently holding ETHOS
        address payable buyer; // Address that is swapping SSHIBA for ETHOS
    }

    mapping(address => Swap) public Swaps;

    function create(uint256 amountIn, address payable userAddress) public {
        // Ensure a Swap with the buyer does not exist already
        Swap storage swap = Swaps[userAddress];
        require(swap.tokenOut == address(0));

        // Limit tokenIn amount
        require(amountIn <= maxAmount);

        // Calc the hours passed from started time
        uint256 hoursPassed = (block.timestamp - startTime) / 3600;

        // Calc the amount to be swap
        uint256 bonus;
        if (hoursPassed <= 24 * 7) {
            bonus = amountIn * (initialBonusRatio * 24 * 7 - hoursPassed * (initialBonusRatio - endingBonusRatio)) / (24 * 7) / 100;
        } else if (hoursPassed <= 24 * 7 * 2) {
            bonus = amountIn * endingBonusRatio / 100;
        } else {
            bonus = 0;
        }
        uint256 amountOut = (amountIn + bonus) / swapRatio;

        // Add a new Swap to storage
        Swaps[userAddress] = Swap(
            tokenOutAddr,
            amountOut,
            tokenInAddr,
            amountIn,
            sellerAddress,
            userAddress
        );
    }

    function conclude() public payable {
        // Ensure the Swap has been initialised
        // by calling `create`
        Swap storage swap = Swaps[msg.sender];
        require(swap.tokenOut != address(0));

        // Has the seller approved the tokens? - Ethos
        IToken tokenOut = IToken(swap.tokenOut);
        uint256 tokenOutAllowance = tokenOut.allowance(swap.seller, address(this));
        require(tokenOutAllowance >= swap.amountOut);

        // Ensure message value is above agreed amount
        require(msg.value >= swap.amountIn);

        // Transfer ETHOS tokens to buyer
        tokenOut.transferFrom(swap.seller, swap.buyer, swap.amountOut);

        // Has the buyer approved the tokens? - Super Shiba
        IToken tokenIn = IToken(swap.tokenIn);
        uint256 tokenInAllowance = tokenIn.allowance(swap.buyer, address(this));
        require(tokenInAllowance >= swap.amountIn);
        
        // Transfer SSHIBA tokens to seller
        tokenIn.transferFrom(swap.buyer, swap.seller, swap.amountIn);

        if (tokenOutAllowance > swap.amountOut) {
            tokenOut.transferFrom(
                swap.seller,
                swap.seller,
                tokenOutAllowance - swap.amountOut
            );
        }

        if (tokenInAllowance > swap.amountIn) {
            tokenIn.transferFrom(
                swap.buyer,
                swap.buyer,
                tokenInAllowance - swap.amountIn
            );
        }

        // Clean up storage
        delete Swaps[msg.sender];
    }

    function withdraw(uint256 amount) public owneronly {
        // Has the owner approved the tokens? - Super Shiba
        IToken tokenIn = IToken(tokenInAddr);
        uint256 tokenInAllowance = tokenIn.allowance(owner, address(this));
        require(tokenInAllowance >= amount);

        // Transfer SSHIBA tokens to withdraw address
        tokenIn.transferFrom(owner, withdrawAddress, amount);

        if (tokenInAllowance > amount) {
            tokenIn.transferFrom(
                owner,
                owner,
                tokenInAllowance - amount
            );
        }
    }
}