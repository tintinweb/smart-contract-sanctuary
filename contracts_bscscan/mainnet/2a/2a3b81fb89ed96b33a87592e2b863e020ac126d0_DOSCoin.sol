/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

pragma solidity >=0.4.22 <0.6.0;

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
interface IERC20 {
    function transfer(address to, uint256 value) external returns (bool);
    function approve(address spender, uint256 value) external returns (bool);
    function transferFrom(address from, address to, uint256 value) external returns (bool);
    function totalSupply() external view returns (uint256);
    function balanceOf(address who) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error
 */
library SafeMath {
    /**
     * @dev Multiplies two unsigned integers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two unsigned integers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
     * reverts when dividing by zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}





/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token
 */
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) public _balances;

    mapping (address => mapping (address => uint256)) private _allowed;

    uint256 private _totalSupply =  0;
    
    
    

    /**
     * @dev Total number of tokens in existence
     */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev Gets the balance of the specified address.
     * @param owner The address to query the balance of.
     * @return A uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    /**
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param owner address The address which owns the funds.
     * @param spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowed[owner][spender];
    }

    /**
     * @dev Transfer token to a specified address
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function transfer(address to, uint256 value) public returns (bool) {
        _transfer(msg.sender, to, value);
        return true;
    }
 
 
    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * Beware that changing an allowance with this method brings the risk that someone may use both the old
     * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
     * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards
     * @param spender The address which will spend the funds.
     * @param value The amount of tokens to be spent.
     */
    function approve(address spender, uint256 value) public returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }

    /**
     * @dev Transfer tokens from one address to another.
     * Note that while this function emits an Approval event, this is not required as per the specification,
     * and other compliant implementations may not emit the event.
     * @param from address The address which you want to send tokens from
     * @param to address The address which you want to transfer to
     * @param value uint256 the amount of tokens to be transferred
     */
    function transferFrom(address from, address to, uint256 value) public returns (bool) {
        _transfer(from, to, value);
        _approve(from, msg.sender, _allowed[from][msg.sender].sub(value));
        return true;
    }

    /**
     * @dev Increase the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To increment
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param addedValue The amount of tokens to increase the allowance by.
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].add(addedValue));
        return true;
    }

    /**
     * @dev Decrease the amount of tokens that an owner allowed to a spender.
     * approve should be called when _allowed[msg.sender][spender] == 0. To decrement
     * allowed value is better to use this function to avoid 2 calls (and wait until
     * the first transaction is mined)
     * Emits an Approval event.
     * @param spender The address which will spend the funds.
     * @param subtractedValue The amount of tokens to decrease the allowance by.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        _approve(msg.sender, spender, _allowed[msg.sender][spender].sub(subtractedValue));
        return true;
    }

    /**
     * @dev Transfer token for a specified addresses
     * @param from The address to transfer from.
     * @param to The address to transfer to.
     * @param value The amount to be transferred.
     */
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

    /**
     * @dev Internal function that mints an amount of the token and assigns it to
     * an account. This encapsulates the modification of balances such that the
     * proper events are emitted.
     * @param account The account that will receive the created tokens.
     * @param value The amount that will be created.
     */
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account.
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burn(address account, uint256 value) internal {
        require(account != address(0));
        require(value <= _balances[account]);
        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }


    /**
     * @dev Approve an address to spend another addresses' tokens.
     * @param owner The address that owns the tokens.
     * @param spender The address that will spend the tokens.
     * @param value The number of tokens that can be spent.
     */
    function _approve(address owner, address spender, uint256 value) internal {
        require(spender != address(0));
        require(owner != address(0));

        _allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    /**
     * @dev Internal function that burns an amount of the token of a given
     * account, deducting from the sender's allowance for said account. Uses the
     * internal burn function.
     * Emits an Approval event (reflecting the reduced allowance).
     * @param account The account whose tokens will be burnt.
     * @param value The amount that will be burnt.
     */
    function _burnFrom(address account, uint256 value) internal {
        _burn(account, value);
        _approve(account, msg.sender, _allowed[account][msg.sender].sub(value));
    }
}


