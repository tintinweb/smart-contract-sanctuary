contract problem3{
    mapping(address=>bool)  pass1;
    mapping(address=>bool)  pass2;
    event GetFlag(string b64email,string back);
    function level1 (address _player,bytes32 _hash,uint _blocknumber)public{
        uint8 size;
        address attack=msg.sender;
        assembly{size:=extcodesize(attack)}
        if(size==0 && blockhash(block.number)==_hash && blockhash(_blocknumber)<10){
            pass1[_player]=true;
            }
    }
    function level2(address _player,address _target) public   {
        Get get = Get(_target);
        uint8 size;
        uint256   value = get.getvalue();
        assembly{size:=extcodesize(_target)}
        if(size==9 &&  value==block.difficulty){
            pass2[_player]=true;
        }
   }
    function flag(string b64email)public payable {
        require(pass2[msg.sender] && pass1[msg.sender]);
            emit GetFlag(b64email, "Get flag!");
        
}
}
contract Get {
  function getvalue() public view returns (uint256);
}
//LCTF{6666_C0ngratulat10ns_6666}