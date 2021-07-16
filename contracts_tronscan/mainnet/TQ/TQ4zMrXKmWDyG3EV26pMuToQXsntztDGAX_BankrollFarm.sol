//SourceUnit: Farm.sol

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


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


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

// File: openzeppelin-solidity/contracts/ownership/Whitelist.sol

/**
 * @title Whitelist
 * @dev The Whitelist contract has a whitelist of addresses, and provides basic authorization control functions.
 * @dev This simplifies the implementation of "user permissions".
 */
contract Whitelist is Ownable {
    mapping(address => bool) public whitelist;

    event WhitelistedAddressAdded(address addr);
    event WhitelistedAddressRemoved(address addr);

    /**
     * @dev Throws if called by any account that's not whitelisted.
     */
    modifier onlyWhitelisted() {
        require(whitelist[msg.sender]);
        _;
    }

    /**
     * @dev add an address to the whitelist
     * @param addr address
     * @return true if the address was added to the whitelist, false if the address was already in the whitelist
     */
    function addAddressToWhitelist(address addr) onlyOwner public returns(bool success) {
        if (!whitelist[addr]) {
            whitelist[addr] = true;
            emit WhitelistedAddressAdded(addr);
            success = true;
        }
    }

    /**
     * @dev add addresses to the whitelist
     * @param addrs addresses
     * @return true if at least one address was added to the whitelist,
     * false if all addresses were already in the whitelist
     */
    function addAddressesToWhitelist(address[] addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (addAddressToWhitelist(addrs[i])) {
                success = true;
            }
        }
    }

    /**
     * @dev remove an address from the whitelist
     * @param addr address
     * @return true if the address was removed from the whitelist,
     * false if the address wasn't in the whitelist in the first place
     */
    function removeAddressFromWhitelist(address addr) onlyOwner public returns(bool success) {
        if (whitelist[addr]) {
            whitelist[addr] = false;
            emit WhitelistedAddressRemoved(addr);
            success = true;
        }
    }

    /**
     * @dev remove addresses from the whitelist
     * @param addrs addresses
     * @return true if at least one address was removed from the whitelist,
     * false if all addresses weren't in the whitelist in the first place
     */
    function removeAddressesFromWhitelist(address[] addrs) onlyOwner public returns(bool success) {
        for (uint256 i = 0; i < addrs.length; i++) {
            if (removeAddressFromWhitelist(addrs[i])) {
                success = true;
            }
        }
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
    function getInputPrice(uint256 input_amount, uint256 input_reserve, uint256 output_reserve) public view returns (uint256);

    /**
      * @dev Pricing function for converting between TRX && Tokens.
      * @param output_amount Amount of TRX or Tokens being bought.
      * @param input_reserve Amount of TRX or Tokens (input type) in exchange reserves.
      * @param output_reserve Amount of TRX or Tokens (output type) in exchange reserves.
      * @return Amount of TRX or Tokens sold.
      */
    function getOutputPrice(uint256 output_amount, uint256 input_reserve, uint256 output_reserve) public view returns (uint256);
    /**
     * @notice Convert TRX to Tokens.
     * @dev User specifies exact input (msg.value) && minimum output.
     * @param min_tokens Minimum Tokens bought.
     * @return Amount of Tokens bought.
     */
    function trxToTokenSwapInput(uint256 min_tokens) public payable returns (uint256);

    /**
     * @notice Convert TRX to Tokens.
     * @dev User specifies maximum input (msg.value) && exact output.
     * @param tokens_bought Amount of tokens bought.
     * @return Amount of TRX sold.
     */
    function trxToTokenSwapOutput(uint256 tokens_bought) public payable returns (uint256);

    /**
     * @notice Convert Tokens to TRX.
     * @dev User specifies exact input && minimum output.
     * @param tokens_sold Amount of Tokens sold.
     * @param min_trx Minimum TRX purchased.
     * @return Amount of TRX bought.
     */
    function tokenToTrxSwapInput(uint256 tokens_sold, uint256 min_trx) public returns (uint256);

    /**
     * @notice Convert Tokens to TRX.
     * @dev User specifies maximum input && exact output.
     * @param trx_bought Amount of TRX purchased.
     * @param max_tokens Maximum Tokens sold.
     * @return Amount of Tokens sold.
     */
    function tokenToTrxSwapOutput(uint256 trx_bought, uint256 max_tokens) public returns (uint256);

    /***********************************|
    |         Getter Functions          |
    |__________________________________*/

    /**
     * @notice Public price function for TRX to Token trades with an exact input.
     * @param trx_sold Amount of TRX sold.
     * @return Amount of Tokens that can be bought with input TRX.
     */
    function getTrxToTokenInputPrice(uint256 trx_sold) public view returns (uint256);

    /**
     * @notice Public price function for TRX to Token trades with an exact output.
     * @param tokens_bought Amount of Tokens bought.
     * @return Amount of TRX needed to buy output Tokens.
     */
    function getTrxToTokenOutputPrice(uint256 tokens_bought) public view returns (uint256);

    /**
     * @notice Public price function for Token to TRX trades with an exact input.
     * @param tokens_sold Amount of Tokens sold.
     * @return Amount of TRX that can be bought with input Tokens.
     */
    function getTokenToTrxInputPrice(uint256 tokens_sold) public view returns (uint256);

    /**
     * @notice Public price function for Token to TRX trades with an exact output.
     * @param trx_bought Amount of output TRX.
     * @return Amount of Tokens needed to buy output TRX.
     */
    function getTokenToTrxOutputPrice(uint256 trx_bought) public view returns (uint256) ;

    /**
     * @return Address of Token that is sold on this exchange.
     */
    function tokenAddress() public view returns (address) ;


    function tronBalance() public view returns (uint256);

    function tokenBalance() public view returns (uint256);

    function getTrxToLiquidityInputPrice(uint256 trx_sold) public view returns (uint256);

    function getLiquidityToReserveInputPrice(uint amount) public view returns (uint256, uint256);

    function txs(address owner) public view returns (uint256) ;


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
    function addLiquidity(uint256 min_liquidity, uint256 max_tokens) public payable returns (uint256) ;

    /**
     * @dev Burn SWAP tokens to withdraw TRX && Tokens at current ratio.
     * @param amount Amount of SWAP burned.
     * @param min_trx Minimum TRX withdrawn.
     * @param min_tokens Minimum Tokens withdrawn.
     * @return The amount of TRX && Tokens withdrawn.
     */
    function removeLiquidity(uint256 amount, uint256 min_trx, uint256 min_tokens) public returns (uint256, uint256);
}

