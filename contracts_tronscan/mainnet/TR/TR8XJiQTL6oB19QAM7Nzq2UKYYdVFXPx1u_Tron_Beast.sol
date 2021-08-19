//SourceUnit: contract.sol

//Tron Beast - Smart Sustainable Contract https://tronbeast.org
//Earn up to 250% your investment.
//Audited & verified no back door.
//Low fee High profit
//By interaction with this contract you are agreeing to the terms and conditions published in https://tronbeast.org/TOS.html
// Copying this contract in anyway will result in strong legal actions. The SourceCode has been protected by international copyright laws.

pragma solidity ^0.5.10;
//contract name
contract Tron_Beast {
  //Importing safe SafeMath
	using SafeMath for uint256;
	// total amount invested in the contract
	uint256 public TotalInvested;
  mapping(address => userst) internal users;
  //base variables
  uint256[] public referralreward = [8, 3, 2, 1, 1];
	uint256 maxearnings=25;
	uint256 minimum=100000000;
  uint256 minimumwtime=86400;
  uint256 public oppfee;
  uint256 public devfee;
  address payable public opp;
  address payable public dev;
  uint256 userno;
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
	    uint256 lastactions;
	}
	//contract varibles
	constructor() public{
	    oppfee=80;
	    devfee=70;
	    dev=msg.sender;
	    opp=address(0);
	    userno=0;
	    TotalInvested =0;
	}
	function invest(address referrer) public payable returns(bool){
	    require(msg.value>=minimum && msg.sender!=referrer);
        userst storage user = users[msg.sender];
        TotalInvested=TotalInvested+msg.value;
        // first time users
        if(users[msg.sender].deposits.length == 0){
            userno=userno+1;
            user.wallet=msg.sender;
            uint256 feesdev=(msg.value.div(1000)).mul(70);
            uint256 feesop=(msg.value.div(1000)).mul(80);
	        	opp.transfer(feesop);
	        	dev.transfer(feesdev);
            user.deposits.push(deposit(msg.value, block.timestamp, 0, block.timestamp));
            user.totalwithdrawn=0;
            user.lastactions=block.timestamp;
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
            uint256 feesdev=(msg.value.div(1000)).mul(70);
            uint256 feesop=(msg.value.div(1000)).mul(80);
	        	opp.transfer(feesop);
	        	dev.transfer(feesdev);
            user.deposits.push(deposit(msg.value, block.timestamp, 0, block.timestamp));
            user.lastactions=block.timestamp;
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
    function getuser(address uaddr) public view returns(address wallet, address referrer, uint256 refreward, uint256 totalwithdrawn, uint256 noofdeposits, uint256 total, uint256 lastupdate){
	    userst storage user = users[uaddr];
	    wallet=user.wallet;
	    referrer=user.referrer;
	    refreward=user.refreward;
	    totalwithdrawn=user.totalwithdrawn;
	    noofdeposits=user.deposits.length;
	    total=0;
			lastupdate=user.lastactions;
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
	        if(block.timestamp > (user.lastactions+minimumwtime)){
	            withdrawablebalance=(user.deposits[i].amount*_ROI)*(block.timestamp-user.deposits[i].start)/(86400*10000);
	            if(withdrawablebalance > (user.deposits[i].amount*maxearnings)/10){
                    withdrawablebalance=(user.deposits[i].amount*maxearnings)/10;
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
	            if(withdrawablebalance > (user.deposits[i].amount*maxearnings)/10){
                    withdrawablebalance=(user.deposits[i].amount*maxearnings)/10;
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
	         if(contractbalance>16000000000000){
	             return _ROI=320;
	         }
	         else{
	             uint additional = contractbalance/1000000000000;
	             _ROI=170+(additional*10);
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
    	            if(withdrawablebalance > (user.deposits[i].amount*maxearnings)/10){
                        withdrawablebalance=(user.deposits[i].amount*maxearnings)/10;
    	            }
    	            withdrawablebalance=withdrawablebalance-user.deposits[i].withdrawn;
    	            user.deposits[i].withdrawn=user.deposits[i].withdrawn.add(withdrawablebalance);
					 user.deposits[i].lastaction=block.timestamp;
    	         }
    	    }
	        user.totalwithdrawn = user.totalwithdrawn.add(currentbalance);
	        user.refreward=0;
					user.lastactions=block.timestamp;
	        uint256 effectivebalance=address(this).balance;
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