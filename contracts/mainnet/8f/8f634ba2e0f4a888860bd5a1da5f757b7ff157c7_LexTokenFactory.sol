pragma solidity 0.5.17;

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
    address payable public owner;
    address public resolver;
    uint8 public decimals;
    uint256 public saleRate;
    uint256 public totalSupply;
    uint256 public totalSupplyCap;
    string public message;
    string public name;
    string public symbol;
    bool public forSale;
    bool private initialized;
    bool public transferable; 
    
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event BalanceResolution(string indexed details);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    
    mapping(address => mapping(address => uint256)) public allowances;
    mapping(address => uint256) public balanceOf;
    
    modifier onlyOwner {
        require(msg.sender == owner, "!owner");
        _;
    }
    
    function init(
        address payable _owner,
        address _resolver,
        uint8 _decimals, 
        uint256 ownerSupply, 
        uint256 _saleRate, 
        uint256 saleSupply, 
        uint256 _totalSupplyCap,
        string calldata _message, 
        string calldata _name, 
        string calldata _symbol,  
        bool _forSale, 
        bool _transferable
    ) external {
        require(!initialized, "initialized"); 
        require(ownerSupply.add(saleSupply) <= _totalSupplyCap, "capped");
        owner = _owner; 
        resolver = _resolver;
        decimals = _decimals; 
        saleRate = _saleRate; 
        totalSupplyCap = _totalSupplyCap; 
        message = _message; 
        name = _name; 
        symbol = _symbol;  
        forSale = _forSale; 
        initialized = true; 
        transferable = _transferable; 
        balanceOf[owner] = ownerSupply;
        balanceOf[address(this)] = saleSupply;
        totalSupply = ownerSupply.add(saleSupply);
        emit Transfer(address(0), owner, ownerSupply);
        emit Transfer(address(0), address(this), saleSupply);
    }
    
    function() external payable { // SALE 
        require(forSale, "!forSale");
        (bool success, ) = owner.call.value(msg.value)("");
        require(success, "!transfer");
        uint256 amount = msg.value.mul(saleRate); 
        _transfer(address(this), msg.sender, amount);
    } 
    
    function approve(address spender, uint256 amount) external returns (bool) {
        require(amount == 0 || allowances[msg.sender][spender] == 0, "!reset"); 
        allowances[msg.sender][spender] = amount; 
        emit Approval(msg.sender, spender, amount); 
        return true;
    }

    function balanceResolution(address from, address to, uint256 amount, string calldata details) external { // resolve disputed or lost balances
        require(msg.sender == resolver, "!resolver"); 
        _transfer(from, to, amount); 
        emit BalanceResolution(details);
    }
    
    function burn(uint256 amount) external {
        balanceOf[msg.sender] = balanceOf[msg.sender].sub(amount); 
        totalSupply = totalSupply.sub(amount); 
        emit Transfer(msg.sender, address(0), amount);
    }
    
    function _transfer(address from, address to, uint256 amount) internal {
        balanceOf[from] = balanceOf[from].sub(amount); 
        balanceOf[to] = balanceOf[to].add(amount); 
        emit Transfer(from, to, amount); 
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        require(transferable, "!transferable"); 
        _transfer(msg.sender, to, amount);
        return true;
    }
    
    function transferBatch(address[] calldata to, uint256[] calldata amount) external {
        require(to.length == amount.length, "!to/amount");
        for (uint256 i = 0; i < to.length; i++) {
            transfer(to[i], amount[i]);
        }
    }
    
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(transferable, "!transferable");
        allowances[from][msg.sender] = allowances[from][msg.sender].sub(amount); 
        _transfer(from, to, amount);
        return true;
    }
    
    /**************
    OWNER FUNCTIONS
    **************/
    function mint(address to, uint256 amount) public onlyOwner {
        require(totalSupply.add(amount) <= totalSupplyCap, "capped"); 
        balanceOf[to] = balanceOf[to].add(amount); 
        totalSupply = totalSupply.add(amount); 
        emit Transfer(address(0), to, amount); 
    }
    
    function mintBatch(address[] calldata to, uint256[] calldata amount) external onlyOwner {
        require(to.length == amount.length, "!to/amount");
        for (uint256 i = 0; i < to.length; i++) {
            mint(to[i], amount[i]);
        }
    }
    
    function updateGovernance(address payable _owner, address _resolver, string calldata _message) external onlyOwner {
        owner = _owner;
        resolver = _resolver;
        message = _message;
    }

    function updateSale(uint256 amount, uint256 _saleRate, bool _forSale) external onlyOwner {
        saleRate = _saleRate;
        forSale = _forSale;
        mint(address(this), amount);
    }
    
    function updateTransferability(bool _transferable) external onlyOwner {
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
    function createClone(address payable target) internal returns (address payable result) { // adapted for payable lexToken
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

contract LexTokenFactory is CloneFactory {
    address payable public lexDAO;
    address payable public template;
    string public message;
    
    event LaunchLexToken(address indexed lexToken, address indexed owner, address indexed resolver, bool forSale);
    event UpdateGovernance(address indexed lexDAO, string indexed message);
    
    constructor (address payable _lexDAO, address payable _template, string memory _message) public {
        lexDAO = _lexDAO;
        template = _template;
        message = _message;
    }
    
    function launchLexToken(
        address payable _owner,
        address _resolver,
        uint8 _decimals, 
        uint256 ownerSupply, 
        uint256 _saleRate, 
        uint256 saleSupply, 
        uint256 _totalSupplyCap,
        string memory _message,
        string memory _name, 
        string memory _symbol, 
        bool _forSale, 
        bool _transferable
    ) payable public {
        LexToken lex = LexToken(createClone(template));
        
        lex.init(
            _owner,
            _resolver,
            _decimals, 
            ownerSupply, 
            _saleRate, 
            saleSupply, 
            _totalSupplyCap,
            _message,
            _name, 
            _symbol, 
            _forSale, 
            _transferable);
        
        (bool success, ) = lexDAO.call.value(msg.value)("");
        require(success, "!transfer");
        emit LaunchLexToken(address(lex), _owner, _resolver, _forSale);
    }
    
    function updateGovernance(address payable _lexDAO, string calldata _message) external {
        require(msg.sender == lexDAO, "!lexDAO");
        lexDAO = _lexDAO;
        message = _message;
        emit UpdateGovernance(lexDAO, message);
    }
}