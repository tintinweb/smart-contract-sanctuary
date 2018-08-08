pragma solidity ^0.4.0;
contract HelloYincheng {
    string mystr="锄禾日当午，学以太坊真他妈苦，跟着尹成大魔王学，就一点都不苦。";
    
    function getMystr()  public view returns (string){
        return mystr;
    }
    
    function getName()  public  view returns (string){
        return "白日依山尽，花钱似海流，郎中无一物，急得欲跳楼";
    }
    
    function setMystr(string  newmystr) public{
        mystr= newmystr;
    }
    
    
    
    
}