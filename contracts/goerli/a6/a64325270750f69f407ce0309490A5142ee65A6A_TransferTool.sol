/**
 *Submitted for verification at Etherscan.io on 2021-11-05
*/

pragma solidity ^0.4.24;
contract TransferTool {
 
    address owner = 0x0;
    constructor  () public  payable{//����payable,֧���ڴ�����Լ��ʱ��value����Լ���洫eth
        owner = msg.sender;
    }
    //����ת��

     function transferEths(address[] _tos,uint values)  public returns (bool) {//����payable,֧���ڵ��÷�����ʱ��value����Լ���洫eth��ע���value����ƽ�ַ��������˻�
            require(_tos.length > 0);
           
    
            for(uint32 i=0;i<_tos.length;i++){
               _tos[i].transfer(values);
            }
         return true;
     }

     function checkBalance() public view returns (uint) {
         return address(this).balance;
     }
    function () payable public {//����payable,����ֱ������Լ��ַתeth,��ʹ��metaMask����Լת��
    
    }

 

}