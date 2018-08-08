pragma solidity ^0.4.11;

// VERSION LAVA(I)


// --------------------------
// here&#39;s how this works:
// the current amount of dividends due to each token-holder&#39;s  is:
//   previous_due + [ p(x) * t(x)/N ] + [ p(x+1) * t(x+1)/N ] + ...
//   where p(x) is the x&#39;th payment received by the contract
//         t(x) is the number of tokens held by the token-holder at the time of p(x)
//         N    is the total number of tokens, which never changes
//
// assume that t(x) takes on 3 values, t(a), t(b) and t(c), during periods a, b, and c. then:
// factoring:
//   current_due = { (t(a) * [p(x) + p(x+1)] ...) +
//                   (t(b) * [p(y) + p(y+1)] ...) +
//                   (t(c) * [p(z) + p(z+1)] ...) } / N
//
// or
//
//   current_due = { (t(a) * period_a_fees) +
//                   (t(b) * period_b_fees) +
//                   (t(c) * period_c_fees) } / N
//
// if we designate current_due * N as current-points, then
//
//   currentPoints = {  (t(a) * period_a_fees) +
//                      (t(b) * period_b_fees) +
//                      (t(c) * period_c_fees) }
//
// or more succictly, if we recompute current points before a token-holder&#39;s number of
// tokens, T, is about to change:
//
//   currentPoints = previous_points + (T * current-period-fees)
//
// when we want to do a payout, we&#39;ll calculate:
//  current_due = current-points / N
//
// we&#39;ll keep track of a token-holder&#39;s current-period-points, which is:
//   T * current-period-fees
// by taking a snapshot of fees collected exactly when the current period began; that is, the when the
// number of tokens last changed. that is, we keep a running count of total fees received
//
//   TotalFeesReceived = p(x) + p(x+1) + p(x+2)
//
// (which happily is the same for all token holders) then, before any token holder changes their number of
// tokens we compute (for that token holder):
//
//  function calcCurPointsForAcct(acct) {
//    currentPoints[acct] += (TotalFeesReceived - lastSnapshot[acct]) * T[acct]
//    lastSnapshot[acct] = TotalFeesReceived
//  }
//
// in the withdraw fcn, all we need is:
//
//  function withdraw(acct) {
//    calcCurPointsForAcct(acct);
//    current_amount_due = currentPoints[acct] / N
//    currentPoints[acct] = 0;
//    send(current_amount_due);
//  }
//
//
// special provisions for transfers from the old e4row contract (token-split transfers)
// -------------------------------------------------------------------------------------
// normally when a new acct is created, eg cuz tokens are transferred from one acct to another, we first call
// calcCurPointsForAcct(acct) on the old acct; on the new acct we set:
//  currentPoints[acct] = 0;
//  lastSnapshot[acct] = TotalFeesReceived;
//
// this starts the new account with no credits for any dividends that have been collected so far, which is what
// you would generally want. however, there is a case in which tokens are transferred from the old e4row contract.
// in that case the tokens were reserved on this contract all along, and they earn dividends even before they are
// assigned to an account. so for token-split transfers:
//  currentPoints[acct] = 0;
//  lastSnapshot[acct] = 0;
//
// then immediately call calcCurPointsForAcct(acct) for the new token-split account. he will get credit
// for all the accumulated points, from the beginning of time.
//
// --------------------------


// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

