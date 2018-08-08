pragma solidity ^0.4.18;
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
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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


    function Ownable() public {
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
    function transferOwnership(address newOwner) internal onlyOwner {
        require(newOwner != address(0));
        owner = newOwner;
    }

}
/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
/**
 * @title PoSTokenStandard
 * @dev the interface of PoSTokenStandard
 */
contract PoSTokenStandard {
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    function mine() public  returns (bool);
    function coinAge(address who) public  returns (uint256);
    function annualInterest() public  returns (uint256);
    event Mine(address indexed _address, uint _reward);
}

contract CoinVila is ERC20,PoSTokenStandard,Ownable {
    using SafeMath for uint256;
    string public name = "CoinVila";
    string public symbol = "VILA";
    uint public decimals = 18;

    uint public chainStartTime; //chain start time
    uint public chainStartBlockNumber; //chain start block number
    uint public stakeStartTime; //stake start time
    uint public stakeMinAge = 3 days; // minimum age for coin age: 3D
    uint public stakeMaxAge = 90 days; // stake age of full weight: 90D
    uint public maxMintProofOfStake = 10**17; // default 10% annual interest

    uint public totalSupply;
    uint public maxTotalSupply = 44 * (10**6) * (10**uint256(decimals)); // 44 Mil
    uint public totalInitialSupply = 250 * (10**3) * (10**uint256(decimals)); // 250 K
    uint256 public INITIAL_SUPPLY = 250 * (10**3) * (10 ** uint256(decimals)); //250 K

    address public addressFundTeam =    0x5F7C2F8041cAB567c41708D5a89119F710322e3f;
    address public addressFundAirdrop = 0xba960ab8007B825Fa74682A61735FE3ECd653ee3;
    address public addressFundBounty = 0xdF96e49EC0983153B0Bf2125d60032Eb3685A457;
    address public addressFundPlatform = 0x65632770903989Ae84B49E9A758d7ADDA63697A3;
    address public addressFundHolder = 0xa198baaB6dD6D7023b184C450D64175d19bCB450;

    uint256 public amountFundTeam = 25 * (10**3) * (10**uint256(decimals));
    uint256 public amountFundAirdrop = 120 * (10**3) * (10**uint256(decimals));
    uint256 public amountFundBounty = 5 * (10**3) * (10**uint256(decimals));
    uint256 public amountFundPlatform = 75 * (10**3) * (10**uint256(decimals));
    uint256 public amountFundHolder = 25 * (10**3) * (10**uint256(decimals));

    struct transferInStruct{
        uint128 amount;
        uint64 time;
    }

    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    mapping(address => transferInStruct[]) transferIns;

    /**
     * @dev Fix for the ERC20 short address attack.
     */
    modifier onlyPayloadSize(uint size) {
        require(msg.data.length >= size + 4);
        _;
    }

    modifier canPoSMint() {
        require(totalSupply < maxTotalSupply);
        _;
    }

    function CoinVila(address _owner) public {
        require(_owner != address(0));
        owner = _owner;
        CoinVilaStart();
    }

    function CoinVilaStart() private {

        uint64 _now = uint64(now);
        totalSupply = totalInitialSupply;

        chainStartTime = _now;
        chainStartBlockNumber = block.number;
        stakeStartTime = _now;

        balances[addressFundTeam] = amountFundTeam;
        transferIns[addressFundTeam].push(transferInStruct(uint128(amountFundTeam),_now));

        balances[addressFundHolder] = amountFundHolder;
        transferIns[addressFundHolder].push(transferInStruct(uint128(amountFundHolder),_now));

        balances[addressFundAirdrop] = amountFundAirdrop;
        transferIns[addressFundAirdrop].push(transferInStruct(uint128(amountFundAirdrop),_now));

        balances[addressFundBounty] = amountFundBounty;
        transferIns[addressFundBounty].push(transferInStruct(uint128(amountFundBounty),_now));

        balances[addressFundPlatform] = amountFundPlatform;
        transferIns[addressFundPlatform].push(transferInStruct(uint128(amountFundPlatform),_now));
    }

    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) public returns (bool) {
        if(msg.sender == _to) return mine();
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
        uint64 _now = uint64(now);
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
        transferIns[_to].push(transferInStruct(uint128(_value),_now));
        return true;
    }

    function balanceOf(address _owner) public returns (uint256 balance) {
        return balances[_owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) public returns (bool) {
        require(_to != address(0));

        var _allowance = allowed[_from][msg.sender];
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

    function approve(address _spender, uint256 _value) public returns (bool) {
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    function mine() canPoSMint public returns (bool) {
        if(balances[msg.sender] <= 0) return false;
        if(transferIns[msg.sender].length <= 0) return false;

        uint reward = getProofOfStakeReward(msg.sender);
        if(reward <= 0) return false;

        totalSupply = totalSupply.add(reward);
        balances[msg.sender] = balances[msg.sender].add(reward);
        delete transferIns[msg.sender];
        transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),uint64(now)));
        Mine(msg.sender, reward);
        return true;
    }

    function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }

    function coinAge(address who) public returns (uint myCoinAge) {
        myCoinAge = getCoinAge(who,now);
    }

    /**
    * Year 1	300%	1,000,000
    * Year 2	300%	4,000,000
    * Year 3	50%	    6,000,000
    * Year 4	50%	    9,000,000
    * Year 5	50%	    13,500,000
    * Year 6	50%	    21,000,000
    * Year 7	50%	    32,000,000
    * Year 8	10%	    36,000,000
    * Year 9	10%	    40,000,000
    * Year 10	10%     44,000,000
    */
    function annualInterest() public returns(uint interest) {
        uint _now = now;
        interest = maxMintProofOfStake;
        if((_now.sub(stakeStartTime).div(1 years) == 0) || (_now.sub(stakeStartTime).div(1 years) == 1) ) {
            interest = (1650 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime).div(1 years) == 2) || (_now.sub(stakeStartTime).div(1 years) == 3) ||
                    (_now.sub(stakeStartTime).div(1 years) == 4) || (_now.sub(stakeStartTime).div(1 years) == 5) ||
                    (_now.sub(stakeStartTime).div(1 years) == 6)){
            interest = (435 * maxMintProofOfStake).div(100);
        }
    }

    function getProofOfStakeReward(address _address) internal view returns (uint) {
        require( (now >= stakeStartTime) && (stakeStartTime > 0) );

        uint _now = now;
        uint _coinAge = getCoinAge(_address, _now);
        if(_coinAge <= 0) return 0;

        uint interest = maxMintProofOfStake;
        // Due to the high interest rate for the first two years, compounding should be taken into account.
        // Effective annual interest rate = (1 + (nominal rate / number of compounding periods)) ^ (number of compounding periods) - 1
        if((_now.sub(stakeStartTime).div(1 years) == 0) || (_now.sub(stakeStartTime).div(1 years) == 1)) {
            // 1st, 2nd year effective annual interest rate is 300% when we select the stakeMaxAge (90 days) as the compounding period.
            interest = (1650 * maxMintProofOfStake).div(100);
        } else if ((_now.sub(stakeStartTime).div(1 years) == 2) || (_now.sub(stakeStartTime).div(1 years) == 3) ||
            (_now.sub(stakeStartTime).div(1 years) == 4) || (_now.sub(stakeStartTime).div(1 years) == 5) ||
            (_now.sub(stakeStartTime).div(1 years) == 6)) {
            // 3nd, 4nd, 5nd, 6nd, 7nd year effective annual interest rate is 50% when we select the stakeMaxAge (90 days) as the compounding period.
            interest = (435 * maxMintProofOfStake).div(100);
        }

        return (_coinAge * interest).div(365 * (10**decimals));
    }

    function getCoinAge(address _address, uint _now) internal view returns (uint _coinAge) {
        if(transferIns[_address].length <= 0) return 0;

        for (uint i = 0; i < transferIns[_address].length; i++){
            if( _now < uint(transferIns[_address][i].time).add(stakeMinAge) ) continue;

            uint nCoinSeconds = _now.sub(uint(transferIns[_address][i].time));
            if( nCoinSeconds > stakeMaxAge ) nCoinSeconds = stakeMaxAge;

            _coinAge = _coinAge.add(uint(transferIns[_address][i].amount) * nCoinSeconds.div(1 days));
        }
    }

    //function ownerSetStakeStartTime(uint timestamp) public {
    function ownerSetStakeStartTime(uint timestamp) public onlyOwner {
        require(stakeStartTime <= 0);
        stakeStartTime = timestamp;
    }

    /**
    * Peterson&#39;s Law Protection
    * Claim tokens
    */
    function claimTokens() public onlyOwner {
        uint256 balance = balanceOf(this);
        transfer(owner, balance);
        Transfer(this, owner, balance);
        owner.transfer(this.balance);
    }
}