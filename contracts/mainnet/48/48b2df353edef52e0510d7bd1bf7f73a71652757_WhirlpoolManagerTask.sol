/**
 *Submitted for verification at Etherscan.io on 2020-12-30
*/

pragma solidity <=0.6.2;

interface IRelease {
    function release() external;
}

interface ISURF3D {
    function dividendsOf(address _user) external view returns (uint256);
}

contract WhirlpoolManagerTask {
    address private constant _surf3D = 0xeb620A32Ea11FcAa1B3D70E4CFf6500B85049C97;
    address private constant _whirlpoolManager = 0x6E6D30D1Fd3c49278F93d4D29681f628d88b050b;

    function check(uint _requirement)
    external view returns (uint256) {
        uint balance = ISURF3D(_surf3D).dividendsOf(_whirlpoolManager);

        if(balance >= _requirement)
            return 0;
        else
            return _requirement - balance;
    }

    function execute()
    external {
        IRelease(_whirlpoolManager).release();
    }
}