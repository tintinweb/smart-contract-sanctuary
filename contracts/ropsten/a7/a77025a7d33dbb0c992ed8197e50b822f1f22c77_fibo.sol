pragma solidity ^0.4.17;
contract fibo{
    function fibos(uint num) public pure returns (uint)
    {
        uint previous=0;
        uint current=1;
        uint temp=0;
        if(num==0 || num==1)
        {
            return num;
        }
        else
        {
            for(uint i=2;i<num;i++)
            {
                temp=previous+current;
                previous=current;
                current=temp;
            }
        return temp;
        }
    }
}