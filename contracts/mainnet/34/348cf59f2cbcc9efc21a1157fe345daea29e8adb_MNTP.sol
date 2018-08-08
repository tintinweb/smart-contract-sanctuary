pragma solidity ^0.4.16;

contract SafeMath {
     function safeMul(uint a, uint b) internal returns (uint) {
          uint c = a * b;
          assert(a == 0 || c / a == b);
          return c;
     }

     function safeSub(uint a, uint b) internal returns (uint) {
          assert(b <= a);
          return a - b;
     }

     function safeAdd(uint a, uint b) internal returns (uint) {
          uint c = a + b;
          assert(c>=a && c>=b);
          return c;
     }
}

// Standard token interface (ERC 20)
// https://github.com/ethereum/EIPs/issues/20
contract Token is SafeMath {
     // Functions:
     /// @return total amount of tokens
     function totalSupply() constant returns (uint256 supply) {}

     /// @param _owner The address from which the balance will be retrieved
     /// @return The balance
     function balanceOf(address _owner) constant returns (uint256 balance) {}

     /// @notice send `_value` token to `_to` from `msg.sender`
     /// @param _to The address of the recipient
     /// @param _value The amount of token to be transferred
     function transfer(address _to, uint256 _value) returns(bool) {}

     /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
     /// @param _from The address of the sender
     /// @param _to The address of the recipient
     /// @param _value The amount of token to be transferred
     /// @return Whether the transfer was successful or not
     function transferFrom(address _from, address _to, uint256 _value)returns(bool){}

     /// @notice `msg.sender` approves `_addr` to spend `_value` tokens
     /// @param _spender The address of the account able to transfer the tokens
     /// @param _value The amount of wei to be approved for transfer
     /// @return Whether the approval was successful or not
     function approve(address _spender, uint256 _value) returns (bool success) {}

     /// @param _owner The address of the account owning tokens
     /// @param _spender The address of the account able to transfer the tokens
     /// @return Amount of remaining tokens allowed to spent
     function allowance(address _owner, address _spender) constant returns (uint256 remaining) {}

     // Events:
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract StdToken is Token {
     // Fields:
     mapping(address => uint256) balances;
     mapping (address => mapping (address => uint256)) allowed;
     uint public totalSupply = 0;

     // Functions:
     function transfer(address _to, uint256 _value) returns(bool){
          require(balances[msg.sender] >= _value);
          require(balances[_to] + _value > balances[_to]);

          balances[msg.sender] = safeSub(balances[msg.sender],_value);
          balances[_to] = safeAdd(balances[_to],_value);

          Transfer(msg.sender, _to, _value);
          return true;
     }

     function transferFrom(address _from, address _to, uint256 _value) returns(bool){
          require(balances[_from] >= _value);
          require(allowed[_from][msg.sender] >= _value);
          require(balances[_to] + _value > balances[_to]);

          balances[_to] = safeAdd(balances[_to],_value);
          balances[_from] = safeSub(balances[_from],_value);
          allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);

          Transfer(_from, _to, _value);
          return true;
     }

     function balanceOf(address _owner) constant returns (uint256 balance) {
          return balances[_owner];
     }

     function approve(address _spender, uint256 _value) returns (bool success) {
          allowed[msg.sender][_spender] = _value;
          Approval(msg.sender, _spender, _value);
          return true;
     }

     function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
          return allowed[_owner][_spender];
     }

     modifier onlyPayloadSize(uint _size) {
          require(msg.data.length >= _size + 4);
          _;
     }
}

