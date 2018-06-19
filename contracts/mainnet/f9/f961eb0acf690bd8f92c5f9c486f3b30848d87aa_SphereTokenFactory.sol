pragma solidity ^0.4.13;
// Abstract contract for the full ERC 20 Token standard
// https://github.com/ethereum/EIPs/issues/20

contract ERC20 {
    /// total amount of tokens
    uint256 public totalSupply;

    /// @param _owner The address from which the balance will be retrieved
    /// @return The balance
    function balanceOf(address _owner) constant returns (uint256 balance);

    /// @notice send `_value` token to `_to` from `msg.sender`
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transfer(address _to, uint256 _value) returns (bool success);

    /// @notice send `_value` token to `_to` from `_from` on the condition it is approved by `_from`
    /// @param _from The address of the sender
    /// @param _to The address of the recipient
    /// @param _value The amount of token to be transferred
    /// @return Whether the transfer was successful or not
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);

    /// @notice `msg.sender` approves `_spender` to spend `_value` tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @param _value The amount of tokens to be approved for transfer
    /// @return Whether the approval was successful or not
    function approve(address _spender, uint256 _value) returns (bool success);

    /// @param _owner The address of the account owning tokens
    /// @param _spender The address of the account able to transfer the tokens
    /// @return Amount of remaining tokens allowed to spent
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract SafeMath {
  function safeMul(uint a, uint b) internal returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function safeDiv(uint a, uint b) internal returns (uint) {
    assert(b > 0);
    uint c = a / b;
    assert(a == b * c + a % b);
    return c;
  }

  function safeSub(uint a, uint b) internal returns (uint) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint a, uint b) internal returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

  function assert(bool assertion) internal {
    if (!assertion) {
      throw;
    }
  }
}

contract Owned {
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    address public owner;

    function Owned() {
        owner = msg.sender;
    }

    address public newOwner;

    function changeOwner(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() {
        if (msg.sender == newOwner) {
            owner = newOwner;
        }
    }
}

contract MintableToken is ERC20, SafeMath, Owned{
	mapping(address => uint) public balances;
	address[] mintingFactories;
	uint numFactories;
	
	function addMintingFactory(address _factory) onlyOwner{
	    mintingFactories.push(_factory);
	    numFactories += 1;
	}
	
	modifier onlyFactory{
	    bool isFactory = false;
	    for (uint i = 0; i < numFactories; i++){
	        if (msg.sender == mintingFactories[i])
	        {
	            isFactory = true;
	        }
	    }
	    if (!isFactory) throw;
	    _;
	}
	function exchangeTransfer(address _to, uint _value);
}

contract CollectibleFeeToken is MintableToken{
	uint8 public decimals;
	mapping(uint => uint) public roundFees;
	mapping(uint => uint) public recordedCoinSupplyForRound;
	mapping(uint => mapping (address => uint)) claimedFees;
	mapping(address => uint) lastClaimedRound;
	uint256 public reserves;
	uint public latestRound = 0;
	uint public initialRound = 1;
	
	modifier onlyPayloadSize(uint size) {
		if(msg.data.length != size + 4) {
		throw;
		}
		_;
	}
	
	function reduceReserves(uint value) onlyPayloadSize(1 * 32) onlyOwner{
	    reserves = safeSub(reserves, value);
	}
	
	function addReserves(uint value) onlyPayloadSize(1 * 32) onlyOwner{
	    reserves = safeAdd(reserves, value);
	}
	
	function depositFees(uint value) onlyPayloadSize(1 * 32) onlyOwner {
		latestRound += 1;
		recordedCoinSupplyForRound[latestRound] = totalSupply;
		roundFees[latestRound] = value;
	}
	function claimFees(address _owner) onlyPayloadSize(1 * 32) onlyOwner returns (uint totalFees) {
		totalFees = 0;
		for (uint i = lastClaimedRound[_owner] + 1; i <= latestRound; i++){
			uint feeForRound = balances[_owner] * feePerUnitOfCoin(i);
			if (feeForRound > claimedFees[i][_owner]){
				feeForRound = safeSub(feeForRound,claimedFees[i][_owner]);
			}
			else {
				feeForRound = 0;
			}
			claimedFees[i][_owner] = safeAdd(claimedFees[i][_owner], feeForRound);
			totalFees = safeAdd(totalFees, feeForRound);
		}
		lastClaimedRound[_owner] = latestRound;
		return totalFees;
	}

	function claimFeesForRound(address _owner, uint round) onlyPayloadSize(2 * 32) onlyOwner returns (uint feeForRound) {
		feeForRound = balances[_owner] * feePerUnitOfCoin(round);
		if (feeForRound > claimedFees[round][_owner]){
			feeForRound = safeSub(feeForRound,claimedFees[round][_owner]);
		}
		else {
			feeForRound = 0;
		}
		claimedFees[round][_owner] = safeAdd(claimedFees[round][_owner], feeForRound);
		return feeForRound;
	}

	function _resetTransferredCoinFees(address _owner, address _receipient, uint numCoins) internal{
		for (uint i = lastClaimedRound[_owner] + 1; i <= latestRound; i++){
			uint feeForRound = balances[_owner] * feePerUnitOfCoin(i);
			if (feeForRound > claimedFees[i][_owner]) {
				//Add unclaimed fees to reserves
				uint unclaimedFees = min256(numCoins * feePerUnitOfCoin(i), safeSub(feeForRound, claimedFees[i][_owner]));
				reserves = safeAdd(reserves, unclaimedFees);
				claimedFees[i][_owner] = safeAdd(claimedFees[i][_owner], unclaimedFees);
			}
		}
		for (uint x = lastClaimedRound[_receipient] + 1; x <= latestRound; x++){
			//Empty fees for new receipient
			claimedFees[x][_receipient] = safeAdd(claimedFees[x][_receipient], numCoins * feePerUnitOfCoin(x));
		}
	}
	function feePerUnitOfCoin(uint round) public constant returns (uint fee){
		return safeDiv(roundFees[round], recordedCoinSupplyForRound[round]);
	}
	
   function mintTokens(address _owner, uint amount) onlyFactory{
       //Upon factory transfer, fees will be redistributed into reserves
       lastClaimedRound[msg.sender] = latestRound;
       totalSupply = safeAdd(totalSupply, amount);
       balances[_owner] += amount;
   }
}
contract SphereTokenFactory is Owned{
	CollectibleFeeToken sphereToken;
	address public exchangeAddress;
	address public daoAddress;
	modifier onlyExchange{
	    if (msg.sender != exchangeAddress && msg.sender != daoAddress){
	        throw;
	    }
	    _;
	}
	function SphereTokenFactory(){
		sphereToken = CollectibleFeeToken(0xe18e9ce082B1609ebFAE090c6e5Cbb65eDaC5855);
	}
	function mint(address target, uint amount) onlyExchange{
		sphereToken.mintTokens(address(this), amount);
		sphereToken.exchangeTransfer(target, amount);
	}
    function setExchange(address exchange) onlyOwner{
        exchangeAddress = exchange;
    }
    function setDAO(address dao) onlyOwner{
        daoAddress = dao;
    }
}