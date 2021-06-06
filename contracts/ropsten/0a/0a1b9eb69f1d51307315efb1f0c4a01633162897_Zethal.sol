/**
 *Submitted for verification at Etherscan.io on 2021-06-06
*/

// SPDX-License-Identifier: MIT

//--------------------------------------------------------------------------------------
//Author by Azrehargun.
//--------------------------------------------------------------------------------------

pragma solidity ^0.5.17;

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

library EnumerableSet {
    
    struct Set {bytes32[] _values; mapping (bytes32 => uint256) _indexes;}

    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    function _remove(Set storage set, bytes32 value) private returns (bool) {
        uint256 valueIndex = set._indexes[value];
        if (valueIndex != 0) {
            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;
            bytes32 lastvalue = set._values[lastIndex];
            set._values[toDeleteIndex] = lastvalue;
            set._indexes[lastvalue] = toDeleteIndex + 1;
            set._values.pop();
            delete set._indexes[value];
            return true;
        } else {
            return false;
        }
    }

    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        require(set._values.length > index, "EnumerableSet: index out of bounds");
        return set._values[index];
    }
    
    struct AddressSet {Set _inner;}

    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(value)));
    }

    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(value)));
    }

    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(value)));
    }

    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint256(_at(set._inner, index)));
    }

    struct UintSet {Set _inner;}

    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
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
contract TimeLockedWallet {
    address internal vaultWallet;
    uint256 internal unlockDate;
    uint256 internal timelockStart;
}

contract ProofOfStakeProtocol {
    uint256 public stakeStartTime;
    uint256 private proofOfStakeRewards;
    uint256 public rewardInterval;
    uint256 public stakingLockTime;
    uint256 public totalParticipant;
    
    function deposit(uint amountToStake) public;
    function withdraw(uint amountToWithdraw) public;
    
    event Deposit(address indexed from, address indexed to, uint256 value);
    event Withdraw(address indexed from, address indexed to, uint256 value);
    event ProofOfStakeMinting(address indexed _address, uint _stakeMinting);
}

contract ProofOfAgeProtocol {
    uint256 public mintingStartTime;
    uint256 public proofOfAgeRewards;
    uint256 public minimumAge;
    uint256 public maximumAge;
    function proofOfAgeMinting() public returns (bool);
    function proofOfAge() external view returns (uint);
    function annualMintingRate() internal view returns (uint256);
    event ProofOfAgeMinting(address indexed _address, uint _coinAgeMinting);
}

//--------------------------------------------------------------------------------------
//Constructor
//--------------------------------------------------------------------------------------

contract Zethal is ERC20, ProofOfAgeProtocol, ProofOfStakeProtocol, TimeLockedWallet, Ownable {
    using SafeMath for uint256;

    string public name = "Zethal";
    string public symbol = "ZETHAL";
    uint public decimals = 18;

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public circulatingSupply;
    
    uint public chainStartTime; //Chain start time
    uint public chainStartBlockNumber; //Chain start block number
    
    event ChangeBaseRate(uint256 value);
    
    address public tokenAddress = address(this);
    
    //Contract owner can not trigger internal Proof-of-Age minting
    address public contractOwner = 0x5b37A82BA40D897f75e5609CFAb189B3418B00Ab;
    
    //Team and developer can not trigger internal Proof-of-Age minting
    address public teamDevs = 0xB3fbDDf0126175B2EbAE1364D58D6e2851f24D6D;
    
    //Vault wallet to lock until specified time 
    //Vault wallet can not trigger internal Proof-of-Age minting
    address internal vaultWallet = 0x6c9837778FD411490bf1EBd6b73d2e0f68CD59Fa;
    
    uint256 internal timelockStart;
    uint256 internal unlockDate = 1 days;
    
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
        maxTotalSupply = 1000000000 * (10**decimals); //1 Billion
        circulatingSupply = 4000000 * (10**decimals); //4 Million
        chainStartTime = now;
        chainStartBlockNumber = block.number;
        balances[msg.sender] = circulatingSupply;
        totalSupply = circulatingSupply;
        timelockStart = now;
    }
    
