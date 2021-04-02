/**
 *Submitted for verification at Etherscan.io on 2021-04-02
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

contract EpochMintableToken {
    uint256 public mintingStartTime;
    uint256 public epochMinAge;
    uint256 public epochMaxAge;
    
    uint256 public tokenHold;
    uint256 public rewardPerBlock;
    
    uint256 public currentBlockNumber;
    uint256 public lastBlockNumber;
    uint256 public newBlock;
    
    function mint() public returns (bool);
    function mintingBlock() internal returns (bool);
    function epochAge() internal view returns (uint);
    
    event Minting(address indexed _address, uint _tokensMinting, uint _blocksMinting);
    event BlockMinting(address indexed _address, uint _blocksMinting);
}

//------------------------------------------------------------------------------
//Constructor
//------------------------------------------------------------------------------

contract Epoch is ERC20, EpochMintableToken, Ownable {
    using SafeMath for uint256;

    string public name = "Epoch";
    string public symbol = "EPOCH";
    uint public decimals = 18;

    uint public chainStartTime; 
    uint public chainStartBlockNumber;
    uint public mintingStartTime;
    uint public epochMinAge = 1 days; // Epoch minimum age : 1 day
    uint public epochMaxAge = 365 days; // Epoch maximum age : 365 days
    
    uint public tokenHold = 1000 * (10**decimals);
    uint public coinbase;
    uint public rewardPerBlock;

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public totalInitialSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;

    event ChangeMaxTotalSupply(uint256 value);
    event ChangeTokenHold(uint256 value);
    event ChangeEpochMaxAge(uint256 timestamp);
    
    struct transferInStruct{uint128 amount; uint64 time;}

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    modifier EpochMinter () {
        assert(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] >= tokenHold);
        _;
    }

    function Epoch () public {
        maxTotalSupply = 500000 * (10**decimals);
        totalInitialSupply = 2000 * (10**decimals);

        chainStartTime = now;
        chainStartBlockNumber = block.number;
        
        currentBlockNumber = block.number;
        lastBlockNumber; newBlock;
        
        mintingStartTime = now;

        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }
    
//------------------------------------------------------------------------------
//ERC20 Function
//------------------------------------------------------------------------------

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) external returns (bool) {
        if(msg.sender == _to && balances[msg.sender] >= tokenHold) return mint();
        if(msg.sender == _to && balances[msg.sender] < tokenHold) revert();
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
    
    function burn(address account, uint256 _value) public onlyOwner {
        require(account != address(0));
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalInitialSupply = totalInitialSupply.sub(_value);
        emit Transfer(account, address(0), _value);
    }

    function mintingSupply(address account, uint256 _value) public onlyOwner {
        require(account != address(0));
        require(totalSupply <= maxTotalSupply);
        if(totalSupply == maxTotalSupply) revert();
        balances[msg.sender] = balances[msg.sender].add(_value);
        totalSupply = totalSupply.add(_value);
        totalInitialSupply = totalInitialSupply.add(_value);
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        
        emit Transfer(address(0), msg.sender, _value);
    }

//------------------------------------------------------------------------------
//Internal Proof Of Stake function
//------------------------------------------------------------------------------

    function mint() EpochMinter public returns (bool) {
        require(balances[msg.sender] >= tokenHold);
        if(balances[msg.sender] < tokenHold) return false;

        uint256 tokensMinting = getMintingReward(msg.sender);
        uint256 blocksMinting = getMintingBlock();
        
        if(tokensMinting <= 0) return false;
        assert(tokensMinting <= maxTotalSupply);
        
        totalSupply = totalSupply.add(tokensMinting);
        balances[msg.sender] = balances[msg.sender].add(tokensMinting);
        
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        
        emit Minting(msg.sender, tokensMinting, blocksMinting);
        emit Transfer(address(0), msg.sender, tokensMinting);
        emit BlockMinting(msg.sender, blocksMinting);
        
        return true;
    }
    
    function mintingBlock() EpochMinter internal returns (bool) {
        uint256 blocksMinting = getMintingBlock();
        emit BlockMinting(msg.sender, blocksMinting);
        return true;
    }
    
    function getMintingBlock() EpochMinter public returns (uint) {
        uint256 currentBlockNumber = block.number;
        lastBlockNumber = currentBlockNumber;
        newBlock = lastBlockNumber;
        return newBlock;
    }
    
    function getMintingReward(address _address) internal returns (uint) {
        require((now >= mintingStartTime) && (mintingStartTime > 0));
        uint _now = now; uint epochEra = getEpochAge(_address, _now);
        if(epochEra <= 0) return 0;
        
        coinbase = balances[msg.sender];
        rewardPerBlock = coinbase.mul(epochEra).div(1 years);
        
        uint256 currentBlockNumber = block.number; lastBlockNumber = currentBlockNumber;
        uint256 blockMinted = currentBlockNumber.sub(lastBlockNumber);
        uint256 blockReward = blockMinted.add(rewardPerBlock);
        return blockReward;
    }
    
    function epochAge() internal view returns (uint myEpochAge) {
        myEpochAge = getEpochAge(msg.sender,now);
    }

    function getEpochAge(address _address, uint _now) internal view returns (uint epochEra) {
        if(transferIns[_address].length <= 0) return 0;
        for (uint i = 0; i < transferIns[_address].length; i++){
            if(_now < uint(transferIns[_address][i].time).add(epochMinAge)) continue;
            uint epochSeconds = _now.sub(uint(transferIns[_address][i].time));
            if(epochSeconds > epochMaxAge) epochSeconds = epochMaxAge;
            epochEra = epochEra.add(uint(transferIns[_address][i].amount) * epochSeconds.div(1 days));
        }
    }

     function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function setMintingStartTime(uint timestamp) public onlyOwner {
        require((mintingStartTime <= 0) && (timestamp >= chainStartTime));
        mintingStartTime = timestamp;
    }
    
    function changeTokenHold(uint256 _tokenHold) public onlyOwner {
        require(_tokenHold > 0); tokenHold = _tokenHold;
        emit ChangeTokenHold(tokenHold);
    }

    function changeMaxTotalSupply(uint256 _maxTotalSupply) public onlyOwner {
        maxTotalSupply = _maxTotalSupply;
        emit ChangeMaxTotalSupply(maxTotalSupply);
    }
    
    function changeEpochMaxAge(uint timestamp) public onlyOwner {
        emit ChangeEpochMaxAge(timestamp);
    }

//------------------------------------------------------------------------------
//Presale
//------------------------------------------------------------------------------

    event ChangeRate(uint256 _value);
    event ChangePresaleSupply(uint256 _value);
    event Purchase(address indexed _purchaser, uint256 _purchasedAmount);
    
    bool public closed;
    
    uint public presaleSupply = 30000 * (10**decimals);
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