import "./TokenStaking.sol";

contract MFIStaking is TokenStaking {
    constructor(address _MFI, uint256 initialRewardPerBlock, address _roles)
        TokenStaking(_MFI, _MFI, initialRewardPerBlock, _roles)
    {}
}