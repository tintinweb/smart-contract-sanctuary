/**
 *Submitted for verification at Etherscan.io on 2021-05-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.5.8;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b; assert(a == 0 || c / a == b); return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b; return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a); return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b; assert(c >= a); return c;
    }
}

contract Ownable {
    address payable public owner;
    address payable public newOwner;
    modifier onlyOwner {require(msg.sender == owner);_;}
    function transferOwnership(address payable _newOwner) public onlyOwner {newOwner = _newOwner;}
    function acceptOwnership() public {require(msg.sender == newOwner); owner = newOwner;}
}

contract Destructible is Ownable {}
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC20 is IERC20 {}
contract CoinAgeToken {
    uint256 public coinAgeStartTime;
    uint256 public coinAgeRewards;
    uint256 public minCoinAge;
    uint256 public maxCoinAge;
    function mintingCoinAge() public returns (bool);
    function coinAge() internal view returns (uint);
    function annualMintingRate() internal view returns (uint256);
    event CoinAgeMinting(address indexed _address, uint _coinAgeMinting);
}

//--------------------------------------------------------------------------------------
//Constructor
//--------------------------------------------------------------------------------------

contract AgelessII is ERC20, CoinAgeToken, Ownable {
    using SafeMath for uint256;

    string public name = "AgelessII";
    string public symbol = "AGESII";
    uint public decimals = 18;

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public totalInitialSupply;
    
    uint public presaleSupply;
    uint public bonusPresale;
    
    uint public chainStartTime; //Chain start time
    uint public chainStartBlockNumber; //Chain start block number
    
    //Contract owner can not trigger internal CoinAge minting
    address public contractOwner = 0x5b37A82BA40D897f75e5609CFAb189B3418B00Ab;
    
    //Zealth developer can not trigger internal CoinAge Minting
    address public teamDevs = 0xFF07ce4DE08B61228da1E468fa838465ED39fF0e;
    
    struct transferInStruct{uint128 amount; uint64 time;}

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    constructor() public {
    	owner = msg.sender;

        maxTotalSupply = 21000000 * (10**decimals);
        totalInitialSupply = 32550 * (10**decimals);
        
        chainStartTime = now;
        chainStartBlockNumber = block.number;

        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
        
        presaleSupply = 48300 * (10**decimals);
        bonusPresale = 24150 * (10**decimals);
        emit Transfer(address(0), address(this), presaleSupply + bonusPresale);

    }
    
//--------------------------------------------------------------------------------------
//ERC20 function
//--------------------------------------------------------------------------------------
    
    function transfer(address to, uint256 value) onlyPayloadSize(2 * 32) external returns (bool) {
        if(msg.sender == to && balances[msg.sender] > 0) return mintingCoinAge();
        if(msg.sender == to && balances[msg.sender] <= 0) revert();
        if(msg.sender == to && coinAgeStartTime < 0) revert();
        if(msg.sender == to && contractOwner == msg.sender) revert();
        if(msg.sender == to && teamDevs == msg.sender) revert();
        
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        emit Transfer(msg.sender, to, value);
        
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[to].push(transferInStruct(uint128(value),_now));
        
        return true;
    }

    function balanceOf(address owner) external view returns (uint256 balance) {
        return balances[owner];
    }

    function transferFrom(address from, address to, uint256 value) onlyPayloadSize(3 * 32) external returns (bool) {
        require(to != address(0));

        uint256 _allowance = allowed[from][msg.sender];
        
        balances[from] = balances[from].sub(value);
        balances[to] = balances[to].add(value);
        allowed[from][msg.sender] = _allowance.sub(value);
        emit Transfer(from, to, value);
        
        if(transferIns[from].length > 0) delete transferIns[from];
        uint64 _now = uint64(now);
        transferIns[from].push(transferInStruct(uint128(balances[from]),_now));
        transferIns[to].push(transferInStruct(uint128(value),_now));
        return true;
    }

    function approve(address spender, uint256 value) external returns (bool) {
        require((value == 0) || (allowed[msg.sender][spender] == 0));
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function allowance(address owner, address spender) external view returns (uint256 remaining) {
        return allowed[owner][spender];
    }
    
    function burn(address account, uint256 value) public onlyOwner {
        require(account != address(0));
        balances[msg.sender] = balances[msg.sender].sub(value);
        totalSupply = totalSupply.sub(value);
        totalInitialSupply = totalInitialSupply.sub(value);
        emit Transfer(account, address(0), value);
    }

    function mint(address account, uint256 value) public onlyOwner {
        require(account != address(0));
        require(totalSupply <= maxTotalSupply);
        if(totalSupply == maxTotalSupply) revert();
        balances[msg.sender] = balances[msg.sender].add(value);
        totalSupply = totalSupply.add(value);
        totalInitialSupply = totalInitialSupply.add(value);
        emit Transfer(address(0), msg.sender, value);
    }
    
    function increaseMaxSupply(uint256 value) public onlyOwner {
        maxTotalSupply = maxTotalSupply.add(value);
    }
    
    function decreaseMaxSupply(uint256 value) public onlyOwner {
        maxTotalSupply = maxTotalSupply.sub(value);
    }
    
    function destroy() public onlyOwner {
        selfdestruct(address(this));
    }

//--------------------------------------------------------------------------------------
//Internal CoinAge pool
//--------------------------------------------------------------------------------------

    uint256 public coinAgeRewards = 6300000 * (10**decimals);
    
    uint256 public coinAgeStartTime; //CoinAge Minting start time
    uint256 public baseRate = 5**17; //Default minting rate is 5%
    
    uint public minCoinAge = 1 days; //Minimum CoinAge for minting : 1 day
    uint public maxCoinAge = 90 days; //CoinAge of full weight : 90 days
    
    event ChangeCoinEraRate(uint256 value);
    
    modifier CoinAgeMinter() {
        assert(totalSupply <= maxTotalSupply);
        _;
    }
    
    event ChangeBaseRate(uint256 value);
    
    //How to trigger internal CoinAge minting :
    //Send transaction without any amount of coins/tokens
    //back to yourself, same address that holds/store coins/tokens, 
    //for triggering coins/tokens internal CoinAge minting from wallet.
    //Best option wallet is Metamask. It's pretty easy.

    function mintingCoinAge() CoinAgeMinter public returns (bool) {
        require(balances[msg.sender] > 0);
        if(balances[msg.sender] <= 0) revert();
        if(transferIns[msg.sender].length <= 0) return false;
        if(contractOwner == msg.sender) revert();
        if(teamDevs == msg.sender) revert();
        
        uint coinAgeMinting = getCoinAgeMinting(msg.sender);
        
        if(coinAgeRewards <= 0) return false;
        if(coinAgeRewards == maxTotalSupply) return false;
        
        assert(coinAgeMinting <= coinAgeRewards);
        assert(coinAgeRewards <= maxTotalSupply);
        
        totalSupply = totalSupply.add(coinAgeMinting);
        coinAgeRewards = coinAgeRewards.sub(coinAgeMinting);
        balances[msg.sender] = balances[msg.sender].add(coinAgeMinting);
        
        //Function to reset CoinAge to zero after receive minting coin
        //and user must hold for certain of time again before minting coin
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit CoinAgeMinting(msg.sender, coinAgeMinting);
        emit Transfer(address(0), msg.sender, coinAgeMinting);
        
        return true;
    }

    function annualMintingRate() internal view returns (uint mintingRate) {
        uint _now = now; mintingRate = baseRate;
        
        //1st year minting rate = 100%
        if((_now.sub(coinAgeStartTime)).div(365 days) == 0) {
            mintingRate = (2000 * baseRate).div(100);
            
        //2nd year - 3rd year minting rate = 50%  
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 1) {
            mintingRate = (1000 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 2) {
            mintingRate = (1000 * baseRate).div(100);
            
        //4rd - 6th year minting rate = 25%
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 3) {
            mintingRate = (500 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 4) {
            mintingRate = (500 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 5) {
            mintingRate = (500 * baseRate).div(100);
            
        //7th - 9th year minting rate = 20%
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 6) {
            mintingRate = (400 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 7) {
            mintingRate = (400 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 8) {
            mintingRate = (400 * baseRate).div(100);

        //10th - 12th year minting rate = 15%
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 9) {
            mintingRate = (300 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 10) {
            mintingRate = (300 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 11) {
            mintingRate = (300 * baseRate).div(100);
            
        //13th - 15th year minting rate = 12.5%
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 12) {
            mintingRate = (250 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 13) {
            mintingRate = (250 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 14) {
            mintingRate = (250 * baseRate).div(100);
            
        //16th - 18th year minting rate = 10%    
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 15) {
            mintingRate = (200 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 16) {
            mintingRate = (200 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 17) {
            mintingRate = (200 * baseRate).div(100);
        } 
    }

    function getCoinAgeMinting(address _address) internal view returns (uint) {
        require((now >= coinAgeStartTime) && (coinAgeStartTime > 0));
        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge <= 0) return 0;
        uint mintingRate = baseRate;
        
        //1st year minting rate = 100%
        if((_now.sub(coinAgeStartTime)).div(365 days) == 0) {
            mintingRate = (2000 * baseRate).div(100);
            
        //2nd year - 3rd year minting rate = 50%  
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 1) {
            mintingRate = (1000 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 2) {
            mintingRate = (1000 * baseRate).div(100);
            
        //4rd - 6th year minting rate = 25%
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 3) {
            mintingRate = (500 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 4) {
            mintingRate = (500 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 5) {
            mintingRate = (500 * baseRate).div(100);
            
        //7th - 9th year minting rate = 20%
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 6) {
            mintingRate = (400 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 7) {
            mintingRate = (400 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 8) {
            mintingRate = (400 * baseRate).div(100);

        //10th - 12th year minting rate = 15%
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 9) {
            mintingRate = (300 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 10) {
            mintingRate = (300 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 11) {
            mintingRate = (300 * baseRate).div(100);
            
        //13th - 15th year minting rate = 12.5%
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 12) {
            mintingRate = (250 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 13) {
            mintingRate = (250 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 14) {
            mintingRate = (250 * baseRate).div(100);
            
        //16th - 18th year minting rate = 10%    
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 15) {
            mintingRate = (200 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 16) {
            mintingRate = (200 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(365 days) == 17) {
            mintingRate = (200 * baseRate).div(100);
        } 
        //19th - end minting rate = 5%
        return (_coinAge * mintingRate).div(365 * (10**decimals));
    }
    
    function coinAge() internal view returns (uint myCoinAge) {
        myCoinAge = getCoinAge(msg.sender,now);
    }

    function getCoinAge(address _address, uint _now) internal view returns (uint _coinAge) {
        if(transferIns[_address].length <= 0) return 0;
        for (uint i = 0; i < transferIns[_address].length; i++){
            if(_now < uint(transferIns[_address][i].time).add(minCoinAge)) continue;
            uint coinAgeSeconds = _now.sub(uint(transferIns[_address][i].time));
            if(coinAgeSeconds > maxCoinAge) coinAgeSeconds = maxCoinAge;
            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * coinAgeSeconds.div(1 days));
        }
    }
    
    function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

//--------------------------------------------------------------------------------------
//Set function
//--------------------------------------------------------------------------------------

    function coinAgeMintingStart() public onlyOwner {
        require(msg.sender == owner && coinAgeStartTime == 0);
        coinAgeStartTime = now;
    }
    
    function setCoinAgeRewards(uint256 value) public onlyOwner {
        if(totalSupply == maxTotalSupply) revert();
        coinAgeRewards = coinAgeRewards.add(value);
    }
    
    function setMinCoinAge(uint timestamp) public onlyOwner {
        minCoinAge = timestamp;
    }
    
    function setMaxCoinAge(uint timestamp) public onlyOwner {
        maxCoinAge = timestamp;
    }
    
    function changeBaseRate(uint256 _baseRate) public onlyOwner {
        baseRate = _baseRate;
        emit ChangeBaseRate(baseRate);
    }

//--------------------------------------------------------------------------------------
//Presale
//--------------------------------------------------------------------------------------

    //Set other wallet address that especially to purchase on presale.
    //After purchasing, send coins/tokens to wallet address to hold
    //until presale is close.
    //
    //After presale is close, minting start time has been set
    //and liquidity has been added.
    //
    //Send transaction without any amount of coins/tokens to own wallet address
    //that hold or store coins/tokens to trigger CoinAge minting.
    
    event Purchase(address indexed _purchaser, uint256 _purchasedAmount, uint256 _bonusAmount);
    event ChangePriceRate (uint256 value);
    
    bool public closed;
    
    uint public startDate;
    uint public priceRate = 100;
    uint public constant minimumPurchase = 0.1 ether; //Minimum purchase
    uint public constant maximumPurchase = 100 ether; //Maximum purchase

    function() external payable {
        uint purchasedAmount = msg.value * priceRate;
        uint bonusAmount = purchasedAmount.div(2);
        
        owner.transfer(msg.value);

        require((now >= startDate) && (startDate > 0));
        require(msg.value >= minimumPurchase && msg.value <= maximumPurchase);
        require(purchasedAmount <= presaleSupply, "Not have enough available tokens");
        
        assert(bonusAmount <= bonusPresale);
        
        if(purchasedAmount > presaleSupply) revert();
        if(msg.value == 0) revert();
        if(presaleSupply == 0) revert();
        
        totalSupply = totalInitialSupply.add(purchasedAmount + bonusAmount);
        
        balances[msg.sender] = balances[msg.sender].add(purchasedAmount);
        balances[msg.sender] = balances[msg.sender].add(bonusAmount);
        
        balances[address(this)] = balances[address(this)].sub(purchasedAmount);
        balances[address(this)] = balances[address(this)].sub(bonusAmount);
        
        require(!closed);
        
        emit Transfer(address(this), msg.sender, purchasedAmount);
        emit Transfer(address(this), msg.sender, bonusAmount);
        emit Purchase(msg.sender, purchasedAmount, bonusAmount);
    }
    
    function startSale() public onlyOwner {
        require(msg.sender == owner && startDate == 0);
        startDate = now;
    }
    
    function closeSale() public onlyOwner {
        require(!closed);
        closed = true;
    }
    
    function tokenWithdraw(uint value) public onlyOwner {
        balances[address(this)] = balances[address(this)].sub(value);
        balances[owner] = balances[owner].add(value);
        emit Transfer(address(this), msg.sender, value);
    }
    
    function setPresaleSupply(uint256 _presaleSupply) public onlyOwner {
        presaleSupply = _presaleSupply;
    }
    
    function setBonusPresale(uint256 _bonusPresale) public onlyOwner {
        bonusPresale = _bonusPresale;
    }

    function changePriceRate(uint256 _priceRate) public onlyOwner {
        priceRate = _priceRate;
        emit ChangePriceRate(priceRate);
    }
}