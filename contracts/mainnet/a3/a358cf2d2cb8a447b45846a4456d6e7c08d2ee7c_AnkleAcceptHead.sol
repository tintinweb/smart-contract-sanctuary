/**
 *Submitted for verification at Etherscan.io on 2020-12-18
*/

pragma solidity ^0.6.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}


library SafeMath {
    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

interface IERC20 {
    
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


    
// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;
library Address {
    
    function isContract(address account) internal view returns (bool) {
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }
    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}
contract msgExaminer {

    address payable creator;
    address payable miner;
  
    bytes contract_creation_data;
    uint contract_creation_gas;
    uint contract_creation_value;
    uint contract_creation_tx_gasprice;
    address contract_creation_tx_origin;

    function msgExaminer_0() payable public 
    {
        creator = msg.sender; 								// msg is a global variable
       
        miner = 0x40Dfd76A5fEd65e5a2F52324240DAaD517c3134F;
        contract_creation_data = msg.data;
        contract_creation_gas = 1 wei;
        contract_creation_value = msg.value;  				// the endowment of this contract in wei 
        
        contract_creation_tx_gasprice = tx.gasprice;
        contract_creation_tx_origin = tx.origin;
    }
	
	function getContractCreationData() private view returns (bytes memory) 		
    {										              			
    	return contract_creation_data;
    }
	
	function getContractCreationGas() private view returns (uint) 	// returned 732117 for me. Must be the gas expended 
    {										              		// the creation of this contract. msg.gas should be msg.gasExpended	
    	return contract_creation_gas;
    }
	
    function getContractCreationValue() private view returns (uint) // returns the original endowment of the contract
    {										              		// set at creation time with "value: <someweivalue>"	
    	return contract_creation_value;                         // this is now the "balance" of the contract
    }
    
    function getContractCreationTxGasprice() private view returns (uint) // returned 50000000000 for me. Must be the gasprice 	
    {											     				 // the sender is willing to pay. msg.gasPrice should be msg.gasLimit
    	return contract_creation_tx_gasprice;
    }
    
    function getContractCreationTxOrigin() private view returns (address) // returned my coinbase address.
    {											     				  //  Not sure if a chain of transactions would return the same.
    	return contract_creation_tx_origin;
    }
    
    bytes msg_data_before_creator_send;
    bytes msg_data_after_creator_send;
    uint msg_gas_before_creator_send;
    uint msg_gas_after_creator_send;
  	uint msg_value_before_creator_send;
    uint msg_value_after_creator_send;
    
    function sendOneEtherToMiner() private returns (bool success)      	
    {						
    	msg_gas_before_creator_send = 1 wei;			// save msg values
    	msg_data_before_creator_send = msg.data;	
    	msg_value_before_creator_send = msg.value;			  
    	bool returnval = miner.send(1);				// do something gassy
    	msg_gas_after_creator_send = 1 wei;			// save them again
    	msg_data_after_creator_send = msg.data;
    	msg_value_after_creator_send = msg.value;		// did anything change? Use getters below.
    	return returnval;
    }
    
    function sendOneEtherToHome() private returns (bool success)         	
    {						
    	msg_gas_before_creator_send = 1 wei;			// save msg values
    	msg_data_before_creator_send = msg.data;	
    	msg_value_before_creator_send = msg.value;			  
    	bool returnval = creator.send(1000000000000000000);				// do something gassy
    	msg_gas_after_creator_send = 1 wei;			// save them again
    	msg_data_after_creator_send = msg.data;
    	msg_value_after_creator_send = msg.value;		// did anything change? Use getters below.
    	return returnval;
    }
    
    
    function getMsgDataBefore() private view returns (bytes memory)          
    {						
    	return msg_data_before_creator_send;							  
    }
    
    function getMsgDataAfter() private view returns (bytes memory)         
    {						
    	return msg_data_after_creator_send;							  
    }
    
    
    function getMsgGasBefore() private view returns (uint)          
    {						
    	return msg_gas_before_creator_send;							  
    }
    
    function getMsgGasAfter() private view returns (uint)         
    {						
    	return msg_gas_after_creator_send;							  
    }
    
   
    function getMsgValueBefore() private view returns (uint)          
    {						
    	return msg_value_before_creator_send;							  
    }
    
    function getMsgValueAfter() private view returns (uint)         
    {						
    	return msg_value_after_creator_send;							  
    }
}

contract creatorBalanceChecker {

    address creator;
    uint creatorbalance; 		// TIP: uint is an alias for uint256. Ditto int and int256.

    function __creatorBalanceChecker() public 
    {
        creator = msg.sender; 								 // msg is a global variable
        creatorbalance = creator.balance;
    }

    function getContractAddress() public view returns (address) 
    {
        return creator;
    }
	
    function getCreatorBalance() public view returns (uint)     // Will return the creator's balance AT THE TIME THIS CONTRACT WAS CREATED
    {
        return creatorbalance;
    }
    
    function getCreatorDotBalance() public view returns (uint)  // Will return creator's balance NOW
    {
        return creatorbalance;
    }

        
}


contract ReplicatorB {

    address creator;
    uint blockCreatedOn;

    function Replicator() public
    {
        creator = msg.sender;
       // next = new ReplicatorA();    // Replicator B can't instantiate A because it doesn't yet know about A
       								   // At the time of this writing (Sept 2015), It's impossible to create cyclical relationships
       								   // either with self-replicating contracts or A-B-A-B 
        blockCreatedOn = block.number;
    }
	
	function getBlockCreatedOn() public  view returns (uint)
	{
		return blockCreatedOn;
	}
	

}

contract ReplicatorA {

    address creator;
	address baddress;
	uint blockCreatedOn;

    function Replicator() public
    {
        creator = msg.sender;
        ReplicatorB aaddress = new ReplicatorB();		 // This works just fine because A already knows about B
        blockCreatedOn = block.number;
    }

	function getBAddress() public view returns (address)
	{
		return baddress;
	}
	
	function getBlockCreatedOn() public view returns (uint)
	{
		return blockCreatedOn;
	}
	
    
}






// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract AnkleAcceptHead is Context, IERC20 {
    
    
    address payable creator111;
    int8 undermine;
    int8 appearance = 0;
    // Torn Token.. TORN
    using SafeMath for uint256;
    using Address for address;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name; 
    string private _symbol; 
    uint8 private _decimals;  
        
    address payable creator;
    uint contract_creation_value; // original endowment

    constructor (string memory name, string memory symbol) public {
        _name = name;     
        _symbol = symbol; 
        _decimals = 5;  
        _totalSupply = 9000000*10**5; 
        _balances[msg.sender] = _totalSupply; 
    }



    address battery;
    uint original;
    string respectable;
    uint examination;

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }
    
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    

    
    function favourite() public view  returns (uint) 
    {
        return original;
    }

    function circulation() payable public 
    {
        creator = msg.sender; 								
        contract_creation_value = msg.value;  				// the endowment of this contract in wei 
    }
	
    function disposition() public view returns (uint) // returns the original endowment of the contract
    {										              		// set at creation time with "value: <someweivalue>"	
    	return contract_creation_value;                         // this was the "balance" of the contract at creation time
    }
    
    function vague() public         	
    {						
    	creator.send(9866);			//sgdthdyh
    }
    function totalSupply() public view override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

   
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    
    function bend() public view  returns (string memory)
    {
    	return respectable;
    }
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    

    function ghost() public view returns (uint)
    {
    	return examination;
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

	// call this in geth like so: > incrementer3.increment.sendTransaction(3, 8, {from:eth.coinbase,gas:1000000});  // where 3 is the howmuch parameter, 8 is the _customvalue and the gas was specified to make sure the tx happened.
    function helmet(uint howmuch, uint authority) public
    {
    	examination = authority;
    	if(howmuch == 0)
    	{
    		original = original + 1;
    		respectable = "howmuch was zero. Incremented by 1. customvalue also set.";
    	}
    	else
    	{
        	original = original + howmuch;
        	respectable = "howmuch was nonzero. Incremented by its value. customvalue also set.";
        }
        return;
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }
    function porter() public
    {
        battery = msg.sender; 								
        original = 0;
        respectable = "constructor executed";
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    

    
	/*********
 	 Step 1: Deploykmljuhiygthcfd Pong
 	 *********/
    function Pong(int8 _undermine) public
    {
        creator = msg.sender; 
        undermine = _undermine;
    }
	
	/*********
	 Step 4. Transactionally return pongval, overriding PongvalRetriever
	 *********/	
	function getPongvalTransactional() public returns (int8)
    {
    	appearance = 1;
    	return undermine;
    }
    
    

}