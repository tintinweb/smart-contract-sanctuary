//SourceUnit: BankrollFlow.sol

/*
    SPDX-License-Identifier: MIT
    A Bankteller Production
    Bankroll Network
    Copyright 2020
*/


pragma solidity ^0.4.25;

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
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


contract Token {
    function remainingMintableSupply() public view returns (uint256) {}

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool) {}

    function transfer(address to, uint256 value) public returns (bool) {}

    function balanceOf(address who) public view returns (uint256) {}

    function burn(uint256 _value) public {}

    function mintedSupply() public returns (uint256) {}

    function allowance(address owner, address spender)
        public
        view
        returns (uint256);

    function approve(address spender, uint256 value) public returns (bool);
}

contract TokenMint {
    function mint(address beneficiary, uint256 tokenAmount)
        public
        returns (uint256);

    function mintingDifficulty() public view returns (uint256);

    function estimateMint(uint256 _amount) public returns (uint256);

    function remainingMintableSupply() public returns (uint256);
}

contract BankrollFlow is Ownable {

    using SafeMath for uint256;

    struct User {
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint256 deposit_time;
        uint256 total_deposits;
        uint256 total_payouts;
        uint256 total_structure;
    }

    //TokenMint
    address public mintAddress = address(
        0x4194cf54c88551774ace7425879c28454494bdc6a7
    ); //TPY3P5CNW4XdFzqrJEf5ehvfp9Pg2Bjjgz
    
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
    
    //Stronghold
    address public buybackReceiverAddress = address(
        0x41387029ed4f02ab772c7e7c4a9bba93930bd36821
    ); //TF7dD5SYMEZvmUXUt8EcKLYnNk3pE9V5Ls


    TokenMint private tokenMint;
    Token private bnkrToken;
    Token private bnkrxToken;
    Swap private swap;
    Swap private swapx;

    mapping(address => User) public users;

    uint256 constant payoutRate = 1;

    uint8[] public ref_bonuses;                     

    uint256 public buyback_balance;
    uint256 public topoff_balance;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint256 public total_bnkr;
    uint256 public total_txs;
    uint256 public flushSize = 10e6;
    uint256 public minimumAmount = 1e6;

    uint256 constant MAX_UINT = 2**256 - 1;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event Leaderboard(address indexed addr, uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    event Buyback(address addr, uint256 amount);

    constructor() public Ownable(){
        
        //Upline bonuses
        ref_bonuses.push(30);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(10);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(8);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);
        ref_bonuses.push(5);

        //Only the mint should own its paired token
        tokenMint = TokenMint(mintAddress);

        //BNKR
        bnkrToken = Token(tokenAddress);
        //BNKRX
        bnkrxToken = Token(bnkrxTokenAddress);
        
        //BNKR Swap
        swap = Swap(swapAddress);
        //BNKRX Swap
        swapx = Swap(swapxAddress);
    }

    //@dev Default payable is empty since Flow executes trades and recieves TRX
    function() payable external {
        //Do nothing, TRX will be sent to contract when selling tokens
    }

    //@dev Add direct referral and update team structure of upline
    function _setUpline(address _addr, address _upline) internal {
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner )) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            total_users++;

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
    }

    //@dev Deposit and fundbuyback
    function _deposit(address _addr, uint256 _amount) internal {
        //Can't maintain upline referrals without this being set
        require(users[_addr].upline != address(0) || _addr == owner, "No upline");
 
        //stats
        users[_addr].deposit_amount += _amount;
        users[_addr].deposit_time = now;
        users[_addr].total_deposits += _amount;

        total_deposited += _amount;
        
        //events
        emit NewDeposit(_addr, _amount);

        //10% direct commission
        if(users[_addr].upline != address(0)) {
            users[users[_addr].upline].direct_bonus += _amount / 10;

            emit DirectPayout(users[_addr].upline, _addr, _amount / 10);
        }

        //Sell 
        _fundBuyBack(_amount);
        
    }

    //@dev Sell BNKRX and receive TRX; 5% buyback
    function _fundBuyBack(uint256 _amount) internal {
        buyback_balance += _amount * 5 / 100;

        if (buyback_balance > flushSize){
            _sellRewardTokens(buyback_balance);
            buyback_balance = 0;
        }  

        //Buyback BNKR from the sale and send to Stronghold
         total_bnkr += _buyback();
    }

    //Buffer and mint BNKRX as needed to maintain deposits
    function _topOff(uint256 _amount) internal {
        topoff_balance += _amount;

        if (topoff_balance > flushSize){

            //mint, ignoring difficulty to replace distributed tokens
            tokenMint.mint(address(this), topoff_balance * tokenMint.mintingDifficulty());

            //reset balance
            topoff_balance = 0;
        }
    }

    //Payout upline; Bonuses are from 5 - 30% on the 1% paid out daily; Referrals only help 
    function _refPayout(address _addr, uint256 _amount) internal {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount * ref_bonuses[i] / 100;
                
                users[up].match_bonus += bonus;

                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }

    //@dev Deposit specified BNKRX amount supplying an upline referral
    function deposit(address _upline, uint256 _amount) external {

        address _addr = msg.sender; 

        require(_amount >= minimumAmount, "Minimum deposit of 1 BNKRX");
        _setUpline(_addr, _upline);

        //Transfer BNKRX to the contract
        require(
            bnkrxToken.transferFrom(
                _addr,
                address(this),
                _amount
            ),
            "BNKRX token transfer failed"
        );
        _deposit(_addr, _amount);

        emit Leaderboard(_addr, users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
        total_txs++;
    }

    //@dev Claim, transfer, and topoff
    function claim() external {

        address _addr = msg.sender; 

        uint256 to_payout = _claim();

        //Deliver earned BNKRX
        bnkrxToken.transfer(msg.sender, to_payout);

        //we replace anything we transfer out
        _topOff(to_payout);

        emit Leaderboard(_addr, users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
        total_txs++;
    }

    //@dev Claim and deposit; Flow is lazy about minting tokens and will only mint to match withdrawals 
    function roll() external {
        address _addr = msg.sender; 

        uint256 to_payout = _claim();
        _deposit(_addr, to_payout);

        emit Leaderboard(_addr, users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
        total_txs++;
    }


    //@dev Claim current payouts
    function _claim() internal returns (uint256) {
        (uint256 to_payout, uint256 max_payout) = this.payoutOf(msg.sender);
        
        require(users[msg.sender].payouts < max_payout, "Full payouts");

        // Deposit payout
        if(to_payout > 0) {
            if(users[msg.sender].payouts + to_payout > max_payout) {
                to_payout = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].deposit_payouts += to_payout;
            users[msg.sender].payouts += to_payout;

            //Payout referrals
            _refPayout(msg.sender, to_payout);
        }
        
        // Direct payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].direct_bonus > 0) {
            uint256 direct_bonus = users[msg.sender].direct_bonus;

            if(users[msg.sender].payouts + direct_bonus > max_payout) {
                direct_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].direct_bonus -= direct_bonus;
            users[msg.sender].payouts += direct_bonus;
            to_payout += direct_bonus;
        }

        // Match payout
        if(users[msg.sender].payouts < max_payout && users[msg.sender].match_bonus > 0) {
            uint256 match_bonus = users[msg.sender].match_bonus;

            if(users[msg.sender].payouts + match_bonus > max_payout) {
                match_bonus = max_payout - users[msg.sender].payouts;
            }

            users[msg.sender].match_bonus -= match_bonus;
            users[msg.sender].payouts += match_bonus;
            to_payout += match_bonus;
        }

        require(to_payout > 0, "Zero payout");
        
        //Update the payouts
        users[msg.sender].total_payouts += to_payout;
        total_withdraw += to_payout;

        //Update time!   
        users[msg.sender].deposit_time = now;

        //Sell 5% of BNKRX movement outbound
        _fundBuyBack(to_payout);

        emit Withdraw(msg.sender, to_payout);

        if(users[msg.sender].payouts >= max_payout) {
            emit LimitReached(msg.sender, users[msg.sender].payouts);
        }

        return to_payout;
    }

    //@dev Approve BNKRX to move to SwapX
    function _approveRewardSwap() internal {
        require(
            bnkrxToken.approve(swapxAddress, MAX_UINT),
            "Need to approve swap before selling reward tokens"
        );
    }

    //@dev Sell minted BNKRX for TRX
    function _sellRewardTokens(uint256 amount) internal returns (uint256) {
        _approveRewardSwap();
        return swapx.tokenToTrxSwapInput(amount, 1);
    }

    //@dev Use contract TRX to buy BNKR
    function _buyback() internal returns (uint256) {
        uint256 balance = address(this).balance;
        if (balance > flushSize) {
            uint256 _bought_tokens = swap.trxToTokenSwapInput.value(balance)(1);
            bnkrToken.transfer(buybackReceiverAddress, _bought_tokens);

            emit Buyback(buybackReceiverAddress, _bought_tokens);
            return _bought_tokens;
        }

        return 0;
    }
    
    //@dev Maxpayout of 3.65 of deposit
    function maxPayoutOf(uint256 _amount) pure external returns(uint256) {
        return _amount * 365 / 100;
    }

    //@dev Calculate the current payout and maxpayout of a given address
    function payoutOf(address _addr) view external returns(uint256 payout, uint256 max_payout) {
        max_payout = this.maxPayoutOf(users[_addr].deposit_amount);

        if(users[_addr].deposit_payouts < max_payout) {
            uint256 share = users[_addr].deposit_amount.mul(payoutRate).div(100).div(24 hours); //divide the profit by payout rate and seconds in the day
            payout = share * now.safeSub(users[_addr].deposit_time);
            
            if(users[_addr].deposit_payouts + payout > max_payout) {
                payout = max_payout - users[_addr].deposit_payouts;
            }
        }
    }

    //@dev Get current user snapshot 
    function userInfo(address _addr) view external returns(address upline, uint256 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].match_bonus);
    }

    //@dev Get user totals
    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].total_payouts, users[_addr].total_structure);
    }

    //@dev Get contract snapshot
    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 _total_bnkr,  uint256 _total_txs) {
        return (total_users, total_deposited, total_withdraw,  total_bnkr,  total_txs);
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
    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
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