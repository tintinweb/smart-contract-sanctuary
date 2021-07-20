/**
 *Submitted for verification at Etherscan.io on 2021-07-20
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

interface token
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
     event Deposit(address token, address user, uint256 amount, uint256 balance);
     event Withdraw(address token, address user, uint256 amount, uint256 balance);
     mapping(address => mapping(address=>uint256))public tokens;
    
    function depositToken(address _tokenAddress,uint256 _amount)public  //tranfer tokens from user to contract address
    {
        require(_amount>0,"Invalid amount");
        require(_tokenAddress!=address(0),"Invalid address");
        tokens[_tokenAddress][msg.sender]=tokens[_tokenAddress][msg.sender].add(_amount);
        token(_tokenAddress).transferFrom(msg.sender,address(this), _amount);
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
            token(_tokenAddress).transfer(msg.sender, _amount); //transfer tokens from contract address to user.
            emit Withdraw(_tokenAddress, msg.sender, _amount, tokens[_tokenAddress][msg.sender]);
        }
    }
}