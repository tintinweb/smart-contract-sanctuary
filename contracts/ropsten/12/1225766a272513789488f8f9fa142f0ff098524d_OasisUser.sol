pragma solidity ^ 0.4.25;
// ----------------------------------------------------------------------------
// 管理员
// ----------------------------------------------------------------------------
contract Owned {
	address public owner;
	address public newOwner;
	event OwnershipTransferred(address indexed _from, address indexed _to);
	constructor() public {
		owner = msg.sender;
	}
	modifier onlyOwner {
		require(msg.sender == owner);
		_;
	}
	function transferOwnership(address _newOwner) public onlyOwner {
		newOwner = _newOwner;
	}
	function acceptOwnership() public {
		require(msg.sender == newOwner);
		emit OwnershipTransferred(owner, newOwner);
		owner = newOwner;
		newOwner = address(0);
	}
}
contract OasisUser is Owned {
    bool public actived;
    mapping(address => address) public topuser1;
	mapping(address => address) public topuser2;
	mapping(address => address) public topuser3;
	//mapping(address => mapping(uint => address[])) public sunuser;
	mapping(address => address[]) public sunuser1;
	mapping(address => address[]) public sunuser2;
	mapping(address => address[]) public sunuser3;
	mapping(uint => address[]) public levelusers;
	mapping(address => bool) public intertoken;
	uint8[] public mans;//用户上线人数的数组
	uint8[] public prizelevelsuns;//用户上线人数的数组
	uint8[] public prizelevelmans;//用户上线人数的比例数组
	uint8[] public prizelevelsunsday;//用户上线人数的数组
	uint[] public prizelevelmansday;//用户上线人数的比例数组
	uint[] public prizeactivetime;
    constructor() public {
	    actived = true;
	    mans = [2,4,6];
	    //prizelevelsuns = [20,30,50];
		//prizelevelmans = [100,300,800];
		//prizelevelsunsday = [2,4,6];
		//prizelevelmansday = [10 ether,30 ether,50 ether];
		
		prizelevelsuns = [2,3,5];//test
		prizelevelmans = [3,5,8];//test
		prizelevelsunsday = [1,2,3];//test
		prizelevelmansday = [1 ether,3 ether,5 ether];//test
		prizeactivetime = [0,0,0];
    }
    function bindusertop(address me, address top) public returns(bool) {
	    //uint d = ethBase.gettoday();
	    require(intertoken[msg.sender] == true);
	    if(topuser1[me] == address(0) && me != top){
	        topuser1[me] = top;
	        sunuser1[top].push(me);
	        if(topuser1[top] != address(0)) {
	            address top2 = topuser1[top];
	            topuser2[me] = top2;
	            sunuser2[top2].push(me);
	            //dayusersun[top2][d]++;
	            if(topuser1[top2] != address(0)) {
	                address top3 = topuser1[top2];
	                topuser3[me] = top3;
    	            sunuser3[top3].push(me);
    	            //dayusersun[top3][d]++;
	            }
	        }
	        return(true);
	    }else{
	        return(false);
	    }
	    
	}
	function gettopuser(address user) public view returns(address top) {
	    top = topuser1[user];
	}
	function gettops(address user) public view returns(address top1,address top2,address top3) {
	    if(topuser1[user] != address(0) && sunuser1[topuser1[user]].length >= mans[0]) {
	        top1 = topuser1[user];
	    }
	    if(topuser2[user] != address(0) && sunuser2[topuser2[user]].length >= mans[1]) {
	        top2 = topuser2[user];
	    }
	    if(topuser3[user] != address(0) && sunuser3[topuser3[user]].length >= mans[2]) {
	        top3 = topuser3[user];
	    }
	}
	function setactivelevel(uint level) private returns(bool) {
	    uint t = prizeactivetime[level];
	    if(t == 0) {
	        prizeactivetime[level] = now + 1 days;
	    }
	    return(true);
	}
	function getactiveleveltime(uint level) public view returns(uint t) {
	    t = prizeactivetime[level];
	}
	function getlevellen(uint l) public view returns(uint) {
	    return(levelusers[l].length);
	}
	function setuserlevel(address user) public returns(bool) {
	    require(intertoken[msg.sender] == true);
	    uint level = getlevel(user);
	    bool has = false;
	    if(level == 1) {
	        
	        for(uint i = 0; i < levelusers[1].length; i++) {
	            if(levelusers[1][i] == user) {
	                has = true;
	            }
	        }
	        if(has == false) {
	            levelusers[1].push(user);
	            setactivelevel(0);
	            return(true);
	        }
	    }
	    if(level == 2) {
	        if(has == true) {
	            for(uint ii = 0; ii < levelusers[1].length; ii++) {
    	            if(levelusers[1][ii] == user) {
    	                delete levelusers[1][ii];
    	            }
    	        }
    	        levelusers[2].push(user);
    	        setactivelevel(1);
    	        return(true);
	        }else{
	           for(uint i2 = 0; i2 < levelusers[2].length; i2++) {
    	            if(levelusers[2][i2] == user) {
    	                has = true;
    	            }
    	        }
    	        if(has == false) {
    	            levelusers[2].push(user);
    	            setactivelevel(1);
    	            return(true);
    	        }
	        }
	    }
	    if(level == 3) {
	        if(has == true) {
	            for(uint iii = 0; iii < levelusers[2].length; iii++) {
    	            if(levelusers[2][iii] == user) {
    	                delete levelusers[2][iii];
    	            }
    	        }
    	        levelusers[3].push(user);
    	        setactivelevel(2);
    	        return(true);
	        }else{
	           for(uint i3 = 0; i3 < levelusers[3].length; i3++) {
    	            if(levelusers[3][i3] == user) {
    	                has = true;
    	            }
    	        }
    	        if(has == false) {
    	            levelusers[3].push(user);
    	            setactivelevel(2);
    	            return(true);
    	        }
	        }
	    }
	}
	function getlevel(address addr) public view returns(uint) {
	    uint num1 = sunuser1[addr].length;
	    uint num2 = sunuser2[addr].length;
	    uint num3 = sunuser3[addr].length;
	    uint nums = num1 + num2 + num3;
	    if(num1 >= prizelevelsuns[2] && nums >= prizelevelmans[2]) {
	        return(3);
	    }
	    if(num1 >= prizelevelsuns[1] && nums >= prizelevelmans[1]) {
	        return(2);
	    }
	    if(num1 >= prizelevelsuns[0] && nums >= prizelevelmans[0]) {
	        return(1);
	    }
	    return(0);
	}
	function gettruelevel(uint n, uint m) public view returns(uint) {
	    if(n >= prizelevelsunsday[2] && m >= prizelevelmansday[2]) {
	        return(3);
	    }
	    if(n >= prizelevelsunsday[1] && m >= prizelevelmansday[1]) {
	        return(2);
	    }
	    if(n >= prizelevelsunsday[0] && m >= prizelevelmansday[0]) {
	        return(1);
	    }
	    return(0);
	    
	}
	function settoken(address target, bool freeze) onlyOwner public {
		intertoken[target] = freeze;
	}
}