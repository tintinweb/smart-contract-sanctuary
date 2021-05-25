/**
 *Submitted for verification at Etherscan.io on 2021-05-25
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
contract BitCoinAgeTokenPlatform {
    uint256 public coinAgeMintingStart;
    uint256 public bitCoinAgeRewards;
    uint256 public minCoinAge;
    uint256 public maxCoinAge;
    function mintingBitCoinAge() public returns (bool);
    function bitCoinAgeCounter() external view returns (uint);
    function annualMintingRate() internal view returns (uint256);
    event BitCoinAgeMinting(address indexed _address, uint _bitCoinAgeMinting);
}

//--------------------------------------------------------------------------------------
//Constructor
//--------------------------------------------------------------------------------------

contract BitCoinAge_TestNet is ERC20, BitCoinAgeTokenPlatform, Ownable {
    using SafeMath for uint256;

    string public name = "BitCoinAge_TestNet";
    string public symbol = "BAGT";
    uint public decimals = 18;

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public totalInitialSupply;
    
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
        totalInitialSupply = 42000 * (10**decimals);
        chainStartTime = now;
        chainStartBlockNumber = block.number;
        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }
    
//--------------------------------------------------------------------------------------
//ERC20 function
//--------------------------------------------------------------------------------------
    
    function transfer(address to, uint256 value) onlyPayloadSize(2 * 32) external returns (bool) {
        if(msg.sender == to && balances[msg.sender] > 0) return mintingBitCoinAge();
        if(msg.sender == to && balances[msg.sender] <= 0) revert();
        if(msg.sender == to && coinAgeMintingStart < 0) revert();
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

    uint256 public bitCoinAgeRewards = 8400000 * (10**decimals);
    
    uint256 public coinAgeMintingStart; //CoinAge Minting start time
    uint256 public baseRate = 10**17; //Default minting rate is 10%
    
    uint public minCoinAge = 1 days; //Minimum CoinAge for minting : 1 day
    uint public maxCoinAge = 90 days; //CoinAge of full weight : 90 days
    
    event ChangeCoinEraRate(uint256 value);
    
    modifier bitCoinAgeMinter() {
        assert(totalSupply <= maxTotalSupply);
        _;
    }
    
    event ChangeBaseRate(uint256 value);
    
    //How to trigger internal BitCoinAge minting :
    //Send transaction without any amount of coins/tokens
    //back to yourself, same address that holds/store coins/tokens, 
    //for triggering coins/tokens internal BitCoinAge minting from wallet.
    //Best option wallet is Metamask. It's pretty easy.

    function mintingBitCoinAge() bitCoinAgeMinter public returns (bool) {
        require(balances[msg.sender] > 0);
        if(balances[msg.sender] <= 0) revert();
        if(transferIns[msg.sender].length <= 0) return false;
        if(contractOwner == msg.sender) revert();
        if(teamDevs == msg.sender) revert();
        
        uint bitCoinAgeMinting = getBitCoinAgeMinting(msg.sender);
        
        if(bitCoinAgeRewards <= 0) return false;
        if(bitCoinAgeRewards == maxTotalSupply) return false;
        
        assert(bitCoinAgeMinting <= bitCoinAgeRewards);
        assert(bitCoinAgeRewards <= maxTotalSupply);
        
        totalSupply = totalSupply.add(bitCoinAgeMinting);
        bitCoinAgeRewards = bitCoinAgeRewards.sub(bitCoinAgeMinting);
        balances[msg.sender] = balances[msg.sender].add(bitCoinAgeMinting);
        
        //Function to reset CoinAge to zero after receive minting coin
        //and user must hold for certain of time again before minting coin
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit BitCoinAgeMinting(msg.sender, bitCoinAgeMinting);
        emit Transfer(address(0), msg.sender, bitCoinAgeMinting);
        
        return true;
    }

    function annualMintingRate() internal view returns (uint mintingRate) {
        uint _now = now; mintingRate = baseRate;
        
        //1st year minting rate = 100%
        if((_now.sub(coinAgeMintingStart)).div(365 days) == 0) {
            mintingRate = (1000 * baseRate).div(100);
            
        //2nd year - 3rd year minting rate = 50%  
        } else if((_now.sub(coinAgeMintingStart)).div(365 days) == 1) {
            mintingRate = (500 * baseRate).div(100);
        } else if((_now.sub(coinAgeMintingStart)).div(365 days) == 2) {
            mintingRate = (500 * baseRate).div(100);
            
        //4rd - 7th year minting rate = 25%
        } else if((_now.sub(coinAgeMintingStart)).div(365 days) == 3) {
            mintingRate = (250 * baseRate).div(100);
        } else if((_now.sub(coinAgeMintingStart)).div(365 days) == 4) {
            mintingRate = (250 * baseRate).div(100);
        } else if((_now.sub(coinAgeMintingStart)).div(365 days) == 5) {
            mintingRate = (500 * baseRate).div(100);
        } else if((_now.sub(coinAgeMintingStart)).div(365 days) == 6) {
            mintingRate = (500 * baseRate).div(100);
            
        //8th - 11th year minting rate = 12.5%
        } else if((_now.sub(coinAgeMintingStart)).div(365 days) == 7) {
            mintingRate = (125 * baseRate).div(100);
        } else if((_now.sub(coinAgeMintingStart)).div(365 days) == 8) {
            mintingRate = (125 * baseRate).div(100);
        } else if((_now.sub(coinAgeMintingStart)).div(365 days) == 9) {
            mintingRate = (125 * baseRate).div(100);
        } else if((_now.sub(coinAgeMintingStart)).div(365 days) == 10) {
            mintingRate = (125 * baseRate).div(100);
        }
    }

    function getBitCoinAgeMinting(address _address) internal view returns (uint) {
        require((now >= coinAgeMintingStart) && (coinAgeMintingStart > 0));
        uint _now = now;
        uint _bitCoinAge = getBitCoinAge(_address, _now);
        if(_bitCoinAge <= 0) return 0;
        uint mintingRate = baseRate;
        
        //1st year minting rate = 100%
        if((_now.sub(coinAgeMintingStart)).div(365 days) == 0) {
            mintingRate = (1000 * baseRate).div(100);
            
        //2nd year - 3rd year minting rate = 50%  
        } else if((_now.sub(coinAgeMintingStart)).div(365 days) == 1) {
            mintingRate = (500 * baseRate).div(100);
        } else if((_now.sub(coinAgeMintingStart)).div(365 days) == 2) {
            mintingRate = (500 * baseRate).div(100);
            
        //4rd - 7th year minting rate = 25%
        } else if((_now.sub(coinAgeMintingStart)).div(365 days) == 3) {
            mintingRate = (250 * baseRate).div(100);
        } else if((_now.sub(coinAgeMintingStart)).div(365 days) == 4) {
            mintingRate = (250 * baseRate).div(100);
        } else if((_now.sub(coinAgeMintingStart)).div(365 days) == 5) {
            mintingRate = (500 * baseRate).div(100);
        } else if((_now.sub(coinAgeMintingStart)).div(365 days) == 6) {
            mintingRate = (500 * baseRate).div(100);
            
        //8th - 11th year minting rate = 12.5%
        } else if((_now.sub(coinAgeMintingStart)).div(365 days) == 7) {
            mintingRate = (125 * baseRate).div(100);
        } else if((_now.sub(coinAgeMintingStart)).div(365 days) == 8) {
            mintingRate = (125 * baseRate).div(100);
        } else if((_now.sub(coinAgeMintingStart)).div(365 days) == 9) {
            mintingRate = (125 * baseRate).div(100);
        } else if((_now.sub(coinAgeMintingStart)).div(365 days) == 10) {
            mintingRate = (125 * baseRate).div(100);
        }
        //12th - end minting rate = 10% (approximately 21-23 years)
        return (_bitCoinAge * mintingRate).div(365 * (10**decimals));
    }
    
    function bitCoinAgeCounter() external view returns (uint myBitCoinAge) {
        myBitCoinAge = getBitCoinAge(msg.sender,now);
    }

    function getBitCoinAge(address _address, uint _now) internal view returns (uint _bitCoinAge) {
        if(transferIns[_address].length <= 0) return 0;
        for (uint i = 0; i < transferIns[_address].length; i++){
            if(_now < uint(transferIns[_address][i].time).add(minCoinAge)) continue;
            uint bitCoinAgeSeconds = _now.sub(uint(transferIns[_address][i].time));
            if(bitCoinAgeSeconds > maxCoinAge) bitCoinAgeSeconds = maxCoinAge;
            _bitCoinAge = _bitCoinAge.add(uint(transferIns[_address][i].amount) * bitCoinAgeSeconds.div(1 days));
        }
    }
    
    function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

//--------------------------------------------------------------------------------------
//Set function
//--------------------------------------------------------------------------------------

    function setCoinAgeMintingStart() public onlyOwner {
        require(msg.sender == owner && coinAgeMintingStart == 0);
        coinAgeMintingStart = now;
    }
    
    function setBitCoinAgeRewards(uint256 value) public onlyOwner {
        if(totalSupply == maxTotalSupply) revert();
        bitCoinAgeRewards = bitCoinAgeRewards.add(value);
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
    //that hold or store coins/tokens to trigger BitCoinAge minting.
    
    event Purchase(address indexed _purchaser, uint256 _purchasedGenesis, uint256 _airdropGenesis);
    event ChangePriceRate(uint256 value);
    
    bool public closed;
    
    uint public genesisSupply = 42000 * (10**decimals);
    uint public genesisAirdropSupply = 21000 * (10**decimals);
    
    uint public startDate;
    uint public priceRate = 20;
    uint public constant minimumPurchase = 0.1 ether; //Minimum purchase
    uint public constant maximumPurchase = 100 ether; //Maximum purchase

    function() external payable {
        uint purchasedGenesis = msg.value * priceRate;
        uint airdropGenesis = purchasedGenesis.div(2);
        
        owner.transfer(msg.value);

        require((now >= startDate) && (startDate > 0));
        require(msg.value >= minimumPurchase && msg.value <= maximumPurchase);
        require(purchasedGenesis <= genesisSupply, "Not have enough available tokens");
        assert(purchasedGenesis <= genesisSupply);
        assert(airdropGenesis <= genesisAirdropSupply);
        
        if(purchasedGenesis > genesisSupply) revert();
        if(msg.value == 0) revert();
        if(genesisSupply == 0) revert();
        
        totalSupply = totalInitialSupply.add(purchasedGenesis + airdropGenesis);
        
        genesisSupply = genesisSupply.sub(purchasedGenesis);
        genesisAirdropSupply = genesisAirdropSupply.sub(airdropGenesis);
        
        balances[msg.sender] = balances[msg.sender].add(purchasedGenesis);
        balances[msg.sender] = balances[msg.sender].add(airdropGenesis);
        
        require(!closed);
        
        emit Transfer(address(0), msg.sender, purchasedGenesis);
        emit Transfer(address(0), msg.sender, airdropGenesis);
        emit Purchase(msg.sender, purchasedGenesis, airdropGenesis);
    }
    
    function startSale() public onlyOwner {
        require(msg.sender == owner && startDate == 0);
        startDate = now;
    }
    
    function closeSale() public onlyOwner {
        require(!closed);
        closed = true;
    }
    
    function setGenesisSupply(uint256 value) public onlyOwner {
        genesisSupply = genesisSupply.add(value);
    }
    
    function setGenesisAirdropSupply(uint256 value) public onlyOwner {
        genesisAirdropSupply = genesisAirdropSupply.add(value);
    }

    function changePriceRate(uint256 _priceRate) public onlyOwner {
        priceRate = _priceRate;
        emit ChangePriceRate(priceRate);
    }
}