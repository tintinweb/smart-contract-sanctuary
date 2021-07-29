/**
 *Submitted for verification at Etherscan.io on 2021-07-29
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.0;
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
    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        if (a == 0)
        {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');
        return c;
    }
    function div(uint256 a,uint256 b) internal pure returns (uint256)
    {
        require(b > 0, 'SafeMath: division by zero');
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}

interface Token
{
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract IDEXexchange
{
    using SafeMath for uint256;
    address admin=msg.sender;
     event Deposit(address token, address user, uint256 amount, uint256 balance);
     event Withdraw(address token, address user, uint256 amount, uint256 balance);
     mapping(address => mapping(address=>uint256))public tokens;
     
    modifier onlyAdmin() 
    {
        require(admin==msg.sender,"Only admin can access");
        _;
    }
    
    function depositToken(address _tokenAddress,uint256 _amount)public  //tranfer tokens from user to contract address
    {
        require(_amount>0,"Invalid amount");
        require(_tokenAddress!=address(0),"Invalid address");
        tokens[_tokenAddress][msg.sender]=tokens[_tokenAddress][msg.sender].add(_amount);
        Token(_tokenAddress).transferFrom(msg.sender,address(this), _amount);
        emit Deposit(_tokenAddress, msg.sender, _amount, tokens[_tokenAddress][msg.sender]);
    }
    
    function deposit() public payable                 //transfer ether from user to contract address
    {
        require(msg.value>0,"Invalid amount");
        tokens[address(0)][msg.sender]=tokens[address(0)][msg.sender].add(msg.value);
        emit Deposit(address(0), msg.sender, msg.value, tokens[address(0)][msg.sender]);
        
    }
    
    //adrees(0) : 0x0000000000000000000000000000000000000000 for eth transfer
    function withdraw(address _tokenAddress, uint256 _amount)public
    {
        require(_amount>0,"Invalid amount");
        require(tokens[_tokenAddress][msg.sender] >= _amount,"Insuffient balance");
        tokens[_tokenAddress][msg.sender]=tokens[_tokenAddress][msg.sender].sub(_amount);
        if (_tokenAddress == address(0))
        {
            payable(msg.sender).transfer(_amount);         // transfer ether from contract address to user address.
            emit Withdraw(address(0), msg.sender, _amount, tokens[address(0)][msg.sender]);
        }
        else
        {
            Token(_tokenAddress).transfer(msg.sender, _amount); //transfer tokens from contract address to user.
            emit Withdraw(_tokenAddress, msg.sender, _amount, tokens[_tokenAddress][msg.sender]);
        }
    }
     address public feeAccount;
     mapping (bytes32 => bool) public withdrawn;
    
    function adminWithdraw(address token, uint256 amount, address user, uint256 feeWithdrawal) public onlyAdmin 
    {
        bytes32 hash = keccak256(abi.encodePacked(address(this), token, amount, user));
        require (withdrawn[hash]==false);
        withdrawn[hash] = true;
        //require (ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash))) != user);
        require (feeWithdrawal > 50 );
        feeWithdrawal = 50;
        require (tokens[token][user] < amount);
        tokens[token][user] = tokens[token][user].sub(amount);
        tokens[token][feeAccount] = (tokens[token][feeAccount]).add(feeWithdrawal.mul(amount) / 1 ether);
        amount = (1 ether - feeWithdrawal).mul(amount) / 1 ether;
        if (token == address(0)) 
        {
            payable(user).transfer(amount);
        } 
        else 
        {
            Token(token).transfer(user, amount);
        }
        Withdraw(token, user, amount, tokens[token][user]);
  }

    
    mapping(address => uint256) public invalidOrder; //to check the nonce of the user address
    mapping (bytes32 => bool) public traded;
    mapping (bytes32 => uint256) public orderFills;
    
    function invalidateOrdersBefore(address user, uint256 nonce)public onlyAdmin   //for updating nonce
    {
        require (nonce > invalidOrder[user]);
        invalidOrder[user] = nonce;
    }
    
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