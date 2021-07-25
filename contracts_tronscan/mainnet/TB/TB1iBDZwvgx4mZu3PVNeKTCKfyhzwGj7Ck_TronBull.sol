//SourceUnit: contract.sol

 /*  TronBull - Community Contribution pool with daily ROI (Return Of Investment) based on TRX blockchain smart-contract technology. 
 *   Safe and decentralized. The Smart Contract source is verified and available to everyone. The community decides the future of the project!
 *
 *   ┌───────────────────────────────────────────────────────────────────────┐
 *   │   Website: https://tronbull.space                                     │
 *   │                                                                       │
 *   │   Telegram Public Group and Support: @tronbullcommunity                |
 *   |                                                                       |        
 *   |                                       
 *   └───────────────────────────────────────────────────────────────────────┘
 *
 *   [USAGE INSTRUCTION]
 *
 *   1) Connect TRON browser extension TronLink, or mobile wallet apps like TronLink Pro / Klever
 *   2) Ask your sponsor the login link and contribute to the contract with at least the minimum amount of TRX required (100 TRX)
 *   3) Wait for your earnings. You can withdraw once every 24h
 *   4) Invite your friends and earn some referral bonus. Help the smart contract balance to grow and have fun
 *   5) Withdraw earnings (dividends+referral) using our website "Withdraw" button 
 *   6) Deposit more if you want. 
 *
 *   [SMART CONTRACT DETAILS]
 *
 *   - ROI (return of Investment): 1.5% To 5.5% Based on smart contract balance every 24h - max 300%  for every deposit.
 *   - Minimal deposit: 100 TRX, no maximal limit
 *   - Single button withdraw for dividends and cumulated referral bonus
 *   - Withdraw any time, but with the limit of max 1 withdraw every 24h. No max withdraw limit.
 *
 *   [AFFILIATE PROGRAM]
 *
 *   - 5-level referral commission: 7% - 3% - 2% - 1% - 4% - Earn more from the last line!
 *  
*/


