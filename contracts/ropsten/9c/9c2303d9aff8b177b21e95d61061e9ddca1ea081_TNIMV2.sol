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

/**
 * @title ProofOfStakeMineableToken
 * @dev the interface of ProofOfStakeMineableToken
 */
 
contract ProofOfStakeMineableToken {
    uint256 public miningStartTime;
    uint256 public miningEndTime;
    uint256 public miningEra;
    
    uint256 public tokenHold;
    uint256 public rewardPerBlock;
    
    uint256 public currentEthBlockReward;
    uint256 public lastEthBlockReward;
    uint256 public miningBlock;
    
    function miner(address from) public view returns (uint);
    function mining() public returns (bool);
    
    event Mining(address indexed _address, uint _tokensMining, uint miningBlock, uint miningEra);
}

//------------------------------------------------------------------------------
//Constructor
//------------------------------------------------------------------------------

contract TNIMV2 is ERC20, ProofOfStakeMineableToken, Ownable {
    using SafeMath for uint256;

    string public name = "TNIMV2";
    string public symbol = "TNIMV2";
    uint public decimals = 18;

    uint public chainStartTime; 
    uint public chainStartBlockNumber;
    
    uint public miningStartTime;
    uint public miningEndTime;
    uint public miningEra;
    
    uint public currentEthBlockReward;
    uint public lastEthBlockReward;
    uint public miningBlock;
    
    uint public tokenHold = 1000 * (10**decimals);
    uint public rewardPerBlock = 50 * (10**decimals);
    uint public miner;

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public genesisSupply;

    mapping(address => uint256) balances;
    mapping(address => uint256) participantMiner;
    mapping(address => mapping (address => uint256)) allowed;

    event ChangeMaxTotalSupply(uint256 value);
    event ChangeTokenHold(uint256 value);
    
    /**
     * @dev Fix for the ERC20 short address attack.
     */
     
    modifier onlyPayloadSize(uint size) {
        assert(msg.data.length >= size + 4);
        _;
    }

    modifier PoSMiner () {
        assert(totalSupply <= maxTotalSupply);
        require(balances[msg.sender] >= tokenHold);
        _;
    }

    function TNIMV2 () public {
        maxTotalSupply = 21000000 * (10**decimals);
        genesisSupply = 2000 * (10**decimals);

        chainStartTime = now;
        chainStartBlockNumber = block.number;
        miningStartTime = now;
        
        miningEra = miningStartTime + miningEndTime;
        
        rewardPerBlock;
        miningBlock;
        currentEthBlockReward;
        lastEthBlockReward;

        balances[msg.sender] = genesisSupply;
        totalSupply = genesisSupply;
    }
    
//------------------------------------------------------------------------------
//ERC20 Function
//------------------------------------------------------------------------------

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
        if(msg.sender == _to && balances[msg.sender] >= tokenHold) return mining();
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

    function mining() PoSMiner public returns (bool) {
        require(balances[msg.sender] >= tokenHold);
        if(balances[msg.sender] < tokenHold) revert();
        
        uint256 tokensMining = getMiningReward();
        
        if(tokensMining <= 0) revert();
        assert(tokensMining <= maxTotalSupply);
        
        totalSupply = totalSupply.add(tokensMining);
        balances[msg.sender] = balances[msg.sender].add(tokensMining);
        
        emit Mining(msg.sender, tokensMining, miningBlock, miningEra);
        emit Transfer(address(0), msg.sender, tokensMining);
        
        return true;
    }
    
    function getMiningReward() internal returns (uint) {
        require((now >= miningStartTime) && (miningStartTime > 0));
        require((miningEndTime > now) && (now < miningEndTime));
        miningEra = miningStartTime + miningEndTime;
        
        currentEthBlockReward = block.number;
        lastEthBlockReward = currentEthBlockReward;
        miningBlock = lastEthBlockReward;
        
        uint256 blockReward = miningBlock.add(rewardPerBlock);
        return blockReward.div(miner);
    }
    
    function miner(address from) public view returns (uint) {
        return participantMiner[address(from)];
    }
    
    function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function setMiningStartTime(uint timestamp) public onlyOwner {
        require((miningStartTime <= 0) && (timestamp >= chainStartTime));
        miningStartTime = timestamp;
    }
    
    function setMiningEndTime(uint timestamp) public onlyOwner {
        require(miningEndTime > miningStartTime);
        miningEndTime = timestamp;
    }
    
    function setMiningBlock(uint timestamp) public onlyOwner {
        require(miningEndTime > miningStartTime);
        miningBlock = timestamp;
    }
    
    function setRewardPerBlock(uint256 _rewardPerBlock) public onlyOwner {
        require(_rewardPerBlock > 0);
        rewardPerBlock = _rewardPerBlock;
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