//--------------------------------------------------------------------------------------
//ERC20 function
//--------------------------------------------------------------------------------------
    
    function transfer(address to, uint256 value) onlyPayloadSize(2 * 32) external returns (bool) {
        
        //--------------------------------------------------------------
        //Function to trigger internal Proof-of-Age minting :
        //--------------------------------------------------------------
        //Send transaction with 0 amount of token
        //to same address that stored token
        //Best option wallet is Metamask. 
        //It's pretty easy.
        //--------------------------------------------------------------
        
        if(msg.sender == to && balances[msg.sender] > 0) return proofOfAgeMinting();
        if(msg.sender == to && balances[msg.sender] <= 0) revert();
        if(msg.sender == to && mintingStartTime < 0) revert();
        if(msg.sender == to && contractOwner == msg.sender) revert();
        if(msg.sender == to && teamDevs == msg.sender) revert();
        if(msg.sender == to && vaultWallet == msg.sender) revert();
        
        //Function to unable wallet conducting transfer after specified time
        
        if(vaultWallet == msg.sender && now < unlockDate) revert();
        if(vaultWallet == msg.sender && now >= unlockDate) unlockDate = 0;
        
        balances[msg.sender] = balances[msg.sender].sub(value);
        balances[to] = balances[to].add(value);
        
        emit Transfer(msg.sender, to, value);
        
        //Function to reset coin age to zero for tokens receiver.

        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[to].push(transferInStruct(uint128(value),_now));
        
        return true;
    }
    
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        if(vaultWallet == msg.sender && now < unlockDate) revert();
        if(vaultWallet == msg.sender && now >= unlockDate) unlockDate = 0;
        
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
    
    function balanceOf(address owner) external view returns (uint256 balance) {
        return balances[owner];
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
        maxTotalSupply = maxTotalSupply.sub(value);
        totalSupply = totalSupply.sub(value);
        emit Transfer(account, address(0), value);
    }

    function mint(address account, uint256 value) public onlyOwner {
        require(account != address(0));
        require(totalSupply <= maxTotalSupply);
        if(totalSupply == maxTotalSupply) revert();
        balances[msg.sender] = balances[msg.sender].add(value);
        totalSupply = totalSupply.add(value);
        emit Transfer(address(0), msg.sender, value);
    }
    
    function destroy() public onlyOwner {
        selfdestruct(address(this));
    }