/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address private _owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    /**
     * @return true if `msg.sender` is the owner of the contract.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Allows the current owner to relinquish control of the contract.
     * It will not be possible to call the functions with the `onlyOwner`
     * modifier anymore.
     * @notice Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    

}

contract Pausable is Ownable {
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor () internal {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function pause() public onlyOwner whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    function unpause() public onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}

/**
 * @title ERC20Detailed token
 * @dev The decimals are only for visualization purposes.
 * All the operations are done using the smallest and indivisible token unit,
 * just as on Ethereum all the operations are done in wei.
 */
contract ERC20Detailed is IERC20 {
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    constructor (string memory name, string memory symbol, uint8 decimals) public {
        _name = name;
        _symbol = symbol;
        _decimals = decimals;
    }

    /**
     * @return the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @return the symbol of the token.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @return the number of decimals of the token.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }
}



contract DOSCoin is ERC20, Pausable, ERC20Detailed {
    
	address teamWallet = 0x1Fe111b01cf485c56fce29Ad08340b3D76547051;
    address advisorWallet = 0x899C20BA446de4723C16ad43128Aa4043fBE4Da4;
    address strategyPartnerWallet = 0x04b1D474C7c67bc925145aBe70Fb504938fC8099;
    address seedWallet = 0xb6Ce7acF8d609A7880bE8952BaEfDb8Bda06a9a5;
    address privateWallet = 0x8C093de239Fba99Ec0247BB2345FA3C526D71215;
    address marketingWallet = 0x30Ed9e3B6eb35645f55B504BA28d592b3c39250f;
    address echosystemFundWallet = 0x020B8C9EA53c10Ae3e674A073FEe3A9023C74a53;
    address IEOWallet = 0x3DbCb11Bf4Cd0AC3Dd868A7DEbe5E0424cd5c90f;
    
    uint256 private totalCoins; 
    
    struct LockItem {
        uint256  releaseDate;
        uint256  amount;
    }
    
    mapping (address => LockItem[]) public lockList;
    mapping (uint => uint) public monthMap;
    mapping (uint => uint) public quarterMap;
    address [] private lockedAddressList; // list of addresses that have some fund currently or previously locked
    
    
	constructor() public ERC20Detailed("DOS Coin", "DOS", 9) {  
	   
        monthMap[1]=1641945600;//=Wed, 12 Jan 2022 00:00:0 GMT
        monthMap[2]=1644624000;//=Sat, 12 Feb 2022 00:00:0 GMT
        monthMap[3]=1647043200;//=Sat, 12 Mar 2022 00:00:0 GMT
        monthMap[4]=1649721600;//=Tue, 12 Apr 2022 00:00:0 GMT
        monthMap[5]=1652313600;//=Thu, 12 May 2022 00:00:0 GMT
        monthMap[6]=1654992000;//=Sun, 12 Jun 2022 00:00:0 GMT
        monthMap[7]=1657584000;//=Tue, 12 Jul 2022 00:00:0 GMT
        monthMap[8]=1660262400;//=Fri, 12 Aug 2022 00:00:0 GMT
        monthMap[9]=1662940800;//=Mon, 12 Sep 2022 00:00:0 GMT
        monthMap[10]=1665532800;//=Wed, 12 Oct 2022 00:00:0 GMT
        monthMap[11]=1668211200;//=Sat, 12 Nov 2022 00:00:0 GMT
        monthMap[12]=1670803200;//=Mon, 12 Dec 2022 00:00:0 GMT
        monthMap[13]=1673481600;//=Thu, 12 Jan 2023 00:00:0 GMT
        monthMap[14]=1676160000;//=Sun, 12 Feb 2023 00:00:0 GMT
        monthMap[15]=1678579200;//=Sun, 12 Mar 2023 00:00:0 GMT
        monthMap[16]=1681257600;//=Wed, 12 Apr 2023 00:00:0 GMT
        monthMap[17]=1683849600;//=Fri, 12 May 2023 00:00:0 GMT
        monthMap[18]=1686528000;//=Mon, 12 Jun 2023 00:00:0 GMT
        monthMap[19]=1689120000;//=Wed, 12 Jul 2023 00:00:0 GMT
        monthMap[20]=1691798400;//=Sat, 12 Aug 2023 00:00:0 GMT
        monthMap[21]=1694476800;//=Tue, 12 Sep 2023 00:00:0 GMT
        monthMap[22]=1697068800;//=Thu, 12 Oct 2023 00:00:0 GMT
        monthMap[23]=1699747200;//=Sun, 12 Nov 2023 00:00:0 GMT
        monthMap[24]=1702339200;//=Tue, 12 Dec 2023 00:00:0 GMT
        monthMap[25]=1705017600;//=Fri, 12 Jan 2024 00:00:0 GMT
        monthMap[26]=1707696000;//=Mon, 12 Feb 2024 00:00:0 GMT
        monthMap[27]=1710201600;//=Tue, 12 Mar 2024 00:00:0 GMT
        monthMap[28]=1712880000;//=Fri, 12 Apr 2024 00:00:0 GMT
        monthMap[29]=1715472000;//=Sun, 12 May 2024 00:00:0 GMT
        monthMap[30]=1718150400;//=Wed, 12 Jun 2024 00:00:0 GMT
        
        quarterMap[1]=1647043200;//=Sat, 12 Mar 2022 00:00:0 GMT
        quarterMap[2]=1654992000;//=Sun, 12 Jun 2022 00:00:0 GMT
        quarterMap[3]=1662940800;//=Mon, 12 Sep 2022 00:00:0 GMT
        quarterMap[4]=1670803200;//=Mon, 12 Dec 2022 00:00:0 GMT
        quarterMap[5]=1678579200;//=Sun, 12 Mar 2023 00:00:0 GMT
        quarterMap[6]=1686528000;//=Mon, 12 Jun 2023 00:00:0 GMT
        quarterMap[7]=1694476800;//=Tue, 12 Sep 2023 00:00:0 GMT
        quarterMap[8]=1702339200;//=Tue, 12 Dec 2023 00:00:0 GMT
        quarterMap[9]=1710201600;//=Tue, 12 Mar 2024 00:00:0 GMT
        quarterMap[10]=1718150400;//=Wed, 12 Jun 2024 00:00:0 GMT
        quarterMap[11]=1726099200;//=Thu, 12 Sep 2024 00:00:0 GMT
        quarterMap[12]=1733961600;//=Thu, 12 Dec 2024 00:00:0 GMT
        quarterMap[13]=1741737600;//=Wed, 12 Mar 2025 00:00:0 GMT
        quarterMap[14]=1749686400;//=Thu, 12 Jun 2025 00:00:0 GMT
        quarterMap[15]=1757635200;//=Fri, 12 Sep 2025 00:00:0 GMT
        quarterMap[16]=1765497600;//=Fri, 12 Dec 2025 00:00:0 GMT
        quarterMap[17]=1773273600;//=Thu, 12 Mar 2026 00:00:0 GMT
        quarterMap[18]=1781222400;//=Fri, 12 Jun 2026 00:00:0 GMT
        quarterMap[19]=1789171200;//=Sat, 12 Sep 2026 00:00:0 GMT
        quarterMap[20]=1797033600;//=Sat, 12 Dec 2026 00:00:0 GMT
        quarterMap[21]=1804809600;//=Fri, 12 Mar 2027 00:00:0 GMT
        quarterMap[22]=1812758400;//=Sat, 12 Jun 2027 00:00:0 GMT
        quarterMap[23]=1820707200;//=Sun, 12 Sep 2027 00:00:0 GMT
        quarterMap[24]=1828569600;//=Sun, 12 Dec 2027 00:00:0 GMT
        quarterMap[25]=1836432000;//=Sun, 12 Mar 2028 00:00:0 GMT
        quarterMap[26]=1844380800;//=Mon, 12 Jun 2028 00:00:0 GMT
        quarterMap[27]=1852329600;//=Tue, 12 Sep 2028 00:00:0 GMT
        quarterMap[28]=1860192000;//=Tue, 12 Dec 2028 00:00:0 GMT
        quarterMap[29]=1867968000;//=Mon, 12 Mar 2029 00:00:0 GMT
        quarterMap[30]=1875916800;//=Tue, 12 Jun 2029 00:00:0 GMT
        quarterMap[31]=1883865600;//=Wed, 12 Sep 2029 00:00:0 GMT
        quarterMap[32]=1891728000;//=Wed, 12 Dec 2029 00:00:0 GMT
        quarterMap[33]=1899504000;//=Tue, 12 Mar 2030 00:00:0 GMT
        quarterMap[34]=1907452800;//=Wed, 12 Jun 2030 00:00:0 GMT
        quarterMap[35]=1915401600;//=Thu, 12 Sep 2030 00:00:0 GMT
        quarterMap[36]=1923264000;//=Thu, 12 Dec 2030 00:00:0 GMT
        quarterMap[37]=1931040000;//=Wed, 12 Mar 2031 00:00:0 GMT
        quarterMap[38]=1938988800;//=Thu, 12 Jun 2031 00:00:0 GMT
        quarterMap[39]=1946937600;//=Fri, 12 Sep 2031 00:00:0 GMT
        quarterMap[40]=1954800000;//=Fri, 12 Dec 2031 00:00:0 GMT
        
        totalCoins = 1000000000 * 10 ** uint256(decimals());
        _mint(owner(), totalCoins); // total supply fixed at 1 billion coins
        
        ERC20.transfer(strategyPartnerWallet, 100000000 * 10 ** uint256(decimals()));
        ERC20.transfer(seedWallet, 125000000 * 10 ** uint256(decimals()));
        ERC20.transfer(privateWallet, 57000000 * 10 ** uint256(decimals()));
        ERC20.transfer(IEOWallet, 2000000 * 10 ** uint256(decimals()));

        for(uint i = 6; i<= 30; i++) {
            transferAndLock(teamWallet, 6000000 * 10 ** uint256(decimals()), monthMap[i]);
        }
        
        for(uint i = 6; i<= 25; i++) {
            transferAndLock(advisorWallet, 2500000 * 10 ** uint256(decimals()), monthMap[i]);
        }        
        
        for(uint i = 1; i<= 20; i++) {
            transferAndLock(marketingWallet, 7500000 * 10 ** uint256(decimals()), monthMap[i]);
        }
        
        for(uint i = 1; i<= 40; i++) {
            transferAndLock(echosystemFundWallet, 9150000 * 10 ** uint256(decimals()), quarterMap[i]);
        }  
        
    }
	
	
     /**
     * @dev transfer of token to another address.
     * always require the sender has enough balance
     * @return the bool true if success. 
     * @param _receiver The address to transfer to.
     * @param _amount The amount to be transferred.
     */
     
	function transfer(address _receiver, uint256 _amount) public whenNotPaused returns (bool success) {
	    require(_receiver != address(0)); 
	    require(_amount <= getAvailableBalance(msg.sender));
        return ERC20.transfer(_receiver, _amount);
	}
	
	/**
     * @dev transfer of token on behalf of the owner to another address. 
     * always require the owner has enough balance and the sender is allowed to transfer the given amount
     * @return the bool true if success. 
     * @param _from The address to transfer from.
     * @param _receiver The address to transfer to.
     * @param _amount The amount to be transferred.
     */
    function transferFrom(address _from, address _receiver, uint256 _amount) public whenNotPaused returns (bool) {
        require(_from != address(0));
        require(_receiver != address(0));
        require(_amount <= allowance(_from, msg.sender));
        require(_amount <= getAvailableBalance(_from));
        return ERC20.transferFrom(_from, _receiver, _amount);
    }

    /**
     * @dev transfer to a given address a given amount and lock this fund until a given time
     * used for sending fund to team members, partners, or for owner to lock service fund over time
     * @return the bool true if success.
     * @param _receiver The address to transfer to.
     * @param _amount The amount to transfer.
     * @param _releaseDate The date to release token.
     */
	
	function transferAndLock(address _receiver, uint256 _amount, uint256 _releaseDate) public whenNotPaused returns (bool success) {
	    require(msg.sender == teamWallet || msg.sender == advisorWallet || msg.sender == strategyPartnerWallet || msg.sender == seedWallet ||
	            msg.sender == privateWallet || msg.sender == marketingWallet || msg.sender == echosystemFundWallet || msg.sender == owner());
        ERC20._transfer(msg.sender,_receiver,_amount);
    	
    	if (lockList[_receiver].length==0) lockedAddressList.push(_receiver);
		
    	LockItem memory item = LockItem({amount:_amount, releaseDate:_releaseDate});
		lockList[_receiver].push(item);
		
        return true;
	}
	
	
    /**
     * @return the total amount of locked funds of a given address.
     * @param lockedAddress The address to check.
     */
	function getLockedAmount(address lockedAddress) public view returns(uint256 _amount) {
	    uint256 lockedAmount =0;
	    for(uint256 j = 0; j<lockList[lockedAddress].length; j++) {
	        if(now < lockList[lockedAddress][j].releaseDate) {
	            uint256 temp = lockList[lockedAddress][j].amount;
	            lockedAmount += temp;
	        }
	    }
	    return lockedAmount;
	}
	
	/**
     * @return the total amount of locked funds of a given address.
     * @param lockedAddress The address to check.
     */
	function getAvailableBalance(address lockedAddress) public view returns(uint256 _amount) {
	    uint256 bal = balanceOf(lockedAddress);
	    uint256 locked = getLockedAmount(lockedAddress);
	    return bal.sub(locked);
	}
	
	/**
     * @dev function that burns an amount of the token of a given account.
     * @param _amount The amount that will be burnt.
     */
    function burn(uint256 _amount) public whenNotPaused {
        require(_amount <= getAvailableBalance(msg.sender));
        _burn(msg.sender, _amount);
    }
    
    function () payable external {   
        revert();
    }
    
    
    // the following functions are useful for frontend dApps
	
	/**
     * @return the list of all addresses that have at least a fund locked currently or in the past
     */
	function getLockedAddresses() public view returns (address[] memory) {
	    return lockedAddressList;
	}
	
	/**
     * @return the number of addresses that have at least a fund locked currently or in the past
     */
	function getNumberOfLockedAddresses() public view returns (uint256 _count) {
	    return lockedAddressList.length;
	}
	    
	    
	/**
     * @return the number of addresses that have at least a fund locked currently
     */
	function getNumberOfLockedAddressesCurrently() public view returns (uint256 _count) {
	    uint256 count=0;
	    for(uint256 i = 0; i<lockedAddressList.length; i++) {
	        if (getLockedAmount(lockedAddressList[i])>0) count++;
	    }
	    return count;
	}
	    
	/**
     * @return the list of all addresses that have at least a fund locked currently
     */
	function getLockedAddressesCurrently() public view returns (address[] memory) {
	    address [] memory list = new address[](getNumberOfLockedAddressesCurrently());
	    uint256 j = 0;
	    for(uint256 i = 0; i<lockedAddressList.length; i++) {
	        if (getLockedAmount(lockedAddressList[i])>0) {
	            list[j] = lockedAddressList[i];
	            j++;
	        }
	    }
	    
        return list;
    }
    
    
	/**
     * @return the total amount of locked funds at the current time
     */
	function getLockedAmountTotal() public view returns(uint256 _amount) {
	    uint256 sum =0;
	    for(uint256 i = 0; i<lockedAddressList.length; i++) {
	        uint256 lockedAmount = getLockedAmount(lockedAddressList[i]);
    	    sum = sum.add(lockedAmount);
	    }
	    return sum;
	}
	    
	    
	/**
	 * @return the total amount of circulating coins that are not locked at the current time
	 * 
	 */
	function getCirculatingSupplyTotal() public view returns(uint256 _amount) {
	    return totalSupply().sub(getLockedAmountTotal());
	}
    
    /**
	 * @return the total amount of burned coins
	 * 
	 */
	function getBurnedAmountTotal() public view returns(uint256 _amount) {
	    return totalCoins.sub(totalSupply());
	}
    
}