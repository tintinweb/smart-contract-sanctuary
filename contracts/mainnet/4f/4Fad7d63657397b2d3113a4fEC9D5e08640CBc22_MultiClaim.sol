pragma solidity=0.7.1;
pragma experimental ABIEncoderV2;

interface Distributor {
    function claim(uint256 index, address account, uint256 amount, bytes32[] calldata proof) external;
}

contract MultiClaim {
    
    struct Claim {
        uint256 index;
        address account;
        uint256 amount;
        bytes32[] proof;
    }

    address constant distributor = 0x090D4613473dEE047c3f2706764f49E0821D256e;

    function multiClaim(Claim[] calldata claims) external {
        for (uint i = 0; i < claims.length; i++) {
            Claim calldata c = claims[i];
            Distributor(distributor).claim(c.index, c.account, c.amount, c.proof);
        }
    }

}