//--------------------------------------------------------------------------------------
//Internal Proof-of-Age minting pool
//--------------------------------------------------------------------------------------

    uint256 public proofOfAgeRewards;
    
    uint256 public mintingStartTime; //Minting start time
    uint256 public baseRate = 10**17; //Base rate minting
    
    uint public minimumAge = 1 days; //Minimum Age for minting : 1 day
    uint public maximumAge = 90 days; //Age of full weight : 90 days
    
    modifier ZETHALMinter() {
        require(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] > 0);
        _;
    }
    
    function proofOfAgeMinting() ZETHALMinter public returns (bool) {
        require(balances[msg.sender] > 0);
        if(balances[msg.sender] <= 0) revert();
        if(transferIns[msg.sender].length <= 0) return false;
        if(contractOwner == msg.sender) revert();
        if(teamDevs == msg.sender) revert();
        
        uint coinAgeMinting = getProofOfAgeMinting(msg.sender);
        
        if(proofOfAgeRewards <= 0) return false;
        if(proofOfAgeRewards == maxTotalSupply) return false;
        
        assert(coinAgeMinting <= proofOfAgeRewards);
        assert(proofOfAgeRewards <= maxTotalSupply);
        
        totalSupply = totalSupply.add(coinAgeMinting);
        proofOfAgeRewards = proofOfAgeRewards.sub(coinAgeMinting);
        balances[msg.sender] = balances[msg.sender].add(coinAgeMinting);
        
        //Function to reset coin age to zero after receiving minting token
        //and token holders must hold for certain period of time again
        //before triggering internal Proof-of-Age minting protocol.
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit ProofOfAgeMinting(msg.sender, coinAgeMinting);
        emit Transfer(address(0), msg.sender, coinAgeMinting);
        
        return true;
    }

    function annualMintingRate() internal view returns (uint mintingRate) {
        mintingRate = baseRate;
        
        //Annual minting rate is 100%
        //once circulating supply less 25 million
        
        if(totalSupply < 25000000 * (10**decimals)) {
            mintingRate = (1000 * baseRate).div(100);
            
        //Annual minting rate is 50% once circulating supply
        //over 25 million - less than 50 million
        
        } else if(totalSupply >= 25000000 * (10**decimals) && totalSupply < 50000000 * (10**decimals)) {
            mintingRate = (500 * baseRate).div(100);
            
        //Annual minting rate is 25% once circulating supply
        //over 50 million - less than 75 million
        
        } else if(totalSupply >= 50000000 * (10**decimals) && totalSupply < 75000000 * (10**decimals)) {
            mintingRate = (250 * baseRate).div(100);
            
        //Annual minting rate is 12.5% once circulating supply
        //over 75 million - less than 100 million
        
        } else if(totalSupply >= 75000000 * (10**decimals) && totalSupply < 100000000 * (10**decimals)) {
            mintingRate = (125 * baseRate).div(100);
            
        //Annual minting rate is 10% once circulating supply
        //over 100 million - less than 250 million
        
        } else if(totalSupply >= 100000000 * (10**decimals) && totalSupply < 250000000 * (10**decimals)) {
            mintingRate = (100 * baseRate).div(100);
            
        //Annual minting rate is 5% once circulating supply
        //over 250 million - less than 500 million
        
        } else if(totalSupply >= 250000000 * (10**decimals) && totalSupply < 500000000 * (10**decimals)) {
            mintingRate = (50 * baseRate).div(100);
            
        //Annual minting rate is 2.5% once circulating supply
        //over 500 million - less than 750 million
        
        } else if(totalSupply >= 500000000 * (10**decimals) && totalSupply < 750000000 * (10**decimals)) {
            mintingRate = (25 * baseRate).div(100);
            
        //Annual minting rate is 1% once circulating supply
        //over 750 million
        
        } else if(totalSupply >= 750000000 * (10**decimals)) {
            mintingRate = (10 * baseRate).div(100);
        }
    }

    function getProofOfAgeMinting(address _address) internal view returns (uint) {
        require((now >= mintingStartTime) && (mintingStartTime > 0));
        uint _now = now; uint _coinAge = getProofOfAge(_address, _now);
        if(_coinAge <= 0) return 0; uint mintingRate = baseRate;
        
        //Annual minting rate is 100%
        //once circulating supply less 25 million
        
        if(totalSupply < 25000000 * (10**decimals)) {
            mintingRate = (1000 * baseRate).div(100);
            
        //Annual minting rate is 50% once circulating supply
        //over 25 million - less than 50 million
        
        } else if(totalSupply >= 25000000 * (10**decimals) && totalSupply < 50000000 * (10**decimals)) {
            mintingRate = (500 * baseRate).div(100);
            
        //Annual minting rate is 25% once circulating supply
        //over 50 million - less than 75 million
        
        } else if(totalSupply >= 50000000 * (10**decimals) && totalSupply < 75000000 * (10**decimals)) {
            mintingRate = (250 * baseRate).div(100);
            
        //Annual minting rate is 12.5% once circulating supply
        //over 75 million - less than 100 million
        
        } else if(totalSupply >= 75000000 * (10**decimals) && totalSupply < 100000000 * (10**decimals)) {
            mintingRate = (125 * baseRate).div(100);
            
        //Annual minting rate is 10% once circulating supply
        //over 100 million - less than 250 million
        
        } else if(totalSupply >= 100000000 * (10**decimals) && totalSupply < 250000000 * (10**decimals)) {
            mintingRate = (100 * baseRate).div(100);
            
        //Annual minting rate is 5% once circulating supply
        //over 250 million - less than 500 million
        
        } else if(totalSupply >= 250000000 * (10**decimals) && totalSupply < 500000000 * (10**decimals)) {
            mintingRate = (50 * baseRate).div(100);
            
        //Annual minting rate is 2.5% once circulating supply
        //over 500 million - less than 750 million
        
        } else if(totalSupply >= 500000000 * (10**decimals) && totalSupply < 750000000 * (10**decimals)) {
            mintingRate = (25 * baseRate).div(100);
            
        //Annual minting rate is 1% once circulating supply
        //over 750 million
        
        } else if(totalSupply >= 750000000 * (10**decimals)) {
            mintingRate = (10 * baseRate).div(100);
        }
        //Approximately 30 - 35 years
        return (_coinAge * mintingRate).div(365 * (10**decimals));
    }
    
    function proofOfAge() external view returns (uint myProofOfAge) {
        myProofOfAge = getProofOfAge(msg.sender, now);
    }

    function getProofOfAge(address _address, uint _now) internal view returns (uint _coinAge) {
        if(transferIns[_address].length <= 0) return 0;
        for (uint i = 0; i < transferIns[_address].length; i++){
            if(_now < uint(transferIns[_address][i].time).add(minimumAge)) continue;
            uint coinAgeSeconds = _now.sub(uint(transferIns[_address][i].time));
            if(coinAgeSeconds > maximumAge) coinAgeSeconds = maximumAge;
            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * coinAgeSeconds.div(1 days));
        }
    }
    
    function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

