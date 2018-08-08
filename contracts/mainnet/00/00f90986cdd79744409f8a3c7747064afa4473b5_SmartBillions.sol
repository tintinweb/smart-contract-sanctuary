pragma solidity ^0.4.13;

library SafeMath {
  function sub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20Basic {
  uint public totalSupply;
  address public owner; //owner
  address public animator; //animator
  function balanceOf(address who) constant returns (uint);
  function transfer(address to, uint value);
  event Transfer(address indexed from, address indexed to, uint value);
  function commitDividend(address who) internal; // pays remaining dividend
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) constant returns (uint);
  function transferFrom(address from, address to, uint value);
  function approve(address spender, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint;
  mapping(address => uint) balances;

  modifier onlyPayloadSize(uint size) {
     assert(msg.data.length >= size + 4);
     _;
  }
  /**
  * @dev transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint _value) onlyPayloadSize(2 * 32) {
    commitDividend(msg.sender);
    balances[msg.sender] = balances[msg.sender].sub(_value);
    if(_to == address(this)) {
        commitDividend(owner);
        balances[owner] = balances[owner].add(_value);
        Transfer(msg.sender, owner, _value);
    }
    else {
        commitDividend(_to);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
    }
  }
  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of. 
  * @return An uint representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) constant returns (uint balance) {
    return balances[_owner];
  }
}

contract StandardToken is BasicToken, ERC20 {
  mapping (address => mapping (address => uint)) allowed;

  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint the amout of tokens to be transfered
   */
  function transferFrom(address _from, address _to, uint _value) onlyPayloadSize(3 * 32) {
    var _allowance = allowed[_from][msg.sender];
    commitDividend(_from);
    commitDividend(_to);
    balances[_to] = balances[_to].add(_value);
    balances[_from] = balances[_from].sub(_value);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    Transfer(_from, _to, _value);
  }
  /**
   * @dev Aprove the passed address to spend the specified amount of tokens on beahlf of msg.sender.
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint _value) {
    //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    assert(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
  }
  /**
   * @dev Function to check the amount of tokens than an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint specifing the amount of tokens still avaible for the spender.
   */
  function allowance(address _owner, address _spender) constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

/**
 * @title SmartBillions contract
 */
contract SmartBillions is StandardToken {

    // metadata
    string public constant name = "SmartBillions Token";
    string public constant symbol = "PLAY";
    uint public constant decimals = 0;

    // contract state
    struct Wallet {
        uint208 balance; // current balance of user
    	uint16 lastDividendPeriod; // last processed dividend period of user&#39;s tokens
    	uint32 nextWithdrawBlock; // next withdrawal possible after this block number
    }
    mapping (address => Wallet) wallets;
    struct Bet {
        uint192 value; // bet size
        uint32 betHash; // selected numbers
        uint32 blockNum; // blocknumber when lottery runs
    }
    mapping (address => Bet) bets;

    uint public walletBalance = 0; // sum of funds in wallets

    // investment parameters
    uint public investStart = 1; // investment start block, 0: closed, 1: preparation
    uint public investBalance = 0; // funding from investors
    uint public investBalanceMax = 200000 ether; // maximum funding
    uint public dividendPeriod = 1;
    uint[] public dividends; // dividens collected per period, growing array

    // betting parameters
    uint public maxWin = 0; // maximum prize won
    uint public hashFirst = 0; // start time of building hashes database
    uint public hashLast = 0; // last saved block of hashes
    uint public hashNext = 0; // next available bet block.number
    uint public hashBetSum = 0; // used bet volume of next block
    uint public hashBetMax = 5 ether; // maximum bet size per block
    uint[] public hashes; // space for storing lottery results

    // constants
    //uint public constant hashesSize = 1024 ; // DEBUG ONLY !!!
    uint public constant hashesSize = 16384 ; // 30 days of blocks
    uint public coldStoreLast = 0 ; // block of last cold store transfer

    // events
    event LogBet(address indexed player, uint bethash, uint blocknumber, uint betsize);
    event LogLoss(address indexed player, uint bethash, uint hash);
    event LogWin(address indexed player, uint bethash, uint hash, uint prize);
    event LogInvestment(address indexed investor, address indexed partner, uint amount);
    event LogRecordWin(address indexed player, uint amount);
    event LogLate(address indexed player,uint playerBlockNumber,uint currentBlockNumber);
    //event LogWithdraw(address indexed who, uint amount);

    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }

    modifier onlyAnimator() {
        assert(msg.sender == animator);
        _;
    }

    // constructor
    function SmartBillions() {
        owner = msg.sender;
        animator = msg.sender;
        wallets[owner].lastDividendPeriod = uint16(dividendPeriod);
        //wallets[animator].lastDividendPeriod = uint16(dividendPeriod);
        dividends.push(0); // not used
        dividends.push(0); // current dividend
    }

/* getters */
    
    /**
     * @dev Show length of allocated swap space
     */
    function hashesLength() constant external returns (uint) {
        return uint(hashes.length);
    }
    
    /**
     * @dev Show balance of wallet
     * @param _owner The address of the account.
     */
    function walletBalanceOf(address _owner) constant external returns (uint) {
        return uint(wallets[_owner].balance);
    }
    
    /**
     * @dev Show last dividend period processed
     * @param _owner The address of the account.
     */
    function walletPeriodOf(address _owner) constant external returns (uint) {
        return uint(wallets[_owner].lastDividendPeriod);
    }
    
    /**
     * @dev Show block number when withdraw can continue
     * @param _owner The address of the account.
     */
    function walletBlockOf(address _owner) constant external returns (uint) {
        return uint(wallets[_owner].nextWithdrawBlock);
    }
    
    /**
     * @dev Show bet size.
     * @param _owner The address of the player.
     */
    function betValueOf(address _owner) constant external returns (uint) {
        return uint(bets[_owner].value);
    }
    
    /**
     * @dev Show block number of lottery run for the bet.
     * @param _owner The address of the player.
     */
    function betHashOf(address _owner) constant external returns (uint) {
        return uint(bets[_owner].betHash);
    }
    
    /**
     * @dev Show block number of lottery run for the bet.
     * @param _owner The address of the player.
     */
    function betBlockNumberOf(address _owner) constant external returns (uint) {
        return uint(bets[_owner].blockNum);
    }
    
    /**
     * @dev Print number of block till next expected dividend payment
     */
    function dividendsBlocks() constant external returns (uint) {
        if(investStart > 0) {
            return(0);
        }
        uint period = (block.number - hashFirst) / (10 * hashesSize);
        if(period > dividendPeriod) {
            return(0);
        }
        return((10 * hashesSize) - ((block.number - hashFirst) % (10 * hashesSize)));
    }

/* administrative functions */

    /**
     * @dev Change owner.
     * @param _who The address of new owner.
     */
    function changeOwner(address _who) external onlyOwner {
        assert(_who != address(0));
        commitDividend(msg.sender);
        commitDividend(_who);
        owner = _who;
    }

    /**
     * @dev Change animator.
     * @param _who The address of new animator.
     */
    function changeAnimator(address _who) external onlyAnimator {
        assert(_who != address(0));
        commitDividend(msg.sender);
        commitDividend(_who);
        animator = _who;
    }

    /**
     * @dev Set ICO Start block.
     * @param _when The block number of the ICO.
     */
    function setInvestStart(uint _when) external onlyOwner {
        require(investStart == 1 && hashFirst > 0 && block.number < _when);
        investStart = _when;
    }

    /**
     * @dev Set maximum bet size per block
     * @param _maxsum The maximum bet size in wei.
     */
    function setBetMax(uint _maxsum) external onlyOwner {
        hashBetMax = _maxsum;
    }

    /**
     * @dev Reset bet size accounting, to increase bet volume above safe limits
     */
    function resetBet() external onlyOwner {
        hashNext = block.number + 3;
        hashBetSum = 0;
    }

    /**
     * @dev Move funds to cold storage
     * @dev investBalance and walletBalance is protected from withdraw by owner
     * @dev if funding is > 50% admin can withdraw only 0.25% of balance weakly
     * @param _amount The amount of wei to move to cold storage
     */
    function coldStore(uint _amount) external onlyOwner {
        houseKeeping();
        require(_amount > 0 && this.balance >= (investBalance * 9 / 10) + walletBalance + _amount);
        if(investBalance >= investBalanceMax / 2){ // additional jackpot protection
            require((_amount <= this.balance / 400) && coldStoreLast + 4 * 60 * 24 * 7 <= block.number);
        }
        msg.sender.transfer(_amount);
        coldStoreLast = block.number;
    }

    /**
     * @dev Move funds to contract
     */
    function hotStore() payable external { // not needed because jackpot is protected
        houseKeeping();
    }

/* housekeeping functions */

    /**
     * @dev Update accounting
     */
    function houseKeeping() public {
        if(investStart > 1 && block.number >= investStart + (hashesSize * 5)){ // ca. 14 days
            investStart = 0; // start dividend payments
        }
        else {
            if(hashFirst > 0){
		        uint period = (block.number - hashFirst) / (10 * hashesSize );
                if(period > dividends.length - 2) {
                    dividends.push(0);
                }
                if(period > dividendPeriod && investStart == 0 && dividendPeriod < dividends.length - 1) {
                    dividendPeriod++;
                }
            }
        }
    }

/* payments */

    /**
     * @dev Pay balance from wallet
     */
    function payWallet() public {
        if(wallets[msg.sender].balance > 0 && wallets[msg.sender].nextWithdrawBlock <= block.number){
            uint balance = wallets[msg.sender].balance;
            wallets[msg.sender].balance = 0;
            walletBalance -= balance;
            pay(balance);
            //LogWithdraw(msg.sender,balance);
        }
    }

    function pay(uint _amount) private {
        uint maxpay = this.balance / 2;
        if(maxpay >= _amount) {
            msg.sender.transfer(_amount);
            if(_amount > 1 finney) {
                houseKeeping();
            }
        }
        else {
            uint keepbalance = _amount - maxpay;
            walletBalance += keepbalance;
            wallets[msg.sender].balance += uint208(keepbalance);
            wallets[msg.sender].nextWithdrawBlock = uint32(block.number + 4 * 60 * 24 * 30); // wait 1 month for more funds
            msg.sender.transfer(maxpay);
        }
    }

/* investment functions */

    /**
     * @dev Buy tokens
     */
    function investDirect() payable external {
        invest(owner);
    }

    /**
     * @dev Buy tokens with affiliate partner
     * @param _partner Affiliate partner
     */
    function invest(address _partner) payable public {
        //require(fromUSA()==false); // fromUSA() not yet implemented :-(
        require(investStart > 1 && block.number < investStart + (hashesSize * 5) && investBalance < investBalanceMax);
        uint investing = msg.value;
        if(investing > investBalanceMax - investBalance) {
            investing = investBalanceMax - investBalance;
            investBalance = investBalanceMax;
            investStart = 0; // close investment round
            msg.sender.transfer(msg.value.sub(investing)); // send back funds immediately
        }
        else{
            investBalance += investing;
        }
        if(_partner == address(0) || _partner == owner){
            walletBalance += investing / 10;
            wallets[owner].balance += uint208(investing / 10);} // 10% for marketing if no affiliates
        else{
            walletBalance += (investing * 5 / 100) * 2;
            wallets[owner].balance += uint208(investing * 5 / 100); // 5% initial marketing funds
            //wallets[_partner].lastDividendPeriod = uint16(dividendPeriod); // assert(dividendPeriod == 1);
            wallets[_partner].balance += uint208(investing * 5 / 100);} // 5% for affiliates
        wallets[msg.sender].lastDividendPeriod = uint16(dividendPeriod); // assert(dividendPeriod == 1);
        uint senderBalance = investing / 10**15;
        uint ownerBalance = investing * 16 / 10**17  ;
        uint animatorBalance = investing * 10 / 10**17  ;
        balances[msg.sender] += senderBalance;
        balances[owner] += ownerBalance ; // 13% of shares go to developers
        balances[animator] += animatorBalance ; // 8% of shares go to animator
        totalSupply += senderBalance + ownerBalance + animatorBalance;
        Transfer(address(0),msg.sender,senderBalance); // for etherscan
        Transfer(address(0),owner,ownerBalance); // for etherscan
        Transfer(address(0),animator,animatorBalance); // for etherscan
        LogInvestment(msg.sender,_partner,investing);
    }

    /**
     * @dev Delete all tokens owned by sender and return unpaid dividends and 90% of initial investment
     */
    function disinvest() external {
        require(investStart == 0);
        commitDividend(msg.sender);
        uint initialInvestment = balances[msg.sender] * 10**15;
        Transfer(msg.sender,address(0),balances[msg.sender]); // for etherscan
        delete balances[msg.sender]; // totalSupply stays the same, investBalance is reduced
        investBalance -= initialInvestment;
        wallets[msg.sender].balance += uint208(initialInvestment * 9 / 10);
        payWallet();
    }

    /**
     * @dev Pay unpaid dividends
     */
    function payDividends() external {
        require(investStart == 0);
        commitDividend(msg.sender);
        payWallet();
    }

    /**
     * @dev Commit remaining dividends before transfer of tokens
     */
    function commitDividend(address _who) internal {
        uint last = wallets[_who].lastDividendPeriod;
        if((balances[_who]==0) || (last==0)){
            wallets[_who].lastDividendPeriod=uint16(dividendPeriod);
            return;
        }
        if(last==dividendPeriod) {
            return;
        }
        uint share = balances[_who] * 0xffffffff / totalSupply;
        uint balance = 0;
        for(;last<dividendPeriod;last++) {
            balance += share * dividends[last];
        }
        balance = (balance / 0xffffffff);
        walletBalance += balance;
        wallets[_who].balance += uint208(balance);
        wallets[_who].lastDividendPeriod = uint16(last);
    }

/* lottery functions */

    function betPrize(Bet _player, uint24 _hash) constant private returns (uint) { // house fee 13.85%
        uint24 bethash = uint24(_player.betHash);
        uint24 hit = bethash ^ _hash;
        uint24 matches =
            ((hit & 0xF) == 0 ? 1 : 0 ) +
            ((hit & 0xF0) == 0 ? 1 : 0 ) +
            ((hit & 0xF00) == 0 ? 1 : 0 ) +
            ((hit & 0xF000) == 0 ? 1 : 0 ) +
            ((hit & 0xF0000) == 0 ? 1 : 0 ) +
            ((hit & 0xF00000) == 0 ? 1 : 0 );
        if(matches == 6){
            return(uint(_player.value) * 7000000);
        }
        if(matches == 5){
            return(uint(_player.value) * 20000);
        }
        if(matches == 4){
            return(uint(_player.value) * 500);
        }
        if(matches == 3){
            return(uint(_player.value) * 25);
        }
        if(matches == 2){
            return(uint(_player.value) * 3);
        }
        return(0);
    }
    
    /**
     * @dev Check if won in lottery
     */
    function betOf(address _who) constant external returns (uint)  {
        Bet memory player = bets[_who];
        if( (player.value==0) ||
            (player.blockNum<=1) ||
            (block.number<player.blockNum) ||
            (block.number>=player.blockNum + (10 * hashesSize))){
            return(0);
        }
        if(block.number<player.blockNum+256){
            return(betPrize(player,uint24(block.blockhash(player.blockNum))));
        }
        if(hashFirst>0){
            uint32 hash = getHash(player.blockNum);
            if(hash == 0x1000000) { // load hash failed :-(, return funds
                return(uint(player.value));
            }
            else{
                return(betPrize(player,uint24(hash)));
            }
	}
        return(0);
    }

    /**
     * @dev Check if won in lottery
     */
    function won() public {
        Bet memory player = bets[msg.sender];
        if(player.blockNum==0){ // create a new player
            bets[msg.sender] = Bet({value: 0, betHash: 0, blockNum: 1});
            return;
        }
        if((player.value==0) || (player.blockNum==1)){
            payWallet();
            return;
        }
        require(block.number>player.blockNum); // if there is an active bet, throw()
        if(player.blockNum + (10 * hashesSize) <= block.number){ // last bet too long ago, lost !
            LogLate(msg.sender,player.blockNum,block.number);
            bets[msg.sender] = Bet({value: 0, betHash: 0, blockNum: 1});
            return;
        }
        uint prize = 0;
        uint32 hash = 0;
        if(block.number<player.blockNum+256){
            hash = uint24(block.blockhash(player.blockNum));
            prize = betPrize(player,uint24(hash));
        }
        else {
            if(hashFirst>0){ // lottery is open even before swap space (hashes) is ready, but player must collect results within 256 blocks after run
                hash = getHash(player.blockNum);
                if(hash == 0x1000000) { // load hash failed :-(, return funds
                    prize = uint(player.value);
                }
                else{
                    prize = betPrize(player,uint24(hash));
                }
	    }
            else{
                LogLate(msg.sender,player.blockNum,block.number);
                bets[msg.sender] = Bet({value: 0, betHash: 0, blockNum: 1});
                return();
            }
        }
        bets[msg.sender] = Bet({value: 0, betHash: 0, blockNum: 1});
        if(prize>0) {
            LogWin(msg.sender,uint(player.betHash),uint(hash),prize);
            if(prize > maxWin){
                maxWin = prize;
                LogRecordWin(msg.sender,prize);
            }
            pay(prize);
        }
        else{
            LogLoss(msg.sender,uint(player.betHash),uint(hash));
        }
    }

    /**
     * @dev Send less than 1 ether to contract to play or send 0 to retrieve funds
     */
    function () payable external {
        if(msg.value > 0){
            play();
            return;
        }
        //check for dividends and other assets
        if(investStart == 0 && balances[msg.sender]>0){
            commitDividend(msg.sender);}
        won(); // will run payWallet() if nothing else available
    }

    /**
     * @dev Play in lottery
     */
    function play() payable public returns (uint) {
        return playSystem(uint(sha3(msg.sender,block.number)), address(0));
    }

    /**
     * @dev Play in lottery with random numbers
     * @param _partner Affiliate partner
     */
    function playRandom(address _partner) payable public returns (uint) {
        return playSystem(uint(sha3(msg.sender,block.number)), _partner);
    }

    //function playSystem(uint8 num1, uint8 num2, uint8 num3, address _partner) payable public returns (uint) {
    //    return playHash(uint24(num1)|(uint24(num2)<<8)|(uint24(num3)<<16), _partner);
    //}
    
    /**
     * @dev Play in lottery with own numbers
     * @param _partner Affiliate partner
     */
    function playSystem(uint _hash, address _partner) payable public returns (uint) {
        won(); // check if player did not win 
        uint24 bethash = uint24(_hash);
        require(msg.value <= 1 ether && msg.value < hashBetMax);
        if(msg.value > 0){
            if(investStart==0) { // dividends only after investment finished
                dividends[dividendPeriod] += msg.value / 34; // 3% dividend
            }
            if(_partner != address(0)) {
                uint fee = msg.value / 100;
                walletBalance += fee;
                wallets[_partner].balance += uint208(fee); // 1% for affiliates
            }
            if(hashNext < block.number + 3) {
                hashNext = block.number + 3;
                hashBetSum = msg.value;
            }
            else{
                if(hashBetSum > hashBetMax) {
                    hashNext++;
                    hashBetSum = msg.value;
                }
                else{
                    hashBetSum += msg.value;
                }
            }
            bets[msg.sender] = Bet({value: uint192(msg.value), betHash: uint32(bethash), blockNum: uint32(hashNext)});
            LogBet(msg.sender,uint(bethash),hashNext,msg.value);
        }
        putHash(); // players help collecing data
        return(hashNext);
    }

/* database functions */

    /**
     * @dev Create hash data swap space
     * @param _sadd Number of hashes to add (<=256)
     */
    function addHashes(uint _sadd) public returns (uint) {
        require(hashes.length + _sadd<=hashesSize);
        uint n = hashes.length;
        hashes.length += _sadd;
        for(;n<hashes.length;n++){ // make sure to burn gas
            hashes[n] = 1;
        }
        if(hashes.length>=hashesSize) { // assume block.number > 10
            hashFirst = block.number - ( block.number % 10);
            hashLast = hashFirst;
        }
        return(hashes.length);
    }

    /**
     * @dev Create hash data swap space, add 128 hashes
     */
    function addHashes128() external returns (uint) {
        return(addHashes(128));
    }

    function calcHashes(uint32 _lastb, uint32 _delta) constant private returns (uint) {
        return( ( uint(block.blockhash(_lastb  )) & 0xFFFFFF )
            | ( ( uint(block.blockhash(_lastb+1)) & 0xFFFFFF ) << 24 )
            | ( ( uint(block.blockhash(_lastb+2)) & 0xFFFFFF ) << 48 )
            | ( ( uint(block.blockhash(_lastb+3)) & 0xFFFFFF ) << 72 )
            | ( ( uint(block.blockhash(_lastb+4)) & 0xFFFFFF ) << 96 )
            | ( ( uint(block.blockhash(_lastb+5)) & 0xFFFFFF ) << 120 )
            | ( ( uint(block.blockhash(_lastb+6)) & 0xFFFFFF ) << 144 )
            | ( ( uint(block.blockhash(_lastb+7)) & 0xFFFFFF ) << 168 )
            | ( ( uint(block.blockhash(_lastb+8)) & 0xFFFFFF ) << 192 )
            | ( ( uint(block.blockhash(_lastb+9)) & 0xFFFFFF ) << 216 )
            | ( ( uint(_delta) / hashesSize) << 240)); 
    }

    function getHash(uint _block) constant private returns (uint32) {
        uint delta = (_block - hashFirst) / 10;
        uint hash = hashes[delta % hashesSize];
        if(delta / hashesSize != hash >> 240) {
            return(0x1000000); // load failed, incorrect data in hashes
        }
        uint slotp = (_block - hashFirst) % 10; 
        return(uint32((hash >> (24 * slotp)) & 0xFFFFFF));
    }
    
    /**
     * @dev Fill hash data
     */
    function putHash() public returns (bool) {
        uint lastb = hashLast;
        if(lastb == 0 || block.number <= lastb + 10) {
            return(false);
        }
        uint blockn256;
        if(block.number<256) { // useless test for testnet :-(
            blockn256 = 0;
        }
        else{
            blockn256 = block.number - 256;
        }
        if(lastb < blockn256) {
            uint num = blockn256;
            num += num % 10;
            lastb = num; 
        }
        uint delta = (lastb - hashFirst) / 10;
        hashes[delta % hashesSize] = calcHashes(uint32(lastb),uint32(delta));
        hashLast = lastb + 10;
        return(true);
    }

    /**
     * @dev Fill hash data many times
     * @param _num Number of iterations
     */
    function putHashes(uint _num) external {
        uint n=0;
        for(;n<_num;n++){
            if(!putHash()){
                return;
            }
        }
    }
    
}