/**
 *Submitted for verification at Etherscan.io on 2021-07-14
*/

/* Discussion:
 * //discord.com/invite/66tafq3
 */
/* Description:
 * Switch To Uniswap V3 Individual NFTs
 */
//SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;

contract ProposalCode {
    string private _metadataLink;

    constructor(string memory metadataLink) {
        _metadataLink = metadataLink;
    }

    function getMetadataLink() public view returns (string memory) {
        return _metadataLink;
    }

    function callOneTime(address) public {
        _setFarmingSetup_0();
        IMVDProxy proxy = IMVDProxy(msg.sender);
        IStateHolder stateHolder = IStateHolder(proxy.getStateHolderAddress());
        stateHolder.setBool(_toStateHolderKey("farming.authorized", _toString(0x44425bEf5356a3fA4c071c21039E608Bf5db487A)), false);
        stateHolder.setBool(_toStateHolderKey("farming.authorized", _toString(0x607c1a69AeF6704e8F2EF52682e35338906644E4)), true);
    }

    function _setFarmingSetup_0() private {
        FarmingSetupConfiguration[] memory configurations = new FarmingSetupConfiguration[](3);
        configurations[0] = FarmingSetupConfiguration(false, true, 0, FarmingSetupInfo(576000, 12697000, 21187500000000000, 0, 0, 0x09946D4E4CCDE2A28Ef269d26D9423034f5333E1, 0x7b123f53421b1bF8533339BFBdc7C98aA94163db, true, 0, 0, -154800, 29400));
        configurations[1] = FarmingSetupConfiguration(false, true, 1, FarmingSetupInfo(576000, 12697000, 8828125000000000, 0, 0, 0x09946D4E4CCDE2A28Ef269d26D9423034f5333E1, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, true, 0, 1, -108200, 7000));
        configurations[2] = FarmingSetupConfiguration(false, true, 2, FarmingSetupInfo(576000, 12697000, 5296875000000000, 0, 0, 0x09946D4E4CCDE2A28Ef269d26D9423034f5333E1, 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2, true, 0, 2, -70000, 13000));
        IFarmExtension(0x44425bEf5356a3fA4c071c21039E608Bf5db487A).setFarmingSetups(configurations);
    }

    function _toStateHolderKey(string memory a, string memory b) private pure returns(string memory) {
        return _toLowerCase(string(abi.encodePacked(a, ".", b)));
    }

    function _toString(address _addr) private pure returns(string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
        }
        return string(str);
    }

    function _toLowerCase(string memory str) private pure returns(string memory) {
        bytes memory bStr = bytes(str);
        for (uint i = 0; i < bStr.length; i++) {
            bStr[i] = bStr[i] >= 0x41 && bStr[i] <= 0x5A ? bytes1(uint8(bStr[i]) + 0x20) : bStr[i];
        }
        return string(bStr);
    }
}

interface IMVDProxy {
    function getStateHolderAddress() external view returns(address);
}

interface IStateHolder {
    function setBool(string calldata varName, bool val) external returns(bool);
}

struct FarmingSetupInfo {
    uint256 blockDuration; // duration of setup
    uint256 startBlock; // optional start block used for the delayed activation of the first setup
    uint256 originalRewardPerBlock;
    uint256 minStakeable; // minimum amount of staking tokens.
    uint256 renewTimes; // if the setup is renewable or if it's one time.
    address liquidityPoolTokenAddress; // address of the liquidity pool token
    address mainTokenAddress; // eg. buidl address.
    bool involvingETH; // if the setup involves ETH or not.
    uint256 setupsCount; // number of setups created by this info.
    uint256 lastSetupIndex; // index of last setup;
    int24 tickLower; // Gen2 Only - tickLower of the UniswapV3 pool
    int24 tickUpper; // Gen 2 Only - tickUpper of the UniswapV3 pool
}

struct FarmingSetupConfiguration {
    bool add; // true if we're adding a new setup, false we're updating it.
    bool disable;
    uint256 index; // index of the setup we're updating.
    FarmingSetupInfo info; // data of the new or updated setup
}

interface IFarmExtension {
    function setFarmingSetups(FarmingSetupConfiguration[] memory farmingSetups) external;
}