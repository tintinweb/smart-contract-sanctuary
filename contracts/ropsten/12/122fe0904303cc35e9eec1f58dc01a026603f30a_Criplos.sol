pragma solidity ^0.4.24;

contract Criplos {

    event Transfer(address indexed from, address indexed to, uint tokens);

    using SafeMath for uint;
    using ToAddress for bytes;

    string constant public symbol = "CRL";
    string constant public name = "Criplos";
    uint8 constant public decimals = 18;
	
	address constant public advanced = 0x4cc9158DAAFF4284aAbA41bD9A6E8eA03eBbf46A;
	address constant public techbuff = 0xB21C5824A69b778283667d6868286dD68795A010;

	uint constant public minMining = 100;
	uint constant public minRemining = 10;
	uint constant public minWithdraw = 10;
	uint constant public minMaster = 1000;
	uint constant public priceTokens = 1000;
	
	uint totalMining;
	uint totalMiners;

	struct Record {
	uint balance;
	uint volume;
	uint level;
    address master;
	}

	address owner;
    mapping(address => Record) info;
	address[] recordAccts;
	
    constructor() public {
		owner = msg.sender;	
		totalMining = 0;
		totalMiners = 0;
    }

    function totalSupply() public view returns (uint) {
        return totalMining;
    }

    function balanceOf(address member) public view returns (uint balance) {
        return info[member].balance;
    }
	
    function infoTokens(address member) public view returns (uint balance, uint volume, uint level, address master) {
        return (info[member].balance, info[member].volume, info[member].level, info[member].master);
    }	

    function() public payable {
        process(msg.data.toAddr());
    }

    function process(address master) private {
	
		require(msg.value >= minMining.mul(priceTokens));	
        uint tokens = msg.value.mul(priceTokens);

		if (info[msg.sender].level == 0) {
			totalMiners ++;
			recordAccts.push(msg.sender) -1;

			if (info[master].level >= minMaster) {
				info[msg.sender].master = master;
			}
			else {
				info[msg.sender].master = advanced;
			} 
		}
		process2(tokens, msg.sender);
		
    }

    function process2(uint tokens, address memeber) private {
	
		uint mine = tokens.mul(6).div(5);
		totalMining = totalMining.add(mine);
		info[memeber].volume = info[memeber].volume.add(mine);
		info[memeber].level = info[memeber].level.add(mine);

		uint publicTokens = tokens.mul(4).div(5);
		uint advancedTokens = tokens.div(10);
		uint masterTokens = tokens.div(10);
		uint checkTokens;

		for (uint i = 0; i < totalMiners; i++) {
			if (info[recordAccts[i]].level > 1) {
				checkTokens = publicTokens.mul(info[recordAccts[i]].level).div(totalMining);
				if (checkTokens < info[recordAccts[i]].volume) {
					info[recordAccts[i]].volume = info[recordAccts[i]].volume.sub(checkTokens);
					info[recordAccts[i]].balance = info[recordAccts[i]].balance.add(checkTokens);
					emit Transfer(owner, recordAccts[i], checkTokens);
				}
				else {
					info[recordAccts[i]].balance = info[recordAccts[i]].balance.add(info[recordAccts[i]].volume);
					emit Transfer(owner, recordAccts[i], info[recordAccts[i]].volume);
					if (checkTokens > info[recordAccts[i]].volume) {
						info[techbuff].balance = info[techbuff].balance.add(checkTokens.sub(info[recordAccts[i]].volume));
						emit Transfer(owner, techbuff, checkTokens.sub(info[recordAccts[i]].volume));
					totalMining = totalMining.sub(info[recordAccts[i]].level);
					info[recordAccts[i]].volume = 0;
					info[recordAccts[i]].level = 1;
					}
				} 
			}
		}
	
		info[advanced].balance = info[advanced].balance.add(advancedTokens);
        emit Transfer(owner, advanced, advancedTokens);
        info[info[memeber].master].balance = info[info[memeber].master].balance.add(masterTokens);
        emit Transfer(owner, info[memeber].master, masterTokens);
	}

	function remining(uint tokens) public returns (bool success) {
		require(tokens >= minRemining);
		require(tokens <= info[msg.sender].balance);
		info[msg.sender].balance = info[msg.sender].balance.sub(tokens);
		emit Transfer(msg.sender, owner, tokens);
		process2(tokens, msg.sender);
		return true;
    }

	function withdraw(uint tokens) public returns (bool success) {
		require(tokens >= minWithdraw);
		require(tokens <= info[msg.sender].balance);
		info[msg.sender].balance = info[msg.sender].balance.sub(tokens);
		emit Transfer(msg.sender, owner, tokens);
		msg.sender.transfer(tokens.div(priceTokens));
		return true;
    }	
}

library SafeMath {

    /**
    * @dev Multiplies two numbers
    */
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }
        uint c = a * b;
        require(c / a == b, "mul failed");
        return c;
    }

    /**
    * @dev Subtracts two numbers
    */
    function sub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "sub failed");
        return a - b;
    }

    /**
    * @dev Adds two numbers
    */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "add failed");
        return c;
    }
	
    /**
    * @dev Divided two numbers
    */
    function div(uint a, uint b) internal pure returns (uint) {
        uint c = a / b;
        require(b > 0, "div failed");
        return c;
    }	
}

library ToAddress {

    /*
    * @dev Transforms bytes to address
    */
    function toAddr(bytes source) internal pure returns (address addr) {
        assembly {
            addr := mload(add(source, 0x14))
        }
        return addr;
    }
}