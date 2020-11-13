pragma solidity 0.5.16;

interface TokenInterface {
    function balanceOf(address) external view returns (uint);
    function transfer(address, uint) external returns (bool);
    function burn(uint) external;
}

interface YFVRewards {
    function periodFinish() external view returns (uint);
}

// https://yfv.finance/voting
contract VIP2 {

    address payable owner;
    YFVRewards pool0 = YFVRewards(0xa8d3084Fa61C893eACAE2460ee77E3E5f11C8CFE);
    TokenInterface yfv = TokenInterface(0x45f24BaEef268BB6d63AEe5129015d69702BCDfa);
    TokenInterface usdc = TokenInterface(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    TokenInterface uniswapYFVETH = TokenInterface(0xcB4f983E705caeb7217c5C3785001Cb138115F0b);
    address payable yfvMultisig = 0xb7b2Ea8A1198368f950834875047aA7294A2bDAa;
    uint contractDeployTime;
    uint initialPool0PeriodFinish;
    bool isUniswapLPTLocked;

    constructor() public {
        owner = msg.sender;
        contractDeployTime = block.timestamp;
        initialPool0PeriodFinish = pool0.periodFinish();
    }

    // 325.76YFV will be sent to this contract before voting start
    // If fund is unlocked, anyone can call this function to burn the 325.76YFV
    function giveBack1_BurnYFV() public {
        require(isFundUnlocked());
        yfv.burn(yfv.balanceOf(address(this)));
    }

    // Liquidity token of 500YFV+ETH on uniswap will be sent to this contract before voting start
    // If fund is unlocked, anyone can call this function to lock the LP tokens so owner can only withdraw after 6 weeks from contractDeployTime
    function giveBack2_LockUNI() public {
        require(isFundUnlocked());
        isUniswapLPTLocked = true;
    }

    // 10,000 USDC will be sent to this contract before voting start
    // If fund is unlocked, anyone can call this function to send the 10,000 USDC to the yfv multisig address
    function giveBack3_DonationToTeam() public {
        require(isFundUnlocked());
        usdc.transfer(yfvMultisig, usdc.balanceOf(address(this)));
    }

    // Use the periodFinish data to check for unlock status
    function isFundUnlocked() public view returns (bool) {
        return pool0.periodFinish() > initialPool0PeriodFinish;
    }

    // If the fund is not unlocked after 2 weeks from contractDeployTime, owner can get back all assets in this contract
    function ownerGetBackAfterTwoWeeks() public {
        require(msg.sender == owner);
        require(block.timestamp > contractDeployTime + 14 days);
        yfv.transfer(owner, yfv.balanceOf(address(this)));
        usdc.transfer(owner, usdc.balanceOf(address(this)));

        if (!isUniswapLPTLocked) {
          uniswapYFVETH.transfer(owner, uniswapYFVETH.balanceOf(address(this)));
        }
    }

    // If the fund is unlocked, owner can only get back the YFV/ETH liquidity token after 6 weeks from contractDeployTime
    function ownerGetBackUniswapTokenAfterSixWeeks() public {
        require(msg.sender == owner);
        require(block.timestamp > contractDeployTime + 42 days);
        uniswapYFVETH.transfer(owner, uniswapYFVETH.balanceOf(address(this)));
    }

}