contract MNTP is StdToken {
/// Fields:
     string public constant name = "Goldmint MNT Prelaunch Token";
     string public constant symbol = "MNTP";
     uint public constant decimals = 18;

     address public creator = 0x0;
     address public icoContractAddress = 0x0;
     bool public lockTransfers = false;

     // 10 mln
     uint public constant TOTAL_TOKEN_SUPPLY = 10000000 * (1 ether / 1 wei);

/// Modifiers:
     modifier onlyCreator() { 
          require(msg.sender == creator); 
          _; 
     }

     modifier byCreatorOrIcoContract() { 
          require((msg.sender == creator) || (msg.sender == icoContractAddress)); 
          _; 
     }

     function setCreator(address _creator) onlyCreator {
          creator = _creator;
     }

/// Setters/Getters
     function setIcoContractAddress(address _icoContractAddress) onlyCreator {
          icoContractAddress = _icoContractAddress;
     }

/// Functions:
     /// @dev Constructor
     function MNTP() {
          creator = msg.sender;

          // 10 mln tokens total
          assert(TOTAL_TOKEN_SUPPLY == (10000000 * (1 ether / 1 wei)));
     }

     /// @dev Override
     function transfer(address _to, uint256 _value) public returns(bool){
          require(!lockTransfers);
          return super.transfer(_to,_value);
     }

     /// @dev Override
     function transferFrom(address _from, address _to, uint256 _value) public returns(bool){
          require(!lockTransfers);
          return super.transferFrom(_from,_to,_value);
     }

     function issueTokens(address _who, uint _tokens) byCreatorOrIcoContract {
          require((totalSupply + _tokens) <= TOTAL_TOKEN_SUPPLY);

          balances[_who] = safeAdd(balances[_who],_tokens);
          totalSupply = safeAdd(totalSupply,_tokens);
     }

     function burnTokens(address _who, uint _tokens) byCreatorOrIcoContract {
          balances[_who] = safeSub(balances[_who], _tokens);
          totalSupply = safeSub(totalSupply, _tokens);
     }

     function lockTransfer(bool _lock) byCreatorOrIcoContract {
          lockTransfers = _lock;
     }

     // Do not allow to send money directly to this contract
     function() {
          revert();
     }
}

// This contract will hold all tokens that were unsold during ICO
// (Goldmint should be able to withdraw them and sold only 1 year post-ICO)
contract GoldmintUnsold is SafeMath {
     address public creator;
     address public teamAccountAddress;
     address public icoContractAddress;
     uint64 public icoIsFinishedDate;

     MNTP public mntToken;

     function GoldmintUnsold(address _teamAccountAddress,address _mntTokenAddress){
          creator = msg.sender;
          teamAccountAddress = _teamAccountAddress;

          mntToken = MNTP(_mntTokenAddress);          
     }

     modifier onlyCreator() { 
          require(msg.sender==creator); 
          _; 
     }

     modifier onlyIcoContract() { 
          require(msg.sender==icoContractAddress); 
          _; 
     }

/// Setters/Getters
     function setIcoContractAddress(address _icoContractAddress) onlyCreator {
          icoContractAddress = _icoContractAddress;
     }

     // only by Goldmint contract 
     function finishIco() public onlyIcoContract {
          icoIsFinishedDate = uint64(now);
     }

     // can be called by anyone...
     function withdrawTokens() public {
          // wait for 1 year!
          uint64 oneYearPassed = icoIsFinishedDate + 365 days;  
          require(uint(now) >= oneYearPassed);

          // transfer all tokens from this contract to the teamAccountAddress
          uint total = mntToken.balanceOf(this);
          mntToken.transfer(teamAccountAddress,total);
     }

     // Default fallback function
     function() payable {
          revert();
     }
}

contract FoundersVesting is SafeMath {
     address public teamAccountAddress;
     uint64 public lastWithdrawTime;

     uint public withdrawsCount = 0;
     uint public amountToSend = 0;

     MNTP public mntToken;

     function FoundersVesting(address _teamAccountAddress,address _mntTokenAddress){
          teamAccountAddress = _teamAccountAddress;
          lastWithdrawTime = uint64(now);

          mntToken = MNTP(_mntTokenAddress);          
     }

     // can be called by anyone...
     function withdrawTokens() public {
          // 1 - wait for next month!
          uint64 oneMonth = lastWithdrawTime + 30 days;  
          require(uint(now) >= oneMonth);

          // 2 - calculate amount (only first time)
          if(withdrawsCount==0){
               amountToSend = mntToken.balanceOf(this) / 10;
          }

          require(amountToSend!=0);

          // 3 - send 1/10th
          uint currentBalance = mntToken.balanceOf(this);
          if(currentBalance<amountToSend){
             amountToSend = currentBalance;  
          }
          mntToken.transfer(teamAccountAddress,amountToSend);

          // 4 - update counter
          withdrawsCount++;
          lastWithdrawTime = uint64(now);
     }

     // Default fallback function
     function() payable {
          require(false);
     }
}

