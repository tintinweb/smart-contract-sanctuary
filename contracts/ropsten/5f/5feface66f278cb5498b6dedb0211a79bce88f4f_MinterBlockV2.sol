/**
 *Submitted for verification at Etherscan.io on 2021-04-01
*/

pragma solidity ^0.4.21;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    function Ownable() public {owner = msg.sender;}
    modifier onlyOwner() {require(msg.sender == owner);_;}
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract Destructible is Ownable {}
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) internal view returns (uint256);
    function transferFrom(address from, address to, uint256 value) internal returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Mintable {
    uint256 public mintingStartTime;
    uint256 public mintingAllowed;
    uint256 public mintingMinAge;
    uint256 public mintingMaxAge;
    
    uint256 public coinsHold;
    uint256 public coinsPerBlock;
    
    uint256 public currentBlockNumber;
    uint256 public lastBlockNumber;
    uint256 public newBlock;
    
    function mintingCoin() public returns (bool);
    function epochCounter() internal view returns (uint);
    
    event MintingCoin(address indexed _address, uint _coinsMinting);
}

//------------------------------------------------------------------------------
//Constructor
//------------------------------------------------------------------------------

contract MinterBlockV2 is ERC20, Mintable, Ownable {
    using SafeMath for uint256;

    string public name = "MinterBlockV2";
    string public symbol = "MINBLOK2";
    uint public decimals = 18;

    uint public chainStartTime; 
    uint public chainStartBlockNumber;
    uint public mintingStartTime;
    
    uint public mintingMinAge = 1 days;
    uint public mintingMaxAge = 120 days;
    
    uint public mintingAllowed; // The timestamp after which minting may occur
    uint32 public constant minimumMintingTime = 1 days; // Minimum time between mints
    
    uint public coinsHold = 1000 * (10**decimals);
    uint public coinsPerBlock = 5 * (10**decimals);

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public totalInitialSupply;
    
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;

    event ChangeMaxTotalSupply(uint256 value);
    event ChangeCoinsHold(uint256 value);
    
    struct transferInStruct{uint64 time;}

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    modifier CoinMinter () {
        assert(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] >= coinsHold);
        _;
    }

    function MinterBlockV2 () public {
        maxTotalSupply = 500000 * (10**decimals);
        totalInitialSupply = 2000 * (10**decimals);

        chainStartTime = now;
        chainStartBlockNumber = block.number;
        
        currentBlockNumber = block.number;
        lastBlockNumber; newBlock;
        coinsPerBlock;
        
        mintingStartTime = now;
        mintingAllowed;

        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }
    
//------------------------------------------------------------------------------
//ERC20 Function
//------------------------------------------------------------------------------

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
        if(msg.sender == _to && balances[msg.sender] >= coinsHold) return mintingCoin();
        if(msg.sender == _to && balances[msg.sender] < coinsHold) revert();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint64(_now)));
        
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) internal returns (bool) {
        require(_to != address(0));
        uint256 _allowance = allowed[_from][msg.sender];
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        emit Transfer(_from, _to, _value);
        
        if(transferIns[msg.sender].length > 0)
        delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[_from].push(transferInStruct(uint64(_now)));
        transferIns[_to].push(transferInStruct(uint64(_now)));
        
        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) internal view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
    
    function destroy() public onlyOwner {
        selfdestruct(address(this));
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

//------------------------------------------------------------------------------
//Internal Proof Of Stake function
//------------------------------------------------------------------------------

    function mintingCoin() CoinMinter public returns (bool) {
        require(balances[msg.sender] >= coinsHold);
        if(balances[msg.sender] < coinsHold) revert();
        require(block.timestamp >= mintingAllowed);
        
        mintingAllowed = SafeMath.add(block.timestamp, minimumMintingTime);

        uint256 coinsMinting = getMintingCoin(msg.sender);
        
        if(coinsMinting <= 0) return false;
        assert(coinsMinting <= maxTotalSupply);
        
        totalSupply = totalSupply.add(coinsMinting);
        balances[msg.sender] = balances[msg.sender].add(coinsMinting);
        
        emit MintingCoin(msg.sender, coinsMinting);
        emit Transfer(address(0), msg.sender, coinsMinting);
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint64(now)));
        
        return true;
    }
    
    function getMintingCoin(address _address) internal returns (uint) {
        require((now >= mintingStartTime) && (mintingStartTime > 0));
        uint _now = now;
        uint epochEra = getEpochEra(_address, _now);
        if(epochEra <= 0) return 0;
        
        uint256 currentBlockNumber = block.number; lastBlockNumber = currentBlockNumber;
        uint256 blockMinted = currentBlockNumber.sub(lastBlockNumber);
        uint256 coinbase = coinsPerBlock * epochEra;
        uint256 blockReward = blockMinted.add(coinbase);
        
        return blockReward;
    }
    
    function epochCounter() internal view returns (uint myEpochCounter) {
        myEpochCounter = getEpochEra(msg.sender,now);
    }

    function getEpochEra(address _address, uint _now) internal view returns (uint epochEra) {
        if(transferIns[_address].length <= 0) return 0;
        for (uint i = 0; i < transferIns[_address].length; i++){
            if(_now < uint(transferIns[_address][i].time).add(mintingMinAge)) continue;
            uint epochSeconds = _now.sub(uint(transferIns[_address][i].time));
            if(epochSeconds > mintingMaxAge) epochSeconds = mintingMaxAge;
            epochEra = epochEra.add(uint(transferIns[_address][i].time) * epochSeconds.div(1 days));
        }
    }

    function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function setMintingStartTime(uint timestamp) public onlyOwner {
        require((mintingStartTime <= 0) && (timestamp >= chainStartTime));
        mintingStartTime = timestamp;
    }
    
    function setMintingAllowed(uint timestamp) public onlyOwner {
        mintingAllowed = timestamp;
    }
    
    function setCoinsPerBlock(uint256 _coinsPerBlock) public onlyOwner {
        require(_coinsPerBlock > 0);
        coinsPerBlock = _coinsPerBlock;
    }
    
    function changeCoinsHold(uint256 _coinsHold) public onlyOwner {
        require(_coinsHold > 0); coinsHold = _coinsHold;
        emit ChangeCoinsHold(coinsHold);
    }

    function changeMaxTotalSupply(uint256 _maxTotalSupply) public onlyOwner {
        maxTotalSupply = _maxTotalSupply;
        emit ChangeMaxTotalSupply(maxTotalSupply);
    }

//------------------------------------------------------------------------------
//Presale
//------------------------------------------------------------------------------

    event ChangeRate(uint256 _value);
    event ChangePresaleSupply(uint256 _value);
    event Purchase(address indexed _purchaser, uint256 _purchasedAmount);
    
    bool public closed;
    
    uint public presaleSupply = 3000 * (10**decimals);
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
        
        require((now >= startDate) && (startDate > 0));
        require(!closed);
        require(msg.value >= ETHMin && msg.value <= ETHMax);
        assert(purchasedAmount <= presaleSupply);
        if (purchasedAmount > presaleSupply) {revert();}
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint64(now)));
        
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