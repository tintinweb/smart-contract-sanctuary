/**
 *Submitted for verification at BscScan.com on 2021-12-15
*/

pragma solidity ^0.8.9;

//SPDX-License-Identifier: MIT Licensed

interface IBEP20 {
    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
}

interface AggregatorV3Interface {
    function decimals() external view returns (uint8);

    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract VerifySignature {
    address internal signer;

    function verify(
        address _user,
        uint256[3] memory _slotsQty,
        uint256 _nonce,
        bytes memory _sign
    ) public view returns (bool) {
        bytes32 messageHash = getMessageHash(_user, uint2str(_slotsQty[0]), uint2str(_slotsQty[1]), uint2str(_slotsQty[2]), uint2str(_nonce));
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageHash);

        return recoverSigner(ethSignedMessageHash, _sign) == signer;
    }

    function getMessageHash(
        address _user,
        string memory _slotsQty1,
        string memory _slotsQty2,
        string memory _slotsQty3,
        string memory _nonce
    ) private pure returns (bytes32) {
        return keccak256(abi.encodePacked(_user, _slotsQty1, _slotsQty2, _slotsQty3, _nonce));
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        private
        pure
        returns (bytes32)
    {
        /*
        Signature is produced by signing a keccak256 hash with the following format:
        "\x19Ethereum Signed Message\n" + len(msg) + msg
        */
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recoverSigner(
        bytes32 _ethSignedMessageHash,
        bytes memory _signature
    ) private pure returns (address) {
        (bytes32 r, bytes32 s, uint8 v) = splitSignature(_signature);

        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function splitSignature(bytes memory sig)
        private
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(sig.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(sig, 32))
            // second 32 bytes
            s := mload(add(sig, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(sig, 96)))
        }
    }

    function uint2str(uint _i) private pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }
}

