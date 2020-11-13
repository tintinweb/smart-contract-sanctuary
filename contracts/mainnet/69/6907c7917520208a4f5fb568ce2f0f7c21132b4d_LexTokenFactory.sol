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
pragma solidity 0.7.0;

library SafeMath {
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
    address public resolver; // account acting as backup for lost token & arbitration of disputed token transfers - updateable by manager
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
    event BalanceResolution(string indexed resolution);
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    mapping(address => mapping(address => uint256)) public allowances;
    mapping(address => uint256) private _balanceOf;
    mapping(address => uint256) public nonces;
    
    modifier onlyManager {
        require(msg.sender == manager, "!manager");
        _;
    }
    
    function init(
        address payable _manager,
        address _resolver,
        uint8 _decimals, 
        uint256 managerSupply, 
        uint256 _saleRate, 
        uint256 saleSupply, 
        uint256 _totalSupplyCap,
        string memory _details, 
        string memory _name, 
        string memory _symbol,  
        bool _forSale, 
        bool _transferable
    ) external {
        require(!initialized, "initialized"); 
        manager = _manager; 
        resolver = _resolver;
        decimals = _decimals; 
        saleRate = _saleRate; 
        totalSupplyCap = _totalSupplyCap; 
        details = _details; 
        name = _name; 
        symbol = _symbol;  
        forSale = _forSale; 
        initialized = true; 
        transferable = _transferable; 
        _balanceOf[address(this)] = type(uint256).max; // trick to prevent token transfer to contract itself
        _mint(manager, managerSupply);
        _mint(address(this), saleSupply);
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
    
    receive() external payable { // SALE 
        require(forSale, "!forSale");
        (bool success, ) = manager.call{value: msg.value}("");
        require(success, "!ethCall");
        uint256 value = msg.value.mul(saleRate); 
        _transfer(address(this), msg.sender, value);
    } 
    
    function _approve(address owner, address spender, uint256 value) internal {
        allowances[owner][spender] = value; 
        emit Approval(owner, spender, value); 
    }
    
    function approve(address spender, uint256 value) external returns (bool) {
        require(value == 0 || allowances[msg.sender][spender] == 0, "!reset"); 
        _approve(msg.sender, spender, value);
        return true;
    }
    
    function balanceOf(address account) external view returns (uint256) {
        return account == address(this) ? 0 : _balanceOf[account];
    }

    function balanceResolution(address from, address to, uint256 value, string memory resolution) external { // resolve disputed or lost balances
        require(msg.sender == resolver, "!resolver"); 
        _transfer(from, to, value); 
        emit BalanceResolution(resolution);
    }
    
    function burn(uint256 value) external {
        _balanceOf[msg.sender] = _balanceOf[msg.sender].sub(value); 
        totalSupply = totalSupply.sub(value); 
        emit Transfer(msg.sender, address(0), value);
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
    
    function _transfer(address from, address to, uint256 value) internal {
        _balanceOf[from] = _balanceOf[from].sub(value); 
        _balanceOf[to] = _balanceOf[to].add(value); 
        emit Transfer(from, to, value); 
    }
    
    function transfer(address to, uint256 value) external returns (bool) {
        require(transferable, "!transferable"); 
        _transfer(msg.sender, to, value);
        return true;
    }
    
    function transferBatch(address[] memory to, uint256[] memory value) external {
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
        _balanceOf[to] = _balanceOf[to].add(value); 
        totalSupply = totalSupply.add(value); 
        emit Transfer(address(0), to, value); 
    }
    
    function mint(address to, uint256 value) external onlyManager {
        _mint(to, value);
    }
    
    function mintBatch(address[] memory to, uint256[] memory value) external onlyManager {
        require(to.length == value.length, "!to/value");
        for (uint256 i = 0; i < to.length; i++) {
            _mint(to[i], value[i]); 
        }
    }
    
    function updateGovernance(address payable _manager, address _resolver, string memory _details) external onlyManager {
        manager = _manager;
        resolver = _resolver;
        details = _details;
    }

    function updateSale(uint256 _saleRate, uint256 saleSupply, bool _forSale) external onlyManager {
        saleRate = _saleRate;
        forSale = _forSale;
        _mint(address(this), saleSupply);
    }
    
    function updateTransferability(bool _transferable) external onlyManager {
        transferable = _transferable;
    }
}

/*
The MIT License (MIT)
Copyright (c) 2018 Murray Software, LLC.
Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:
The above copyright notice and this permission notice shall be included
in all copies or substantial portions of the Software.
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
contract CloneFactory {
    function createClone(address payable target) internal returns (address payable result) { // eip-1167 proxy pattern adapted for payable lexToken
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
}

interface IERC20Transfer { // brief interface for erc20 token transfer
    function transfer(address recipient, uint256 value) external returns (bool);
}

contract LexTokenFactory is CloneFactory {
    address payable public lexDAO;
    address public lexDAOtoken;
    address payable immutable public template;
    uint256 public userReward;
    string  public details;
    
    event LaunchLexToken(address indexed lexToken, address indexed manager, address indexed resolver, uint256 saleRate, bool forSale);
    event UpdateGovernance(address indexed lexDAO, address indexed lexDAOtoken, uint256 indexed userReward, string details);
    
    constructor(address payable _lexDAO, address _lexDAOtoken, address payable _template, uint256 _userReward, string memory _details) {
        lexDAO = _lexDAO;
        lexDAOtoken = _lexDAOtoken;
        template = _template;
        userReward = _userReward;
        details = _details;
    }
    
    function launchLexToken(
        address payable _manager,
        address _resolver,
        uint8 _decimals, 
        uint256 managerSupply, 
        uint256 _saleRate, 
        uint256 saleSupply, 
        uint256 _totalSupplyCap,
        string memory _details,
        string memory _name, 
        string memory _symbol, 
        bool _forSale, 
        bool _transferable
    ) external payable {
        LexToken lex = LexToken(createClone(template));
        
        lex.init(
            _manager,
            _resolver,
            _decimals, 
            managerSupply, 
            _saleRate, 
            saleSupply, 
            _totalSupplyCap,
            _details,
            _name, 
            _symbol, 
            _forSale, 
            _transferable);
        
        (bool success, ) = lexDAO.call{value: msg.value}("");
        require(success, "!ethCall");
        IERC20Transfer(lexDAOtoken).transfer(_manager, userReward);
        emit LaunchLexToken(address(lex), _manager, _resolver, _saleRate, _forSale);
    }
    
    function updateGovernance(address payable _lexDAO, address _lexDAOtoken, uint256 _userReward, string memory _details) external {
        require(msg.sender == lexDAO, "!lexDAO");
        lexDAO = _lexDAO;
        lexDAOtoken = _lexDAOtoken;
        userReward = _userReward;
        details = _details;
        emit UpdateGovernance(_lexDAO, _lexDAOtoken, _userReward, _details);
    }
}