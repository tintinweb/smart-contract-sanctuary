pragma solidity ^0.4.24;

contract Random{
    event generateRandom(uint256 randomNumber, uint256 pool);

    address private admin = msg.sender;
    uint256 public pool;
    function core(bool _isOdd) public payable{
        uint random = uint256(keccak256(abi.encodePacked(block.timestamp)));
        bool isOdd;
        if (random/2 == 0) {
            isOdd=false;
        } else {
            isOdd=true;
        }
        if(_isOdd == isOdd){
            uint256 win=msg.value * 2;
            uint256 comPofit=win * 5 / 100;
            uint256 balance= win - comPofit;
            msg.sender.transfer(balance);
            admin.transfer(comPofit);
            pool = pool - win;
        } else {
            pool = pool + msg.value;
        }
       emit generateRandom(random, pool);
    }
}