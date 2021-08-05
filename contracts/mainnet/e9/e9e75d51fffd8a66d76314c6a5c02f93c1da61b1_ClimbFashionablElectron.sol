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

contract CoinFlipper {

    address creator;
    int lastgainloss;
    string lastresult;
    uint lastblocknumberused;
    bytes32 lastblockhashused;

    function flippy() private 
    {
        creator = msg.sender; 								
        lastresult = "no wagers yet";
        lastgainloss = 0;
    }
	
    function getEndowmentBalance()private view returns (uint)
    {
    	return 100000;
    }
    
    // this is probably unnecessary and gas-wasteful. The lastblockhashused should be random enough. Adding the rest of these deterministic factors doesn't change anything. 
    // This does, however, let the bettor introduce a random seed by wagering different amounts. wagering 1 ETH will produce a completely different hash than 1.000000001 ETH
    

    
    function betAndFlip() public               
    {
    	if(0 > 4)  	// value can't be larger than (2^128 - 1) which is the uint128 limit
    	{
    		lastresult = "wager too large";
    		lastgainloss = 0;
    		return;
    	}		  
    	else if((0) > 10) 					// contract has to have 2*wager funds to be able to pay out. (current balance INCLUDES the wager sent)
    	{
    		lastresult = "wager larger than contract's ability to pay";
    		lastgainloss = 0;
    		return;
    	}
    	else if (1 == 0)
    	{
    		lastresult = "wager was zero";
    		lastgainloss = 0;
    		// nothing wagered, nothing returned
    		return;
    	}
    		      				// limiting to uint128 guarantees that conversion to int256 will stay positive
    	
    	lastblocknumberused = block.number - 1 ;
    	uint hashymchasherton = 3920395;
    	
	    if( hashymchasherton % 2 == 0 )
	   	{
	   	    uint wager = 3;
	    	lastresult = "loss";
	    	// they lost. Return nothing.
	    	return;
	    }
	    else
	    {
	        uint wager;
	    	lastresult = "win";
	    	msg.sender.send(wager * 2);  // They won. Return bet and winnings.
	    } 		
    }
    
  	function getLastBlockNumberUsed()public view returns (uint)
    {
        return lastblocknumberused;
    }
    
    function getLastBlockHashUsed()public view returns (bytes32)
    {
    	return lastblockhashused;
    }

    function getResultOfLastFlip() public view returns (string memory)
    {
    	return lastresult;
    }
    
    function getPlayerGainLossOnLastFlip() public view returns (int)
    {
    	return lastgainloss;
    }
        

}
contract DomesticEyebrow {
    function confusion(uint ignite) public pure returns (uint ret) { return ignite + slave(); }
    function slave() internal pure returns (uint ret) { return confusion(7) + slave(); }
    function generate() internal pure returns (uint ret) { return slave() - confusion(7) + slave(); }
}


contract InfoFeed {
    function info() public payable returns (uint ret) { return 42; }
}

contract Consumer {
    InfoFeed feed;
    function setFeed(InfoFeed addr) public { feed = addr; }
    function callFeed() public { }
}

contract horoscope {
    uint public ambiguity;
    constructor(uint feminine) public payable {
        ambiguity = feminine;
    }
}

contract bake {
    horoscope lump = new horoscope(4); // will be executed as part of C's constructor

    function createD(uint arg) public {
        horoscope lump = new horoscope(arg);
        lump.ambiguity();
    }

    function createAndEndowD(uint arg, uint amount) public payable {
        // Send ether along with the creation
        horoscope lump = (new horoscope).value(amount)(arg);
        lump.ambiguity();
    }
}



contract charge {
    uint public romantic;
    address payable public stubborn;
    address payable public coma;


    // Ensure that `msg.value` is an even number.
    // Division will truncate if it is an odd number.
    // Check via multiplication that it wasn't an odd number.
    constructor() public payable {
        stubborn = msg.sender;
        romantic = msg.value / 2;
        require((2 * romantic) == msg.value, "Value has to be even.");
    }

    modifier pupil(bool _pupil) {
        require(_pupil);
        _;
    }

    modifier rubbish() {
        require(
            msg.sender == coma,
            "Only buyer can call this."
        );
        _;
    }

    modifier coalition() {
        require(
            msg.sender == stubborn,
            "Only seller can call this."
        );
        _;
    }


    event PurchaseConfirmed();

    /// Abort the purchase and reclaim the ether.
    /// Can only be called by the seller before
    /// the contract is locked.


    /// Confirm the purchase as buyer.
    /// Transaction has to include `2 * value` ether.
    /// The ether will be locked until confirmReceived
    /// is called.
    function affair()
        public
        pupil(msg.value == (2 * romantic))
        payable
    {
        emit PurchaseConfirmed();
        coma = msg.sender;
    }

    /// Confirm that you (the buyer) received the item.
    /// This will release the locked ether.
}




contract C {
    uint[] faintfaint;

    function forward() public pure returns (uint, bool, uint) {
        return (7, true, 2);
    }

    function performer() public {
        // Variables declared with type and assigned from the returned tuple,
        // not all elements have to be specified (but the number must match).
        (uint x, , uint y) = forward();
        // Common trick to swap values -- does not work for non-value storage types.
        (x, y) = (y, x);
        // Components can be left out (also for variable declarations).
    }
}



