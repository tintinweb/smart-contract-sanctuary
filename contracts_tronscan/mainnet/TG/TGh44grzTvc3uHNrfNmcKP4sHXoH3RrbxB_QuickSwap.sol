//SourceUnit: QuickSwap.sol

/*
    SPDX-License-Identifier: MIT
    A Bankteller Production
    Bankroll Network
    Copyright 2020
*/

pragma solidity ^0.4.25;

contract Token {

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {}

    function transfer(address to, uint256 value) public returns (bool) {}

    function balanceOf(address who) public view returns (uint256) {}

    function allowance(address owner, address spender)
        public
        view
        returns (uint256);

    function approve(address spender, uint256 value) public returns (bool);

}

contract Swap {
    /**
     * @dev Pricing function for converting between TRX && Tokens.
     * @param input_amount Amount of TRX or Tokens being sold.
     * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
     * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
     * @return Amount of TRX or Tokens bought.
     */
    function getInputPrice(
        uint256 input_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) public view returns (uint256);

    /**
     * @dev Pricing function for converting between TRX && Tokens.
     * @param output_amount Amount of TRX or Tokens being bought.
     * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
     * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
     * @return Amount of TRX or Tokens sold.
     */
    function getOutputPrice(
        uint256 output_amount,
        uint256 input_reserve,
        uint256 output_reserve
    ) public view returns (uint256);

    /**
     * @notice Convert TRX to Tokens.
     * @dev User specifies exact input (msg.value) && minimum output.
     * @param min_tokens Minimum Tokens bought.
     * @return Amount of Tokens bought.
     */
    function trxToTokenSwapInput(uint256 min_tokens)
        public
        payable
        returns (uint256);

    /**
     * @notice Convert TRX to Tokens.
     * @dev User specifies maximum input (msg.value) && exact output.
     * @param tokens_bought Amount of tokens bought.
     * @return Amount of TRX sold.
     */
    function trxToTokenSwapOutput(uint256 tokens_bought)
        public
        payable
        returns (uint256);

    /**
     * @notice Convert Tokens to TRX.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_trx Minimum TRX purchased.
     * @return Amount of TRX bought.
     */
    function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx)
        public
        returns (uint256);

    /**
     * @notice Convert Tokens to TRX.
     * @dev User specifies maximum input && exact output.
     * @param trx_bought Amount of TRX purchased.
     * @param max_tokens Maximum Tokens sold.
     * @return Amount of Tokens sold.
     */
    function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens)
        public
        returns (uint256);

    /***********************************|
    |         Getter Functions          |
    |__________________________________*/

    /**
     * @notice Public price function for TRX to Token trades with an exact input.
     * @param trx_sold Amount of TRX sold.
     * @return Amount of Tokens that can be bought with input TRX.
     */
    function getTrxToTokenInputPrice(uint256 trx_sold)
        public
        view
        returns (uint256);

    /**
     * @notice Public price function for TRX to Token trades with an exact output.
     * @param tokens_bought Amount of Tokens bought.
     * @return Amount of TRX needed to buy output Tokens.
     */
    function getTrxToTokenOutputPrice(uint256 tokens_bought)
        public
        view
        returns (uint256);

    /**
     * @notice Public price function for Token to TRX trades with an exact input.
     * @param tokens_sold Amount of Tokens sold.
     * @return Amount of TRX that can be bought with input Tokens.
     */
    function getTokenToTrxInputPrice(uint256 tokens_sold)
        public
        view
        returns (uint256);

    /**
     * @notice Public price function for Token to TRX trades with an exact output.
     * @param trx_bought Amount of output TRX.
     * @return Amount of Tokens needed to buy output TRX.
     */
    function getTokenToTrxOutputPrice(uint256 trx_bought)
        public
        view
        returns (uint256);

    /**
     * @return Address of Token that is sold on this exchange.
     */
    function tokenAddress() public view returns (address);

    function tronBalance() public view returns (uint256);

    function tokenBalance() public view returns (uint256);

    function getTrxToLiquidityInputPrice(uint256 trx_sold)
        public
        view
        returns (uint256);

    function getLiquidityToReserveInputPrice(uint256 amount)
        public
        view
        returns (uint256, uint256);

    function txs(address owner) public view returns (uint256);

    /***********************************|
    |        Liquidity Functions        |
    |__________________________________*/

    /**
     * @notice Deposit TRX && Tokens (token) at current ratio to mint SWAP tokens.
     * @dev min_liquidity does nothing when total SWAP supply is 0.
     * @param min_liquidity Minimum number of SWAP sender will mint if total SWAP supply is greater than 0.
     * @param max_tokens Maximum number of tokens deposited. Deposits max amount if total SWAP supply is 0.
     * @return The amount of SWAP minted.
     */
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens)
        public
        payable
        returns (uint256);

    /**
     * @dev Burn SWAP tokens to withdraw TRX && Tokens at current ratio.
     * @param amount Amount of SWAP burned.
     * @param min_trx Minimum TRX withdrawn.
     * @param min_tokens Minimum Tokens withdrawn.
     * @return The amount of TRX && Tokens withdrawn.
     */
    function removeLiquidity(
        uint256 amount,
        uint256 min_trx,
        uint256 min_tokens
    ) public returns (uint256, uint256);
}

