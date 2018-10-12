pragma solidity ^0.4.25;

contract RISK{

    //global variables
    uint16[19][3232] private adjacencies;
    address private admin = msg.sender;
    uint256 private seed = block.timestamp;
    uint256 public roundID;
    mapping(uint256=>RoundData) public Rounds;
    bool public isactive;
    mapping(address=>uint256) private playerlastroundwithdrawn;
    
    
    //settings that are read at the beggining of a round, and admin can change them, taking effect at new round 
    uint16 public beginterritories = 5; //number of territories to claim at createnation
    uint16 public maxroll= 6;
    uint256 public trucetime=72 hours;
    uint256 public price=30 finney;
    uint256 public maxextensiontruce=50; //max number of territories owned during truce
    
    
    //store names
    mapping(bytes32=>address) public ownerXname; //get owner by name, anyone can own an arbitrary number of names
    mapping(address=>bytes32) public nameXaddress;//get the current name in use by the address
    mapping(bytes32=>uint256) public priceXname; //get the price of a name



    /*_____       _     _ _      ______                _   _                 
     |  __ \     | |   | (_)    |  ____|              | | (_)                
     | |__) |   _| |__ | |_  ___| |__ _   _ _ __   ___| |_ _  ___  _ __  ___ 
     |  ___/ | | | &#39;_ \| | |/ __|  __| | | | &#39;_ \ / __| __| |/ _ \| &#39;_ \/ __|
     | |   | |_| | |_) | | | (__| |  | |_| | | | | (__| |_| | (_) | | | \__ \
     |_|    \__,_|_.__/|_|_|\___|_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/*/


    function createnation(uint16[] territories,string _name,
    uint256 RGB)
    public
    payable
    {
        RequireHuman();
        require(isactive);
        uint256 _rID = roundID;
        uint16 _teamcnt =Rounds[_rID].teamcnt;
        
        
        require(_teamcnt<255); //max 255 teams, with 0 being unclaimed territories
        
        
        RGB=colorfilter(RGB);//format and check it&#39;s not one of the UI colors
        require(!Rounds[_rID].iscolorregistered[RGB]); //color must be unique
        
        
        bytes32 name=nameFilter(_name);
        require(ownerXname[name]==msg.sender); //player must own this name
        require(Rounds[_rID].isnameregistered[name]==false); //name must be unique to round


        uint16 _beginterritories =  Rounds[roundID].beginterritories;
        require(msg.value==Rounds[_rID].price);
        require(territories.length==_beginterritories);//send only the exact ammount pls
        require(Rounds[_rID].teamXaddr[msg.sender]==0); //one player can only play with one team
        
        uint i;
        for (i =0 ; i<territories.length;i++){
            require(territories[i]<uint16(2750)); //don&#39;t claim sea provinces
            require(getownership(territories[i])==uint16(0)); //don&#39;t claim other players&#39; lands
        }

        _teamcnt+=1; //increase the team counter

        setownership(territories[0],_teamcnt);
        for (i =1 ; i<territories.length;i++){ 
            require(hasteamadjacency(territories[i],_teamcnt)); //all territories should share borders
            setownership(territories[i],_teamcnt);
        }
        

        //starting a nation gives as many shares to the pot as the number of territories claimed
        Rounds[_rID].validrollsXaddr[msg.sender]+=_beginterritories;
        Rounds[_rID].validrollsXteam[_teamcnt]+=_beginterritories;
        
        
        Rounds[_rID].teamXaddr[msg.sender]=_teamcnt; //map the players address to his team
        Rounds[_rID].nationnameXteam[_teamcnt]=name;
        Rounds[_rID].colorXteam[_teamcnt]=RGB;
        Rounds[_rID].iscolorregistered[RGB]=true;
        Rounds[_rID].teamcnt=_teamcnt;
        Rounds[_rID].isnameregistered[name]=true;//don&#39;t allow countries with duplicate names
        Rounds[_rID].pot+=msg.value;
        
        
        //trigger event
        emit oncreatenation(
            nameXaddress[msg.sender],
            name,
            RGB,
            _teamcnt,
            territories,
            msg.sender);
    }
    
    
    function roll(uint16[] territories,uint16 team) 
    payable
    public
    {
        RequireHuman();
        require(isactive);
        
        require(team!=0);
        
        uint256 _rID = roundID;
        uint256 _now = block.timestamp;
        uint256 _roundstart = Rounds[_rID].roundstart;
        uint256 _trucetime = Rounds[_rID].trucetime;


        if (Rounds[_rID].teamXaddr[msg.sender]==0){ //new player
            Rounds[_rID].teamXaddr[msg.sender]=team;
        }
        else{
            require(Rounds[_rID].teamXaddr[msg.sender]==team); //don&#39;t allow to switch teams   
        }


        //require(territories.length==maxroll); //should allow player to input fewer or extra territories, as a backup plan in case someone is includead earlier in the block or for endgame too
        
        
        require(msg.value==Rounds[_rID].price ); 
        
        uint16 _maxroll = Rounds[_rID].maxroll;
        seed = uint256(keccak256(abi.encodePacked((seed^block.timestamp)))); //far from safe, but the advantadge to roll a 6 is not worth for a miner to cheat
        uint256 rolled = (seed % _maxroll)+1; //dice roll from 1 to maxroll
        uint256 validrolls=0; 
        uint16[] memory territoriesconquered = new uint16[](_maxroll);
        
        if  (_roundstart+_trucetime<_now){//check if the truce has ended
            for (uint i = 0 ; i<territories.length;i++){
                if (getownership(territories[i])==team){ //dont waste a roll for own provinces
                    continue;
                }
                if (hasteamadjacency(territories[i],team)){//valid territory, is adjacent to own
                    territoriesconquered[validrolls]=territories[i];
                    setownership(territories[i],team); //invade it
                    validrolls+=1;
                    if (validrolls==rolled){//exit the loop when we reached our rolled
                        break;
                    }
                }
            }
        }
        else{//if truce
            require(Rounds[_rID].validrollsXteam[team]<Rounds[_rID].maxextensiontruce); //limit number of territories during truce, don&#39;t allow to roll if 50 territories or more
            for  (i = 0 ; i<territories.length;i++){
                if (getownership(territories[i])!=0){ //only invade neutral provinces
                    continue;
                }
                if (hasteamadjacency(territories[i],team)){//valid territory, is adjacent to own
                    territoriesconquered[validrolls]=territories[i];
                    setownership(territories[i],team); //invade it
                    validrolls+=1;
                    if (validrolls==rolled){//exit the loop when we reached our rolled
                        break;
                    }
                }
            }
        }

        Rounds[_rID].validrollsXaddr[msg.sender]+=validrolls;
        Rounds[_rID].validrollsXteam[team]+=validrolls;
        
        uint256 refund;
        if (validrolls<rolled){
            refund = ((rolled-validrolls)*msg.value)/rolled;
        }
        Rounds[_rID].pot+=msg.value-refund;
        if (refund>0){
            msg.sender.transfer(refund);
        }
        
        
        //trigger event
        emit onroll(
            nameXaddress[msg.sender],
            Rounds[_rID].nationnameXteam[team],
            rolled,
            team,
            territoriesconquered,
            msg.sender
            );
    }


    function endround()
    //call this in a separate function cause it can take quite a bit of gas, around 1Mio gas
    public
    {
        RequireHuman();
        require(isactive);
        
        uint256 _rID = roundID;
        require(Rounds[_rID].teamcnt>0); // require at least one nation has been created

        uint256 _pot = Rounds[_rID].pot;
        uint256 fee =_pot/20; //5% admin fee
        uint256 nextpot = _pot/20; //5% of current pot to next round
        uint256 finalpot = _pot-fee-nextpot; //remaining pot to distribute 
        
        
        uint256 _roundstart=Rounds[_rID].roundstart;
        uint256 _now=block.timestamp;
        require(_roundstart+Rounds[_rID].trucetime<_now);//require that the truce has ended


        uint256[] memory _owners_ = new uint256[](86);
        for (uint16 i = 0;i<86;i++){ //memory copy of owners, saves around 400k gas by avoiding SSLOAD opcodes
            _owners_[i]=Rounds[_rID].owners[i];
        }

        uint16 t;
        uint16 team;
        uint16 j;
        for ( i = 1; i<uint16(2750);i++){ //loop until you find a nonzero team
            t=getownership2(i,_owners_[i/32]);
            if (t!=uint16(0)){
                team=t;
                j=i+1;
                break;
            }
        }
        
        for ( i = j; i<uint16(2750);i++){ //check that all nonzero territories belong to team
            t=getownership2(i,_owners_[i/32]);
            if(t>0){
                if(t!=team){
                    require(false);
                }
            }
        }
        Rounds[_rID].teampotshare[team]=finalpot; //entire pot to winner team
        Rounds[_rID].winner=Rounds[_rID].nationnameXteam[team];
        
        
        admin.transfer(fee);
        
        
        //start next round
        _rID+=1;
        Rounds[_rID].trucetime =trucetime;
        Rounds[_rID].roundstart =block.timestamp;
        Rounds[_rID].beginterritories =beginterritories; 
        Rounds[_rID].maxroll = maxroll;
        Rounds[_rID].pot = nextpot;
        Rounds[_rID].price = price;
        Rounds[_rID].maxextensiontruce = maxextensiontruce;
        roundID=_rID;
        
        emit onendround();
    }


    function withdraw() 
    public
    {
        RequireHuman();
        uint256 balance;
        uint256 _roundID=roundID;
        balance=getbalance(_roundID);
        playerlastroundwithdrawn[msg.sender]=_roundID-1;
        if (balance>0){
            msg.sender.transfer(balance);
        }
    }
    
    
    function buyname( string _name)
    public
    payable
    {
        RequireHuman();
        
        
        bytes32 name=nameFilter(_name);
        address prevowner=ownerXname[name];
        require(prevowner!=msg.sender);
        uint256 buyprice = 3*priceXname[name]/2; //require 1.5X what was paid to get the name
        if (3 finney > buyprice){ //starting bids at 3mETH
            buyprice = 3 finney;
        }
        require(msg.value>=buyprice);
        
        uint256 fee;
        uint256 topot;
        uint256 reimbursement;
        
        
        if (prevowner==address(0)){ //if it&#39;s the first time the name is purchased, the payment goes to the pot
            Rounds[roundID].pot+=msg.value ;   
        }
        else{
            fee = buyprice/20; //5% fee on refund
            topot = msg.value-buyprice;//anything over the buyprice goes to the pot
            reimbursement=buyprice-fee; //ammount to pay back
            if (topot>0){
            Rounds[roundID].pot+=topot;
            }
        }
        

        nameXaddress[prevowner]=&#39;&#39;; //change the name of the previous owner to empty
        ownerXname[name]=msg.sender; //set new owner
        priceXname[name]=msg.value; //new buyprice
        bytes32 prevname = nameXaddress[msg.sender];
        nameXaddress[msg.sender]=name; //set name bought as display name for buyer
        
        emit onbuyname(
            name,
            msg.value,
            prevname,
            msg.sender
            );
            
        if (fee>0){
        admin.transfer(fee);
            
        }
        if (reimbursement>0){
        prevowner.transfer(reimbursement);
        }
    }
    
    
    function switchname(bytes32 name) //switch between owned names
    public
    {
        require(ownerXname[name]==msg.sender);//check that sender is the owner of this name
        nameXaddress[msg.sender]=name;//set it
    }
    
    
    function clearname() //empty name, use default random one on UI
    public
    {
        bytes32 empty;
        nameXaddress[msg.sender]=empty;
    }
    

    /*_____      _            _       ______                _   _                 
     |  __ \    (_)          | |     |  ____|              | | (_)                
     | |__) | __ ___   ____ _| |_ ___| |__ _   _ _ __   ___| |_ _  ___  _ __  ___ 
     |  ___/ &#39;__| \ \ / / _` | __/ _ \  __| | | | &#39;_ \ / __| __| |/ _ \| &#39;_ \/ __|
     | |   | |  | |\ V / (_| | ||  __/ |  | |_| | | | | (__| |_| | (_) | | | \__ \
     |_|   |_|  |_| \_/ \__,_|\__\___|_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/*/


    function getownership(uint16 terr) 
    private 
    view
    returns(uint16)
    {//index is floor division, perform AND with a filter that&#39;s full of 0s except in the 8 bit range we want to access so it returns only that 8bit window
        //shift it to the 8 rightmost bits and convert to int16
        return(uint16((Rounds[roundID].owners[terr/32]&(255*2**(8*(uint256(terr%32)))))/(2**(uint256(terr)%32*8))));
    }


    function getownership2(uint16 terr,uint256 ownuint) //slightly modified version of getownership() to use in endround()
    private 
    pure
    returns(uint16)
    {//index if floor division, perform AND with a filter that&#39;s full of 0s except in the 8 bit range we want to access so it returns only that 8bit window
        //shift it right and convert to int16
        return(uint16((ownuint&255*2**(8*(uint256(terr)%32)))/(2**(uint256(terr)%32*8))));
    } 


    function setownership(uint16 terr, uint16 team)
    private
    { //index is floor division, perform AND with a filter that&#39;s full of 1s except in the 8bit range we want to access so that it removes the prev record
        //perform OR with the team number shifted left into the position
        Rounds[roundID].owners[terr/32]=(Rounds[roundID].owners[terr/32]&(115792089237316195423570985008687907853269984665640564039457584007913129639935-(255*(2**(8*(uint256(terr)%32))))))|(uint256(team)*2**((uint256(terr)%32)*8));
    }


    function areadjacent(uint16 terr1, uint16 terr2) 
    private
    view
    returns(bool)
    {
        for (uint i=0;i<19;i++){
            if (adjacencies[terr1][i]==terr2){//are adjacent
                return true;
            }
            if (adjacencies[terr1][i]==0){ //exit early if we get to the end of the valid adjacencies
                return false;
            }
        }
        return false;
    } 


    function hasteamadjacency(uint16 terr,uint16 team) 
    private
    view
    returns(bool)
    {
        for (uint i = 0; i<adjacencies[terr].length;i++){
            if (getownership(adjacencies[terr][i])==team){
                return true;
            }
        }
        return false;
    }
    
    
    //block transactions from contracts
    function RequireHuman()
    private
    view
    {
        uint256  size;
        address addr = msg.sender;
        
        assembly {size := extcodesize(addr)}
        require(size == 0 );
    }

   /*__      ___               ______                _   _                 
     \ \    / (_)             |  ____|              | | (_)                
      \ \  / / _  _____      _| |__ _   _ _ __   ___| |_ _  ___  _ __  ___ 
       \ \/ / | |/ _ \ \ /\ / /  __| | | | &#39;_ \ / __| __| |/ _ \| &#39;_ \/ __|
        \  /  | |  __/\ V  V /| |  | |_| | | | | (__| |_| | (_) | | | \__ \
         \/   |_|\___| \_/\_/ |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/ */

    
    function colorfilter(uint256 RGB)
    public
    pure
    returns(uint256)
    {
        //rounds the R, G and B values down to the closest 32 mutiple, removes anything outside the range
        //this is done to ensure all colors are different enough to avoid confusion
        RGB=RGB&14737632;

        //filter out game default colors
        require(RGB!=12632256);
        require(RGB!=14704640);
        require(RGB!=14729344);
        require(RGB!=8421504);
        require(RGB!=224);
        require(RGB!=8404992);


        return(RGB);
    }


    function getbalance(uint rID)
    public
    view
    returns(uint256)
    {
        uint16 team;
        uint256 balance;
        for (uint i = playerlastroundwithdrawn[msg.sender]+1;i<rID;i++){
            if (Rounds[i].validrollsXaddr[msg.sender]==0){ //skip if player didn&#39;t take part in the round
                continue;
            }
            
            team=Rounds[i].teamXaddr[msg.sender];
            
            balance += (Rounds[i].teampotshare[team]*Rounds[i].validrollsXaddr[msg.sender])/Rounds[i].validrollsXteam[team];
        }
        return balance;
    }
     
     
    function nameFilter(string _input) //Versioned from team JUST, no numbers, no caps, but caps are displayed after each space on the UI
    public
    pure
    returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;
        
        //sorry limited to 32 characters
        require (_length <= 32 && _length > 0, "string must be between 1 and 64 characters");
        // make sure it doesnt start with or end with space
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
        
        // check
        for (uint256 i = 0; i < _length; i++)
        {
                require
                (
                    // require character is a space
                    _temp[i] == 0x20 || 
                    // OR lowercase a-z
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) 
                );
                // make sure theres not 2x spaces in a row
                if (_temp[i] == 0x20){
                    
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");
                }
            }
        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
    
    
    //retrieve arrays and mappings from inside the struct array
    function readowners()
    view
    public
    returns(uint256[101])
    {
        return(Rounds[roundID].owners);
    }
    
    
    function readownerXname(string name)
    view
    public
    returns(address)
    {
        return(ownerXname[nameFilter(name)]);
    }
    
    
    function readisnameregistered(string name)
    view
    public
    returns(bool)
    {
        return(Rounds[roundID].isnameregistered[nameFilter(name)]);
    }
    
    
    function readnameXaddress(address addr)
    view
    public
    returns(bytes32)
    {
        return(nameXaddress[addr]);
    }
    
    
    function readpriceXname(string name)
    view
    public
    returns(uint256)
    {
        return(priceXname[nameFilter(name)]*3/2);
    }
    
    
    function readteamXaddr(address adr)
    view
    public
    returns(uint16){
        return(Rounds[roundID].teamXaddr[adr]);
    }
    
    
    function readvalidrollsXteam(uint16 tim)
    view
    public
    returns(uint256){
        return(Rounds[roundID].validrollsXteam[tim]);
    }
    
    
    function readvalidrollsXaddr(address adr)
    view
    public
    returns(uint256){
        return(Rounds[roundID].validrollsXaddr[adr]);
    }
    
    
    function readnationnameXteam()
    view
    public
    returns(bytes32[256]){
        bytes32[256] memory temp;
        for (uint16 i = 0; i<256; i++){
            temp[i]=Rounds[roundID].nationnameXteam[i];
        }
        return(temp);
    }
    
    
    function readcolorXteam()
    view
    public
    returns(uint256[256]){
        uint256[256] memory temp;
        for (uint16 i = 0; i<256; i++){
            temp[i]=Rounds[roundID].colorXteam[i];
        }
        return(temp);
    }
    
    
    function readiscolorregistered(uint256 rgb)
    view
    public
    returns(bool){
        return(Rounds[roundID].iscolorregistered[colorfilter(rgb)]);
    }
    
    
    function readhistoricalrounds()
    view
    public
    returns(bytes32[]){
        bytes32[] memory asdfg=new bytes32[](2*roundID-2);
        for (uint256 i = 1;i<roundID;i++){
            asdfg[2*i]=Rounds[roundID].winner;
            asdfg[2*i+1]=bytes32(Rounds[roundID].pot);
        }
        return asdfg;
    }
    

     
   /*_____             ______                _   _
    |  __ \           |  ____|              | | (_)                
    | |  | | _____   _| |__ _   _ _ __   ___| |_ _  ___  _ __  ___ 
    | |  | |/ _ \ \ / /  __| | | | &#39;_ \ / __| __| |/ _ \| &#39;_ \/ __|
    | |__| |  __/\ V /| |  | |_| | | | | (__| |_| | (_) | | | \__ \
    |_____/ \___| \_/ |_|   \__,_|_| |_|\___|\__|_|\___/|_| |_|___/ */
   

    //used to load the adjacencies file that&#39;s required to block invalid actions
    function addadjacencies(uint16[] indexes,uint16[] numvals,uint16[] adjs)
    public
    {   
        require(msg.sender==admin);
        require(!isactive);
        
        uint cnt=0;
        for (uint i = 0; i<indexes.length;i++){
            for (uint j = 0;j<numvals[i];j++){
                adjacencies[indexes[i]][j]=adjs[cnt];
                cnt++;
            }
        }   
    }


    //blocks the add function so dev can&#39;t modify the adjacencies after they&#39;ve been loaded, serves as activate function too
    function finishedloading()
    public
    {
        require(msg.sender==admin);
        require(!isactive);
        
        isactive=true;
        
        //seed the first round
        roundID=1;
        uint256 _rID=roundID;
        //Rounds[_rID].roundtime =roundtime;
        Rounds[_rID].roundstart =block.timestamp;
        Rounds[_rID].beginterritories =beginterritories; 
        Rounds[_rID].maxroll = maxroll;
        Rounds[_rID].trucetime = trucetime;
        Rounds[_rID].price = price;
        Rounds[_rID].maxextensiontruce = maxextensiontruce;
    }
    
    
    //admin can change some settings to balance the game if required, they will get into effect at the beggining of a new round
    function changesettings(/*uint256 _roundtime,*/ uint16 _beginterritories, uint16 _maxroll,uint256 _trucetime,uint256 _price,uint256 _maxextensiontruce)
    public
    {
        require(msg.sender==admin);
        //roundtime = _roundtime;
        beginterritories = _beginterritories ;
        maxroll = _maxroll;
        trucetime = _trucetime;
        price = _price;
        maxextensiontruce = _maxextensiontruce;
        
    }


    /* _____ _                   _       
      / ____| |                 | |      
     | (___ | |_ _ __ _   _  ___| |_ ___ 
      \___ \| __| &#39;__| | | |/ __| __/ __|
      ____) | |_| |  | |_| | (__| |_\__ \
     |_____/ \__|_|   \__,_|\___|\__|___/*/

     
    struct RoundData{
        
        //tracks ownership of the territories
        //encoded in 8bit such that 0=noncolonized and the remaining 255 values reference a team
        //32 territories fit each entry, for a total of 3232, there are only 3231 territories 
        //the one that corresponds to the nonexisting ID=0 remains empty
        uint256[101] owners;
        
        
        mapping(address=>uint16) teamXaddr; //return team by address
        //keep track of the rolls to split the pot
        mapping(uint16=>uint256) validrollsXteam; // number of valid rolls by team
        mapping(address=>uint256) validrollsXaddr; //valid rolls by address
        mapping(uint16=>uint256) teampotshare; //money that each team gets at the end of the round is stored here
        mapping(uint16=>bytes32) nationnameXteam;
        uint256 pot;
        
        //1xRGB for map display color
        mapping(uint16=>uint256) colorXteam;
        //track which colors are registered
        mapping(uint256=>bool) iscolorregistered;
        
        
        mapping(bytes32=>bool) isnameregistered; //avoid duplicate nation names within a same round
        
        
        //counter
        uint16 teamcnt;
        
        
        //timers
        uint256 roundstart;
        
        
        //these settings can be modified by admin to balance if required, will get into effect when a new round is started
        uint16 beginterritories; //number of territories to claim at createnation
        uint16 maxroll;// = 6;
        uint256 trucetime;
        uint256 price;
        uint256 maxextensiontruce;
        
        bytes32 winner;
    }


    /*______               _       
     |  ____|             | |      
     | |____   _____ _ __ | |_ ___ 
     |  __\ \ / / _ \ &#39;_ \| __/ __|
     | |___\ V /  __/ | | | |_\__ \
     |______\_/ \___|_| |_|\__|___/*/

     
     event oncreatenation(
        bytes32 leadername,
        bytes32 nationname,
        uint256 color,
        uint16 team,
        uint16[] territories,
        address addr
     );

     event onroll(
        bytes32 playername,
        bytes32 nationname,
        uint256 rolled,
        uint16 team,
        uint16[] territories,
        address addr
     );
     event onbuyname(
        bytes32 newname,
        uint256 price,
        bytes32 prevname,
        address addr
     );
     event onendround(
     );
}