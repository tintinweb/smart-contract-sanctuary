//SourceUnit: Reactor-v2.sol

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


contract Reactor {

    using SafeMath for uint;
    
    //BNKRX
    address public bnkrxTokenAddress = address(
        0x4167da83cfc7d0a1894bb52d7fb12ac8f536b0716f
    ); //TKSLNVrDjb7xCiAySZvjXB9SxxVFieZA7C
    
    //SwapX
    address public swapxAddress = address(
        0x410bf515389a27ba991f09f92cd1bd1b85ad8aade1
    ); //TB4S2pvyX8uQsBPrTDWYCuSDfYSg6tMJm7


    uint256 private constant trxBuffer = 1000e6;
    uint256 public lastSweep;
  
    Token private bnkrx;
    Swap private swapx;


    constructor() public {

        //BNKRX
        bnkrx = Token(bnkrxTokenAddress);
        
        //BNKRX Swap
        swapx = Swap(swapxAddress);

        lastSweep = now;
    }

    /**
     * @dev Fallback function to handle eth that was send straight to the contract
     */
    function() public payable {
        //DO NOTHING!!! We collect TRX and a sweep will distribute it
    }


    //@dev Sweep excess, 1% to locked BNKRX liquidity
    function  sweep() public returns (uint256) {
        //balance at the contract is dripped back to swapx
        uint256 _balance = address(this).balance;

        //Calculate daily drip 1%
        uint256 _share = _balance.mul(1).div(100).div(24 hours); //divide the profit by seconds in the day
        uint256 _payout = _share * now.safeSub(lastSweep);  //share times the amount of time elapsed

        
        //Do we have enough value to play with?
        if (_payout > trxBuffer){
        
            uint256 _trx = _payout; 

            //Buy BNKRX with half TRX
            uint256 _halfTrx = _trx.sub(_trx.div(2)); 
            uint256 _bnkrx = swapx.trxToTokenSwapInput.value(_halfTrx)(1);

            //Approve BNKRX movement
            bnkrx.approve(swapxAddress, _bnkrx);

             //the secret sauce for adding liquidity properly
            _trx = SafeMath.min(swapx.getTokenToTrxInputPrice(_bnkrx), _trx);

            //Add BNKRX liquidity and harden the price
            uint256 liquidAmount = swapx.addLiquidity.value(_trx)(1, _bnkrx);

            lastSweep = now;

            return liquidAmount;

        }

        return 0;
        
    }

    //@dev Return the trx equivalent balance 
    function trxBalance() public view returns (uint256){
        return address(this).balance;
    }

}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /* @dev Subtracts two numbers, else returns zero */
    function safeSub(uint a, uint b) internal pure returns (uint) {
        if (b > a) {
            return 0;
        } else {
            return a - b;
        }
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}