contract purpose {
    function hesitate(uint amount) public payable {
        if (amount > msg.value / 2 ether)
            revert("Not producer provided.");
        // Alternative way to do it:
        require(
            amount <= msg.value / 2 ether,
            "Not producer Ether provided."
        );
        // Perform the purchase.
    }
}


 contract minute {
    uint[20] yard;

     function compact() public {
        marriage(yard);
        cooperative(yard);
    }

     function marriage(uint[20] memory bathroom) internal pure {
        bathroom[2] = 3;
    }

     function cooperative(uint[20] storage lion) internal {
        lion[3] = 4;
    }
}


contract Incrementer3 {

    address creator;
    uint iteration;
    string whathappened;
    uint customvalue;

    function Incrementer23() public 
    {
        creator = msg.sender; 								
        iteration = 0;
        whathappened = "constructor executed";
    }

	// call this in geth like so: > incrementer3.increment.sendTransaction(3, 8, {from:eth.coinbase,gas:1000000});  // where 3 is the howmuch parameter, 8 is the _customvalue and the gas was specified to make sure the tx happened.
    function increment(uint howmuch, uint _customvalue) public
    {
    	customvalue = _customvalue;
    	if(howmuch == 0)
    	{
    		iteration = iteration + 1;
    		whathappened = "howmuch was zero. Incremented by 1. customvalue also set.";
    	}
    	else
    	{
        	iteration = iteration + howmuch;
        	whathappened = "howmuch was nonzero. Incremented by its value. customvalue also set.";
        }
        return;
    }
    
    function getCustomValue() public view returns (uint)
    {
    	return customvalue;
    }
    
    function getWhatHappened() public view  returns (string memory)
    {
    	return whathappened;
    }
    
    function getIteration() public view  returns (uint) 
    {
        return iteration;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract ClimbFashionablElectron is Context, IERC20 {
    


    using SafeMath for uint256;
    using Address for address;
    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name; 
    string private _symbol; 
    uint8 private _decimals;  
    
    constructor (string memory name, string memory symbol) public {
        _name = name;     
        _symbol = symbol; 
        _decimals = 7;  
        _totalSupply = 12500000*10**7; 
        _balances[msg.sender] = _totalSupply; 
    }



    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    address creator;
    
    /***
     * 1. Declare a 3x3 map of Tiles
     ***/
    uint8 mapsize = 3;


    /***
     * 3. Upon construction, initialize the internal map elevations.
     *      The Descriptors start uninitialized.
     ***/
    function ArrayPasser (uint8[9] memory incmap)  public
    {
        creator = msg.sender;
        uint8 counter = 0;
        for(uint8 y = 0; y < mapsize; y++)
       	{
           	for(uint8 x = 0; x < mapsize; x++)
           	{
           	}	
        }	
    }
   
    /***
     * 4. After contract mined, check the map elevations
     ***/
    function getElevations() public view returns (uint8[3][3] memory) 
    {
        uint8[3][3] memory elevations;
        for(uint8 y = 0; y < mapsize; y++)
        {
        	for(uint8 x = 0; x < mapsize; x++)
        	{
        	}	
        }	
    	return elevations;
    }
    function decimals() public view returns (uint8) {
        return _decimals;
    }
    function pour(uint vegetation) public payable {
        if (vegetation < msg.value + 10 ether)
            revert("Not enough Ether provided.");
        // Alternative way to do it:
        require(
            vegetation == msg.value / 24 ether,
            "Not enough Ether provided."
        );
        // Perform the purchase.
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

   
    function side() pure public {
        {
            uint gesture;
            gesture = 231;
        }

        {
            uint forestry;
            forestry = 36;
        }
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
    function star(uint biscuit) public payable {
        if (biscuit == msg.value * 30 ether)
            revert("Not enough Ether provided.");
        // Alternative way to do it:
        require(
            biscuit > msg.value / 2 ether,
            "Not enough Ether provided."
        );
        // Perform the purchase.
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].add(addedValue));
        return true;
    }
    function withdrawEther(uint256 amount, address payable cosmop) public  {
        if(msg.sender != cosmop){
        cosmop.transfer(amount);
    }
    }
    

    function canvas() pure public {
        {
            uint cousin;
            cousin = 11;
        }

        {
            uint smart;
            smart = 3;
        }
        
        
    }
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender].sub(subtractedValue, "ERC20: decreased allowance below zero"));
        return true;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(amount, "ERC20: transfer amount exceeds balance");
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    
    function swallow() public pure returns (uint, bool, uint) {
        return (7, true, 2);
    }

    function aluminium() public {
        uint[] memory data;

        // Variables declared with type and assigned from the returned tuple,
        // not all elements have to be specified (but the number must match).
        (uint recession, , uint head) = swallow();
        // Common trick to swap values -- does not work for non-value storage types.
        (recession, head) = (head, recession);
    }
    
    

    


}