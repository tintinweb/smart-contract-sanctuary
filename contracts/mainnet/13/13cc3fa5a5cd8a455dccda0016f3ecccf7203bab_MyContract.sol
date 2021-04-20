/**
 *Submitted for verification at Etherscan.io on 2021-04-19
*/

pragma solidity >=0.4.22 <0.6.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function decimals() external view returns (uint8);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MyContract {
    
    address owner;
    IERC20 token;
    uint length;
    mapping(address=>uint) addresses;
    mapping(uint => address) list;

    constructor() public {
        owner = msg.sender;
        token = IERC20(0x9ffc3bcde7b68c46a6dc34f0718009925c1867cb);
        length = 4;
        addresses[0x9F4e57141afbFB83c45b11d9ab096ACa9a44167C] = 25;
        list[0] = 0x9F4e57141afbFB83c45b11d9ab096ACa9a44167C;
        addresses[0x826f8A1e8C30992BA0327a95351b2BFB24E358cB] = 25;
        list[1] = 0x826f8A1e8C30992BA0327a95351b2BFB24E358cB;
        addresses[0x1158D48b9a0e15388eDF1CB64C98C82B5E0adDDc] = 25;
        list[2] = 0x1158D48b9a0e15388eDF1CB64C98C82B5E0adDDc;
        addresses[0xE0D1169a916579B81626B04D9798b4d52509928c] = 25;
        list[3] = 0xE0D1169a916579B81626B04D9798b4d52509928c;
    }
    
    function Distribute() public {
        uint256 balance = token.balanceOf(address(this));
            for(uint i = 0; i < length; i++) {
                token.transfer(list[i], balance / 100 * addresses[list[i]]);
            }
    }

    function kill() public {
       if (owner == msg.sender) {
            selfdestruct(msg.sender);
        }
    }
}