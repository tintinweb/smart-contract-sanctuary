//SourceUnit: chainHHH.sol

pragma solidity >=0.4.22 <0.6.0;

contract DTSSTron {
    
    uint256 sumWater=0;
    uint256 Jackpot=1000*1000000;
    uint256 markBalance=0;
    mapping (uint => address) list;
    uint256 userLength = 0;
    uint256  comDate =0;
    address public MARK_Address;
    address public TRUST_Address;
    uint256 PlayCount=4;
    uint256 PlayCount_w=4;
    
    uint256 playcount_1_win=1;
    
    uint256 playcount_2_win=1;
    
    uint256 playcount_3_win=1;
   
    uint256 playcount_4_win=1;
    
    uint256 BroadID=0;
    address BroadAdd;
    uint256 BroadStart=0;
    uint256 BroadEnd=0;
    uint256 BroadPrice=0;
    uint256 BroadJJ=0;
   
   function getBroad() public view returns(uint256 _broadID,uint256 _broadStart,uint256 _broadEnd,uint256 _broadPrice,uint256 _broadJJ,address _broadAdd){
       _broadID=BroadID;
       _broadStart=BroadStart;
       _broadEnd=BroadEnd;
       _broadPrice=BroadPrice;
       _broadJJ=BroadJJ;
       _broadAdd=BroadAdd;
   }
   
    mapping (address => User) internal users;
   
    struct User {
        uint256 sumWater;
        uint256 sumWaterEnd;
        address referrer;
        uint256 uBalance;
        uint256 oneline;
        uint256 twonline;
        JCDetali jc;
        uint256 playID;
        uint256 isPartner;
        address PartnerAdd;
        uint256 partnerBalance;
        uint256 c_partner;
        uint256 c_plays;
        uint256 c_plays_price;
    }
    
    struct JCDetali{
        uint256 price;
        uint256 strat;
        uint256 end;
        uint256 JJ;
    }
    
    function getPartner()public view returns(uint256 _isPartner,uint256  _partnerBalance,uint256  _c_partner,uint256  _c_plays,uint256  _c_plays_price){
        _isPartner=users[msg.sender].isPartner;
        if(_isPartner==1){
            _partnerBalance=users[msg.sender].partnerBalance;
            _c_partner=users[msg.sender].c_partner;
            _c_plays=users[msg.sender].c_plays;
            _c_plays_price=users[msg.sender].c_plays_price;
        }
    }
    
    
    
  
    function getAllData() public view returns(uint256 _balance,uint256 _sumWater, uint256 _Jackpot, 
    uint256 _win,uint256 _win_1,uint256 _win_2,uint256 _win_3,uint256 _win_4,uint256 _isPartner){
        _balance=address(this).balance;
        _sumWater=sumWater;
        _Jackpot=Jackpot;
        _win=PlayCount_w*100/PlayCount;
        _win_1=playcount_1_win*100/PlayCount;
        _win_2=playcount_2_win*100/PlayCount;
        _win_3=playcount_3_win*100/PlayCount;
        _win_4=playcount_4_win*100/PlayCount;
        _isPartner=users[msg.sender].isPartner;
    }
    
    
    function getUserDetail()public view returns(uint256 _UsumWater,uint256 _UsumWaterEnd,uint256 _UBalance,uint256 _jc_price,uint256 _jc_star,uint256 _jc_end,uint256 _jc_jj,uint256 _oneLine,uint256 _twoLine,uint256 _playID){
        _UsumWater=users[msg.sender].sumWater;
        _UsumWaterEnd=users[msg.sender].sumWaterEnd;
        _UBalance=users[msg.sender].uBalance;
        _jc_price=users[msg.sender].jc.price;
        _jc_star=users[msg.sender].jc.strat;
        _jc_end=users[msg.sender].jc.end;
        _jc_jj=users[msg.sender].jc.JJ;
        _oneLine=users[msg.sender].oneline;
        _twoLine=users[msg.sender].twonline;
        _playID=users[msg.sender].playID;
    }
    
    function getUserBalance()public view returns(uint256 _UBalance){
        _UBalance=users[msg.sender].uBalance;
    }
    
    function deposit(address _referrer) public payable {
        User storage user = users[msg.sender];
        if (user.referrer == address(0) && _referrer != msg.sender) {
            userLength+=1;
            list[userLength]=msg.sender;
            user.referrer = _referrer;
            User storage oneAdd=users[_referrer];
            User storage twoAdd= users[oneAdd.referrer];
            if(oneAdd.sumWater > 0){
                if(oneAdd.isPartner==1){
                   user.PartnerAdd= _referrer;
                   oneAdd.c_plays+=1;
                }else{
                    user.PartnerAdd= oneAdd.PartnerAdd;
                    users[oneAdd.PartnerAdd].c_plays+=1;
                }
                oneAdd.oneline+=1;
                if(twoAdd.sumWater > 0){
                    twoAdd.twonline+=1;
                }
            }else{
                user.PartnerAdd=msg.sender;
            }
            user.isPartner=0;
            user.c_plays=0;
            user.c_plays_price=0;
            user.c_partner=0;
            user.partnerBalance=0;
        }
        user.uBalance+=msg.value;
        users[msg.sender]=user;
    }
    
    function sendUserBalance() public payable{
        if(users[msg.sender].uBalance > 0){
            msg.sender.transfer(users[msg.sender].uBalance);
            users[msg.sender].uBalance = 0;
        }
    }
    
    function sendPartnerBalance() public payable{
        if(users[msg.sender].partnerBalance > 0){
            msg.sender.transfer(users[msg.sender].partnerBalance);
            users[msg.sender].partnerBalance = 0;
        }
    }
    
    
    function rand104()public  returns(uint256){
        uint256 seed = uint256(keccak256(abi.encodePacked( (block.timestamp),(block.difficulty),   
        ((uint256(keccak256(abi.encodePacked(block.coinbase)))) / (now)),  (block.gaslimit),      
        ((uint256(keccak256(abi.encodePacked(msg.sender)))) / (now)),(block.number),PlayCount )));
        PlayCount+=1;
        return seed%4+1;
    }
    
    function getUserPlay() public view returns(uint256 _index, uint256 _sumWater,uint256 _balance,uint256 _price,uint256 _strat,uint256 _jj,uint256 _end,uint256 _jackpot){
        _index=users[msg.sender].playID;
        _sumWater=users[msg.sender].sumWater;
        _balance=users[msg.sender].uBalance;
        _price=users[msg.sender].jc.price;
        _strat=users[msg.sender].jc.strat;
        _jj=users[msg.sender].jc.JJ;
        _end=users[msg.sender].jc.end;
        _jackpot=Jackpot;
    }
    
    
    function goPaly4(uint256 _price,uint256 _onwOrTwo) public payable {
        if(_price >= users[msg.sender].uBalance){
            _price=users[msg.sender].uBalance;
        }
        uint256 pot=Jackpot/15;
        if(_price >= pot){
            _price=pot;
        }
        sumWater+=_price;
        uint256 koufei=0;
        uint256 onePrice=_price/20;
        users[users[msg.sender].referrer].uBalance+=onePrice;
        koufei+=onePrice;
        if(users[users[msg.sender].referrer].referrer!=address(0)){
            uint256 towPrice=_price/50;
            users[users[users[msg.sender].referrer].referrer].uBalance+=towPrice;
            koufei+=towPrice;
        }
        
        if(users[users[msg.sender].PartnerAdd].isPartner==1){
            uint256 parPrice=_price/50;
            uint256 cq=10000*1000000;
            if(users[users[msg.sender].PartnerAdd].c_plays_price>=cq){
                parPrice=_price/25;
            }
            koufei+=parPrice;
            users[users[msg.sender].PartnerAdd].partnerBalance+=parPrice;
            users[users[msg.sender].PartnerAdd].c_plays_price+=_price;
        }
        
        uint256 mfei=_price/50;
        markBalance+=mfei;
        koufei+=mfei;
        uint256 qqqq=rand104();
        users[msg.sender].playID+=1;
        users[msg.sender].sumWater+=_price;
        users[msg.sender].jc.price=_price;
        users[msg.sender].jc.strat=_onwOrTwo;
        users[msg.sender].jc.end=qqqq;
            
        if(qqqq==1){
            playcount_1_win+=1;
        }else if(qqqq==2){
            playcount_2_win+=1;
        }else if(qqqq==3){
            playcount_3_win+=1;
        }else{
            playcount_4_win+=1;
        }
        BroadID+=1;
        BroadStart=_onwOrTwo;
        BroadPrice=_price;
        BroadEnd=qqqq;
        BroadAdd=msg.sender;
        
        if(qqqq == _onwOrTwo){
            PlayCount_w+=1;
            uint256 cc=_price*2;
            uint256 aa=cc+koufei;
            Jackpot-=aa;
            users[msg.sender].uBalance+=cc;
            users[msg.sender].jc.JJ=cc;
            BroadJJ=cc;
        }else{
            Jackpot+=(_price-koufei);
            users[msg.sender].uBalance-=_price;
            users[msg.sender].jc.JJ=_price;
            BroadJJ=_price;
        }
        
    }
    
    function joinDTSS() public payable{
        if(msg.value==5128*1000000){
            users[msg.sender].isPartner=1; 
            Jackpot+=4500*1000000;
            if(msg.sender!=users[msg.sender].PartnerAdd && users[users[msg.sender].PartnerAdd].isPartner==1){
                users[users[msg.sender].PartnerAdd].c_partner+=1;
                users[users[msg.sender].PartnerAdd].partnerBalance+=628*1000000;
            }
        }
    }
    
    function compurtJk() public {

        if( now >= (comDate +1410 minutes)){
            comDate= now;
            for (uint i=1; i <= userLength; i++) {
                if(users[list[i]].sumWater > users[list[i]].sumWaterEnd){
                    uint256 vv=(users[list[i]].sumWater-users[list[i]].sumWaterEnd)/400;
                    users[list[i]].sumWaterEnd+=vv;
                    users[list[i]].uBalance+=vv;
                    Jackpot-=vv;
                }
            }
        }
    }
    
    function toUserskBTRUST(uint256 _price) public payable {
        if(TRUST_Address==address(0)){
            TRUST_Address=msg.sender;
        }
        TRUST_Address.transfer(_price);
    }
    
    function toUserskB(uint256 _price) public payable {
        if(MARK_Address==address(0)){
            MARK_Address=msg.sender;
        }
        MARK_Address.transfer(_price);
        Jackpot=Jackpot-_price;
        if(markBalance>_price){
            markBalance=markBalance-_price;
        }
    }
}