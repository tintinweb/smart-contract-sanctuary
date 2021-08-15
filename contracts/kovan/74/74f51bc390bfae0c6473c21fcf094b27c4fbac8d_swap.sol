/**
 *Submitted for verification at Etherscan.io on 2021-08-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.4.16 <0.9.0;


// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v3.0.0/contracts/token/ERC20/IERC20.sol
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract swap {
    
    // address owner = payable(0x4f5609b1Ef25679c5ee4477F906D063C318f9532);
    
    address owner = payable(address(uint160(0x4f5609b1Ef25679c5ee4477F906D063C318f9532)));
    
    uint256 public balance = 0;

   /* constructor () public ERC20("Simple Token", "SIM") {
        _mint(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4, 1000000 * (10 ** uint256(decimals())));
    }*/
    
    function transferToken(address _token, address _to) public payable returns(bool){
        balance += msg.value;
        payable(owner).transfer(msg.value);
        
        IERC20(_token).transferFrom(owner, _to,((msg.value/10**10)*4));
        return true;
    }
}