contract Goldmint is SafeMath {
     address public creator = 0x0;
     address public tokenManager = 0x0;
     address public multisigAddress = 0x0;
     address public otherCurrenciesChecker = 0x0;

     uint64 public icoStartedTime = 0;

     MNTP public mntToken; 
     GoldmintUnsold public unsoldContract;

     struct TokenBuyer {
          uint weiSent;
          uint tokensGot;
     }
     mapping(address => TokenBuyer) buyers;

     // These can be changed before ICO start ($7USD/MNTP)
     uint constant STD_PRICE_USD_PER_1000_TOKENS = 7000;
     // coinmarketcap.com 14.08.2017
     uint constant ETH_PRICE_IN_USD = 300;
     // price changes from block to block
     //uint public constant SINGLE_BLOCK_LEN = 700000;

     // TODO: only for tests. DO NOT merge this to master!!!
     uint public constant SINGLE_BLOCK_LEN = 100;

///////     
     // 1 000 000 tokens
     uint public constant BONUS_REWARD = 1000000 * (1 ether/ 1 wei);
     // 2 000 000 tokens
     uint public constant FOUNDERS_REWARD = 2000000 * (1 ether / 1 wei);
     // 7 000 000 we sell only this amount of tokens during the ICO
     //uint public constant ICO_TOKEN_SUPPLY_LIMIT = 7000000 * (1 ether / 1 wei); 

     // TODO: only for tests. DO NOT merge this to master!!!
     // 150 - we sell only this amount of tokens during the ICO
     uint public constant ICO_TOKEN_SUPPLY_LIMIT = 150 * (1 ether / 1 wei); 

     // 150 000 tokens soft cap
     uint public constant ICO_TOKEN_SOFT_CAP = 150000 * (1 ether / 1 wei);
     
     // this is total number of tokens sold during ICO
     uint public icoTokensSold = 0;
     // this is total number of tokens sent to GoldmintUnsold contract after ICO is finished
     uint public icoTokensUnsold = 0;

     // this is total number of tokens that were issued by a scripts
     uint public issuedExternallyTokens = 0;

     bool public foundersRewardsMinted = false;
     bool public restTokensMoved = false;

     // this is where FOUNDERS_REWARD will be allocated
     address public foundersRewardsAccount = 0x0;

     enum State{
          Init,

          ICORunning,
          ICOPaused,
         
          ICOFinished,

          Refunding
     }
     State public currentState = State.Init;

/// Modifiers:
     modifier onlyCreator() { 
          require(msg.sender==creator); 
          _; 
     }
     modifier onlyTokenManager() { 
          require(msg.sender==tokenManager); 
          _; 
     }
     modifier onlyOtherCurrenciesChecker() { 
          require(msg.sender==otherCurrenciesChecker); 
          _; 
     }
     modifier onlyInState(State state){ 
          require(state==currentState); 
          _; 
     }

/// Events:
     event LogStateSwitch(State newState);
     event LogBuy(address indexed owner, uint value);
     event LogBurn(address indexed owner, uint value);
     
/// Functions:
     /// @dev Constructor
     function Goldmint(
          address _multisigAddress,
          address _tokenManager,
          address _otherCurrenciesChecker,

          address _mntTokenAddress,
          address _unsoldContractAddress,
          address _foundersVestingAddress)
     {
          creator = msg.sender;

          multisigAddress = _multisigAddress;
          tokenManager = _tokenManager;
          otherCurrenciesChecker = _otherCurrenciesChecker; 

          mntToken = MNTP(_mntTokenAddress);
          unsoldContract = GoldmintUnsold(_unsoldContractAddress);

          // slight rename
          foundersRewardsAccount = _foundersVestingAddress;
     }

     /// @dev This function is automatically called when ICO is started
     /// WARNING: can be called multiple times!
     function startICO() internal onlyCreator {
          mintFoundersRewards(foundersRewardsAccount);

          mntToken.lockTransfer(true);

          if(icoStartedTime==0){
               icoStartedTime = uint64(now);
          }
     }

     function pauseICO() internal onlyCreator {
     }

     function startRefunding() internal onlyCreator {
          // only switch to this state if less than ICO_TOKEN_SOFT_CAP sold
          require(icoTokensSold<ICO_TOKEN_SOFT_CAP);

          // in this state tokens still shouldn&#39;t be transferred
          assert(mntToken.lockTransfers());
     }

     /// @dev This function is automatically called when ICO is finished 
     /// WARNING: can be called multiple times!
     function finishICO() internal {
          mntToken.lockTransfer(false);

          if(!restTokensMoved){
               restTokensMoved = true;

               // move all unsold tokens to unsoldTokens contract
               icoTokensUnsold = safeSub(ICO_TOKEN_SUPPLY_LIMIT,icoTokensSold);
               if(icoTokensUnsold>0){
                    mntToken.issueTokens(unsoldContract,icoTokensUnsold);
                    unsoldContract.finishIco();
               }
          }

          // send all ETH to multisig
          if(this.balance>0){
               multisigAddress.transfer(this.balance);
          }
     }

     function mintFoundersRewards(address _whereToMint) internal onlyCreator {
          if(!foundersRewardsMinted){
               foundersRewardsMinted = true;
               mntToken.issueTokens(_whereToMint,FOUNDERS_REWARD);
          }
     }

/// Access methods:
     function setTokenManager(address _new) public onlyTokenManager {
          tokenManager = _new;
     }

     function setOtherCurrenciesChecker(address _new) public onlyCreator {
          otherCurrenciesChecker = _new;
     }

     function getTokensIcoSold() constant public returns (uint){
          return icoTokensSold;
     }

     function getTotalIcoTokens() constant public returns (uint){
          return ICO_TOKEN_SUPPLY_LIMIT;
     }

     function getMntTokenBalance(address _of) constant public returns (uint){
          return mntToken.balanceOf(_of);
     }

     function getCurrentPrice()constant public returns (uint){
          return getMntTokensPerEth(icoTokensSold);
     }

     function getBlockLength()constant public returns (uint){
          return SINGLE_BLOCK_LEN;
     }

////
     function isIcoFinished() public returns(bool){
          if(icoStartedTime==0){return false;}          

          // 1 - if time elapsed
          uint64 oneMonth = icoStartedTime + 30 days;  
          if(uint(now) > oneMonth){return true;}

          // 2 - if all tokens are sold
          if(icoTokensSold>=ICO_TOKEN_SUPPLY_LIMIT){
               return true;
          }

          return false;
     }

     function setState(State _nextState) public {
          // only creator can change state
          // but in case ICOFinished -> anyone can do that after all time is elapsed
          bool icoShouldBeFinished = isIcoFinished();
          bool allow = (msg.sender==creator) || (icoShouldBeFinished && (State.ICOFinished==_nextState));
          require(allow);

          bool canSwitchState
               =  (currentState == State.Init && _nextState == State.ICORunning)
               || (currentState == State.ICORunning && _nextState == State.ICOPaused)
               || (currentState == State.ICOPaused && _nextState == State.ICORunning)
               || (currentState == State.ICORunning && _nextState == State.ICOFinished)
               || (currentState == State.ICORunning && _nextState == State.Refunding);

          require(canSwitchState);

          currentState = _nextState;
          LogStateSwitch(_nextState);

          if(currentState==State.ICORunning){
               startICO();
          }else if(currentState==State.ICOFinished){
               finishICO();
          }else if(currentState==State.ICOPaused){
               pauseICO();
          }else if(currentState==State.Refunding){
               startRefunding();
          }
     }

     function getMntTokensPerEth(uint tokensSold) public constant returns (uint){
          // 10 buckets
          uint priceIndex = (tokensSold / (1 ether/ 1 wei)) / SINGLE_BLOCK_LEN;
          assert(priceIndex>=0 && (priceIndex<=9));
          
          uint8[10] memory discountPercents = [20,15,10,8,6,4,2,0,0,0];

          // We have to multiply by &#39;1 ether&#39; to avoid float truncations
          // Example: ($7000 * 100) / 120 = $5833.33333
          uint pricePer1000tokensUsd = 
               ((STD_PRICE_USD_PER_1000_TOKENS * 100) * (1 ether / 1 wei)) / (100 + discountPercents[priceIndex]);

          // Correct: 300000 / 5833.33333333 = 51.42857142
          // We have to multiply by &#39;1 ether&#39; to avoid float truncations
          uint mntPerEth = (ETH_PRICE_IN_USD * 1000 * (1 ether / 1 wei) * (1 ether / 1 wei)) / pricePer1000tokensUsd;
          return mntPerEth;
     }

     function buyTokens(address _buyer) public payable onlyInState(State.ICORunning) {
          require(msg.value!=0);

          // The price is selected based on current sold tokens.
          // Price can &#39;overlap&#39;. For example:
          //   1. if currently we sold 699950 tokens (the price is 10% discount)
          //   2. buyer buys 1000 tokens
          //   3. the price of all 1000 tokens would be with 10% discount!!!
          uint newTokens = (msg.value * getMntTokensPerEth(icoTokensSold)) / (1 ether / 1 wei);

          issueTokensInternal(_buyer,newTokens);

          // update &#39;buyers&#39; map
          // (only when buying from ETH)
          TokenBuyer memory b = buyers[msg.sender];
          b.weiSent = safeAdd(b.weiSent, msg.value);
          b.tokensGot = safeAdd(b.tokensGot, newTokens);
          buyers[msg.sender] = b;
     }

     /// @dev This is called by other currency processors to issue new tokens 
     function issueTokensFromOtherCurrency(address _to, uint _wei_count) onlyInState(State.ICORunning) public onlyOtherCurrenciesChecker {
          require(_wei_count!=0);

          uint newTokens = (_wei_count * getMntTokensPerEth(icoTokensSold)) / (1 ether / 1 wei);
          issueTokensInternal(_to,newTokens);
     }

     /// @dev This can be called to manually issue new tokens 
     /// from the bonus reward
     function issueTokensExternal(address _to, uint _tokens) public onlyInState(State.ICOFinished) onlyTokenManager {
          // can not issue more than BONUS_REWARD
          require((issuedExternallyTokens + _tokens)<=BONUS_REWARD);

          mntToken.issueTokens(_to,_tokens);

          issuedExternallyTokens = issuedExternallyTokens + _tokens;
     }

     function issueTokensInternal(address _to, uint _tokens) internal {
          require((icoTokensSold + _tokens)<=ICO_TOKEN_SUPPLY_LIMIT);

          mntToken.issueTokens(_to,_tokens);

          icoTokensSold+=_tokens;

          LogBuy(_to,_tokens);
     }

     function burnTokens(address _from, uint _tokens) public onlyInState(State.ICOFinished) onlyTokenManager {
          mntToken.burnTokens(_from,_tokens);

          LogBurn(_from,_tokens);
     }

     // anyone can call this and get his money back
     function getMyRefund() public onlyInState(State.Refunding) {
          address sender = msg.sender;

          require(0!=buyers[sender].weiSent);
          require(0!=buyers[sender].tokensGot);

          // 1 - send money back
          sender.transfer(buyers[sender].weiSent);

          // 2 - burn tokens
          mntToken.burnTokens(sender,buyers[sender].tokensGot);
     }

     // Default fallback function
     function() payable {
          // buyTokens -> issueTokensInternal
          buyTokens(msg.sender);
     }
}