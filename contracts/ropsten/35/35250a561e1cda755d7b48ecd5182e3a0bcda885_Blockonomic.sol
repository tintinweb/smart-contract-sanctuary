/**
 *Submitted for verification at Etherscan.io on 2021-04-20
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
contract PoHAMRMintable {
    uint256 public mintingStartTime;
    uint256 public miningStartTime;
    
    uint256 public mintingRewards;
    uint256 public miningRewards;
    
    uint256 public mintingMinAge;
    uint256 public mintingMaxAge;
    
    uint256 public COINHold;
    uint256 public COINStore;
    
    function mintingCOIN() public returns (bool);
    function miningCOIN() public returns (bool);
    function mintingAge() internal view returns (uint);
    function annualMintingRate() internal view returns (uint256);
    
    event CoinsMinting(address indexed _address, uint _coinMinting);
    event CoinsMining(address indexed _address, uint _coinMining);
}

//------------------------------------------------------------------------------------
//Constructor
//------------------------------------------------------------------------------------

contract Blockonomic is ERC20, PoHAMRMintable, Ownable {
    using SafeMath for uint256;

    string public name = "Blockonomic";
    string public symbol = "BLOCK";
    uint public decimals = 18;

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

    function Blockonomic() public {
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
        
        //Function to trigger internal PoHAMR minting and mining by sending transaction
        //without any amount to own wallet address that store/hold minimun coin.
        
        if(msg.sender == _to && balances[msg.sender] >= COINHold) return mintingCOIN();
        if(msg.sender == _to && balances[msg.sender] >= COINStore) return miningCOIN();
        if(msg.sender == _to && balances[msg.sender] < COINHold) revert();
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
//CoinAge Pool
//------------------------------------------------------------------------------------

    uint public mintingRewards = 30000000 * (10**decimals);
    uint public mintingStartTime; //Minting start time
    
    uint public chainStartTime; //Chain start time
    uint public chainStartBlockNumber; //Chain start block number
    
    uint public baseMintingRate = 10**17; //Default minting rate is 10%
    uint public mintingMinAge = 1 days; //Minimum age for minting age: 1 day
    uint public mintingMaxAge = 90 days; //Minting age of full weight: 120 days

    uint public COINHold = 300 * (10**decimals); //Minimum coin/token hold in wallet to trigger minting
    
    modifier PoHAMRMinter() {
        assert(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] >= COINHold);
        _;
    }
    
    event ChangeBaseMintingRate(uint256 value);
    
    //How to trigger internal PoHAMR minting and mining :
    //Sending transaction without any amount of coin/token
    //back to yourself, same address that holds/store coin/token, 
    //to triggering coin/token internal PoHAMR minting from wallet.
    //Best option wallet is Metamask.

    function mintingCOIN() PoHAMRMinter public returns (bool) {
        require(balances[msg.sender] >= COINHold);
        
        if(balances[msg.sender] < COINHold) revert();
        if(transferIns[msg.sender].length <= 0) return false;
        
        uint coinMinting = getCOINminting(msg.sender);
        
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

    function getCOINminting(address _address) internal view returns (uint) {
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
    
    function setMintingMinAge(uint timestamp) public onlyOwner {
        mintingMinAge = timestamp;
    }
    
    function setMintingMaxAge(uint timestamp) public onlyOwner {
        mintingMaxAge = timestamp;
    }

    function setMaxTotalSupply(uint256 _maxTotalSupply) public onlyOwner {
        maxTotalSupply = _maxTotalSupply;
    }
    
    function setCOINHold(uint _COINHold) public onlyOwner {
        COINHold = _COINHold;
    }
    
    function changeBaseMintingRate(uint256 _baseMintingRate) public onlyOwner {
        baseMintingRate = _baseMintingRate;
        emit ChangeBaseMintingRate(baseMintingRate);
    }

//------------------------------------------------------------------------------------
//Internal PoHAMR (Proof-of-Hold-Age-Minting-and-Repeat) implementation
//BlockAge Pool
//------------------------------------------------------------------------------------

    uint public miningRewards = 30000000 * (10**decimals);
    uint public miningStartTime; //Mining start time
    
    uint public miningMinAge = 1 days; //Minimum age for mining age: 1 day
    uint public miningMaxAge = 180 days; //Mining age of full weight: 180 days
    
    uint public coinPerMining = 1 * (10**decimals);
    uint public currentBlockNumber;

    uint public COINStore = 300 * (10**decimals); //Minimum coin/token hold in wallet to trigger mining
    
    modifier PoHAMRMiner() {
        assert(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] >= COINHold);
        require(balances[msg.sender] >= COINStore);
        _;
    }
    
    function miningCOIN() PoHAMRMiner public returns (bool) {
        require(balances[msg.sender] >= COINStore);
        
        if(balances[msg.sender] < COINStore) revert();
        if(transferIns[msg.sender].length <= 0) return false;
        
        uint coinMining = getCOINmining(msg.sender);
        if(coinMining <= 0) return false;
        
        assert(coinMining <= miningRewards);
        assert(miningRewards <= maxTotalSupply);
        
        totalSupply = totalSupply.add(coinMining);
        miningRewards = miningRewards.sub(coinMining);
        balances[msg.sender] = balances[msg.sender].add(coinMining);
        
        //Function to reset mining age to zero after receive mining coin
        //and user must hold for certain of time again before mining coin
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        
        emit CoinsMining(msg.sender, coinMining);
        return true;
    }

    function getCOINmining(address _address) internal view returns (uint) {
        require((now >= miningStartTime) && (miningStartTime > 0));
        uint _now = now; if(_miningAge <= 0) return 0;
        uint _miningAge = getMiningAge(_address, _now);
        uint miningEra = _miningAge;
        uint coinMining = coinPerMining.mul(miningEra);
        return coinMining;
    }
    
    function miningAge() internal view returns (uint myMiningAge) {
        myMiningAge = getMiningAge(msg.sender,now);
    }

    function getMiningAge(address _address, uint _now) internal view returns (uint _miningAge) {
        if(transferIns[_address].length <= 0) return 0;
        for (uint i = 0; i < transferIns[_address].length; i++){
            if(_now < uint(transferIns[_address][i].time).add(miningMinAge)) continue;
            uint blockAge = _now.sub(uint(transferIns[_address][i].time));
            if(blockAge >= 1 days && blockAge <= 10 days) blockAge = miningMinAge.mul(100).div(4);
            if(blockAge > 10 days && blockAge <= 20 days) blockAge = miningMinAge.mul(100).div(4);
            if(blockAge >= miningMaxAge) blockAge = miningMaxAge.mul(100).div(4);
            _miningAge = _miningAge.add(uint(transferIns[_address][i].amount) * blockAge.div(1 days));
        }
    }
    
    function miningStart() public onlyOwner {
        require(msg.sender == owner && mintingStartTime == 0);
        mintingStartTime = now;
    }
    
    function setMiningRewards(uint256 value) public onlyOwner {
        if(totalSupply == maxTotalSupply) revert();
        miningRewards = miningRewards.add(value);
    }
    
    function setCOINStore(uint _COINStore) public onlyOwner {
        COINStore = _COINStore;
    }
    
    function setCoinPerMining(uint _coinPerMining) public onlyOwner {
        coinPerMining = _coinPerMining;
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

    function() public payable {
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