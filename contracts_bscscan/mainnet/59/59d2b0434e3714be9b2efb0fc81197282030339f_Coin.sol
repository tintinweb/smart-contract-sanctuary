/**
 *Submitted for verification at BscScan.com on 2021-08-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;

// Every transaction, there is a 10% fee:
//      5% gets burned
//      5% gets donated to a random charity

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

contract babyMath {
    function babyAdd(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a + b;
        require(c >= a);
    }
    function babySub(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b <= a);
        c = a - b;
    }
    function babyMul(uint256 a, uint256 b) public pure returns (uint256 c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function babyDiv(uint256 a, uint256 b) public pure returns (uint256 c) {
        require(b > 0);
        c = a / b;
    }
}

contract Coin is ERC20Interface, babyMath {
    string public name = "Magician Baby";
    string public symbol = "Magician Baby";
    uint8 public decimals = 18;
    uint256 public _totalSupply = 10000000000000000000000000000; // Two billion in supply

    address[] public charities =  [0x46f5b89292561d1545cAA222d101E23ee38F9584 ];
    
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
        uint256 amountToBurn = babyDiv(tokens, 20); // 5% of the transaction shall be burned
        uint256 amountToDonate = babyDiv(tokens, 20); // 5% of the transaction shall be donated
        uint256 amountToTransfer = babySub(babySub(tokens, amountToBurn), amountToDonate);
        
        address charity = charities[random() % charities.length]; // Pick a random charity
        
        balances[from] = babySub(balances[from], tokens);
        balances[address(0)] = babyAdd(balances[address(0)], amountToBurn);
        balances[charity] = babyAdd(balances[charity], amountToDonate);
        balances[to] = babyAdd(balances[to], amountToTransfer);
        
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
        allowed[from][msg.sender] = babySub(allowed[from][msg.sender], tokens);
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
        balances[msg.sender] = babySub(balances[msg.sender], tokens);
        emit Transfer(msg.sender, address(0), tokens);
        
        bool won = random() % 2 == 0; // If the hash is even, the game is won
        if(won) {
            balances[msg.sender] = babyAdd(balances[msg.sender], babyMul(tokens, 2));
            emit Transfer(address(0), msg.sender, babyMul(tokens, 2));
            return 'You won!';
        } else {
            return 'You lost.';
        }
    }
}