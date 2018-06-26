pragma solidity ^0.4.11;

contract ethsoccer48{
	
    struct gamecard
    {
		address gamecardaddress;
		string cardname;
		string cardintro;
		uint cardid;
		uint cardtype;
		uint lv;
		uint maxexp;
        uint exp;
        uint atk;
        uint wins;
		uint games;
		uint rndvalue;
		uint256 salemoney;
    }
    //basic
    //=======
    uint public constant nodata = 0xffffffff;
    uint public constant typemaxcards = 250;
    uint public constant maxtypes = 200;
    address public masteraddress;
    mapping (address => bool) public isgodaddress;
	mapping (address => uint) public addressret;
	uint[7] public payvalue;
	uint public safemode = 0;
	//=======
	
	//all game
	//=======
	mapping (address => uint) public addressfocuscardid;
	mapping (address => string) public addressname;
	uint[200] public typecards;
    gamecard[50000] public allgamecard;
	uint public gamecardcount = 0;
	//=======
	
	function ethsoccer48()
    {
        uint i = 0;
        for(i=0;i<maxtypes;i++)
        {
            typecards[i] = 0;
            if(i<7)
            {
                payvalue[i] = 0;
            }
        }
        masteraddress = msg.sender;
	    isgodaddress[masteraddress] = true;
    }
    
    function getmaxcardcount() public constant returns (uint)
    {
		return 200*250;
    }
    
    function getnowcardcount() public constant returns (uint)
    {
        uint i = 0;
        uint nowcardcount = 0;
        for(i=0;i<maxtypes;i++)
        {
            nowcardcount+=typecards[i];
        }
		return nowcardcount;
    }
    
    function ismaster() constant returns (bool)
	{
		if(msg.sender==masteraddress)
        {
			return true;
		}
		
		if(isgodaddress[msg.sender])
		{
			return true;
		}
		return false;
	}
    
    function addgodaddress(address _setaddress) public
    {
        if(msg.sender==masteraddress)
        {
            isgodaddress[_setaddress] = true;
        }
    }
    
    function delgodaddress(address _setaddress) public
    {
        if(msg.sender==masteraddress)
        {
            isgodaddress[_setaddress] = false;
        }
    }
    
    function setsafemode(uint _setsafemode) public
    {
		if(!ismaster())
		{
			revert();
		}
		safemode = _setsafemode;
    }
	
	function getsafemode() public constant returns (uint)
    {
		return safemode;
    }
    
	function sendeth(uint256 sendethvalue) payable
	{
	    if(!ismaster())
		{
			revert();
		}
	    masteraddress.transfer(sendethvalue);
	}
	
	function getaddressret(address checkaddress) public constant returns (uint)
	{
	    if(checkaddress==msg.sender)
	    {
	        return addressret[msg.sender];
	    }
	    else
	    {
	        if(ismaster())
		    {
		        return addressret[checkaddress];
		    }
	    }
	    return nodata;
	}
	
	function () payable {
        uint i = 0;
        //local var dont too mush
        //uint j = 0;
        uint256 op = 0;
        uint doop = 0;
        uint ret2 = 0;
        uint256 mulvalue = 1;
        for(i=0;i<msg.data.length;i++)
        {
            mulvalue = 1;
            for(ret2=0;ret2<msg.data.length-(i+1);ret2++)
            {
                mulvalue*=256;
            }
            op += (uint(msg.data[i])*mulvalue);
        }
        ret2 = 0;
        
        uint optype = uint(op/100000);
        uint cardid = uint(op%100000);
        
        payvalue[0]+=1;
        payvalue[1] = msg.data.length;
        payvalue[2] = op;
        payvalue[3] = optype;
        payvalue[4] = cardid;
        ret2 = optype;
        
		if(safemode==nodata)
		{
			ret2 = 200;
		}
		else
        //system
        if((optype==0)&&(cardid==0))
        {
            doop = 1;
            ret2 = 100;
        }
        
		if(doop==0)
		{
		    msg.sender.transfer(msg.value);
		}
		addressret[msg.sender] = op;
    }
    
    function getgamecardpos(uint cardid) constant returns (uint)
    {
        uint findpos = nodata;
		if((cardid<=50000)&&(cardid>0))
		{
		    findpos = cardid - 1;
		}
		return findpos;
    }
    
    function getgamecardpos2(address checkaddress) constant returns (uint)
    {
        uint findpos = getgamecardpos(addressfocuscardid[checkaddress]);
		return findpos;
    }
    
    function setaddressname(string setname)
    {
        addressname[msg.sender] = setname;
    }
    
    function getaddressname() constant returns (string) 
    {
        return addressname[msg.sender];
    }
	
    function getaddressfocuscardid() constant returns (uint)
	{
	    return addressfocuscardid[msg.sender];
	}
	
	function getaddressfocuscardid2(address checkaddress) constant returns (uint)
	{
	    return addressfocuscardid[checkaddress];
	}
	
	function setcardaddress(address setaddress,uint cardid) returns (uint)
	{
	    uint  ret = 0;
	    if(ismaster())
		{
			uint findpos = getgamecardpos(cardid);
			if(findpos!=nodata)
			{
				allgamecard[findpos].gamecardaddress =setaddress;
				ret = 1;
			}
		}
		return ret;
	}
	
	function setfocuscardid(address setaddress,uint cardid) returns (uint)
	{
		uint  ret = 0;
	    if(ismaster())
		{
			addressfocuscardid[setaddress] = cardid;
			ret = 1;
		}
		return ret;
	}
	
	function setcardsalemoney(uint cardid,uint256 _setsalemoney) returns (uint)
	{
		uint  ret = 0;
		if(ismaster())
		{
			uint findpos = getgamecardpos(cardid);
			if(findpos!=nodata)
			{
				//addressfocuscardid[allgamecard[findpos].gamecardaddress] = 0;
				allgamecard[findpos].salemoney = _setsalemoney;
			}
		}
		return ret;
	}
	
    function getgamecardcount() constant returns (uint)
    {
        return gamecardcount;
    }
    
    function getgamecardlength() constant returns (uint)
    {
        return allgamecard.length;
    }
    
	function addgamecard(string cardname,string cardintro,uint cardtype,uint lv,uint maxexp,uint atk,uint wins,uint games,uint256 salemoney,address setgamecardaddress)
    {
		if((safemode%10)>0)
		{
			revert();
		}
		//cardtype對應圖
		//cardtype div 10對應數量
		uint cardtype2 = cardtype/10;
        if(cardtype2>=maxtypes)
        {
            revert();
        }
		if(!ismaster())
		{
			revert();
		}
		if(typecards[cardtype2]>=typemaxcards)
		{
			revert();
		}
		typecards[cardtype2]+=1;
		
		//uint cardid = cardtype*typemaxcards+typecards[cardtype];
		//uint pos = cardtype*typemaxcards + typecards[cardtype] - 1;
		
		uint pos = gamecardcount;
		gamecardcount++;
		uint cardid = gamecardcount;
		if(setgamecardaddress==address(0))
		{
			setgamecardaddress = masteraddress;
		}
		allgamecard[pos].gamecardaddress = setgamecardaddress;
		allgamecard[pos].cardname = cardname;
		allgamecard[pos].cardintro = cardintro;
		allgamecard[pos].cardid = cardid;
		allgamecard[pos].cardtype = cardtype;
		allgamecard[pos].lv = lv;
		allgamecard[pos].atk = atk;
		allgamecard[pos].maxexp = maxexp;
		allgamecard[pos].exp = 0;
		allgamecard[pos].wins = wins;
		allgamecard[pos].games = games;
        allgamecard[pos].salemoney = salemoney*100000000;
        allgamecard[pos].rndvalue = uint(now)%100;
    }
    
	function setgamecardname(uint pos,string cardname)	
	{
	    if(pos>=allgamecard.length)
	    {
	        revert();
	    }
	    if((!ismaster())&&(allgamecard[pos].gamecardaddress!=msg.sender))
		{
			revert();
		}
		allgamecard[pos].cardname = cardname;
	}
	
	function setgamecardintro(uint pos,string cardintro)	
	{
	    if(pos>=allgamecard.length)
	    {
	        revert();
	    }
	    if((!ismaster())&&(allgamecard[pos].gamecardaddress!=msg.sender))
		{
			revert();
		}
		allgamecard[pos].cardintro = cardintro;
	}
	
	function setgamecard(uint cardid,uint lv,uint maxexp,uint exp,uint atk,uint wins,uint games)
    {
        uint findpos = getgamecardpos(cardid);
        if((((safemode/10)%10)==0)&&ismaster()&&(findpos!=nodata))
        {
    		uint pos = findpos;
    		allgamecard[pos].lv = lv;
    		allgamecard[pos].maxexp = maxexp;
    		allgamecard[pos].exp = exp;
    		allgamecard[pos].atk = atk;
    		allgamecard[pos].wins = wins;
    		allgamecard[pos].games = games;
            allgamecard[pos].rndvalue = uint(now)%100;
        }
    }
	
    function getgamecard(uint cardid) constant returns (uint[9])
    {
		uint i = 0;
		uint findpos = getgamecardpos(cardid);
        uint[9] memory allstr;
        for(i=0;i<9;i++)
        {
            allstr[i] = 0;
        }
        if(findpos!=nodata)
        {
            //allstr[0] = AddresstoString(allgamecard[findpos].gamecardaddress);
    		//allstr[1] = allgamecard[findpos].cardname;
    		//allstr[2] = allgamecard[findpos].cardintro;
    		allstr[0] = allgamecard[findpos].cardid;
    		allstr[1] = allgamecard[findpos].cardtype;
            allstr[2] = allgamecard[findpos].lv;
            allstr[3] = allgamecard[findpos].maxexp;
			allstr[4] = allgamecard[findpos].exp; 
            allstr[5] = allgamecard[findpos].atk;
            allstr[6] = allgamecard[findpos].wins;
    		allstr[7] = allgamecard[findpos].games;
    		allstr[8] = allgamecard[findpos].rndvalue;
        }
        else
        {
            allstr[0] = nodata;
        }
        return allstr;
    }
    
    function stringToUint(string s) constant returns (uint result) {
        bytes memory b = bytes(s);
        uint i;
        result = 0xffffffff;
        for (i = 0; i < b.length; i++) {
            uint c = uint(b[i]);
            if (c >= 48 && c <= 57) {
                if(result==0xffffffff)
                {
                    result = 0;
                }
                result = (result*10)+(c-48);
            }
        }
    }
    
    function strConcat(string _a, string _b) constant returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        
        string memory abcde = new string(_ba.length + _bb.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
       
        return string(babcde);
    }
    
    function uintToString(uint v) constant returns (string) {
        uint maxlength = 100;
        bytes memory reversed = new bytes(maxlength);
        uint i = 0;
        while (v != 0) {
            uint remainder = v % 10;
            v = v / 10;
            reversed[i] = byte(48 + remainder);
            i++;
            if(i>=maxlength)
            {
                break;
            }
        }
        bytes memory s = new bytes(i);
        for (uint j = 0; j < i; j++) {
            s[j] = reversed[i - j - 1];
        }
        string memory str = string(s);
        return str;
    }
    
    function getgamecardname(uint cardid) constant returns (string)
    {
		uint findpos = getgamecardpos(cardid);
        string memory allstr;
        
        if(findpos!=nodata)
        {
            string memory cardidstr = uintToString(cardid);
            string memory allstr2 = strConcat(cardidstr,&quot;,&quot;);
    		allstr = strConcat(allstr2,allgamecard[findpos].cardname);
        }
        else
        {
            allstr = &quot;nodata&quot;;
        }
        return allstr;
    }
    
    function getgamecardintro(uint cardid) constant returns (string)
    {
		uint findpos = getgamecardpos(cardid);
        string memory allstr;
        
        if(findpos!=nodata)
        {
    		string memory cardidstr = uintToString(cardid);
            string memory allstr2 = strConcat(cardidstr,&quot;,&quot;);
    		allstr = strConcat(allstr2,allgamecard[findpos].cardintro);
        }
        else
        {
            allstr = &quot;nodata&quot;;
        }
        return allstr;
    }
    
    function getgamecardsalemoneyuint256(uint cardid) constant returns (uint256)
    {
		uint findpos = getgamecardpos(cardid);
        uint256 ret = nodata;
        if(findpos!=nodata)
        {
           return allgamecard[findpos].salemoney;
        }
        return ret;
    }
    
    function getgamecardaddress(uint cardid) constant returns (address)
    {
		if(cardid==0)
		{
		    return msg.sender;
		}
		else
		{
    		uint findpos = getgamecardpos(cardid);
            if(findpos!=nodata)
            {
                return allgamecard[findpos].gamecardaddress;
            }
		}
		return address(0);
    }
}