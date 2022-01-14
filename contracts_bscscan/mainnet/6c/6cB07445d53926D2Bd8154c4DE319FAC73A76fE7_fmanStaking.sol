pragma solidity ^0.5.16;

import "./Ownable.sol";
import "./FCards.sol";
import "./Strings.sol";
import "./SafeMath.sol";
import "./IERC20.sol";
import "./Address.sol";
import "./erc1155MockR.sol";

contract fmanStaking is Ownable, ERC1155MockReceiver {
    using SafeMath for uint256;
    using Strings for string;

    struct Card {
        uint256 id;
        uint256 price;
        uint256 maxSupply;
        uint256 maxOwned;
        uint256 rank;
    }

    uint256 public rewardWholeSeason = 200;
    uint256 public reward4s = 100;
    uint256 public reward5s = 180;
    uint256 public interval = 200;
    uint256 public p3 = 10;
    uint256 public p4 = 40;
    uint256 public p5 = 50;
    uint256 public fmanMaxWallet = 2000000000000000000000000000000;
    uint256 private rewardFor3 = 0;
    uint256 private rewardFor4 = 0;
    uint256 private rewardFor5 = 0;

    string public name = "FMAN Airdrop";
    string public symbol = "FMANAIR";

    mapping(address => mapping(uint256 => uint256)) internal cardBalance;
    mapping(address => mapping(uint256 => uint256)) internal rankBalance;

    address[] private otAddresses;
    mapping(address => bool) private otSeenAddy;

    mapping(uint256 => uint256) public totalLockedPerRank;

    bool public stakeIsLocked = false;

    // FMAN Token Contract Addy
    address public fmanAddy = 0xC2aEbbBc596261D0bE3b41812820dad54508575b;
    fmanCards fmanft;
    IERC20 fman;
    address public nftAddy = 0x403336AE5440FE5e0c1A1aD977273B20013CF79B;

    // Address of owner wallet
    address payable private ownerAddress;

    // Address of NFT dev
    address payable private devAddress;

    // Modifiers
    modifier onlyDev() {
        require(
            devAddress == msg.sender,
            "dev: only dev can change their address."
        );
        _;
    }

    modifier unlockedStake() {
        require(
            !stakeIsLocked,
            "Deposits and withdrawals are paused at the moment. Please hold on.."
        );
        _;
    }


    constructor(
        address payable _devAddress
    ) public {
        ownerAddress = msg.sender;
        devAddress = _devAddress;
        fmanft = fmanCards(nftAddy);
        fman = IERC20(fmanAddy);
    }

    function setOTPRewards(uint256 fourReward, uint256 fiveReward, uint256 setReward) public onlyOwner{
        rewardWholeSeason = setReward;
        reward4s = fourReward;
        reward5s = fiveReward;
    }

    function setFmanMaxWallet(uint256 maxWallet) external onlyOwner{
        fmanMaxWallet = maxWallet * 10**18;
    }

    function setIterationInterval(uint256 i) external onlyOwner {
        interval = i;
    }

    function setOwnerAddress(address payable addy) external onlyOwner{
        ownerAddress = addy;
        transferOwnership(addy);
    }

    function numberOfAddresses() external view returns(uint256){
        return otAddresses.length;
    }

    function balanceOf(address user, uint256 id) external view returns(uint256){
        require(fmanft.validCard(id), "invalid card id");
        return cardBalance[user][id];
    }

    function setRewardSplits(
        uint256 _ratio3,
        uint256 _ratio4,
        uint256 _ratio5
    ) external onlyOwner {
        require(
            _ratio3 + _ratio4 + _ratio5 == 100,
            "should add up to 100"
        );
        p3 = _ratio3;
        p4 = _ratio4;
        p5 = _ratio5;
    }

    function withdrawToken(address tokenAddy) public onlyOwner {
        uint256 balance = IERC20(tokenAddy).balanceOf(address(this));
        // 5% goes to NFT dev
        uint256 balanceForDev = balance.div(10).div(2);
        uint256 deltaBalance = balance.sub(balanceForDev);
        IERC20(tokenAddy).transfer(devAddress, balanceForDev);
        IERC20(tokenAddy).transfer(ownerAddress, deltaBalance);
    }

    function WithdrawBeans() public onlyOwner {
        uint256 balance = address(this).balance;
        // 5% goes to NFT dev
        uint256 balanceForDev = balance.div(10).div(2);
        uint256 deltaBalance = balance.sub(balanceForDev);
        devAddress.transfer(balanceForDev);
        ownerAddress.transfer(deltaBalance);
    }

    function deposite(
        uint256 id,
        uint256 qnt,
        bytes memory _data
    ) public unlockedStake {
        require(fmanft.validCard(id), "Invalid card Id");
        require(qnt > 0, "Please increase quantity from 0");
        require(
            fmanft.balanceOf(msg.sender, id) >= qnt,
            "Make sure you have the quantity u want to deposite."
        );
        (, , , , uint256 rank) = fmanft.cardById(id);
        totalLockedPerRank[rank]++;
        if (!otSeenAddy[msg.sender]) {
            otSeenAddy[msg.sender] = true;
            otAddresses.push(msg.sender);
        }
        cardBalance[msg.sender][id] += qnt;
        rankBalance[msg.sender][rank] += qnt;

        fmanft.safeTransferFrom(msg.sender, address(this), id, qnt, _data);
    }

    function withdraw(
        uint256 id,
        uint256 qnt,
        bytes memory _data
    ) public unlockedStake {
        require(fmanft.validCard(id), "Invalid card Id");
        require(qnt > 0, "Please increase quantity from 0");
        require(
            cardBalance[msg.sender][id] >= qnt,
            "Make sure you have the quantity u want to withdraw."
        );
        (, , , , uint256 rank) = fmanft.cardById(id);
        totalLockedPerRank[rank]--;
        rankBalance[msg.sender][rank] -= qnt;
        cardBalance[msg.sender][id] -= qnt;
        fmanft.safeTransferFrom(address(this), msg.sender, id, qnt, _data);
    }

    function hasSet(address user) internal view returns (bool) {
        return (cardBalance[user][2] > 0 &&
            cardBalance[user][3] > 0 &&
            cardBalance[user][4] > 0 &&
            cardBalance[user][5] > 0 &&
            cardBalance[user][6] > 0);
    }

    function has4s(address user) internal view returns (bool) {
        return rankBalance[user][4] >= 2 && rankBalance[user][5] >= 1;
    }

    function has5s(address user) internal view returns (bool) {
        return rankBalance[user][5] >= 2;
    }

    function otDistro(uint256 index) public onlyOwner {
        require(stakeIsLocked, "Please initialize distro first");
        require(index < otAddresses.length, "index larger than array size");
        uint256 range = min(index + interval, otAddresses.length);
        for (uint256 i = index; i < range; i++) {
            uint256 payableAmt = 0;
            if (has4s(otAddresses[i])) {
                payableAmt += reward4s;
            }
            if (has5s(otAddresses[i])) {
                payableAmt += reward5s;
            }
            if (hasSet(otAddresses[i])) {
                payableAmt += rewardWholeSeason;
            }
            if (
                payableAmt > 0 &&
                fman.balanceOf(otAddresses[i]) + payableAmt < fmanMaxWallet
            ) {
                fman.transfer(otAddresses[i], payableAmt);
            }
        }
    }

    function calculateOTP() public view returns (uint256 payableAmt) {
        uint256 payableAmt = 0;
        for (uint256 i = 0; i < otAddresses.length; i++) {
            if (has4s(otAddresses[i])) {
                payableAmt += reward4s;
            }
            if (has5s(otAddresses[i])) {
                payableAmt += reward5s;
            }
            if (hasSet(otAddresses[i])) {
                payableAmt += rewardWholeSeason;
            }
        }
        return payableAmt;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256) {
        if (x < y) {
            return x;
        } else {
            return y;
        }
    }

    function initializeDistro(bool includeOneTimePayment) external onlyOwner {
        stakeIsLocked = true;
        resetRewards();
        uint256 bal = fman.balanceOf(address(this));
        uint256 balToOt = 0;
        if (includeOneTimePayment) {
            balToOt = calculateOTP();
        }
        uint256 balToDistro = bal.sub(balToOt);
        uint256 amt3 = balToDistro.mul(p3).div(100);
        uint256 amt4 = balToDistro.mul(p4).div(100);
        uint256 amt5 = balToDistro.sub(amt3).sub(amt4);
        if (totalLockedPerRank[3] > 0) {
            rewardFor3 = amt3.div(totalLockedPerRank[3]);
        }
        if (totalLockedPerRank[4] > 0) {
            rewardFor4 = amt4.div(totalLockedPerRank[4]);
        }
        if (totalLockedPerRank[5] > 0) {
            rewardFor5 = amt5.div(totalLockedPerRank[5]);
        }
    }

    function resetRewards() internal {
        rewardFor3 = 0;
        rewardFor4 = 0;
        rewardFor5 = 0;
    }

    function finalizeDistro() external onlyOwner {
        stakeIsLocked = false;
        resetRewards();
    }

    function distro(uint256 index) public onlyOwner {
        require(stakeIsLocked, "Please initialize distro first");
        require(index < otAddresses.length, "index larger than array size");
        uint256 range = min(index + interval, otAddresses.length);
        for (uint256 i = index; i < range; i++) {
            uint256 payableAmt = 0;
            payableAmt += rewardFor3.mul(rankBalance[otAddresses[i]][3]);
            payableAmt += rewardFor4.mul(rankBalance[otAddresses[i]][4]);
            payableAmt += rewardFor5.mul(rankBalance[otAddresses[i]][5]);
            if (
                payableAmt > 0 &&
                fman.balanceOf(otAddresses[i]) + payableAmt < fmanMaxWallet
            ) {
                fman.transfer(otAddresses[i], payableAmt);
            }
        }
    }
}