pragma solidity ^0.5.10;
//contract name
contract TronBull {
    //Importing safe SafeMath
	using SafeMath for uint256;
	// total amount invested in the contract
	uint256 public TotalInvested;
    mapping(address => userst) internal users;
    //base variables
    uint256[] public referralreward = [7, 3, 2, 1, 4];
	uint256 maximum=25000000000;
	uint256 maxearnings=3;
	uint256 minimum=100000000;
    uint256 minimumwtime=86400;
    uint256 public oppfee;
    uint256 public devfee;
    address payable public opp;
    address payable public dev;
    uint256 userno;
    uint256 oppfeeam;
    uint256 devfeeam;
	//define deposit sructure
	struct deposit {
		uint256 amount;
		uint256 start;
		uint256 withdrawn;
		uint256 lastaction;
	}
	// define user structure
	struct userst {
	    address payable wallet;
	    deposit[] deposits;
	    address referrer;
	    uint256 refreward;
	    uint256 totalwithdrawn;
	}
	//contract varibles
	constructor() public{
	    oppfee=75;
	    devfee=75;
	    dev=msg.sender;
	    opp=msg.sender;
	    userno=0;
	    TotalInvested =0;
	}
	function invest(address referrer) public payable returns(bool){
	    require(msg.value>=minimum);
        userst storage user = users[msg.sender];
        TotalInvested=TotalInvested+msg.value;
        // first time users
        if(users[msg.sender].deposits.length == 0){
            userno=userno+1;
            user.wallet=msg.sender;
            uint256 fees=(msg.value.div(1000)).mul(75);
	        	devfeeam=devfeeam+fees;
	        	oppfeeam=oppfeeam+fees;
            user.deposits.push(deposit(msg.value, block.timestamp, 0, block.timestamp));
            user.totalwithdrawn=0;
            user.refreward=0;
            if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
    				user.referrer = referrer;
    			}
    			else{
    			    user.referrer =address(0);
    			}
        }
        //re investors
        else{
            user.wallet=msg.sender;
            uint256 fees=(msg.value.div(1000)).mul(75);
	        	devfeeam=devfeeam+fees;
	        	oppfeeam=oppfeeam+fees;
            user.deposits.push(deposit(msg.value, block.timestamp, 0, block.timestamp));
        }
      //paying referrel rewards
      address upline = user.referrer;
    	for (uint256 i = 0; i < 5; i++) {
    		if (upline != address(0)) {
    		    uint256 amount = msg.value.mul(referralreward[i]).div(100);
						users[upline].refreward = users[upline].refreward.add(amount);
						upline = users[upline].referrer;
    		} else break;
    	}
    	return true;
	}

	//int to string
	 function uint2str(uint256 _i) internal pure returns (string memory _uintAsString) {
    if (_i == 0) {
        return "0";
    }
    uint256 j = _i;
    uint256 len;
    while (j != 0) {
        len++;
        j /= 10;
    }
    bytes memory bstr = new bytes(len);
    uint256 k = len - 1;
    while (_i != 0) {
        bstr[k--] = byte(uint8(48 + _i % 10));
        _i /= 10;
    }
    return string(bstr);
}
    function getuser(address uaddr) public view returns(address wallet, address referrer, uint256 refreward, uint256 totalwithdrawn, uint256 noofdeposits, uint256 total){
	    userst storage user = users[uaddr];
	    wallet=user.wallet;
	    referrer=user.referrer;
	    refreward=user.refreward;
	    totalwithdrawn=user.totalwithdrawn;
	    noofdeposits=user.deposits.length;
	    total=0;
	    for(uint256 i=0; i<noofdeposits; i++){
	        total=total+user.deposits[i].amount;
	    }
	}
	function getdeposits(address uaddr) public view returns(string memory s){
	    userst storage user = users[uaddr];
	    bytes memory b;
	    uint256 noofdeposits=user.deposits.length;
	    b = abi.encodePacked("{");
	    b = abi.encodePacked(b,'"result":[');
	    for(uint256 i=0; i<noofdeposits; i++){
	        if(i!=0){
	            b = abi.encodePacked(b,",");
	        }
	        b = abi.encodePacked(b,'{');
	        b = abi.encodePacked(b,'"amount":');
	        b = abi.encodePacked(b,uint2str(user.deposits[i].amount));
	        b = abi.encodePacked(b,",");
	        b = abi.encodePacked(b,'"start":');
	        b = abi.encodePacked(b,uint2str(user.deposits[i].start));
	        b = abi.encodePacked(b,",");
	        b = abi.encodePacked(b,'"withdrawn":');
	        b = abi.encodePacked(b,uint2str(user.deposits[i].withdrawn));
	        b = abi.encodePacked(b,",");
	        b = abi.encodePacked(b,'"lastaction":');
	        b = abi.encodePacked(b,uint2str(user.deposits[i].lastaction));
	        b = abi.encodePacked(b,"}");
	    }
    b = abi.encodePacked(b, "]}");
    s = string(b);
	}
	//shows withdrawable ammount.`
	function withdrawable(address _address) view public returns(uint256 total, bool status){
        userst storage user = users[_address];
	    uint256 noofdeposits=user.deposits.length;
	    total=0;
        status=false;
	    uint256 withdrawablebalance=0;
	    uint256 _ROI=currentroi();
	    for(uint256 i=0; i<noofdeposits; i++){
	        if(block.timestamp > (user.deposits[i].lastaction+minimumwtime)){
	            withdrawablebalance=(user.deposits[i].amount*_ROI)*(block.timestamp-user.deposits[i].start)/(86400*10000);
	            if(withdrawablebalance > (user.deposits[i].amount*maxearnings)){
                    withdrawablebalance=(user.deposits[i].amount*maxearnings);
	            }
	            withdrawablebalance=withdrawablebalance-user.deposits[i].withdrawn;
                status=true;
	         }
	       total=total+withdrawablebalance;
	    }
	    total=total+user.refreward;
	}
		//shows eaarnings.`
	function earnings(address _address) view public returns(uint256 total){
        userst storage user = users[_address];
	    uint256 noofdeposits=user.deposits.length;
	    total=0;
	    uint256 withdrawablebalance=0;
	    uint256 _ROI=currentroi();
	    for(uint256 i=0; i<noofdeposits; i++){
	            withdrawablebalance=(user.deposits[i].amount*_ROI)*(block.timestamp-user.deposits[i].start)/(86400*10000);
	            if(withdrawablebalance > (user.deposits[i].amount*maxearnings)){
                    withdrawablebalance=(user.deposits[i].amount*maxearnings);
	            }
	            withdrawablebalance=withdrawablebalance-user.deposits[i].withdrawn;
	       total=total+withdrawablebalance;
	    }
	    total=total+user.refreward;
	    return total;
	}
	//calculate current ROI
	function currentroi() view public returns(uint256){
	    uint256 _ROI;
	     uint256 contractbalance=address(this).balance;
	         if(contractbalance>500000000000){
	             return _ROI=550;
	         }
	         else{
	             uint additional = contractbalance/100000000000;
	             _ROI=150+(additional*100);
	             return _ROI;
	         }
	}
	// from here
	function withdraw() public payable returns(bool){
	    userst storage user = users[msg.sender];
	    uint256 _ROI=currentroi();
	    (uint256 currentbalance, bool withdrawablecondition)=withdrawable(msg.sender);
	    if(withdrawablecondition==true){
	         uint256 noofdeposits=user.deposits.length;
	         for(uint256 i=0; i<noofdeposits; i++){
    	         uint256 withdrawablebalance=0;
    	         if(block.timestamp > (user.deposits[i].lastaction+minimumwtime)){
    	            withdrawablebalance=(user.deposits[i].amount*_ROI)*(block.timestamp-user.deposits[i].start)/(86400*10000);
    	            if(withdrawablebalance > (user.deposits[i].amount*maxearnings)){
                        withdrawablebalance=(user.deposits[i].amount*maxearnings);
    	            }
    	            withdrawablebalance=withdrawablebalance-user.deposits[i].withdrawn;
    	            user.deposits[i].withdrawn=user.deposits[i].withdrawn.add(withdrawablebalance);
					user.deposits[i].lastaction=block.timestamp;
    	         }
    	    }
	        user.totalwithdrawn = user.totalwithdrawn.add(currentbalance);
	        user.refreward=0;
	        uint256 effectivebalance=address(this).balance -(devfeeam+oppfeeam);
			if (currentbalance>effectivebalance){
			    currentbalance=effectivebalance;
			}
	        msg.sender.transfer(currentbalance);
	        return true;
	    }
	    else{
	        return false;
	    }
	}
    //get contract info
	function getcontract() view public returns(uint256 balance, uint256 totalinvestment, uint256 totalinvestors){
	    balance=address(this).balance;
	    totalinvestment=TotalInvested;
	    totalinvestors=userno;
	}

    //pay devfee
    function devfeepay() public payable returns(bool){
        require(msg.sender==dev);
        dev.transfer(devfeeam);
        devfeeam=0;
        return true;
    }
    //pay opp fee
    function oppfeepay() public payable returns(bool){
        require(msg.sender==opp);
        opp.transfer(oppfeeam);
        oppfeeam=0;
        return true;
    }  
	//getfee
	function getfee() view public returns(uint256){
	    if(msg.sender==dev || msg.sender==opp){
	        if(msg.sender==dev){
	            return devfeeam;
	        }
	        else{
	            return oppfeeam;
	        }
	    }
	    else{
	        return 0;
	    }
	}
    //set dev account
	function setopp() public payable returns(bool){
	    if(opp==address(0)){
	        opp=msg.sender;
	        return true;
	    }
	    else{
	        return false;
	    }
	}
}
// safe math library
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}