/**
 *Submitted for verification at Etherscan.io on 2021-04-05
*/

pragma solidity ^0.4.21;

//---------------------------------------------------------------------------------
//MintCoin contract
//Hodl, Ages, Stake, Earn, Accumulate, Repeat
//
//A flexible PoHAS (Proof-of-Hold-Age-and-Stake) digital economic
//asset and commodity built on Ethereum Blockchain network.
//
//Inbuilt with pure internal PoHAS protocol
//with inflation protection and lightning-fast
//speeds transaction through Ethereum Blockchain
//for everyone digitally, anonimously, privately,
//globally, peer to peer borderless and permissionless.
//
//Name     : MintCoin
//Symbols  : MTC
//Decimals : 18
//Type     : ERC20 and PoHAS (Proof-of-Hold-Age-and-Stake)
//
//Maximum supply on year 1 - 2     :  10,000,000
//Genesis supply                   :   1,000,000
//Coin left to mint on year 1 - 2  :   9,000,000
//
//Maximum Supply on year 3 - 6     :  20,000,000
//Maximum Supply on year 7 - 10    :  30,000,000
//Maximum Supply on year 11 - end  :  50,000,000
//
//Minting Rate:
//1st - 2nd year Annual Minting Rate  : 50%
//3rd - 6th year Annual Minting Rate  : 25%
//7th - 10th year Annual Minting Rate : 12.5%
//11th year - End Annual Minting Rate : 10%
//
//Minting Age:
//Minimum Minting Age to stake to earn reward :  1 day
//Maximum Minting Age to stake to earn reward : 90 days
//
//Which means, user must hold MintCoin  for certain period of times
//before stake to earn reward, minimum holding is 1 day (by default)
//and maximum holding is 90 days (by default).
//
//After stake and earn reward, Minting Age will reset to zero again
//and user must hold again for certain period of times to earn reward.
//
//Herza Nugraha
//------------------------------------------------------------------------------

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
contract PoHASMintableStandard {
    uint256 public mintingStartTime;
    uint256 public mintingMinAge;
    uint256 public mintingMaxAge;
    uint256 public coinHold;
    
    function mintingCoin() public returns (bool);
    function mintingAge() internal view returns (uint);
    function annualMintingRate() internal view returns (uint256);
    
    event Mint(address indexed _address, uint _coinMinting);
}

//------------------------------------------------------------------------------
//Constructor
//------------------------------------------------------------------------------

contract MinterAge2 is ERC20, PoHASMintableStandard, Ownable {
    using SafeMath for uint256;

    string public name = "MinterAge2";
    string public symbol = "MINAGE2";
    uint public decimals = 18;

    uint public chainStartTime; // Chain start time
    uint public chainStartBlockNumber; // Chain start block number
    uint public mintingStartTime; // Minting start time 
    
    uint public mintingMinAge = 1 days; // Minimum age for minting age: 1 day
    uint public mintingMaxAge = 90 days; // Minting age of full weight: 90 days
    uint public defaultMintingRate = 10**17; // Default minting rate is 10%
    uint public coinHold = 1000 * (10**decimals); // Minimum coin hold in wallet to trigger mint

    uint public totalSupply;
    uint public maxTotalSupply = 50000000 * (10**decimals);
    uint public totalInitialSupply;

    struct transferInStruct{uint128 amount; uint64 time;}

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;

    event ChangeMaxTotalSupply(uint256 value);
    event ChangeDefaultMintingRate(uint256 value);
    event ChangeCoinHold(uint value);

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    modifier PoHASMinter () {
        assert(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] >= coinHold);
        _;
    }

    function MinterAge2 () public {
        maxTotalSupply;
        totalInitialSupply = 400000 * (10**decimals);

        chainStartTime = now;
        chainStartBlockNumber = block.number;
        mintingStartTime = now;

        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }
    
