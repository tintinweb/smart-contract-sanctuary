pragma solidity 0.4.19;

// -------------------------------------------------------------------------------------------
// Created by HIGHLANDER NETWORK
// "ONEX Network"
//
// Homepage: https://onex.network
// ONEX Network is a ERC223 Proof-of-Stake standard token on Ethereum with a max supply of 10 Million.
// For details, please visit: https://github.com/HighlanderNetwork/ONEX-Network
// -------------------------------------------------------------------------------------------

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

contract ERC223 {
  uint public totalSupply;
  function balanceOf(address who) constant returns (uint);

  function name() constant returns (string _name);
  function symbol() constant returns (string _symbol);
  function decimals() constant returns (uint8 _decimals);
  function totalSupply() constant returns (uint256 _supply);

  function transfer(address to, uint value) returns (bool ok);
  function transfer(address to, uint value, bytes data) returns (bool ok);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event ERC223Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
}

contract ContractReceiver {
  function tokenFallback(address _from, uint _value, bytes _data);
}

/**
 * @title PoSTokenStandard
 * @dev the interface of PoSTokenStandard
 */
contract PoSTokenStandard {
    uint256 public stakeStartTime;
    uint256 public stakeMinAge;
    uint256 public stakeMaxAge;
    function mint() public returns (bool);
    function coinAge(address staker) public view returns (uint256);
    function annualInterest() public view returns (uint256);
    event Mint(address indexed _address, uint _reward);
}


contract ONEXN is ERC223, PoSTokenStandard {
    using SafeMath for uint256;

    string public name = "ONEX Network";
    string public symbol = "ONEXN";
    uint8 public decimals = 18;

    uint public chainStartTime; //chain start time
    uint public chainStartBlockNumber; //chain start block number
    uint public stakeStartTime; //stake start time
    uint public stakeMinAge = 3 days; // minimum age for coin age: 3D
    uint public stakeMaxAge = 90 days; // stake age of full weight: 90D
    uint public maxMintProofOfStake = 10**17; // default 10% annual interest

    uint public totalSupply;
    uint public maxTotalSupply;
    uint public totalInitialSupply;

    struct transferInStruct{
        uint128 amount;
        uint64 time;
    }

    mapping(address => uint256) balances;
    mapping(address => transferInStruct[]) transferIns;

    modifier canPoSMint() {
        require(totalSupply < maxTotalSupply);
        _;
    }


    function ONEXN() public {
        maxTotalSupply = 10**25; // 10 Mil.
        totalInitialSupply = 10**24; // 1 Mil.

        chainStartTime = now;
        stakeStartTime = now;
        chainStartBlockNumber = block.number;

        balances[msg.sender] = totalInitialSupply;
        totalSupply = totalInitialSupply;
    }

    //assemble the given address bytecode. If bytecode exists then the _addr is a contract.
    function isContract(address _addr) private returns (bool is_contract) {
        uint length;
        assembly {
            //retrieve the size of the code on target address, this needs assembly
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

    // Function that is called when a user or another contract wants to transfer funds .
    function transfer(address _to, uint _value, bytes _data) returns (bool success) {
        if(isContract(_to)) {
          return transferToContract(_to, _value, _data);
        } else {
          return transferToAddress(_to, _value, _data);
        }
    }

    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint _value) returns (bool success) {
        //standard function transfer similar to ERC20 transfer with no _data
        //added due to backwards compatibility reasons
        bytes memory empty;
        if(isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

    function transferToAddress(address _to, uint _value, bytes _data) private returns (bool success) {
      if(msg.sender == _to) return mint();
      if(balanceOf(msg.sender) < _value) revert();
      balances[msg.sender] = balanceOf(msg.sender).sub(_value);
      balances[_to] = balanceOf(_to).add(_value);

      if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
      uint64 _now = uint64(now);
      transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
      transferIns[_to].push(transferInStruct(uint128(_value),_now));

      Transfer(msg.sender, _to, _value);
      ERC223Transfer(msg.sender, _to, _value, _data);
      return true;
    }

    //function that is called when transaction target is a contract
    function transferToContract(address _to, uint _value, bytes _data) private returns (bool success) {
      if(msg.sender == _to) return mint();
      if (balanceOf(msg.sender) < _value) revert();
      balances[msg.sender] = balanceOf(msg.sender).sub(_value);
      balances[_to] = balanceOf(_to).add(_value);
      ContractReceiver reciever = ContractReceiver(_to);
      reciever.tokenFallback(msg.sender, _value, _data);

      if(transferIns[msg.sender].length > 0) delete transferIns[msg.sender];
      uint64 _now = uint64(now);
      transferIns[msg.sender].push(transferInStruct(uint128(balances[msg.sender]),_now));
      transferIns[_to].push(transferInStruct(uint128(_value),_now));

      Transfer(msg.sender, _to, _value);
      ERC223Transfer(msg.sender, _to, _value, _data);
      return true;
    }

    function mint() public canPoSMint returns (bool) {
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


    function getBlockNumber() public view returns (uint blockNumber) {
        blockNumber = block.number.sub(chainStartBlockNumber);
    }


    function coinAge(address staker) public view returns (uint256) {
        return getCoinAge(staker, now);
    }


    function annualInterest() public view returns(uint interest) {
        uint _now = now;
        interest = maxMintProofOfStake;
        if((_now.sub(stakeStartTime)).div(365 days) == 0) {
            interest = (770 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(365 days) == 1){
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
        if((_now.sub(stakeStartTime)).div(365 days) == 0) {
            // 1st year effective annual interest rate is 100% when we select the stakeMaxAge (90 days) as the compounding period.
            interest = (770 * maxMintProofOfStake).div(100);
        } else if((_now.sub(stakeStartTime)).div(365 days) == 1){
            // 2nd year effective annual interest rate is 50%
            interest = (435 * maxMintProofOfStake).div(100);
        }

        uint offset = 10**uint(decimals);

        return (_coinAge * interest).div(365 * offset);
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

    function balanceOf(address _owner) constant returns (uint balance) {
      return balances[_owner];
    }

    // Function to access name of token .
    function name() constant returns (string _name) {
        return name;
    }
    // Function to access symbol of token .
    function symbol() constant returns (string _symbol) {
        return symbol;
    }
    // Function to access decimals of token .
    function decimals() constant returns (uint8 _decimals) {
        return decimals;
    }
    // Function to access total supply of tokens .
    function totalSupply() constant returns (uint256 _totalSupply) {
        return totalSupply;
    }
}