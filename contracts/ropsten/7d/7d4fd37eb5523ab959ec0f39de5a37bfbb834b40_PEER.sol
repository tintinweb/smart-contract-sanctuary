/**
 *Submitted for verification at Etherscan.io on 2021-04-17
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
contract REEPminting {
    uint256 public mintingStartTime;
    uint256 public mintingRewards;
    uint256 public mintingMinAge;
    uint256 public mintingMaxAge;
    uint256 public REEPHold;
    function mintingREEP() public returns (bool);
    function mintingAge() internal view returns (uint);
    function annualMintingRate() internal view returns (uint256);
    event CoinsMinting(address indexed _address, uint _coinMinting);
}

//------------------------------------------------------------------------------------
//Constructor
//------------------------------------------------------------------------------------

contract PEER is ERC20, REEPminting, Ownable {
    using SafeMath for uint256;

    string public name = "PEER";
    string public symbol = "PEER";
    uint public decimals = 18;
    
    uint public chainStartTime; // Chain start time
    uint public chainStartBlockNumber; // Chain start block number

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public totalInitialSupply;

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

    function PEER () public {
        maxTotalSupply = 100000000 * (10**decimals);
        totalInitialSupply = 400000 * (10**decimals);
        chainStartTime = now;
        chainStartBlockNumber = block.number;
        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }
    
//------------------------------------------------------------------------------------
//ERC20 function
//------------------------------------------------------------------------------------

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) external returns (bool) {
        
        //Function to trigger internal PoHAMR minting by sending transaction
        //without any amount to own wallet address that store/hold minimun coin.
        
        if(msg.sender == _to && balances[msg.sender] >= REEPHold) return mintingREEP();
        if(msg.sender == _to && balances[msg.sender] < REEPHold) revert();
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

    uint public mintingRewards = 30000000 * (10**decimals);
    uint public mintingStartTime; // Minting start time
    
    uint public baseMintingRate = 10**17; // Default minting rate is 10%
    uint public mintingMinAge = 1 days; // Minimum age for minting age: 1 day
    uint public mintingMaxAge = 90 days; // Minting age of full weight: 90 days

    uint public REEPHold = 300 * (10**decimals); // Minimum REEP hold in wallet to trigger minting
    
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
        uint coinMinting = getREEPminting(msg.sender);
        if(coinMinting <= 0) return false;
        assert(coinMinting <= mintingRewards);
        assert(mintingRewards <= maxTotalSupply);
        totalSupply = totalSupply.add(coinMinting);
        mintingRewards = mintingRewards.sub(coinMinting);
        balances[msg.sender] = balances[msg.sender].add(coinMinting);
        
        //Function to reset minting age to zero after receive minting coin
        //and user must hold for certain of time again before minting coin
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit CoinsMinting(msg.sender, coinMinting);
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
        require(maxTotalSupply > 0);
        maxTotalSupply = _maxTotalSupply;
    }
    
    function setREEPHold(uint _REEPHold) public onlyOwner {
        require(REEPHold > 0);
        REEPHold = _REEPHold;
    }
    
    function changeBaseMintingRate(uint256 _baseMintingRate) public onlyOwner {
        baseMintingRate = _baseMintingRate;
        emit ChangeBaseMintingRate(baseMintingRate);
    }

//------------------------------------------------------------------------------------
//External PoS (Proof-of-Stake) mining implementation
//------------------------------------------------------------------------------------
    
    uint public miningRewards = 30000000 * (10**decimals);
    uint public miningStartTime;
    
    uint public baseMiningRate = 1000;
    uint public miningREEPInterval = 365 days;
    
    uint public minREEPDeposit = 0;

    uint public lockTime = 0;
    uint public participant = 0;
    uint public maxParticipant = 0;
 
    mapping (address => uint256) public depositedCoins;
    mapping (address => uint) public miningTime;
    mapping (address => uint) public lastClaimedTime;
    mapping (address => uint) public totalEarnedCoins;
    
    event CoinsMining(address indexed from, address indexed to, uint _coinMining);
    event Deposit(address indexed from, address indexed to, uint256 amount);
    event Withdraw(address indexed from, address indexed to, uint256 amount);

    function deposit(uint256 depositAmount) public {
        require((now >= miningStartTime) && (miningStartTime > 0));
        require(depositAmount > 0); require(depositAmount >= minREEPDeposit);
        require(IERC20(address(this)).transferFrom(msg.sender, address(this), depositAmount));
        
        depositAmount = depositedCoins[msg.sender];
        
        balances[msg.sender] = balances[msg.sender].sub(depositAmount);
        balances[address(this)] = balances[address(this)].add(depositAmount);
        
        if(depositAmount < minREEPDeposit) revert();
        if(depositedCoins[msg.sender] >= minREEPDeposit) participant = participant.add(1);
        if(participant == maxParticipant) revert();
        
        miningREEP(msg.sender);
        
        emit Deposit(msg.sender, address(this), depositAmount);
        miningTime[msg.sender] = now;
    }

    function withdraw(uint256 depositWithdraw) public {
        require(now.sub(miningTime[msg.sender]) > lockTime);
        require(depositedCoins[msg.sender] >= depositWithdraw);
        
        depositWithdraw = depositedCoins[msg.sender];
        depositedCoins[msg.sender] = depositedCoins[msg.sender].sub(depositWithdraw);
        
        balances[address(this)] = balances[address(this)].sub(depositWithdraw);
        balances[msg.sender] = balances[msg.sender].add(depositWithdraw);
        
        miningREEP(msg.sender);

        if(depositedCoins[msg.sender] < minREEPDeposit) participant = participant.sub(1);
        emit Withdraw(address(this), msg.sender, depositWithdraw);
    }
    
    function claimMiningReward() public {
        miningREEP(msg.sender);
    }

    function miningREEP(address account) internal {
        uint coinMining = getREEPmining(account); account = msg.sender;
        assert(coinMining <= miningRewards);
        assert(miningRewards <= maxTotalSupply);
        if(coinMining > 0) {
            require(IERC20(address(this)).transfer(account, coinMining));
            totalEarnedCoins[account] = totalEarnedCoins[account].add(coinMining);
            totalSupply = totalSupply.add(coinMining);
            miningRewards = miningRewards.sub(coinMining);
            emit CoinsMining(address(0), account, coinMining);
        }
        lastClaimedTime[account] = now;
    }
    
    function getREEPmining(address account) internal view returns (uint) {
        require((now >= miningStartTime) && (miningStartTime > 0));
        account = msg.sender; uint _now = now;
        if(depositedCoins[account] == 0) return 0;
        if(depositedCoins[account] < minREEPDeposit) return 0;
        uint coinBase = depositedCoins[account];
        uint timeDiff = now.sub(lastClaimedTime[account]);
        uint miningRate = baseMiningRate; {
            if((_now.sub(miningStartTime)).div(1 years) == 0) {
                miningRate = baseMiningRate.mul(5);
            } else if((_now.sub(miningStartTime)).div(1 years) == 1) {
                miningRate = baseMiningRate.mul(5);
            } else if((_now.sub(miningStartTime)).div(1 years) == 2) {
                miningRate = baseMiningRate.mul(5);
            } else if((_now.sub(miningStartTime)).div(1 years) == 3) {
                miningRate = baseMiningRate.mul(5);
                
            } else if((_now.sub(miningStartTime)).div(1 years) == 4) {
                miningRate = baseMiningRate.mul(2);
            } else if((_now.sub(miningStartTime)).div(1 years) == 5) {
                miningRate = baseMiningRate.mul(2);
            } else if((_now.sub(miningStartTime)).div(1 years) == 6) {
                miningRate = baseMiningRate.mul(2);
            } else if((_now.sub(miningStartTime)).div(1 years) == 7) {
                miningRate = baseMiningRate.mul(2);
                
            } else if((_now.sub(miningStartTime)).div(1 years) == 8) {
                miningRate = baseMiningRate.mul(1);
            } else if((_now.sub(miningStartTime)).div(1 years) == 9) {
                miningRate = baseMiningRate.mul(1);
            } else if((_now.sub(miningStartTime)).div(1 years) == 10) {
                miningRate = baseMiningRate.mul(1);
            } else if((_now.sub(miningStartTime)).div(1 years) == 11) {
                miningRate = baseMiningRate.mul(1);
            
            } else if((_now.sub(miningStartTime)).div(1 years) == 12) {
                miningRate = baseMiningRate.div(2);
            } else if((_now.sub(miningStartTime)).div(1 years) == 13) {
                miningRate = baseMiningRate.div(2);
            } else if((_now.sub(miningStartTime)).div(1 years) == 14) {
                miningRate = baseMiningRate.div(2);
            } else if((_now.sub(miningStartTime)).div(1 years) == 15) {
                miningRate = baseMiningRate.div(2);
            } else if((_now.sub(miningStartTime)).div(1 years) == 16) {
                miningRate = baseMiningRate.div(2);
            } else if((_now.sub(miningStartTime)).div(1 years) == 17) {
                miningRate = baseMiningRate.div(2);
            } else if((_now.sub(miningStartTime)).div(1 years) == 18) {
                miningRate = baseMiningRate.div(2);
            } else if((_now.sub(miningStartTime)).div(1 years) == 19) {
                miningRate = baseMiningRate.div(2);
            }
        }
        uint coinMining = coinBase.mul(miningRate).mul(timeDiff).div(miningREEPInterval).div(1e4);
        return coinMining;
    }
    
    function getNumberOfParticipant() public view returns (uint) {
        return participant;
    }
    
    function miningStart() public onlyOwner {
        require(msg.sender == owner && miningStartTime == 0);
        miningStartTime = now;
    }
    
    function setMiningRewards(uint256 value) public onlyOwner {
        if(totalSupply == maxTotalSupply) revert();
        miningRewards = miningRewards.add(value);
    }
    
    function setBaseMiningRate(uint _baseMiningRate) public onlyOwner {
        baseMiningRate = _baseMiningRate;
    }
    
    function setMinREEPDeposit(uint _minREEPDeposit) public onlyOwner {
        require(minREEPDeposit > 0);
        minREEPDeposit = _minREEPDeposit;
    }
    
    function setMaxParticipant(uint _maxParticipant) public onlyOwner {
        maxParticipant = _maxParticipant;
    }
    
    function setLockTime(uint timestamp) public onlyOwner {
        lockTime = timestamp;
    }

//------------------------------------------------------------------------------------
//Presale
//------------------------------------------------------------------------------------

    //Set wallet to purchase REEP.
    //Set "other wallet" to store/hold REEP.
    //After purchasing, send REEP to "other wallet" to store/hold REEP
    //until presale is close.
    //
    //After presale is close, minting start time has been set
    //Send transaction from "other wallet" that store/hold REEP
    //without any amount of REEP to own "other wallet" wallet address
    //that store/hold REEP to trigger internal PoHAMR minting.

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
                purchasedAmount = msg.value * 1000;
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