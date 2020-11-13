/*
██╗     ███████╗██╗  ██╗                    
██║     ██╔════╝╚██╗██╔╝                    
██║     █████╗   ╚███╔╝                     
██║     ██╔══╝   ██╔██╗                     
███████╗███████╗██╔╝ ██╗                    
╚══════╝╚══════╝╚═╝  ╚═╝                    
████████╗ ██████╗ ██╗  ██╗███████╗███╗   ██╗
╚══██╔══╝██╔═══██╗██║ ██╔╝██╔════╝████╗  ██║
   ██║   ██║   ██║█████╔╝ █████╗  ██╔██╗ ██║
   ██║   ██║   ██║██╔═██╗ ██╔══╝  ██║╚██╗██║
   ██║   ╚██████╔╝██║  ██╗███████╗██║ ╚████║
   ╚═╝    ╚═════╝ ╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝
DEAR MSG.SENDER(S):
/ LexToken is a project in beta.
// Please audit and use at your own risk.
/// Entry into LexToken shall not create an attorney/client relationship.
//// Likewise, LexToken should not be construed as legal advice or replacement for professional counsel.
///// STEAL THIS C0D3SL4W 
////// presented by LexDAO LLC
*/
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.4;

interface IERC20 { // brief interface for erc20 token
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

library SafeMath { // arithmetic wrapper for unit under/overflow check
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }
    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }
}

