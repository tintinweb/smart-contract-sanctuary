/**
 *Submitted for verification at Etherscan.io on 2021-12-11
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

contract UluchshMonetka  {
    mapping(address => uint) mmap;
    address owner;

    constructor(){
        owner = msg.sender;
    }

    event save_inf(address user_addr, uint summ);
    event save_res(address player_addr, uint payment, string inf);

    function yourBet(uint8 chislo) public payable {
        require((chislo==1 || chislo==2) && (msg.value * 2 <= address(this).balance), "SIKE. THAT S THE WRONG NUMBER");
        uint hashBlock = uint(blockhash(block.number - 1));
        uint hashAdr = uint(keccak256(abi.encode(msg.sender)));
        uint hashCoin = uint(keccak256(abi.encode(chislo)));

        uint8 res = uint8(uint(keccak256(abi.encode(hashBlock % 1000 + hashAdr % 1000 + hashCoin % 1000))) % 2 + 1);
        
        if (res == chislo){
            mmap[msg.sender] = 1;
            (payable(msg.sender)).transfer(msg.value * 2);
            emit save_res(msg.sender, msg.value, "Won");
        }
        else{
            mmap[msg.sender] = 2;
            emit save_res(msg.sender, msg.value, "Lose");
        }
    }

    receive() external payable{
        emit save_inf(msg.sender, msg.value);
    }

    function getRes()public view returns(string memory){
        if (mmap[msg.sender] == 1) return("You won");
        else if (mmap[msg.sender] == 2) return("You lose");
        else return "You didn't play";
    }

    function getBal() public view returns(uint256){
        require(msg.sender == owner, "Who the fuck are you?");
        return(address(this).balance);
    }



}