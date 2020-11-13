pragma solidity 0.6.5;
pragma experimental ABIEncoderV2;

import "../BaseWithStorage/ERC20Group.sol";


contract ERC20GroupGem is ERC20Group {
    function addGems(ERC20SubToken[] calldata catalysts) external {
        require(msg.sender == _admin, "NOT_AUTHORIZED_ADMIN");
        for (uint256 i = 0; i < catalysts.length; i++) {
            _addSubToken(catalysts[i]);
        }
    }

    constructor(
        address metaTransactionContract,
        address admin,
        address initialMinter
    ) public ERC20Group(metaTransactionContract, admin, initialMinter) {}
}