contract LexToken {
    using SafeMath for uint256;
    
    address payable public manager; // account managing token rules & sale - see 'Manager Functions' - updateable by manager
    uint8   public decimals; // fixed unit scaling factor - default 18 to match ETH
    uint256 public saleRate; // rate of token purchase when sending ETH to contract - e.g., 10 saleRate returns 10 token per 1 ETH - updateable by manager
    uint256 public totalSupply; // tracks outstanding token mint - mint updateable by manager
    uint256 public totalSupplyCap; // maximum of token mintable
    bytes32 public DOMAIN_SEPARATOR; // eip-2612 permit() pattern - hash identifies contract
    bytes32 constant public PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"); // eip-2612 permit() pattern - hash identifies function for signature
    string  public details; // details token offering, redemption, etc. - updateable by manager
    string  public name; // fixed token name
    string  public symbol; // fixed token symbol
    bool    public forSale; // status of token sale - e.g., if `false`, ETH sent to token address will not return token per saleRate - updateable by manager
    bool    private initialized; // internally tracks token deployment under eip-1167 proxy pattern
    bool    public transferable; // transferability of token - does not affect token sale - updateable by manager
    
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Redeem(string details);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event UpdateGovernance(address indexed manager, string details);
    event UpdateSale(uint256 saleRate, uint256 saleSupply, bool burnToken, bool forSale);
    event UpdateTransferability(bool transferable);
    
    mapping(address => mapping(address => uint256)) public allowances;
    mapping(address => uint256) public balanceOf;
    mapping(address => uint256) public nonces;
    
    modifier onlyManager {
        require(msg.sender == manager, "!manager");
        _;
    }
    
    function init(
        address payable _manager,
        uint8 _decimals, 
        uint256 _managerSupply, 
        uint256 _saleRate, 
        uint256 _saleSupply, 
        uint256 _totalSupplyCap,
        string calldata _details, 
        string calldata _name, 
        string calldata _symbol,  
        bool _forSale, 
        bool _transferable
    ) external {
        require(!initialized, "initialized"); 
        manager = _manager; 
        decimals = _decimals; 
        saleRate = _saleRate; 
        totalSupplyCap = _totalSupplyCap; 
        details = _details; 
        name = _name; 
        symbol = _symbol;  
        forSale = _forSale; 
        initialized = true; 
        transferable = _transferable; 
        _mint(_manager, _managerSupply);
        _mint(address(this), _saleSupply);
        // eip-2612 permit() pattern:
        uint256 chainId;
        assembly {chainId := chainid()}
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256(bytes(name)),
            keccak256(bytes("1")),
            chainId,
            address(this)));
    }
    
    function _approve(address owner, address spender, uint256 value) internal {
        allowances[owner][spender] = value; 
        emit Approval(owner, spender, value); 
    }
    
    function approve(address spender, uint256 value) external returns (bool) {
        _approve(msg.sender, spender, value);
        return true;
    }
    
    function _burn(address from, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value); 
        totalSupply = totalSupply.sub(value); 
        emit Transfer(from, address(0), value);
    }
    
    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
    
    function burnFrom(address from, uint256 value) external {
        _approve(from, msg.sender, allowances[from][msg.sender].sub(value));
        _burn(from, value);
    }
    
    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool) {
        _approve(msg.sender, spender, allowances[msg.sender][spender].sub(subtractedValue));
        return true;
    }
    
    function increaseAllowance(address spender, uint256 addedValue) external returns (bool) {
        _approve(msg.sender, spender, allowances[msg.sender][spender].add(addedValue));
        return true;
    }
    
    // Adapted from https://github.com/albertocuestacanada/ERC20Permit/blob/master/contracts/ERC20Permit.sol
    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        require(block.timestamp <= deadline, "expired");
        bytes32 hashStruct = keccak256(abi.encode(
                PERMIT_TYPEHASH,
                owner,
                spender,
                value,
                nonces[owner]++,
                deadline));
        bytes32 hash = keccak256(abi.encodePacked(
                '\x19\x01',
                DOMAIN_SEPARATOR,
                hashStruct));
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0) && signer == owner, "!signer");
        _approve(owner, spender, value);
    }
    
    receive() external payable { // SALE 
        require(forSale, "!forSale");
        (bool success, ) = manager.call{value: msg.value}("");
        require(success, "!ethCall");
        _transfer(address(this), msg.sender, msg.value.mul(saleRate));
    } 
    
    function redeem(uint256 value, string calldata _details) external {
        _burn(msg.sender, value);
        emit Redeem(_details);
    }
    
    function _transfer(address from, address to, uint256 value) internal {
        balanceOf[from] = balanceOf[from].sub(value); 
        balanceOf[to] = balanceOf[to].add(value); 
        emit Transfer(from, to, value); 
    }
    
    function transfer(address to, uint256 value) external returns (bool) {
        require(transferable, "!transferable"); 
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function transferBatch(address[] calldata to, uint256[] calldata value) external {
        require(to.length == value.length, "!to/value");
        require(transferable, "!transferable");
        for (uint256 i = 0; i < to.length; i++) {
            _transfer(msg.sender, to[i], value[i]);
        }
    }
    
    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(transferable, "!transferable");
        _approve(from, msg.sender, allowances[from][msg.sender].sub(value));
        _transfer(from, to, value);
        return true;
    }
    
    /****************
    MANAGER FUNCTIONS
    ****************/
    function _mint(address to, uint256 value) internal {
        require(totalSupply.add(value) <= totalSupplyCap, "capped"); 
        balanceOf[to] = balanceOf[to].add(value); 
        totalSupply = totalSupply.add(value); 
        emit Transfer(address(0), to, value); 
    }
    
    function mint(address to, uint256 value) external onlyManager {
        _mint(to, value);
    }
    
    function mintBatch(address[] calldata to, uint256[] calldata value) external onlyManager {
        require(to.length == value.length, "!to/value");
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], value[i]); 
        }
    }
    
    function updateGovernance(address payable _manager, string calldata _details) external onlyManager {
        manager = _manager;
        details = _details;
        emit UpdateGovernance(_manager, _details);
    }

    function updateSale(uint256 _saleRate, uint256 _saleSupply, bool _burnToken, bool _forSale) external onlyManager {
        saleRate = _saleRate;
        forSale = _forSale;
        if (_saleSupply > 0 && _burnToken) {_burn(address(this), _saleSupply);}
        if (_saleSupply > 0 && !_burnToken) {_mint(address(this), _saleSupply);}
        emit UpdateSale(_saleRate, _saleSupply, _burnToken, _forSale);
    }
    
    function updateTransferability(bool _transferable) external onlyManager {
        transferable = _transferable;
        emit UpdateTransferability(_transferable);
    }
    
    function withdrawToken(address[] calldata token, address[] calldata withdrawTo, uint256[] calldata value, bool max) external onlyManager { // withdraw token sent to lextoken contract
        require(token.length == withdrawTo.length && token.length == value.length, "!token/withdrawTo/value");
        for (uint256 i = 0; i < token.length; i++) {
            uint256 withdrawalValue = value[i];
            if (max) {withdrawalValue = IERC20(token[i]).balanceOf(address(this));}
            IERC20(token[i]).transfer(withdrawTo[i], withdrawalValue);
        }
    }
}