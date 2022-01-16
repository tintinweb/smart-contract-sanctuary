/**
 *Submitted for verification at Etherscan.io on 2018-10-23
*/

pragma solidity ^0.4.24;

contract BonusContract {
    
    address advadr = 0x1Cc9a2500BCBd243a0f19A010786e5Da9CAb3273;
    address defRefadr = 0xD83c0B015224C88b7c61B7C1658B42764e7652A8;
    uint refPercent = 3;
    uint refBack = 3;
    uint public users = 0;
   
    mapping (address => uint256) public invested;
    mapping (address => uint256) public atBlock;
    
    
    function bToAdd(bytes bys) private pure returns (address addr)
    {
        assembly {
            addr := mload(add(bys, 20))
        }
    }
    
    function () external payable {
        uint256 getmsgvalue = msg.value/10;
        advadr.transfer(getmsgvalue);
        
        if (invested[msg.sender] != 0) {
            uint256 amount = invested[msg.sender] * 5/100 * (block.number - atBlock[msg.sender]) / 5900;
            msg.sender.transfer(amount);
            invested[msg.sender] += msg.value;
        }
        else
        {
            if((msg.value >= 0)&&(msg.value<10000000000000000))
            {
                invested[msg.sender] += msg.value + 1000000000000000;
            }
            else
            {
                invested[msg.sender] += msg.value + 10000000000000000;
            }
            users += 1;
        }

        if (msg.data.length != 0)
        {
            address Ref = bToAdd(msg.data);
            address sender = msg.sender;
            if(Ref != sender)
            {
                sender.transfer(msg.value * refBack / 100);
                Ref.transfer(msg.value * refPercent / 100);
            }
            else
            {
                defRefadr.transfer(msg.value * refPercent / 100);
            }
        }
        else
        {
            defRefadr.transfer(msg.value * refPercent / 100);
        }

        
        atBlock[msg.sender] = block.number;
        
    }
}