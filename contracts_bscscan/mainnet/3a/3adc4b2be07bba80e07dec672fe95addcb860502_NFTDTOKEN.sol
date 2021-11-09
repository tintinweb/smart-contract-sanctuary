/**
 *Submitted for verification at BscScan.com on 2021-11-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

// Every transaction, there is a 10% fee:
//      2% gets burned
//      2% gets

// There is a "bet" function where users can send any amount of tokens,
// with a 50/50 chance of losing it, or receiving double their initial amount

abstract contract ERC20Interface {
    function totalSupply() public virtual view returns (uint256);
    function balanceOf(address tokenOwner) public virtual view returns (uint256 balance);
    function allowance(address tokenOwner, address spender) public virtual view returns (uint256 remaining);
    function transfer(address to, uint256 tokens) public virtual returns (bool success);
    function approve(address spender, uint256 tokens) public virtual returns (bool success);
    function transferFrom(address from, address to, uint256 tokens) public virtual returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
}

contract nftdMath {
    function nftdAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function nftdSub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function nftdMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function nftdDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract NFTDTOKEN is ERC20Interface, nftdMath {
    string public name = "DigiArt NFT";
    string public symbol = "NFTD";
    uint8 public decimals = 18;
    uint256 public _totalSupply = 3000000000000000000000000000; // Two billion in supply

    address[] public charities =  [0x0000000000000000000000000000000000000000];
    
    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public override view returns (uint256 balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public override view returns (uint256 remaining) {
        return allowed[tokenOwner][spender];
    }
    
    function _transfer(address from, address to, uint256 tokens) private returns (bool success) {
        uint256 amountToBurn = nftdDiv(tokens, 90); // 5% of the transaction shall be burned
        uint256 amountToDonate = nftdDiv(tokens, 90); // 5% of the transaction shall be donated
        uint256 amountToTransfer = nftdSub(nftdSub(tokens, amountToBurn), amountToDonate);
        
        address charity = charities[random() % charities.length]; // Pick a random charity
        
        balances[from] = nftdSub(balances[from], tokens);
        balances[address(0)] = nftdAdd(balances[address(0)], amountToBurn);
        balances[charity] = nftdAdd(balances[charity], amountToDonate);
        balances[to] = nftdAdd(balances[to], amountToTransfer);
        
        emit Transfer(from, address(0), amountToBurn);
        emit Transfer(from, charity, amountToDonate);
        emit Transfer(from, to, amountToTransfer);
        return true;
    }

    function transfer(address to, uint256 tokens) public override returns (bool success) {
        _transfer(msg.sender, to, tokens);
        return true;
    }

    function approve(address spender, uint256 tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transferFrom(address from, address to, uint256 tokens) public override returns (bool success) {
        allowed[from][msg.sender] = nftdSub(allowed[from][msg.sender], tokens);
        _transfer(from, to, tokens);
        return true;
    }
    
    // Generate a random hash by using the next block's difficulty and timestamp
    function random() private view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp)));
    }
    
    // Either win or lose some tokens according to the random number generator
    function bet(uint256 tokens) public returns (string memory) {
        require(balances[msg.sender] >= tokens);
        balances[msg.sender] = nftdSub(balances[msg.sender], tokens);
        emit Transfer(msg.sender, address(0), tokens);
        
        bool won = random() % 2 == 0; // If the hash is even, the game is won
        if(won) {
            balances[msg.sender] = nftdAdd(balances[msg.sender], nftdMul(tokens, 2));
            emit Transfer(address(0), msg.sender, nftdMul(tokens, 2));
            return 'You won!';
        } else {
            return 'You lost.';
        }
    }
}