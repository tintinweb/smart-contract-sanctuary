// SPDX-License-Identifier: MIT

pragma solidity 0.6.12;

import "./LotteryNFT.sol";
import "./IBEP20.sol";
import "./SafeBEP20.sol";
import "./SafeMath.sol";
import "./OwnableUpgradeable.sol";

// 4 numbers
contract Lottery is OwnableUpgradeable {
    using SafeMath for uint256;
    using SafeMath for uint8;
    using SafeBEP20 for IBEP20;

    uint8 constant winningCombinations = 11;
    // Allocation for first/sencond/third reward
    uint8[3] public allocation;
    // The TOKEN to buy lottery
    IBEP20 public token;
    // The Lottery NFT for tickets
    LotteryNFT public lotteryNFT;
    // adminAddress
    address public adminAddress;
    // maxNumber
    uint8 public maxNumber;
    // minPrice, if decimal is not 18, please reset it
    uint256 public minPrice;

    // =================================

    // issueId => winningNumbers[numbers]
    mapping (uint256 => uint8[4]) public historyNumbers;
    // issueId => [tokenId]
    mapping (uint256 => uint256[]) public lotteryInfo;
    // issueId => [totalAmount, firstMatchAmount, secondMatchingAmount, thirdMatchingAmount]
    mapping (uint256 => uint256[]) public historyAmount;
    // issueId => trickyNumber => buyAmountSum
    mapping (uint256 => mapping(uint64 => uint256)) public userBuyAmountSum;
    // address => [tokenId]
    mapping (address => uint256[]) public userInfo;

    uint256 public issueIndex = 0;
    uint256 public totalAddresses = 0;
    uint256 public totalAmount = 0;
    uint256 public lastTimestamp;

    uint8[4] public winningNumbers;

    // default false
    bool public drawingPhase;

    // =================================

    event Buy(address indexed user, uint256 tokenId);
    event Drawing(uint256 indexed issueIndex, uint8[4] winningNumbers);
    event Claim(address indexed user, uint256 tokenid, uint256 amount);
    event DevWithdraw(address indexed user, uint256 amount);
    event Reset(uint256 indexed issueIndex);
    event MultiClaim(address indexed user, uint256 amount);
    event MultiBuy(address indexed user, uint256 amount);
    event SetMinPrice(address indexed user, uint256 price);
    event SetMaxNumber(address indexed user, uint256 number);
    event SetAdmin(address indexed user, address indexed admin);
    event SetAllocation(address indexed user, uint8 allocation1, uint8 allocation2, uint8 allocation3);

    constructor() public {
    }

    function initialize(
        IBEP20 _token,
        LotteryNFT _lottery,
        uint256 _minPrice,
        uint8 _maxNumber,
        address _adminAddress
    ) external initializer {
        require(_adminAddress != address(0));

        token = _token;
        lotteryNFT = _lottery;
        minPrice = _minPrice;
        maxNumber = _maxNumber;
        adminAddress = _adminAddress;
        lastTimestamp = block.timestamp;
        allocation = [60, 20, 10];
        __Ownable_init();
    }

    uint8[4] private nullTicket = [0,0,0,0];

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "admin: wut?");
        _;
    }

    function drawed() public view returns(bool) {
        return winningNumbers[0] != 0;
    }

    function reset() external onlyAdmin {
        require(drawed(), "drawed?");
        lastTimestamp = block.timestamp;
        totalAddresses = 0;
        totalAmount = 0;
        winningNumbers[0]=0;
        winningNumbers[1]=0;
        winningNumbers[2]=0;
        winningNumbers[3]=0;
        drawingPhase = false;
        issueIndex = issueIndex +1;
        if(getMatchingRewardAmount(issueIndex-1, 4) == 0) {
            uint256 amount = getTotalRewards(issueIndex-1).mul(allocation[0]).div(100);
            internalBuy(amount, nullTicket);
        }
        emit Reset(issueIndex);
    }

    function enterDrawingPhase() external onlyAdmin {
        require(!drawed(), 'drawed');
        drawingPhase = true;
    }

    // add externalRandomNumber to prevent node validators exploiting
    function drawing(uint256 _externalRandomNumber) external onlyAdmin {
        require(!drawed(), "reset?");
        require(drawingPhase, "enter drawing phase first");
        bytes32 _structHash;
        uint256 _randomNumber;
        uint8 _maxNumber = maxNumber;
        bytes32 _blockhash = blockhash(block.number-1);

        // waste some gas fee here
        for (uint i = 0; i < 10; i++) {
            getTotalRewards(issueIndex);
        }
        uint256 gasLeft = gasleft();

        // 1
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                totalAddresses,
                gasLeft,
                _externalRandomNumber
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}
        winningNumbers[0]=uint8(_randomNumber);

        // 2
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                totalAmount,
                gasLeft,
                _externalRandomNumber
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}
        winningNumbers[1]=uint8(_randomNumber);

        // 3
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                lastTimestamp,
                gasLeft,
                _externalRandomNumber
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}
        winningNumbers[2]=uint8(_randomNumber);

        // 4
        _structHash = keccak256(
            abi.encode(
                _blockhash,
                gasLeft,
                _externalRandomNumber
            )
        );
        _randomNumber  = uint256(_structHash);
        assembly {_randomNumber := add(mod(_randomNumber, _maxNumber),1)}
        winningNumbers[3]=uint8(_randomNumber);
        historyNumbers[issueIndex] = winningNumbers;
        historyAmount[issueIndex] = calculateMatchingRewardAmount();
        drawingPhase = false;
        emit Drawing(issueIndex, winningNumbers);
    }

    function internalBuy(uint256 _price, uint8[4] memory _numbers) internal {
        require (!drawed(), 'drawed, can not buy now');
        for (uint i = 0; i < 4; i++) {
            require (_numbers[i] <= maxNumber, 'exceed the maximum');
        }
        uint256 tokenId = lotteryNFT.newLotteryItem(address(this), _numbers, _price, issueIndex);
        lotteryInfo[issueIndex].push(tokenId);
        totalAmount = totalAmount.add(_price);
        lastTimestamp = block.timestamp;
        emit Buy(address(this), tokenId);

    }

    function _buySingleTicket(uint256 _price, uint8[4] memory _numbers) private returns (uint256){
        for (uint i = 0; i < 4; i++) {
            require (_numbers[i] <= maxNumber, 'bad number');
        }
        uint256 tokenId = lotteryNFT.newLotteryItem(msg.sender, _numbers, _price, issueIndex);
        lotteryInfo[issueIndex].push(tokenId);
        if (userInfo[msg.sender].length == 0) {
            totalAddresses = totalAddresses + 1;
        }
        userInfo[msg.sender].push(tokenId);
        totalAmount = totalAmount.add(_price);
        lastTimestamp = block.timestamp;
        uint32[winningCombinations] memory userCombinations = generateCombinations(_numbers);
        for (uint i = 0; i < winningCombinations; i++) {
            userBuyAmountSum[issueIndex][userCombinations[i]]=userBuyAmountSum[issueIndex][userCombinations[i]].add(_price);
        }
        return tokenId;
    }

    function buy(uint256 _price, uint8[4] memory _numbers) external {
        require(!drawed(), 'drawed, can not buy now');
        require(!drawingPhase, 'drawing, can not buy now');
        require (_price >= minPrice, 'price must above minPrice');
        uint256 tokenId = _buySingleTicket(_price, _numbers);
        token.safeTransferFrom(address(msg.sender), address(this), _price);
        emit Buy(msg.sender, tokenId);
    }

    function multiBuy(uint256 _price, uint8[4][] memory _numbers) external {
        require (!drawed(), 'drawed, can not buy now');
        require (_price >= minPrice, 'price must above minPrice');
        uint256 totalPrice  = 0;
        for (uint i = 0; i < _numbers.length; i++) {
            _buySingleTicket(_price, _numbers[i]);
            totalPrice = totalPrice.add(_price);
        }
        token.safeTransferFrom(address(msg.sender), address(this), totalPrice);
        emit MultiBuy(msg.sender, totalPrice);
    }

    function claimReward(uint256 _tokenId) external {
        require(msg.sender == lotteryNFT.ownerOf(_tokenId), "not from owner");
        require (!lotteryNFT.getClaimStatus(_tokenId), "claimed");
        uint256 reward = getRewardView(_tokenId);
        lotteryNFT.claimReward(_tokenId);
        if(reward>0) {
            safeTokenTransfer(address(msg.sender), reward);
        }
        emit Claim(msg.sender, _tokenId, reward);
    }

    function multiClaim(uint256[] memory _tickets) external {
        uint256 totalReward = 0;
        for (uint i = 0; i < _tickets.length; i++) {
            require (msg.sender == lotteryNFT.ownerOf(_tickets[i]), "not from owner");
            require (!lotteryNFT.getClaimStatus(_tickets[i]), "claimed");
            uint256 reward = getRewardView(_tickets[i]);
            if(reward>0) {
                totalReward = reward.add(totalReward);
            }
        }
        lotteryNFT.multiClaimReward(_tickets);
        if(totalReward>0) {
            safeTokenTransfer(address(msg.sender), totalReward);
        }
        emit MultiClaim(msg.sender, totalReward);
    }

    function generateCombinations(uint8[4] memory number) public pure returns (uint32[winningCombinations] memory) {
        uint32 packedNumber = (number[0] << 24) + (number[1] << 16) + (number[2] << 8) + number[3];

        uint32[winningCombinations] memory combinations;

        //Match 4
        combinations[0] = packedNumber;

        //Match 3
        combinations[1] = packedNumber & 0x00FFFFFF;
        combinations[2] = packedNumber & 0xFF00FFFF;
        combinations[3] = packedNumber & 0xFFFF00FF;
        combinations[4] = packedNumber & 0xFFFFFF00;

        //Match 2
        combinations[5] = packedNumber & 0x0000FFFF;
        combinations[6] = packedNumber & 0x00FF00FF;
        combinations[7] = packedNumber & 0x00FFFF00;
        combinations[8] = packedNumber & 0xFF0000FF;
        combinations[9] = packedNumber & 0xFF00FF00;
        combinations[10] = packedNumber & 0xFFFF0000;

        return combinations;
    }

    function calculateMatchingRewardAmount() internal view returns (uint256[4] memory) {
        uint32[winningCombinations] memory combinations = generateCombinations(winningNumbers);

        uint256 totalMatched4 = userBuyAmountSum[issueIndex][combinations[0]];

        uint256 totalMatched3 = userBuyAmountSum[issueIndex][combinations[1]];
        totalMatched3 = totalMatched3.add(userBuyAmountSum[issueIndex][combinations[2]]);
        totalMatched3 = totalMatched3.add(userBuyAmountSum[issueIndex][combinations[3]]);
        totalMatched3 = totalMatched3.add(userBuyAmountSum[issueIndex][combinations[4]]);
        totalMatched3 = totalMatched3.sub(totalMatched4.mul(4)); //Remove overlaps from Matched4 users

        uint256 totalMatched2 = userBuyAmountSum[issueIndex][combinations[5]];
        totalMatched2 = totalMatched2.add(userBuyAmountSum[issueIndex][combinations[6]]);
        totalMatched2 = totalMatched2.add(userBuyAmountSum[issueIndex][combinations[7]]);
        totalMatched2 = totalMatched2.add(userBuyAmountSum[issueIndex][combinations[8]]);
        totalMatched2 = totalMatched2.add(userBuyAmountSum[issueIndex][combinations[9]]);
        totalMatched2 = totalMatched2.add(userBuyAmountSum[issueIndex][combinations[10]]);
        totalMatched2 = totalMatched2.sub(totalMatched3.mul(3)); //Remove overlaps from Matched3 users
        totalMatched2 = totalMatched2.sub(totalMatched4.mul(6)); //Remove overlaps from Matched4 users

        return [totalAmount, totalMatched4, totalMatched3, totalMatched2];
    }

    function getMatchingRewardAmount(uint256 _issueIndex, uint256 _matchingNumber) public view returns (uint256) {
        require(_matchingNumber >= 2 && _matchingNumber <= 4, "getMatchingRewardAmount: INVALID");
        return historyAmount[_issueIndex][5 - _matchingNumber];
    }

    function getTotalRewards(uint256 _issueIndex) public view returns(uint256) {
        require (_issueIndex <= issueIndex, '_issueIndex <= issueIndex');

        if(!drawed() && _issueIndex == issueIndex) {
            return totalAmount;
        }
        return historyAmount[_issueIndex][0];
    }

    function getRewardView(uint256 _tokenId) public view returns(uint256) {
        uint256 _issueIndex = lotteryNFT.getLotteryIssueIndex(_tokenId);
        uint8[4] memory lotteryNumbers = lotteryNFT.getLotteryNumbers(_tokenId);
        uint8[4] memory _winningNumbers = historyNumbers[_issueIndex];
        require(_winningNumbers[0] != 0, "not drawed");

        uint256 matchingNumber = 0;
        for (uint i = 0; i < lotteryNumbers.length; i++) {
            if (_winningNumbers[i] == lotteryNumbers[i]) {
                matchingNumber = matchingNumber + 1;
            }
        }
        uint256 reward = 0;
        if (matchingNumber > 1) {
            uint256 amount = lotteryNFT.getLotteryAmount(_tokenId);
            uint256 poolAmount = getTotalRewards(_issueIndex).mul(allocation[4-matchingNumber]).div(100);
            reward = amount.mul(1e12).mul(poolAmount).div(getMatchingRewardAmount(_issueIndex, matchingNumber));
        }
        return reward.div(1e12);
    }

    // Safe token transfer function, just in case if rounding error causes pool to not have enough Tokens.
    function safeTokenTransfer(address _to, uint256 _amount) internal {
        uint256 tokenBal = token.balanceOf(address(this));
        if (_amount > tokenBal) {
            token.transfer(_to, tokenBal);
        } else {
            token.transfer(_to, _amount);
        }
    }

    // Update admin address by the previous dev.
    function setAdmin(address _adminAddress) external onlyOwner {
        require(_adminAddress != address(0));
        adminAddress = _adminAddress;
        emit SetAdmin(msg.sender, _adminAddress);
    }

    // Withdraw without caring about rewards. EMERGENCY ONLY.
    function adminWithdraw(uint256 _amount) external onlyAdmin {
        token.safeTransfer(address(msg.sender), _amount);
        emit DevWithdraw(msg.sender, _amount);
    }

    // Set the minimum price for one ticket
    function setMinPrice(uint256 _price) external onlyAdmin {
        minPrice = _price;
        emit SetMinPrice(msg.sender, _price);
    }

    // Set the max number to be drawed
    function setMaxNumber(uint8 _maxNumber) external onlyAdmin {
        maxNumber = _maxNumber;
        emit SetMaxNumber(msg.sender, _maxNumber);
    }

    // Set the allocation for one reward
    function setAllocation(uint8 _allcation1, uint8 _allcation2, uint8 _allcation3) external onlyAdmin {
        allocation = [_allcation1, _allcation2, _allcation3];
        emit SetAllocation(msg.sender, _allcation1, _allcation2, _allcation3);
    }

}