// ---------------------------------
// ABSTRACT standard token class
// ---------------------------------
contract Token {
    function totalSupply() constant returns (uint256 supply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


// --------------------------
//  E4RowRewards - abstract e4 dividend contract
// --------------------------
contract E4LavaRewards
{
        function checkDividends(address _addr) constant returns(uint _amount);
        function withdrawDividends() public returns (uint namount);
        function transferDividends(address _to) returns (bool success);
        function getAccountInfo(address _addr) constant returns(uint _tokens, uint _snapshot, uint _points);

}

// --------------------------
//  E4LavaOptin - abstract e4 optin contract
// --------------------------
contract E4LavaOptIn
{
        function optInFromClassic() public;
}


// --------------------------
//  E4ROW (LAVA) - token contract
// --------------------------
contract E4Lava is Token, E4LavaRewards, E4LavaOptIn {
        event StatEvent(string msg);
        event StatEventI(string msg, uint val);

        enum SettingStateValue  {debug, lockedRelease}

        struct tokenAccount {
                bool alloced;       // flag to ascert prior allocation
                uint tokens;        // num tokens currently held in this acct
                uint currentPoints; // updated before token balance changes, or before a withdrawal. credit for owning tokens
                uint lastSnapshot;  // snapshot of global TotalPoints, last time we updated this acct&#39;s currentPoints
        }

// -----------------------------
//  data storage
// ----------------------------------------
        uint constant NumOrigTokens         = 5762;   // number of old tokens, from original token contract
        uint constant NewTokensPerOrigToken = 100000; // how many new tokens are created for each from original token
        uint constant NewTokenSupply        = 5762 * 100000;
        uint public numToksSwitchedOver;              // count old tokens that have been converted
        uint public holdoverBalance;                  // funds received, but not yet distributed
        uint public TotalFeesReceived;                // total fees received from partner contract(s)

        address public developers;                    // developers token holding address
        address public owner;                         // deployer executor
        address public oldE4;                         // addr of old e4 token contract
        address public oldE4RecycleBin;               // addr to transfer old tokens

        uint public decimals;
        string public symbol;

        mapping (address => tokenAccount) holderAccounts;          // who holds how many tokens (high two bytes contain curPayId)
        mapping (uint => address) holderIndexes;                   // for iteration thru holder
        mapping (address => mapping (address => uint256)) allowed; // approvals
        uint public numAccounts;

        uint public payoutThreshold;                  // no withdrawals less than this amount, to avoid remainders
        uint public rwGas;                            // reward gas
        uint public optInXferGas;                     // gas used when optInFromClassic calls xfer on old contract
        uint public optInFcnMinGas;                   // gas we need for the optInFromClassic fcn, *excluding* optInXferGas
        uint public vestTime = 1525219201;            // 1 year past sale vest developer tokens

        SettingStateValue public settingsState;


        // --------------------
        // contract constructor
        // --------------------
        function E4Lava()
        {
                owner = msg.sender;
                developers = msg.sender;
                decimals = 2;
                symbol = "E4ROW";
        }

        // -----------------------------------
        // use this to reset everything, will never be called after lockRelease
        // -----------------------------------
        function applySettings(SettingStateValue qState, uint _threshold, uint _rw, uint _optXferGas, uint _optFcnGas )
        {
                if (msg.sender != owner)
                        return;

                // these settings are permanently tweakable for performance adjustments
                payoutThreshold = _threshold;
                rwGas = _rw;
                optInXferGas = _optXferGas;
                optInFcnMinGas = _optFcnGas;

                // this first test checks if already locked
                if (settingsState == SettingStateValue.lockedRelease)
                        return;

                settingsState = qState;

                // this second test allows locking without changing other permanent settings
                // WARNING, MAKE SURE YOUR&#39;RE HAPPY WITH ALL SETTINGS
                // BEFORE LOCKING

                if (qState == SettingStateValue.lockedRelease) {
                        StatEvent("Locking!");
                        return;
                }

                // zero out all token holders.
                // leave alloced on, leave num accounts
                // cant delete them anyways

                for (uint i = 0; i < numAccounts; i++ ) {
                        address a = holderIndexes[i];
                        if (a != address(0)) {
                                holderAccounts[a].tokens = 0;
                                holderAccounts[a].currentPoints = 0;
                                holderAccounts[a].lastSnapshot = 0;
                        }
                }

                numToksSwitchedOver = 0;

                if (this.balance > 0) {
                        if (!owner.call.gas(rwGas).value(this.balance)())
                                StatEvent("ERROR!");
                }
                StatEvent("ok");

        }


        // ---------------------------------------------------
        // allocate a new account by setting alloc to true
        // add holder index, bump the num accounts
        // ---------------------------------------------------
        function addAccount(address _addr) internal  {
                holderAccounts[_addr].alloced = true;
                holderAccounts[_addr].tokens = 0;
                holderAccounts[_addr].currentPoints = 0;
                holderAccounts[_addr].lastSnapshot = TotalFeesReceived;
                holderIndexes[numAccounts++] = _addr;
        }


// --------------------------------------
// BEGIN ERC-20 from StandardToken
// --------------------------------------

        function totalSupply() constant returns (uint256 supply)
        {
                supply = NewTokenSupply;
        }

        // ----------------------------
        // sender transfers tokens to a new acct
        // do not use this fcn for a token-split transfer from the old token contract!
        // ----------------------------
        function transfer(address _to, uint256 _value) returns (bool success)
        {
                if ((msg.sender == developers)
                        &&  (now < vestTime)) {
                        //statEvent("Tokens not yet vested.");
                        return false;
                }

                //Default assumes totalSupply can&#39;t be over max (2^256 - 1).
                //If your token leaves out totalSupply and can issue more tokens as time goes on, you need to check if it doesn&#39;t wrap.
                //Replace the if with this one instead.
                //if (holderAccounts[msg.sender].tokens >= _value && balances[_to] + _value > holderAccounts[_to]) {
                if (holderAccounts[msg.sender].tokens >= _value && _value > 0) {
                    //first credit sender with points accrued so far.. must do this before number of held tokens changes
                    calcCurPointsForAcct(msg.sender);
                    holderAccounts[msg.sender].tokens -= _value;

                    if (!holderAccounts[_to].alloced) {
                        addAccount(_to);
                    }
                    //credit destination acct with points accrued so far.. must do this before number of held tokens changes
                    calcCurPointsForAcct(_to);
                    holderAccounts[_to].tokens += _value;

                    Transfer(msg.sender, _to, _value);
                    return true;
                } else {
                    return false;
                }
        }


        function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
                if ((_from == developers)
                        &&  (now < vestTime)) {
                        //statEvent("Tokens not yet vested.");
                        return false;
                }

                //same as above. Replace this line with the following if you want to protect against wrapping uints.
                //if (holderAccounts[_from].tokens >= _value && allowed[_from][msg.sender] >= _value && holderAccounts[_to].tokens + _value > holderAccounts[_to].tokens) {
                if (holderAccounts[_from].tokens >= _value && allowed[_from][msg.sender] >= _value && _value > 0) {

                    calcCurPointsForAcct(_from);
                    holderAccounts[_from].tokens -= _value;

                    if (!holderAccounts[_to].alloced) {
                        addAccount(_to);
                    }
                    //credit destination acct with points accrued so far.. must do this before number of held tokens changes
                    calcCurPointsForAcct(_to);
                    holderAccounts[_to].tokens += _value;

                    allowed[_from][msg.sender] -= _value;
                    Transfer(_from, _to, _value);
                    return true;
                } else {
                    return false;
                }
        }


        function balanceOf(address _owner) constant returns (uint256 balance) {
                balance = holderAccounts[_owner].tokens;
        }

        function approve(address _spender, uint256 _value) returns (bool success) {
                allowed[msg.sender][_spender] = _value;
                Approval(msg.sender, _spender, _value);
                return true;
        }

        function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
                return allowed[_owner][_spender];
        }
// ----------------------------------
// END ERC20
// ----------------------------------

        // ----------------------------
        // calc current points for a token holder; that is, points that are due to this token holder for all dividends
        // received by the contract during the current "period". the period began the last time this fcn was called, at which
        // time we updated the account&#39;s snapshot of the running point count, TotalFeesReceived. during the period the account&#39;s
        // number of tokens must not have changed. so always call this fcn before changing the number of tokens.
        // ----------------------------
        function calcCurPointsForAcct(address _acct) internal {
              holderAccounts[_acct].currentPoints += (TotalFeesReceived - holderAccounts[_acct].lastSnapshot) * holderAccounts[_acct].tokens;
              holderAccounts[_acct].lastSnapshot = TotalFeesReceived;
        }


        // ---------------------------
        // accept payment from a partner contract
        // funds sent here are added to TotalFeesReceived
        // WARNING! DO NOT CALL THIS FUNCTION LEST YOU LOSE YOUR MONEY
        // ---------------------------
        function () payable {
                holdoverBalance += msg.value;
                TotalFeesReceived += msg.value;
                StatEventI("Payment", msg.value);
        }

        // ---------------------------
        // one never knows if this will come in handy.
        // ---------------------------
        function blackHole() payable {
                StatEventI("adjusted", msg.value);
        }

        // ----------------------------
        // sender withdraw entire rewards/dividends
        // ----------------------------
        function withdrawDividends() public returns (uint _amount)
        {
                calcCurPointsForAcct(msg.sender);

                _amount = holderAccounts[msg.sender].currentPoints / NewTokenSupply;
                if (_amount <= payoutThreshold) {
                        StatEventI("low Balance", _amount);
                        return;
                } else {
                        if ((msg.sender == developers)
                                &&  (now < vestTime)) {
                                StatEvent("Tokens not yet vested.");
                                _amount = 0;
                                return;
                        }

                        uint _pointsUsed = _amount * NewTokenSupply;
                        holderAccounts[msg.sender].currentPoints -= _pointsUsed;
                        holdoverBalance -= _amount;
                        if (!msg.sender.call.gas(rwGas).value(_amount)())
                                throw;
                }
        }

        // ----------------------------
        // allow sender to transfer dividends
        // ----------------------------
        function transferDividends(address _to) returns (bool success)
        {
                if ((msg.sender == developers)
                        &&  (now < vestTime)) {
                        //statEvent("Tokens not yet vested.");
                        return false;
                }
                calcCurPointsForAcct(msg.sender);
                if (holderAccounts[msg.sender].currentPoints == 0) {
                        StatEvent("Zero balance");
                        return false;
                }
                if (!holderAccounts[_to].alloced) {
                        addAccount(_to);
                }
                calcCurPointsForAcct(_to);
                holderAccounts[_to].currentPoints += holderAccounts[msg.sender].currentPoints;
                holderAccounts[msg.sender].currentPoints = 0;
                StatEvent("Trasnfered Dividends");
                return true;
        }



        // ----------------------------
        // set gas for operations
        // ----------------------------
        function setOpGas(uint _rw, uint _optXferGas, uint _optFcnGas)
        {
                if (msg.sender != owner && msg.sender != developers) {
                        //StatEvent("only owner calls");
                        return;
                } else {
                        rwGas = _rw;
                        optInXferGas = _optXferGas;
                        optInFcnMinGas = _optFcnGas;
                }
        }


        // ----------------------------
        // check rewards.  pass in address of token holder
        // ----------------------------
        function checkDividends(address _addr) constant returns(uint _amount)
        {
                if (holderAccounts[_addr].alloced) {
                   //don&#39;t call calcCurPointsForAcct here, cuz this is a constant fcn
                   uint _currentPoints = holderAccounts[_addr].currentPoints +
                        ((TotalFeesReceived - holderAccounts[_addr].lastSnapshot) * holderAccounts[_addr].tokens);
                   _amount = _currentPoints / NewTokenSupply;

                // low balance? let him see it -Etansky
                  // if (_amount <= payoutThreshold) {
                  //    _amount = 0;
                  // }

                }
        }



        // ----------------------------
        // swap executor
        // ----------------------------
        function changeOwner(address _addr)
        {
                if (msg.sender != owner
                        || settingsState == SettingStateValue.lockedRelease)
                         throw;
                owner = _addr;
        }

        // ----------------------------
        // set developers account
        // ----------------------------
        function setDeveloper(address _addr)
        {
                if (msg.sender != owner
                        || settingsState == SettingStateValue.lockedRelease)
                         throw;
                developers = _addr;
        }

        // ----------------------------
        // set oldE4 Addresses
        // ----------------------------
        function setOldE4(address _oldE4, address _oldE4Recyle)
        {
                if (msg.sender != owner
                        || settingsState == SettingStateValue.lockedRelease)
                         throw;
                oldE4 = _oldE4;
                oldE4RecycleBin = _oldE4Recyle;
        }

        // ----------------------------
        // get account info
        // ----------------------------
        function getAccountInfo(address _addr) constant returns(uint _tokens, uint _snapshot, uint _points)
        {
                _tokens = holderAccounts[_addr].tokens;
                _snapshot = holderAccounts[_addr].lastSnapshot;
                _points = holderAccounts[_addr].currentPoints;
        }


        // ----------------------------
        // DEBUG ONLY - end this contract, suicide to developers
        // ----------------------------
        function haraKiri()
        {
                if (settingsState != SettingStateValue.debug)
                        throw;
                if (msg.sender != owner)
                         throw;
                suicide(developers);
        }


        // ----------------------------
        // OPT IN FROM CLASSIC.
        // All old token holders can opt into this new contract by calling this function.
        // This "transferFrom"s tokens from the old addresses to the new recycleBin address
        // which is a new address set up on the old contract.  Afterwhich new tokens
        // are credited to the old holder.  Also the lastSnapShot is set to 0 then
        // calcCredited points are called setting up the new signatoree all of his
        // accrued dividends.
        // ----------------------------
        function optInFromClassic() public
        {
                if (oldE4 == address(0)) {
                        StatEvent("config err");
                        return;
                }
                // 1. check balance of msg.sender in old contract.
                address nrequester = msg.sender;

                // 2. make sure account not already allocd (in fact, it&#39;s ok if it&#39;s allocd, so long
                // as it is empty now. the reason for this check is cuz we are going to credit him with
                // dividends, according to his token count, from the begin of time.
                if (holderAccounts[nrequester].tokens != 0) {
                        StatEvent("Account has already has tokens!");
                        return;
                }

                // 3. check his tok balance
                Token iclassic = Token(oldE4);
                uint _toks = iclassic.balanceOf(nrequester);
                if (_toks == 0) {
                        StatEvent("Nothing to do");
                        return;
                }

                // must be 100 percent of holdings
                if (iclassic.allowance(nrequester, address(this)) < _toks) {
                        StatEvent("Please approve this contract to transfer");
                        return;
                }

                // 4. before we do the transfer, make sure that we have at least enough gas for the
                // transfer plus the remainder of this fcn.
                if (msg.gas < optInXferGas + optInFcnMinGas)
                        throw;

                // 5. transfer his old toks to recyle bin
                iclassic.transferFrom.gas(optInXferGas)(nrequester, oldE4RecycleBin, _toks);

                // todo, error check?
                if (iclassic.balanceOf(nrequester) == 0) {
                        // success, add the account, set the tokens, set snapshot to zero
                        if (!holderAccounts[nrequester].alloced)
                                addAccount(nrequester);
                        holderAccounts[nrequester].tokens = _toks * NewTokensPerOrigToken;
                        holderAccounts[nrequester].lastSnapshot = 0;
                        calcCurPointsForAcct(nrequester);
                        numToksSwitchedOver += _toks;
                        // no need to decrement points from a "holding account"
                        // b/c there is no need to keep it.
                        StatEvent("Success Switched Over");
                } else
                        StatEvent("Transfer Error! please contact Dev team!");


        }



}