contract Exchange {
    function getTrxToTokenInputPrice(uint256 trx_sold) external view returns (uint256);
    function getTokenToTrxInputPrice(uint256 tokens_sold) external view returns (uint256);
}



contract Token {
    function remainingMintableSupply() public view returns (uint256) {}
    function transferFrom(address from, address to, uint256 value) public returns (bool){}
    function transfer(address to, uint256 value) public returns (bool){}
    function balanceOf(address who) public view returns (uint256){}
    function burn(uint256 _value) public {}
    function mintedSupply() public returns (uint256) {}
    function allowance(address owner, address spender) public view returns (uint256);
    function approve(address spender, uint256 value) public returns (bool);
}


contract TokenMint {
    function mint(address beneficiary, uint256 tokenAmount) public returns (uint256){}
    function sponsorFor(address _sender, address _beneficiary) public payable {}
    function mintingDifficulty() public view returns (uint256) {}
    function estimateMint(uint256 _amount) public returns (uint256){}
}

contract BankrollFarm is Whitelist {

    using Address for address;
    using SafeMath for uint;

    /**
    * No bloody contracts
    *
    */
    modifier isHuman {
        //No contracts
        require(msg.sender == tx.origin && !msg.sender.isContract());
        _;
    }


    struct Stats {
        uint balance; //current BNKR balance
        uint counterBalance; //current balance off farmable token
        uint totalMinted; //total minted BNKR
        uint totalDeposited; //total ever deposited TRON
        uint totalWithdrawn; //total withdrawn
        uint totalReferral; //total referrals
        uint lastUpdated; //last tx time used for calculating minted BNKR
        uint xMinted; //times claim has been called
        uint xDeposited; //times a deposit has been made
        uint xWithdrawn; //times a withdrawal was made
    }

    event onClose(
        uint256 closed
    );

    event onFreeze(
        address indexed customerAddress,
        uint256 tron
    );

    event onUnfreeze(
        address indexed customerAddress,
        uint256 tron
    );

    event onClaim(
        address indexed customerAddress,
        uint256 bnkr
    );

    event onBalance(
        address indexed customerAddress,
        uint256 tronBalance,
        uint256 bnkrMinted
    );

    event onContractBalance(
        uint256 balance
    );


    mapping(address => Stats) internal stats;
    address public mintAddress = address(0x413b155e2c501254567913a1d15e2fab4b9abea6aa); //TFMcU3QBGVB5ghtYw8g9wMV3rTFdkH2avv
    address public tokenAddress = address(0x418caeea9c7ebb8840ee4b49d10542b99cec6ffbc6); //TNo59Khpq46FGf4sD7XSWYFNfYfbc8CqNK
    address public swapAddress = address(0x41aaa7d283fa8ff534ca65a5a311e376b63411981a); //TRXYvAoYvCqmvZWpFCTLc4rdQ7KxbLsUSj
    address public wtrxAddress = address(0x41891cdb91d149f23b1a45d9c5ca78a88d0cb44c18); //TNUC9Qb1rRpS5CbWLmNMxXBjyFoydXjWFR
    address public counterAddress;
    address public exchangeAddress;
    TokenMint private tokenMint;
    Token private token;
    Token private counterToken;
    Exchange private exchange;
    Swap private swap;

    uint256 public totalMinted;
    uint256 public totalDeposits;
    uint256 public totalTxs;
    uint256 public players;
    uint256 public closed = 0;
    uint256 public launched;

    

    uint256 internal lastBalance_;

    uint256 internal balanceIncrement_ = 50e6;
    uint256 internal trackingInterval_ = 6 hours;
    uint256 internal bonusPeriod = 24 hours * 365;

    /**
    * @dev 
    * @param _counterAddress The address of the TRC20 to stake vs BNKR
    * @param _exchangeAddress The Justswap pair contract used as a  price oracle
    */
    constructor(address _counterAddress, address _exchangeAddress) Ownable() public {

       
        counterAddress = _counterAddress;
        exchangeAddress = _exchangeAddress;

        //Only the mint should own its paired token
        tokenMint = TokenMint(mintAddress);
        token = Token(tokenAddress);
        swap = Swap(swapAddress);
        counterToken = Token(counterAddress);
        exchange = Exchange(exchangeAddress);

        //add creator to whitelist
        addAddressToWhitelist(msg.sender);

        launched = now;

    }

    // @dev Stake counter and base tokens with counter amount as input; base is calculated
    function freeze(address referrer, uint _counterAmount) public {

        //If closed then don't accept new funds
        if (closed > 0){
            return;
        }

        //No double spend
        claim(referrer);

        //Got to be able to mint
        require(isOpen(), "Mint is closed");

        address _customerAddress = msg.sender;

        require(_counterAmount > 0, "Deposit zero");
        require(counterToken.transferFrom(_customerAddress, address(this), _counterAmount), "Counter token transfer failed");
        uint _baseAmount = counterToBaseAmount(_counterAmount);

        //As long as we have the balance lets go for it
        require(_baseAmount <= token.balanceOf(_customerAddress), "Base amount required > balance");
        require(token.transferFrom(_customerAddress, address(this), _baseAmount), "Base token transfer failed");

        //Count players
        if (stats[_customerAddress].totalDeposited == 0 ){
            players += 1;
        }

        uint trxValue = counterToTrx(_counterAmount) * 2;
        //Increase the amount staked
        stats[_customerAddress].balance += _baseAmount;
        stats[_customerAddress].counterBalance += _counterAmount;
        stats[_customerAddress].lastUpdated = now;
        stats[_customerAddress].xDeposited += 1;
        stats[_customerAddress].totalDeposited += trxValue;

        totalDeposits += trxValue;
        totalTxs += 1;


        emit onFreeze(_customerAddress, trxValue);
    }

    // @dev Unfreeze staked tokens
    function unfreeze(address referrer) public  {

        //No double spend
        claim(referrer);

        address _customerAddress = msg.sender;

        uint balance = stats[_customerAddress].balance;
        uint counterBalance = stats[_customerAddress].counterBalance;
        uint trxValue = counterToTrx(counterBalance) + baseToTrx(balance);
        
        //Lets always update time on any modification
        stats[_customerAddress].balance = 0;
        stats[_customerAddress].counterBalance = 0;
        stats[_customerAddress].lastUpdated = now;
        stats[_customerAddress].xWithdrawn += 1;
        stats[_customerAddress].totalWithdrawn += trxValue;

        totalTxs += 1;

        //Transfer the coins, thank you
        token.transfer(_customerAddress, balance);
        counterToken.transfer(_customerAddress, counterBalance);

        emit onUnfreeze(_customerAddress, trxValue);

    }

    // @dev Claim available base tokens
    function claim(address referrer) public {

        //No work to do, just return and this is pause aware
        //Pause only impacts a user after they claim after the pause
        if (availableMint() == 0){
            return;
        }

        if (now.safeSub(lastBalance_) > trackingInterval_) {
            emit onContractBalance(totalTronBalance());
            lastBalance_ = now;
        }

        address _customerAddress = msg.sender;


        //This has already been validated with availableMint
        //If we are here _stakeAmount will be greater than zero
        uint _stakeAmount = availableStake();

        //Minimum of 50 deposited to receive a referral; 5% referral
        if (referrer != address(0) && referrer != _customerAddress && stats[referrer].balance >= balanceIncrement_){
            uint _referrerMinted = tokenMint.mint(referrer,  _stakeAmount / 10);
            stats[referrer].totalReferral += _referrerMinted;
            totalMinted += _referrerMinted;
            emit onClaim(referrer, _referrerMinted);
        }

        //Update stats; time is updated only
        uint _minted = tokenMint.mint(_customerAddress,  _stakeAmount);
        stats[_customerAddress].lastUpdated = now;
        stats[_customerAddress].xMinted += 1;
        stats[_customerAddress].totalMinted += _minted;
        totalMinted += _minted;

        //Mint to the customer directly
        uint _ownerMinted = tokenMint.mint(owner,  _stakeAmount);
        stats[owner].totalReferral += _ownerMinted;
        totalMinted += _ownerMinted;
        emit onClaim(owner, _ownerMinted);

        totalTxs += 1;

        emit onClaim(_customerAddress, _minted);
        emit onBalance(_customerAddress, balanceOf(_customerAddress), stats[_customerAddress].totalMinted);
    }

    //@dev Sanity check to assure we have adequate balance of base tokens and allowance based on counter token amount
    function  baseAvailable(uint _counterAmount) public view returns (bool){
        address _customerAddress = msg.sender;

        uint _baseAmount = counterToBaseAmount(_counterAmount);

        //As long as we have the balance lets go for it
        return _baseAmount <= token.balanceOf(_customerAddress) && _baseAmount <= token.allowance(_customerAddress, address(this));
    }

    // @dev Calculate base tokens based on the counter token using both price oracles from Swap / Justswap
    function counterToBaseAmount(uint _amount) public view returns (uint){
        if (_amount > 0) {
            uint _trxValue = 0;
            if (counterAddress != wtrxAddress){
                _trxValue = exchange.getTokenToTrxInputPrice(_amount);
            } else {
                _trxValue = _amount;
            }
            return swap.getTrxToTokenInputPrice(_trxValue); 
        } else {
            return 0;
        }
    }

    // @dev Return the amount of TR based on price from JustSwap exchange
    function counterToTrx(uint _amount) public view returns (uint){
        if (counterAddress != wtrxAddress){
            return (_amount > 0) ? exchange.getTokenToTrxInputPrice(_amount) : 0;
        } else {
            return _amount;
        }
    }

    // @dev Return the amount of TRX based on price from Swap
    function baseToTrx(uint _amount) public view returns (uint){
        return (_amount > 0) ? swap.getTokenToTrxInputPrice(_amount) : 0;
    }

    // @dev Return estimate to mint based on available stake and minter
    function availableMint() public view returns (uint256){

        return tokenMint.estimateMint(availableStake());

    }

    // @dev Return available stake that can be used against the minter based on time
    function availableStake() public view returns (uint256){
        address _customerAddress = msg.sender;

        //Use simple balance for sanity checking
        uint balance = stats[_customerAddress].balance;

        //lastUpdated should always be greater than zero, but for safety we'll check
        if (balance == 0 || stats[_customerAddress].lastUpdated == 0){
            return 0;
        }

        //If closed and a claim has happened since
        if (closed > 0){
            if (stats[_customerAddress].lastUpdated > closed){
                return 0;
            }
        }

        //Grab the calculate full TRX balance
        balance = balanceOf(_customerAddress);

        uint lapsed = now.safeSub(stats[_customerAddress].lastUpdated);

        //Daily staked amount times the bonus factor
        uint _stakeAmount  = balance.div(86400) * lapsed * bonusFactor();

        //We are done
        return _stakeAmount;

    }

    // @dev Return estimate of daily returns based on calculate TRX balance
    function dailyEstimate(address _customerAddress) public view returns (uint256){

        //Use simple balance for sanity checking
        uint balance = stats[_customerAddress].balance;

        //lastUpdated should always be greater than zero, but for safety we'll check
        if (balance == 0 || stats[_customerAddress].lastUpdated == 0){
            return 0;
        }

        //Grab the calculate full TRX balance
        balance = balanceOf(_customerAddress);

        return tokenMint.estimateMint(balance * bonusFactor());

    }

    // @dev Returns the calculated TRX balance based on swap/exchange price oracles
    function balanceOf(address _customerAddress) public view returns (uint256){
        return counterToTrx(stats[_customerAddress].counterBalance) + baseToTrx(stats[_customerAddress].balance);
    }

    // @dev Returns the base tokens for a customer
    function balanceOfBase(address _customerAddress) public view returns (uint256){
        return stats[_customerAddress].balance;
    }

    // @dev Returns the balance of the counter tokens for  customer
    function balanceOfCounter(address _customerAddress) public view returns (uint256){
        return stats[_customerAddress].counterBalance;
    }

    // @dev Returns the total referral income for a given customer
    function totalReferralOf(address _customerAddress) public view returns (uint256) {
        return stats[_customerAddress].totalReferral;
    }

    //@dev Returns the total number of coins minted for a given customer
    function totalMintedOf(address _customerAddress) public view returns (uint256) {
        return stats[_customerAddress].totalMinted;
    }

    // @dev Returns tx count across deposts, withdraws, and claims
    function txsOf(address _customerAddress) public view returns (uint256){
        Stats stat = stats[_customerAddress];
        return stat.xDeposited + stat.xWithdrawn + stat.xMinted;
    }

    // @dev Returns bulk stats for a given customer
    function statsOf(address _customerAddress) public view returns (uint, uint, uint, uint,uint, uint, uint, uint, uint, uint,uint) {

        Stats stat = stats[_customerAddress];

        return
        (stat.balance,
        stat.totalDeposited,
        stat.totalWithdrawn,
        stat.totalMinted,
        stat.totalReferral,
        stat.lastUpdated,
        stat.xDeposited,
        stat.xWithdrawn,
        stat.xMinted,
        stat.xDeposited + stat.xWithdrawn + stat.xMinted,
        stat.counterBalance);
    }

    // @dev Returns true when balance and lastUpdate are positive and pat the current block time
    function ready() public view returns (bool){
        //Requirements: non zero balance, lapsed time
        return stats[msg.sender].balance > 0 && now.safeSub(stats[msg.sender].lastUpdated) > 0 && stats[msg.sender].lastUpdated > 0;
    }

    // @dev Returns true if the base token can still be mined
    function isOpen() public view returns (bool){
        return token.remainingMintableSupply() > 0;
    }

    // @dev Returns the last time the user interacted with the contract
    function lastUpdated() public view returns (uint){
        return stats[msg.sender].lastUpdated;
    }

    // @dev Graceful step for 10 down to 1 over the bonusperiod 
    function bonusFactor() public view returns (uint){
        uint elapsed = now.safeSub(launched);
        return  1 + bonusPeriod.safeSub(elapsed).mul(10).div(bonusPeriod);
    }

    /**
     * @dev Method to view the current tron stored in the contract as calculated from price oracles
     *  Example: totaltronBalance()
     */
    function totalTronBalance() public view returns (uint256) {
        return counterToTrx(counterBalance()) + baseToTrx(baseBalance());
    }

    //@dev Returns the daily estimate based on the total contract balance and bonusfactor
    function totalDailyEstimate() public view returns (uint){
        return tokenMint.estimateMint(totalTronBalance() * bonusFactor());
    }

    //@dev Returns the total balance of base tokens in the contract
    function baseBalance() public view returns (uint) {
        return token.balanceOf(address(this));
    }

    //@dev Returns the total balance of all counter tokens in the contract
    function counterBalance() public view returns (uint){
        return counterToken.balanceOf(address(this));
    }

    /* Admin functions */

    //@dev Closes a pool.  Once a pool is closed a user can claim one last time and then withdraw funds  
    function close() onlyWhitelisted public returns (uint){
        if (closed == 0){
            closed = now;
            emit onClose(closed);
        }

        return closed;
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

/**
 * Utility library of inline functions on addresses
 */
library Address {
    /**
     * Returns whether the target address is a contract
     * @dev This function will return false if invoked during the constructor of a contract,
     * as the code is not actually created until after the constructor finishes.
     * @param account address of the account to check
     * @return whether the target address is a contract
     */
    function isContract(address account) internal view returns (bool) {
        uint size;
        // XXX Currently there is no better way to check if there is a contract in an address
        // than to check the size of the code at that address.
        // See https://ethereum.stackexchange.com/a/14016/36603
        // for more details about how this works.
        // TODO Check this again before the Serenity release, because all addresses will be
        // contracts then.
        // solhint-disable-next-line no-inline-assembly
        assembly {size := extcodesize(account)}
        return size > 0;
    }
}