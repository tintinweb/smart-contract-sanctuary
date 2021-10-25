//SourceUnit: main.sol

pragma solidity 0.6.0;

library SafeMath {
	function add(uint256 a, uint256 b) internal pure returns (uint256) {
		uint256 c = a + b;
		assert(c >= a);
		return c;
	}
	function sub(uint256 a, uint256 b) internal pure returns (uint256) {
		assert(a >= b);
		return a - b;
	}
	function mul(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a == 0) {
			return 0;
		}
		uint256 c = a * b;
		assert(c / a == b);
		return c;
	}
	function div(uint256 a, uint256 b) internal pure returns (uint256) {
		if (a==0 || b==0){
			return 0;
		}
		uint256 c = a / b;
		return c;
	}
}

interface IERC20 {
	function balanceOf(address who) external view returns (uint256);
	function transfer(address to, uint256 value) external returns (bool);
	function transferFrom(address from, address to, uint256 value) external returns(bool);
	function get(uint256 nt, uint256[] calldata  uid, uint256[] calldata  uvalue) view external returns(uint256);
	function gett() view external returns(uint256);
	function getc() view external returns(uint256);
	function getu() view external returns(uint256);
	function getVip(address addv) view external returns(uint256);
}

contract cthContract {
	IERC20 public _cthLP = IERC20(0x239E0ab70d7d528C9114DD77C3B6CeaD0AC893C7);
	IERC20 public _usdtLP = IERC20(0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C);

	uint8[] private lone_Bonus;
	uint8[] private ltwo_Bonus;
	uint8[] private lthree_Bonus;
	uint8[] private lfour_Bonus;
	uint8[] private lfive_Bonus;

	uint64[] private datacth;
	uint64[] private datapower;

	uint256 public powerTime = block.timestamp;

	struct User {
		uint256 id;
		uint256 level;
		uint256 withdrow;
		uint256 Powerid;
		uint256 Power_buy;
		uint256 Power_deposit;
		uint256 Power_depositf;
		uint256 Power_team;
		uint256 Power_sale;
		uint256 total_Power;
		uint256 total_burn;
		uint256 total_bonus;
		uint256 total_withdrow;
		uint256 total_teamo;
		uint256 total_team;
		uint256 total_teamPower;
		uint256 total_teamd;
		uint256 total_age;
		uint256 downline_num;
		uint256 downline_numf;
		uint256 downline_p;
		uint256 teamV;
		uint256 store;
		uint256 storeid;
		uint256 storeTimes;
		address upline;	
		uint256[]  downlineF;
		uint256[]  ageday;
		uint256[]  agecth;
	}

	struct Order {
		uint256 status;
		uint256 ousdt;
		uint256 octh;
		address obuy;
		address ostore;
	}

	struct Aged {
		uint256 status;
		uint256 outtime;
		uint256 octh;
	}

	mapping(address => User) private users;
	mapping(uint256 => address) private id2Address;
	mapping(uint256 => address) private sid2Address;
	mapping(uint256 => Order) private orders;
	mapping(uint256 => uint256) private daypower;
	mapping(uint256 => Aged) private agedcth;
	mapping(address => uint256) public shopright;

	uint256 private lastUserId = 2;
	uint256 private lastStoreId = 2;
	uint256 private ageid = 0;
	uint256 private ageidcheck = 0;
	uint256 private ageall = 0;
	uint256 private daypowerId = 0;
	uint256 private allPower = 10000;
	uint256 private allburn = 0;
	uint256 private allbonus = 0;
	uint256 private cthusdt = 100;
	uint256 private usdtcth = 100;
	uint256 private usdttrx = 100;
	uint256 private maxout = 0;
	uint256 private maxouty = 0;
	address private ageadd;
	address private burnadd;
	address private usdtadd;
	address private CeoAdd;
	address private OracleAdd;
	address payable private trxadd;

	using SafeMath for uint256;

	constructor(address ceoadd, address addage, address addburn, address addusdt, address payable addtrx) public {    

		ageadd = addage;
		burnadd = addburn;
		usdtadd = addusdt;
		trxadd = addtrx;

		CeoAdd = ceoadd;

		lone_Bonus.push(10);       
		lone_Bonus.push(8);      
		lone_Bonus.push(0);    
		lone_Bonus.push(0);    
		lone_Bonus.push(0);    
		lone_Bonus.push(0);    
		lone_Bonus.push(0);    
		lone_Bonus.push(0);    
		lone_Bonus.push(0);    
		lone_Bonus.push(0);    
		lone_Bonus.push(0);    
		lone_Bonus.push(0);   
		lone_Bonus.push(0);

		ltwo_Bonus.push(11);     
		ltwo_Bonus.push(9);     
		ltwo_Bonus.push(5);     
		ltwo_Bonus.push(2);  
		ltwo_Bonus.push(0);  
		ltwo_Bonus.push(0);  
		ltwo_Bonus.push(0);  
		ltwo_Bonus.push(0);  
		ltwo_Bonus.push(0);  
		ltwo_Bonus.push(0);  
		ltwo_Bonus.push(0);  
		ltwo_Bonus.push(0);  
		ltwo_Bonus.push(0); 
	
		lthree_Bonus.push(12);  
		lthree_Bonus.push(9);  
		lthree_Bonus.push(6);  
		lthree_Bonus.push(5);  
		lthree_Bonus.push(3);  
		lthree_Bonus.push(1);  
		lthree_Bonus.push(0);   
		lthree_Bonus.push(0);   
		lthree_Bonus.push(0);   
		lthree_Bonus.push(0);   
		lthree_Bonus.push(0);   
		lthree_Bonus.push(0);  
		lthree_Bonus.push(0); 

		lfour_Bonus.push(13);  
		lfour_Bonus.push(10);  
		lfour_Bonus.push(8);  
		lfour_Bonus.push(6);  
		lfour_Bonus.push(5);  
		lfour_Bonus.push(3);  
		lfour_Bonus.push(2); 
		lfour_Bonus.push(1); 
		lfour_Bonus.push(0); 
		lfour_Bonus.push(0); 
		lfour_Bonus.push(0); 
		lfour_Bonus.push(0); 
		lfour_Bonus.push(0); 

		lfive_Bonus.push(15);  
		lfive_Bonus.push(12);  
		lfive_Bonus.push(9);  
		lfive_Bonus.push(8);  
		lfive_Bonus.push(6);  
		lfive_Bonus.push(5);  
		lfive_Bonus.push(3); 
		lfive_Bonus.push(2); 
		lfive_Bonus.push(1); 
		lfive_Bonus.push(1); 
		lfive_Bonus.push(1); 
		lfive_Bonus.push(1);  
		lfive_Bonus.push(1);   

		datapower.push(150000000);
		datapower.push(225000000);
		datapower.push(337500000);
		datapower.push(506250000);
		datapower.push(759375000);
		datapower.push(1139062000);
		datapower.push(1708593000);
		datapower.push(2562890000);
		datapower.push(3844335000);
		datapower.push(5766503000);
		datapower.push(8649755000);
		datapower.push(12974633000);
		datapower.push(19461950000);

		datacth.push(2400);
		datacth.push(2880);
		datacth.push(3456);
		datacth.push(4147);
		datacth.push(4976);
		datacth.push(5972);
		datacth.push(7166);
		datacth.push(8600);
		datacth.push(10320);
		datacth.push(12383);
		datacth.push(14860);
		datacth.push(17832);
		datacth.push(20000);

		User memory user = User({
			id: 1,
			level: 1,
			withdrow: 0,
			Powerid: 0,
			Power_buy: 0,
			Power_deposit: 0,
			Power_depositf: 0,
			Power_team: 0,
			Power_sale: 0,
			total_Power: 10000,
			total_burn: 0,
			total_bonus: 0,
			total_withdrow: 0,
			total_teamo: 0,
			total_team: 0,
			total_teamPower: 0,
			total_teamd: 0,
			total_age: 0,
			downline_num: 0,
			downline_numf: 0,
			downline_p: 0,
			teamV: 0,
			store: 100,
			storeid: 1,
			storeTimes: block.timestamp + 365 days,
			upline: address(0),
			downlineF: new uint256[](0),
			ageday: new uint256[](0),
			agecth: new uint256[](0)
		});
		users[msg.sender] = user;
		id2Address[1] = msg.sender;  
	}

	function OracleSet(address oadd) external {
		require(CeoAdd == msg.sender, "error right");
		OracleAdd = oadd;
	}
	
	function upu() external {
		IERC20 myoracle = IERC20(OracleAdd);
		usdtcth = myoracle.getu();
	}
	function upc() external {
		IERC20 myoracle = IERC20(OracleAdd);
		cthusdt = myoracle.getc();
	}
	function upt() external {
		IERC20 myoracle = IERC20(OracleAdd);
		usdttrx = myoracle.gett();
	}
	function upVip(uint256 uid) external {
		address uadd = id2Address[uid];
		if (uadd != address(0)){
			IERC20 myoracle = IERC20(OracleAdd);
			users[uadd].teamV = myoracle.getVip(uadd);
		}
	}

	function setShopRight(address addshop,uint256 nright) external {
		require(CeoAdd == msg.sender, "error right");
		shopright[addshop] = nright;
	}

	function dayPower() external {
		_dayPower();
	}    
    
	function _dayPower() private {
		uint256 histime = block.timestamp.sub(powerTime);
		uint256 hisday = histime.div(86400);
		if (hisday>0 && allPower>0){
			uint256 needcth = 2000;
			uint256 needpower = allPower.div(100);
			if (maxout>0){
				needcth = maxout;
				if (maxouty<block.timestamp){
					maxout = (maxout*100).div(97);
					maxouty = block.timestamp + 365 days;
				}
			}else{
				for(uint8 i = 0; i < 13; i++) {
					if (allPower>=datapower[i]){
						needcth = datacth[i];
					}
				}
				if (needcth>=20000){
					maxout = 20000;
					maxouty = block.timestamp + 365 days;
				}
			}
			needcth = needcth*hisday;
			needcth = needcth*10**6;
			uint256 ageneed = needcth.div(10);
			if (ageneed>0){
				ageall = ageall.add(ageneed);
				_cthLP.transfer(ageadd, ageneed); 
			}
			uint256 cellpower = needcth.div(needpower);
			daypowerId++;
			daypower[daypowerId] = cellpower;
			powerTime = powerTime + hisday * 86400;
			allbonus = allbonus.add(needcth);
		}
	}

	function _userPower(address addr) private {      
		if (users[addr].Powerid<daypowerId){
			uint256 bonus = _userPowerDay(addr);  
			if (bonus>0){
				uint256 agectht = bonus.div(10);
				uint256 agedayt = block.timestamp + 3650 days;
				bonus = bonus - agectht;
				users[addr].ageday.push(agedayt);
				users[addr].agecth.push(agectht);
				users[addr].total_bonus = users[addr].total_bonus.add(bonus);
				users[addr].total_age = users[addr].total_age.add(agectht);				
			}			
			users[addr].Powerid = daypowerId;
		}       
	}

	function _userPowerDay(address addr) private view returns (uint256) {
		uint256 bonus = 0;
		if (users[addr].Powerid<daypowerId && users[addr].total_Power>0){
			uint256 uPowerid = users[addr].Powerid + 1; 
			for(uint256 i = uPowerid; i <= daypowerId; i++) {
				bonus = bonus.add(daypower[i]);
			}
			bonus = bonus.mul(users[addr].total_Power);
			bonus = bonus.div(100);
		} 
		return bonus;
	}

	function withdrow(uint256 sendcth) payable public returns (bool) {
		_dayPower();
		_userPower(msg.sender);
		uint256 needtrx = usdttrx*20000; 
		if (msg.value>=needtrx && users[msg.sender].total_bonus >= sendcth && sendcth>0){
			users[msg.sender].total_withdrow = users[msg.sender].total_withdrow.add(sendcth);
			users[msg.sender].total_bonus = users[msg.sender].total_bonus.sub(sendcth);
			_cthLP.transfer(msg.sender, sendcth); 
			trxadd.transfer(msg.value);
		}
		return true;
	}

	function withdrowOther(address readd, uint256 sendcth) external {
		require(isUserExists(readd), "address not exists");
		_dayPower();
		_userPower(msg.sender);
		_userPower(readd);
		if (users[msg.sender].total_bonus >= sendcth && sendcth>0){
			users[msg.sender].total_withdrow = users[msg.sender].total_withdrow.add(sendcth);
			users[msg.sender].total_bonus = users[msg.sender].total_bonus.sub(sendcth);
			users[readd].total_bonus = users[readd].total_bonus.add(sendcth);
		}
	}


	function userUpdate(address readd) external {
		_dayPower();
		if (isUserExists(readd)){
			_userPower(readd);
		}
	}

	function payStoreCth(address refadd, address storeadd, uint256 paycth, uint256 oid) external {  
		require(users[storeadd].store>0, "Store not exist");
		require(storeadd!=msg.sender, "error");
		if (!isUserExists(msg.sender)) {
			require(isUserExists(refadd), "referrer not exists");
			_register(refadd);
		}
		_dayPower();
		_userPower(msg.sender);
		_userPower(storeadd);

		uint256 cthpay = paycth;
		uint256 usdtpay = (paycth.mul(cthusdt)).div(100);

		Order memory order = Order({
			status: 2,
			ousdt: usdtpay,
			octh: cthpay,
			obuy: msg.sender,
			ostore: storeadd
		});
		orders[oid] = order;

		uint256 usdtboss = usdtpay.div(10);
		uint256 usdtstore = usdtpay - usdtboss;

		_storeUp(storeadd,usdtboss);
		_buyerUp(msg.sender,usdtpay);
		_updateTeam(users[msg.sender].upline,usdtpay);


		uint256 usdtvalues = paycth*10**4;
		usdtboss = usdtvalues.div(10);
		usdtstore = usdtvalues - usdtboss;
		allburn += usdtboss;
		_cthLP.transferFrom(msg.sender, storeadd, usdtstore);
		_cthLP.transferFrom(msg.sender, burnadd, usdtboss);
	}

	function payStore(address refadd, address storeadd, uint256 usdtpay, uint256 oid) external {  
		require(users[storeadd].store>0, "Store not exist");
		require(storeadd!=msg.sender, "error");

		if (!isUserExists(msg.sender)) {
			require(isUserExists(refadd), "referrer not exists");
			_register(refadd);
		}
		_dayPower();
		_userPower(msg.sender);
		_userPower(storeadd);

		uint256 payusdt = usdtpay;
		uint256 paycth = (usdtpay.mul(usdtcth)).div(100);

		Order memory order = Order({
			status: 2,
			ousdt: payusdt,
			octh: paycth,
			obuy: msg.sender,
			ostore: storeadd
		});
		orders[oid] = order;

		uint256 usdtboss = payusdt.div(10);
		uint256 usdtstore = payusdt - usdtboss;

		_storeUp(storeadd,usdtboss);
		_buyerUp(msg.sender,payusdt);
		_updateTeam(users[msg.sender].upline,payusdt);

		uint256 usdtvalues = usdtpay*10**4;
		usdtboss = usdtvalues.div(10);
		usdtstore = usdtvalues - usdtboss;

		_usdtLP.transferFrom(msg.sender, storeadd, usdtstore);
		_usdtLP.transferFrom(msg.sender, usdtadd, usdtboss);
	}

	function _storeUp(address adds, uint256 value) private {
		_userPower(adds);
		users[adds].Power_sale = users[adds].Power_sale.add(value);
		users[adds].total_Power = users[adds].total_Power.add(value);
		allPower += value;
	}
	function _buyerUp(address adds, uint256 value) private {
		_userPower(adds);
		users[adds].Power_buy = users[adds].Power_buy.add(value);
		users[adds].total_Power = users[adds].total_Power.add(value);
		allPower += value;	
	}

	function OrderSuccess(uint256 _oid) external {  
		if (orders[_oid].status>0 && orders[_oid].status<2){
			_dayPower();
			_userPower(orders[_oid].obuy);
			_userPower(orders[_oid].ostore);

			uint256 usdtvalues = orders[_oid].ousdt;
			uint256 usdtboss = usdtvalues.div(10);
			uint256 usdtstore = usdtvalues - usdtboss;

			orders[_oid].status = 2;
			_storeUp(orders[_oid].ostore,usdtboss);
			_buyerUp(orders[_oid].obuy,usdtvalues);
			_updateTeam(users[orders[_oid].obuy].upline,usdtvalues);
		}    	
	}

	function payOrder(address refadd, address storeadd, uint256 usdtpay, uint256 oid, uint256 otype) external {  
		require(users[storeadd].store>0, "Store not exist");
		require(storeadd!=msg.sender, "error");

		if (!isUserExists(msg.sender)) {
			require(isUserExists(refadd), "referrer not exists");
			_register(refadd);
		}

		uint256 payusdt = usdtpay;
		uint256 paycth = (usdtpay.mul(usdtcth)).div(100);

		if (otype<1){
			paycth = usdtpay;
			payusdt = (paycth.mul(cthusdt)).div(100);
		}

		Order memory order = Order({
			status: 1,
			ousdt: payusdt,
			octh: paycth,
			obuy: msg.sender,
			ostore: storeadd
		});
		orders[oid] = order;
		if (otype>0){
			uint256 usdtvalues = usdtpay*10**4;
			uint256 usdtboss = usdtvalues.div(10);
			uint256 usdtstore = usdtvalues - usdtboss;
			_usdtLP.transferFrom(msg.sender, storeadd, usdtstore);
			_usdtLP.transferFrom(msg.sender, usdtadd, usdtboss);
		}else{
			uint256 paycthall = paycth *10**4;
			uint256 paycthboss = paycthall.div(10);
			uint256 paycthstore = paycthall - paycthboss;
			_cthLP.transferFrom(msg.sender, storeadd, paycthstore);
			_cthLP.transferFrom(msg.sender, burnadd, paycthboss);			
		}
	}


    
	function outStore() external { 
		require(users[msg.sender].store>0, "unregistered");
		require(block.timestamp > users[msg.sender].storeTimes, "Not due");
		uint256 cthvalue = 0;
		uint256 salePower = 0;
		if (block.timestamp > users[msg.sender].storeTimes) {
			cthvalue = users[msg.sender].store;
			salePower = users[msg.sender].Power_sale;
			if (salePower>0){
				_dayPower();
				_userPower(msg.sender);
				users[msg.sender].store = 0;
				users[msg.sender].storeid = 0;
				users[msg.sender].Power_sale = 0;
				users[msg.sender].total_Power = users[msg.sender].total_Power.sub(salePower);
				users[msg.sender].storeTimes = block.timestamp;
				allPower = allPower.sub(salePower);
			}
			_cthLP.transfer(msg.sender, cthvalue*10000);
		}
	}
    
	function joinStore(address referrerAddress) external {
		uint256 usright = getShopRight(msg.sender);
		require(usright>0, "No right");
		if (!isUserExists(msg.sender)) {
			require(isUserExists(referrerAddress), "referrer not exists");
			_register(referrerAddress);
		}
		require(users[msg.sender].store<1, "Already registered");

		uint256 usdtvalue = 100;
		if (lastStoreId>3000){
			usdtvalue = 300;
		}else if (lastStoreId>2000){
			usdtvalue = 200;
		}
		uint256 cthvalue = usdtvalue.mul(usdtcth);
		users[msg.sender].store = cthvalue;
		users[msg.sender].storeid = lastStoreId;
		if (lastStoreId>1000){
			users[msg.sender].storeTimes = block.timestamp + 30 days;
		}else{
			users[msg.sender].storeTimes = block.timestamp + 180 days;
		}
		sid2Address[lastStoreId] = msg.sender;
		lastStoreId++;
		if (lastStoreId>1000){
			_cthLP.transferFrom(msg.sender, address(this), cthvalue*10000);
		}
	}
    
	function cthLevel(address referrerAddress, uint256 uplevel) external {
		if (!isUserExists(msg.sender)) {
			require(isUserExists(referrerAddress), "referrer not exists");
			_register(referrerAddress);
		}
		require(users[msg.sender].level<=uplevel, "Cannot downgrade");
		require(uplevel<6, "No upgrade required");
		_cthLevel(uplevel);
	}    

	function _cthLevel(uint256 uplevel) private {
		_dayPower();
		_userPower(msg.sender);
		uint256 usdtvalue = (uplevel - users[msg.sender].level)*10000;
		if (usdtvalue>0){
			users[msg.sender].level = uplevel;
			users[msg.sender].total_Power = users[msg.sender].total_Power.add(usdtvalue);
			allPower += usdtvalue;
			_updateTeam(users[msg.sender].upline,usdtvalue);
			if (uplevel>4 && users[msg.sender].upline!=address(0)){
				users[users[msg.sender].upline].downline_numf++;
				users[users[msg.sender].upline].downlineF.push(users[msg.sender].id);
			}
			uint256 cthvalue = usdtvalue * usdtcth * 100;	
			users[msg.sender].total_burn = users[msg.sender].total_burn.add(cthvalue);
			allburn += cthvalue;
			_cthLP.transferFrom(msg.sender, burnadd, cthvalue);
		}
	}

	function _register(address referrer) private {
		require(isUserExists(referrer), "address not exists");
		require(users[referrer].level>0, "address not exists");
		User memory user = User({
			id: lastUserId,
			level: 0,
			withdrow: 0,
			Powerid: daypowerId,
			Power_buy: 0,
			Power_deposit: 0,
			Power_depositf: 0,
			Power_team: 0,
			Power_sale: 0,
			total_Power: 0,
			total_burn: 0,
			total_bonus: 0,
			total_withdrow: 0,
			total_teamo: 0,
			total_team: 0,
			total_teamPower: 0,
			total_teamd: 0,
			total_age: 0,
			downline_num: 0,
			downline_numf: 0,
			downline_p: 0,
			teamV: 0,
			store: 0,
			storeid: 0,
			storeTimes: 0,
			upline: referrer,
			downlineF: new uint256[](0),
			ageday: new uint256[](0),
			agecth: new uint256[](0)
		});
		users[msg.sender] = user;
		id2Address[lastUserId] = msg.sender;
		lastUserId++;
		users[referrer].total_teamo++;

		for(uint8 i = 1; i<lastUserId; i++) {
			if(referrer == address(0)) break;
			users[referrer].total_team++;
			referrer = users[referrer].upline;
		}	
	}

	function _updateTeam(address referrer, uint256 _amount) private {
		uint256 levelPower = 0;
		uint256 wincth = 0;
		uint256 pxcth = 0;
		for(uint8 i = 0; i<12; i++) {
			if(referrer == address(0)) break;
			if(users[referrer].id<2) break;
			_userPower(referrer);

			users[referrer].total_teamPower = users[referrer].total_teamPower.add(_amount);
			if (users[referrer].teamV>0 && users[referrer].level>4){
				wincth = _amount;
				if (users[referrer].teamV>4){
					wincth = wincth.mul(10);
					wincth = wincth.div(165);
				}else if (users[referrer].teamV>3){
					wincth = wincth.div(20);
				}else if (users[referrer].teamV>2){
					wincth = wincth.div(25);
				}else if (users[referrer].teamV>1){
					wincth = wincth.div(33);
				}else{
					wincth = wincth.div(50);
				}
				if (wincth>pxcth){
					wincth = wincth - pxcth;
					users[referrer].Power_team = users[referrer].Power_team.add(wincth);
					pxcth = pxcth.add(wincth);
					allPower = allPower.add(wincth);
				}
			}

			levelPower = 0;
			if (users[referrer].level>4){
				levelPower = lfive_Bonus[i];
			}else if (users[referrer].level>3){
				levelPower = lfour_Bonus[i];
			}else if (users[referrer].level>2){
				levelPower = lthree_Bonus[i];
			}else if (users[referrer].level>1){
				levelPower = ltwo_Bonus[i];
			}else if (users[referrer].level>0){
				levelPower = lone_Bonus[i];
			}
			if (levelPower>0){
			   levelPower = levelPower.mul(_amount);
			   levelPower = levelPower.div(100);
			   users[referrer].Power_deposit = users[referrer].Power_deposit.add(levelPower);
			   allPower = allPower.add(levelPower);

			   _uplevelF(referrer,levelPower);

			   if (users[referrer].teamV>1 && users[referrer].upline!=address(0) && users[referrer].teamV==users[users[referrer].upline].teamV){
				if (users[referrer].teamV>4){
					levelPower = levelPower.div(100);
				}else if (users[referrer].teamV>3){
					levelPower = levelPower.div(50);
				}else if (users[referrer].teamV>2){
					levelPower = levelPower.div(33);
				}else{
					levelPower = levelPower.div(25);
				}
				if (levelPower>0){
					_userPower(users[referrer].upline);
					users[users[referrer].upline].total_teamd = users[users[referrer].upline].total_teamd.add(levelPower);
					users[users[referrer].upline].total_Power = users[users[referrer].upline].total_Power.add(levelPower);
					allPower = allPower.add(levelPower);					
				}
			   }
			   
			}
			levelPower = users[referrer].Power_buy;
			levelPower = levelPower.add(users[referrer].Power_deposit);
			levelPower = levelPower.add(users[referrer].Power_depositf);
			levelPower = levelPower.add(users[referrer].Power_sale);
			levelPower = levelPower.add(users[referrer].Power_team);
			levelPower = levelPower.add(users[referrer].total_teamd);
			levelPower = levelPower + users[referrer].level*10000;
			users[referrer].total_Power = levelPower;
			referrer = users[referrer].upline;
		}
	}


	function _uplevelF(address _addr, uint256 ncth) private {		
		if (users[_addr].downline_numf>0){
			uint256 cthF = ncth.div(20);
			uint256 winCTH = cthF.div(users[_addr].downline_numf);			
			for(uint8 i = 0; i < users[_addr].downline_numf; i++) {
				_uplevelFive(id2Address[users[_addr].downlineF[i]],winCTH);
			}
		}
	}
	function _uplevelFive(address _addr, uint256 _amount) private {
		if (_addr != address(0)){
			_userPower(_addr);
			users[_addr].Power_depositf = users[_addr].Power_depositf.add(_amount);
			users[_addr].total_Power = users[_addr].total_Power.add(_amount);
			allPower = allPower.add(_amount);
		}
	}

	function isUserExists(address _addr) public view returns (bool) {
		return (users[_addr].id != 0);
	}

	function isStore(address _addr) public view returns (uint256 defi) {
		uint256 nback = 0;
		if (users[_addr].id >0){
			nback = 1;
			if (users[_addr].store>0){
				nback = users[_addr].store;
			}
		}
		return nback;
	}

	function PriceInfo() view external returns(uint256 pcth,uint256 pusdt) {
		return (cthusdt,usdtcth);
	}


	function orderInfo(uint256 oid) view external returns (uint256 status, uint256 usdt,  uint256 cth, address buyer, address store) {
		return (orders[oid].status, orders[oid].ousdt, orders[oid].octh, orders[oid].obuy, orders[oid].ostore);
	}

	function cthdeficount() view external returns(uint256 UserId, uint256 StoreId) {
		return (lastUserId, lastStoreId);
	}
    
	function userPower(address _addr) view external returns (uint256 ucth,uint256 ucthage) {
		uint256 ubonusday = _userPowerDay(_addr);
		uint256 uageday = 0; 
		if (ubonusday>0){
			uageday = ubonusday.div(10);
			ubonusday = ubonusday - uageday;
		}
		ubonusday = ubonusday.add(users[_addr].total_bonus);
		uageday = uageday.add(users[_addr].total_age);
		return (ubonusday,uageday);
	}

	function userInfo(address _addr) view external returns(uint256 id, uint256 store, uint256 storeTimes, uint256 level, address upline) {
		return (users[_addr].id, users[_addr].store, users[_addr].storeTimes, users[_addr].level, users[_addr].upline);
	}


	function userBase(address _addr) view external returns(uint256 userpower, uint256 userburn, uint256 userbonus, uint256 userwithdrow) {
		return (users[_addr].total_Power, users[_addr].total_burn, users[_addr].total_bonus, users[_addr].total_withdrow);
	}

	function sysBase() view external returns(uint256 totalpower, uint256 totalburn, uint256 totalage, uint256 totalbonus) {
		return (allPower, allburn, ageall, allbonus);
	}

	function userTeam(address _addr) view external returns(uint256 team, uint256 teamAll, uint256 teamPower, uint256 teamV) {
		return (users[_addr].total_teamo, users[_addr].total_team, users[_addr].total_teamPower, users[_addr].teamV);
	}

	function userPowerm(address _addr) view external returns(uint256 buy, uint256 deposit, uint256 depositf, uint256 team, uint256 teamd, uint256 sale) {
		return (users[_addr].Power_buy, users[_addr].Power_deposit, users[_addr].Power_depositf, users[_addr].Power_team, users[_addr].total_teamd, users[_addr].Power_sale);
	}

	function getAgeLive(address adduser) view external returns(uint256) {
		uint256 uage = 0;
		if (isUserExists(adduser)){
			for(uint256 i = 0; i < users[adduser].ageday.length; i++) {
				if (users[adduser].ageday[i]<block.timestamp){
					if (users[adduser].agecth[i]>0){
						uage = uage+users[adduser].agecth[i];
					}else{
						i = users[adduser].ageday.length;
					}
				}				
			}
		}
		return uage;
	}

	function getAgeAll(address adduser) view external returns(uint256) {
		uint256 uage = 0;
		if (isUserExists(adduser)){
			for(uint256 i = 0; i < users[adduser].ageday.length; i++) {
				if (users[adduser].agecth[i]>0){
					uage = uage+users[adduser].agecth[i];
				}			
			}
		}
		return uage;
	}


	function getShopRight(address addshop) public view returns (uint256) {
		return shopright[addshop];
	}
}