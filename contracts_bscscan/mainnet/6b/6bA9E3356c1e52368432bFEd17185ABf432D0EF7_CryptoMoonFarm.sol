/**
 *Submitted for verification at BscScan.com on 2021-10-26
*/

/* 
 *
 *   https://busd.cryptomoon.farm/
 *   https://t.me/CryptoMoonFarm
 *   The newest high-yield experimental BUSD farm game!
 *
 *   [USAGE INSTRUCTION]
 *   1) Connect any BSC(BUSD) supported wallet
 *   2) Approve BUSD and buy Farmers
 *   3) Wait for Farmers to farm BUSD
 *   4) Compound and Collect your BUSD!
 *
 *   [INFO ON FARMING]
 *   1 FARMER CAN FARM 0.1 BUSD PER DAY
 *   FARMER START PRICE: 1.0526 BUSD PER FARMER
 *   -- 95 Farmers, 9.5 BUSD per day, equalling to 9.5% daily roi
 *   -- As supply decreases and demand increases, daily roi can go down up to 5% for new buys
 *
 *   [REFERRALS]
 *   - 10% Direct Referral Commission
 *
 */


pragma solidity ^0.4.26;

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract CryptoMoonFarm {

    using SafeMath for uint256;
    
    address public BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;
    uint256 public HARVEST_STEP = 10 days; // 10% daily
    uint256 public marketSupply = 0; // to be initialized with 500,000
    uint256 public marketDemand = 0;
    uint256 DEV_FEE = 5;
    uint256 REF_FEE = 10;
    bool public initialized = false;
    address public ceoAddress;
    mapping(address => uint256) public farmers;
    mapping(address => uint256) public claimedBUSD;
    mapping(address => uint256) public unclaimedBUSD;
    mapping(address => uint256) public lastCompound;
    mapping(address => address) public referrals;

    constructor() public {
        ceoAddress = msg.sender;
    }

    function hireFarmers(address ref, uint256 amount) public {
        require(initialized);

        ERC20(BUSD).transferFrom(address(msg.sender), address(this), amount);

        uint256 farmersBought = calculateBuy(amount);
        require(farmersBought > 0);
        
        updateRef(msg.sender, ref, amount);
        
        // update user info
        unclaimedBUSD[msg.sender] = getBUSDSinceLastCompound(msg.sender);
        lastCompound[msg.sender] = block.timestamp;
        farmers[msg.sender] = farmers[msg.sender].add(farmersBought);
        
        // pay fee
        uint256 fee = devFee(amount);
        ERC20(BUSD).transfer(ceoAddress, fee);
        
        // update market
        // normalise amount from wei to busd
        amount = amount.div(1 ether);
        marketSupply = marketSupply.sub(amount);
        marketDemand = marketDemand.add(amount);
    }

    function compound() public {
        require(initialized);
        
        // check BUSD amount claimable
        uint256 amount = getBUSDSinceLastCompound(msg.sender);
        require(amount > 0);
        
        // check if valid for buying
        uint256 farmersBought = calculateBuy(amount);
        require(farmersBought > 0);
        
        // update user info
        unclaimedBUSD[msg.sender] = 0;
        lastCompound[msg.sender] = block.timestamp;
        farmers[msg.sender] = farmers[msg.sender].add(farmersBought);
    }

    function collectBUSD() public {
        require(initialized);
        
        // check BUSD amount claimable
        uint256 amount = getBUSDSinceLastCompound(msg.sender);
        require(amount > 0);
        
        // update user info
        claimedBUSD[msg.sender] = claimedBUSD[msg.sender].add(amount);
        unclaimedBUSD[msg.sender] = 0;
        lastCompound[msg.sender] = block.timestamp;
        
        // collect
        ERC20(BUSD).transfer(msg.sender, amount);
        
        // update market
        // normalise amount from wei to busd
        amount = amount.div(1 ether);
        marketSupply = marketSupply.add(amount);
        marketDemand = marketDemand.sub(amount);
    }
    
    function updateRef(address user, address ref, uint256 amount) internal {
        // default to ceoAddress if invalid ref
        ref = (ref == address(0)) ? ceoAddress : ref;
        if(referrals[user] == address(0)) {
            // new user
            referrals[user] = ref;
            // give commission
            unclaimedBUSD[ref] = unclaimedBUSD[ref].add(amount.mul(REF_FEE).div(100));
        }
    }

    function calculateBuy(uint256 amount) public view returns(uint256) {
    
        // subtract devFee to allow more room for contract balance
        amount = amount.sub(devFee(amount));
        
        // normalize amount to market value
        amount = amount.div(1 ether);
        if(amount <= 0) return 0;
        
        // supply & demand magic formula
        uint256 a = amount.mul(marketSupply).div(marketDemand);
        uint256 b = amount.mul(amount).mul(marketSupply).div(marketDemand.mul(marketDemand));
        
        // avoid SafeMath error
        return a > b ? a.sub(b) : 0;
    }

    function devFee(uint256 amount) public view returns (uint256) {
        return amount.mul(DEV_FEE).div(100);
    }

    function initMarket() public {
        require(msg.sender == ceoAddress);
        require(marketSupply == 0);
        initialized = true;
        marketSupply = 500000;
        marketDemand = 500000;
    }

    function getBalance() public view returns (uint256) {
        return ERC20(BUSD).balanceOf(address(this));
    }

    function getMyFarmers() public view returns (uint256) {
        return farmers[msg.sender];
    }

    function getMyBUSD() public view returns (uint256) {
        return unclaimedBUSD[msg.sender].add(getBUSDSinceLastCompound(msg.sender));
    }

    function getMyClaimedBUSD() public view returns (uint256) {
        return claimedBUSD[msg.sender].add(getBUSDSinceLastCompound(msg.sender));
    }

    function getBUSDSinceLastCompound(address user) public view returns (uint256 amount) {
        uint256 _farmers = farmers[user];
        if(_farmers > 0) {
            uint256 elapsed = block.timestamp.sub(lastCompound[user]);
            amount = _farmers.mul(1 ether).mul(elapsed).div(HARVEST_STEP);
        }
        amount = amount.add(unclaimedBUSD[user]);
    }
    
    function getMyLastCompound() public view returns(uint256) {
        return lastCompound[msg.sender];
    }
    
    function getMyReferrer() public view returns(address) {
        return referrals[msg.sender];
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