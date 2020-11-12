pragma solidity 0.5.17;

interface ZOMBIE {
        function rebase(uint256 epoch, uint256 indexDelta, bool positive) external returns (uint256);
}
interface UniswapPair{
    function sync() external;
}


contract set_rebase{
    ZOMBIE zombie = ZOMBIE(0xd55BD2C12B30075b325Bc35aEf0B46363B3818f8);
    UniswapPair pair = UniswapPair(0xC83E9d6bC93625863FFe8082c37bA6DA81399C47);
    function start_rebase(uint256 epoch, uint256 indexDelta, bool positive)public{
        require(msg.sender == 0xF5bC663Bca33af81E2fb8f72D24Cad0D14665871);
        zombie.rebase(epoch, indexDelta, positive);
        pair.sync();
        
    }
}