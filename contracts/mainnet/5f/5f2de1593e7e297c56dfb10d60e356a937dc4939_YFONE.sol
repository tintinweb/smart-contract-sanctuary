pragma solidity 0.5.17;

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "permission denied");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 value, address token, bytes calldata data) external;
}

contract YFONE is Ownable {
    // --- ERC20 Data ---
    string  public constant name     = "yfone.trade";
    string  public constant symbol   = "YET";
    string  public constant version  = "1";
    uint8   public constant decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256)                      public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    mapping (address => uint256)                      public nonces;

    event Approval(address indexed holder, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);

    // --- Math ---
    function add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }
    function sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;

    constructor(uint256 chainId_) public {
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes(version)),
            chainId_,
            address(this)
        ));
    }

    // --- Token ---
    
    function supply(address to, uint256 amount) external onlyOwner {
        balanceOf[to] = add(balanceOf[to], amount);
        totalSupply = add(totalSupply, amount);
        emit Transfer(address(0), to, amount);
    }
    
    function transfer(address to, uint256 amount) external returns (bool) {
        return transferFrom(msg.sender, to, amount);
    }
    
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        if (from != msg.sender && allowance[from][msg.sender] != uint256(-1))
            allowance[from][msg.sender] = sub(allowance[from][msg.sender], amount);
        require(balanceOf[from] >= amount, "insufficient-balance");
        balanceOf[from] = sub(balanceOf[from], amount);
        balanceOf[to] = add(balanceOf[to], amount);
        emit Transfer(from, to, amount);
        return true;
    }
    
    function burn(address from, uint256 amount) external {
        if (from != msg.sender && allowance[from][msg.sender] != uint256(-1))
            allowance[from][msg.sender] = sub(allowance[from][msg.sender], amount);
        require(balanceOf[from] >= amount, "insufficient-balance");
        balanceOf[from] = sub(balanceOf[from], amount);
        totalSupply = sub(totalSupply, amount);
        emit Transfer(from, address(0), amount);
    }
    
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    // --- Approve and call contract ---
    function approveAndCall(address spender, uint256 amount, bytes calldata data) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, amount, address(this), data);
        return true;
    }

    // --- Approve by signature ---
    function permit(address holder, address spender, uint256 nonce, uint256 expiry,
                    bool allowed, uint8 v, bytes32 r, bytes32 s) external
    {
        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH,
                                     holder,
                                     spender,
                                     nonce,
                                     expiry,
                                     allowed))
        ));

        require(holder != address(0), "invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "invalid-permit");
        require(expiry == 0 || now <= expiry, "permit-expired");
        require(nonce == nonces[holder]++, "invalid-nonce");
        uint256 amount = allowed ? uint256(-1) : 0;
        allowance[holder][spender] = amount;
        emit Approval(holder, spender, amount);
    }
}