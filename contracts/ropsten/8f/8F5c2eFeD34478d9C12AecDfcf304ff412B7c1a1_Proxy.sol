/**
 *Submitted for verification at Etherscan.io on 2021-10-26
*/

//SPDX-License-Identifier: MIT

pragma solidity 0.8.1;
contract Proxy {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"
    constructor(bytes memory constructData, address contractLogic) {
        // save the code address
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, contractLogic)
        }
        (bool success, bytes memory result ) = contractLogic.delegatecall(constructData); // solium-disable-line
        require(success, "Construction failed");
    }

    fallback() external payable {
        assembly { // solium-disable-line
            let contractLogic := sload(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7)
            calldatacopy(0x0, 0x0, calldatasize())
            let success := delegatecall(sub(gas(), 10000), contractLogic, 0x0, calldatasize(), 0, 0)
            let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }
    }
}

contract Proxiable {
    // Code position in storage is keccak256("PROXIABLE") = "0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7"

    function updateCodeAddress(address newAddress) internal {
        require(
            bytes32(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7) == Proxiable(newAddress).proxiableUUID(),
            "Not compatible"
        );
        assembly { // solium-disable-line
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, newAddress)
        }
    }

    function proxiableUUID() public pure returns (bytes32) {
        return 0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7;
    }
} 

/**
 *Submitted for verification at Etherscan.io on 2020-06-25
*/

// pragma solidity 0.8.1;

library SafeMath
{

  function mul(uint256 a, uint256 b) internal pure returns (uint256)
    	{
		uint256 c = a * b;
		assert(a == 0 || c / a == b);

		return c;
  	}

  	function div(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a / b;

		return c;
  	}

  	function sub(uint256 a, uint256 b) internal pure returns (uint256)
	{
		assert(b <= a);

		return a - b;
  	}

  	function add(uint256 a, uint256 b) internal pure returns (uint256)
	{
		uint256 c = a + b;
		assert(c >= a);

		return c;
  	}
}

