/**
 *Submitted for verification at Etherscan.io on 2021-04-19
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
contract CoinAgeMintingPool {
    uint256 public mintingStartTime;
    uint256 public mintingRewards;
    uint256 public minCoinAge;
    uint256 public maxCoinAge;
    uint256 public coinHold;
    function mintingCoin() public returns (bool);
    function coinAge() internal view returns (uint);
    function annualMintingRate() internal view returns (uint256);
    event CoinMinting(address indexed _address, uint _coinsMinting);
}

contract CoinBlockMiningPool {
    uint256 public miningStartTime;
    uint256 public miningRewards;
    uint256 public blockInterval;
    uint256 public coinStored;
    uint256 public currentBlockNumber;
    uint256 public lastBlockNumber;
    uint256 public lastMinedBlockNumber;
    function miningCoin() public returns (bool);
    event CoinMining(address indexed _address, uint _coinsMining);
    event BlockMining(address indexed _address, uint _blocksMining);
}

//------------------------------------------------------------------------------------
//Constructor
//------------------------------------------------------------------------------------

contract PIERCES is ERC20, CoinAgeMintingPool, CoinBlockMiningPool, Ownable {
    using SafeMath for uint256;

    string public name = "PIERCES";
    string public symbol = "PIERCES";
    uint public decimals = 18;

    uint256 public totalSupply;
    uint256 public maxTotalSupply;
    uint256 public totalInitialSupply;

    struct transferInStruct{uint128 amount; uint64 time;}
    
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;

    function PIERCES() public {
        maxTotalSupply = 100000000 * (10**decimals);
        totalInitialSupply = 400000 * (10**decimals);
        
        chainStartTime = now;
        chainStartBlockNumber = block.number;
        
        currentBlockNumber = block.number;
        lastBlockNumber; lastMinedBlockNumber;
        
        coinsPerBlock;
        
        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }
    
//------------------------------------------------------------------------------------
//ERC20 function
//------------------------------------------------------------------------------------

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) external returns (bool) {
        
        //Function to trigger internal PoHAMR minting by sending transaction
        //without any amount to own wallet address that store/hold minimun coin.
        
        if(msg.sender == _to && balances[msg.sender] >= coinHold) return mintingCoin();
        if(msg.sender == _to && balances[msg.sender] < coinHold) revert();
        
        //Function to trigger coin mining by sending transaction
        //without any amount to own wallet address that store/hold minimun coin.
        
        if(msg.sender == _to && balances[msg.sender] >= coinStored) return miningCoin();
        
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
    
    function destroy() public onlyOwner {
        selfdestruct(address(this));
    }

//------------------------------------------------------------------------------------
//Internal PoHAMR (Proof-of-Hold-Age-Minting-and-Repeat) implementation
//------------------------------------------------------------------------------------

    uint256 public chainStartTime; //Chain start time
    uint256 public chainStartBlockNumber; //Chain start block number
    
    uint256 public mintingRewards = 30000000 * (10**decimals);
    uint256 public mintingStartTime; //Minting start time
    
    uint256 public baseMintingRate = 10**17; //Default minting rate is 10%
    uint256 public minCoinAge = 1 days; //Minimum age for minting age: 1 day
    uint256 public maxCoinAge = 90 days; //Minting age of full weight: 90 days

    uint256 public coinHold = 300 * (10**decimals); // Minimum coin/token hold in wallet to trigger minting

    modifier CoinAgeMinter () {
        assert(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] >= coinHold);
        _;
    }
    
    event ChangeBaseMintingRate(uint256 value);
    
    //How to trigger internal PoHAMR minting :
    //Sending transaction without any amount of coin/token
    //back to yourself, same address that holds/store coin/token, 
    //to triggering REEP internal PoHAMR minting from wallet.
    //Best option wallet is Metamask.

    function mintingCoin() CoinAgeMinter public returns (bool) {
        require(balances[msg.sender] >= coinHold);
        if(balances[msg.sender] < coinHold) revert();
        if(transferIns[msg.sender].length <= 0) return false;
        
        uint256 coinsMinting = getCoinMinting(msg.sender);
        if(coinsMinting <= 0) return false;
        
        assert(coinsMinting <= mintingRewards);
        assert(mintingRewards <= maxTotalSupply);
        
        totalSupply = totalSupply.add(coinsMinting);
        mintingRewards = mintingRewards.sub(coinsMinting);
        balances[msg.sender] = balances[msg.sender].add(coinsMinting);
        
        //Function to reset minting age to zero after receive minting coin
        //and user must hold for certain of time again before minting coin
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit CoinMinting(msg.sender, coinsMinting);
        return true;
    }

    function annualMintingRate() internal view returns (uint mintingRate) {
        uint _now = now; mintingRate = baseMintingRate;
        
        //1st year minting rate = 100%
        if((_now.sub(mintingStartTime)).div(1 years) == 0) {
            mintingRate = (1000 * baseMintingRate).div(100);
            
        //2nd year minting rate = 50%  
        } else if((_now.sub(mintingStartTime)).div(1 years) == 1) {
            mintingRate = (500 * baseMintingRate).div(100);
            
        //3rd - 6th year minting rate = 25%
        } else if((_now.sub(mintingStartTime)).div(1 years) == 2) {
            mintingRate = (250 * baseMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 3) {
            mintingRate = (250 * baseMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 4) {
            mintingRate = (250 * baseMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 5) {
            mintingRate = (250 * baseMintingRate).div(100);
            
        //7th - 9th year minting rate = 15%
        } else if((_now.sub(mintingStartTime)).div(1 years) == 6) {
            mintingRate = (150 * baseMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 7) {
            mintingRate = (150 * baseMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 8) {
            mintingRate = (150 * baseMintingRate).div(100);

        //10th - 12th year minting rate = 12.5%
        } else if((_now.sub(mintingStartTime)).div(1 years) == 9) {
            mintingRate = (125 * baseMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 10) {
            mintingRate = (125 * baseMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 11) {
            mintingRate = (125 * baseMintingRate).div(100);
        }
    }

    function getCoinMinting(address _address) internal view returns (uint) {
        require((now >= mintingStartTime) && (mintingStartTime > 0));
        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge <= 0) return 0;
        uint mintingRate = baseMintingRate;
        
        //1st year minting rate = 100%
        if((_now.sub(mintingStartTime)).div(1 years) == 0) {
            mintingRate = (1000 * baseMintingRate).div(100);
            
        //2nd year minting rate = 50%  
        } else if((_now.sub(mintingStartTime)).div(1 years) == 1) {
            mintingRate = (500 * baseMintingRate).div(100);
            
        //3rd - 6th year minting rate = 25%
        } else if((_now.sub(mintingStartTime)).div(1 years) == 2) {
            mintingRate = (250 * baseMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 3) {
            mintingRate = (250 * baseMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 4) {
            mintingRate = (250 * baseMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 5) {
            mintingRate = (250 * baseMintingRate).div(100);
            
        //7th - 9th year minting rate = 15%
        } else if((_now.sub(mintingStartTime)).div(1 years) == 6) {
            mintingRate = (150 * baseMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 7) {
            mintingRate = (150 * baseMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 8) {
            mintingRate = (150 * baseMintingRate).div(100);

        //10th - 12th year minting rate = 12.5%
        } else if((_now.sub(mintingStartTime)).div(1 years) == 9) {
            mintingRate = (125 * baseMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 10) {
            mintingRate = (125 * baseMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 11) {
            mintingRate = (125 * baseMintingRate).div(100);
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
            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time));
            if(nCoinSeconds > maxCoinAge) nCoinSeconds = maxCoinAge;
            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * nCoinSeconds.div(1 days));
        }
    }
    
    function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }
    
    function mintingStart() public onlyOwner {
        require(msg.sender == owner && mintingStartTime == 0);
        mintingStartTime = now;
    }
    
    function setMintingRewards(uint256 value) public onlyOwner {
        if(totalSupply == maxTotalSupply) revert();
        mintingRewards = mintingRewards.add(value);
    }
    
    function setMinCoinAge(uint timestamp) public onlyOwner {
        minCoinAge = timestamp;
    }
    
    function setMaxCoinAge(uint timestamp) public onlyOwner {
        maxCoinAge = timestamp;
    }

    function setMaxTotalSupply(uint256 _maxTotalSupply) public onlyOwner {
        maxTotalSupply = _maxTotalSupply;
    }
    
    function setCoinHold(uint _coinHold) public onlyOwner {
        coinHold = _coinHold;
    }
    
    function changeBaseMintingRate(uint256 _baseMintingRate) public onlyOwner {
        baseMintingRate = _baseMintingRate;
        emit ChangeBaseMintingRate(baseMintingRate);
    }

//------------------------------------------------------------------------------------
//Internal Block Mining Pool implementation
//------------------------------------------------------------------------------------

    uint256 public miningRewards = 30000000 * (10**decimals);
    uint256 public miningStartTime;

    uint256 public coinStored = 1000 * (10**decimals); //Minimum coin/token stored in wallet to trigger mining
    
    uint256 public blockInterval = 10; //The number of blocks that need to pass until the next mining
    uint256 public coinsPerBlock = 1 * (10**decimals);
    
    uint256 public currentBlockNumber = block.number;
    uint256 public lastBlockNumber = currentBlockNumber;
    uint256 public lastMinedBlockNumber = lastBlockNumber;
    
    modifier CoinMiner() {
        assert(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] >= coinStored);
        _;
    }
    
    function miningCoin() CoinMiner public returns (bool) {
        require((now >= miningStartTime) && (miningStartTime > 0));
        require(balances[msg.sender] >= coinStored);
        if(balances[msg.sender] < coinStored) revert();
        
        if(currentBlockNumber > lastBlockNumber + blockInterval) {
            return true;
        } else {
            return false;
        }
    
        uint256 coinsMining = getCoinMining(msg.sender);
        uint256 blocksMining = getBlockMining(msg.sender);
        
        if(coinsMining <= 0) return false;
        
        assert(coinsMining <= miningRewards);
        assert(miningRewards <= maxTotalSupply);
        
        totalSupply = totalSupply.add(coinsMining);
        miningRewards = miningRewards.sub(coinsMining);
        balances[msg.sender] = balances[msg.sender].add(coinsMining);

        emit CoinMining(msg.sender, coinsMining);
        emit BlockMining(msg.sender, blocksMining);
        emit Transfer(address(0), msg.sender, coinsMining);
        
        return true;
    }
    
    function getCoinMining(address _address) internal view returns (uint256) {
        require((now >= miningStartTime) && (miningStartTime > 0));
        _address = msg.sender;
        uint256 blockMining = currentBlockNumber.sub(lastMinedBlockNumber);
        uint256 coinsMining = blockMining.mul(coinsPerBlock);
        return coinsMining;
    }
    
    function getBlockMining(address _address) internal view returns (uint256) {
        _address = msg.sender;
        return lastMinedBlockNumber;
    }
    
    function getBlockCount(address _address) public view returns (uint blockCount) {
        _address = msg.sender; blockCount = currentBlockNumber.sub(lastMinedBlockNumber);
    }
    
    function miningStart() public onlyOwner {
        require(msg.sender == owner && miningStartTime == 0);
        miningStartTime = now;
    }
    
    function setMiningRewards(uint256 value) public onlyOwner {
        if(totalSupply == maxTotalSupply) revert();
        miningRewards = miningRewards.add(value);
    }
    
    function setCoinStored(uint _coinStored) public onlyOwner {
        coinStored = _coinStored;
    }
    
    function setCoinsPerBlock(uint256 _coinsPerBlock) public onlyOwner {
        require(_coinsPerBlock > 0);
        coinsPerBlock = _coinsPerBlock;
    }
    
    function setBlockInterval(uint256 _blockInterval) public onlyOwner {
        blockInterval = _blockInterval;
    }
    
//------------------------------------------------------------------------------------
//Presale
//------------------------------------------------------------------------------------

    event ChangePresaleSupply(uint256 value);
    event ChangeBonusPurchase(uint256 value);
    event ChangeBonusRate(uint256 value);
    event Purchase(address indexed _purchaser, uint256 _purchasedAmount, uint256 _bonusAmount);
    
    bool public closed;
    
    uint public presaleSupply = 400000 * (10**decimals);
    uint public bonusPurchase = 200000 * (10**decimals);
    uint public startDate;
    uint public constant minimumPuchase = 0.1 ether; //Minimum purchase
    uint public constant maximumPurchase = 100 ether; //Maximum purchase

    function () public payable {
        require((now >= startDate && now.sub(startDate) <= 120 days));
        require(msg.value >= minimumPuchase && msg.value <= maximumPurchase);
        assert(purchasedAmount <= presaleSupply);
        assert(bonusAmount <= bonusPurchase);
        if(purchasedAmount > presaleSupply) revert();
        
        uint purchasedAmount; {
        
        if (now.sub(startDate) <= 15 days) {
                purchasedAmount = msg.value * 200;
            } else if(now.sub(startDate) > 15 days && now.sub(startDate) <= 30 days) {
                purchasedAmount = msg.value * 200;
            } else if(now.sub(startDate) > 30 days && now.sub(startDate) <= 45 days) {
                purchasedAmount = msg.value * 200;
            } else if(now.sub(startDate) > 45 days && now.sub(startDate) <= 60 days) {
                purchasedAmount = msg.value * 200;
            } else if(now.sub(startDate) > 60 days && now.sub(startDate) <= 75 days) {
                purchasedAmount = msg.value * 100;
            } else if(now.sub(startDate) > 75 days && now.sub(startDate) <= 90 days) {
                purchasedAmount = msg.value * 100;
            } else if(now.sub(startDate) > 90 days && now.sub(startDate) <= 105 days) {
                purchasedAmount = msg.value * 100;
            } else if(now.sub(startDate) > 105 days && now.sub(startDate) <= 120 days) {
                purchasedAmount = msg.value * 100;
            }
        }
        
        uint bonusAmount; {
            
            if (now.sub(startDate) <= 15 days) {
                bonusAmount = purchasedAmount.div(2);
            } else if(now.sub(startDate) > 15 days && now.sub(startDate) <= 30 days) {
                bonusAmount = purchasedAmount.div(2);
            } else if(now.sub(startDate) > 30 days && now.sub(startDate) <= 45 days) {
                bonusAmount = purchasedAmount.div(4);
            } else if(now.sub(startDate) > 45 days && now.sub(startDate) <= 60 days) {
                bonusAmount = purchasedAmount.div(4);
            } else if(now.sub(startDate) > 60 days && now.sub(startDate) <= 75 days) {
                bonusAmount = purchasedAmount.div(2);
            } else if(now.sub(startDate) > 75 days && now.sub(startDate) <= 90 days) {
                bonusAmount = purchasedAmount.div(2);
            } else if(now.sub(startDate) > 90 days && now.sub(startDate) <= 105 days) {
                bonusAmount = purchasedAmount.div(4);
            } else if(now.sub(startDate) > 105 days && now.sub(startDate) <= 120 days) {
                bonusAmount = purchasedAmount.div(4);
            }
        }
        
        owner.transfer(msg.value);
        
        totalSupply = totalInitialSupply.add(purchasedAmount + bonusAmount);
        presaleSupply = presaleSupply.sub(purchasedAmount);
        bonusPurchase = bonusPurchase.sub(bonusAmount);
        balances[msg.sender] = balances[msg.sender].add(purchasedAmount + bonusAmount);
        
        transferIns[msg.sender]; transferIns[msg.sender].length;
        
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
    
    function changePresaleSupply(uint256 _presaleSupply) public onlyOwner {
        presaleSupply = _presaleSupply;
        emit ChangePresaleSupply(presaleSupply);
    }
    
    function changeBonusPurchase(uint256 _bonusPurchase) public onlyOwner {
        bonusPurchase = _bonusPurchase;
        emit ChangeBonusPurchase(bonusPurchase);
    }
}