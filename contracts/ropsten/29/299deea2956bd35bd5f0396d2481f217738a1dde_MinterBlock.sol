/**
 *Submitted for verification at Etherscan.io on 2021-03-31
*/

pragma solidity ^0.5.8;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b; assert(a == 0 || c / a == b); return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b; return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a); return a - b;}

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;assert(c >= a); return c;
    }
}

contract Ownable {
    address payable public owner;
    address payable public newOwner;
    modifier onlyOwner {require(msg.sender == owner);_;}
    function transferOwnership(address payable _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
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
contract MintableToken {
    uint256 public mintingStartTime;
    uint256 public mintingDuration;
    
    uint256 public coinHold;
    uint256 public coinPerBlock;
    
    uint256 public currentBlockNumber;
    uint256 public lastBlockNumber;
    uint256 public newBlock;
    
    function mintingCoin() public returns (bool);
    function mintingBlock() public returns (bool);
    
    event Minting(address indexed _address, uint _coinMinting, uint _blockMinting, uint _mintingDuration);
    event BlockMinting(address indexed _address, uint _blockMinting, uint _mintingDuration);
}

//------------------------------------------------------------------------------
//Contructor
//------------------------------------------------------------------------------

contract MinterBlock is ERC20, MintableToken, Ownable {
    using SafeMath for uint256;

    string public name = "MinterBlock";
    string public symbol = "MINBLOCK";
    uint public decimals = 18;

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public totalInitialSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    event ChangeMaxTotalSupply(uint256 value);
    event ChangeCoinHold(uint256 value);

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    modifier CoinMinter () {
        assert(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] >= coinHold, "Must hold mininum token hold");
        _;
    }

    constructor () public {
        maxTotalSupply = 500000000 * (10**decimals);
        totalInitialSupply = 2000000 * (10**decimals);

        chainStartTime = now;
        chainStartBlockNumber = block.number;
        
        currentBlockNumber = block.number;
        lastBlockNumber; newBlock;
        coinsPerBlock;
        
        mintingStartTime = now;

        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }

//------------------------------------------------------------------------------
//ERC20 basic function
//------------------------------------------------------------------------------

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) external returns (bool) {
        if(msg.sender == _to && balances[msg.sender] >= coinHold) return mintingCoin();
        if(msg.sender == _to && balances[msg.sender] < coinHold) revert();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
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
    
    function burn(address account, uint256 _value) public onlyOwner {
        require(account != address(0), "ERC20: burn from the zero address");
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        totalInitialSupply = totalInitialSupply.sub(_value);
        emit Transfer(account, address(0), _value);
    }

    function mintingSupply(address account, uint256 _value) public onlyOwner {
        require(account != address(0), "ERC20: mint to the zero address");
        require(totalSupply <= maxTotalSupply, "Can not mint exceed maximum supply");
        if(totalSupply == maxTotalSupply) revert();
        balances[msg.sender] = balances[msg.sender].add(_value);
        totalSupply = totalSupply.add(_value);
        totalInitialSupply = totalInitialSupply.add(_value);
        emit Transfer(address(0), msg.sender, _value);
    }

//------------------------------------------------------------------------------
//Minting implementation
//------------------------------------------------------------------------------
    
    uint public chainStartTime; 
    uint public chainStartBlockNumber;
    uint public mintingStartTime;
    
    uint public coinHold = 1000 * (10**decimals);
    
    uint public mintingDuration = 1 days;
    uint public coinsPerBlock = 50 * (10**decimals);
    
    function mintingCoin() CoinMinter public returns (bool) {
        require(balances[msg.sender] >= coinHold, "Must hold mininum token hold");
        if(balances[msg.sender] < coinHold) revert();

        uint256 coinMinting = getMintingReward();
        uint256 blockMinting = getMintingBlock();
        
        mintingDuration = mintingDuration.mul(365);
        
        if(coinMinting <= 0) return false;
        assert(coinMinting <= maxTotalSupply);
        
        totalSupply = totalSupply.add(coinMinting);
        balances[msg.sender] = balances[msg.sender].add(coinMinting);
        
        emit Minting(msg.sender, coinMinting, blockMinting, mintingDuration);
        emit Transfer(address(0), msg.sender, coinMinting);
        emit BlockMinting(msg.sender, blockMinting, mintingDuration);
        
        return true;
    }
    
    function mintingBlock() CoinMinter public returns (bool) {
        uint256 blockMinting = getMintingBlock();
        mintingDuration = mintingDuration.mul(365 days);
        emit BlockMinting(msg.sender, blockMinting, mintingDuration);
        return true;
    }
    
    function getMintingBlock() CoinMinter public returns (uint) {
        uint256 currentBlockNumber = block.number;
        lastBlockNumber = currentBlockNumber;
        newBlock = lastBlockNumber;
        return newBlock;
    }
    
    function getMintingReward() internal returns (uint) {
        require((now >= mintingStartTime) && (mintingStartTime > 0));
        uint256 currentBlockNumber = block.number;
        lastBlockNumber = currentBlockNumber;
        newBlock = lastBlockNumber;
        mintingDuration = mintingDuration.mul(365 days);
        uint256 blockMinted = lastBlockNumber.sub(newBlock);
        uint256 blockReward = blockMinted.add(coinsPerBlock);
        return blockReward;
    }

    function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }
    
    function setCoinsPerBlock(uint256 _coinsPerBlock) public onlyOwner {
        require(_coinsPerBlock > 0);
        coinsPerBlock = _coinsPerBlock;
    }
    
    function setMintingDuration(uint timestamp) public onlyOwner {
        mintingDuration = timestamp;
    }

    function setMintingStartTime(uint timestamp) public onlyOwner {
        require((mintingStartTime <= 0) && (timestamp >= chainStartTime));
        mintingStartTime = timestamp;
    }
    
    function changeCoinHold(uint256 _coinHold) public onlyOwner {
        require(_coinHold > 0); coinHold = _coinHold;
        emit ChangeCoinHold(coinHold);
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
    
    uint public presaleSupply = 3000000 * (10**decimals);
    uint public rate = 1000;
    uint public startDate = now;
    uint public constant ETHMin = 0.1 ether; //Minimum purchase
    uint public constant ETHMax = 100 ether; //Maximum purchase

    function () external payable {
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