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
    uint256 constant public RATE = 1000;
    uint256 constant public DIVIDER = 10;
    uint256 constant public minBNB = 1;
    uint256 constant public maxBNB = 50;
    address constant public OWNER = 0x0A39aB2Df9841716CCDFAcDEd2E48FD9aaE2BAaf;

    uint256 public totalInvested;
    uint256 public forSale = 5000;

    IERC20 constant public token = IERC20(0x390626db689C1b3B5ED100d4A20E7ad8865016EE);

    mapping(address => uint256) balances;
    mapping(address => uint256) invested;

    function invest(uint256 amount) public {
        //require(block.timestamp >= START_TIME,"07/26/2021 @ 8:05pm GMT+0000");
        //require(block.timestamp <= START_TIME.add(PRESALE_DAYS),"End Sale");
        //uint256 amount = msg.value;
        require(amount >= minBNB.div(DIVIDER),"Min amount 1 BNB");
        require(amount.add(invested[msg.sender]) <= maxBNB.div(DIVIDER),"Total maximum investment amount 5 BNB");
        uint tokens = amount.mul(RATE);
        require(forSale >= tokens,"No more tokens");
        balances[msg.sender] = balances[msg.sender].add(tokens);
        invested[msg.sender] = invested[msg.sender].add(amount);
        totalInvested = totalInvested.add(amount);
        forSale = forSale.sub(tokens);
    }

    function getToken() public payable{
        require(balances[msg.sender] > 0, "User has no tokens");
        require(getContractBalanceToken() > balances[msg.sender], "The contract does not have as many tokens");
        uint256 allowance = token.allowance(address(this),msg.sender);
        require(allowance >= balances[msg.sender], "Check the token allowance");
        token.transfer(msg.sender, balances[msg.sender]);
        balances[msg.sender] = 0;
    }

    function endSale() public {
        require(msg.sender == OWNER);
        require(block.timestamp >= START_TIME.add(PRESALE_DAYS) || getContractBalanceToken() == 0,"Expect the end of the sale");
        token.transfer(OWNER, token.balanceOf(address(this)));
        msg.sender.transfer(address(this).balance);
    }

    function getUserTotalInvested(address userAddress) public view returns(uint256) {
		return invested[userAddress];
	}

    function getUserTokens(address userAddress) public view returns(uint256) {
		return balances[userAddress];
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

