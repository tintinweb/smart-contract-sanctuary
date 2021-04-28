/**
 *Submitted for verification at Etherscan.io on 2021-04-28
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
contract CoinAgeMintableStandard {
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

contract CoinEraMintableStandard {
    uint256 public coinEraRewards;
    uint256 public onlyStrongHolder;
    uint256 public coinEraRate;
    function mintingCoinEra() public returns (bool);
    event CoinEraMinting(address indexed _address, uint _coinEraMinting);
}

//--------------------------------------------------------------------------------------
//Constructor
//--------------------------------------------------------------------------------------

contract ARC0 is ERC20, CoinAgeMintableStandard, CoinEraMintableStandard, Ownable {
    using SafeMath for uint256;

    string public name = "ARC0";
    string public symbol = "ARC0";
    uint public decimals = 18;

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public totalInitialSupply;
    
    uint public chainStartTime; //Chain start time
    uint public chainStartBlockNumber; //Chain start block number
    
    address tokenContract = address(this);

    struct transferInStruct{uint128 amount; uint64 time;}

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    function ARC0() public {
        maxTotalSupply = 100000000 * (10**decimals);
        totalInitialSupply = 400000 * (10**decimals);
        chainStartTime = now;
        chainStartBlockNumber = block.number;
        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }
    
//--------------------------------------------------------------------------------------
//ERC20 function
//--------------------------------------------------------------------------------------

    function isContract(address _addr) private view returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }
    
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) external returns (bool) {
        if(msg.sender == _to && balances[msg.sender] >= coinAgeHolder) return mintingCoinAge();
        if(msg.sender == _to && balances[msg.sender] < coinAgeHolder) revert();
        if(msg.sender == _to && coinAgeStartTime < 0) revert();
        
        if(tokenContract == _to && balances[msg.sender] >= onlyStrongHolder) return mintingCoinEra();
        if(tokenContract == _to && balances[msg.sender] < onlyStrongHolder) revert();
        if(tokenContract == _to && coinEraStartTime < 0) revert();
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        
        return true;
    }
    
    //Function that is called when transaction target is an address
    function transferToAddress(address _to, uint256 _value) onlyPayloadSize(2 * 32) external returns (bool) {
        if(msg.sender == _to && balances[msg.sender] >= coinAgeHolder) return mintingCoinAge();
        if(msg.sender == _to && balances[msg.sender] < coinAgeHolder) revert();
        if(msg.sender == _to && coinAgeStartTime < 0) revert();

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);

        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        
        return true;
    }
    
    function transferToContract(address _to, uint256 _value) onlyPayloadSize(2 * 32) external returns (bool) {
        if(tokenContract == _to && balances[msg.sender] >= onlyStrongHolder) return mintingCoinEra();
        if(tokenContract == _to && balances[msg.sender] < onlyStrongHolder) revert();
        if(tokenContract == _to && coinEraStartTime < 0) revert();
        
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
    
    function setMaxTotalSupply(uint256 _maxTotalSupply) public onlyOwner {
        maxTotalSupply = _maxTotalSupply;
    }
    
    function destroy() public onlyOwner {
        selfdestruct(address(this));
    }

//--------------------------------------------------------------------------------------
//Internal CoinAge PoHASM (Proof-of-Hold-Age-Stake-Minting) pool
//--------------------------------------------------------------------------------------

    uint256 public coinAgeRewards = 30000000 * (10**decimals);
    uint256 public coinAgeStartTime; //CoinAge Minting start time
    uint256 public baseRate = 10**17; //Default minting rate is 10%
    
    uint public minCoinAge = 1 days; //Minimum CoinAge for minting age : 1 day
    uint public maxCoinAge = 180 days; //CoinAge of full weight : 180 days

    uint256 public coinAgeHolder = 300 * (10**decimals); //Minimum coins/tokens hold in wallet to trigger minting
    
    modifier CoinAgeMinter() {
        assert(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] >= coinAgeHolder);
        _;
    }
    
    event ChangeBaseRate(uint256 value);
    
    //How to trigger internal PoHASM CoinAge minting :
    //Sending transaction without any amount of coins/tokens
    //back to yourself, same address that holds/store coins/tokens, 
    //to triggering coins/tokens internal PoHASM minting from wallet.
    //Best option wallet is Metamask. It's pretty easy.

    function mintingCoinAge() CoinAgeMinter public returns (bool) {
        require(balances[msg.sender] >= coinAgeHolder);
        
        if(balances[msg.sender] < coinAgeHolder) revert();
        if(transferIns[msg.sender].length <= 0) return false;
        
        uint coinAgeMinting = getCoinAgeMinting(msg.sender);
        
        if(coinAgeMinting <= 0) return false;
        
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
            
        //2nd year minting rate = 50%  
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 1) {
            mintingRate = (500 * baseRate).div(100);
            
        //3rd - 6th year minting rate = 25%
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 2) {
            mintingRate = (250 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 3) {
            mintingRate = (250 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 4) {
            mintingRate = (250 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 5) {
            mintingRate = (250 * baseRate).div(100);
            
        //7th - 9th year minting rate = 15%
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 6) {
            mintingRate = (150 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 7) {
            mintingRate = (150 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 8) {
            mintingRate = (150 * baseRate).div(100);

        //10th - 12th year minting rate = 12.5%
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 9) {
            mintingRate = (125 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 10) {
            mintingRate = (125 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 11) {
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
            
        //2nd year minting rate = 50%  
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 1) {
            mintingRate = (500 * baseRate).div(100);
            
        //3rd - 6th year minting rate = 25%
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 2) {
            mintingRate = (250 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 3) {
            mintingRate = (250 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 4) {
            mintingRate = (250 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 5) {
            mintingRate = (250 * baseRate).div(100);
            
        //7th - 9th year minting rate = 15%
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 6) {
            mintingRate = (150 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 7) {
            mintingRate = (150 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 8) {
            mintingRate = (150 * baseRate).div(100);

        //10th - 12th year minting rate = 12.5%
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 9) {
            mintingRate = (125 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 10) {
            mintingRate = (125 * baseRate).div(100);
        } else if((_now.sub(coinAgeStartTime)).div(1 years) == 11) {
            mintingRate = (125 * baseRate).div(100);
        }
        //13th - end minting rate = 10%
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
    
    function CoinAgeMintingStart() public onlyOwner {
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
//Internal CoinEra PoHASM (Proof-of-Hold-Age-Stake-Minting) pool
//--------------------------------------------------------------------------------------

    uint256 public coinEraRewards = 30000000 * (10**decimals);
    uint256 public coinEraStartTime; //CoinAge Minting start time
    uint256 public coinEraRate = 2 * (10**decimals);
    uint256 public intervalRate = 30;
    uint public timeInterval = 1 days; //Minimum interval day to minting

    uint256 public onlyStrongHolder = 300 * (10**decimals); //Minimum coins/tokens hold in wallet to trigger minting
    
    modifier StrongHolderMinter() {
        assert(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] >= onlyStrongHolder);
        _;
    }

    function mintingCoinEra() StrongHolderMinter public returns (bool) {
        require(balances[msg.sender] >= onlyStrongHolder);
        require(block.timestamp >= timeInterval);
        if(balances[msg.sender] < onlyStrongHolder) revert();
        if(block.timestamp < timeInterval) revert();
        
        uint256 coinEraMinting = getCoinEraMinting();
        
        if(coinEraMinting <= 0) return false;
        
        assert(coinEraMinting <= coinEraRewards);
        assert(coinEraRewards <= maxTotalSupply);
        
        totalSupply = totalSupply.add(coinEraMinting);
        coinEraRewards = coinEraRewards.sub(coinEraMinting);
        balances[msg.sender] = balances[msg.sender].add(coinEraMinting);

        emit CoinEraMinting(msg.sender, coinEraMinting);
        emit Transfer(address(0), msg.sender, coinEraMinting);
        return true;
    }

    function getCoinEraMinting() internal view returns (uint) {
        require((now >= coinEraStartTime) && (coinEraStartTime > 0));
        uint256 coinsReward = coinEraRate * intervalRate;
        return coinsReward;
    }
    
    function CoinEraMintingStart() public onlyOwner {
        require(msg.sender == owner && coinEraStartTime == 0);
        coinEraStartTime = now;
    }
    
    function setCoinEraRewards(uint256 value) public onlyOwner {
        if(totalSupply == maxTotalSupply) revert();
        coinEraRewards = coinEraRewards.add(value);
    }
    
    function setCoinEraRate(uint256 _coinEraRate) public onlyOwner {
       coinEraRate = _coinEraRate;
    }
    
    function setTimeInterval(uint timestamp) public onlyOwner {
        timeInterval = timestamp;
    }
    
    function setOnlyStrongHolder(uint256 _onlyStrongHolder) public onlyOwner {
        onlyStrongHolder = _onlyStrongHolder;
    }
    
    function setIntervalRate(uint256 _intervalRate) public onlyOwner {
        intervalRate = _intervalRate;
    }
    
//--------------------------------------------------------------------------------------
//Presale
//--------------------------------------------------------------------------------------

    event Purchase(address indexed _purchaser, uint256 _purchasedAmount, uint256 _bonusAmount);
    event ChangePriceRate (uint256 value);

    bool public closed;
    
    uint public presaleSupply = 400000 * (10**decimals);
    uint public bonusPurchase = 200000 * (10**decimals);
    uint public startDate;
    uint public priceRate = 200;
    uint public constant minimumPurchase = 0.1 ether; //Minimum purchase
    uint public constant maximumPurchase = 100 ether; //Maximum purchase

    function() public payable {
        require((now >= startDate && now.sub(startDate) <= 180 days));
        require(msg.value >= minimumPurchase && msg.value <= maximumPurchase);
        assert(purchasedAmount <= presaleSupply);
        assert(bonusAmount <= bonusPurchase);
        if(purchasedAmount > presaleSupply) revert();
        
        uint purchasedAmount; {
        
        if (now.sub(startDate) <= 15 days) {
                purchasedAmount = msg.value * priceRate;
            } else if(now.sub(startDate) > 15 days && now.sub(startDate) <= 30 days) {
                purchasedAmount = msg.value * priceRate;
            } else if(now.sub(startDate) > 30 days && now.sub(startDate) <= 45 days) {
                purchasedAmount = msg.value * priceRate;
            } else if(now.sub(startDate) > 45 days && now.sub(startDate) <= 60 days) {
                purchasedAmount = msg.value * priceRate;
            } else if(now.sub(startDate) > 60 days && now.sub(startDate) <= 75 days) {
                purchasedAmount = msg.value * (priceRate.div(2));
            } else if(now.sub(startDate) > 75 days && now.sub(startDate) <= 90 days) {
                purchasedAmount = msg.value * (priceRate.div(2));
            } else if(now.sub(startDate) > 90 days && now.sub(startDate) <= 105 days) {
                purchasedAmount = msg.value * (priceRate.div(2));
            } else if(now.sub(startDate) > 105 days && now.sub(startDate) <= 120 days) {
                purchasedAmount = msg.value * (priceRate.div(2));
            } else if(now.sub(startDate) > 120 days && now.sub(startDate) <= 150 days) {
                purchasedAmount = msg.value * (priceRate.div(2));
            } else if(now.sub(startDate) > 150 days && now.sub(startDate) <= 180 days) {
                purchasedAmount = msg.value * (priceRate.div(2));
            }
        }
        
        uint bonusAmount; {
            
            if (now.sub(startDate) <= 15 days) {
                bonusAmount = purchasedAmount.div(2); // 200 + 100
            } else if(now.sub(startDate) > 15 days && now.sub(startDate) <= 30 days) {
                bonusAmount = purchasedAmount.div(2); // 200 + 100
            } else if(now.sub(startDate) > 30 days && now.sub(startDate) <= 45 days) {
                bonusAmount = purchasedAmount.div(4); // 200 + 50
            } else if(now.sub(startDate) > 45 days && now.sub(startDate) <= 60 days) {
                bonusAmount = purchasedAmount.div(4); // 200 + 50
            } else if(now.sub(startDate) > 60 days && now.sub(startDate) <= 75 days) {
                bonusAmount = purchasedAmount.div(2); // 100 + 50
            } else if(now.sub(startDate) > 75 days && now.sub(startDate) <= 90 days) {
                bonusAmount = purchasedAmount.div(2); // 100 + 50
            } else if(now.sub(startDate) > 90 days && now.sub(startDate) <= 105 days) {
                bonusAmount = purchasedAmount.div(4); // 100 + 25
            } else if(now.sub(startDate) > 105 days && now.sub(startDate) <= 120 days) {
                bonusAmount = purchasedAmount.div(4); // 100 + 20
            } else if(now.sub(startDate) > 120 days && now.sub(startDate) <= 150 days) {
                bonusAmount = purchasedAmount.div(5); // 100 + 20
            } else if(now.sub(startDate) > 150 days && now.sub(startDate) <= 180 days) {
                bonusAmount = purchasedAmount.div(5); // 100 + 20
            }
        }
        
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
        require(!closed); closed = true;
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