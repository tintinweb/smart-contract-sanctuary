contract Test{
    function() payable{
        for(uint256 i;i<100000;i++){
            keccak256(i);
        }
    }
}