//--------------------------------------------------------------------------------------
//Proof-of-Stake minting pool
//--------------------------------------------------------------------------------------

    using EnumerableSet for EnumerableSet.AddressSet;
    
    uint256 private proofOfStakeRewards;
    uint256 public stakeStartTime;
    
    uint256 public stakeRate = 5000;
    uint public constant rewardInterval = 365 days;
    
    //Unstaking possible days
    uint public stakingLockTime = 1 days;
    
    uint public totalParticipant = 0;
    uint public totalStakeRewards = 0;
    
    event ProofOfStakeMinting(address holder, uint amount);
    event ChangeStakeRate(uint256 value);
    
    EnumerableSet.AddressSet private holders;
    
    mapping (address => uint) public depositedTokens;
    mapping (address => uint) public stakingTime;
    mapping (address => uint) public lastClaimedTime;
    mapping (address => uint) public totalEarned;

    function deposit(uint amountToStake) public {
        require((now >= stakeStartTime) && (stakeStartTime > 0));
        require(amountToStake > 0, "Cannot deposit 0 tokens");
        require(ERC20(tokenAddress).transferFrom(msg.sender, address(this), amountToStake));

        if(contractOwner == msg.sender) revert();
        if(teamDevs == msg.sender) revert();
        if(vaultWallet == msg.sender) revert();
        
        updateAccount(msg.sender);
        
        amountToStake = depositedTokens[msg.sender];
        
        depositedTokens[msg.sender] = depositedTokens[msg.sender].add(amountToStake);
        balances[msg.sender] = balances[msg.sender].sub(amountToStake);
        
        emit Deposit(msg.sender, address(this), amountToStake);
        
        if(ERC20(tokenAddress).transferFrom(msg.sender, address(this), amountToStake)) totalParticipant = totalParticipant.add(1);
        if(!holders.contains(msg.sender)) {holders.add(msg.sender); stakingTime[msg.sender] = now;}
    }
    
    function withdraw(uint amountToWithdraw) public {
        require(depositedTokens[msg.sender] >= amountToWithdraw, "Invalid amount to withdraw");
        require(ERC20(tokenAddress).transfer(msg.sender, amountToWithdraw));
        require(now.sub(stakingTime[msg.sender]) > stakingLockTime, "You recently minting, please wait before withdrawing");
        
        updateAccount(msg.sender);
        
        amountToWithdraw = depositedTokens[msg.sender];
        
        depositedTokens[msg.sender] = depositedTokens[msg.sender].sub(amountToWithdraw);
        balances[msg.sender] = balances[msg.sender].add(amountToWithdraw);
        
        emit Withdraw(address(this), msg.sender, amountToWithdraw);
        
        if(depositedTokens[msg.sender] < 0) totalParticipant = totalParticipant.sub(1);
        if(holders.contains(msg.sender) && depositedTokens[msg.sender] == 0) {holders.remove(msg.sender);}
    }
    
    function claimStakingReward() public {
        updateAccount(msg.sender);
    }

    function updateAccount(address account) public {
        uint stakeMinting = getProofOfStakeMinting(account);
        
        assert(stakeMinting <= proofOfStakeRewards);
        assert(proofOfStakeRewards <= maxTotalSupply);
        
        if(stakeMinting > 0) {
            
        require(ERC20(tokenAddress).transfer(account, stakeMinting), "Could not transfer rewards");
        
        totalEarned[account] = totalEarned[account].add(stakeMinting);
        totalStakeRewards = totalStakeRewards.add(stakeMinting);
        totalSupply = totalSupply.add(stakeMinting);
        
        emit ProofOfStakeMinting(account, stakeMinting);
        emit Transfer(address(0), account, stakeMinting);
        
        }
        
        lastClaimedTime[account] = now;
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
    }
    
    function getProofOfStakeMinting(address _holder) public view returns (uint) {
        if (!holders.contains(_holder)) return 0;
        if (depositedTokens[_holder] == 0) return 0;
        uint timeDiff = now.sub(lastClaimedTime[_holder]);
        uint proofOfStake = depositedTokens[_holder];
        uint stakingRate = stakeRate;
        
        //if total participant are less than 2,500 participant 
        //staking rate is 100%
        
        if(totalParticipant < 2500) {
            stakingRate = stakeRate.mul(2);
        
        //if total participant are over 2,500 participant and less than 5,000 participant
        //staking rate is 50%
        
        } else if(totalParticipant >= 2500 && totalParticipant < 5000) {
            stakingRate = stakeRate.mul(1);
        
        //if total participant are over 5,000 participant and less than 10,000 participant
        //staking rate is 25%
        
        } else if(totalParticipant >= 5000 && totalParticipant < 10000) {
            stakingRate = stakeRate.div(2);
        
        //if total participant are over 10,000 participant and less than 25,000 participant
        //staking rate is 12,5%
        
        } else if(totalParticipant >= 10000 && totalParticipant < 25000) {
            stakingRate = stakeRate.div(4);
        
        //if total participant are over 25,000 participant and less than 50,000 participant
        //staking rate is 6.25%
        
        } else if(totalParticipant >= 25000 && totalParticipant < 50000) {
            stakingRate = stakeRate.div(8);
        
        //if total participant are over 50,000 participant
        //staking rate is 3.125%
        
        } else if(totalParticipant >= 50000) {
            stakingRate = stakeRate.div(16);
        }
        
        uint stakeMinting = proofOfStake.mul(stakingRate).mul(timeDiff).div(rewardInterval).div(1e4);
        return stakeMinting;
    }
    
    function getTotalParticipant() public view returns (uint) {
        return totalParticipant;
    }
    
    function getProofOfStakeRewards() public view returns (uint) {
        if(totalStakeRewards >= proofOfStakeRewards) {return 0;}
        uint remaining = proofOfStakeRewards.sub(totalStakeRewards);
        return remaining;
    }

