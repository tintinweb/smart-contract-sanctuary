/**
 *Submitted for verification at Etherscan.io on 2021-06-05
*/

// SPDX-License-Identifier: MIT

//----------------------------------------------------------------------
//Author by Azrehargun 2021
//Hard fork from PoS Token
//----------------------------------------------------------------------

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
    
contract ProofOfAgeProtocol {
    uint256 public mintingStartTime;
    uint256 public proofOfAgeRewards;
    uint256 public minimumAge;
    uint256 public maximumAge;
    function proofOfAgeMinting() public returns (bool);
    function proofOfAge() external view returns (uint);
    function annualMintingRate() internal view returns (uint256);
    event ProofOfAgeMinting(address indexed _address, uint _tokensMinting);
}

//--------------------------------------------------------------------------------------
//Constructor
//--------------------------------------------------------------------------------------

contract Zeth is ERC20, ProofOfAgeProtocol, TimeLockedWallet, Ownable {
    using SafeMath for uint256;

    string public name = "Zeth";
    string public symbol = "ZETH";
    uint public decimals = 18;

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public circulatingSupply;
    
    uint public chainStartTime; //Chain start time
    uint public chainStartBlockNumber; //Chain start block number
    
    event ChangeBaseRate(uint256 value);
    
    //Contract owner can not trigger internal Proof-of-Age minting
    address public contractOwner = 0x5b37A82BA40D897f75e5609CFAb189B3418B00Ab;
    
    //Team and developer can not trigger internal Proof-of-Age minting
    address public teamDevs = 0xB3fbDDf0126175B2EbAE1364D58D6e2851f24D6D;
    
    //Vault wallet to lock until specified time 
    //Vault wallet can not trigger internal Proof-of-Age minting
    address internal vaultWallet = 0x75603A40aB2cD54B890C29ffbb3aCE8BF62e92a5;
    
    uint256 internal unlockDate;
    uint256 internal timelockStart;
    
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
        timelockStart = now;
        chainStartBlockNumber = block.number;
        balances[msg.sender] = circulatingSupply;
        totalSupply = circulatingSupply;
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
        
        //Function to unable wallet conducting transfer after specified time.
        
        if((vaultWallet == msg.sender && now.sub(timelockStart) < unlockDate)) revert();
        
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
    
    function transferFrom(address from, address to, uint256 value) onlyPayloadSize(3 * 32) onlyOwner external returns (bool) {
        require(to != address(0));
        
        //Function to unable wallet conducting transfer after specified time.
        
        if((vaultWallet == msg.sender && now.sub(timelockStart) < unlockDate)) revert();
        
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
//Internal Proof of Age pool
//--------------------------------------------------------------------------------------

    uint256 public proofOfAgeRewards = 550000000 * (10**decimals); //550 Million
    
    uint256 public mintingStartTime; //Minting start time
    uint256 public baseRate = 10**17; //Base rate minting
    
    uint public minimumAge = 1 days; //Minimum Age for minting : 1 day
    uint public maximumAge = 90 days; //Age of full weight : 90 days
    
    modifier ProofOfAgeMinter() {
        assert(totalSupply <= maxTotalSupply);
        _;
    }
    
    function proofOfAgeMinting() ProofOfAgeMinter public returns (bool) {
        require(balances[msg.sender] > 0);
        if(balances[msg.sender] <= 0) revert();
        if(transferIns[msg.sender].length <= 0) return false;
        if(contractOwner == msg.sender) revert();
        if(teamDevs == msg.sender) revert();
        
        uint tokensMinting = getProofOfAgeMinting(msg.sender);
        
        if(proofOfAgeRewards <= 0) return false;
        if(proofOfAgeRewards == maxTotalSupply) return false;
        
        assert(tokensMinting <= proofOfAgeRewards);
        assert(proofOfAgeRewards <= maxTotalSupply);
        
        totalSupply = totalSupply.add(tokensMinting);
        proofOfAgeRewards = proofOfAgeRewards.sub(tokensMinting);
        balances[msg.sender] = balances[msg.sender].add(tokensMinting);
        
        //Function to reset coin age to zero after receiving minting token
        //and token holders must hold for certain period of time again
        //before triggering internal Proof-of-Age minting protocol.
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit ProofOfAgeMinting(msg.sender, tokensMinting);
        emit Transfer(address(0), msg.sender, tokensMinting);
        
        return true;
    }

    function annualMintingRate() internal view returns (uint mintingRate) {
        mintingRate = baseRate;
        
        //Annual minting rate is 100%
        //once circulating supply less 25 million
        
        if(totalSupply < 25000000 * (10**decimals)) {
            mintingRate = (1000 * baseRate).div(100);
            
        //Annual minting rate is 50%
        //once circulating supply over 25 million
        
        } else if(totalSupply >= 25000000 * (10**decimals)) {
            mintingRate = (500 * baseRate).div(100);
            
        //Annual minting rate is 25%
        //once circulating supply over 50 million
        
        } else if(totalSupply >= 50000000 * (10**decimals)) {
            mintingRate = (250 * baseRate).div(100);
            
        //Annual minting rate is 12.5%
        //once circulating supply over 75 million
        
        } else if(totalSupply >= 75000000 * (10**decimals)) {
            mintingRate = (125 * baseRate).div(100);
            
        //Annual minting rate is 10%
        //once circulating supply over 100 million
        
        } else if(totalSupply >= 100000000 * (10**decimals)) {
            mintingRate = (100 * baseRate).div(100);
            
        //Annual minting rate is 5%
        //once circulating supply over 250 million
        
        } else if(totalSupply >= 250000000 * (10**decimals)) {
            mintingRate = (50 * baseRate).div(100);
            
        //Annual minting rate is 2.5%
        //once circulating supply over 500 million
        
        } else if(totalSupply >= 500000000 * (10**decimals)) {
            mintingRate = (25 * baseRate).div(100);
            
        //Annual minting rate is 1%
        //once circulating supply over 750 million
        
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
            
        //Annual minting rate is 50%
        //once circulating supply over 25 million
        
        } else if(totalSupply >= 25000000 * (10**decimals)) {
            mintingRate = (500 * baseRate).div(100);
            
        //Annual minting rate is 25%
        //once circulating supply over 50 million
        
        } else if(totalSupply >= 50000000 * (10**decimals)) {
            mintingRate = (250 * baseRate).div(100);
            
        //Annual minting rate is 12.5%
        //once circulating supply over 75 million
        
        } else if(totalSupply >= 75000000 * (10**decimals)) {
            mintingRate = (125 * baseRate).div(100);
            
        //Annual minting rate is 10%
        //once circulating supply over 100 million
        
        } else if(totalSupply >= 100000000 * (10**decimals)) {
            mintingRate = (100 * baseRate).div(100);
            
        //Annual minting rate is 5%
        //once circulating supply over 250 million
        
        } else if(totalSupply >= 250000000 * (10**decimals)) {
            mintingRate = (50 * baseRate).div(100);
            
        //Annual minting rate is 2.5%
        //once circulating supply over 500 million
        
        } else if(totalSupply >= 500000000 * (10**decimals)) {
            mintingRate = (25 * baseRate).div(100);
            
        //Annual minting rate is 1%
        //once circulating supply over 750 million
        
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
//Set function
//--------------------------------------------------------------------------------------

    function mintingStart() public onlyOwner {
        require(msg.sender == owner && mintingStartTime == 0);
        mintingStartTime = now;
    }
    
    function setProofOfAgeRewards(uint256 value) public onlyOwner {
        if(totalSupply == maxTotalSupply) revert();
        proofOfAgeRewards = proofOfAgeRewards.add(value);
    }
    
    function setMinimumAge(uint timestamp) public onlyOwner {
        minimumAge = timestamp;
    }
    
    function setMaximumAge(uint timestamp) public onlyOwner {
        maximumAge = timestamp;
    }
    
    function changeBaseRate(uint256 _baseRate) public onlyOwner {
        baseRate = _baseRate;
        emit ChangeBaseRate(baseRate);
    }

//--------------------------------------------------------------------------------------
//Wallet Timelock 
//--------------------------------------------------------------------------------------

    //Function to unable wallet conducting transfer any tokens after specified time
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