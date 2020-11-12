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

contract ReentrancyGuard { 
    bool private _notEntered; 
    
    function _initReentrancyGuard() internal {
        _notEntered = true;
    } 
}

contract LexTokenLite is ReentrancyGuard {
    using SafeMath for uint256;
    
    address payable public owner;
    address public resolver;
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public saleRate;
    uint256 public totalSupply;
    uint256 public totalSupplyCap;
    bytes32 public message;
    bool public forSale;
    bool private initialized;
    bool public transferable; 
    
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Transfer(address indexed from, address indexed to, uint256 amount);
    
    mapping(address => mapping(address => uint256)) public allowances;
    mapping(address => uint256) private balances;
    
    modifier onlyOwner {
        require(msg.sender == owner, "!owner");
        _;
    }
    
    function init(
        string calldata _name, 
        string calldata _symbol, 
        uint8 _decimals, 
        address payable _owner, 
        address _resolver, 
        uint256 ownerSupply, 
        uint256 _saleRate, 
        uint256 saleSupply, 
        uint256 _totalSupplyCap, 
        bytes32 _message, 
        bool _forSale, 
        bool _transferable
    ) external {
        require(!initialized, "initialized"); 
        require(ownerSupply.add(saleSupply) <= _totalSupplyCap, "capped");
        
        name = _name; 
        symbol = _symbol; 
        decimals = _decimals; 
        owner = _owner; 
        resolver = _resolver;
        saleRate = _saleRate; 
        totalSupplyCap = _totalSupplyCap; 
        message = _message; 
        forSale = _forSale; 
        initialized = true; 
        transferable = _transferable; 
        balances[owner] = balances[owner].add(ownerSupply);
        balances[address(this)] = balances[address(this)].add(saleSupply);
        totalSupply = ownerSupply.add(saleSupply);
        
        emit Transfer(address(0), owner, ownerSupply);
        emit Transfer(address(0), address(this), saleSupply);
        _initReentrancyGuard(); 
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
    
    function balanceOf(address account) external view returns (uint256) {
        return balances[account];
    }
    
    function balanceResolution(address sender, address recipient, uint256 amount) external returns (bool) {
        require(msg.sender == resolver, "!resolver"); 
        
        _transfer(sender, recipient, amount); 
        
        return true;
    }
    
    function burn(uint256 amount) external {
        balances[msg.sender] = balances[msg.sender].sub(amount); 
        totalSupply = totalSupply.sub(amount); 
        
        emit Transfer(msg.sender, address(0), amount);
    }
    
    function _transfer(address sender, address recipient, uint256 amount) internal {
        balances[sender] = balances[sender].sub(amount); 
        balances[recipient] = balances[recipient].add(amount); 
        
        emit Transfer(sender, recipient, amount); 
    }
    
    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(transferable, "!transferable"); 
        
        _transfer(msg.sender, recipient, amount);
        
        return true;
    }
    
    function transferBatch(address[] calldata recipient, uint256[] calldata amount) external returns (bool) {
        require(transferable, "!transferable");
        require(recipient.length == amount.length, "!recipient/amount");
        
        for (uint256 i = 0; i < recipient.length; i++) {
            _transfer(msg.sender, recipient[i], amount[i]);
        }
        
        return true;
    }
    
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(transferable, "!transferable");
        
        _transfer(sender, recipient, amount);
        allowances[sender][msg.sender] = allowances[sender][msg.sender].sub(amount); 
        
        return true;
    }
    
    /**************
    OWNER FUNCTIONS
    **************/
    function mint(address recipient, uint256 amount) external onlyOwner {
        require(totalSupply.add(amount) <= totalSupplyCap, "capped"); 
        
        balances[recipient] = balances[recipient].add(amount); 
        totalSupply = totalSupply.add(amount); 
        
        emit Transfer(address(0), recipient, amount); 
    }
    
    function mintBatch(address[] calldata recipient, uint256[] calldata amount) external onlyOwner {
        require(recipient.length == amount.length, "!recipient/amount");
        
        for (uint256 i = 0; i < recipient.length; i++) {
            balances[recipient[i]] = balances[recipient[i]].add(amount[i]); 
            totalSupply = totalSupply.add(amount[i]);
            emit Transfer(address(0), recipient[i], amount[i]); 
        }
        
        require(totalSupply <= totalSupplyCap, "capped");
    }

    function updateMessage(bytes32 _message) external onlyOwner {
        message = _message;
    }
    
    function updateOwner(address payable _owner) external onlyOwner {
        owner = _owner;
    }
    
    function updateResolver(address _resolver) external onlyOwner {
        resolver = _resolver;
    }
    
    function updateSale(uint256 amount, bool _forSale) external onlyOwner {
        require(totalSupply.add(amount) <= totalSupplyCap, "capped");
        
        forSale = _forSale;
        balances[address(this)] = balances[address(this)].add(amount); 
        totalSupply = totalSupply.add(amount); 
        
        emit Transfer(address(0), address(this), amount);
    }
    
    function updateSaleRate(uint256 _saleRate) external onlyOwner {
        saleRate = _saleRate;
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
    function createClone(address payable target) internal returns (address payable result) {
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

contract LexTokenLiteFactory is CloneFactory {
    address payable public lexDAO;
    address payable public template;
    bytes32 public message;
    
    constructor (address payable _lexDAO, address payable _template, bytes32 _message) public {
        lexDAO = _lexDAO;
        template = _template;
        message = _message;
    }
    
    function LaunchLexTokenLite(
        string memory _name, 
        string memory _symbol, 
        uint8 _decimals, 
        address payable _owner, 
        address _resolver,
        uint256 ownerSupply,
        uint256 _saleRate,
        uint256 saleSupply,
        uint256 _totalSupplyCap,
        bytes32 _message,
        bool _forSale,
        bool _transferable
    ) payable public returns (address) {
        LexTokenLite lexLite = LexTokenLite(createClone(template));
        
        lexLite.init(
            _name, 
            _symbol,
            _decimals, 
            _owner, 
            _resolver,
            ownerSupply, 
            _saleRate, 
            saleSupply, 
            _totalSupplyCap, 
            _message, 
            _forSale, 
            _transferable);
        
        (bool success, ) = lexDAO.call.value(msg.value)("");
        require(success, "!transfer");

        return address(lexLite);
    }
    
    function updateLexDAO(address payable _lexDAO) external {
        require(msg.sender == lexDAO, "!lexDAO");
        
        lexDAO = _lexDAO;
    }
    
    function updateMessage(bytes32 _message) external {
        require(msg.sender == lexDAO, "!lexDAO");
        
        message = _message;
    }
}