contract OwnerHelper
{
  	address public owner;
    address public manager;

  	event ChangeOwner(address indexed _from, address indexed _to);
    event ChangeManager(address indexed _from, address indexed _to);

    function setOwner(address to) public {
        require(owner == address(0), "Already initalized");
        owner = to;
    }
  	modifier onlyOwner
	{
		require(msg.sender == owner, "Only owner is allowed to perform this action");
		_;
  	}
  	
    modifier onlyManager
    {
        require(msg.sender == manager);
        _;
    }
  	
  	function transferOwnership(address _to) onlyOwner public
  	{
    	require(_to != owner);
        require(_to != manager);
    	require(_to != address(0x0));

        address from = owner;
      	owner = _to;
  	    
      	emit ChangeOwner(from, _to);
  	}

    function transferManager(address _to) onlyOwner public
    {
        require(_to != owner);
        require(_to != manager);
        require(_to != address(0x0));
        
        address from = manager;
        manager = _to;
        
        emit ChangeManager(from, _to);
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract FansOnlyCoin is IERC20, OwnerHelper
{
    using SafeMath for uint;
    
    string public name;
    uint public decimals;
    string public symbol;
    
    uint  private E18;
    uint private month;
    
    // Team                                   (25%)
    uint public vestingScheduleSupply;
    uint private vestinglock;

    
    uint public totalTokenSupply;
    uint public tokenIssuedSale;
        
    uint public burnTokenSupply;
    
    mapping (address => uint) public balances;
    mapping (address => mapping ( address => uint )) public approvals;
    
    bool public tokenLock;
    uint256 lastRun;
    address burnwallet;
    event SaleIssue(address indexed _to, uint _tokens);
    event SaleIssueLock(uint _tokens);
    event Burn(address indexed _from, uint _tokens);
    
    event TokenUnlock(address indexed _to, uint _tokens);
    function constructor1() public
    {
        setOwner(msg.sender);
        name        = "FansOnlyCoin";
        decimals    = 18;
        symbol      = "FOC";
        E18 = 1000000000000000000;
        month = 2592000;
        burnwallet=0x778eC422462c8c2AAe4BB8E34C3b30686151De32;
        vestingScheduleSupply      = 25*10**7 * E18;
        totalTokenSupply = 10**9 * E18;
        tokenLock = true;
        vestinglock=0;
        balances[msg.sender] = totalTokenSupply;
        require(totalTokenSupply==vestingScheduleSupply*4,"");

        tokenIssuedSale     = 0;
        burnTokenSupply     = 0;
        lastRun=block.timestamp;
    }
    function totalSupply() override view public returns (uint) 
    {
        return totalTokenSupply;
    }
    
    function balanceOf(address _who) override view public returns (uint) 
    {
        return balances[_who];
    }
    
    function transfer(address _to, uint _value) override public returns (bool) 
    {
        require(balances[msg.sender]>=_value,"No enough money");
        // require(isTransferable() == true);
        // saleIssueLock();
        // if(msg.sender!=owner){
        //     require(vestinglock > 0,"No time to transfer");
        //     require(balances[msg.sender]*vestinglock/4 >= _value,"Don't transfer out of allowed money value");
        // }
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    function approve(address _spender, uint _value) override public returns (bool)
    {
        require(balances[msg.sender]>=_value,"No enough money");
        require(isTransferable() == true);
        saleIssueLock();
        require(vestinglock > 0,"No time to transfer");
        require(balances[msg.sender]*vestinglock/4 >= _value,"Don't transfer out of allowed money value");
        
        approvals[msg.sender][_spender] = _value;                                                                                
        
        emit Approval(msg.sender, _spender, _value);
        
        return true; 
    }
    
    function allowance(address _owner, address _spender) override view public returns (uint) 
    {
        return approvals[_owner][_spender];
    }

    function transferFrom(address _from, address _to, uint _value) override public returns (bool) 
    {
        require(balances[_from]>=_value,"No enough money");
        require(isTransferable() == true);
        saleIssueLock();
        require(vestinglock > 0,"No time to transfer");
        require(balances[_from]*vestinglock/4 >= _value,"Don't transfer out of allowed money value");
        require(approvals[_from][msg.sender] >= _value);
        
        approvals[_from][msg.sender] = approvals[_from][msg.sender].sub(_value);
        balances[_from] = balances[_from].sub(_value);
        balances[_to]  = balances[_to].add(_value);
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
    function saleIssue(address _to) onlyOwner public
    {   
        require(tokenIssuedSale == 0);    
        uint tokens = vestingScheduleSupply;
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);

        balances[_to] = balances[_to].add(tokens);
        
        tokenIssuedSale = tokenIssuedSale.add(tokens);
        
        emit SaleIssue(_to, tokens);
    }

    function saleIssueLock() public
    {   
        if(block.timestamp - lastRun-month*vestinglock >= month){
            vestinglock=uint(block.timestamp - lastRun)/month;
        }
    }

    function isTransferable() private view returns (bool)
    {
        if(tokenLock == false)
        {
            return true;
        }
        else if(msg.sender == owner)
        {
            return true;
        }
        
        return false;
    }
    
    function setTokenUnlock() onlyManager public
    {
        require(tokenLock == true);
        
        tokenLock = false;
    }
    
    function setTokenLock() onlyManager public
    {
        require(tokenLock == false);
        
        tokenLock = true;
    }
    
    
    function transferAnyERC20Token(address tokenAddress, uint tokens) onlyOwner public returns (bool success)
    {
        return IERC20(tokenAddress).transfer(manager, tokens);
    }
    
    function burnToken(uint _value) onlyManager public
    {
        uint tokens = _value * E18;
        
        require(balances[msg.sender] >= tokens);
        
        balances[msg.sender] = balances[msg.sender].sub(tokens);
        
        burnTokenSupply = burnTokenSupply.add(tokens);
        totalTokenSupply = totalTokenSupply.sub(tokens);
        
        emit Burn(msg.sender, tokens);
    }
    
}
contract LogicContract is FansOnlyCoin, Proxiable {

    function updateCode(address newCode) onlyOwner public {
        updateCodeAddress(newCode);
    }
}