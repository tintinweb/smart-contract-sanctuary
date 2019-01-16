pragma solidity ^0.5.1;


contract Assets {

	struct Investor {
			uint id;
			uint invested;
			uint invested_count;
			uint payments;
			uint payments_count;
			uint[] refer_bonus;
			uint[] refer_bonus_count;
			uint cashback;
			address payable refer;
			address[] referals;
			uint referals_count;
			uint last_payment;
			uint first_invest;
	}

	event Operation(
		address investor,
		uint date,
		uint amount,
		uint otype
	);

	event Registration(
		address investor,
		uint date,
		address refer,
		uint otype
	);

	event RefBonus(
		address investor,
		uint date,
		uint amount,
		uint otype,
		address meta,
		uint lvl
	);
}



contract Eva is Assets{
	using SafeMath for uint;
	using ToAddress for *;
	using Zero for *;



	//init Statistics
	uint public all_invest_count = 0;
	uint public all_invest = 0;
	uint public all_payments_count = 0;
	uint public all_payments = 0;
	uint public all_marketing_payments = 0;
	uint public all_cashbacks = 0;
	uint public all_cashbacks_count = 0;
	uint public investors_count = 0;
	uint[] private admin_ref_sys_payment = [0,0,0];
	uint[] private admin_ref_sys_payment_count = [0,0,0];
	uint[] private all_refer_bonus = [0,0,0];
	uint[] private all_refer_bonus_count = [0,0,0];

	//init Constants
	uint private marketingFee = 1500;
	uint private dividends = 188;
	uint constant private cashback_percent = 300;

	uint constant private sec_in_24h = 1 days;
	uint constant private min_invesment = 10 finney;

  //refer config
	uint[] private refer_levels = [0 finney, 5 ether, 20 ether];
	uint[] private refer_bonus_percent = [1000,500,300];

	//init other variables
	address payable private admin;
	uint constant reg_otype = 4;
	uint constant cashback_otype = 3;
	uint constant refer_bonus_otype = 2;
	uint constant invest_otype = 1;
	uint constant payments_otype = 0;

	//investors
	mapping (address => Investor) public investors;
	address[] public investors_indexes;

	constructor() public{
	    admin = msg.sender;
	}

	modifier onlyAdmin{
		require(msg.sender == admin, "Admin only");
		_;
	}

	function() payable external{
		Investor storage investor = investors[msg.sender];

		//payment
		if(investor.invested > 0){
			uint amount = 0;
			amount = investor.invested.mul(dividends).div(10000).mul(now.sub(investor.last_payment)).div(sec_in_24h);
			if(amount > 0){

				investor.last_payment = now;
				require(amount < address(this).balance, "insufficient balance");

				//payment investor statistics
				investor.payments_count++;
				investor.payments += amount;

				//payment global statistics
				all_payments_count++;
				all_payments += amount;

				//payment operation
				emit Operation(msg.sender,now,amount,payments_otype);
				msg.sender.transfer(amount);
			}
		}

		//investment
		if(msg.value > 0){
			require(msg.value >= min_invesment, "value to invest must be >= 0.01 ether");
			//create user
			if(investor.invested == 0){
				investors_indexes.push(msg.sender);
				investor.id = investors_count;
				investors_count++;
				investor.invested = 0;
				investor.invested_count = 0;
				investor.payments = 0;
				investor.payments_count = 0;
				investor.refer = address(0);
				investor.cashback = 0;
				investor.refer_bonus = [0,0,0];
				investor.refer_bonus_count = [0,0,0];
				investor.first_invest = now;
				investor.last_payment = now;
				address payable ref_addr = msg.data.toAddr();
				if(ref_addr.notZero()){
					require(investors[ref_addr].invested != 0, "refer address not found");

					investor.refer = ref_addr;
					investors[ref_addr].referals.push(msg.sender);
					investors[ref_addr].referals_count++;

					//cashback
					uint cashback_amount = msg.value.mul(cashback_percent).div(10000);

					//cashback investor statistics
					investor.cashback = cashback_amount;
					//payment global statistics
					all_cashbacks += cashback_amount;
					all_cashbacks_count++;

					//cashback operation
					emit Registration(msg.sender,now,ref_addr,reg_otype);
					emit Operation(msg.sender,now,cashback_amount,cashback_otype);
					msg.sender.transfer(cashback_amount);
				}else
					emit Registration(msg.sender,now,address(0),reg_otype);
			}

			//investment investor statistics
			investor.invested_count++;
			investor.invested += msg.value;
			//investment global statistics
			all_invest_count++;
			all_invest += msg.value;
			//investment operation
			emit Operation(msg.sender,now,msg.value,invest_otype);

			//refer bonus



			Investor storage investor_refer = investor;
			uint sum = 0;
			for(uint lvl = 0; lvl < refer_bonus_percent.length; lvl++){
				sum = msg.value.mul(refer_bonus_percent[lvl]).div(10000);
				if(investor_refer.refer.notZero()){
					if(getInvestorStatus(investor_refer.refer) > lvl){
						//refer bonus investor statistics
						investors[investor_refer.refer].refer_bonus_count[lvl]++;
						investors[investor_refer.refer].refer_bonus[lvl] += sum;
						//refer bonus global statistics
						all_refer_bonus[lvl] += sum;
						all_refer_bonus_count[lvl]++;
						//refer bonus operation
						emit RefBonus(investor_refer.refer, now, sum, refer_bonus_otype, msg.sender, lvl.add(1));
						address(investor_refer.refer).transfer(sum);

						sum = 0;
					 }
					 investor_refer = investors[investor_refer.refer];
				}

				if(sum>0){
					admin_ref_sys_payment[lvl] += sum;
					admin_ref_sys_payment_count[lvl]++;
					admin.transfer(sum);
				}
			}
			//marketing fee
		    uint fee = msg.value.mul(marketingFee).div(10000);
		    all_marketing_payments += fee;
			admin.transfer(fee);
		}
	}

	function getReferals(address investor) public view onlyAdmin returns (address[] memory){
		return investors[investor].referals;
	}

	// returns available level to collect refer_bonus
	function getInvestorStatus(address investor) private view returns (uint){
		uint sum = investors[investor].invested;
		require(sum > 0);
		for(uint i = refer_levels.length-1; i >= 0; i--){
			if(sum >= refer_levels[i])
				return i+1;
		}
		return 0;
	}
}

