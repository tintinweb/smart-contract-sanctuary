contract X {


    function getT() public view returns(bool) {
        uint256 blockValue = uint256(block.blockhash(block.number-1));
        uint256 FACTOR = 57896044618658097711785492504343953926634992332820282019728792003956564819968;
        uint256 coinFlip = blockValue / FACTOR;
        bool side = coinFlip == 1 ? true : false;
        return side;
    }

}