contract PreSaleContract is VerifySignature {
    using SafeMath for uint256;

    address payable public owner;
    // Token address
    IBEP20 public kredToken;
    IBEP20 public jedToken;
    // 0 USDT, 1 DAI, 2 BUSD
    address[3] public coins;
    AggregatorV3Interface internal priceFeed;

    // Contract States
    uint256 public preSaleStartTime;
    uint256 public preSaleEndTime;
    uint256 public soldToken;
    uint256 public amountRaised;
    uint256 public timeStep = 5 minutes;
    uint256 public percentDivider = 100;
    mapping(address => uint256) public nonce;
    uint256 public claimStartTime;
    uint256 public minJedTokens;
    bool public isClaimEnabled;

    uint256[5] public tokensPerSlot = [
        100000000e18,
        33333333e18,
        10000000e18,
        500000000e18,
        400000000e18
    ];
    // Whitelist Presale
    uint256[6] public whitelistClaimAmountU1 = [10, 10, 20, 20, 20, 20];
    uint256[6] public whitelistClaimAmountU2 = [25, 15, 15, 15, 15, 15];
    // Public Presale
    uint256[5] public usdSlots = [4000, 2000, 800, 10000, 8000];
    uint256[5] public totalClaims = [4, 2, 1, 6, 6];

    struct Slot {
        uint256 tokenBalance;
        uint256 totalClaimedTokens;
        uint256 remainingClaims;
        uint256[4] claimDate;
        uint256[] claimPercentage;
    }

    mapping(address => mapping(uint256 => Slot)) public users;
    mapping(address => uint256) public nextUnlockDate;
    mapping(address => bool) public whitelist;
    mapping(address => uint256) public claimTime;

    modifier onlyOwner() {
        require(msg.sender == owner, "PreSale: Not an owner");
        _;
    }

    modifier isWhitelisted(address _user) {
        require(whitelist[_user], "PreSale: Not a vip user");
        _;
    }

    modifier isVerified(
        address _user,
        uint256[3] memory _slotsQty,
        uint256 _nonce,
        bytes memory _sign
    ) {
        require(_nonce > nonce[msg.sender], "Presale: invalid nonce");
        require(
            verify(_user, _slotsQty, _nonce, _sign),
            "Presale: Unverified."
        );
        _;
    }

    event BuyToken(address _user, uint256 _amount);
    event ClaimToken(address _user, uint256 _amount);

    constructor(
        // address payable _owner,
        // IBEP20 _kredToken,
        // IBEP20 _jedToken,
        // address _signer
    ) {
        owner = payable(0x4b371A173cE974059F43D8219Cfc1972187822a8);
        kredToken = IBEP20(0x5c4A207620b67e93C447fF9A93627f8cb626Fda6);
        jedToken = IBEP20(0x5c4A207620b67e93C447fF9A93627f8cb626Fda6);
        signer = 0x7eA759BD08Aa1F4764688badaC7e6E87059c7243;
        coins[0] = 0x5c4A207620b67e93C447fF9A93627f8cb626Fda6; // USDT
        coins[1] = 0x5c4A207620b67e93C447fF9A93627f8cb626Fda6; // DAI
        coins[2] = 0x5c4A207620b67e93C447fF9A93627f8cb626Fda6; // BUSD
        priceFeed = AggregatorV3Interface(
            0x2514895c72f50D8bd4B4F9b1110F0D6bD2c97526
        );
        minJedTokens = 1000 * 10**(jedToken.decimals());
        // Setting presale time.
        preSaleStartTime = block.timestamp;
        preSaleEndTime = block.timestamp + timeStep;
    }

    receive() external payable {}

    // to buy token during public preSale time => for web3 use
    function buyTokenBNB(
        uint256[3] memory _slotsQty,
        uint256 _nonce,
        bytes memory _sign
    ) public payable isVerified(msg.sender, _slotsQty, _nonce, _sign) {
        require(_slotsQty.length == 3, "Invalid Slots");
        require(
            jedToken.balanceOf(msg.sender) >= 1000e18,
            "Insufficient JED Tokens."
        );
        require(
            block.timestamp >= preSaleStartTime,
            "PreSale: PreSale not started yet"
        );
        require(block.timestamp < preSaleEndTime, "PreSale: PreSale over");
        // Check requried bnb for slot.
        uint256 totalUsd = usdSlots[0].mul(_slotsQty[0]);
        totalUsd = totalUsd.add(usdSlots[1].mul(_slotsQty[1]));
        totalUsd = totalUsd.add(usdSlots[2].mul(_slotsQty[2]));
        require(msg.value >= usdToBNB(totalUsd), "PreSale: Invalid Amount");
        amountRaised = amountRaised.add(totalUsd);

        uint256 totalTokens;
        for (uint256 i = 0; i < 3; i++) {
            if (_slotsQty[i] > 0) {
                _updateUserData(msg.sender, i, _slotsQty[i]);

                // Event trigger.
                totalTokens = totalTokens.add(
                    tokensPerSlot[i].mul(_slotsQty[i])
                );
            }
        }

        require(totalTokens > 0, "Presale: not buy any slot.");
        kredToken.transferFrom(owner, address(this), totalTokens);
        nonce[msg.sender] = _nonce;
        emit BuyToken(msg.sender, totalTokens);
    }

    // to buy token during public preSale time => for web3 use
    function buyToken(
        uint256 choice,
        uint256[3] memory _slotsQty,
        uint256 _nonce,
        bytes memory _sign
    ) public isVerified(msg.sender, _slotsQty, _nonce, _sign) {
        require(_slotsQty.length == 3, "Invalid Slots");
        require(choice < coins.length, "Invalid token");
        require(
            jedToken.balanceOf(msg.sender) >= 1000e18,
            "Insufficient JED Tokens."
        );
        require(
            block.timestamp >= preSaleStartTime,
            "PreSale: PreSale not started yet"
        );
        require(block.timestamp < preSaleEndTime, "PreSale: PreSale over");

        uint256 totalUsd = usdSlots[0].mul(_slotsQty[0]);
        totalUsd = totalUsd.add(usdSlots[1].mul(_slotsQty[1]));
        totalUsd = totalUsd.add(usdSlots[2].mul(_slotsQty[2]));
        uint256 totDecimals = 10**IBEP20(coins[choice]).decimals();
        IBEP20(coins[choice]).transferFrom(
            msg.sender,
            owner,
            totalUsd.mul(totDecimals)
        );
        amountRaised = amountRaised.add(totalUsd);

        uint256 totalTokens;
        for (uint256 i = 0; i < 3; i++) {
            if (_slotsQty[i] > 0) {
                _updateUserData(msg.sender, i, _slotsQty[i]);

                // Event trigger.
                totalTokens = totalTokens.add(
                    tokensPerSlot[i].mul(_slotsQty[i])
                );
            }
        }

        require(totalTokens > 0, "Presale: not buy any slot.");
        kredToken.transferFrom(owner, address(this), totalTokens);
        nonce[msg.sender] = _nonce;
        emit BuyToken(msg.sender, totalTokens);
    }

    function _updateUserData(
        address _user,
        uint256 slotIndex,
        uint256 _qty
    ) private {
        // Set User data.
        users[_user][slotIndex].tokenBalance = users[_user][slotIndex]
            .tokenBalance
            .add(tokensPerSlot[slotIndex].mul(_qty));
        users[_user][slotIndex].remainingClaims = totalClaims[slotIndex];

        // Set total info
        soldToken = soldToken.add(tokensPerSlot[slotIndex].mul(_qty));
    }

    // to claim tokens in vesting => for web3 use
    function claim() public {
        // Claim checks.
        require(isClaimEnabled, "Presale: Claim not started yet");
        require(
            getUserTotalTokens(msg.sender) > 0,
            "Presale: Insufficient Balance"
        );
        // Check if claim date is available
        if (nextUnlockDate[msg.sender] == 0) {
            require(
                block.timestamp > claimStartTime + timeStep,
                "Presale: Wait for first claim."
            );
            nextUnlockDate[msg.sender] = claimStartTime.add(timeStep.mul(2));
        } else {
            require(
                block.timestamp > nextUnlockDate[msg.sender],
                "Presale: Wait for next claim."
            );
            nextUnlockDate[msg.sender] = nextUnlockDate[msg.sender].add(
                timeStep
            );
        }

        uint256 totalClaimeable;
        for (uint256 slotIndex = 0; slotIndex < usdSlots.length; slotIndex++) {
            if (users[msg.sender][slotIndex].tokenBalance > 0) {
                totalClaimeable = totalClaimeable.add(
                    _claim(msg.sender, slotIndex)
                );
            }
        }

        require(totalClaimeable > 0, "No claimable balance.");
        kredToken.transfer(msg.sender, totalClaimeable);
        emit ClaimToken(msg.sender, totalClaimeable);
    }

    function _claim(address _user, uint256 slotIndex) public returns (uint256) {
        // Claim checks.
        Slot storage user = users[_user][slotIndex];
        if (user.remainingClaims == 0) {
            return 0;
        }

        // Claim processing.
        uint256 BASE_PERCENT = percentDivider.div(totalClaims[slotIndex]);
        // Get Dividend by user type
        uint256 dividends;
        if (slotIndex > 2) {
            uint256 claimIndex = user.claimPercentage.length -
                user.remainingClaims;
            dividends = user
                .tokenBalance
                .mul(user.claimPercentage[claimIndex])
                .div(percentDivider);
        } else {
            dividends = user.tokenBalance.mul(BASE_PERCENT).div(percentDivider);
        }

        // Setting next claim date.
        user.totalClaimedTokens = user.totalClaimedTokens.add(dividends);
        user.remainingClaims = user.remainingClaims.sub(1);

        return dividends;
    }

    // set presale for whitelist users.
    function setEthUsers(
        address[] memory _users,
        uint256[] memory _firstSlots,
        uint256[] memory _secondSlots,
        uint256[] memory _thirdSlots
    ) public {
        require(
            _users.length == _firstSlots.length,
            "Users and first slots are not equal"
        );
        require(
            _users.length == _secondSlots.length,
            "Users and second slots are not equal"
        );
        require(
            _users.length == _thirdSlots.length,
            "Users and third slots are not equal"
        );

        uint256 totalTokens;
        for (uint256 i = 0; i < _users.length; i++) {
            totalTokens = totalTokens.add(
                _firstSlots[i].add(_secondSlots[i]).add(_thirdSlots[i])
            );
            // Setting first slot user data.
            if (_firstSlots[i] > 0) {
                users[_users[i]][0].tokenBalance = users[_users[i]][0]
                    .tokenBalance
                    .add(_firstSlots[i]);
                users[_users[i]][0].remainingClaims = totalClaims[0];
            }
            // Setting second slot user data.
            if (_secondSlots[i] > 0) {
                users[_users[i]][1].tokenBalance = users[_users[i]][1]
                    .tokenBalance
                    .add(_secondSlots[i]);
                users[_users[i]][1].remainingClaims = totalClaims[1];
            }
            // Setting third slot user data.
            if (_thirdSlots[i] > 0) {
                users[_users[i]][2].tokenBalance = users[_users[i]][2]
                    .tokenBalance
                    .add(_thirdSlots[i]);
                users[_users[i]][2].remainingClaims = totalClaims[2];
            }
        }
        kredToken.transferFrom(owner, address(this), totalTokens);
        soldToken = soldToken.add(totalTokens);
    }

    // set presale for whitelist users.
    function setVipUsers(
        address[] memory _users,
        uint256[] memory _firstSlots,
        uint256[] memory _secondSlots
    ) public {
        require(
            _users.length == _firstSlots.length,
            "Users and first slots are not equal"
        );
        require(
            _users.length == _secondSlots.length,
            "Users and second slots are not equal"
        );

        uint256 totalTokens;
        for (uint256 i = 0; i < _users.length; i++) {
            totalTokens = totalTokens.add(_firstSlots[i].add(_secondSlots[i]));
            // Setting first vip slot user data.
            if (_firstSlots[i] > 0) {
                users[_users[i]][3].tokenBalance = users[_users[i]][3]
                    .tokenBalance
                    .add(_firstSlots[i]);
                users[_users[i]][3].remainingClaims = totalClaims[3];
                users[_users[i]][3].claimPercentage = whitelistClaimAmountU1;
            }
            // Setting second vip slot user data.
            if (_secondSlots[i] > 0) {
                users[_users[i]][4].tokenBalance = users[_users[i]][4]
                    .tokenBalance
                    .add(_secondSlots[i]);
                users[_users[i]][4].remainingClaims = totalClaims[4];
                users[_users[i]][4].claimPercentage = whitelistClaimAmountU2;
            }

            // settting total.
            whitelist[_users[i]] = true;
        }
        kredToken.transferFrom(owner, address(this), totalTokens);
        soldToken = soldToken.add(totalTokens);
    }

    function getUserTotalTokens(address _user)
        public
        view
        returns (uint256 total)
    {
        for (uint256 i = 0; i < usdSlots.length; i++) {
            total = total.add(users[_user][i].tokenBalance);
        }
    }

    function usdToBNB(uint256 value) public view returns (uint256) {
        uint256 reqBNB = getBNB(value.mul(10**priceFeed.decimals()));
        return reqBNB.mul(1e10);
    }

    function getBNB(uint256 _usd) private view returns (uint256) {
        return _usd.mul(10**priceFeed.decimals()).div(getLatestPriceBNB());
    }

    function getLatestPriceBNB() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        return uint256(price);
    }

    function getUserSlotInfo(address _user, uint256 slotIndex)
        public
        view
        returns (
            uint256 purchases,
            uint256 claimed_tokens,
            uint256 next_claim_date,
            uint256 next_claim_amount
        )
    {
        require(slotIndex < 5, "Presale: Invalid Slot");

        Slot storage user = users[_user][slotIndex];
        uint256 BASE_PERCENT = percentDivider.div(totalClaims[slotIndex]);
        // Get Dividend by user type
        uint256 dividends;
        if (user.remainingClaims > 0) {
            if (slotIndex > 2) {
                uint256 claimIndex = user.claimPercentage.length -
                    user.remainingClaims;
                dividends = user
                    .tokenBalance
                    .mul(user.claimPercentage[claimIndex])
                    .div(percentDivider);
            } else {
                dividends = user.tokenBalance.mul(BASE_PERCENT).div(
                    percentDivider
                );
            }
        }

        uint256 _nextUnlockDate = nextUnlockDate[_user];
        if (claimStartTime != 0 && nextUnlockDate[_user] == 0) {
            _nextUnlockDate = claimStartTime + timeStep;
        }

        return (
            user.tokenBalance,
            user.totalClaimedTokens,
            _nextUnlockDate,
            dividends
        );
    }

    function startClaim() public onlyOwner {
        require(
            block.timestamp > preSaleEndTime && !isClaimEnabled,
            "Presale: Not over yet."
        );
        isClaimEnabled = true;
        claimStartTime = block.timestamp;
    }

    function updatePriceAggregator(address _feedAddress) public onlyOwner {
        priceFeed = AggregatorV3Interface(_feedAddress);
    }

    function setPublicPreSale(uint256 _startTime, uint256 _endTime)
        external
        onlyOwner
    {
        preSaleStartTime = _startTime;
        preSaleEndTime = _endTime;
    }

    function changeOwner(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function changeSigner(address _newSigner) external onlyOwner {
        signer = _newSigner;
    }

    function changeKredToken(address _token) external onlyOwner {
        kredToken = IBEP20(_token);
    }

    function changeJedToken(address _token) external onlyOwner {
        jedToken = IBEP20(_token);
    }

    function updateCoinAddress(uint256 choice, address _token)
        external
        onlyOwner
    {
        require(choice < coins.length, "Invalid token");
        coins[choice] = _token;
    }

    function setClaimDuration(uint256 _duration) external onlyOwner {
        timeStep = _duration;
    }

    function setDenominator(uint256 _amount) external onlyOwner {
        percentDivider = _amount;
    }

    // to draw funds
    function withdrawBNB(uint256 _value) external onlyOwner {
        payable(owner).transfer(_value);
    }

    function withdrawToken(address _token, uint256 _value) external onlyOwner {
        require(IBEP20(_token) != kredToken, "Invalid token");
        IBEP20(_token).transfer(owner, _value);
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}