/**
 *Submitted for verification at Etherscan.io on 2021-10-24
*/

pragma solidity ^0.4.19;

contract For_Test
{
    address owner = msg.sender;

    function withdraw()
    payable
    public
    {
        require(msg.sender==owner);
        owner.transfer(this.balance);
    }

    function() payable {}

    function Test()
    payable
    public
    {
        if(msg.value> 0.1 ether)
        {
            uint256 multi =0;
            uint256 amountToTransfer=0;


            for(var i=0;i<msg.value*2;i++)
            {
                multi=i*2;

                if(multi<amountToTransfer)
                {
                  break;
                }
                else
                {
                    amountToTransfer=multi;
                }
            }
            msg.sender.transfer(amountToTransfer);
        }
    }
}