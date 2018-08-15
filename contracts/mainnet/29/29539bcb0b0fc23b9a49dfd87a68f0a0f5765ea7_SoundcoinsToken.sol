pragma solidity ^0.4.13;

library SafeMath {
    
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}

contract IERC20Token {
    function totalSupply() public constant returns (uint256 totalSupply);
    function balanceOf(address _owner) public  constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
    // NOT IERC20 Token
    function hasSDC(address _address,uint256 _quantity) public returns (bool success);
    function hasSDCC(address _address,uint256 _quantity) public returns (bool success);
    function eliminateSDCC(address _address,uint256 _quantity) public returns (bool success);
    function createSDCC(address _address,uint256 _quantity) public returns (bool success); 
    function createSDC(address _address,uint256 _init_quantity, uint256 _quantity) public returns (bool success);
    function stakeSDC(address _address, uint256 amount)  public returns(bool);
    function endStake(address _address, uint256 amount)  public returns(bool);

    function chipBalanceOf(address _address) public returns (uint256 _amount);
    function transferChips(address _from, address _to, uint256 _value) public returns (bool success);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------

contract Owned {
    
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Lockable is Owned{

	uint256 public lockedUntilBlock;

	event ContractLocked(uint256 _untilBlock, string _reason);

	modifier lockAffected {
		require(block.number > lockedUntilBlock);
		_;
	}

	function lockFromSelf(uint256 _untilBlock, string _reason) internal {
		lockedUntilBlock = _untilBlock;
		ContractLocked(_untilBlock, _reason);
	}


	function lockUntil(uint256 _untilBlock, string _reason) onlyOwner {
		lockedUntilBlock = _untilBlock;
		ContractLocked(_untilBlock, _reason);
	}
}

contract Token is IERC20Token, Lockable {

	using SafeMath for uint256;

	/* Public variables of the token */
	string public standard;
	string public name;
	string public symbol;
	uint8 public decimals;
	uint256 public supply;

	address public crowdsaleContractAddress;

	/* Private variables of the token */
	mapping (address => uint256) balances;
	mapping (address => mapping (address => uint256)) allowances;

	/* Events */
	event Mint(address indexed _to, uint256 _value);

	function Token(){

	}
	/* Returns total supply of issued tokens */
	function totalSupply() constant returns (uint256) {
		return supply;
	}

	/* Returns balance of address */
	function balanceOf(address _owner) constant returns (uint256 balance) {
		return balances[_owner];
	}

	/* Transfers tokens from your address to other */
	function transfer(address _to, uint256 _value) lockAffected returns (bool success) {
		require(_to != 0x0 && _to != address(this));
		balances[msg.sender] = balances[msg.sender].sub(_value); // Deduct senders balance
		balances[_to] = balances[_to].add(_value);               // Add recivers blaance
		Transfer(msg.sender, _to, _value);                       // Raise Transfer event
		return true;
	}

	/* Approve other address to spend tokens on your account */
	function approve(address _spender, uint256 _value) lockAffected returns (bool success) {
		allowances[msg.sender][_spender] = _value;        // Set allowance
		Approval(msg.sender, _spender, _value);           // Raise Approval event
		return true;
	}

	/* A contract attempts to get the coins */
	function transferFrom(address _from, address _to, uint256 _value)  returns (bool success) {
		require(_to != 0x0 && _to != address(this));
		balances[_from] = balances[_from].sub(_value);                              // Deduct senders balance
		balances[_to] = balances[_to].add(_value);                                  // Add recipient blaance
		allowances[_from][msg.sender] = allowances[_from][msg.sender].sub(_value);  // Deduct allowance for this address
		Transfer(_from, _to, _value);                                               // Raise Transfer event
		return true;
	}

	function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
		return allowances[_owner][_spender];
	}

	function mintTokens(address _to, uint256 _amount) {
		require(msg.sender == crowdsaleContractAddress);
		supply = supply.add(_amount);
		balances[_to] = balances[_to].add(_amount);
		Mint(_to, _amount);
		Transfer(0x0, _to, _amount);
	}

	function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) onlyOwner {
		IERC20Token(_tokenAddress).transfer(_to, _amount);
	}
}


//----------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}

