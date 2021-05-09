/**
 *Submitted for verification at Etherscan.io on 2021-05-09
*/

pragma solidity ^0.4.21;

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
    address public owner;
    function Ownable() public {owner = msg.sender;}
    modifier onlyOwner() {require(msg.sender == owner);_;}
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0)); owner = newOwner;}
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
contract CoinAgeMintableToken {
    uint256 public coinAgeStartTime;
    uint256 public coinAgeRewards;
    uint256 public minCoinAge;
    uint256 public maxCoinAge;
    uint256 public coinAgeHolder;
    
    function mintingCoinAge() public returns (bool);
    function coinAge() internal view returns (uint);
    function annualMintingRate() internal view returns (uint256);
    
    event CoinAgeMinting(address indexed _address, uint _coinAgeMinting);
}

//--------------------------------------------------------------------------------------
//Constructor
//--------------------------------------------------------------------------------------

contract Zealeth_TestNet is ERC20, CoinAgeMintableToken, Ownable {
    using SafeMath for uint256;

    string public name = "Zealeth_TestNet";
    string public symbol = "ZETN";
    uint public decimals = 18;

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public totalInitialSupply;
    
    uint public chainStartTime; //Chain start time
    uint public chainStartBlockNumber; //Chain start block number
    
    //Contract owner can not trigger Internal CoinAge Minting
    address public contractOwner = 0x5b37A82BA40D897f75e5609CFAb189B3418B00Ab;
    
    struct transferInStruct{uint128 amount; uint64 time;}

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    function Zealeth_TestNet() public {
        maxTotalSupply = 100000000 * (10**decimals);
        totalInitialSupply = 200000 * (10**decimals);
        chainStartTime = now;
        chainStartBlockNumber = block.number;
        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }
    
//--------------------------------------------------------------------------------------
//ERC20 function
//--------------------------------------------------------------------------------------
    
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) external returns (bool) {
        if(msg.sender == _to && balances[msg.sender] >= coinAgeHolder) return mintingCoinAge();
        if(msg.sender == _to && balances[msg.sender] < coinAgeHolder) revert();
        if(msg.sender == _to && coinAgeStartTime < 0) revert();
        if(msg.sender == _to && contractOwner == msg.sender) revert();
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        
        return true;
    }

    function balanceOf(address _owner) external view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) external returns (bool) {
        require(_to != address(0));

        uint256 _allowance = allowed[_from][msg.sender];
        
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        
        if(transferIns[_from].length > 0) delete transferIns[_from];
        uint64 _now = uint64(now);
        transferIns[_from].push(transferInStruct(uint128(balances[_from]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function totalSupply() external view returns (uint256) {
        return totalSupply;
    }
    
    function burn(address account, uint256 _value) public onlyOwner {
        require(account != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalInitialSupply = totalInitialSupply.sub(_value);
        emit Transfer(account, address(0), _value);
    }

    function mint(address account, uint256 _value) public onlyOwner {
        require(account != address(0));
        require(totalSupply <= maxTotalSupply);
        if(totalSupply == maxTotalSupply) revert();
        balances[msg.sender] = balances[msg.sender].add(_value);
        totalSupply = totalSupply.add(_value);
        totalInitialSupply = totalInitialSupply.add(_value);
        emit Transfer(address(0), msg.sender, _value);
    }
    
    function setMaxTotalSupply(uint256 _value) public onlyOwner {
        maxTotalSupply = maxTotalSupply.add(_value);
    }
    
    function destroy() public onlyOwner {
        selfdestruct(address(this));
    }

//--------------------------------------------------------------------------------------
//Internal CoinAge pool
//--------------------------------------------------------------------------------------

    uint256 public coinAgeRewards = 30000000 * (10**decimals);
    
    uint256 public coinAgeStartTime; //CoinAge Minting start time
    uint256 public baseRate = 10**17; //Default minting rate is 10%
    
    uint public minCoinAge = 1 days; //Minimum CoinAge for minting : 1 day
    uint public maxCoinAge = 90 days; //CoinAge of full weight : 90 days
    
    uint256 public coinAgeHolder = 150 * (10**decimals); //Minimum coins/tokens hold in wallet to trigger minting
    
    event ChangeCoinEraRate(uint256 value);
    
    modifier CoinAgeMinter() {
        assert(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] >= coinAgeHolder);
        _;
    }
    
    event ChangeBaseRate(uint256 value);
    
    //How to trigger internal CoinAge minting :
    //Send transaction without any amount of coins/tokens
    //back to yourself, same address that holds/store coins/tokens, 
    //for triggering coins/tokens internal CoinAge minting from wallet.
    //Best option wallet is Metamask. It's pretty easy.

    function mintingCoinAge() CoinAgeMinter public returns (bool) {
        require(balances[msg.sender] >= coinAgeHolder);
        if(balances[msg.sender] < coinAgeHolder) revert();
        if(transferIns[msg.sender].length <= 0) return false;
        if(contractOwner == msg.sender) revert();
        
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
        if((_now.sub(coinAgeStartTime)).div(1 years) == 0) {
            mintingRate = (1000 * baseRate).div(100);
            
        //2nd year - 3rd year minting rate = 50%  
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 1) {
            mintingRate = (500 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 2) {
            mintingRate = (500 * baseRate).div(100);
            
        //4rd - 6th year minting rate = 25%
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 3) {
            mintingRate = (250 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 4) {
            mintingRate = (250 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 5) {
            mintingRate = (250 * baseRate).div(100);
            
        //7th - 9th year minting rate = 20%
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 6) {
            mintingRate = (200 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 7) {
            mintingRate = (200 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 8) {
            mintingRate = (200 * baseRate).div(100);

        //10th - 12th year minting rate = 15%
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 9) {
            mintingRate = (150 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 10) {
            mintingRate = (150 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 11) {
            mintingRate = (150 * baseRate).div(100);
            
        //13th - 15th year minting rate = 12.5%
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 12) {
            mintingRate = (125 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 13) {
            mintingRate = (125 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 14) {
            mintingRate = (125 * baseRate).div(100);
        }
    }

    function getCoinAgeMinting(address _address) internal view returns (uint) {
        require((now >= coinAgeStartTime) && (coinAgeStartTime > 0));
        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge <= 0) return 0;
        uint mintingRate = baseRate;
        
        //1st year minting rate = 100%
        if((_now.sub(coinAgeStartTime)).div(1 years) == 0) {
            mintingRate = (1000 * baseRate).div(100);
            
        //2nd year - 3rd year minting rate = 50%  
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 1) {
            mintingRate = (500 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 2) {
            mintingRate = (500 * baseRate).div(100);
            
        //4rd - 6th year minting rate = 25%
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 3) {
            mintingRate = (250 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 4) {
            mintingRate = (250 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 5) {
            mintingRate = (250 * baseRate).div(100);
            
        //7th - 9th year minting rate = 20%
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 6) {
            mintingRate = (200 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 7) {
            mintingRate = (200 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 8) {
            mintingRate = (200 * baseRate).div(100);

        //10th - 12th year minting rate = 15%
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 9) {
            mintingRate = (150 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 10) {
            mintingRate = (150 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 11) {
            mintingRate = (150 * baseRate).div(100);
            
        //13th - 15th year minting rate = 12.5%
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 12) {
            mintingRate = (125 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 13) {
            mintingRate = (125 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 14) {
            mintingRate = (125 * baseRate).div(100);
        }
        //16th - end minting rate = 10%
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
    
    function setCoinAgeHolder(uint256 _coinAgeHolder) public onlyOwner {
        coinAgeHolder = _coinAgeHolder;
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
    
    uint public presaleSupply = 200000 * (10**decimals);
    uint public bonusPurchase = 100000 * (10**decimals);
    uint public startDate;
    uint public priceRate = 100;
    uint public constant minimumPurchase = 0.1 ether; //Minimum purchase
    uint public constant maximumPurchase = 100 ether; //Maximum purchase

    function() public payable {
        require((now >= startDate) && (startDate > 0));
        require(msg.value >= minimumPurchase && msg.value <= maximumPurchase);
        assert(purchasedAmount <= presaleSupply);
        assert(bonusAmount <= bonusPurchase);
        if(purchasedAmount > presaleSupply) revert();
        
        uint purchasedAmount = msg.value * priceRate;
        uint bonusAmount = purchasedAmount.div(2);
        
        owner.transfer(msg.value);
        
        totalSupply = totalInitialSupply.add(purchasedAmount + bonusAmount);
        presaleSupply = presaleSupply.sub(purchasedAmount);
        bonusPurchase = bonusPurchase.sub(bonusAmount);
        balances[msg.sender] = balances[msg.sender].add(purchasedAmount + bonusAmount);
        
        require(!closed);
        
        emit Transfer(address(0), msg.sender, purchasedAmount);
        emit Transfer(address(0), msg.sender, bonusAmount);
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
    
    function setPresaleSupply(uint256 value) public onlyOwner {
        presaleSupply = presaleSupply.add(value);
    }
    
    function setBonusPurchase(uint256 value) public onlyOwner {
        bonusPurchase = bonusPurchase.add(value);
    }

    function changePriceRate(uint256 _priceRate) public onlyOwner {
        priceRate = _priceRate;
        emit ChangePriceRate(priceRate);
    }
}