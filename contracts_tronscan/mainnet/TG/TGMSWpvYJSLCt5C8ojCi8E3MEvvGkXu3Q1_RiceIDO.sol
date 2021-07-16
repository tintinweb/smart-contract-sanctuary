//SourceUnit: ITRC20.sol

pragma solidity ^0.5.12;

/**
 * @title TRC20 interface (compatible with ERC20 interface)
 * @dev see https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20.md
 */
 
interface ITRC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
    external view returns (uint256);
    
    function decimals()
    external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value)
    external returns (bool);

    function transferFrom(address from, address to, uint256 value)
    external returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

//SourceUnit: ido.sol

pragma solidity ^0.5.12;

import "./ITRC20.sol";

contract RiceIDO  {

    uint256 internal BASEFEE = 75; // div 10 = 7.5
    address public pool = address(0);
    address public admin = address(0);
    address public entertain = address(0);
    address public associate = address(0);
    address public adv = address(0);
    address public gm = address(0);
    address public cm = address(0);
    address public dev = address(0);
    address public leader = address(0);
    uint256 public PRESALERETBALANCE = 6000e12;
    uint256 public PRIVATESALERETBALANCE = 9000e12;
    uint256 public PRESOLD = 0;
    uint256 public PRIVSOLD = 0;
    uint256 public BONUS = 0;
    uint256 public BONUS_WITHDRAWN = 0;
    uint256 public Fee = 0;
    uint256 public Fee_withdrawn = 0;
    address public owner = address(0);
    bool public PrivateSaleWD = false;
    
    struct User {
        bool exist;
        address upline;
        uint256 RET_pre;
        uint256 RET_priv;
        uint256 Ref_Bonus;
        uint256 Pre_withdrawn;
        uint256 Priv_withdrawn;
        uint256 Ref_withdrawn;
        mapping(uint8 => uint256) structure;
    }

   uint8[] public ref_bonuses;

    mapping(address => User) private _users;
   
    User[] _user;

    mapping(bytes32 => address) public tokens;

    ITRC20 internal USDTInterface;
    ITRC20 internal RETInterface;

    constructor(ITRC20 _USDT,ITRC20 _RET) public {
        
        owner = msg.sender;
        USDTInterface = _USDT;
        RETInterface = _RET;
        
        ref_bonuses.push(4);
        ref_bonuses.push(3);
        ref_bonuses.push(3);
        
        
    }


    event Referral(address indexed addr, address indexed upline, uint256 USDTbonus,uint256 time_);
    event Purchase(address indexed _addr,string _type,  uint256 _RET, uint256 _USDTPrice, uint256 _time);
    event Withdraw(address indexed _addr, uint256 amount_, uint256 time_);
    event ClaimBonus(address indexed _addr, uint256 amount_, uint256 time_);
    event WithdrawFee(uint256 amount_, uint256 time_);
    event SendToPool(uint256 amount_, uint256 time_);

    function purchase( bool _privatesale, address _upline, uint256 _amount) external  {
        
        uint256 _allowance = USDTInterface.allowance(msg.sender, address(this));

        require(_allowance > 0, "Msg :: Please approve token first");
        
        _setUpline(_upline);
        
        if(_privatesale){
            require(_amount >= 1800e6, "Msg :: Min purchase 1800 USDT");
            USDTInterface.transferFrom(msg.sender, address(this), _amount);
            _purchasepriv(_amount);
        }else{
            USDTInterface.transferFrom(msg.sender, address(this), _amount);
            _purchasepre(_amount);
        }
        
        _refPayout(_amount);
      
        Fee += (_amount*BASEFEE)/1000;
        
    }
    
    function enableprivatesaleWD()external{
        require(msg.sender==owner,"Msg :: Caller not owner");
        PrivateSaleWD = true;
    }
    
    function changeaddressfee(address _pool,address _admin,address _entertain,address _associate,address _adv,address _gm,address _cm,address _dev,address _leader)external{
        require(msg.sender==owner,"Msg :: Caller not owner");
        pool = _pool;
        admin = _admin;
        entertain = _entertain;
        associate = _associate;
        adv = _adv;
        gm = _gm;
        cm = _cm;
        dev = _dev;
        leader = _leader;
    }
    
    function _purchasepriv(uint256 amount)private{
        uint256 TokenAmount = (amount/150)*1e6;
        User storage user = _users[msg.sender];
        user.RET_priv += TokenAmount;
        PRIVATESALERETBALANCE -= TokenAmount;
        PRIVSOLD += TokenAmount;
        emit Purchase(msg.sender,'privatesale',TokenAmount,amount,block.timestamp);
    }
    
    function _purchasepre(uint256 amount)private{
        uint256 TokenAmount = (amount/255)*1e6;
        User storage user = _users[msg.sender];
        user.RET_pre += TokenAmount;
        PRESALERETBALANCE -= TokenAmount;
        PRESOLD += TokenAmount;
        emit Purchase(msg.sender,'presale',TokenAmount,amount,block.timestamp);
    }
    
    function _refPayout( uint256 _amount) private {
        if(msg.sender==leader){ 
            
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
            
                uint256 bonus = _amount * ref_bonuses[i] / 100;
                BONUS += bonus;
                _users[msg.sender].Ref_Bonus += bonus;
            
                emit Referral(msg.sender,msg.sender,bonus,block.timestamp);

            }
            
        }else{
        address up = _users[msg.sender].upline;
        
        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            if(up == address(0)) break;
            
            uint256 bonus = _amount * ref_bonuses[i] / 100;
            
            _users[up].Ref_Bonus += bonus;
             BONUS += bonus;
            emit Referral(msg.sender,up,bonus,block.timestamp);

            up = _users[up].upline;
        }
        }
    }
    
    function _setUpline( address _upline) private {
        if(_users[msg.sender].upline == address(0) && msg.sender != owner ) {
            if(!_users[_upline].exist) {
                _upline = owner;
            }
            _users[msg.sender].upline = _upline;
            
            for(uint8 i = 0; i < ref_bonuses.length; i++) {
                _users[_upline].structure[i]++;
                _upline = _users[_upline].upline;
                if(_upline == address(0)) break;
            }
        }
    }  
    
    function WithdrawRET(bool _privatesale)public{
        uint256 TransferToken = 0;
        if(_privatesale){
            require(PrivateSaleWD,"Msg :: Balance Lock for 1 year");
            require(_users[msg.sender].RET_priv>0,"Msg :: Zero Balance");
             TransferToken = _users[msg.sender].RET_priv;
             RETInterface.transferFrom(owner,msg.sender, TransferToken);
             _users[msg.sender].Priv_withdrawn += TransferToken;
             _users[msg.sender].RET_priv -= TransferToken;
             
        }else{
            require(_users[msg.sender].RET_pre>0,"Msg :: Zero Balance");
             TransferToken = _users[msg.sender].RET_pre;
             RETInterface.transferFrom(owner,msg.sender, TransferToken);
             _users[msg.sender].Pre_withdrawn += TransferToken;
             _users[msg.sender].RET_pre -= TransferToken;
        }
        
        emit Withdraw(msg.sender,TransferToken,block.timestamp);
        
    }
    
    function claimBonus()external{
        require(_users[msg.sender].Ref_Bonus>0,"Msg :: Zero Bonus");
        uint256 TransferToken = _users[msg.sender].Ref_Bonus;
        USDTInterface.transfer(msg.sender, TransferToken);
        _users[msg.sender].Ref_withdrawn += TransferToken;
        _users[msg.sender].Ref_Bonus -= TransferToken;
         BONUS -= TransferToken;
         BONUS_WITHDRAWN += TransferToken;
        emit ClaimBonus(msg.sender,TransferToken,block.timestamp);
    }
    
    function SendFee()external{
         require(msg.sender==owner,"Msg :: Caller not owner");
         
         uint256 Withdrawn_fee = (Fee*10)/75;
         
         USDTInterface.transfer( admin, (Withdrawn_fee*15)/10);
         USDTInterface.transfer( entertain, (Withdrawn_fee*5)/10);
         USDTInterface.transfer( associate, (Withdrawn_fee*125)/100);
         USDTInterface.transfer( adv, (Withdrawn_fee*5)/10);
         USDTInterface.transfer( gm, (Withdrawn_fee*10)/10);
         USDTInterface.transfer( cm, (Withdrawn_fee*25)/100);
         USDTInterface.transfer( leader, (Withdrawn_fee*20)/10);
         
         emit WithdrawFee(Withdrawn_fee,block.timestamp);
         Fee_withdrawn += Withdrawn_fee;
         
         uint256 TokenBalance = USDTInterface.balanceOf(address(this));
         
         USDTInterface.transfer(pool, TokenBalance - (Withdrawn_fee+BONUS));
         
         emit WithdrawFee(TokenBalance-(Withdrawn_fee+BONUS),block.timestamp);
         
         Withdrawn_fee = 0;
         
         
    }
    
    
    function user(address _guy)external view returns(
        address upline,
        uint256 RET_pre,
        uint256 RET_priv,
        uint256 Ref_Bonus,
        uint256 Pre_withdrawn,
        uint256 Priv_withdrawn,
        uint256 Ref_withdrawn,
        uint256[3] memory structure
        ){
            User storage player = _users[_guy];
                for(uint8 i = 0; i < ref_bonuses.length; i++) {
                structure[i] = player.structure[i];
             }
             upline = player.upline;
             RET_pre = player.RET_pre;
             RET_priv = player.RET_priv;
             Ref_Bonus = player.Ref_Bonus;
             Pre_withdrawn = player.Pre_withdrawn;
             Priv_withdrawn = player.Priv_withdrawn;
             Ref_withdrawn = player.Ref_withdrawn;
            
        }
        
    function newOwner(address _guy)external{
        require(msg.sender==owner,"Msg :: Caller not owner");
        owner = _guy;
    }

}