// ----------------------------------------------------------------------------
// ERC20 Token, with the addition of symbol, name and decimals and an
// initial fixed supply
// ----------------------------------------------------------------------------
contract SoundcoinsToken is Token {

    address _teamAddress; // Account 3
    address _saleAddress;

    uint256 availableSupply = 250000000;
    uint256 minableSupply = 750000000;

    address public SoundcoinsAddress;
    /* Balances for ships */
    uint256 public total_SDCC_supply = 0;
    mapping (address => uint256) balances_chips;
    mapping (address => uint256) holdings_SDC;
    uint256 holdingsSupply = 0;


    modifier onlyAuthorized {
        require(msg.sender == SoundcoinsAddress);
        _;
    }
    /* Initializes contract */
    function SoundcoinsToken(address _crowdsaleContract) public {
        standard = "Soundcoins Token  V1.0";
        name = "Soundcoins";
        symbol = "SDC";
        decimals = 0;
        supply = 1000000000;
        _teamAddress = msg.sender;
        balances[msg.sender] = 100000000;
        _saleAddress = _crowdsaleContract;
        balances[_crowdsaleContract] = 150000000;
    }

    /********* */
    /* TOOLS  */
    /********* */


    function getAvailableSupply() public returns (uint256){
        return availableSupply;
    }

    function getMinableSupply() public returns (uint256){
        return minableSupply;
    }

    function getHoldingsSupply() public returns (uint256){
        return holdingsSupply;
    }

    function getSDCCSupply() public returns (uint256){
        return total_SDCC_supply;
    }

    function getSoundcoinsAddress() public returns (address){
        return SoundcoinsAddress;
    }
    // See if Address has Enough SDC
    function hasSDC(address _address,uint256 _quantity) public returns (bool success){
        return (balances[_address] >= _quantity);
    }

    // See if Address has Enough SDC
    function hasSDCC(address _address, uint256 _quantity) public returns (bool success){
        return (chipBalanceOf(_address) >= _quantity);
    }
   /*SDC*/

    function createSDC(address _address, uint256 _init_quantity, uint256 _quantity) onlyAuthorized public returns (bool success){
        require(minableSupply >= 0);
        balances[_address] = balances[_address].add(_quantity);
        availableSupply = availableSupply.add(_quantity);
        holdings_SDC[_address] = holdings_SDC[_address].sub(_init_quantity);
        minableSupply = minableSupply.sub(_quantity.sub(_init_quantity));
        holdingsSupply = holdingsSupply.sub(_init_quantity);
        return true;
    }

    function eliminateSDCC(address _address, uint256 _quantity) onlyAuthorized public returns (bool success){
        balances_chips[_address] = balances_chips[_address].sub(_quantity);
        total_SDCC_supply = total_SDCC_supply.sub(_quantity);
        return true;
    }

    function createSDCC(address _address, uint256 _quantity) onlyAuthorized public returns (bool success){
        balances_chips[_address] = balances_chips[_address].add(_quantity);
        total_SDCC_supply = total_SDCC_supply.add(_quantity);
        return true;
    }
    
    function chipBalanceOf(address _address) public returns (uint256 _amount) {
        return balances_chips[_address];
    }

    function transferChips(address _from, address _to, uint256 _value) onlyAuthorized public returns (bool success) {
        require(_to != 0x0 && _to != address(msg.sender));
        balances_chips[_from] = balances_chips[_from].sub(_value); // Deduct senders balance
        balances_chips[_to] = balances_chips[_to].add(_value);               // Add recivers blaance
        return true;
    }

    function changeSoundcoinsContract(address _newAddress) public onlyOwner {
        SoundcoinsAddress = _newAddress;
    }

    function stakeSDC(address _address, uint256 amount) onlyAuthorized public returns(bool){
        balances[_address] = balances[_address].sub(amount);
        availableSupply = availableSupply.sub(amount);
        holdings_SDC[_address] = holdings_SDC[_address].add(amount);
        holdingsSupply = holdingsSupply.add(amount);
        return true;
    }

    function endStake(address _address, uint256 amount) onlyAuthorized public returns(bool){
        balances[_address] = balances[_address].add(amount);
        availableSupply = availableSupply.add(amount);
        holdings_SDC[_address] = holdings_SDC[_address].sub(amount);
        holdingsSupply = holdingsSupply.sub(amount);
        return true;
    }
}