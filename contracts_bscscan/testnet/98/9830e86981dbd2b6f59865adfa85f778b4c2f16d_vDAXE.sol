/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

// SPDX-License-Identifier: unlicensed
pragma solidity 0.8.4;
pragma experimental ABIEncoderV2;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {


    function percentageOf(uint val, uint percent) internal pure returns(uint){
        val = mul(val,10000);
        val = mul(val,percent);
        val = div(val,100);
        val = div(val,10000);
        return val;
    }

 
    //These functions enable operations on big integers
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }


    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }



}
// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
// ----------------------------------------------------------------------------
abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}
// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals
// assisted token transfers
// ----------------------------------------------------------------------------
contract vDAXE is ERC20Interface, SafeMath {
    // Staking maps
    mapping(uint=>address) internal allStakedAddresses;
    mapping(address=>uint) internal allAddresseIndexes;
    mapping(address=>bool) internal addressHasStake;
    mapping(uint=>uint) public allStakedAmounts;
    mapping(uint=>uint) public allStakedReleaseDate;
    mapping(uint=>uint) public allStakedStartDate;
    mapping(uint=>bool) public allStakedIsClosed;
    mapping(uint=>uint) public allStakedInitialPrinciple;
    mapping(uint=>uint) public allStakedPenalties;
    mapping(uint=>uint) public allStakedPayout;
    
    // mapping(uint=>uint) public allStakedCummulatedPenalties;

    uint public stakeCount = 100;
   
   
   
    mapping(address=>uint) public balances;
    mapping(address=>mapping(address=>uint)) internal allowed;
    // mapping(address=>uint) public stakedBalance;
    // mapping(address=>mapping(address=>uint)) public allowance;
    uint public decimals = 18;
    uint public _totalSupply = 20000000000000 * 10**decimals;
    uint public totalStaked = 0;
    string public name = "vDAXE";
    string public symbol = "vDAXE";
   


    struct stakingInfo {
        uint amount;
        address ownerAddress;
        uint releaseDate;
    }
   
    stakingInfo[] allStakes;
   
    // event Transfer(address indexed from, address indexed to, uint value);
    // event Approval(address indexed _owner, address indexed _spender, uint _value);
   
    event test_value(string _msg,address _address, uint _value);
    event test_value2(string _msg, uint _value);
    
    
    
    
    
    
    
    
    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(){
        balances[msg.sender] = _totalSupply;
    }
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public override view returns (uint) {
        return _totalSupply;
    }
    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address owner) public override view returns (uint balance) {
        return balances[owner];
    }
    // ------------------------------------------------------------------------
    // Transfer the balance from token owner's account to receiver account
    // - Owner's account must have sufficient balance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transfer(address to, uint value) public override returns (bool success) {
        uint maxTransactionAmount = percentageOf(_totalSupply,1);
        require(balances[msg.sender]>= value, 'Balance too low');
        require(value<maxTransactionAmount,"Send transaction limit exeeded.  ");
        balances[to] += value;
        balances[msg.sender] -= value;
        emit Transfer(msg.sender,to,value);
        return true;
    }
    // ------------------------------------------------------------------------
    // Token owner can approve for spender to transferFrom(...) tokens
    // from the token owner's account
    //
    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
    // recommends that there are no checks for the approval double-spend attack
    // as this should be implemented in user interfaces 
    // ------------------------------------------------------------------------
    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    // ------------------------------------------------------------------------
    // Transfer tokens from sender account to receiver account
    // 
    // The calling account must already have sufficient tokens approve(...)-d
    // for spending from sender account and
    // - From account must have sufficient balance to transfer
    // - Spender must have sufficient allowance to transfer
    // - 0 value transfers are allowed
    // ------------------------------------------------------------------------
    function transferFrom(address sender, address receiver, uint tokens) public override returns (bool success) {
        // uint maxTransactionAmount = percentageOf(_totalSupply,1);
        // maxTransactionAmount = percentageOf(maxTransactionAmount,1);
        // require(balances[msg.sender]>= tokens, 'Balance too low');
        balances[sender] = sub(balances[sender], tokens);
        allowed[sender][msg.sender] = sub(allowed[sender][msg.sender], tokens);
        balances[receiver] = add(balances[receiver], tokens);
        emit Transfer(sender, receiver, tokens);
        return true;
    }
    // ------------------------------------------------------------------------
    // Returns the amount of tokens approved by the owner that can be
    // transferred to the spender's account
    // ------------------------------------------------------------------------
    function allowance(address tokenOwner, address spender) public override view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    






    // ------------------------------------------------------------------------
    // Custom DAXE functions
    // ------------------------------------------------------------------------
    function getAllStakesOf(address owner) public view returns (uint[8][] memory){
        //   find out number os stakes for owner
        uint numStake = 0;
        for(uint a=100;a<stakeCount;a++){
            if(allStakedAddresses[a]==owner) numStake++;
        }
        // emit test_value("Nuum stake ",owner,numStake);
        require( numStake>0 );
        uint[8][]    memory stakeIDs = new uint[8][](numStake);
        // address[]  memory addresses = new address[](numStake);
        // uint[]    memory stakedAmounts = new uint[](numStake);
        numStake=0;
        uint isClosed = 0;
        for (uint i=100; i< stakeCount;i++){
          if (allStakedAddresses[i]==owner){
            stakeIDs[numStake][0]=i;
            stakeIDs[numStake][1]=allStakedAmounts[i];
            stakeIDs[numStake][2]=allStakedStartDate[i];
            stakeIDs[numStake][3]=allStakedReleaseDate[i];
            stakeIDs[numStake][4]=allStakedInitialPrinciple[i];
            stakeIDs[numStake][5]=allStakedPenalties[i];
            stakeIDs[numStake][6]=allStakedPayout[i];
            if (allStakedIsClosed[i]) 
                isClosed = 1;
            else
                isClosed = 0;
            stakeIDs[numStake][7] = isClosed;
            // stakeIDs[numStake][5]=getCumulativeInterestToDate(i);
            //   addresses[i]=allStakedAddresses[i];
            //   stakedAmounts[i]=allStakedAmounts[i];
            // //   emit test_value("Adding for return ",owner,allStakedAmounts[i]);
            numStake++;
          }
        }
   
        return (stakeIDs);
   
    }    
   
    function getNumStakesOf(address owner) internal returns(uint){

    }
    
    function getActiveStakesCount() public view returns (uint){
        uint numStakes=0;
        for(uint i=100;i<stakeCount;i++){
            if(!allStakedIsClosed[i]) numStakes++;
        }
        return numStakes;
    }
   
   

   
    function stake( uint value,uint startDate, uint releaseDate) public returns(bool){
        require(balances[msg.sender]>=value , 'Balance too low');
        require(releaseDate>startDate,'Trying to end stake before it starts');
        startDate = block.timestamp*1000;
        
        // do not stake less than 48 hours
        uint hoursServed = releaseDate - startDate;
        hoursServed = div(hoursServed,1000);
        hoursServed = div(hoursServed,60);
        hoursServed = div(hoursServed,60);
        
        require(hoursServed>48, 'Trying to start a stake shorter than 48 hours');
       
    
        uint maxReleaseDate = add(startDate, mul(5555,86400000));   
        if (releaseDate>maxReleaseDate)  releaseDate = maxReleaseDate;
        
        allStakedAmounts[stakeCount] += value;
        allStakedInitialPrinciple[stakeCount] = value;
        allStakedReleaseDate[stakeCount] = releaseDate;
        allStakedStartDate[stakeCount] = startDate;
        allStakedAddresses[stakeCount] = msg.sender;
        balances[msg.sender] -= value;
        totalStaked += value;
        stakeCount +=1;
        return true;
    }
   
    function endStake(uint stakeID) public returns(bool){
        // require(value>0, 'Trying to unstake negative value');
        // require(allStakedAmounts[stakeID]>=value , 'Trying to unstake more than available staked');

        //Staking PENALTY
        //Unstake for this user
        // allStakedamounts[msg.sender] = sub( allStakedamounts[msg.sender] , value);
        
        // emit test_value("msg.sender  ",msg.sender, 0);
        // emit test_value("allStakedAddresses[stakedID] ",allStakedAddresses[stakeID], 0);
        require(allStakedAddresses[stakeID]==msg.sender,'Trying to unstake a stake belonging to another user');
        require( allStakedIsClosed[stakeID]==false, 'Tryint to end a stake that is already closed' );
        
        uint currentDate = block.timestamp*1000;
        // uint currentDate = block.timestamp*1000 + 1000*60*60*24*99;
        uint startDate = allStakedStartDate[stakeID];
        uint releaseDate = allStakedReleaseDate[stakeID];
        
        uint daysServed = sub(currentDate, startDate);
        daysServed = div(daysServed,1000);
        daysServed = div(daysServed,60);
        daysServed = div(daysServed,60);
        uint hoursServed = daysServed;
        daysServed = div(daysServed,24);
        
        uint stakeDuration = sub(releaseDate, startDate);
        stakeDuration = div(stakeDuration,1000);
        stakeDuration = div(stakeDuration,60);
        stakeDuration = div(stakeDuration,60);
        stakeDuration = div(stakeDuration,24);

        if(hoursServed<24){
            allStakedPenalties[stakeID] = 0;
            allStakedPayout[stakeID] = 0;
    
            // Remove stake

            allStakedIsClosed[stakeID] = true;
            balances[msg.sender] = add( balances[msg.sender],  allStakedAmounts[stakeID] );
            _totalSupply +=             allStakedAmounts[stakeID];
            allStakedAmounts[stakeID] = 0;
            return true;
        }

        // emit test_value("daysServed ",msg.sender, daysServed);
        // emit test_value("stakeDuration ",msg.sender, stakeDuration);  
        // emit test_value("allStakedAmounts[stakeID] ",msg.sender, allStakedAmounts[stakeID]);
       
        uint cumulativePrinciple = computeInterestOnPriniple( daysServed, stakeDuration , allStakedAmounts[stakeID] );
        // emit test_value("cumulativePrinciple ",msg.sender, cumulativePrinciple);  
        
        uint penaltyOnPrinciple  = 0;
        uint leftOverPrinciple = cumulativePrinciple;
        
        // if stake ended normally there is no penalty
        if (daysServed>=stakeDuration){
            leftOverPrinciple = cumulativePrinciple;
            penaltyOnPrinciple = 0;
        }
        else{
            penaltyOnPrinciple  = computePenaltyOnPrinciple( daysServed, stakeDuration, cumulativePrinciple );
            leftOverPrinciple = computeLeftOverPrinciple( daysServed, stakeDuration, cumulativePrinciple ); 
            
            //distribute remainingStake amongst all stakers
            for (uint i=100; i< stakeCount;i++){
                address _add = allStakedAddresses[i];
                // make sure the address unstaking doesn't receive any unstaking distribution
                // also make sure ended stakes do not receive benefits
                if(_add !=msg.sender && allStakedIsClosed[i]==false){
                    uint currentStake = allStakedAmounts[i];
                    currentStake = mul(currentStake,penaltyOnPrinciple);
                    currentStake = div(currentStake,totalStaked);
                    _totalSupply += currentStake;
                    allStakedAmounts[i] = add(allStakedAmounts[i],currentStake);
                                    
                }
            }  
        
        }
        
        allStakedPenalties[stakeID] = penaltyOnPrinciple;
        allStakedPayout[stakeID] = leftOverPrinciple;

        // Remove stake
        allStakedAmounts[stakeID] = 0;
        allStakedIsClosed[stakeID] = true;
        balances[msg.sender] = add( balances[msg.sender], leftOverPrinciple);
        _totalSupply += leftOverPrinciple;
        
        // emit test_value("late Balance  ",msg.sender, balances[msg.sender]);
       
       
        return true;
    }
    
    function computePenaltyOnPrinciple(uint daysServed, uint stakeDuration, uint cumulativePrinciple) internal pure returns( uint){
        uint proportionServed =  mul( daysServed , 1000);
        proportionServed = div(proportionServed,stakeDuration);
        if( proportionServed < 500)
            return div( mul( 795, cumulativePrinciple), 1000);
        else
            return div( mul( sub(1000,proportionServed), cumulativePrinciple), 1000);
    }

    function computeLeftOverPrinciple(uint daysServed, uint stakeDuration, uint cumulativePrinciple) internal pure returns( uint){
        uint proportionServed =  mul( daysServed , 1000);
        proportionServed = div(proportionServed,stakeDuration);
        if( proportionServed < 500)
            return div( mul( 175, cumulativePrinciple), 1000);
        else
            return div( mul( proportionServed, cumulativePrinciple), 1000);
    }    
    
    function getCumulativeInterestToDate(uint stakeID) public view returns(uint){
        if(allStakedIsClosed[stakeID]==true) return 0;
        uint currentDate = block.timestamp*1000;
        currentDate = add(currentDate,(mul ( 5550, mul(1000,  mul(60, mul(60,24) ) ) ) ) ); 
        // currentDate = add(currentDate,400*)
        uint startDate = allStakedStartDate[stakeID];
        uint releaseDate = allStakedReleaseDate[stakeID];
        
        uint daysServed = sub(currentDate, startDate);
        daysServed = div(daysServed,1000);
        daysServed = div(daysServed,60);
        daysServed = div(daysServed,60);
        daysServed = div(daysServed,24);
        
        uint stakeDuration = sub(releaseDate, startDate);
        stakeDuration = div(stakeDuration,1000);
        stakeDuration = div(stakeDuration,60);
        stakeDuration = div(stakeDuration,60);
        stakeDuration = div(stakeDuration,24);
        uint cumulativePrinciple = computeInterestOnPriniple( daysServed, stakeDuration, allStakedAmounts[stakeID] ); 
        return cumulativePrinciple;
    }
    
    // function getProjectedPayout(uint stakedAmount, uint _releaseDate) public view returns (uint){
    //     // uint currentDate = _releaseDate;
    //     uint startDate = block.timestamp*1000;
    //     uint releaseDate = _releaseDate;
        

        
    //     uint stakeDuration = sub(releaseDate, startDate);
    //     stakeDuration = div(stakeDuration,1000);
    //     stakeDuration = div(stakeDuration,60);
    //     stakeDuration = div(stakeDuration,60);
    //     stakeDuration = div(stakeDuration,24);
        
    //     uint daysServed = stakeDuration;
    //     uint cumulativePrinciple = computeInterestOnPriniple( daysServed, stakeDuration, stakedAmount ); 
    //     return cumulativePrinciple;       
    // }
    
    function computeInterestOnPriniple(uint daysServed,uint stakeDuration, uint principle) internal pure returns(uint){
        return computeAllInteresAtDayN(daysServed,stakeDuration,principle);
    }
    
    function computeAllInteresAtDayN( uint daysServed, uint stakeDuration ,uint principleAtDayN)internal pure returns(uint){
        // if ( daysServed > lastDayOfStake) return 0;
        
        uint cumulativePrinciple = principleAtDayN;
        uint initialPrincipal = add(principleAtDayN,0);
        
        
        uint baseInterest =  mul( principleAtDayN, 2000000);
        baseInterest = div(baseInterest,3652500000);
        uint longStakeInterest = 0;
        uint allInterest =0;
        
        for(uint i=0;i<daysServed && i<stakeDuration;i++){
            // uint baseInterest = computeBaseInterestForDayN(initialPrincipal);
            // longStakeInterest = computeLongStateDialyBonus(i, initialPrincipal);
            longStakeInterest = i*i*10000;
            longStakeInterest = longStakeInterest / (30858025);
            longStakeInterest = longStakeInterest * initialPrincipal *2;
            longStakeInterest = longStakeInterest / 3650000;
            
            allInterest = add( baseInterest, longStakeInterest );
            
            
            cumulativePrinciple = add(cumulativePrinciple, allInterest);
        }
        
        // uint newPrinciple = sum(principleAtDayN, interesAccruedtToday);
        return cumulativePrinciple;
        
    }
    
    function computeBaseInterestForDayN( uint principleAtDayN)internal pure returns(uint){
        uint retval =  mul( principleAtDayN, 2000000);
        retval = div(retval,3652500000);
        return retval;
    }
    
    function computeLongStateDialyBonus(uint daysServed, uint principleAtDayN)internal pure returns(uint){
        // emit test_value2("daysServed**2",mul(daysServed,daysServed)); 
        
        uint retval = mul(mul(daysServed,daysServed),100000);
        
        retval = div(retval,mul(5555,5555));
        retval = mul(retval,principleAtDayN);
        retval = mul(retval,200);
        retval = div(retval,100);
        // // get daily rate
        retval = div(retval,365);
        retval = div(retval,100000);
        return retval;
        
    }
   
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
}