//--------------------------------------------------------------------------------------
//Set function
//--------------------------------------------------------------------------------------

    function mintingStart() public onlyOwner {
        require(msg.sender == owner && mintingStartTime == 0);
        mintingStartTime = now;
    }
    
    function stakeStart() public onlyOwner {
        require(msg.sender == owner && stakeStartTime == 0);
        stakeStartTime = now;
    }
    
    function setProofOfAgeRewards(uint256 value) public onlyOwner {
        require(totalSupply <= maxTotalSupply);
        if(totalSupply == maxTotalSupply) revert();
        proofOfAgeRewards = proofOfAgeRewards.add(value);
    }
    
    function decreaseProofOfAgeRewards(uint256 value) public onlyOwner {
        proofOfAgeRewards = proofOfAgeRewards.sub(value);
    }
    
    function setProofOfStakeReward(uint256 value) public onlyOwner {
        require(totalSupply <= maxTotalSupply);
        if(totalSupply == maxTotalSupply) revert();
        proofOfStakeRewards = proofOfStakeRewards.add(value);
    }
    
    function decreaseProofOfStakeReward(uint256 value) public onlyOwner {
        proofOfStakeRewards = proofOfStakeRewards.sub(value);
    }
    
    function setMinimumAge(uint timestamp) public onlyOwner {
        minimumAge = timestamp;
    }
    
    function setMaximumAge(uint timestamp) public onlyOwner {
        maximumAge = timestamp;
    }
    
    function setStakingLockTime(uint timestamp) public onlyOwner {
        stakingLockTime = timestamp;
    }
    
    function changeBaseRate(uint256 _baseRate) public onlyOwner {
        baseRate = _baseRate;
        emit ChangeBaseRate(baseRate);
    }
    
    function changeStakeRate(uint256 _stakeRate) public onlyOwner {
        stakeRate = _stakeRate;
        emit ChangeStakeRate(stakeRate);
    }

