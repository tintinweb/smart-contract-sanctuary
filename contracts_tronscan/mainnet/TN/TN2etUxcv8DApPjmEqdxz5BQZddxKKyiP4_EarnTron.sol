//SourceUnit: earntrx.sol

//////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////

//////////////  www.EARNTRX.net ////////////////////////

//////////////////////////////////////////////////////////
/////////////////////////////////////////////////////////

pragma solidity ^0.5.0;



contract EarnTron{

	

	address payable public owner;

	struct LevelBonus {

		uint level1;

		uint level2;

		uint level3;

		uint level4;

		uint level5;



    }

	struct LevelMember {

		uint memlev1;

		uint memlev2;

		uint memlev3;

		uint memlev4;

		uint memlev5;

    }

	struct Plan {

		uint256 planId;

		uint256 amount;

    }

	struct User {

		bool exists;

		address payable upline;

		uint256 total;

		uint256 totalReference;

		uint256 referenceInvestment;

		bool activeStatus;

	}

	struct Income {

		uint256 totalReceive;

	}



	uint256 public count = 1;

	uint256 public adminFee = 1;

	uint8  public tRate = 33;

	uint private dlevelper = 5;

	

	
	uint256 public BUSINESS_DAY = 0;

	uint256 private totalSysInvestment = 0;

	uint256 private totalSysRoi = 0;

	uint256 private totalSysLBonus = 0;

	

	mapping(address => User) public users;

	mapping(address => Income) public incomes;

	mapping(address =>  address[]) public ancestors;

	mapping(address => LevelBonus) public levelBonus;

	mapping(address => LevelMember) public levelMember;

	mapping(uint256 => address) public listUsers;



	
	Plan[] private investmentPlans_;



	constructor(address payable _owner) public {

		owner = _owner;



		User memory user = User({

			exists: true,

			upline: address(0),

			total: 0,

			totalReference: 0,

			referenceInvestment : 0,

			activeStatus : false

		});

		users[_owner] = user;

		listUsers[count] = owner;

		_init();

	}

	

	function _init() private {

        investmentPlans_.push(Plan(1,600));//id,amount,per,term,level


    }

	

	

	function withdraw() public {

	if (msg.sender == owner){

	uint256 contractBalance = address(this).balance;

	owner.transfer(contractBalance);

	} }

		

		

	function register(address payable _upline) public payable {

		address payable upline = _upline;

		require(users[_upline].exists, "No Upline");

		require(!users[msg.sender].exists,"Address exists");

		require(msg.value == 600 trx,"Earn TRX by Just Paying 600 TRX");

		User memory user = User({

				exists: true,

				upline: upline,

				total: 0,

				totalReference: 0,

				referenceInvestment : 0,

				activeStatus : false

		});

		count++;

		users[msg.sender] = user;

		listUsers[count] = msg.sender;

		

		_hanldeSystem(msg.sender, _upline);

		_setReferalIncome(msg.sender,msg.value);

		for(uint8 i=0; i < 10; i++){

			if(_upline == address(0))return;

			_setLevelMember(i+1 , _upline);

			_upline = users[_upline].upline;

		}

		emit Register(upline,msg.sender, msg.value);

	}



	function _setReferalIncome(address _add,uint256 value) private {		

		address payable upline = users[_add].upline;

		users[upline].referenceInvestment +=  value;

		

		for(uint8 i=0; i < 5; i++){

			if(upline == address(0))return;

			





			uint256 targetLevel = 5;// investmentPlans_[_planId].targetLevel;

			if(i+1 <= targetLevel ){

				uint bp = 20;

				uint256 bonus = 100*1e6 ;

				incomes[upline].totalReceive += bonus;

				_setLevelBonus(i+1 ,bonus ,upline);

				totalSysLBonus += bonus;

				upline.transfer(bonus);

				

			}

			upline = users[upline].upline;

		}

	}

	



	function _hanldeSystem(address  _add, address _upline) private {       

		ancestors[_add] = ancestors[_upline];

        ancestors[_add].push(_upline);

        users[_upline].totalReference += 1;

    }

	

	function _setLevelBonus(uint8 lev, uint256 bonus,address upline) private{

		if(lev == 1)levelBonus[upline].level1 += bonus;

		if(lev == 2)levelBonus[upline].level2 += bonus;

		if(lev == 3)levelBonus[upline].level3 += bonus;

		if(lev == 4)levelBonus[upline].level4 += bonus;

		if(lev == 5)levelBonus[upline].level5 += bonus;

	}

   	function _setLevelMember(uint8 lev, address upline) private{

		if(lev == 1)levelMember[upline].memlev1 += 1;

		if(lev == 2)levelMember[upline].memlev2 += 1;

		if(lev == 3)levelMember[upline].memlev3 += 1;

		if(lev == 4)levelMember[upline].memlev4 += 1;

		if(lev == 5)levelMember[upline].memlev5 += 1;

	}

	

    event Register(

    	address upline,

    	address newMember,

    	uint256 value

    );



    event Withdraw(

    	address add,

    	uint256 value

    );

}