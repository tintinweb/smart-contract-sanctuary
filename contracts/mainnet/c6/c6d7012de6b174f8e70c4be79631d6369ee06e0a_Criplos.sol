/*
&#169; Copyright 2019. All rights reserved https://criplos.com
*/
pragma solidity ^0.4.25;

contract Criplos {

    event Transfer(address indexed from, address indexed to, uint tokens);

    using SafeMath for uint;
    using ToAddress for bytes;

    string constant public symbol = "CRL";
    string constant public name = "CRipLos";
    uint8 constant public decimals = 18;
	
	address owner;
	address public advance;
	address[] recordAccts;

	uint public priceTokens;
	uint public minMining;
	uint public minRemining;
	uint public minWithdraw;
	uint public minTransfer;

	uint totalTokens_;
	uint totalMining_;
	uint totalMiners_;
	uint techBuff_;

	struct Record {
	uint balance;
	uint volume;
	uint level;
    address master;
	}
	
    mapping(address => Record) info;
	
    constructor() public {
	
		owner = msg.sender;
		advance = 0x427ddC64b9c9e5b303993C6B32aC05Dd101D9Bc5;

		priceTokens = 1e3;
		minMining = 1e17;
		minRemining = 1e19;
		minWithdraw = 1e19;
		minTransfer = 1e18;

		totalTokens_ = 0;
		totalMining_ = 0;
		totalMiners_ = 0;
		techBuff_ = 0;
    }

    function totalSupply() public view returns (uint) {
        return totalTokens_;
    }

    function totalMining() public view returns (uint) {
        return totalMining_.add(techBuff_);
    }

    function totalMiners() public view returns (uint) {
        return totalMiners_;
    }

    function techBuff() public view returns (uint) {
        return techBuff_;
    }	

    function balanceOf(address member) public view returns (uint balance) {
        return info[member].balance;
    }

    function infoMining(address member) public view returns (uint volume, uint level, address master) {
        return (info[member].volume, info[member].level, info[member].master);
    }	

    function transfer(address to, uint tokens) public returns (bool success) {
		require(tokens >= minTransfer && tokens <= info[msg.sender].balance);		
        info[msg.sender].balance = info[msg.sender].balance.sub(tokens);
        info[to].balance = info[to].balance.add(tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    function() public payable {
        process(msg.data.toAddr());
    }

    function process(address master) private {
		require(msg.value >= minMining);	
        uint tokens = msg.value.mul(priceTokens);
		totalTokens_ = totalTokens_.add(tokens);
		process2(tokens, msg.sender, master);
    }

    function process2(uint tokens, address memeber, address master) private {
		
		if (info[memeber].level == 1) info[memeber].level = 0;
		uint mine = tokens.mul(6).div(5);
		totalMining_ = totalMining_.add(mine);

		if (techBuff_ > 0) {
		tokens = tokens.add(techBuff_);
		techBuff_ = 0;		
		}

		if (info[msg.sender].level == 0) {
			totalMiners_ ++;
			recordAccts.push(msg.sender) -1;

			if (info[master].level > 0) {
				info[msg.sender].master = master;
			}
			else {
				info[msg.sender].master = advance;
			} 
		}
	
		info[memeber].volume = info[memeber].volume.add(mine);
		info[memeber].level = info[memeber].level.add(mine);
		
		uint publicTokens = tokens.mul(21).div(25);
		uint advanceTokens = tokens.mul(9).div(100);
		uint masterTokens = tokens.mul(7).div(100);
		uint checkTokens;

		for (uint i = 0; i < totalMiners_; i++) {
			if (info[recordAccts[i]].level > 1) {
			
				checkTokens = publicTokens.mul(info[recordAccts[i]].level).div(totalMining_);
				
				if (checkTokens < info[recordAccts[i]].volume) {
					info[recordAccts[i]].volume = info[recordAccts[i]].volume.sub(checkTokens);
					info[recordAccts[i]].balance = info[recordAccts[i]].balance.add(checkTokens);
					emit Transfer(owner, recordAccts[i], checkTokens);
				}
				else {
					info[recordAccts[i]].balance = info[recordAccts[i]].balance.add(info[recordAccts[i]].volume);
					emit Transfer(owner, recordAccts[i], info[recordAccts[i]].volume);
					techBuff_ = techBuff_.add(checkTokens.sub(info[recordAccts[i]].volume));
					info[recordAccts[i]].volume = 0;
					info[recordAccts[i]].level = 1;
				}
			}
		}
	
		info[advance].balance = info[advance].balance.add(advanceTokens);
        emit Transfer(owner, advance, advanceTokens);

        info[info[memeber].master].balance = info[info[memeber].master].balance.add(masterTokens);
        emit Transfer(owner, info[memeber].master, masterTokens);
		
	}

	function remining(uint tokens) public returns (bool success) {
		require(tokens >= minRemining && tokens <= info[msg.sender].balance);
		info[msg.sender].balance = info[msg.sender].balance.sub(tokens);
		emit Transfer(msg.sender, owner, tokens);
		process2(tokens, msg.sender, 0x0);
		return true;
    }

	function withdraw(uint tokens) public returns (bool success) {
		require(tokens >= minWithdraw && tokens <= info[msg.sender].balance);
		info[msg.sender].balance = info[msg.sender].balance.sub(tokens);
		totalTokens_ = totalTokens_.sub(tokens);
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