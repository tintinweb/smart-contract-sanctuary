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
contract REEPMintingCoinAgePool {
    uint256 public mintingStartTime;
    uint256 public mintingRewards;
    uint256 public mintingMinAge;
    uint256 public mintingMaxAge;
    uint256 public TokenHold;
    function mintingREEP() public returns (bool);
    function mintingAge() internal view returns (uint);
    function annualMintingRate() internal view returns (uint256);
    event REEPMinting(address indexed _address, uint _tokensMinting);
}

contract REEPBlockMiningPool {
    uint256 public miningStartTime;
    uint256 public blockRewards;
    uint256 public REEPStored;
    function miningBLOCK() public returns (bool);
    event BLOCKMining(address indexed _address, uint _blockMining);
}

//------------------------------------------------------------------------------------
//Constructor
//------------------------------------------------------------------------------------

contract PEERS is ERC20, REEPMintingCoinAgePool, REEPBlockMiningPool, Ownable {
    using SafeMath for uint256;

    string public name = "PEERS";
    string public symbol = "PEERS";
    uint public decimals = 18;
    
    uint256 public chainStartTime; // Chain start time
    uint256 public chainStartBlockNumber; // Chain start block number

    uint256 public totalSupply;
    uint256 public maxTotalSupply;
    uint256 public totalInitialSupply;

    struct transferInStruct{uint128 amount; uint64 time;}

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    modifier REEPMinter () {
        assert(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] >= REEPHold);
        _;
    }

    function PEERS () public {
        maxTotalSupply = 100000000 * (10**decimals);
        totalInitialSupply = 400000 * (10**decimals);
        chainStartTime = now;
        chainStartBlockNumber = block.number;
        currentBlockNumber = block.number;
        lastBlockNumber;
        lastMinedBlockNumber = block.number;
        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
        tokensPerBlock;
    }
    