//------------------------------------------------------------------------------
//ERC20 Function
//------------------------------------------------------------------------------

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) external returns (bool) {
        
        //Function to trigger mint by sending transaction without any amount
        //to own wallet address that hold minimun coin.
        
        if(msg.sender == _to && balances[msg.sender] >= coinHold) return mintingCoin();
        if(msg.sender == _to && balances[msg.sender] < coinHold) revert();

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
    
    function destroy() public onlyOwner {
        selfdestruct(address(this));
    }
    
    function totalSupply() external view returns (uint256) {
        return totalSupply;
    }

//------------------------------------------------------------------------------
//Internal Proof Of Stake and Hold function implementation
//------------------------------------------------------------------------------

    function mintingCoin() PoHASMinter public returns (bool) {
        require(balances[msg.sender] >= coinHold);
        if(balances[msg.sender] < coinHold) revert();
        
        if(transferIns[msg.sender].length <= 0) return false;

        uint coinMinting = getCoinMinting(msg.sender);
        if(coinMinting <= 0) return false;
        assert(coinMinting <= maxTotalSupply);

        totalSupply = totalSupply.add(coinMinting);
        balances[msg.sender] = balances[msg.sender].add(coinMinting);
        
        //Function to reset minting age to zero after receive minting coin
        //and user must hold for certain of time again before minting coin
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        emit Mint(msg.sender, coinMinting);
        return true;
    }

    function annualMintingRate() internal view returns (uint mintingRate) {
        uint _now = now;
        mintingRate = defaultMintingRate;
        if((_now.sub(mintingStartTime)).div(1 years) == 0) {
            mintingRate = (500 * defaultMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 1) {
            mintingRate = (500 * defaultMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 2) {
            mintingRate = (250 * defaultMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 3) {
            mintingRate = (250 * defaultMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 4) {
            mintingRate = (250 * defaultMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 5) {
            mintingRate = (250 * defaultMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 6) {
            mintingRate = (125 * defaultMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 7) {
            mintingRate = (125 * defaultMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 8) {
            mintingRate = (125 * defaultMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 9) {
            mintingRate = (125 * defaultMintingRate).div(100);
        }
    }

    function getCoinMinting(address _address) internal view returns (uint) {
        require((now >= mintingStartTime) && (mintingStartTime > 0));
        uint _now = now; uint _mintingAge = getMintingAge(_address, _now);
        if(_mintingAge <= 0) return 0;
        uint mintingRate = defaultMintingRate;
        if((_now.sub(mintingStartTime)).div(1 years) == 0) {
            mintingRate = (500 * defaultMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 1) {
            mintingRate = (500 * defaultMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 2) {
            mintingRate = (250 * defaultMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 3) {
            mintingRate = (250 * defaultMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 4) {
            mintingRate = (250 * defaultMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 5) {
            mintingRate = (250 * defaultMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 6) {
            mintingRate = (125 * defaultMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 7) {
            mintingRate = (125 * defaultMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 8) {
            mintingRate = (125 * defaultMintingRate).div(100);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 9) {
            mintingRate = (125 * defaultMintingRate).div(100);
        }
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

    function setMintingStartTime(uint timestamp) public onlyOwner {
        require((mintingStartTime <= 0) && (timestamp >= chainStartTime));
        mintingStartTime = timestamp;
    }

    function changeDefaultMintingRate(uint256 _defaultMintingRate) public onlyOwner {
        defaultMintingRate = _defaultMintingRate;
        emit ChangeDefaultMintingRate(defaultMintingRate);
    }

    function changeCoinHold(uint256 _coinHold) public onlyOwner {
        coinHold = _coinHold;
        emit ChangeCoinHold(coinHold);
    }

    function changeMaxTotalSupply(uint256 _maxTotalSupply) public onlyOwner {
        maxTotalSupply = _maxTotalSupply;
        emit ChangeMaxTotalSupply(maxTotalSupply);
    }
    
    function maximumTotalSupply(uint256 _maxTotalSupply) public {
        maxTotalSupply = _maxTotalSupply; uint _now = now;
        if((_now.sub(mintingStartTime)).div(1 years) == 0) {
            maxTotalSupply = 10000000 * (10**decimals);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 1) {
            maxTotalSupply = 10000000 * (10**decimals);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 2) {
            maxTotalSupply = 20000000 * (10**decimals);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 3) {
            maxTotalSupply = 20000000 * (10**decimals);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 4) {
            maxTotalSupply = 20000000 * (10**decimals);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 5) {
            maxTotalSupply = 20000000 * (10**decimals);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 6) {
            maxTotalSupply = 30000000 * (10**decimals);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 7) {
            maxTotalSupply = 30000000 * (10**decimals);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 8) {
            maxTotalSupply = 30000000 * (10**decimals);
        } else if((_now.sub(mintingStartTime)).div(1 years) == 9) {
            maxTotalSupply = 30000000 * (10**decimals);
        }
    }

//------------------------------------------------------------------------------
//Presale
//------------------------------------------------------------------------------

    //Set other wallet address that especially to purchase MintCoin on presale.
    //After purchasing, send MintCoin to wallet address to hold MintCoin
    //until presale is close.
    //
    //After presale is close, minting start time has been set and liquidity has been added
    //Send transaction without any amount of MintCoin to own wallet address
    //that hold MintCoin to trigger mint.

    event ChangeRate(uint256 _value);
    event ChangePresaleSupply(uint256 _value);
    event Purchase(address indexed _purchaser, uint256 _purchasedAmount);
    
    bool public closed;
    
    uint public presaleSupply = 600000 * (10**decimals);
    uint public rate = 1000;
    uint public startDate = now;
    uint public constant ETHMin = 0.1 ether; //Minimum purchase
    uint public constant ETHMax = 100 ether; //Maximum purchase

    function () public payable {
        uint purchasedAmount = msg.value * rate;
        owner.transfer(msg.value);
        
        totalSupply = totalInitialSupply.add(purchasedAmount);
        presaleSupply = presaleSupply.sub(purchasedAmount);

        balances[msg.sender] = balances[msg.sender].add(purchasedAmount);
        
        transferIns[msg.sender]; transferIns[msg.sender].length;
        
        require((now >= startDate) && (startDate > 0));
        require(!closed);
        require(msg.value >= ETHMin && msg.value <= ETHMax);
        assert(purchasedAmount <= presaleSupply);
        if (purchasedAmount > presaleSupply) {revert();}
        
        emit Transfer(address(0), msg.sender, purchasedAmount);
        emit Purchase(msg.sender, purchasedAmount);
    }
    
    function closeSale() public onlyOwner {
        require(!closed); closed = true;
    }
    
    function changePresaleSupply(uint256 _presaleSupply) public onlyOwner {
        presaleSupply = _presaleSupply;
        emit ChangePresaleSupply(presaleSupply);
    }
}