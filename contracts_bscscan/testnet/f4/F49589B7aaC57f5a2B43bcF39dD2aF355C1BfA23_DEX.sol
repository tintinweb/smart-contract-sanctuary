// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract DEX {
    using SafeMath for uint256;

    uint256 constant public START_TIME = 1627329949; // start
    uint256 constant public PRESALE_DAYS = 1 hours;//
    uint256 constant public LOCK_DAYS = 10 minutes;
    uint256 constant public RATE = 1000;
    uint256 constant public DIVIDER = 10;
    uint256 constant public minBUSD = 100;
    uint256 constant public maxBUSD = 500;
    address constant public OWNER = 0x0A39aB2Df9841716CCDFAcDEd2E48FD9aaE2BAaf;

    uint256 public totalInvested;

    IERC20 constant public token = IERC20(0x390626db689C1b3B5ED100d4A20E7ad8865016EE);
    IERC20 constant public BUSD = IERC20(0x390626db689C1b3B5ED100d4A20E7ad8865016EE);

    struct Deposit {
		uint256 amountBUSD;
        uint256 amountToken;
		uint256 timestamp;
        uint256 endLock;
        uint256 status;
	}

    struct User {
		Deposit[] deposits;
	}

    mapping (address => User) internal users;

    function invest(uint256 amount) public payable{
        require(block.timestamp >= START_TIME,"07/26/2021 @ 8:05pm GMT+0000");
        require(block.timestamp <= START_TIME.add(PRESALE_DAYS),"End Sale");
        require(amount >= minBUSD.div(DIVIDER),"Min amount 100 BUSD");
        require(amount.add(getUserTotalInvested(msg.sender)) <= maxBUSD,"Total maximum investment amount 500 BUSD");
        uint tokens = msg.value.mul(RATE);
        require(tokens <= getContractBalanceToken(),"The contract does not have as many tokens");
        User storage user = users[msg.sender];
		user.deposits.push(Deposit(amount,tokens,block.timestamp,block.timestamp.add(LOCK_DAYS),1));
        totalInvested = totalInvested.add(msg.value);
    }

    function getToken() public {
        require(getUserAvailableTokens(msg.sender) > 0, "User has no tokens");
        require(getContractBalanceToken() > getUserAvailableTokens(msg.sender), "The contract does not have as many tokens");
        uint256 amount;
		for (uint256 i = 0; i < users[msg.sender].deposits.length; i++) {
            require(users[msg.sender].deposits[i].status == 1);
            require(users[msg.sender].deposits[i].endLock >= block.timestamp);
			amount = amount.add(users[msg.sender].deposits[i].amountToken);
            users[msg.sender].deposits[i].status = 0;
		}
    }

    function endSale() public {
        require(msg.sender == OWNER);
        require(block.timestamp >= START_TIME.add(PRESALE_DAYS) || getContractBalanceToken() == 0,"Expect the end of the sale");
        token.transfer(OWNER, token.balanceOf(address(this)));
        BUSD.transfer(OWNER, BUSD.balanceOf(address(this)));
    }

    function getUserTotalInvested(address userAddress) public view returns(uint256) {
		uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
			amount = amount.add(users[userAddress].deposits[i].amountBUSD);
		}
		return amount;
	}

    function getUserTokens(address userAddress) public view returns(uint256) {
		uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            require(users[userAddress].deposits[i].status == 1);
			amount = amount.add(users[userAddress].deposits[i].amountToken);
		}
		return amount;
	}

    function getUserAvailableTokens(address userAddress) public view returns(uint256) {
		uint256 amount;
		for (uint256 i = 0; i < users[userAddress].deposits.length; i++) {
            require(users[userAddress].deposits[i].status == 1);
            require(users[userAddress].deposits[i].endLock >= block.timestamp);
			amount = amount.add(users[userAddress].deposits[i].amountToken);
		}
		return amount;
	}

    function getContractBalance() public view returns (uint256) {
		return BUSD.balanceOf(address(this));
	}

    function getContractBalanceToken() public view returns (uint256) {
		return token.balanceOf(address(this));
	}
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }
}

