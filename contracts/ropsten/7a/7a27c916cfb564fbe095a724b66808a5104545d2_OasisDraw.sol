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
contract OasisDraw is Owned {
    bool public actived;
    mapping(uint => mapping(address => uint)) drawflag;
    address[] private drawadmins;
    mapping(address => uint) drawtokens;
    mapping(address => bool) public intertoken;
    constructor() public {
	    actived = true;
    }
    function setdrawadm(address user) onlyOwner public {
		bool has = false;
		for(uint i = 0; i < drawadmins.length; i++) {
		    if(drawadmins[i] == user) {
		        delete drawadmins[i];
		        has = true;
		        break;
		    }
		}
		if(has == false) {
		    drawadmins.push(user);
		}
	}
	function chkdrawadm(address user) private view returns(bool hasadm) {
	    hasadm = false;
	    for(uint i = 0; i < drawadmins.length; i++) {
		    if(drawadmins[i] == user) {
		        hasadm = true;
		        break;
		    }
		}
	}
	function adddraw(uint money) public{
	    require(actived == true);
	    require(chkdrawadm(msg.sender) == true);
	    uint _n = now;
	    require(money <= address(this).balance);
	    drawtokens[msg.sender] = _n;
	    drawflag[_n][msg.sender] = money;
	}
	function getdrawtoken(address user) public view returns(uint) {
	    return(drawtokens[user]);
	}
	function chkcan(address user, uint t, uint money) public view returns(bool isdraw){
	    require(chkdrawadm(user) == true);
	    require(actived == true);
		isdraw = true;
		for(uint i = 0; i < drawadmins.length; i++) {
		    address adm = drawadmins[i];
		    if(drawflag[t][adm] != money) {
		        isdraw = false;
		        break;
		    }
		}
	}
	function setactive(bool t) public onlyOwner {
		actived = t;
	}
	function settoken(address target, bool freeze) onlyOwner public {
		intertoken[target] = freeze;
	}
}