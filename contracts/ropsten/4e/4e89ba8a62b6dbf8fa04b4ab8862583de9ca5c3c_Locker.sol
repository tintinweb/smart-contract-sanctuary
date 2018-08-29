pragma solidity ^0.4.24;

contract RHEM_TEST2 {
    
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    
}

contract Owner {
    address public owner;

    /**
     * @dev The Ownable constructor sets the original `owner` 
     * of the contract to the sender account.
     */
    constructor() public {
        owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the current owner
     */
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

}

contract Locker is Owner {
    
    RHEM_TEST2 rhem;
    
    constructor(address _t) public {
        rhem = RHEM_TEST2(_t);
    }
    
    mapping(address => bool) locked;
    mapping(address => uint256) lockBalances;
    address[] public addressIndices;
    
    /**
     * @dev get Rhem Balance of Contract Address
     */
    function getContractRhemBalance() public view returns (uint256 balance) {
        return rhem.balanceOf(address(this));
    }
    
    /**
     * @dev Add Address with Lock Rhem Token
     */
    function addLockAccount(address _addr, uint256 _value) public onlyOwner returns (bool success){
        
        require(_value > 0);
        
        uint arrayLength = addressIndices.length;
        
        // Ccheck address exist, add value
        while(arrayLength > 0){
            if(addressIndices[arrayLength-1] == _addr){
                lockBalances[_addr] += _value;
                locked[_addr] = true;
                
                return true;
            }
            arrayLength -= 1;
        }
        
        addressIndices.push(_addr);
        lockBalances[_addr] = _value;
        locked[_addr] = true;
        
        return true;
    }
    
    /**
     * @dev Unlock Rhem Token of one specific address 
     */
    function Unlock(address _addr) public onlyOwner returns (uint256 amount){
        
        require(locked[_addr] == true);
        
        uint arrayLength = addressIndices.length;
        
        // Check index of address
        while(arrayLength > 0){
            if(addressIndices[arrayLength-1] == _addr){
                break;
            }
            arrayLength -= 1;
        }
        
        amount = lockBalances[addressIndices[arrayLength-1]];

        // transfer last index to target index, then delete last index
        addressIndices[arrayLength-1] = addressIndices[addressIndices.length-1];
        delete addressIndices[addressIndices.length-1];
        addressIndices.length--;
        
        locked[_addr] = false;
        
        return amount;
    }
    
    /**
     * @dev Unlock all Addresses with Lock Token 
     */
    function UnlockAll() public onlyOwner{
        
        uint arrayLength = addressIndices.length;
        
        // Unlock All address
        while(arrayLength > 0){
            
          //  rhem.approve(addressIndices[arrayLength-1], lockBalances[addressIndices[arrayLength-1]]);
            locked[addressIndices[arrayLength-1]] = false;
            delete addressIndices[arrayLength-1];
            addressIndices.length--;
            
            arrayLength -= 1;
        }
    }
    
    /**
     * @dev Check if address is lock
     */
    function isLock(address _addr) public view returns (bool success){
        
        if(locked[_addr] == false){
            return false;
        }
        
        return true;
    }
    
    /**
     * @dev Get Lock Balance of Specific address 
     */
    function LockBalance(address _addr) public view returns (uint256 lockBalance){

        return lockBalances[_addr];
    }
    
    /**
     * @dev Release Lock Rhem Token of the sender
     */
    function Release() public returns(bool success){
        
        rhem.transfer(msg.sender, lockBalances[msg.sender]);
        lockBalances[msg.sender] = 0;
        
        return true;
    }

}