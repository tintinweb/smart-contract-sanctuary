/**
 *Submitted for verification at Etherscan.io on 2021-03-04
*/

pragma solidity ^0.4.19;

library SafeMath {
    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal constant returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal constant returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract Ownable {
    address public owner;
    function Ownable() {owner = msg.sender;}
    modifier onlyOwner() {require(msg.sender == owner);_;}
    function transferOwnership(address newOwner) onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }
}

contract Destructible is Ownable {}

contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) constant returns (uint256);
    function transfer(address to, uint256 value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) constant returns (uint256);
    function transferFrom(address from, address to, uint256 value) returns (bool);
    function approve(address spender, uint256 value) returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract PoSTokenStandard {
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    function mint() returns (bool);
    function coinAge() constant returns (uint256);
    function annualInterest() constant returns (uint256);
    event Mint(address indexed _address, uint _reward);
}

contract StakeIV is ERC20, PoSTokenStandard, Ownable {
    using SafeMath for uint256;

    string public name = "StakeIV";
    string public symbol = "STAKIV";
    uint public decimals = 18;

    uint public chainStartTime; // chain start time
    uint public chainStartBlockNumber; // chain start block number
    uint public stakeStartTime; // stake start time
    uint public stakeMinAge = 1 days; // minimum age for coin age: 1 Days
    uint public stakeMaxAge = 10 days; // stake age of full weight: 10 Days
    uint public maxMintProofOfStake = 10**17; // Default 10% annual interest (0.1)
    uint public rewardInterval = 365;

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public totalInitialSupply;
    uint public presaleSupply = 30**24; //3,000,000.000000000000000000

    struct transferInStruct{uint128 amount; uint64 time;}

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;

    event Burn(address indexed burner, uint256 value);
    event ChangeMaxTotalSupply(uint256 value);
    event ChangeStakeMaxAge(uint256 value);
    
//------------------------------------------------------------------------------
//Contructor
//------------------------------------------------------------------------------

    modifier onlyPayloadSize(uint size) {require(msg.data.length >= size + 4);_;}
    modifier canPoSMint() {require(totalSupply < maxTotalSupply);_;}

    function StakeIV() {
        maxTotalSupply = 50**25; // Maximum Total Supply is 50,000,000.000000000000000000
        totalInitialSupply = 22**25; // Total Initial Supply is 22,000.000.000000000000000000
        // 1,500,000 for Add Liqudity
        // 500,000 for Team and Development
        // 20,000,000 for LPs External Staking Rewards
        stakeStartTime = now + 5 days;
        chainStartTime = now;
        chainStartBlockNumber = block.number;

        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }

//------------------------------------------------------------------------------
//ERC20 Function
//------------------------------------------------------------------------------

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) returns (bool) {
        if(msg.sender == _to) return mint();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) returns (bool) {
        require(_to != address(0));

        var _allowance = allowed[_from][msg.sender];

        // Check is not needed because sub(_allowance, _value) will already throw if this condition is not met
        // require (_value <= _allowance);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
        if(transferIns[_from].length > 0) delete transferIns[_from];
        uint64 _now = uint64(now);
        transferIns[_from].push(transferInStruct(uint128(balances[_from]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }

    function approve(address _spender, uint256 _value) returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

//------------------------------------------------------------------------------
//Proof Of Stake Implementation
//------------------------------------------------------------------------------

    //There are 2 ways to activate internal Ethic minting.
    //Send any amount of Ethic tokens back to yourself (same Ethereum address that holds Ethic token).
    //Interact with the contract with any Ethereum wallet that is capable of calling smart contract functions.
    //Best option are My Ether Wallet, Metamask Wallet and Saturn Wallet
    //See tutorial : https://www.youtube.com/watch?v=yynLE412ehI&feature=emb_logo
    //See tutorial : https://medium.com/@btcmasterflex/postoken-the-worlds-first-pos-smart-contract-token-287932d7c668
    //It is the very same mechanism but with different earning percentage mechanism

    function mint() canPoSMint returns (bool) {
        if(balances[msg.sender] <= 0) return false;
        if(transferIns[msg.sender].length <= 0) return false;

        uint reward = getProofOfStakeReward(msg.sender);
        if(reward <= 0) return false;

        totalSupply = totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));

        Mint(msg.sender, reward);
        return true;
    }

    function getBlockNumber() returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function coinAge() constant returns (uint myCoinAge) {
        myCoinAge = getCoinAge(msg.sender,now);
    }

    function annualInterest() constant returns(uint interest) {
        uint _now = now;
        interest = maxMintProofOfStake;
        if((_now.sub(stakeStartTime)).div(rewardInterval) == 0) {
            interest = (1000 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(rewardInterval) == 1) {
            interest = (1000 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(rewardInterval) == 2) {
            interest = (1000 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(rewardInterval) == 3) {
            interest = (750 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(rewardInterval) == 4) {
            interest = (750 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(rewardInterval) == 5) {
            interest = (750 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(rewardInterval) == 6) {
            interest = (500 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(rewardInterval) == 7) {
            interest = (500 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(rewardInterval) == 8) {
            interest = (500 * maxMintProofOfStake).div(100);
        }
    }

    function getProofOfStakeReward(address _address) internal returns (uint) {
        require( (now >= stakeStartTime) && (stakeStartTime > 0) );

        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge <= 0) return 0;

        uint interest = maxMintProofOfStake;

        if((_now.sub(stakeStartTime)).div(rewardInterval) == 0) {
            // 1st year effective annual interest rate is 100%
            interest = (1000 * maxMintProofOfStake).div(100);
            // example : user have 1000 tokens
            // 1000 token x 10 of coinAge = 10,000
            // Interest = (1000 x 0.1) / 100 = 1 (100%)
            // Reward = 10,000 x 1 / 365 = 27.397
            // 1,000 token + 27.397 = 1,027.397 token
        } else if((_now.sub(stakeStartTime)).div(rewardInterval) == 1) {
            // 2nd year effective annual interest rate is 100%
            interest = (1000 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(rewardInterval) == 2) {
            // 3rd year effective annual interest rate is 100%
            interest = (1000 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(rewardInterval) == 3) {
            // 4th year effective annual interest rate is 75%
            interest = (750 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(rewardInterval) == 4) {
            // 5th year effective annual interest rate is 75%
            interest = (750 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(rewardInterval) == 5) {
            // 6th year effective annual interest rate is 75%
            interest = (750 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(rewardInterval) == 6) {
            // 7th year effective annual interest rate is 50%
            interest = (500 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(rewardInterval) == 7) {
            // 8th year effective annual interest rate is 50%
            interest = (500 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(rewardInterval) == 8) {
            // 9th year effective annual interest rate is 50%
            interest = (500 * maxMintProofOfStake).div(100);
        } // 10th year - 14 year effective annual interest rate is 10%
        return _coinAge.mul(interest).div(rewardInterval);
    }

    function getCoinAge(address _address, uint _now) internal returns (uint _coinAge) {
        if(transferIns[_address].length <= 0) return 0;

        for (uint i = 0; i < transferIns[_address].length; i++){
            if( _now < uint(transferIns[_address][i].time).add(stakeMinAge) ) continue;

            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time));
            if( nCoinSeconds > stakeMaxAge ) nCoinSeconds = stakeMaxAge;

            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * nCoinSeconds.div(1 days));
        }
    }

    function ownerSetStakeStartTime(uint timestamp) public onlyOwner {
        require((stakeStartTime <= 0) && (timestamp >= chainStartTime));
        stakeStartTime = timestamp;
    }
    
    /* Batch token transfer. Used by contract creator to distribute initial tokens to holders */
    function batchTransfer(address[] _recipients, uint[] _values) onlyOwner returns (bool) {
        require( _recipients.length > 0 && _recipients.length == _values.length);

        uint total = 0;
        for(uint i = 0; i < _values.length; i++){
            total = total.add(_values[i]);
        }
        require(total <= balances[msg.sender]);

        uint64 _now = uint64(now);
        for(uint j = 0; j < _recipients.length; j++){
            balances[_recipients[j]] = balances[_recipients[j]].add(_values[j]);
            transferIns[_recipients[j]].push(transferInStruct(uint128(_values[j]),_now));
            Transfer(msg.sender, _recipients[j], _values[j]);
        }

        balances[msg.sender] = balances[msg.sender].sub(total);
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        if(balances[msg.sender] > 0) transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));

        return true;
    }

//------------------------------------------------------------------------------
//Change Max Supply, Minting and Burn Supply
//------------------------------------------------------------------------------

    //Dev has ability to change Maximum Total Supply
    //To change Maximum Total Supply, it must based on token holder voting
    function changeMaxTotalSupply(uint256 _maxTotalSupply) public onlyOwner {
        maxTotalSupply = _maxTotalSupply;
        ChangeMaxTotalSupply(maxTotalSupply);
    }
    //Mint function is a failsafe if internal stake contract doesn't work
    //Dev will mint supply for external stake contract
    function supply(address account, uint256 amount) public onlyOwner {
        require(account != address(0));
        balances[account] = balances[account].add(amount);
        totalSupply = balances[account].add(amount);
        Transfer(address(0), account, amount);
    }

    function BurnToken(uint _value) public onlyOwner {
        require(_value > 0);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        totalSupply = totalSupply.sub(_value);
        totalInitialSupply = totalInitialSupply.sub(_value);
        Burn(msg.sender, _value);
    }
    
    function changeStakeMaxAge(uint256 _stakeMaxAge) public onlyOwner {
        stakeMaxAge = _stakeMaxAge;
        ChangeStakeMaxAge(stakeMaxAge);
    }
    
    function destroy() public onlyOwner {
        selfdestruct(address(this));
    }
    
//------------------------------------------------------------------------------
//Presale
//------------------------------------------------------------------------------

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event ChangeRate(uint256 _value);
    
    bool public closed;
    
    uint public rate = 5000; //1 ETH = 5,000
    uint public startDate = now;
    uint public constant EthMin = 0.01 ether; //Minimum purchase
    uint public constant EthMax = 50 ether; //Maximum purchase

    function () public payable {
        uint amount;
        owner.transfer(msg.value);
        amount = msg.value * rate;
        balances[msg.sender] += amount;
        totalSupply = totalInitialSupply + balances[msg.sender];
        presaleSupply = presaleSupply - balances[msg.sender];
        require((now >= startDate) && (startDate > 0));
        require(!closed);
        require(msg.value >= EthMin && msg.value <= EthMax);
        require(amount <= presaleSupply);
        Transfer(address(0), msg.sender, amount);
    }
    
    function closeSale() public onlyOwner {
        require(!closed);
        closed = true;
    }
    
    function changeRate(uint256 _rate) public onlyOwner {
        rate = _rate;
        ChangeRate(rate);
    }
}