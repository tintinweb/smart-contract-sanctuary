/**
 *Submitted for verification at Etherscan.io on 2021-09-25
*/

pragma solidity 0.8.7;

// ----------------------------------------------------------------------------
// ERC20 token contract 
// ----------------------------------------------------------------------------
// SPDX-License-Identifier: MIT
// ----------------------------------------------------------------------------

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) { c = a + b; require(c >= a); }
    function sub(uint a, uint b) internal pure returns (uint c) { require(b <= a); c = a - b; }
    function mul(uint a, uint b) internal pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); }
    function div(uint a, uint b) internal pure returns (uint c) { require(b > 0); c = a / b; }
}

interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenOwner) external view returns (uint);
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
    function transfer(address to, uint tokens) external returns (bool success);
    function approve(address spender, uint tokens) external returns (bool success);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function symbol() external view returns (string memory);
    function name() external view returns (string memory);
    function decimals() external view returns (uint8);
    function burn(address tokenAddress) external returns (bool success);
    function mint(address tokenAddress, uint256 tokens) external returns (bool success);
}

interface ApproveAndCallFallBack {
    function receiveApproval(address from, uint tokens, address token, bytes memory data) external;
}

interface ERC721Interface {
  function approve(address to, uint256 tokenId) external;
  function safeTransferFrom(address from, address to, uint256 tokenId) external;
  function tokenURI(uint256 tokenId) external view returns (string memory);
  function symbol() external view returns (string memory);
  function name() external view returns (string memory);
}

interface IERC721Receiver {
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address transferOwner) public onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

// ----------------------------------------------------------------------------
// ERC20 Token 
// ----------------------------------------------------------------------------
contract ERC20 is Owned {
    using SafeMath for uint;

    bool public running = true;
    string public symbol;
    string public name;
    address public ERC721tokenCONTRACT;
    uint256 public ERC721tokenID;
    string public ERC721tokenURI;
    uint8 public decimals;
    uint _totalSupply;

    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;
    
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

    constructor(string memory _symbol, 
                string memory _name, 
                address _contractAddress, 
                uint256 _tokenId, 
                string memory _tokenURI, 
                uint8 _decimals) {
        symbol = _symbol;
        name = _name;
        ERC721tokenCONTRACT = _contractAddress;
        ERC721tokenID = _tokenId;
        ERC721tokenURI = _tokenURI;
        decimals = _decimals;
    }

    function totalSupply() public view returns (uint) {
        return _totalSupply;
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return balances[tokenOwner];
    }

    function transfer(address to, uint tokens) public returns (bool success) {
        require(tokens <= balances[msg.sender]);
        require(to != address(0));
        _transfer(msg.sender, to, tokens);
        return true;
    }

    function _transfer(address from, address to, uint256 tokens) internal {
        balances[from] = balances[from].sub(tokens);
        balances[to] = balances[to].add(tokens);
        emit Transfer(from, to, tokens);
    }

    function approve(address spender, uint tokens) public returns (bool success) {
        _approve(msg.sender, spender, tokens);
        return true;
    }

    function increaseAllowance(address spender, uint addedTokens) public returns (bool success) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].add(addedTokens));
        return true;
    }

    function decreaseAllowance(address spender, uint subtractedTokens) public returns (bool success) {
        _approve(msg.sender, spender, allowed[msg.sender][spender].sub(subtractedTokens));
        return true;
    }

    function approveAndCall(address spender, uint tokens, bytes memory data) public returns (bool success) {
        _approve(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, address(this), data);
        return true;
    }

    function _approve(address owner, address spender, uint256 value) internal {
        require(owner != address(0));
        require(spender != address(0));
        allowed[owner][spender] = value;
        emit Approval(owner, spender, value);
    }

    function transferFrom(address from, address to, uint tokens) public returns (bool success) {
        require(to != address(0));
        _approve(from, msg.sender, allowed[from][msg.sender].sub(tokens));
        _transfer(from, to, tokens);
        return true;
    }

    function allowance(address tokenOwner, address spender) public view returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function burn(address tokenAddress) public onlyOwner returns (bool success) {
        require(balances[tokenAddress] > 0);
        emit Transfer(tokenAddress, address(0), balances[tokenAddress]);
        _totalSupply = _totalSupply.sub(balances[tokenAddress]);
        balances[tokenAddress] = balances[tokenAddress].sub(balances[tokenAddress]);
        return true;
    }

    function mint(address tokenAddress, uint256 tokens) public onlyOwner returns (bool success) {
        balances[tokenAddress] = balances[tokenAddress].add(tokens);
        _totalSupply = _totalSupply.add(tokens);
        emit Transfer(address(0), tokenAddress, tokens);
        return true;
    } 

    function multiTransfer(address[] memory to, uint[] memory values) public returns (uint) {
        require(to.length == values.length);
        require(to.length < 100);
        uint sum;
        for (uint j; j < values.length; j++) {
            sum += values[j];
        }
        require(sum <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(sum);
        for (uint i; i < to.length; i++) {
            balances[to[i]] = balances[to[i]].add(values[i]);
            emit Transfer(msg.sender, to[i], values[i]);
        }
        return(to.length);
    }
}

