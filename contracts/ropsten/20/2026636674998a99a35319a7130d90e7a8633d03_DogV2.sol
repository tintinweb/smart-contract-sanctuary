/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

contract Dog {
    uint256 public mua = 123; 
    function setMua(uint256 _newMua) public {
        mua = _newMua;
        
    }

}


contract DogV2  is Dog{
    function setMua(uint256 _newMua) public {
        mua = cond(_newMua);
        
    }
    
    function cond(uint i) public pure returns(uint)   {
        if (i == 2) {
            return 100;
        } else {
            return  0;
        }
    }
}