//SourceUnit: IERC20.sol

pragma solidity ^0.6.0;

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SourceUnit: MyDollar.sol

pragma solidity ^0.6.0;
pragma experimental ABIEncoderV2;

import "../IERC20.sol";

contract MyDollar {
    

    IERC20 public usdt ;
    
    address  public wallet1 ;
    address  public wallet2 ;
    
    uint256 public subscriptionFee = 165 * ( 10 ** 6); // 165 fix
    uint256 public decimals = 6;
    
    struct User {
        address addr;
        uint256 cycle;
        address upline;
        uint256 referrals;
        uint256 payouts;
        uint256 direct_bonus;
        uint256 match_bonus;
        uint256 deposit_amount;
        uint256 deposit_payouts;
        uint40  deposit_time;
        uint256 total_deposits;
        uint256 total_structure;
    }

    mapping(address => User) public users;
    address[] public addressIndices;

    uint256[] public cycles;
    uint256[] public ref_bonuses;                    


    uint256 public total_users = 0;
    uint256 public total_deposited;

    event Upline(address indexed addr, address indexed upline);
    event NewSubscription(address indexed addr, uint256 amount);
    event DirectPayout(address indexed addr, address indexed from, uint256 amount);
    event MatchPayout(address indexed addr, address indexed from, uint256 amount);
    event PoolPayout(address indexed addr, uint256 amount);
    event LimitReached(address indexed addr, uint256 amount);

    constructor(address _wallet1,address _wallet2,IERC20 token, uint256 _decimals, uint256 _subscriptionFee) public {
        
        decimals = _decimals;

        wallet1 = _wallet1;
        wallet2 = _wallet2;

        usdt = token;
        
        subscriptionFee = _subscriptionFee * (10 ** decimals);
        
        ref_bonuses.push(50 * (10 ** decimals)); // 1.
        
        for(int i =0; i < 11; i++){
            ref_bonuses.push(10 * (10 ** decimals)); // 2.
        }
        
        // 165 USDT one time
        cycles.push(subscriptionFee);
        
    }
    
    function join(address _upline)  external  {
        
        address sender = msg.sender;
        address reciever = address(this);
        
        require(sender != wallet1 || sender != wallet2, "admin can't join");
        
        require( 
            (users[_upline].deposit_time > 0) ||
            (_upline == address(0)) , "upline not exist");
            
        uint256 balance = usdt.balanceOf(sender);
        
        require( balance >= subscriptionFee , "balance is low");

        bool success = usdt.transferFrom(sender, reciever,  subscriptionFee);
        require(success, "buy failed");
        
        _setUpline(sender, _upline);
        uint256 paid = _join(sender, subscriptionFee);

        uint256 spends = subscriptionFee - (_refPayout(_upline) + paid );
        
        transferToken(usdt, wallet1, spends / 2);
        transferToken(usdt, wallet2, spends / 2);
        

    }
    
    function _setUpline(address _addr, address _upline) private {
        
        if(users[_addr].upline == address(0) && _upline != _addr && 
            ( _addr != wallet1 ||  _addr != wallet2 )
        ) {
            
            users[_addr].upline = _upline;
            users[_upline].referrals++;

            emit Upline(_addr, _upline);

            total_users++;

            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                if(_upline == address(0)) break;

                users[_upline].total_structure++;

                _upline = users[_upline].upline;
            }
        }
        
    }

    function _join(address _addr, uint256 _amount) private returns(uint256 paid) {

        if(users[_addr].deposit_time > 0) {
            users[_addr].cycle++;
        } else {
            // start adding address in array
            addressIndices.push(_addr);
        }
        
        
        users[_addr].addr = _addr;
        users[_addr].deposit_amount = _amount;
        users[_addr].deposit_payouts = 0;
        users[_addr].deposit_time = uint40(block.timestamp);
        users[_addr].total_deposits += _amount;

        total_deposited += _amount;
        
        emit NewSubscription(_addr, _amount);

        // transfer direct ref_bonuses
        if(users[_addr].upline != address(0)) {
            uint256 bonus = ref_bonuses[0];
            
            address level1 = users[_addr].upline;
            users[level1].direct_bonus += bonus;
            users[level1].payouts += bonus;
            transferToken(usdt, level1, bonus);
            paid = bonus;

            emit DirectPayout(users[_addr].upline, _addr, bonus);
        }
        
    }
    
    function transferToken(IERC20 token, address to, uint256 amount) private  {
        
        if(to != address(0)){
            token.approve(to, amount);
            token.transfer(to, amount);
        }
    }
    
    function _refPayout(address _addr) private returns(uint256 total) {
        address up = users[_addr].upline;

        for(uint8 i = 1; i < ref_bonuses.length -1 ; i++) {
            if(up == address(0)) break;
            
            //if(users[up].referrals >= i + 1) {
                uint256 bonus = ref_bonuses[i];
                
                users[up].match_bonus += bonus;
                
                if(up != address(this) || up != wallet1 || up != wallet2)
                {
                    users[up].payouts += bonus;
                    transferToken(usdt, up, bonus);
                    total += bonus;
                }

                emit MatchPayout(up, _addr, bonus);
            //}

            up = users[up].upline;
        }
    }

    /*
        Only external call
    */
    function userInfo(address _addr) view external returns(address addr,address upline, uint40 deposit_time, uint256 deposit_amount, uint256 payouts, uint256 direct_bonus, uint256 match_bonus) {
        return (_addr, users[_addr].upline, users[_addr].deposit_time, users[_addr].deposit_amount, users[_addr].payouts, users[_addr].direct_bonus,  users[_addr].match_bonus);
    }
    
    function getAddressIndices() view external returns(address [] memory)
    {
        return addressIndices;
    }
    
    function getAll() public view returns (address[2][] memory){
        address[2][] memory ret = new address[2][](total_users);
        for (uint i = 0; i < total_users; i++) {
            ret[i][0] = users[addressIndices[i]].addr;
            ret[i][1] = users[addressIndices[i]].upline;
            }
        return ret;
    }

    function stages() view external returns(uint256[] memory) {
      uint256[]    memory st = new uint[](ref_bonuses.length);
      for (uint i = 0; i < ref_bonuses.length; i++) {
          uint256  s = ref_bonuses[i];
          st[i] = s;
      }
        return st;
    }

    function userInfoTotals(address _addr) view external returns(uint256 referrals, uint256 deposits, uint256 total_payouts, uint256 total_structure) {
        return (users[_addr].referrals, users[_addr].total_deposits, users[_addr].payouts, users[_addr].total_structure);
    }

    function contractInfo() view external returns(uint256 _total_users, uint256 _total_deposited) {
        return (total_users, total_deposited);
    }

  
}