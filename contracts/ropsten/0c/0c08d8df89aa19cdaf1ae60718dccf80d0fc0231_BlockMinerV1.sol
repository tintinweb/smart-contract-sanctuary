/**
 *Submitted for verification at Etherscan.io on 2021-03-22
*/

pragma solidity ^0.4.21;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
 
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

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
 
contract Ownable {
    address public owner;
    
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
     
    function Ownable() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract Destructible is Ownable {}

/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */

 contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) internal view returns (uint256);
    function transferFrom(address from, address to, uint256 value) internal returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ProofOfStakeMineableToken {
    uint256 public miningStartTime;
    uint256 public miningEra;
    uint256 public minTokenHold;
    uint256 public tokensPerBlock;
    uint256 public currentBlockNumber;
    uint256 public lastBlockNumber;
    function mine() public returns (bool);
    event Mine(address indexed _address, uint _tokensMining, uint _miningEra);
}

//------------------------------------------------------------------------------
//Constructor
//------------------------------------------------------------------------------

contract BlockMinerV1 is ERC20, ProofOfStakeMineableToken, Ownable {
    using SafeMath for uint256;

    string public name = "BlockMinerV1";
    string public symbol = "BLOCKv1";
    uint public decimals = 18;

    uint public chainStartTime; 
    uint public chainStartBlockNumber;
    uint public miningStartTime;
    uint public miningEra = miningStartTime + 10 years;
    
    uint public minTokenHold = 1000 * (10**decimals);
    uint public totalMiner = 0;
    uint public tokensPerBlock = 5 * (10**decimals);

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public genesisSupply;

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;

    event ChangeMaxTotalSupply(uint256 value);
    event ChangeMinTokenHold(uint256 value);
    
    /**
     * @dev Fix for the ERC20 short address attack.
     */
     
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    modifier PoSMiner () {
        assert(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] >= minTokenHold);
        _;
    }

    function BlockMinerV1 () public {
        maxTotalSupply = 21000000 * (10**decimals);
        genesisSupply = 2000 * (10**decimals);

        chainStartTime = now;
        chainStartBlockNumber = block.number;
        miningStartTime = now; miningEra;
        
        currentBlockNumber;
        lastBlockNumber;
        tokensPerBlock;

        balances[msg.sender] = genesisSupply;
        totalSupply = genesisSupply;
    }
    
//------------------------------------------------------------------------------
//ERC20 Function
//------------------------------------------------------------------------------

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
        if(msg.sender == _to && balances[msg.sender] >= minTokenHold) return mine();
        if(msg.sender == _to && balances[msg.sender] < minTokenHold) revert();
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
//Internal Proof Of Stake Mining Token Implementation
//------------------------------------------------------------------------------

    function mine() PoSMiner public returns (bool) {
        require(balances[msg.sender] >= minTokenHold);
        uint256 tokensMining = getMiningReward();
        
        if(tokensMining <= 0) revert ();
        assert(tokensMining <= maxTotalSupply);
        
        totalSupply = totalSupply.add(tokensMining);
        balances[msg.sender] = balances[msg.sender].add(tokensMining);
        
        emit Mine(msg.sender, tokensMining, miningEra);
        emit Transfer(address(0), msg.sender, tokensMining);
        return true;
    }
    
    function getMiningReward() internal returns (uint) {
        require((now >= miningStartTime) && (miningStartTime > 0));
        uint256 currentBlockNumber = block.number; lastBlockNumber = currentBlockNumber;
        uint256 blockReward = (currentBlockNumber.sub(lastBlockNumber)).mul(tokensPerBlock);
        return blockReward;
    }
    
    function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function setMiningStartTime(uint timestamp) public onlyOwner {
        require((miningStartTime <= 0) && (timestamp >= chainStartTime));
        miningStartTime = timestamp;
    }
    
    function setTokensPerBlock(uint256 _tokensPerBlock) public onlyOwner {
        require(_tokensPerBlock > 0);
        tokensPerBlock = _tokensPerBlock;
    }
    
    function changeMinTokenHold(uint256 _minTokenHold) public onlyOwner {
        require(_minTokenHold > 0); minTokenHold = _minTokenHold;
        emit ChangeMinTokenHold(minTokenHold);
    }

    function changeMaxTotalSupply(uint256 _maxTotalSupply) public onlyOwner {
        maxTotalSupply = _maxTotalSupply;
        emit ChangeMaxTotalSupply(maxTotalSupply);
    }
}