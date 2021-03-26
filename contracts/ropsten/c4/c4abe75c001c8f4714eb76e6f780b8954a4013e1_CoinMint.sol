/**
 *Submitted for verification at Etherscan.io on 2021-03-26
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

contract PoSHMintableToken {
    uint256 public mintingStartTime;
    uint256 public mintingDuration;
    uint256 public tokenHold;
    uint256 public tokensPerBlock;
    
    uint256 public currentBlockNumber;
    uint256 public lastBlockNumber;
    uint256 public newBlock;
    
    function mint() public returns (bool);
    function mintingBlock() public returns (bool);
    
    event Minting(address indexed _address, uint _tokensMinting, uint _blocksMinting, uint _mintingDuration);
    event BlockMinting(address indexed _address, uint _blocksMinting, uint _mintingDuration);
}

//------------------------------------------------------------------------------
//Constructor
//------------------------------------------------------------------------------

contract CoinMint is ERC20, PoSHMintableToken, Ownable {
    using SafeMath for uint256;

    string public name = "CoinMint";
    string public symbol = "COIN";
    uint public decimals = 18;

    uint public chainStartTime; 
    uint public chainStartBlockNumber;
    uint public mintingStartTime;
    uint public mintingDuration;
    
    uint public tokenHold = 1000 * (10**decimals);
    uint public tokensPerBlock = 50 * (10**decimals);

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public genesisSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    event ChangeMaxTotalSupply(uint256 value);
    event ChangeTokenHold(uint256 value);

    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    modifier PoSHMinter () {
        assert(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] >= tokenHold);
        _;
    }

    function CoinMint () public {
        maxTotalSupply = 500000 * (10**decimals);
        genesisSupply = 2000 * (10**decimals);

        chainStartTime = now;
        chainStartBlockNumber = block.number;
        
        currentBlockNumber = block.number;
        lastBlockNumber; newBlock;
        tokensPerBlock;
        
        mintingStartTime = now;
        mintingDuration = 30 days;

        balances[msg.sender] = genesisSupply;
        totalSupply = genesisSupply;
    }
    
//------------------------------------------------------------------------------
//ERC20 Function
//------------------------------------------------------------------------------

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
        if(msg.sender == _to && balances[msg.sender] >= tokenHold) return mint();
        if(msg.sender == _to && balances[msg.sender] < tokenHold) revert();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
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

//------------------------------------------------------------------------------
//Internal Proof Of Stake function
//------------------------------------------------------------------------------

    function mint() PoSHMinter public returns (bool) {
        require(balances[msg.sender] >= tokenHold);
        if(balances[msg.sender] < tokenHold) return false;

        uint256 tokensMinting = getMintingReward();
        uint256 blocksMinting = getMintingBlock();
        mintingDuration;
        
        if(tokensMinting <= 0) return false;
        assert(tokensMinting <= maxTotalSupply);
        
        totalSupply = totalSupply.add(tokensMinting);
        balances[msg.sender] = balances[msg.sender].add(tokensMinting);
        
        emit Minting(msg.sender, tokensMinting, blocksMinting, mintingDuration);
        emit Transfer(address(0), msg.sender, tokensMinting);
        emit BlockMinting(msg.sender, blocksMinting, mintingDuration);
        
        return true;
    }
    
    function mintingBlock() PoSHMinter public returns (bool) {
        uint256 blocksMinting = getMintingBlock();
        emit BlockMinting(msg.sender, blocksMinting, mintingDuration);
        return true;
    }
    
    function getMintingBlock() PoSHMinter public returns (uint) {
        uint256 currentBlockNumber = block.number;
        lastBlockNumber = currentBlockNumber;
        newBlock = lastBlockNumber.mul(mintingDuration);
        return newBlock;
    }
    
    function getMintingReward() internal returns (uint) {
        require((now >= mintingStartTime) && (mintingStartTime > 0));
        uint256 currentBlockNumber = block.number; lastBlockNumber = currentBlockNumber;
        uint256 blockMinted = currentBlockNumber.sub(lastBlockNumber);
        uint256 blockReward = blockMinted.add(tokensPerBlock);
        return blockReward;
    }

     function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function setMintingStartTime(uint timestamp) public onlyOwner {
        require((mintingStartTime <= 0) && (timestamp >= chainStartTime));
        mintingStartTime = timestamp;
    }
    
    function setMintingDuration(uint timestamp) public onlyOwner {
        mintingDuration = timestamp;
    }
    
    function setTokensPerBlock(uint256 _tokensPerBlock) public onlyOwner {
        require(_tokensPerBlock > 0);
        tokensPerBlock = _tokensPerBlock;
    }
    
    function changeTokenHold(uint256 _tokenHold) public onlyOwner {
        require(_tokenHold > 0); tokenHold = _tokenHold;
        emit ChangeTokenHold(tokenHold);
    }

    function changeMaxTotalSupply(uint256 _maxTotalSupply) public onlyOwner {
        maxTotalSupply = _maxTotalSupply;
        emit ChangeMaxTotalSupply(maxTotalSupply);
    }
}