//------------------------------------------------------------------------------------
//ERC20 function
//------------------------------------------------------------------------------------

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) external returns (bool) {
        
        //Function to trigger internal PoHAMR minting by sending transaction
        //without any amount to own wallet address that store/hold minimun coin.
        
        if(msg.sender == _to && balances[msg.sender] >= REEPHold) return mintingREEP();
        if(msg.sender == _to && balances[msg.sender] < REEPHold) revert();
        
        
        if(address(this) == _to && balances[msg.sender] >= REEPStored) return miningBLOCK();
        if(address(this) == _to && balances[msg.sender] < REEPStored) revert();
        
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

    uint256 public mintingRewards = 30000000 * (10**decimals);
    uint256 public mintingStartTime; // Minting start time
    
    uint256 public baseMintingRate = 10**17; // Default minting rate is 10%
    uint256 public mintingMinAge = 1 days; // Minimum age for minting age: 1 day
    uint256 public mintingMaxAge = 90 days; // Minting age of full weight: 90 days

    uint256 public REEPHold = 300 * (10**decimals); // Minimum REEP hold in wallet to trigger minting
    
    event ChangeBaseMintingRate(uint256 value);
    
    //How to trigger internal PoHAMR minting :
    //Sending transaction without any amount of REEP
    //back to yourself, same address that holds/store REEP, 
    //to triggering REEP internal PoHAMR minting from wallet.
    //Best option wallet is Metamask.

    function mintingREEP() REEPMinter public returns (bool) {
        require(balances[msg.sender] >= REEPHold);
        if(balances[msg.sender] < REEPHold) revert();
        if(transferIns[msg.sender].length <= 0) return false;
        
        uint256 tokensMinting = getREEPminting(msg.sender);
        if(tokensMinting <= 0) return false;
        
        assert(tokensMinting <= mintingRewards);
        assert(mintingRewards <= maxTotalSupply);
        
        totalSupply = totalSupply.add(tokensMinting);
        mintingRewards = mintingRewards.sub(tokensMinting);
        balances[msg.sender] = balances[msg.sender].add(tokensMinting);
        
        //Function to reset minting age to zero after receive minting coin
        //and user must hold for certain of time again before minting coin
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit REEPMinting(msg.sender, tokensMinting);
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

    function getREEPminting(address _address) internal view returns (uint) {
        require((now >= mintingStartTime) && (mintingStartTime > 0));
        uint _now = now; uint _mintingAge = getMintingAge(_address, _now);
        if(_mintingAge <= 0) return 0; uint mintingRate = baseMintingRate;
        
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
        return (_mintingAge * mintingRate).div(365 * (10**decimals));
    }
    
    function mintingAge() internal view returns (uint myMintingAge) {
        myMintingAge = getMintingAge(msg.sender,now);
    }

    function getMintingAge(address _address, uint _now) internal view returns (uint _mintingAge) {
        if(transferIns[_address].length <= 0) return 0;
        for (uint i = 0; i < transferIns[_address].length; i++){
            if(_now < uint(transferIns[_address][i].time).add(mintingMinAge)) continue;
            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time));
            if(nCoinSeconds > mintingMaxAge) nCoinSeconds = mintingMaxAge;
            _mintingAge = _mintingAge.add(uint(transferIns[_address][i].amount) * nCoinSeconds.div(1 days));
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
    
    function setMintingMaxAge(uint timestamp) public onlyOwner {
        mintingMaxAge = timestamp;
    }

    function setMaxTotalSupply(uint256 _maxTotalSupply) public onlyOwner {
        maxTotalSupply = _maxTotalSupply;
    }
    
    function setREEPHold(uint _REEPHold) public onlyOwner {
        REEPHold = _REEPHold;
    }
    
    function changeBaseMintingRate(uint256 _baseMintingRate) public onlyOwner {
        baseMintingRate = _baseMintingRate;
        emit ChangeBaseMintingRate(baseMintingRate);
    }

//------------------------------------------------------------------------------------
//Internal Block Mining Pool implementation
//------------------------------------------------------------------------------------

    uint256 public blockRewards = 30000000 * (10**decimals);
    uint256 public miningStartTime;

    uint256 public REEPStored = 100 * (10**decimals); // Minimum REEP stored in wallet to trigger mining

    uint256 public currentBlockNumber = block.number;
    uint256 public lastBlockNumber = currentBlockNumber;
    uint256 public lastMinedBlockNumber = currentBlockNumber;
    
    uint256 public blockInterval = 10; //the number of blocks that need to pass until the next mining
    uint256 public tokensPerBlock = 1 * (10**decimals);
    
    modifier BlockMiner() {
        assert(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] >= REEPStored);
        _;
    }
    
    function miningBLOCK() BlockMiner public returns (bool) {
        require((now >= miningStartTime) && (miningStartTime > 0));
        require(balances[msg.sender] >= REEPStored);
        if(balances[msg.sender] < REEPStored) revert();
    
        uint256 blockMining = getBlockMining(msg.sender);
        
        if(blockMining <= 0) return false;
        if(currentBlockNumber > lastBlockNumber + blockInterval) {return true;} 
            else {return false;}
        
        assert(blockMining <= blockRewards);
        assert(blockRewards <= maxTotalSupply);
        
        totalSupply = totalSupply.add(blockMining);
        blockRewards = mintingRewards.sub(blockMining);
        balances[msg.sender] = balances[msg.sender].add(blockMining);

        emit BLOCKMining(msg.sender, blockMining);
        emit Transfer(address(0), msg.sender, blockMining);
        
        return true;
    }
    
    function getBlockMining(address _address) internal view returns (uint) {
        require((now >= miningStartTime) && (miningStartTime > 0));
        _address = msg.sender;
        uint256 blockMining = (currentBlockNumber.sub(lastMinedBlockNumber)).mul(tokensPerBlock);
        return blockMining;
    }
    
    function getBlockCount(address _address) public view returns (uint blockCount) {
        _address = msg.sender;
        blockCount = currentBlockNumber.sub(lastMinedBlockNumber);
        return blockCount;
    }
    
    function miningStart() public onlyOwner {
        require(msg.sender == owner && miningStartTime == 0);
        miningStartTime = now;
    }
    
    function setBlockRewards(uint256 value) public onlyOwner {
        if(totalSupply == maxTotalSupply) revert();
        blockRewards = blockRewards.add(value);
    }
    
    function setREEPStored(uint _REEPStored) public onlyOwner {
        REEPStored = _REEPStored;
    }
    
    function setTokensPerBlock(uint256 _tokensPerBlock) public onlyOwner {
        require(_tokensPerBlock > 0);
        tokensPerBlock = _tokensPerBlock;
    }
    
    function setBlockInterval(uint256 _blockInterval) public onlyOwner {
        blockInterval = _blockInterval;
    }


//------------------------------------------------------------------------------------
//Deposit Mining Implementation
//------------------------------------------------------------------------------------
    
    address public tokencontractAddress = address(this);
    
    uint256 public depositRewards = 30000000 * (10**decimals);
    uint256 public REEPDeposit = 200 * (10**decimals);
    uint256 public lockTime = 24 hours; //Locking time before withdraw after deposit
    uint256 public participantMiner = 0;
    
    uint256 public depositStartTime;
    uint256 public rewardsPerBlock = 100 * (10*decimals);
    
    mapping (address => uint256) public depositCoins;
    mapping (address => uint) public miningTime;
    mapping (address => uint) public totalDepositRewards;
    
    event DepositMining(address indexed _address, uint256 amount);
    event Deposit(address indexed from, address indexed to, uint256 amount);
    event Withdraw(address indexed from, address indexed to, uint256 amount);
    
    function deposit(uint256 depositAmount) public payable {
        require((now >= depositStartTime) && (depositStartTime > 0));
        require(msg.value == REEPDeposit);
        require(depositAmount >= REEPDeposit);
        
        depositAmount = depositCoins[msg.sender];
        
        ERC20(tokencontractAddress).transferFrom(msg.sender, address(this), depositAmount);
        if(ERC20(tokencontractAddress).transferFrom(msg.sender, address(this), depositAmount)) miningDeposit(msg.sender);
        if(ERC20(tokencontractAddress).transferFrom(msg.sender, address(this), depositAmount)) participantMiner = participantMiner.add(1);
        
        balances[msg.sender] = balances[msg.sender].sub(depositAmount);
        balances[address(this)] = balances[address(this)].add(depositAmount);
        
        emit Deposit(msg.sender, address(this), depositAmount);
        
        miningTime[msg.sender] = now;
        miningDeposit(msg.sender);
    }
    
    function withdraw(uint256 withdrawAmount) public payable {
        require(depositCoins[msg.sender] >= withdrawAmount);
        require(now.sub(miningTime[msg.sender]) > lockTime);
        
        withdrawAmount = depositCoins[msg.sender];
        
        ERC20(tokencontractAddress).transferFrom(address(this), msg.sender, withdrawAmount);
        if(ERC20(tokencontractAddress).transferFrom(address(this), msg.sender, withdrawAmount)) participantMiner = participantMiner.sub(1);
        if(depositCoins[msg.sender] < REEPDeposit) participantMiner = participantMiner.sub(1);
        
        balances[msg.sender] = balances[msg.sender].add(withdrawAmount);
        balances[address(this)] = balances[address(this)].sub(withdrawAmount);
        
        emit Withdraw(address(this), msg.sender, withdrawAmount);
        
        miningDeposit(msg.sender);
    }
    
    function claimDepositReward() public {
        miningDeposit(msg.sender);
    }
    
    function miningDeposit(address account) internal {
        uint depositMining = getDepositMining(account);
        account = msg.sender;
        assert(depositMining <= depositRewards);
        assert(depositRewards <= maxTotalSupply);
        
        totalDepositRewards[account] = totalDepositRewards[account].add(depositMining);
        totalSupply = totalSupply.add(depositMining);
        depositRewards = depositRewards.sub(depositMining);
        
        if(currentBlockNumber > lastBlockNumber + blockInterval)
        balances[account].add(depositMining);
        
        if(depositCoins[msg.sender] < REEPDeposit) revert();
        
        emit DepositMining(account, depositMining);
        emit Transfer(address(0), account, depositMining);
    }
    
    function getDepositMining(address account) internal view returns (uint) {
        require((now >= depositStartTime) && (depositStartTime > 0));
        account = msg.sender;
        if(depositCoins[msg.sender] < REEPDeposit) return 0;
        if(depositMining <= 0) return 0;
        uint256 blockReward = (currentBlockNumber.sub(lastMinedBlockNumber)).mul(rewardsPerBlock);
        uint256 depositMining = blockReward.div(participantMiner);
        return depositMining;
    }
    
    function depositStart() public onlyOwner {
        require(msg.sender == owner && miningStartTime == 0);
        depositStartTime = now;
    }
    
    function setDepositRewards(uint256 value) public onlyOwner {
        if(totalSupply == maxTotalSupply) revert();
        depositRewards = depositRewards.add(value);
    }
    
    function setREEPDeposit(uint _REEPDeposit) public onlyOwner {
        REEPDeposit = _REEPDeposit;
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