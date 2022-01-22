/**
 *Submitted for verification at Etherscan.io on 2022-01-22
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.7.0 < 0.9.0;

contract Pyramid {

    address payable[] all_addr;
    mapping(address => string) addr2name;
    mapping(string => mice) str2mice;
    uint256 public KeyPrizes = 10;
    uint256 public all_Keys = 0;
    uint256 public time = block.timestamp;
    address payable public lastWinner;
    uint256 public val;
    uint8 public start = 0; // (0) unstart  (1) playing  (2) end

    struct mice {
        address payable mouse_addr;
        string mouse_name;
        uint256 mouse_have_Keys;
    }

    function become_a_mouse(string memory name, address payable addr) public returns(mice memory) {
        all_addr.push(addr);
        addr2name[addr] = name;
        mice memory tmp;
        tmp.mouse_addr = addr;
        tmp.mouse_name = name;
        tmp.mouse_have_Keys = 0;
        str2mice[name] = tmp;
        return tmp;
    }

    function GetPrize() public view returns(uint256) {
        return address(this).balance;
    }

    function Buy(uint256 prizes) public payable {}

    function BuyKey() public {
        Buy(10);
        /*if(msg.sender.balance > KeyPrizes && (start == 0 || start == 1)) {
            Buy(KeyPrizes);
            KeyPrizes += (KeyPrizes*12)/(KeyPrizes*10);
            all_Keys += 1;
            str2mice[addr2name[msg.sender]].mouse_have_Keys += 1;
            lastWinner = payable(msg.sender);
            if(start == 0 && all_Keys == 0) {
                start = 1;
            }
            time += 10;
        }*/
    }

    function GameEndTime() public returns(uint256) {
        if(time-block.timestamp==0 && start == 1) {
            start = 2;
        }
        return time-block.timestamp;
    }

    /*function Withdraw() public {
        for(uint256 i=0;i<all_addr.length;i++) {
            if(all_addr[i] == msg.sender && start == 2) {
                mice memory tmp = str2mice[addr2name[msg.sender]];
                uint256 val = all_Keys/tmp.mouse_have_Keys;
                payable(msg.sender).transfer(100);
            }
        }
    }*/

    function GetMouseData() public view returns(mice memory) {
        return str2mice[addr2name[msg.sender]];
    }

    function getvalue() public payable  {
        val = msg.value;
    }
    fallback() external payable {}
    receive() external payable {}

}