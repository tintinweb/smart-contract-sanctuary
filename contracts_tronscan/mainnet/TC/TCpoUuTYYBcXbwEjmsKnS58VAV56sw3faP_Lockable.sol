//SourceUnit: locked.sol

pragma solidity 0.5.9;

interface trc20interface
{
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);    
}

contract Ownable {
    address payable internal _owner;
    address public signer;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () internal {
        _owner = msg.sender;
        signer = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @return the address of the owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }
    
    modifier onlySigner {
        require(msg.sender == signer, 'caller must be signer');
        _;
    }
    
    function setSigner(address _signer) public onlyOwner {
        signer = _signer;
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
    function transferOwnership(address payable newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function _transferOwnership(address payable newOwner) internal {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Lockable is Ownable{
    
    address public trc20=address(0);
    mapping(uint256=>uint256) public lockmap;
    mapping(uint256=>uint256) public locktime;
    mapping(uint256=>uint256) public histLockmap;
    uint256 public cnt=1;
    
    constructor (address tokenContractAddress) public {
        trc20=tokenContractAddress;
    }
    
    
    function lock(uint256 _amount, uint256 _duration) public onlyOwner returns(bool)
    {
        require(_amount!=0,"Invalid Amount");
        require(_duration!=0,"Invalid Duration");
        trc20interface(trc20).transferFrom(msg.sender,address(this),_amount);
        lockmap[cnt]=_amount;
        histLockmap[cnt]=_amount;
        locktime[cnt]=block.timestamp+(_duration*(60*60));
        cnt=cnt+1;
        return true;
    }
    
    function release() public onlyOwner returns(bool)
    {
        uint256 tempval=0;
        for(uint i=1;i<=cnt;i++)
        {
            if(locktime[i]<=block.timestamp && lockmap[i]>0)
            {
                tempval+=lockmap[i];
		lockmap[i]=0;
		locktime[i]=0;
            }
        }
        
        trc20interface(trc20).transfer(msg.sender,tempval);
        return true;
    }
    
    function availableLockedAmount() public view returns(uint256)
    {
        uint256 tempval=0;
        for(uint i=1;i<=cnt;i++)
        {
            if(locktime[i]>=block.timestamp  && lockmap[i]>0)
            {
                tempval+=lockmap[i];
              
            }
        }
        return tempval;
    }
    
    function availableReleaseAmount() public view returns(uint256)
    {
        uint256 tempval=0;
        for(uint i=1;i<=cnt;i++)
        {
            if(locktime[i]<block.timestamp  && lockmap[i]>0)
            {
                tempval+=lockmap[i];
              
            }
        }
        return tempval;
    }
    
    function changeTRC20address(address _add) public onlyOwner returns(bool)
    {
        require(_add!=address(0),"Invalid Address");
        
        trc20=_add;
        return true;
    }
    
    
    
}