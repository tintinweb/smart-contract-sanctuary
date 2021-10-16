pragma solidity 0.6.12;

import "./BaseBEP20.sol";


// TcbToken with Governance.
contract TcbToken is BaseBEP20 {
    constructor(address mint, address rewardAddress, address owner2) public BaseBEP20('Trusted Computing Basecoin', '可信计算基础币', 'TCB', 1, rewardAddress, owner2){
        require(rewardAddress != address(0), "TcbToken：invalid rewardAddress");
        require(owner2 != address(0), "TcbToken：invalid owner2");
        _mint(mint, 21000000000 * 10 ** 4, true);
    }
}