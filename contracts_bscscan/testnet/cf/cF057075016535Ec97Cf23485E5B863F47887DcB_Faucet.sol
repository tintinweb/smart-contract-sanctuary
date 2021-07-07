pragma solidity ^0.4.25;
import "./Ownable.sol";
import "./SafeMath.sol";
import "./ITokenMint.sol";
import "./IToken.sol";
import "./IDripVault.sol";

contract Faucet is Ownable {

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

    struct Custody {
        address manager;
        address beneficiary;
        uint256 last_heartbeat;
        uint256 last_checkin;
        uint256 heartbeat_interval;
    }

    address public fountainAddress; // Fountain is SwapX
    address public dripVaultAddress; //Drip vault is where drip for FLOW is stored??

    ITokenMint private tokenMint;
    IToken private br34pToken; // Token held for referral rewards
    IToken private dripToken; // Yield token
    IDripVault private dripVault;

    mapping(address => User) public users;
    mapping(address => Airdrop) public airdrops;
    mapping(address => Custody) public custody;

    uint256 public CompoundTax = 5;
    uint256 public ExitTax = 10;

    uint256 private constant payoutRate = 1;
    uint256 private constant ref_depth  = 15;
    uint256 private constant ref_bonus  = 10;

    uint256 private constant minimumInitial = 10e18;
    uint256 private constant minimumAmount = 1e18;

    uint256 public deposit_bracket_size = 10000e18;     // @BB 5% increase whale tax per 10000 tokens... 10 below cuts it at 50% since 5 * 10
    uint256 public max_payout_cap = 100000e18;          // 100k DRIP or 10% of supply
    uint256 private constant deposit_bracket_max = 10;  // sustainability fee is (bracket * 5)

    uint256[] public ref_balances;

    uint256 public total_airdrops;
    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    uint256 public total_bnb;
    uint256 public total_txs;

    uint256 public constant MAX_UINT = 2**256 - 1;

    event Upline(address indexed addr, address indexed upline);
    event NewDeposit(address indexed addr, uint256 amount);
    event Leaderboard(address indexed addr, uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event BalanceTransfer(address indexed _src, address indexed _dest, uint256 _deposits, uint256 _payouts);
    event Withdraw(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);
    event NewAirdrop(address indexed from, address indexed to, uint256 amount, uint256 timestamp);
    event ManagerUpdate(address indexed addr, address indexed manager, uint256 timestamp);
    event BeneficiaryUpdate(address indexed addr, address indexed beneficiary);
    event HeartBeatIntervalUpdate(address indexed addr, uint256 interval);
    event HeartBeat(address indexed addr, uint256 timestamp);
    event Checkin(address indexed addr, uint256 timestamp);

    constructor(address _mintAddress, address _BR34PTokenAddress, address _dripTokenAddress, address _vaultAddress) public Ownable() {

        //Only the mint should own its paired token
        tokenMint = ITokenMint(_mintAddress);

        //Br34p
        br34pToken = IToken(_BR34PTokenAddress);

        //Drip
        dripToken = IToken(_dripTokenAddress);

        //IDripVault
        dripVaultAddress = _vaultAddress;
        dripVault = IDripVault(_vaultAddress);

        //Referral Balances
        ref_balances.push(2e8);
        ref_balances.push(3e8);
        ref_balances.push(5e8);
        ref_balances.push(8e8);
        ref_balances.push(13e8);
        ref_balances.push(21e8);
        ref_balances.push(34e8);
        ref_balances.push(55e8);
        ref_balances.push(89e8);
        ref_balances.push(144e8);
        ref_balances.push(233e8);
        ref_balances.push(377e8);
        ref_balances.push(610e8);
        ref_balances.push(987e8);
        ref_balances.push(1597e8);
    }

    //@dev Default payable is empty since Faucet executes trades and recieves BNB
    function() external payable  {
        //Do nothing, BNB will be sent to contract when selling tokens
    }

    /****** Administrative Functions *******/

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

        //2 years is the inactivity limit for Google... (the UI will probably present a more practical upper limit)
        //If not launched the update interval can be set to anything for testng purposes
        require((_interval >= 90 days && _interval <= 730 days), "Time range is invalid");

        custody[_addr].heartbeat_interval =  _interval;

        emit HeartBeatIntervalUpdate(_addr, _interval);
    }

    function updateCompoundTax(uint256 _newCompoundTax) public onlyOwner {
        require(_newCompoundTax >= 0 && _newCompoundTax <= 20);
        CompoundTax = _newCompoundTax;
    }

    function updateExitTax(uint256 _newExitTax) public onlyOwner {
        require(_newExitTax >= 0 && _newExitTax <= 20);
        ExitTax = _newExitTax;
    }

    function updateDepositBracketSize(uint256 _newBracketSize) public onlyOwner {
        deposit_bracket_size = _newBracketSize;
    }

    function updateMaxPayoutCap(uint256 _newPayoutCap) public onlyOwner {
        max_payout_cap = _newPayoutCap;
    }

    function updateHoldRequirements(uint256[] _newRefBalances) public onlyOwner {
        require(_newRefBalances.length == ref_depth);
        delete ref_balances;
        for(uint8 i = 0; i < ref_depth; i++) {
            ref_balances.push(_newRefBalances[i]);
        }
    }

    /********** User Fuctions **************************************************/

    //@dev Checkin disambiguates activity between an active manager and player; this allows a beneficiary to execute a call to "transferInactiveAccount" if the player is gone,
    //but a manager is still executing on their behalf!
    function checkin() public {
        address _addr = msg.sender;
        custody[_addr].last_checkin = now;
        emit Checkin(_addr, custody[_addr].last_checkin);
    }

    //@dev Deposit specified DRIP amount supplying an upline referral
    function deposit(address _upline, uint256 _amount) external {

        address _addr = msg.sender;

        (uint256 realizedDeposit, uint256 taxAmount) = dripToken.calculateTransferTaxes(_addr, _amount);
        uint256 _total_amount = realizedDeposit;

        //Checkin for custody management.  If a user rolls for themselves they are active
        checkin();

        require(_amount >= minimumAmount, "Minimum deposit of 1 DRIP");

        //If fresh account require 10 DRIP
        if (users[_addr].deposits == 0){
            require(_amount >= minimumInitial, "Initial deposit of 10 DRIP");
        }

        _setUpline(_addr, _upline);

        // Claim if divs are greater than 1% of the deposit
        if (claimsAvailable(_addr) > _amount / 100){
            uint256 claimedDivs = _claim(_addr, false);
            uint256 taxedDivs = claimedDivs.mul(SafeMath.sub(100, CompoundTax)).div(100); // 5% tax on compounding
            _total_amount += taxedDivs;
        }

        //Transfer DRIP to the contract
        require(
            dripToken.transferFrom(
                _addr,
                address(dripVaultAddress),
                _amount
            ),
            "DRIP token transfer failed"
        );
        /*
        User deposits 10;
        1 goes for tax, 9 are realized deposit
        */

        _deposit(_addr, _total_amount);

        emit Leaderboard(_addr, users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure);
        total_txs++;

    }


    //@dev Claim, transfer, withdraw from vault
    function claim() external {

        //Checkin for custody management.  If a user rolls for themselves they are active
        checkin();

        address _addr = msg.sender;

        _claim_out(_addr);
    }

    //@dev Claim and deposit;
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

    //@dev Add direct referral and update team structure of upline
    function _setUpline(address _addr, address _upline) internal {
        /*
        1) User must not have existing up-line
        2) Up-line argument must not be equal to senders own address
        3) Senders address must not be equal to the owner
        4) Up-lined user must have a existing deposit
        */
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

    //@dev Deposit
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

    //Payout upline; Bonuses are from 5 - 30% on the 1% paid out daily; Referrals only help
    function _refPayout(address _addr, uint256 _amount) internal {

        address _up = users[_addr].upline;
        uint256 _bonus = _amount * ref_bonus / 100;
        uint256 _share = _bonus / 4;
        uint256 _up_share = _bonus.sub(_share);
        bool _team_found = false;

        for(uint8 i = 0; i < ref_depth; i++) {

            // If we have reached the top of the chain, the owner
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

        //Reward the next
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


    //@dev Claim and deposit;
    function _roll(address _addr) internal {

        uint256 to_payout = _claim(_addr, false);

        uint256 payout_taxed = to_payout.mul(SafeMath.sub(100, CompoundTax)).div(100); // 5% tax on compounding

        //Recycle baby!
        _deposit(_addr, payout_taxed);

        //track rolls for net positive
        users[_addr].rolls += payout_taxed;

        emit Leaderboard(_addr, users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure);
        total_txs++;

    }


    //@dev Claim, transfer, and topoff
    function _claim_out(address _addr) internal {

        uint256 to_payout = _claim(_addr, true);

        uint256 vaultBalance = dripToken.balanceOf(dripVaultAddress);
        if (vaultBalance < to_payout) {
            uint256 differenceToMint = to_payout.sub(vaultBalance);
            tokenMint.mint(dripVaultAddress, differenceToMint);
        }

        dripVault.withdraw(to_payout);

        uint256 realizedPayout = to_payout.mul(SafeMath.sub(100, ExitTax)).div(100); // 10% tax on withdraw
        require(dripToken.transfer(address(msg.sender), realizedPayout));

        emit Leaderboard(_addr, users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure);
        total_txs++;

    }


    //@dev Claim current payouts
    function _claim(address _addr, bool isClaimedOut) internal returns (uint256) {
        (uint256 _gross_payout, uint256 _max_payout, uint256 _to_payout, uint256 _sustainability_fee) = payoutOf(_addr);
        require(users[_addr].payouts < _max_payout, "Full payouts");

        // Deposit payout
        if(_to_payout > 0) {

            // payout remaining allowable divs if exceeds
            if(users[_addr].payouts + _to_payout > _max_payout) {
                _to_payout = _max_payout.safeSub(users[_addr].payouts);
            }

            users[_addr].payouts += _gross_payout;
            //users[_addr].payouts += _to_payout;

            if (!isClaimedOut){
                //Payout referrals
                uint256 compoundTaxedPayout = _to_payout.mul(SafeMath.sub(100, CompoundTax)).div(100); // 5% tax on compounding
                _refPayout(_addr, compoundTaxedPayout);
            }
        }

        require(_to_payout > 0, "Zero payout");

        //Update the payouts
        total_withdraw += _to_payout;

        //Update time!
        users[_addr].deposit_time = now;

        emit Withdraw(_addr, _to_payout);

        if(users[_addr].payouts >= _max_payout) {
            emit LimitReached(_addr, users[_addr].payouts);
        }

        return _to_payout;
    }

    /********* Views ***************************************/

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

    //@dev Returns whether BR34P balance matches level
    function isBalanceCovered(address _addr, uint8 _level) public view returns (bool) {
        return balanceLevel(_addr) >= _level;
    }

    //@dev Returns the level of the address
    function balanceLevel(address _addr) public view returns (uint8) {
        uint8 _level = 0;
        for (uint8 i = 0; i < ref_depth; i++) {
            if (br34pToken.balanceOf(_addr) < ref_balances[i]) break;
            _level += 1;
        }

        return _level;
    }

    //@dev Returns the realized sustainability fee of the supplied address
    function sustainabilityFee(address _addr) public view returns (uint256) {
        uint256 _bracket = users[_addr].deposits.div(deposit_bracket_size);
        _bracket = SafeMath.min(_bracket, deposit_bracket_max);
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
    function lastActivity(address _addr) public view returns (uint256 _heartbeat, uint256 _lapsed_heartbeat, uint256 _checkin, uint256 _lapsed_checkin) {
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
    function maxPayoutOf(uint256 _amount) public pure returns(uint256) {
        return _amount * 365 / 100;
    }

    //@dev Calculate the current payout and maxpayout of a given address
    function payoutOf(address _addr) public view returns(uint256 payout, uint256 max_payout, uint256 net_payout, uint256 sustainability_fee) {

        //The max_payout is capped so that we can also cap available rewards daily
        max_payout = maxPayoutOf(users[_addr].deposits).min(max_payout_cap);

        //This can  be 0 - 50 in increments of 5% @bb Whale tax bracket calcs here
        uint256 _fee = sustainabilityFee(_addr);
        uint256 share;

        // @BB: No need for negative fee

        if(users[_addr].payouts < max_payout) {
            //Using 1e18 we capture all significant digits when calculating available divs
            share = users[_addr].deposits.mul(payoutRate * 1e18).div(100e18).div(24 hours); //divide the profit by payout rate and seconds in the day
            payout = share * now.safeSub(users[_addr].deposit_time);

            // payout remaining allowable divs if exceeds
            if(users[_addr].payouts + payout > max_payout) {
                payout = max_payout.safeSub(users[_addr].payouts);
            }

            sustainability_fee = payout * _fee / 100;

            net_payout = payout.safeSub(sustainability_fee);
        }
    }


    //@dev Get current user snapshot
    function userInfo(address _addr) external view returns(address upline, uint256 deposit_time, uint256 deposits, uint256 payouts, uint256 direct_bonus, uint256 match_bonus, uint256 last_airdrop) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposits, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].match_bonus, airdrops[_addr].last_airdrop);
    }

    //@dev Get user totals
    function userInfoTotals(address _addr) external view returns(uint256 referrals, uint256 total_deposits, uint256 total_payouts, uint256 total_structure, uint256 airdrops_total, uint256 airdrops_received) {
        return (users[_addr].referrals, users[_addr].deposits, users[_addr].payouts, users[_addr].total_structure, airdrops[_addr].airdrops, airdrops[_addr].airdrops_received);
    }

    //@dev Get contract snapshot
    function contractInfo() external view returns(uint256 _total_users, uint256 _total_deposited, uint256 _total_withdraw, uint256 _total_bnb, uint256 _total_txs, uint256 _total_airdrops) {
        return (total_users, total_deposited, total_withdraw, total_bnb, total_txs, total_airdrops);
    }

    /////// Airdrops ///////

    //@dev Send specified DRIP amount supplying an upline referral
    function airdrop(address _to, uint256 _amount) external {

        address _addr = msg.sender;

        (uint256 _realizedAmount, uint256 taxAmount) = dripToken.calculateTransferTaxes(_addr, _amount);
        //This can only fail if the balance is insufficient
        require(
            dripToken.transferFrom(
                _addr,
                address(dripVaultAddress),
                _amount
            ),
            "DRIP to contract transfer failed; check balance and allowance, airdrop"
        );


        //Make sure _to exists in the system; we increase
        require(users[_to].upline != address(0), "_to not found");

        //Fund to deposits (not a transfer)
        users[_to].deposits += _realizedAmount;


        //User stats
        airdrops[_addr].airdrops += _realizedAmount;
        airdrops[_addr].last_airdrop = now;
        airdrops[_to].airdrops_received += _realizedAmount;

        //Keep track of overall stats
        total_airdrops += _realizedAmount;
        total_txs += 1;


        //Let em know!
        emit NewAirdrop(_addr, _to, _realizedAmount, now);
        emit NewDeposit(_to, _realizedAmount);
    }
}