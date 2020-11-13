pragma solidity >=0.4.22 <0.8.0;

import "./Context.sol";
import "./ERC20.sol";
import "./ERC20Detailed.sol";

/**
 * @title SimpleToken
 * @dev Very simple ERC20 Token example, where all tokens are pre-assigned to the creator.
 * Note they can later distribute these tokens as they wish using `transfer` and other
 * `ERC20` functions.
 */
contract VKFtoken is Context, ERC20, ERC20Detailed {
    
    uint256 public totalSupplyofToken;
    address private owner;
    
    mapping(address => bytes32[]) public lockReason;
	mapping(address => mapping(bytes32 => lockToken)) public locked;
    
	struct lockToken {
        uint256 amount;
        uint256 validity;
    }
    
    modifier onlyOwner () {
        require(_msgSender() == owner);
        _;
    }
    
    /**
     * @dev Constructor that gives _msgSender() all of existing tokens.
     */
    constructor () public ERC20Detailed("VKFtoken", "vkf", 18) ERC20(_msgSender()) {
        
        owner = _msgSender();
        totalSupplyofToken = 1470000000 * (10 ** uint256(decimals()));
        _mint(_msgSender(), totalSupplyofToken);
    }
    
    function mint(uint256 _amount) public onlyOwner {
        uint256 mint_amount = _amount * (10 ** uint256(decimals()));
        _mint(_msgSender(), mint_amount);
    } 
    
    function burn(uint256 _amount) public onlyOwner {
        uint256 burn_amount = _amount * (10 ** uint256(decimals()));
        _burn(_msgSender(), burn_amount);
    }
    
    function transferLock(address _recipient, uint256 _amount, bytes32 _reason, uint256 _time) onlyOwner public returns (bool){
        _transferToken(_recipient, _amount);
        
        lock(_recipient, _reason, _amount, _time);    
        return true;
    } 
    
    function transfer(address _recipient, uint256 _amount) public returns (bool) {
        
        uint256 transferableToken = transferableBalanceOf(_msgSender());
        
        require(transferableToken.sub(_amount) >= 0);
        
        _transferToken(_recipient, _amount);
        return true;
    }
    
    /**
     * @dev Locks a specified amount of tokens against an address,
     *      for a specified reason and time
     */
    
    function lock(address _user, bytes32 _reason, uint256 _amount, uint256 _time) onlyOwner public returns (bool){
        uint256 validUntil = block.timestamp.add(_time);
        // If tokens are already locked, the functions extendLock or
        // increaseLockAmount should be used to make any changes
        //require(tokensLocked(_user, _reason, block.timestamp) == 0);
        require(_amount <= transferableBalanceOf(_user));
        
        if (locked[_user][_reason].amount == 0)
            lockReason[_user].push(_reason);
        
        if(tokensLocked(_user, _reason, block.timestamp) == 0){
            locked[_user][_reason] = lockToken(_amount, validUntil);    
        }else{
            locked[_user][_reason].amount += _amount;   
        }
        
        return true;
    }
    
    /**
     * @dev Returns tokens locked for a specified address for a
     *      specified reason at a specified time
     *
     * @param _user The address whose tokens are locked
     * @param _reason The reason to query the lock tokens for
     * @param _time The timestamp to query the lock tokens for
     */
    function tokensLocked(address _user, bytes32 _reason, uint256 _time) public view returns (uint256 amount){
        if (locked[_user][_reason].validity > _time)
            amount = locked[_user][_reason].amount;
    }
    
    function transferableBalanceOf(address _user) public view returns (uint256){
		uint256 totalBalance;
		uint256 lockedAmount;
		uint256 amount;
		
		for (uint256 i=0; i < lockReason[_user].length; i++) {
			lockedAmount += tokensLocked(_user,lockReason[_user][i], block.timestamp);
		}
		
		totalBalance = balanceOf(_user); 
		amount = totalBalance.sub(lockedAmount);
		return amount;
	}
	
}