contract TokenMint {
    function mint(address beneficiary, uint256 tokenAmount)
        public
        returns (uint256);

    function mintingDifficulty() public view returns (uint256);

    function estimateMint(uint256 _amount) public returns (uint256);

    function remainingMintableSupply() public returns (uint256);
}

contract QuickSwap {
    
    //BNKR
    address public tokenAddress = address(
        0x418caeea9c7ebb8840ee4b49d10542b99cec6ffbc6
    ); //TNo59Khpq46FGf4sD7XSWYFNfYfbc8CqNK
    
    //BNKRX
    address public bnkrxTokenAddress = address(
        0x4167da83cfc7d0a1894bb52d7fb12ac8f536b0716f
    ); //TKSLNVrDjb7xCiAySZvjXB9SxxVFieZA7C
    
    //Swap
    address public swapAddress = address(
        0x41aaa7d283fa8ff534ca65a5a311e376b63411981a
    ); //TRXYvAoYvCqmvZWpFCTLc4rdQ7KxbLsUSj
    
    //SwapX
    address public swapxAddress = address(
        0x410bf515389a27ba991f09f92cd1bd1b85ad8aade1
    ); //TB4S2pvyX8uQsBPrTDWYCuSDfYSg6tMJm7
    

    Token private bnkrx;
    Token private bnkr;
    Swap private swap;
    Swap private swapx;

    constructor() public {
        
        //BNKR
        bnkr = Token(tokenAddress);
        //BNKRX
        bnkrx= Token(bnkrxTokenAddress);
        
        //BNKR Swap
        swap = Swap(swapAddress);
        //BNKRX Swap
        swapx = Swap(swapxAddress);
    
    }

    /**
     * @dev Fallback function to handle eth that was send straight to the contract
     */
    function() public payable {
        //DO NOTHING!!! Swap will send TRX to us!!!
    }


    //@dev Swap specified BNKR to BNKRX
    function swapBnkr(uint256 _amount) external returns (uint256){

        address _addr = msg.sender; 

        //Check allowance and send BNKRX to the contract; future proof error reporting a little
        require(bnkr.allowance(_addr, address(this)) >= _amount, "Insufficient allowance for contract");

        //This can only fail if the balance is insufficient
        require(
            bnkr.transferFrom(
                _addr,
                address(this),
                _amount
            ),
            "Token to contract transfer failed; check balance"
        );
        
        //Approve Swap to move BNKR and buy
        bnkr.approve(swapAddress, _amount);
        uint256 _trx = swap.tokenToTrxSwapInput(_amount,1);

        //Swap TRX for 
        uint256 _bnkrx = swapx.trxToTokenSwapInput.value(_trx)(1);

        //Transfer BNKR 
        bnkrx.transfer(_addr, _bnkrx);

        return _bnkrx;
    }

    //@dev Get BNKR to BNKRX price 
    function swapBnkrPrice(uint256 _amount) view external returns (uint256) {
        uint256 _trx = swap.getTokenToTrxInputPrice(_amount);
        return swapx.getTrxToTokenInputPrice(_trx);
    }


    //@dev Swap specified BNKRX  to BNKR
    function swapBnkrx(uint256 _amount) external returns (uint256) {

        address _addr = msg.sender; 

        //Check allowance and send BNKRX to the contract; future proof error reporting a little
        require(bnkrx.allowance(_addr, address(this)) >= _amount, "Insufficient allowance for contract");

        //This can only fail if the balance is insufficient
        require(
            bnkrx.transferFrom(
                _addr,
                address(this),
                _amount
            ),
            "Token to contract transfer failed; check balance"
        );
        
        //Approve Swap to move BNKR and buy
        bnkrx.approve(swapxAddress, _amount);
        uint256 _trx = swapx.tokenToTrxSwapInput(_amount,1);

        //Swap TRX for 
        uint256 _bnkr = swap.trxToTokenSwapInput.value(_trx)(1);

        //Transfer BNKR 
        bnkr.transfer(_addr, _bnkr);

        return _bnkr;
    }

    //@dev Get BNKRX to BNKR price
    function swapBnkrxPrice(uint256 _amount) view external returns (uint256) {
        uint256 _trx = swapx.getTokenToTrxInputPrice(_amount);
        return swap.getTrxToTokenInputPrice(_trx);
    }

}