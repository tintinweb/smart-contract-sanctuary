pragma solidity 0.4.21;
    
// -------------------- SAFE MATH ----------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

// ----------------------------------------------------------------------------
// Basic ERC20 functions
// ----------------------------------------------------------------------------
contract ERC20Interface {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public view returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

// ----------------------------------------------------------------------------
// Owned contract serves Owner and Admin rights.
// Owner is Admin by default and can set other Admin
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;
    address internal admin;

    // modifier for functions called by Owner
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    // modifier for functions called by Admin
    modifier onlyAdmin {
        require(msg.sender == admin || msg.sender == owner);
        _;
    }

    event OwnershipTransferred(address indexed _from, address indexed _to);
    event AdminChanged(address indexed _from, address indexed _to);

    // Constructor asigning msg.sender to Owner and Admin
    function Owned() public {
        owner = msg.sender;
        admin = msg.sender;
    }

    function setAdmin(address newAdmin) public onlyOwner{
        emit AdminChanged(admin, newAdmin);
        admin = newAdmin;
    }

    function showAdmin() public view onlyAdmin returns(address _admin){
        _admin = admin;
        return _admin;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


contract Redenom is ERC20Interface, Owned{
    using SafeMath for uint;
    
    //ERC20 params
    string      public name; // ERC20 
    string      public symbol; // ERC20 
    uint        public _totalSupply; // ERC20
    uint        public decimals = 8; // ERC20 


    //Redenomination
    uint public round = 1; 
    uint public iteration = 1; 

    uint[8] public dec =         [0,0,0,0,0,0,0,0];              // [0,1,2,3,4,5,6,7]
        //dec - contains sum of every exponent 
    uint[9] public mul =         [1,10,100,1000,10000,100000,1000000,10000000,100000000];              // [0,1,2,3,4,5,6,7,8]  return mul[round-1];
        //mul - internal used array for splitting numbers according to round
    uint[9] public weight  =            [uint(0),0,0,0,0,5,10,30,55];   // [0,1,2,3,4,5,6,7,8]
        //weight - internal used array (weights of every digit)    
    uint[9] public current_toadd =      [uint(0),0,0,0,0,0,0,0,0];      // [0,0,0,0,0,0,0,1,2]
    //current_toadd - After redenominate() it holds an amount to ad on each digit.


    uint public total_fund; // All funds for all iterations 1 000 000 NOM
    uint public iter_fund; // All funds for curent iteration 100 000 NOM
    uint public team_fund; // Team Fund 10% of all funds paid
    uint public dao_fund; // Dao Fund 30% of all funds paid


    struct Account {
        uint balance;
        uint lastRound; // Last round user obtained dividents
        uint lastVotedIter; // Last iteration user voted in
        uint bitmask; 
            // 2 - got 0.55... for phone verif.
            // 4 - got 1 for KYC
            // 1024 - banned
            //
            // [2] [4] 8 16 32 64 128 256 512 [1024] ... - free to use
    }
    
    mapping(address=>Account) accounts; 
    mapping(address => mapping(address => uint)) allowed;

    //Redenom special events
    event Redenomination(uint indexed round);
    event Iteration(uint indexed iteration);
    event VotingOn(address indexed initiator);
    event VotingOff(address indexed initiator);
    event Vote(address indexed voter, uint indexed propId, uint indexed voterBalance);

    function Redenom() public {
        symbol = &quot;NOM&quot;;
        name = &quot;Redenom&quot;;
        _totalSupply = 0; // total NOM&#39;s in the game 

        total_fund = 1000000 * 10**decimals; // 1 000 000.00000000, 1Mt
        iter_fund = 100000 * 10**decimals; // 100 000.00000000, 100 Kt
        total_fund = total_fund.sub(iter_fund); // Taking 100 Kt from total to iteration fund

    }




    // New iteration can be started if:
    // - Curent rount is 9
    // - Curen iteration < 10
    // - Voting is over
    function StartNewIteration() public onlyAdmin returns(bool succ){
        require(round == 9);
        require(iteration < 10);
        require(votingActive == false); 

        dec = [0,0,0,0,0,0,0,0];  
        round = 1;
        iteration++;

        iter_fund = 100000 * 10**decimals; // 100 000.00000000, 100 Kt
        total_fund = total_fund.sub(iter_fund); // Taking 100 Kt from total to iteration fund

        delete proposals;

        emit Iteration(iteration);
        return true;
    }




    ///////////////////////////////////////////B A L L O T////////////////////////////////////////////

    //Is voting active?
    bool public votingActive = false;

    // Voter has to:
    // - Not voted in this iteration
    // - Is not banned
    // - Approved KYC (bitmask 4)
    // - (OFF) Has >= 1 NOM
    modifier onlyVoter {
        require(votingActive == true);
        require(bitmask_check(msg.sender, 4) == true); //Approved KYC
        //require((accounts[msg.sender].balance >= 100000000), &quot;must have >= 1 NOM&quot;);
        require((accounts[msg.sender].lastVotedIter < iteration));
        require(bitmask_check(msg.sender, 1024) == false); // banned == false
        _;
    }


    // This is a type for a single proposal.
    struct Proposal {
        uint id;   // Proposal id
        uint votesWeight; // number of total votes weights
        bool active; //is the proposal active.
    }

    // A dynamically-sized array of `Proposal` structs.
    Proposal[] public proposals;

    // Add prop. with id: _id
    function addProposal(uint _id) public onlyAdmin {
        proposals.push(Proposal({
            id: _id,
            votesWeight: 0,
            active: true
        }));
    }

    // Turns proposal ON and OFF
    function swapProposal(uint _id) public onlyAdmin {//TODO view??
        for (uint p = 0; p < proposals.length; p++){
            if(proposals[p].id == _id){
                if(proposals[p].active == true){
                    proposals[p].active = false;
                }else{
                    proposals[p].active = true;
                }
            }
        }
    }

    // Returns prop. weight
    function proposalWeight(uint _id) public constant returns(uint PW){
        for (uint p = 0; p < proposals.length; p++){
            if(proposals[p].id == _id){
                return proposals[p].votesWeight;
            }
        }
    }

    // Returns prop. status
    function proposalActive(uint _id) public constant returns(bool PA){
        for (uint p = 0; p < proposals.length; p++){
            if(proposals[p].id == _id){
                return proposals[p].active;
            }
        }
    }

    // Vote for prop. with id: _id
    function vote(uint _id) public onlyVoter returns(bool success){
        //todo updateAccount
        for (uint p = 0; p < proposals.length; p++){
            if(proposals[p].id == _id && proposals[p].active == true){
                proposals[p].votesWeight += sqrt(accounts[msg.sender].balance);
                accounts[msg.sender].lastVotedIter = iteration;
            }
        }
        emit Vote(msg.sender, _id, accounts[msg.sender].balance);
        return true;
    }

    // Shows currently winning prop 
    function winningProposal() public constant returns (uint _winningProposal){
        uint winningVoteWeight = 0;
        for (uint p = 0; p < proposals.length; p++) {
            if (proposals[p].votesWeight > winningVoteWeight && proposals[p].active == true) {
                winningVoteWeight = proposals[p].votesWeight;
                _winningProposal = proposals[p].id;
            }
        }
    }

    // Activates voting
    // requires round = 9
    function enableVoting() public onlyAdmin returns(bool succ){ 
        require(votingActive == false);
        require(round == 9);
        votingActive = true;

        emit VotingOn(msg.sender);
        return true;


    }

    // Deactivates voting
    function disableVoting() public onlyAdmin returns(bool succ){
        require(votingActive == true);
        votingActive = false;

        emit VotingOff(msg.sender);
        return true;
    }

    // sqrt root func
    function sqrt(uint x)internal pure returns (uint y) {
        uint z = (x + 1) / 2;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }

    ///////////////////////////////////////////B A L L O T////////////////////////////////////////////




    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    // NOM token emission functions
    ///////////////////////////////////////////////////////////////////////////////////////////////////////

    // Pays 1.00000000 from iter_fund to KYC user
    // Uses payout(), bitmask_check(), bitmask_add()
    // adds 4 to bitmask
    function pay1(address to) public onlyAdmin returns(bool success){
        require(bitmask_check(to, 4) == false);
        uint new_amount = 100000000;
        payout(to,new_amount);
        bitmask_add(to, 4);
        return true;
    }

    // Pays .555666XX from iter_fund to user approved phone;
    // Uses payout(), bitmask_check(), bitmask_add()
    // adds 2 to bitmask
    function pay055(address to) public onlyAdmin returns(bool success){
        require(bitmask_check(to, 2) == false);
        uint new_amount = 55566600 + (block.timestamp%100);       
        payout(to,new_amount);
        bitmask_add(to, 2);
        return true;
    }

    // Pays .555666XX from iter_fund to KYC user in new epoch;
    // Uses payout(), bitmask_check(), bitmask_add()
    // adds 2 to bitmask
    function pay055loyal(address to) public onlyAdmin returns(bool success){
        require(iteration > 1);
        require(bitmask_check(to, 4) == true);
        uint new_amount = 55566600 + (block.timestamp%100);       
        payout(to,new_amount);
        return true;
    }

    // Pays random number from iter_fund
    // Uses payout()
    function payCustom(address to, uint amount) public onlyAdmin returns(bool success){
        payout(to,amount);
        return true;
    }

    // Pays [amount] of money to [to] account from iter_fund
    // Counts amount +30% +10%
    // Takes all from iter_fund
    // Adding all to _totalSupply
    // Pays to ballance and 2 funds
    // Refreshes dec[]
    // Emits event
    function payout(address to, uint amount) private returns (bool success){
        require(to != address(0));
        require(amount>=curent_mul());
        require(bitmask_check(to, 1024) == false); // banned == false
        
        //Update account balance
        updateAccount(to);
        //fix amount
        uint fixedAmount = fix_amount(amount);

        renewDec( accounts[to].balance, accounts[to].balance.add(fixedAmount) );

        uint team_part = (fixedAmount/100)*10;
        uint dao_part = (fixedAmount/100)*30;
        uint total = fixedAmount.add(team_part).add(dao_part);

        iter_fund = iter_fund.sub(total);
        team_fund = team_fund.add(team_part);
        dao_fund = dao_fund.add(dao_part);
        accounts[to].balance = accounts[to].balance.add(fixedAmount);
        _totalSupply = _totalSupply.add(total);

        emit Transfer(address(0), to, fixedAmount);
        return true;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////////




    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    // Fund withdrawal functions
    ///////////////////////////////////////////////////////////////////////////////////////////////////////

    // Withdraw team_fund to given address
    function withdraw_team_fund(address to) public onlyOwner returns(bool success){
        accounts[to].balance = accounts[to].balance.add(team_fund);
        team_fund = 0;
        return true;
    }
    // Withdraw dao_fund to given address
    function withdraw_dao_fund(address to) public onlyOwner returns(bool success){
        accounts[to].balance = accounts[to].balance.add(dao_fund);
        dao_fund = 0;
        return true;
    }

    ///////////////////////////////////////////////////////////////////////////////////////////////////////


    // Run this on every change of user ballance
    // Refreshes dec[] array
    // Takes initial and new ammount
    // while transaction must be called for each acc.
    function renewDec(uint initSum, uint newSum) internal returns(bool success){

        if(round < 9){
            uint tempInitSum = initSum; 
            uint tempNewSum = newSum; 
            uint cnt = 1;

            while( (tempNewSum > 0 || tempInitSum > 0) && cnt <= decimals ){

                uint lastInitSum = tempInitSum%10; // 0.0000000 (0)
                tempInitSum = tempInitSum/10; // (0.0000000) 0

                uint lastNewSum = tempNewSum%10; // 1.5556664 (5)
                tempNewSum = tempNewSum/10; // (1.5556664) 5

                if(cnt >= round){
                    if(lastNewSum >= lastInitSum){
                        // If new is bigger
                        dec[decimals-cnt] = dec[decimals-cnt].add(lastNewSum - lastInitSum);
                    }else{
                        // If new is smaller
                        dec[decimals-cnt] = dec[decimals-cnt].sub(lastInitSum - lastNewSum);
                    }
                }

                cnt = cnt+1;
            }
        }//if(round < 9){

        return true;
    }



    ////////////////////////////////////////// BITMASK /////////////////////////////////////////////////////
    // Adding bit to bitmask
    // checks if already set
    function bitmask_add(address user, uint _bit) internal returns(bool success){ //todo privat?
        require(bitmask_check(user, _bit) == false);
        accounts[user].bitmask = accounts[user].bitmask.add(_bit);
        return true;
    }
    // Removes bit from bitmask
    // checks if already set
    function bitmask_rm(address user, uint _bit) internal returns(bool success){
        require(bitmask_check(user, _bit) == true);
        accounts[user].bitmask = accounts[user].bitmask.sub(_bit);
        return true;
    }
    // Shows whole users bitmask
    function bitmask_show(address user) internal view returns(uint _bitmask){
        return accounts[user].bitmask;
    }
    // Checks whether some bit is present in BM
    function bitmask_check(address user, uint _bit) internal view returns (bool status){
        bool flag;
        accounts[user].bitmask & _bit == 0 ? flag = false : flag = true;
        return flag;
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////////

    function ban_user(address user) public onlyAdmin returns(bool success){
        bitmask_add(user, 1024);
        return true;
    }
    function unban_user(address user) public onlyAdmin returns(bool success){
        bitmask_rm(user, 1024);
        return true;
    }
    function is_banned(address user) public view onlyAdmin returns (bool result){
        return bitmask_check(user, 1024);
    }
    ///////////////////////////////////////////////////////////////////////////////////////////////////////



    //Redenominates 
    function redenominate() public onlyAdmin returns(uint current_round){
        require(round<9); // Round must be < 9

        // Deleting funds rest from TS
        _totalSupply = _totalSupply.sub( team_fund%mul[round] ).sub( dao_fund%mul[round] ).sub( dec[8-round]*mul[round-1] );

        // Redenominating 3 vars: _totalSupply team_fund dao_fund
        _totalSupply = ( _totalSupply / mul[round] ) * mul[round];
        team_fund = ( team_fund / mul[round] ) * mul[round]; // Redenominates team_fund
        dao_fund = ( dao_fund / mul[round] ) * mul[round]; // Redenominates dao_fund

        if(round>1){
            // Taking decimals burned in last round and not distributed
            uint superold = dec[(8-round)+1]; 

            // Returning them to iter_fund
            iter_fund = iter_fund.add(superold * mul[round-2]);
            dec[(8-round)+1] = 0;
        }

        
        if(round<8){ // if round between 1 and 7 

            uint unclimed = dec[8-round]; // total sum of burned decimal
            //[23,32,43,34,34,54,34, ->46<- ]
            uint total_current = dec[8-1-round]; // total sum of last active decimal
            //[23,32,43,34,34,54, ->34<-, 46]

            // current_toadd - this array will contain an ammount to add on each digit
            // example: [0,0,0,0,0,1,2,3] means, 9 gets +3, and 8 gets +2 s.o.

            // If nobody has digit on curent active decimals-cnt
            if(total_current==0){
                current_toadd = [0,0,0,0,0,0,0,0,0]; 
                round++;
                return round;
            }

            // Counting amounts to add on all digits
            uint[9] memory numbers  =[uint(1),2,3,4,5,6,7,8,9]; // 
            uint[9] memory ke9  =[uint(0),0,0,0,0,0,0,0,0]; // 
            uint[9] memory k2e9  =[uint(0),0,0,0,0,0,0,0,0]; // 

            uint k05summ = 0;

                for (uint k = 0; k < ke9.length; k++) {
                     
                    ke9[k] = numbers[k]*1e9/total_current;
                    if(k<5) k05summ += ke9[k];
                }             
                for (uint k2 = 5; k2 < k2e9.length; k2++) {
                    k2e9[k2] = uint(ke9[k2])+uint(k05summ)*uint(weight[k2])/uint(100);
                }
                for (uint n = 5; n < current_toadd.length; n++) {
                    current_toadd[n] = k2e9[n]*unclimed/10/1e9;
                }
                // current_toadd now contains all digits
                
        }else{
            if(round==8){
                // Returns last burned decimals to iter_fund
                iter_fund = iter_fund.add(dec[0] * 10000000); //1e7
                dec[0] = 0;
            }
            
        }

        round++;
        emit Redenomination(round);
        return round;
    }

   
    // Refresh user acc
    // Pays dividents if any
    function updateAccount(address account) public returns(uint new_balance){
        require(round<=9);
        require(bitmask_check(account, 1024) == false); // banned == false

        if(round > accounts[account].lastRound){

            if(round >1 && round <=8){


                // Splits user bal by curent multiplier
                uint tempDividedBalance = accounts[account].balance/curent_mul();
                // [1.5556663] 4  (r2)
                uint newFixedBallance = tempDividedBalance*curent_mul();
                // [1.55566630]  (r2)
                uint lastActiveDigit = tempDividedBalance%10;
                 // 1.555666 [3] 4  (r2)
                uint diff = accounts[account].balance - newFixedBallance;
                // 1.5556663 [4] (r2)

                if(diff > 0){
                    accounts[account].balance = newFixedBallance;
                    emit Transfer(account, address(0), diff);
                }

                uint toBalance = 0;
                if(lastActiveDigit>0 && current_toadd[lastActiveDigit-1]>0){
                    toBalance = current_toadd[lastActiveDigit-1] * curent_mul();
                }


                if(toBalance > 0 && toBalance < dec[8-round+1]){ // Not enough

                    renewDec( accounts[account].balance, accounts[account].balance.add(toBalance) );
                    emit Transfer(address(0), account, toBalance);
                    // Renewind dec arr
                    accounts[account].balance = accounts[account].balance.add(toBalance);
                    // Adding to ball
                    dec[8-round+1] = dec[8-round+1].sub(toBalance);
                    // Taking from burned decimal
                    _totalSupply = _totalSupply.add(toBalance);
                    // Add divident to _totalSupply
                }

                accounts[account].lastRound = round;
                // Writting last round in wich user got dividents
                return accounts[account].balance;
                // returns new ballance
            }else{
                if( round == 9){ //100000000 = 9 mul (mul8)

                    uint newBalance = fix_amount(accounts[account].balance);
                    uint _diff = accounts[account].balance.sub(newBalance);

                    if(_diff > 0){
                        renewDec( accounts[account].balance, newBalance );
                        accounts[account].balance = newBalance;
                        emit Transfer(account, address(0), _diff);
                    }

                    accounts[account].lastRound = round;
                    // Writting last round in wich user got dividents
                    return accounts[account].balance;
                    // returns new ballance
                }
            }
        }
    }

    // Returns curent multipl. based on round
    // Returns curent multiplier based on round
    function curent_mul() public view returns(uint _curent_mul){
        return mul[round-1];
    }
    // Removes burned values 123 -> 120  
    // Returns fixed
    function fix_amount(uint amount) public view returns(uint fixed_amount){
        return ( amount / curent_mul() ) * curent_mul();
    }
    // Returns rest
    function get_rest(uint amount) public view returns(uint fixed_amount){
        return amount % curent_mul();
    }



    // ------------------------------------------------------------------------
    // ERC20 totalSupply: 
    //-------------------------------------------------------------------------
    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }
    // ------------------------------------------------------------------------
    // ERC20 balanceOf: Get the token balance for account `tokenOwner`
    // ------------------------------------------------------------------------
    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return accounts[tokenOwner].balance;
    }
    // ------------------------------------------------------------------------
    // ERC20 allowance:
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender&#39;s account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    // ------------------------------------------------------------------------
    // ERC20 transfer:
    // Transfer the balance from token owner&#39;s account to `to` account
    // - Owner&#39;s account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint tokens) public returns (bool success) {
        require(to != address(0));
        require(bitmask_check(to, 1024) == false); // banned == false

        //Fixing amount, deleting burned decimals
        tokens = fix_amount(tokens);
        // Checking if greater then 0
        require(tokens>0);

        //Refreshing accs, payng dividents
        updateAccount(to);
        updateAccount(msg.sender);

        uint fromOldBal = accounts[msg.sender].balance;
        uint toOldBal = accounts[to].balance;

        accounts[msg.sender].balance = accounts[msg.sender].balance.sub(tokens);
        accounts[to].balance = accounts[to].balance.add(tokens);

        require(renewDec(fromOldBal, accounts[msg.sender].balance));
        require(renewDec(toOldBal, accounts[to].balance));

        emit Transfer(msg.sender, to, tokens);
        return true;
    }


    // ------------------------------------------------------------------------
    // ERC20 approve:
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public returns (bool success) {
        require(bitmask_check(msg.sender, 1024) == false); // banned == false
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    // ------------------------------------------------------------------------
    // ERC20 transferFrom:
    // Transfer `tokens` from the `from` account to the `to` account
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from the `from` account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(bitmask_check(to, 1024) == false); // banned == false
        updateAccount(from);
        updateAccount(to);

        uint fromOldBal = accounts[from].balance;
        uint toOldBal = accounts[to].balance;

        accounts[from].balance = accounts[from].balance.sub(tokens);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(tokens);
        accounts[to].balance = accounts[to].balance.add(tokens);

        require(renewDec(fromOldBal, accounts[from].balance));
        require(renewDec(toOldBal, accounts[to].balance));

        emit Transfer(from, to, tokens);
        return true; 
    }
    // ------------------------------------------------------------------------
    // Token owner can approve for `spender` to transferFrom(...) `tokens`
    // from the token owner&#39;s account. The `spender` contract function
    // `receiveApproval(...)` is then executed
    // ------------------------------------------------------------------------
    function approveAndCall(address spender, uint tokens, bytes data) public returns (bool success) {
        require(bitmask_check(msg.sender, 1024) == false); // banned == false
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    }
    // ------------------------------------------------------------------------
    // Don&#39;t accept ETH https://github.com/ConsenSys/Ethereum-Development-Best-Practices/wiki/Fallback-functions-and-the-fundamental-limitations-of-using-send()-in-Ethereum-&-Solidity
    // ------------------------------------------------------------------------
    function () public payable {
        revert();
    } // OR function() payable { } to accept ETH 

    // ------------------------------------------------------------------------
    // Owner can transfer out any accidentally sent ERC20 tokens
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }




} // Redenom by Musqogee