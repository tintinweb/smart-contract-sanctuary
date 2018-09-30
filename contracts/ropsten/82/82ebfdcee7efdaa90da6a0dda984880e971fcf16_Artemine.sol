pragma solidity ^0.4.18;
contract Artemine { 

string public name; 
string public symbol; 
uint8 public decimals; 
uint256 initialBlockCount;
uint256 totalGenesisAddresses;
address genesisCallerAddress;
uint256 availableAmount;
uint256 availableBalance;
uint256 minedBlocks;
uint256 totalMaxAvailableAmount;
uint256 publicMiningReward;
uint256 publicMiningSupply;
uint256 overallSupply;
uint256 genesisSalesCount;
uint256 genesisSalesPriceCount;
uint256 genesisTransfersCount;
uint256 publicMineCallsCount;
bool setupRunning;
uint256 constant maxBlocks = 100000000;

mapping (address => uint256) balances; 
mapping (address => bool) isGenesisAddress; 
mapping (address => uint256) genesisRewardPerBlock;
mapping (address => uint256) genesisInitialSupply;
mapping (address => uint256) genesisBuyPrice;
mapping (address => mapping (address => uint256)) allowed;

event Transfer(address indexed from, address indexed to, uint256 value);
event Approval(address indexed _owner, address indexed _spender, uint256 _value);
event GenesisAddressTransfer(address indexed from, address indexed to, uint256 supply);
event GenesisAddressSale(address indexed from, address indexed to, uint256 price, uint256 supply);
event GenesisBuyPriceHistory(address indexed from, uint256 price);
event PublicMined(address indexed to, uint256 amount);

function Artemine() { 
name = "Artemine"; 
symbol = "ARTE"; 
decimals = 18; 
initialBlockCount = block.number;
publicMiningReward = 32000000000000;
totalGenesisAddresses = 0;
publicMiningSupply = 0;
overallSupply = 0;
genesisSalesCount = 0;
genesisSalesPriceCount = 0;
publicMineCallsCount = 0;
genesisTransfersCount = 0;
setupRunning = true;
genesisCallerAddress = 0x0000000000000000000000000000000000000000;
}

function currentEthBlock() constant returns (uint256 blockNumber)
{
	return block.number;
}

function currentBlock() constant returns (uint256 blockNumber)
{
	return block.number - initialBlockCount;
}

function setGenesisAddress(address _address, uint256 amount) public returns (bool success)
{
	if (setupRunning) //Once setupRunning is set to false there is no more possibility to Generate Genesis Addresses, this can be verified with the function isSetupRunning()
	{
		if (msg.sender == genesisCallerAddress)
		{
			if (balances[_address] == 0)
				totalGenesisAddresses += 1;							
			balances[_address] += amount;
			genesisInitialSupply[_address] += amount;
			genesisRewardPerBlock[_address] += (amount / maxBlocks);			
			isGenesisAddress[_address] = true;			
			overallSupply += amount;
			return true;
		}
	}
	return false;
}


function availableBalanceOf(address _address) constant returns (uint256 Balance)
{
	if (isGenesisAddress[_address])
	{
		minedBlocks = block.number - initialBlockCount;
		
		if (minedBlocks >= maxBlocks) return balances[_address];
		
		availableAmount = genesisRewardPerBlock[_address]*minedBlocks;
		
		totalMaxAvailableAmount = genesisInitialSupply[_address] - availableAmount;
		
		availableBalance = balances[_address] - totalMaxAvailableAmount;
		
		return availableBalance;
	}
	else
		return balances[_address];
}

function totalSupply() constant returns (uint256 TotalSupply)
{	
	minedBlocks = block.number - initialBlockCount;
	return ((overallSupply/maxBlocks)*minedBlocks)+publicMiningSupply;
}

function maxTotalSupply() constant returns (uint256 maxSupply)
{	
	return overallSupply + publicMiningSupply;
}

function transfer(address _to, uint256 _value) { 

if (isGenesisAddress[_to]) revert();

if (balances[msg.sender] < _value) revert(); 

if (balances[_to] + _value < balances[_to]) revert(); 

if (_value > availableBalanceOf(msg.sender)) revert();

balances[msg.sender] -= _value; 
balances[_to] += _value; 
Transfer(msg.sender, _to, _value); 
}

function transferFrom(
        address _from,
        address _to,
        uint256 _amount
) returns (bool success) {
	if (isGenesisAddress[_to])
		revert();
	
    if (availableBalanceOf(_from) >= _amount
        && allowed[_from][msg.sender] >= _amount
        && _amount > 0
        && balances[_to] + _amount > balances[_to]) {
        balances[_from] -= _amount;
        allowed[_from][msg.sender] -= _amount;
        balances[_to] += _amount;
        Transfer(_from, _to, _amount);
        return true;
    } else {
        return false;
    }
}

function approve(address _spender, uint256 _amount) returns (bool success) {
    allowed[msg.sender][_spender] = _amount;
    Approval(msg.sender, _spender, _amount);
    return true;
}

function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
    return allowed[_owner][_spender];
}