contract ERC721Split is Owned {
    using SafeMath for uint;
    
    uint8 decimals = 0;
    string name = "WERC721";
    address erc20contract;

    event Split(address contractAddress, uint256 tokenId, address ercAddress, uint256 time);
    event Constructor(address ERC20contractAddress, string _symbol, string _name, address _contractAddress, uint256 _tokenId, string _tokenURI, uint8 _decimals);
    
    struct SplitInfo {
        address addr721;
        uint256 tokenId;
    }
    mapping (address => SplitInfo) ByERC20contract;
    mapping(address => address[]) byOwner;
    
    function getAllERC20byAddress(address tokenOwner) public view returns (address[] memory) {
        return byOwner[tokenOwner];
    }
    
    mapping(address => mapping(uint256 => address)) public getERC20contract;
    
    function fragmentation(address contractAddress, uint256 tokenId, uint256 splitAmount) public returns (address ERC20contract) { 
        require(splitAmount <= 1000000000000, 'MUST BE LESS THAN TRILLION');
        require(splitAmount != 0, 'MUST BE NOT ZERO');
        require(contractAddress != address(0), 'ZERO ADDRESS');
        ERC721Interface(contractAddress).safeTransferFrom(msg.sender, address(this), tokenId);
        if (getERC20contract[contractAddress][tokenId] == address(0)) { // CREATE2
            bytes memory bytecode = abi.encodePacked(type(ERC20).creationCode, abi.encode(
                ERC721Interface(contractAddress).symbol(), 
                name, 
                contractAddress, 
                tokenId, 
                ERC721Interface(contractAddress).tokenURI(tokenId), 
                decimals));
            bytes32 salt = keccak256(abi.encodePacked(contractAddress, tokenId, address(this)));
            erc20contract = deploy(bytecode, salt);
            emit Constructor(erc20contract, ERC721Interface(contractAddress).symbol(), name, contractAddress, tokenId, ERC721Interface(contractAddress).tokenURI(tokenId), decimals);
        } else {
            erc20contract = getERC20contract[contractAddress][tokenId];
        }
        require(ERC20Interface(erc20contract).mint(msg.sender, splitAmount));
        ByERC20contract[erc20contract].addr721 = contractAddress;
        ByERC20contract[erc20contract].tokenId = tokenId;
        getERC20contract[contractAddress][tokenId] = erc20contract;
        emit Split(contractAddress, tokenId, erc20contract, block.timestamp);
        byOwner[msg.sender].push(erc20contract);
        return (erc20contract);
    }
    
    function defragmentation(address ERC20contract) public returns (bool success) {
        require(ERC20Interface(ERC20contract).balanceOf(msg.sender) == ERC20Interface(ERC20contract).totalSupply());
        require(ERC20Interface(ERC20contract).burn(msg.sender));
        ERC721Interface(ByERC20contract[ERC20contract].addr721).safeTransferFrom(address(this), msg.sender, ByERC20contract[ERC20contract].tokenId);
        for (uint i; i < byOwner[msg.sender].length - 1; i++) { if (byOwner[msg.sender][i] == ERC20contract) { delete byOwner[msg.sender][i]; } }
        return true;
    }
    
    function deploy(bytes memory code, bytes32 salt) internal returns (address addr) {
    assembly {
        addr := create2(0, add(code, 0x20), mload(code), salt)
        if iszero(extcodesize(addr)) { revert(0, 0) }
        }
    }
    
    function getERC721contract(address ERC20contract) public view returns (address ERC721contractAddress, uint256 tokenId) {
        return (ByERC20contract[ERC20contract].addr721, ByERC20contract[ERC20contract].tokenId);
    }

    function onERC721Received(address, address, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }

}