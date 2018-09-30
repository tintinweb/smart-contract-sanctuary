pragma solidity ^0.4.24;

contract ERC20Interface {
    function totalSupply() public view returns (uint256);
    function balanceOf(address tokenOwner) public view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public returns (bool success);
    function approve(address spender, uint256 tokens) public returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract GGCPool{
    // ------------------------------------------------------------------------
    // Events
    // ------------------------------------------------------------------------
    //typeNo WL 1, ACL 2, BL 3, FeeL 4, TransConL 5, GGCPool 6, GGEPool 7  
    event ListLog(address addr, uint8 indexed typeNo, bool active);
    event OwnershipTransferred(address indexed _from, address indexed _to);
    event Deposit(address indexed sender, uint value);

    bool public transContractLocked = true;
    address public owner = msg.sender;
    address private ownerContract = address(0x0);
    mapping(address => bool) public allowContractList;
    mapping(address => bool) public blackList;
    
    function AssignGGCPoolOwner(address _ownerContract) 
    public 
    onlyOwner 
    notNull(_ownerContract) 
    {
        ownerContract = _ownerContract;
        emit OwnershipTransferred(owner, ownerContract);
        owner = ownerContract;
    }

    function isContract(address _addr) 
    private 
    view 
    returns (bool) 
    {
        if(allowContractList[_addr] || !transContractLocked){
            return false;
        }

        uint256 codeLength = 0;

        assembly {
            codeLength := extcodesize(_addr)
        }
        
        return (codeLength > 0);
    }

    function() 
    payable
    {
        if (msg.value > 0)
            emit Deposit(msg.sender, msg.value);
    }

    function tokenFallback(address from_, uint256 value_, bytes data_) 
    external 
    {
        from_;
        value_;
        data_;
        revert();
    }
    
    // ------------------------------------------------------------------------
    // Modifiers
    // ------------------------------------------------------------------------
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    modifier notNull(address _address) {
        require(_address != address(0x0));
        _;
    }

    // ------------------------------------------------------------------------
    // onlyOwner API
    // ------------------------------------------------------------------------
    function transferAnyERC20Token(address _tokenAddr, address _to, uint256 _amount) 
    public 
    onlyOwner 
    returns (bool success) 
    {
        require(!blackList[_tokenAddr]);
        require(!blackList[_to]);       
        require(!isContract(_to));
        return ERC20Interface(_tokenAddr).transfer(_to, _amount);
    }

    function reclaimEther(address _addr) 
    external 
    onlyOwner 
    {
        assert(_addr.send(this.balance));
    }
    
    function addBlacklist(address _addr) public notNull(_addr) onlyOwner {
        blackList[_addr] = true; 
        emit ListLog(_addr, 3, true);
    }
    
    function delBlackList(address _addr) public notNull(_addr) onlyOwner {
        delete blackList[_addr];
        emit ListLog(_addr, 3, false);
    }

    function setTransContractLocked(bool _lock) 
    public 
    onlyOwner 
    {
        transContractLocked = _lock;    
        emit ListLog(address(0x0), 5, _lock); 
    }   

    function addAllowContractList(address _addr) 
    public 
    notNull(_addr) 
    onlyOwner 
    {
        allowContractList[_addr] = true; 
        emit ListLog(_addr, 2, true);
    }
  
    function delAllowContractList(address _addr) 
    public 
    notNull(_addr) 
    onlyOwner 
    {
        delete allowContractList[_addr];
        emit ListLog(_addr, 2, false);
    }

    // ------------------------------------------------------------------------
    // Public view API
    // ------------------------------------------------------------------------
    function getGGCTokenBalance(address _tokenAddr) 
    public
    view 
    returns (uint256){

        return ERC20Interface(_tokenAddr).balanceOf(this);
    }

    function getTransContractLocked() 
    public 
    view 
    returns (bool) 
    { 
        return transContractLocked;
    }
}