function setGenesisCallerAddress(address _caller) public returns (bool success)
{
	if (genesisCallerAddress != 0x0000000000000000000000000000000000000000) return false;
	
	genesisCallerAddress = _caller;
	
	return true;
}

function balanceOf(address _address) constant returns (uint256 balance) {
	return balances[_address];	
}

function TransferGenesis(address _to) { 
	if (!isGenesisAddress[msg.sender]) revert();
	
	if (balances[_to] > 0) revert();
	
	if (isGenesisAddress[_to]) revert();	
	
	balances[_to] = balances[msg.sender]; 
	balances[msg.sender] = 0;
	isGenesisAddress[msg.sender] = false;
	isGenesisAddress[_to] = true;
	genesisRewardPerBlock[_to] = genesisRewardPerBlock[msg.sender];
	genesisRewardPerBlock[msg.sender] = 0;
	genesisInitialSupply[_to] = genesisInitialSupply[msg.sender];
	genesisInitialSupply[msg.sender] = 0;
	Transfer(msg.sender, _to, balanceOf(_to));
	GenesisAddressTransfer(msg.sender, _to, balances[_to]);
	genesisTransfersCount += 1;
}

function SetGenesisBuyPrice(uint256 weiPrice) { 
	if (!isGenesisAddress[msg.sender]) revert();
	
	if (balances[msg.sender] == 0) revert();
	
	genesisBuyPrice[msg.sender] = weiPrice;
	
	GenesisBuyPriceHistory(msg.sender, weiPrice);
}

function BuyGenesis(address _address) payable{
	if (msg.value == 0) revert();
	
	if (genesisBuyPrice[_address] == 0) revert();
	
	if (isGenesisAddress[msg.sender]) revert();

	if (!isGenesisAddress[_address]) revert();
	
	if (balances[_address] == 0) revert();
	
	if (balances[msg.sender] > 0) revert();
	
	if (msg.value == genesisBuyPrice[_address])
	{
		if(!_address.send(msg.value)) revert();	
	}
	else revert();
	
	balances[msg.sender] = balances[_address];
	balances[_address] = 0;
	isGenesisAddress[msg.sender] = true;
	isGenesisAddress[_address] = false;
	genesisBuyPrice[msg.sender] = 0;
	genesisRewardPerBlock[msg.sender] = genesisRewardPerBlock[_address];
	genesisRewardPerBlock[_address] = 0;
	genesisInitialSupply[msg.sender] = genesisInitialSupply[_address];
	genesisInitialSupply[_address] = 0;
	Transfer(_address, msg.sender, balanceOf(msg.sender));	
	GenesisAddressSale(_address, msg.sender, msg.value, balances[msg.sender]);
	genesisSalesCount += 1;
	genesisSalesPriceCount += msg.value;
}

function PublicMine() {
	if (isGenesisAddress[msg.sender]) revert();
	if (publicMiningReward < 10000)	publicMiningReward = 10000;	
	balances[msg.sender] += publicMiningReward;
	publicMiningSupply += publicMiningReward;
	Transfer(this, msg.sender, publicMiningReward);
	PublicMined(msg.sender, publicMiningReward);
	publicMiningReward -= 10000;
	publicMineCallsCount += 1;
}

function stopSetup() public returns (bool success)
{
	if (msg.sender == genesisCallerAddress)
	{
		setupRunning = false;
	}
	return true;
}

function InitialBlockCount() constant returns(uint256){ return initialBlockCount; }
function TotalGenesisAddresses() constant returns(uint256){ return totalGenesisAddresses; }
function GenesisCallerAddress() constant returns(address){ return genesisCallerAddress; }
function MinedBlocks() constant returns(uint256){ minedBlocks = block.number - initialBlockCount; return minedBlocks; }
function PublicMiningReward() constant returns(uint256){ return publicMiningReward; }
function PublicMiningSupply() constant returns(uint256){ return publicMiningSupply; }
function isSetupRunning() constant returns(bool){ return setupRunning; }
function IsGenesisAddress(address _address) constant returns(bool) { return isGenesisAddress[_address];}
function GenesisBuyPrice(address _address) constant returns(uint256) { return genesisBuyPrice[_address];}
function GenesisRewardPerBlock(address _address) constant returns(uint256) { return genesisRewardPerBlock[_address];}
function GenesisInitialSupply(address _address) constant returns(uint256) { return genesisInitialSupply[_address];}
function GenesisSalesCount() constant returns(uint256) { return genesisSalesCount;}
function GenesisSalesPriceCount() constant returns(uint256) { return genesisSalesPriceCount;}
function GenesisTransfersCount() constant returns(uint256) { return genesisTransfersCount;}
function PublicMineCallsCount() constant returns(uint256) { return publicMineCallsCount;}
}