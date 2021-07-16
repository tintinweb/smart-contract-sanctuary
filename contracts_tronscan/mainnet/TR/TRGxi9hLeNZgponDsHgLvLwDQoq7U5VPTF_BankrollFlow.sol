//SourceUnit: BankrollFlow-v1-2-0.sol

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
    function remainingMintableSupply() public view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public returns (bool);

    function transfer(address to, uint256 value) public returns (bool);

    function balanceOf(address who) public view returns (uint256);

    function mintedSupply() public returns (uint256);

    function allowance(address owner, address spender)
        public
        view
        returns (uint256);

    function approve(address spender, uint256 value) public returns (bool);
}

contract FlowSource {
    //@dev Get user totals
    function userInfoTotals(address _addr) public view  returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure);
    function maxPayoutOf(uint256 _amount) external pure  returns(uint256);
}

contract AirdropSource {
    //@dev Get current user snapshot 
    function userInfo(address _addr) external  view  returns(uint256 _airdrops, uint256 _received, uint256 last_airdrop);
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
        //Referral Info
        address upline;
        uint256 referrals;
        uint256 total_structure;

        //Long-term Referral Accounting
        uint256 direct_bonus;
        uint256 match_bonus;

        //Deposit Accounting 
        uint256 deposits;
        uint256 deposit_time;

        //Payout and Roll Accounting 
        uint256 payouts;  
        uint256 rolls;

        //Upline Round Robin tracking
        uint256 ref_claim_pos;      
    }

    struct Airdrop {
        //Airdrop tracking
        uint256 airdrops;
        uint256 airdrops_received;
        uint256 last_airdrop; 
    }

    struct Migration {
        //Migration
        uint256 migrated;
        address destination;
    }

    struct Custody {

        address manager;
        address beneficiary;
        uint256 last_heartbeat;
        uint256 last_checkin;
        uint256 heartbeat_interval;
    }

    //Previous Flow
    address public flowSourceAddress = address(
        0x41c7b4c4e226f231bb4f46c4160b5ff85faffc168c
    ); //TUBA2HhtN7xxEZ8mYwAk26kNEfwKVcSJNS

    //Airdrop Source
    address public airdropSourceAddress = address(
        0x41e7a3fdcaa433a439ccb28a0acfc84fada18c5565
    ); //TX61Yh6pBCQRRDTHj68Yo2JtSk1kL3NEnu

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

    //Reactor
    address public reactorAddress = address(
        0x41469a279570dddab5c7aef3c1ca61c30fcb13ddf2
    ); //TGQWyLZtmirMF2bPvtzwgVRb6ktQEMrrwe (new)


    FlowSource private flowSource;
    AirdropSource private airdropSource;

    TokenMint private tokenMint;
    Token private bnkrToken;
    Token private bnkrxToken;
    Swap private swap;
    Swap private swapx;

    mapping(address => User) public users;
    mapping(address => Migration) public migrations;
    mapping(address => Airdrop) public airdrops;
    mapping(address => Custody) public custody;

    uint256 private constant payoutRate = 1;
    uint256 private constant ref_depth = 15;
    uint256 private constant ref_bonus = 10; 
    uint256 private constant negativeFee = 10;
    uint256 private constant minimumInitial = 10e6;
    uint256 private constant minimumAmount = 1e6;
    uint256 private constant deposit_bracket_size = 1e12; //1M
    uint256 private constant max_payout_cap = 10e12; //10M BNKRX
    uint256 private constant deposit_bracket_max = 10; // sustainability fee is (bracket * 5)

    uint256[] public ref_balances;                   

    uint256 public buyback_balance;
    uint256 public topoff_balance;

    uint256 public total_airdrops; 
    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint256 public total_trx;
    uint256 public total_txs;
    uint256 public flushSize = 10e6;
    bool public launched = false;
    

    uint256 public constant MAX_UINT = 2**256 - 1;
    
    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event Leaderboard(address indexed addr, uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event Migrate(address indexed _src, address indexed _dest, uint256 _deposits, uint256 _payouts);
    event BalanceTransfer(address indexed _src, address indexed _dest, uint256 _deposits, uint256 _payouts);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    event Buyback(address addr, uint256 amount);
    event NewAirdrop(address indexed from, address indexed to, uint256 amount, uint256 timestamp);
    event ManagerUpdate(address indexed addr, address indexed manager, uint256 timestamp);
    event BeneficiaryUpdate(address indexed addr, address indexed beneficiary);
    event HeartBeatIntervalUpdate(address indexed addr, uint256 interval);
    event HeartBeat(address indexed addr, uint256 timestamp);
    event Checkin(address indexed addr, uint256 timestamp);
    event UpdateFlushSize(uint256 size);



    constructor() public Ownable() {
      
        //Migration contracts
        flowSource = FlowSource(flowSourceAddress);
        airdropSource = AirdropSource(airdropSourceAddress);
        
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

        //Referral Balances
        ref_balances.push(50e6);
        ref_balances.push(75e6);
        ref_balances.push(125e6);
        ref_balances.push(180e6);
        ref_balances.push(250e6);
        ref_balances.push(400e6);
        ref_balances.push(600e6);
        ref_balances.push(900e6);
        ref_balances.push(1300e6);
        ref_balances.push(2000e6);
        ref_balances.push(3000e6);
        ref_balances.push(4500e6);
        ref_balances.push(7000e6);
        ref_balances.push(10000e6);
        ref_balances.push(15000e6);
    
    }

    //@dev Default payable is empty since Flow executes trades and recieves TRX
    function() external payable  {
        //Do nothing, TRX will be sent to contract when selling tokens
    }

    /****** Administrative Functions *******/

    //@dev Updates flushSize to adjust how often Flow interacts with the Reactor and SwapX
    function updateFlushSize(uint256 _flush_size) public onlyOwner {

        require(_flush_size >= 10e6 && _flush_size <= 5000e6, "Flush size out of range 10 - 5K BNKRX");

        flushSize = _flush_size;

        emit UpdateFlushSize(flushSize);
    }

    //@dev Launch Flow; Several logic gates are controlled by the launched flag to facilitate easier beta testing
    function launch() public onlyOwner {
        require(!launched, "Flow is already launched!");
        flushSize = 1000e6;
        launched = true;

        //events
        emit UpdateFlushSize(flushSize);
    }

    
    /****** Management Functions *******/
 

    //@dev Update the sender's manager
    function updateManager(address _manager) public {
        address _addr = msg.sender;

        //Checkin for custody management.  If a user rolls for themselves they are active
        checkin();
        
        custody[_addr].manager = _manager;

        emit ManagerUpdate(_addr, _manager, now);
    }

    //@dev Update the sender's beneficiary
    function updateBeneficiary(address _beneficiary, uint256 _interval) public {
        address _addr = msg.sender;

        //Checkin for custody management.  If a user rolls for themselves they are active
        checkin();
        
        custody[_addr].beneficiary = _beneficiary;

        emit BeneficiaryUpdate(_addr, _beneficiary);

        //Some people may prefer a tight window since Flow may be used for income.  
        //2 years is the inactivity limit for Google... (the UI will probably present a more praactical upper limit)
        //If not launched the update interval can be set to anything for testng purposes
        require((_interval >= 90 days && _interval <= 730 days) || !launched, "Time range is invalid"); 

        custody[_addr].heartbeat_interval =  _interval;

        emit HeartBeatIntervalUpdate(_addr, _interval);
    }

    
    //@dev Deposit specified BNKRX amount by a manager
    function depositFor(address _addr, uint256 _amount) external {

        address _sender = msg.sender;
        uint256 _total_amount = _amount; 

        checkForManager(_addr);

        //touch
        _heart(_addr);

        require(_amount >= minimumAmount, "Minimum deposit of 1 BNKRX");
        
        //Account has to be setup
        require(users[_addr].deposits > 0, "Destination must be initialized");

        uint256 _claims = claimsAvailable(_addr);

    
        //Claim if divs are greater than 1% of the deposit
        if (_claims > _amount / 100){
            _roll(_addr);
        }

        //Transfer BNKRX to the contract using the sender
        require(
            bnkrxToken.transferFrom(
                _sender,
                address(this),
                _amount
            ),
            "BNKRX token transfer failed"
        );

        _deposit(_addr, _amount);

        emit Leaderboard(_addr, users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure);
        total_txs++;
        
    }

    //@dev Claim and deposit by a manager
    function rollFor(address _addr) external {

         checkForManager(_addr);

        //touch
        _heart(_addr);

        _roll(_addr);

    }

     //@dev Claim  by a manager
    function claimFor(address _addr) external {

        checkForManager(_addr);

        //touch
        _heart(_addr);

        _claim_out(_addr);

    }

    //@dev Transfer an inactive account and migrate the funds to a defined beneficiary. Only works if a beneficiary is defined
    //Can be initiated if there is no checkin beyond the heartbeat_interval
    function transferInactiveAccount(address _addr) public {

        address _beneficiary = msg.sender;

        //Sender has to be the beneficiary of the account
        require(custody[_addr].beneficiary != address(0), "This account does not have a beneficiary set");
        require(custody[_addr].beneficiary == _beneficiary, "Sender must be the beneficiary of the account");
        
        //Has the user checked into his account
        uint256 lapsed = now.safeSub(custody[_addr].last_checkin);

        if (lapsed >  custody[_addr].heartbeat_interval ){
             
            //transfer balances
            _transfer_balances(_addr, _beneficiary);
         
        }

    }

    //@dev Transfer balances to another account
    function transferBalances(address _dest) public {

        address _src = msg.sender;

        require(isNetPositive(_src), "Source account must be net positive for transfers");
             
        //transfer balances
        _transfer_balances(_src, _dest);
    
    }

    /********** User Fuctions **************************************************/


    //@dev Migrates a wallet into the same or different wallet
    function migrate(address _dest) public returns (uint256 _deposits, uint256 _payouts) {
        
        address _src = msg.sender;

        //Pull source data
        (uint256 _referrals, uint256 _total_deposits, uint256 _total_payouts, uint256 _total_structure) =  flowSource.userInfoTotals(_src);

        //Sanity checks
        require(migrations[_src].migrated == 0, "Address has already been migrated");
        require(users[_dest].deposits > 0, "Destination must have an initial deposit");
        require(_total_deposits > 0, "Source address is not in Flow");


        //Migrate Airdrops
        (uint256 _airdrops, uint256 _received, uint256 last_airdrop) = airdropSource.userInfo(_src);
        airdrops[_dest].airdrops += _airdrops;
        airdrops[_dest].airdrops_received += _received;

        /**** Migrate Balances ****/
        
         //Claim if divs are greater than 1% of the deposit
        if (claimsAvailable(_dest) > _total_deposits / 100){
            //A roll here may be expensive, but it will be correct
            _roll(_dest);
        }
        
        //Scaled payout
        uint256 _dest_payouts = maxPayoutOf(_total_deposits) *  _total_payouts / flowSource.maxPayoutOf(_total_deposits);

        //Update balances and deposit time
        
        users[_dest].deposits += _total_deposits;
        users[_dest].payouts += _dest_payouts;

        users[_dest].deposit_time = now;

        //Mark as migrated
        migrations[_src].migrated = now;
        migrations[_src].destination = _dest;

        //Update Global
        total_deposited += _total_deposits;

        //Fund 10% of deposits via topoff
        _topOff(_total_deposits / 10);


        //events
        emit Migrate(_src, _dest, _total_deposits, _dest_payouts);

        return (_total_deposits, _dest_payouts);
     
    }

    
    //@dev Checkin disambiguates activity between an active manager and player; this allows a beneficiary to execute a call to "transferInactiveAccount" if the player is gone, 
    //but a manager is still executing on their behalf!
    function checkin() public {
        address _addr = msg.sender;
        custody[_addr].last_checkin = now;
        emit Checkin(_addr, custody[_addr].last_checkin);
    }

     

    //@dev Deposit specified BNKRX amount supplying an upline referral
    function deposit(address _upline, uint256 _amount) external {

        address _addr = msg.sender;
        uint256 _total_amount = _amount; 

        
        //Checkin for custody management.  If a user rolls for themselves they are active
        checkin();

        require(_amount >= minimumAmount, "Minimum deposit of 1 BNKRX");
        
        //If fresh account require 10 BNKRX
        if (users[_addr].deposits == 0){
            require(_amount >= minimumInitial, "Initial deposit of 10 BNKRX");
        }
        
        _setUpline(_addr, _upline);

        //Claim if divs are greater than 1% of the deposit
        if (claimsAvailable(_addr) > _amount / 100){
            _total_amount += _claim(_addr);
        }

        //Transfer BNKRX to the contract
        require(
            bnkrxToken.transferFrom(
                _addr,
                address(this),
                _amount
            ),
            "BNKRX token transfer failed"
        );
        _deposit(_addr, _total_amount);

        emit Leaderboard(_addr, users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure);
        total_txs++;
        
    }


    //@dev Claim, transfer, and topoff
    function claim() external {

        //Checkin for custody management.  If a user rolls for themselves they are active
        checkin();

        address _addr = msg.sender;

        _claim_out(_addr);     
    }

    //@dev Claim and deposit; Flow is lazy about minting tokens and will only mint to match withdrawals 
    function roll() public {

        //Checkin for custody management.  If a user rolls for themselves they are active
        checkin();

         address _addr = msg.sender;

        _roll(_addr);   
    }

    /********** Internal Fuctions **************************************************/

    //@dev Is marked as a managed function
    function checkForManager(address _addr) internal {
        //Sender has to be the manager of the account
        require(custody[_addr].manager == msg.sender, "_addr is not set as manager");
    }

    //@dev Transfers account balances; claims and payouts
    function _transfer_balances(address _src, address _dest) internal  {
        
        //Sanity checks
        require(_src != _dest, "Source and destination cannot be equal");
        require(users[_dest].deposits > 0 &&  users[_src].deposits > 0, "Source and Destination must have an initial deposit");

        uint256 _deposits = users[_src].deposits;
        uint256 _payouts = users[_src].payouts;

        //Claim if divs are greater than 1% of the deposit
        if (claimsAvailable(_dest) > _deposits / 100){
            //A roll here may be expensive, but it will be correct
            _roll(_dest);
        }
        

        //Update balances and deposit time
        users[_dest].deposits += _deposits;
        users[_dest].payouts += _payouts;
        users[_dest].deposit_time = now;

        //Zero out source deposits and payouts; this means a 
        users[_src].deposits = 0;
        users[_src].payouts = 0;
        
        //events
        emit NewDeposit(_dest, _deposits);
        emit BalanceTransfer(_src, _dest, _deposits, _payouts);

    }

    //@dev Buffer and mint BNKRX as needed to maintain deposits
    //Topoff is only required to make sure there is ample BNKRX to fuel the reactor
    function _topOff(uint256 _amount) internal {
        topoff_balance += _amount;

        if (topoff_balance > flushSize){

            //mint, ignoring difficulty to replace distributed tokens
            tokenMint.mint(address(this), topoff_balance * tokenMint.mintingDifficulty());

            //reset balance
            topoff_balance = 0;
        }
    }

    //@dev Add direct referral and update team structure of upline
    function _setUpline(address _addr, address _upline) internal {
        
        if(users[_addr].upline == address(0) && _upline != _addr && _addr != owner && (users[_upline].deposit_time > 0 || _upline == owner )) {
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            total_users++;

            for(uint8 i = 0; i < ref_depth; i++) {
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
        users[_addr].deposits += _amount;
        users[_addr].deposit_time = now;

        total_deposited += _amount;
        
        //events
        emit NewDeposit(_addr, _amount);

        //10% direct commission; only if net positive   
        address _up = users[_addr].upline;
        if(_up != address(0) && isNetPositive(_up) && isBalanceCovered(_up, 1)) {
            uint256 _bonus = _amount / 10;
            
            //Log historical and add to deposits
            users[_up].direct_bonus += _bonus;
            users[_up].deposits += _bonus;

            emit NewDeposit(_up, _bonus);
            emit DirectPayout(_up, _addr, _bonus);
        }
        
        
    }

    //@dev Sell BNKRX and receive TRX; 5% buyback
    function _fuelReactor(uint256 _amount) internal {

        //5% buybacks
        buyback_balance += _amount * 5 / 100;

        //We need to take the minimum BNKRX in the contract; jusrt in case there is shortage due to migration deficits (all the tokens are in the old contract)
        uint256 _tokenBalance = bnkrxToken.balanceOf(address(this));
        uint256 _tokens = buyback_balance.min(_tokenBalance);

        if (_tokens > flushSize){

            //Sell BNKRX 
            _sellRewardTokens(_tokens);

            //Adjust buybackbalance down
            buyback_balance = buyback_balance.safeSub(_tokens);

            //Buyback BNKR from the sale and send to Stronghold
            total_trx += _transReactor();
        }  

    }


    //Payout upline; Bonuses are from 5 - 30% on the 1% paid out daily; Referrals only help 
    function _refPayout(address _addr, uint256 _amount) internal {
        
        address _up = users[_addr].upline;
        uint256 _bonus = _amount * ref_bonus / 100;
        uint256 _share = _bonus / 4;
        uint256 _up_share = _bonus.sub(_share);
        bool _team_found = false; 

        for(uint8 i = 0; i < ref_depth; i++) {
                     
            //If we have reached the top of the chain,  the owner         
            if(_up == address(0)){
                //The equivalent of looping through all available
                users[_addr].ref_claim_pos = ref_depth;
                break;
            } 
            
            //We only match if the claim position is valid
            if(users[_addr].ref_claim_pos == i && isBalanceCovered(_up, i + 1) && isNetPositive(_up)) {
                
                //Team wallets are split 75/25%
                if(users[_up].referrals >= 5 && !_team_found) {
                    //This should only be called once    
                    _team_found = true;
                    //upline is paid matching and 
                    users[_up].deposits += _up_share;
                    users[_addr].deposits += _share;

                    //match accounting
                    users[_up].match_bonus += _up_share;
                

                    //Synthetic Airdrop tracking; team wallets get automatic airdrop benefits
                    airdrops[_up].airdrops += _share;
                    airdrops[_up].last_airdrop = now;
                    airdrops[_addr].airdrops_received += _share;

                    //Global airdrops
                    total_airdrops += _share;

                    //Events
                    emit NewDeposit(_addr, _share);
                    emit NewDeposit(_up, _up_share);

                    emit NewAirdrop(_up, _addr, _share, now);
                    emit MatchPayout(_up, _addr, _up_share); 
                } else {
                    
                    users[_up].deposits += _bonus;

                    //match accounting
                    users[_up].match_bonus += _bonus;

                    //events
                    emit NewDeposit(_up, _bonus);
                    emit MatchPayout(_up, _addr, _bonus);
                }

                //The work has been done for the position; just break
                break;
                
            }

            _up = users[_up].upline;
        }

        //Reward  the next
        users[_addr].ref_claim_pos += 1;

        //Reset if we've hit the end of the line
        if (users[_addr].ref_claim_pos >= ref_depth){
            users[_addr].ref_claim_pos = 0;
        } 
    
    }

    //@dev General purpose heartbeat in the system used for custody/management planning
    function _heart(address _addr) internal {
        custody[_addr].last_heartbeat = now;
        emit HeartBeat(_addr, custody[_addr].last_heartbeat);
    }


    //@dev Claim and deposit; Flow is lazy about minting tokens and will only mint to match withdrawals    
     function _roll(address _addr) internal {

        uint256 to_payout = _claim(_addr);

        //We want inflation to reflect in the token supply!!!! (New in v1.2)
        //Rolls create the inflation
        _topOff(to_payout);

        //Recycle baby!
        _deposit(_addr, to_payout);

        //track rolls for net positive
        users[_addr].rolls += to_payout; 

        emit Leaderboard(_addr, users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure);
        total_txs++;
        
    }


    //@dev Claim, transfer, and topoff
    function _claim_out(address _addr) internal {

        uint256 to_payout = _claim(_addr);

        //Mint earned BNKR, ignoring difficulty to replace distributed tokens (In v1.2, we mint here in the claim out function vs topping off)
        //This is the only place in the protocol where tokens are generated for Flow
        tokenMint.mint(_addr, to_payout * tokenMint.mintingDifficulty());


        emit Leaderboard(_addr, users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure);
        total_txs++;

    }


    //@dev Claim current payouts
    
    function _claim(address _addr) internal returns (uint256) {

        (uint256 _gross_payout, uint256 _max_payout, uint256 _to_payout, uint256 _sustainability_fee) = payoutOf(_addr);
        
        
        require(users[_addr].payouts < _max_payout, "Full payouts");

        // Deposit payout
        if(_to_payout > 0) {
            if(users[_addr].payouts + _to_payout > _max_payout) {
                _to_payout = _max_payout.safeSub(users[_addr].payouts);
            }

            users[_addr].payouts += _to_payout;

            //Payout referrals
            _refPayout(_addr, _to_payout);
        }

        require(_to_payout > 0, "Zero payout");
        
        //Update the payouts
        total_withdraw += _to_payout;

        //Update time!   
        users[_addr].deposit_time = now;

        //Sell 5% of BNKRX movement outbound; use gross!
        _fuelReactor(_gross_payout);

        emit Withdraw(_addr, _to_payout);

        if(users[_addr].payouts >= _max_payout) {
            emit LimitReached(_addr, users[_addr].payouts);
        }

        return _to_payout;
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
    function _transReactor() internal returns (uint256) {
        //Get the TRX at the address
        uint256 _balance = address(this).balance;

        if (_balance > flushSize) {
            reactorAddress.transfer(_balance);

            emit Buyback(reactorAddress, _balance);
            return _balance;
        }

        return 0;
    }
    
   


    /********* Views ***************************************/

    //@dev Returns _src and _dest info for migration along with all in checks for validity
    function migrationStatus(address _src, address _dest) public view returns (bool _src_available, bool _dest_available) {
        //Source Stats
        (uint256 _referrals, uint256 _src_deposits, uint256 _src_payouts, uint256 _total_structure) =  flowSource.userInfoTotals(_src);

        _src_available = migrations[_src].migrated == 0 && users[_src].deposits > 0;
        _dest_available = users[_dest].deposits > 0;
        
    }

    //@dev Returns true if the address is net positive
    function isNetPositive(address _addr) public view returns (bool) {
               
        (uint256 _credits, uint256 _debits) = creditsAndDebits(_addr);

        return _credits > _debits;
        
    }

    //@dev Returns the total credits and debits for a given address
    function creditsAndDebits(address _addr) public view returns (uint256 _credits, uint256 _debits) {
        User memory _user = users[_addr];
        Airdrop memory _airdrop = airdrops[_addr];

        _credits = _airdrop.airdrops + _user.rolls + _user.deposits;
        _debits = _user.payouts;

    }

    //@dev Returns true if an account is active

    //@dev Returns whether BNKR balance matches level
    function isBalanceCovered(address _addr, uint8 _level) public view returns (bool) {
        return balanceLevel(_addr) >= _level;
    }

    //@dev Returns the level of the address
    function balanceLevel(address _addr) public view returns (uint8) {
        uint8 _level = 0;
        for (uint8 i = 0; i < ref_depth; i++) {
            if (bnkrToken.balanceOf(_addr) < ref_balances[i]) break;
            _level += 1;
        }

        return _level;
    }

    //@dev Returns the realized sustainability fee of the supplied address
    function sustainabilityFee(address _addr) public view returns (uint256) {
        uint256 _bracket = users[_addr].deposits.div(deposit_bracket_size); 

        _bracket = SafeMath.min(_bracket,deposit_bracket_max);
        return _bracket * 5;
    }


    //@dev Returns custody info of _addr
    function getCustody(address _addr) public view returns (address _beneficiary, uint256 _heartbeat_interval, address _manager) {
        return (custody[_addr].beneficiary, custody[_addr].heartbeat_interval, custody[_addr].manager);
    }


    //@dev Returns true if _manager is the manager of _addr
    function isManager(address _addr, address _manager) public view returns (bool) {
        return custody[_addr].manager == _manager;
    }

    //@dev Returns true if _beneficiary is the beneficiary of _addr
    function isBeneficiary(address _addr, address _beneficiary) public view returns (bool) {
        return custody[_addr].beneficiary == _beneficiary;
    }

    //@dev Returns true if _manager is valid for managing _addr 
    function isManagementEligible(address _addr, address _manager) public view returns (bool) {
        return _manager != address(0) && _addr != _manager && users[_manager].deposits > 0 && users[_manager].deposit_time > 0;
    }



    //@dev Returns account activity timestamps
    function  lastActivity(address _addr) public view returns (uint256 _heartbeat, uint256 _lapsed_heartbeat, uint256 _checkin, uint256 _lapsed_checkin) {
        _heartbeat = custody[_addr].last_heartbeat;
        _lapsed_heartbeat = now.safeSub(_heartbeat);
        _checkin = custody[_addr].last_checkin;
        _lapsed_checkin = now.safeSub(_checkin);
    } 


    //@dev Returns amount of claims available for sender
    function claimsAvailable(address _addr) public view returns (uint256) {
        (uint256 _gross_payout, uint256 _max_payout, uint256 _to_payout, uint256 _sustainability_fee) = payoutOf(_addr);

        return _to_payout;

    }

     //@dev Maxpayout of 3.65 of deposit
    function maxPayoutOf(uint256 _amount) public pure  returns(uint256) {
        return _amount * 125 / 100;
    }

    //@dev Calculate the current payout and maxpayout of a given address
    function payoutOf(address _addr) public view  returns(uint256 payout, uint256 max_payout, uint256 net_payout, uint256 sustainability_fee) {
        
        //The max_payout is capped so that we can also cap available rewards daily  
        max_payout = maxPayoutOf(users[_addr].deposits).min(max_payout_cap);

        //This can  be 0 - 50 in increments of 5%
        uint256 _fee = sustainabilityFee(_addr);
        uint256 share;


        //Negative NDV account pay a mandatory sustainability fee
        _fee = (!isNetPositive(_addr)) ? _fee.max(negativeFee) : _fee;
        


        if(users[_addr].payouts < max_payout) {
            //Using 1e6 we capture all significant digits when calculating avalaible divs
            share = users[_addr].deposits.mul(payoutRate * 1e6).div(100e6).div(24 hours); //divide the profit by payout rate and seconds in the day
            
            payout = share * now.safeSub(users[_addr].deposit_time);
            
            if(users[_addr].payouts + payout > max_payout) {
                payout = max_payout.safeSub(users[_addr].payouts);
            }
            
            sustainability_fee = payout * _fee / 100;

            net_payout = payout.safeSub(sustainability_fee);
        }
    }


    
    //@dev Get current user snapshot 
    function userInfo(address _addr)  external view  returns(address upline, uint256 deposit_time, uint256 deposits, uint256 payouts, uint256 direct_bonus, uint256 match_bonus, uint256 last_airdrop) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposits, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].match_bonus, airdrops[_addr].last_airdrop);
    }

    //@dev Get user totals
    function userInfoTotals(address _addr) external view  returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure, uint256 airdrops_total, uint256 airdrops_received) {
        return (users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure, airdrops[_addr].airdrops, airdrops[_addr].airdrops_received);
    }

    //@dev Get contract snapshot
    function contractInfo() external view  returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 _total_trx, uint256 _total_txs, uint256 _total_airdrops) {
        return (total_users, total_deposited, total_withdraw, total_trx, total_txs, total_airdrops);
    }

    /////// Airdrops ///////

    //@dev Send specified BNKRX amount supplying an upline referral
    function airdrop(address _to, uint256 _amount) external {

        address _addr = msg.sender; 

        //This can only fail if the balance is insufficient
        require(
            bnkrxToken.transferFrom(
                _addr,
                address(this),
                _amount
            ),
            "BNKRX to contract transfer failed; check balance and allowance, airdrop"
        );

      
        //Make sure _to exists in the system; we increase
        require(users[_to].upline != address(0), "_to not found");

        //Fund to deposits (not a transfer)
        users[_to].deposits += _amount;
        

        //User stats
        airdrops[_addr].airdrops += _amount;
        airdrops[_addr].last_airdrop = now;
        airdrops[_to].airdrops_received += _amount;

        //Keep track of overall stats
        total_airdrops += _amount;
        total_txs += 1;


        //Let em know!
        emit NewAirdrop(_addr, _to, _amount, now);
        emit NewDeposit(_to, _amount);
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