library SafeMath {
	function mul(uint a, uint b) internal pure returns (uint) {
		if (a == 0) {
			return 0;
		}
		uint c = a * b;
		require(c / a == b);
		return c;
	}

	function div(uint a, uint b) internal pure returns (uint) {
		require(b > 0);
		uint c = a / b;
		return c;
	}

	function sub(uint a, uint b) internal pure returns (uint) {
		require(b <= a);
		uint c = a - b;
		return c;
	}

	function add(uint a, uint b) internal pure returns (uint) {
		uint c = a + b;
		require(c >= a);
		return c;
	}

	function mod(uint a, uint b) internal pure returns (uint) {
		require(b != 0);
		return a % b;
	}
}


library ToAddress {
	function toAddr(uint source) internal pure returns(address payable) {
		return address(source);
	}

	function toAddr(bytes memory source) internal pure returns(address payable addr) {
		assembly { addr := mload(add(source,0x14)) }
		return addr;
	}
}

library Zero {
	function requireNotZero(uint a) internal pure {
		require(a != 0, "require not zero");
	}

	function requireNotZero(address addr) internal pure {
		require(addr != address(0), "require not zero address");
	}

	function notZero(address addr) internal pure returns(bool) {
		return !(addr == address(0));
	}

	function isZero(address addr) internal pure returns(bool) {
		return addr == address(0);
	}
}