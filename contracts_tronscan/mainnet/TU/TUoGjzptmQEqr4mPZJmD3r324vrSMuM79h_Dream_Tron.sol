//SourceUnit: TESTCONTRACT.sol

//Dream Tron - Smart Sustainable Contract https://dreamtron.org
//Earn up to 7X your investment in 14 days using our Term Plan
//Earn up to 2X your investment using our simple plan with 20% ROI
//Audited verified no back door.
//Low fee High profit

pragma solidity ^0.5.10;
//contract name
contract Dream_Tron {
    //Importing safe SafeMath
	using SafeMath for uint256;
	// total amount invested in the contract
	uint256 public TotalInvested;
    mapping(address => userst) internal users;
    //base variables
    uint256[] public referralreward = [5, 3, 1];
	uint256 maximum=25000000000;
	uint256 maxearnings=2;
	uint256 minimum=100000000;
    uint256 minimumwtime=86400;
    uint256 public ROI;
    uint256 public oppfee;
    uint256 public daysplan=1209600;
    uint256 public devfee;
    address payable public opp;
    address payable public dev;
    uint256 userno;
	//define deposit sructure
	struct deposit {
		uint256 amount;
		uint256 start;
		uint256 withdrawn;
		uint256 plan;
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
	    oppfee=5;
	    devfee=5;
	    opp=msg.sender;
	    dev=address(0);
	    ROI=2000;
	    userno=0;
	    TotalInvested =0;
	}
	function invest(address referrer, uint256 plan) public payable returns(bool){
	    require(msg.value>=minimum);
	    require(plan<2);
	    require(plan>=0);
        userst storage user = users[msg.sender];
        TotalInvested=TotalInvested+msg.value;
        // first time users
        if(users[msg.sender].deposits.length == 0){
            userno=userno+1;
            user.wallet=msg.sender;
            uint256 fee=msg.value.div(10);
	        fee=fee/2;
	        opp.transfer(fee);
	        dev.transfer(fee);
	        if(plan==0){
	            user.deposits.push(deposit(msg.value, block.timestamp, 0, plan, 0));
	        }
	        else{
            user.deposits.push(deposit(msg.value, block.timestamp, 0, plan, block.timestamp));
	        }
            user.totalwithdrawn=0;
            user.refreward=0;
            if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
    				user.referrer = referrer;
    			}
    			else{
    			    user.referrer =address(0);
    			}
        }
        //re investment
        else{
          user.wallet=msg.sender;
          uint256 fee=msg.value.div(10);
	        fee=fee/2;
	        opp.transfer(fee);
	        dev.transfer(fee);
					if(plan==0){
	            user.deposits.push(deposit(msg.value, block.timestamp, 0, plan, 0));
	        }
	        else{
            user.deposits.push(deposit(msg.value, block.timestamp, 0, plan, block.timestamp));
	        }
        }
        //paying referrel rewards
      address upline = user.referrer;
    	for (uint256 i = 0; i < 3; i++) {
    		if (upline != address(0)) {
    		uint256 amount = msg.value.mul(referralreward[i]).div(100);
				users[upline].refreward = users[upline].refreward.add(amount);
				upline = users[upline].referrer;
    		} else break;
    	}
    	return true;
	}
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
	        b = abi.encodePacked(b,'"plan":');
	        b = abi.encodePacked(b,uint2str(user.deposits[i].plan));
	        b = abi.encodePacked(b,",");
	        b = abi.encodePacked(b,'"lastaction":');
	        b = abi.encodePacked(b,uint2str(user.deposits[i].lastaction));
	        b = abi.encodePacked(b,"}");
	    }
    b = abi.encodePacked(b, "]}");
    s = string(b);
	}
	function profits(address _address) view public returns(uint256 total){
	    userst storage user = users[_address];
	     uint256 noofdeposits=user.deposits.length;
	     total=0;
	     uint256 withdrawablebalance=0;
	     for(uint256 i=0; i<noofdeposits; i++){
	         uint256 _plan=user.deposits[i].plan;
	         if(_plan==0){
	            withdrawablebalance=(user.deposits[i].amount*ROI)*(block.timestamp-user.deposits[i].start)/(86400*10000);
	            if(withdrawablebalance > (user.deposits[i].amount*maxearnings)){
                    withdrawablebalance=(user.deposits[i].amount*maxearnings);
	            }
	            withdrawablebalance=withdrawablebalance-user.deposits[i].withdrawn;
	         }
	         if(_plan==1 && user.deposits[i].withdrawn==0){
	            withdrawablebalance=(user.deposits[i].amount*5000)*(block.timestamp-user.deposits[i].start)/(86400*10000);
	            if(withdrawablebalance > (user.deposits[i].amount*7)){
                    withdrawablebalance=(user.deposits[i].amount*7);
	            }
	         }
	       total=total+withdrawablebalance;
	    }
	    total=total+user.refreward;
	}
	function withdrawable(address _address) view public returns(uint256 total, bool status){
      userst storage user = users[_address];
	     uint256 noofdeposits=user.deposits.length;
	     total=0;
       status=false;
	     uint256 withdrawablebalance=0;
	     for(uint256 i=0; i<noofdeposits; i++){
	         uint256 _plan=user.deposits[i].plan;
	         if(_plan==0 && block.timestamp > (user.deposits[i].lastaction+minimumwtime)){
	            withdrawablebalance=(user.deposits[i].amount*ROI)*(block.timestamp-user.deposits[i].start)/(86400*10000);
	            if(withdrawablebalance > (user.deposits[i].amount*maxearnings)){
                    withdrawablebalance=(user.deposits[i].amount*maxearnings);
	            }
	            withdrawablebalance=withdrawablebalance-user.deposits[i].withdrawn;
              status=true;
	         }
	         if(_plan==1 && user.deposits[i].withdrawn==0 && block.timestamp > (user.deposits[i].start+daysplan)){
	            withdrawablebalance=(user.deposits[i].amount*5000)*(block.timestamp-user.deposits[i].start)/(86400*10000);
	            if(withdrawablebalance > (user.deposits[i].amount*7)){
                    withdrawablebalance=(user.deposits[i].amount*7);
                    status=true;
	            }
	         }
	       total=total+withdrawablebalance;
	    }
	    total=total+user.refreward;
	}
	function withdraw()public payable returns(bool){
	    userst storage user = users[msg.sender];
	    (uint256 currentbalance, bool withdrawablecondition)=withdrawable(msg.sender);
	    if(withdrawablecondition==true){
	         uint256 noofdeposits=user.deposits.length;
    	     for(uint256 i=0; i<noofdeposits; i++){
    	         uint256 _plan=user.deposits[i].plan;
    	         uint256 withdrawablebalance=0;
    	         if(_plan==0 && block.timestamp > (user.deposits[i].lastaction+minimumwtime)){
    	            withdrawablebalance=(user.deposits[i].amount*ROI)*(block.timestamp-user.deposits[i].start)/(86400*10000);
    	            if(withdrawablebalance > (user.deposits[i].amount*maxearnings)){
                        withdrawablebalance=(user.deposits[i].amount*maxearnings);
    	            }
    	            withdrawablebalance=withdrawablebalance-user.deposits[i].withdrawn;
    	            user.deposits[i].withdrawn=user.deposits[i].withdrawn.add(withdrawablebalance);
									user.deposits[i].lastaction=block.timestamp;
    	         }
    	         if(_plan==1 && block.timestamp > (user.deposits[i].start+daysplan) && user.deposits[i].withdrawn==0){
    	            withdrawablebalance=user.deposits[i].amount*7;
    	            user.deposits[i].withdrawn=user.deposits[i].withdrawn.add(withdrawablebalance);
					user.deposits[i].lastaction=block.timestamp;
    	         }
    	    }
	        user.totalwithdrawn = user.totalwithdrawn.add(currentbalance);
	        user.refreward=0;
					if (currentbalance>address(this).balance){
						currentbalance=address(this).balance;
					}
	        msg.sender.transfer(currentbalance);
	        return true;
	    }
	    else{
	        return false;
	    }
	}

	function reinvest(uint256 _plan)public payable returns(bool){
	    require(_plan<2);
	    require(_plan>=0);
        userst storage user = users[msg.sender];
	    (uint256 currentbalance, bool withdrawablecondition)=withdrawable(msg.sender);
	    if(withdrawablecondition==true){
	         uint256 noofdeposits=user.deposits.length;
    	     for(uint256 i=0; i<noofdeposits; i++){
						  uint256 plans=user.deposits[i].plan;
    	         uint256 withdrawablebalance=0;
							 if(plans==0 && block.timestamp > (user.deposits[i].lastaction+minimumwtime)){
    	            withdrawablebalance=(user.deposits[i].amount*ROI)*(block.timestamp-user.deposits[i].start)/(86400*10000);
    	            if(withdrawablebalance > (user.deposits[i].amount*maxearnings)){
                        withdrawablebalance=(user.deposits[i].amount*maxearnings);
    	            }
    	            withdrawablebalance=withdrawablebalance-user.deposits[i].withdrawn;
    	            user.deposits[i].withdrawn=user.deposits[i].withdrawn.add(withdrawablebalance);
									user.deposits[i].lastaction=block.timestamp;
    	         }
    	         if(plans==1 && block.timestamp > (user.deposits[i].start+daysplan) && user.deposits[i].withdrawn==0){
    	            withdrawablebalance=user.deposits[i].amount*7;
    	            user.deposits[i].withdrawn=user.deposits[i].withdrawn.add(withdrawablebalance);
									user.deposits[i].lastaction=block.timestamp;
    	         }
    	    }
	        user.totalwithdrawn = user.totalwithdrawn.add(currentbalance);
	        user.refreward=0;
	        if(_plan==0){
	            user.deposits.push(deposit(currentbalance, block.timestamp, 0, _plan, block.timestamp));
	        }
	        else{
            user.deposits.push(deposit(currentbalance, block.timestamp, 0, _plan, block.timestamp));
	        }
	        uint256 fee=msg.value.div(10);
	        fee=fee/2;
	        opp.transfer(fee);
	        dev.transfer(fee);
            return true;
	    }
	    else{
	        return false;
	    }
	}
	function getcontract()view public returns(uint256 balance, uint256 totalinvestment, uint256 totalinvestors){
	    balance=address(this).balance;
	    totalinvestment=TotalInvested;
	    totalinvestors=userno;
	}

	function setdev() public payable returns(bool){
	    if(dev==address(0)){
	        dev=msg.sender;
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