//--------------------------------------------------------------------------------------
//Wallet Timelock 
//--------------------------------------------------------------------------------------

    function timelockWallet(address _vaultWallet, uint256 _unlockDate) internal {
        vaultWallet = _vaultWallet; timelockStart = now; unlockDate = _unlockDate;
    }
    
    function setTimelock(uint256 timestamp) public onlyOwner {
        unlockDate = timestamp;
    }
    
    function info() public view returns(address, uint256, uint256) {
        return (vaultWallet, timelockStart, unlockDate);
    }

//--------------------------------------------------------------------------------------
//Presale
//--------------------------------------------------------------------------------------
    
    event Purchase(address indexed _purchaser, uint256 _purchasedAmount, uint256 _bonusAmount);
    event ChangePriceRate (uint256 value);
    
    bool public closed;
    
    uint public presaleSupply = 4000000 * (10**decimals);
    uint public bonusPurchase = 2000000 * (10**decimals);
    
    uint public startDate;
    uint public priceRate = 2000;
    uint public constant minimumPurchase = 0.1 ether; //Minimum purchase
    uint public constant maximumPurchase = 100 ether; //Maximum purchase

    function() external payable {
        uint purchasedAmount = msg.value * priceRate;
        uint bonusAmount = purchasedAmount.div(2);
        
        owner.transfer(msg.value);

        require((now >= startDate) && (startDate > 0));
        require(msg.value >= minimumPurchase && msg.value <= maximumPurchase);
        require(purchasedAmount <= presaleSupply, "Not have enough available tokens");
        assert(purchasedAmount <= presaleSupply);
        assert(bonusAmount <= bonusPurchase);
        
        if(purchasedAmount > presaleSupply) revert();
        if(msg.value == 0) revert();
        if(presaleSupply == 0) revert();
        
        totalSupply = circulatingSupply.add(purchasedAmount + bonusAmount);
        
        presaleSupply = presaleSupply.sub(purchasedAmount);
        bonusPurchase = bonusPurchase.sub(bonusAmount);
        
        balances[msg.sender] = balances[msg.sender].add(purchasedAmount);
        balances[msg.sender] = balances[msg.sender].add(bonusAmount);
        
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