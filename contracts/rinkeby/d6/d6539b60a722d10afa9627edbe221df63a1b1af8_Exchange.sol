/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath : subtraction overflow");
        uint256 c = a - b;
        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, 'SafeMath: division by zero');
        uint256 c = a / b;
        return c;
    }
}
interface Token {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address _to, uint256 _amount) external returns(bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function mint(address _to, uint256 _amount) external;
    function burn(address _to, uint256 _amount) external;
}
contract Exchange {
    event Order(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, uint256 expires, uint256 nonce, address user, uint8 v, bytes32 r, bytes32 s);
    event Cancel(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, uint256 expires, uint256 nonce, address user, uint8 v, bytes32 r, bytes32 s);
    event Trade(address tokenBuy, uint256 amountBuy, address tokenSell, uint256 amountSell, address get, address give);
    event Deposit(address token, address user, uint256 amount, uint256 balance);
    event Withdraw(address token, address user, uint256 amount, uint256 balance);
    using SafeMath for uint256;
    address public owner;
    address public feeAccount;
    function safeMul(uint a, uint b) internal pure returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
    function safeSub(uint a, uint b) internal pure returns (uint) {
    assert(b <= a);
    return a - b;
  }
    function safeAdd(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    assert(c>=a && c>=b);
    return c;
  }

    mapping (address => uint256) public invalidOrder;
    mapping (address => mapping (address => uint256)) public tokens; 
    mapping (bytes32 => bool) public traded;
    mapping (bytes32 => bool) public withdrawn;
    mapping (bytes32 => uint256) public orderFills;
    
    function exchange(address feeAccount_) public {
    owner = msg.sender;
    feeAccount = feeAccount_;
  }
    function depositToken(address token, uint256 amount) public {
        require(amount>0,"Amount must be greater than zero");
        require(token!=address(0),"Invalid address");
        tokens[token][msg.sender] = safeAdd(tokens[token][msg.sender], amount);
        Token(token).transferFrom(msg.sender, address(this), amount); 
        emit Deposit(token, msg.sender, amount, tokens[token][msg.sender]);
  }
    function deposit() public payable {
        require(msg.value>0,"Value must be greater than zero");
        tokens[address(0)][msg.sender] = safeAdd(tokens[address(0)][msg.sender], msg.value);
        emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
    }
    function withdraw(address token, uint256 amount) public {
        require(amount>0,"Amount must be greater than zero");
        require(tokens[token][msg.sender] >= amount,"Not Enough balance");
        tokens[token][msg.sender] = safeSub(tokens[token][msg.sender], amount);
        if (token == address(0)) {
          payable(msg.sender).transfer(amount);
        } 
        else {
          Token(token).transfer(msg.sender, amount);
        }
        emit Withdraw(token, msg.sender, amount, tokens[token][msg.sender]);
        }
    modifier onlyAdmin {
        require(msg.sender==owner,"Only owner can access");
    _;
  }
    
    /*function adminWithdraw(address token, uint256 amount, address user, uint256 nonce, uint8 v, bytes32 r, bytes32 s, uint256 feeWithdrawal) public onlyAdmin {
        bytes32 hash = keccak256(abi.encodePacked(this, token, amount, user, nonce));
        require(withdrawn[hash]==false);
        withdrawn[hash] = true;
        require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)),v,r,s) == user);
        if (feeWithdrawal > 50000000000000000 wei) feeWithdrawal = 50000000000000000 wei ;
        require(tokens[token][user] >= amount);
        tokens[token][user] = safeSub(tokens[token][user], amount);
        tokens[token][feeAccount] = safeAdd(tokens[token][feeAccount], safeMul(feeWithdrawal, amount) / 1 ether);
        amount = safeMul((1 ether - feeWithdrawal), amount) / 1 ether;
        if (token == address(0)) {
          payable(user).transfer(amount);
        } else {
            Token(token).transfer(user, amount);
        }
        emit Withdraw(token, user, amount, tokens[token][user]);
  }*/
  
  function adminWithdraw(address token, uint256 amount, address user, uint256 nonce, uint256 feeWithdrawal) public onlyAdmin {
        bytes32 hash = keccak256(abi.encodePacked(this, token, amount, user, nonce));
        require(withdrawn[hash]==false);
        withdrawn[hash] = true;
        if (feeWithdrawal > 50000000000000000 wei) feeWithdrawal = 50000000000000000 wei ;
        require(tokens[token][user] >= amount);
        tokens[token][user] = safeSub(tokens[token][user], amount);
        tokens[token][feeAccount] = safeAdd(tokens[token][feeAccount], safeMul(feeWithdrawal, amount) / 1 ether);
        amount = safeMul((1 ether - feeWithdrawal), amount) / 1 ether;
        if (token == address(0)) {
          payable(user).transfer(amount);
        } else {
            Token(token).transfer(user, amount);
        }
        emit Withdraw(token, user, amount, tokens[token][user]);
  }

    
    function invalidateOrdersBefore(address user, uint256 nonce) public onlyAdmin {
    require(nonce > invalidOrder[user]);
    invalidOrder[user] = nonce;
    }
    
    /*function trade(uint256[8] memory tradeValues, address[4] memory tradeAddresses, uint8[2] memory v, bytes32[4] memory rs) public onlyAdmin {
       [0] amountBuy
       [1] amountSell
       [2] expires
       [3] nonce
       [4] amount
       [5] tradeNonce
       [6] feeMake
       [7] feeTake
     tradeAddressses
       [0] tokenBuy
       [1] tokenSell
       [2] maker
       [3] taker
        require(invalidOrder[tradeAddresses[2]] < tradeValues[3]);
        bytes32 orderHash = keccak256(abi.encodePacked(this, tradeAddresses[0], tradeValues[0], tradeAddresses[1], tradeValues[1], tradeValues[2], tradeValues[3], tradeAddresses[2]));
        require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", orderHash)), v[0], rs[0], rs[1]) == tradeAddresses[2]);
        bytes32 tradeHash = keccak256(abi.encodePacked(orderHash, tradeValues[4], tradeAddresses[3], tradeValues[5])); 
        require(ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", tradeHash)), v[1], rs[2], rs[3]) == tradeAddresses[3]);
        require(traded[tradeHash]==false);
        traded[tradeHash] = true;
        if (tradeValues[6] > 100) tradeValues[6] = 100;
        if (tradeValues[7] > 100) tradeValues[7] = 100;
        require (orderFills[orderHash].add(tradeValues[4]) <= tradeValues[0]);
        require(tokens[tradeAddresses[0]][tradeAddresses[3]] >= tradeValues[4]);
        require(tokens[tradeAddresses[1]][tradeAddresses[2]] >= (tradeValues[1].mul(tradeValues[4]) / tradeValues[0]));
        tokens[tradeAddresses[0]][tradeAddresses[3]] = tokens[tradeAddresses[0]][tradeAddresses[3]].sub(tradeValues[4]);
        tokens[tradeAddresses[0]][tradeAddresses[2]] = tokens[tradeAddresses[0]][tradeAddresses[2]].add(tradeValues[4].mul(((1 ether) - tradeValues[6])) / (1 ether));
        tokens[tradeAddresses[0]][feeAccount] = tokens[tradeAddresses[0]][feeAccount].add(tradeValues[4].mul(tradeValues[6]) / (1 ether));
        tokens[tradeAddresses[1]][tradeAddresses[2]] = tokens[tradeAddresses[1]][tradeAddresses[2]].sub(tradeValues[1].mul(tradeValues[4]) / tradeValues[0]);
        tokens[tradeAddresses[1]][tradeAddresses[3]] = tokens[tradeAddresses[1]][tradeAddresses[3]].add(((1 ether) - tradeValues[7]).mul(tradeValues[1]).mul(tradeValues[4]) / tradeValues[0] / (1 ether));
        tokens[tradeAddresses[1]][feeAccount] = tokens[tradeAddresses[1]][feeAccount].add(tradeValues[7].mul(tradeValues[1]).mul(tradeValues[4]) / tradeValues[0] / (1 ether));
        orderFills[orderHash] = orderFills[orderHash].add(tradeValues[4]);
    }*/

    function trade(uint256[6] memory tradeValues, address[4] memory tradeAddresses) public onlyAdmin {
     /*[0] amountBuy
       [1] amountSell
       [2] expires
       [3] amount
       [4] feeMake
       [5] feeTake
     tradeAddressses
       [0] tokenBuy
       [1] tokenSell
       [2] maker
       [3] taker*/
        bytes32 orderHash = keccak256(abi.encodePacked(this, tradeAddresses[0], tradeValues[0], tradeAddresses[1], tradeValues[1], tradeValues[2], tradeAddresses[2]));
        bytes32 tradeHash = keccak256(abi.encodePacked(orderHash, tradeValues[3], tradeAddresses[3])); 
        require(traded[tradeHash]==false,"Hash already exists");
        traded[tradeHash] = true;
        if (tradeValues[4] > 100) tradeValues[4] = 100;
        if (tradeValues[5] > 100) tradeValues[5] = 100;
        require (orderFills[orderHash].add(tradeValues[3]) <= tradeValues[0],"Condition 1");
        require(tokens[tradeAddresses[0]][tradeAddresses[3]] >= tradeValues[3], "Condition 2");
        require(tokens[tradeAddresses[1]][tradeAddresses[2]] >= (tradeValues[1].mul(tradeValues[3]) / tradeValues[0]),"Condition 3");
        tokens[tradeAddresses[0]][tradeAddresses[3]] = tokens[tradeAddresses[0]][tradeAddresses[3]].sub(tradeValues[3]);
        tokens[tradeAddresses[0]][tradeAddresses[2]] = tokens[tradeAddresses[0]][tradeAddresses[2]].add(tradeValues[3].mul(((1 ether) - tradeValues[4])) / (1 ether));
        tokens[tradeAddresses[0]][feeAccount] = tokens[tradeAddresses[0]][feeAccount].add(tradeValues[3].mul(tradeValues[4]) / (1 ether));
        tokens[tradeAddresses[1]][tradeAddresses[2]] = tokens[tradeAddresses[1]][tradeAddresses[2]].sub(tradeValues[1].mul(tradeValues[3]) / tradeValues[0]);
        tokens[tradeAddresses[1]][tradeAddresses[3]] = tokens[tradeAddresses[1]][tradeAddresses[3]].add(((1 ether) - tradeValues[5]).mul(tradeValues[1]).mul(tradeValues[3]) / tradeValues[0] / (1 ether));
        tokens[tradeAddresses[1]][feeAccount] = tokens[tradeAddresses[1]][feeAccount].add(tradeValues[5].mul(tradeValues[1]).mul(tradeValues[3]) / tradeValues[0] / (1 ether));
        orderFills[orderHash] = orderFills[orderHash].add(tradeValues[3]);
    }
    
}