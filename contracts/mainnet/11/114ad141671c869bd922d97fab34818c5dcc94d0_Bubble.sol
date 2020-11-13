pragma solidity ^0.5.0;

interface IERC20 {
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

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

contract Context {
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }
}

contract ERC20 is Context, IERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: mint to the zero address");

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "ERC20: burn from the zero address");

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner`s tokens.
     *
     * This is internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`.`amount` is then deducted
     * from the caller's allowance.
     *
     * See {_burn} and {_approve}.
     */
    function _burnFrom(address account, uint256 amount) internal {
        _burn(account, amount);
        _approve(
            account,
            _msgSender(),
            _allowances[account][_msgSender()].sub(
                amount,
                "ERC20: burn amount exceeds allowance"
            )
        );
    }
}

contract BubbleUtil {
    uint256 ethWei = 1 ether;
    uint256 public startTime;

    //limit user max calc ETH is 15 ether
    function getMaxEthMiner(uint256 value) public view returns (uint256) {
        if (value > 15 * ethWei) {
            return 15 * ethWei;
        }
        return value;
    }

    //limit user max calc BUB is frozenEth * 1000
    function getMaxBubMiner(uint256 frozenEth, uint256 value)
        public
        view
        returns (uint256)
    {
        if (value > (frozenEth / ethWei) * 100000) {
            return (frozenEth / ethWei) * 100000;
        }
        return value;
    }

    function getLevel(uint256 value) public view returns (uint256) {
        if (value >= 1 * ethWei && value < 6 * ethWei) {
            return 1;
        }
        if (value >= 6 * ethWei && value < 11 * ethWei) {
            return 2;
        }
        if (value >= 11 * ethWei) {
            return 3;
        }
        return 0;
    }

    function getBoostLevel(uint256 value) public view returns (uint256) {
        if (value >= 40000 && value < 150000) {
            return 1;
        }
        if (value >= 150000 && value < 200000) {
            return 2;
        }
        if (value >= 200000 && value < 800000) {
            return 3;
        }
        if (value >= 800000 && value < 4000000) {
            return 4;
        }
        if (value >= 4000000 && value < 20000000) {
            return 5;
        }
        if (value >= 20000000) {
            return 6;
        }
        return 0;
    }

    function getUserLevelCoefficient(uint256 level)
        public
        view
        returns (uint256)
    {
        //30%
        if (level == 1) {
            return 30;
        }
        //60%
        if (level == 2) {
            return 60;
        }
        //100%
        if (level >= 3) {
            return 100;
        }

        return 0;
    }

    function getUserBoostCoefficient(uint256 boostLevel)
        public
        view
        returns (uint256)
    {
        //150%
        if (boostLevel == 1) {
            return 150;
        }
        //170%
        if (boostLevel == 2) {
            return 170;
        }
        //200%
        if (boostLevel >= 3) {
            return 200;
        }
        return 100;
    }

    function getUserInviterBoostCoefficient(uint256 boostLevel)
        public
        view
        returns (uint256)
    {
        //120%
        if (boostLevel == 4) {
            return 120;
        }
        //150%
        if (boostLevel == 5) {
            return 150;
        }
        //200%
        if (boostLevel >= 6) {
            return 200;
        }
        return 100;
    }

    function getUserReinvestCoefficient(uint256 reinvestCount)
        public
        view
        returns (uint256)
    {
        //130%
        if (reinvestCount == 1) {
            return 130;
        }
        //170%
        if (reinvestCount == 2) {
            return 170;
        }
        //220%
        if (reinvestCount == 3) {
            return 220;
        }
        if (reinvestCount >= 4) {
            return 300;
        }
        return 100;
    }

    function getGameCoefficient() public view returns (uint256) {
        if (now < startTime + 14 days) {
            return 2;
        }
        return 1;
    }

    function compareStr(string memory _str, string memory str)
        public
        view
        returns (bool)
    {
        bool checkResult = false;
        if (
            keccak256(abi.encodePacked(_str)) ==
            keccak256(abi.encodePacked(str))
        ) {
            checkResult = true;
        }
        return checkResult;
    }
}

contract Bubble is BubbleUtil, ERC20 {
    using SafeMath for *;

    //Token
    string public name = "BubbleToken";
    string public symbol = "BUB";
    uint256 public decimals = 2;
    uint256 public INITIAL_SUPPLY = 10000000000;

    //Game
    address administrator;
    bool isGameOver;

    //0.3%
    uint256 public ETHCoefficient = 30;
    //15%
    uint256 public BUBCoefficient = 1500;
    //2%
    uint256 public JackpotCoefficient = 2;

    uint256 invitePoolTokenAmount;
    uint256 reservedTokenAmount;
    uint256 public diggedTokenAmount;
    uint256 public totalFrozenTokenAmount;
    uint256 LIMITREINVESTTIME = 12 hours;
    uint256 USERLOCKTIME = 5 days;
    uint256 GROWTHPERIOD = 20 days;

    constructor() public {
        //init token
        //0.2%
        _mint(msg.sender, INITIAL_SUPPLY / 500);

        _mint(address(this), (INITIAL_SUPPLY * 499) / 500);
        //1.8% to increase prize pool eth balance
        reservedTokenAmount = (INITIAL_SUPPLY * 9) / 500;
        //init game
        administrator = msg.sender;
        //2%
        invitePoolTokenAmount = INITIAL_SUPPLY / 50;
        isGameOver = false;
        startTime = now;
    }

    struct User {
        address payable userAddress;
        uint256 frozenToken;
        uint256 freeToken;
        uint256 frozenEth;
        uint256 freeEth;
        uint256 startTime;
        uint256 level;
        uint256 boostLevel;
        uint256 totalEthProfit;
        uint256 totalTokenProfit;
        uint256 inviteCount;
        uint256 inviteRewardEth;
        uint256 inviteRewardToken;
        uint256 reinvestCount;
        bool isSendV1Award;
        bool isSendV2Award;
        bool isSendV3Award;
        string inviteCode;
        string referrer;
        uint256 status;
    }

    mapping(address => User) users;
    mapping(string => address payable) addressMapping;

    address payable public jackpotAddr = address(0);
    address payable public devAddr = address(
        0xd7E023642177432b029A274fee54Fb134B829293
    );

    event InvestEvent(
        address indexed user,
        uint256 ethAmount,
        uint256 tokenAmount
    );

    modifier onlyOwner {
        require(
            msg.sender == administrator,
            "OnlyOwner methods called by non-owner."
        );
        _;
    }

    modifier isHuman() {
        address addr = msg.sender;
        uint256 codeLength;

        assembly {
            codeLength := extcodesize(addr)
        }
        require(codeLength == 0, "sorry humans only");
        require(tx.origin == msg.sender, "sorry, human only");
        _;
    }

    modifier checkStart() {
        require(now > startTime, "not start");
        _;
    }

    function() external payable {}

    function setJackpotAddress(address payable addr) public {
        //excute once
        if (jackpotAddr == address(0) && msg.sender == administrator) {
            jackpotAddr = addr;
        } else {
            revert();
        }
    }

    function registerUser(
        User storage userGlobal,
        address payable userAddress,
        string memory inviteCode,
        string memory referrer
    ) private {
        userGlobal.userAddress = userAddress;
        userGlobal.inviteCode = inviteCode;
        userGlobal.referrer = referrer;
        userGlobal.status = 0;
        address invitedAddress = getUserByInvitedCode(referrer);
        User storage invitedUser = users[invitedAddress];
        invitedUser.inviteCount = invitedUser.inviteCount + 1;

        addressMapping[inviteCode] = userAddress;
    }

    function registerUserByOwner(
        address payable userAddress,
        string memory inviteCode,
        string memory referrer
    ) public onlyOwner() {
        User storage user = users[userAddress];
        require(user.userAddress == address(0), "user is exist");
        require(isCodeUsed(inviteCode) == false, "invite code is used");
        registerUser(user, userAddress, inviteCode, referrer);
    }

    function invest(
        uint256 tokenAmount,
        string memory inviteCode,
        string memory referrer
    ) public payable isHuman() checkStart() {
        require(!isGameOver, "game is over");

        address payable userAddress = msg.sender;
        uint256 ethAmount = msg.value;

        //check token balance
        require(
            balanceOf(userAddress) >= tokenAmount,
            "token balance is insufficient"
        );

        User storage user = users[userAddress];

        //register
        if (user.userAddress == address(0)) {
            require(!compareStr(inviteCode, ""), "empty invite code");
            address referrerAddr = getUserByInvitedCode(referrer);
            require(referrerAddr != address(0), "referrer not exist");
            require(referrerAddr != userAddress, "referrer can't be self");
            require(isCodeUsed(inviteCode) == false, "invite code is used");
            registerUser(user, userAddress, inviteCode, referrer);
        }

        if (tokenAmount > 0) {
            transfer(address(this), tokenAmount);
        }

        //invest first
        if (user.status == 0 || user.status == 2) {
            restartUser(user, ethAmount, tokenAmount);
        } else {
            require(user.status == 1, "user status error");

            // user can additional investment in 1 day
            require(
                now < user.startTime + LIMITREINVESTTIME,
                "over the stipulated time, account is locked"
            );
            //reset start time
            restartUser(user, ethAmount, tokenAmount);
        }

        require(user.frozenEth + ethAmount >= 1 * ethWei, "greater than 1 eth");

        calcInvitedAndSendAward(user);

        user.level = getLevel(user.frozenEth);
        user.boostLevel = getBoostLevel(user.frozenToken);

        if (ethAmount >= 0) {
            sendFeeToJackpot(ethAmount);
            sendFeeToAdmin(ethAmount);
        }

        emit InvestEvent(userAddress, ethAmount, tokenAmount);
    }

    function reinvest() public isHuman() {
        require(!isGameOver, "game is over");

        User storage user = users[msg.sender];
        uint256 unlockTime = getUserUnlockTime(user.startTime);

        require(now > unlockTime, "user is locking");
        require(user.status == 1, "user status err");

        //empty frozen ETH
        settleAccount(user);

        require(user.freeEth > 1 * ethWei, "greater than 1 eth");

        uint256 reinvestEth = user.freeEth;
        user.freeEth = 0;

        uint256 reinvestToken = user.freeToken;
        user.freeToken = 0;

        //reset frozen Eth
        restartUser(user, reinvestEth, reinvestToken);

        calcInvitedAndSendAward(user);
        user.level = getLevel(user.frozenEth);
        user.boostLevel = getBoostLevel(user.frozenToken);
        user.reinvestCount = user.reinvestCount + 1;

        sendFeeToJackpot(reinvestEth);
        sendFeeToAdmin(reinvestEth);

        emit InvestEvent(user.userAddress, reinvestEth, reinvestToken);
    }

    function withdraw() public isHuman() checkStart() {
        User storage user = users[msg.sender];

        //withdraw will set reinvest to 0
        user.reinvestCount = 0;

        settleAccount(user);

        uint256 sendMoney = user.freeEth;
        uint256 sendToken = user.freeToken;
        bool isEthEnough = false;
        bool isTokenEnough = false;
        uint256 resultMoney = 0;
        uint256 resultToken = 0;

        (isEthEnough, resultMoney) = isEthBalanceEnough(sendMoney);
        (isTokenEnough, resultToken) = isTokenBalanceEnough(sendToken);

        if (resultMoney > 0) {
            user.freeEth = user.freeEth.sub(resultMoney);
            msg.sender.transfer(resultMoney);
        }
        if (resultToken > 0) {
            user.freeToken = user.freeToken.sub(resultToken);
            sendTokenTo(msg.sender, resultToken);
        }

        if (!isEthEnough) {
            endRound();
        }
    }

    function getUserByInvitedCode(string memory code)
        public
        view
        returns (address)
    {
        return addressMapping[code];
    }

    function restartUser(
        User storage user,
        uint256 ethAmount,
        uint256 tokenAmount
    ) private {
        user.frozenEth = user.frozenEth.add(ethAmount);
        user.frozenToken = user.frozenToken.add(tokenAmount);
        user.startTime = now;
        user.status = 1;
        totalFrozenTokenAmount = totalFrozenTokenAmount + tokenAmount;
    }

    function settleAccount(User storage user) private returns (bool) {
        uint256 unlockTime = getUserUnlockTime(user.startTime);

        if (user.status == 1 && now > unlockTime) {
            totalFrozenTokenAmount = totalFrozenTokenAmount - user.frozenToken;
            uint256 calcEth = getMaxEthMiner(user.frozenEth);
            uint256 earningMoney = getUserEthEarning(user.userAddress, calcEth);
            uint256 calcBub = getMaxBubMiner(user.frozenEth, user.frozenToken);
            uint256 earningToken = getUserTokenEarning(
                user.userAddress,
                calcBub
            );
            user.freeToken = user.freeToken + user.frozenToken + earningToken;
            user.freeEth = user.freeEth + user.frozenEth + earningMoney;
            user.totalEthProfit = user.totalEthProfit + earningMoney;
            user.totalTokenProfit = user.totalTokenProfit + earningToken;
            user.frozenEth = 0;
            user.frozenToken = 0;
            user.level = 0;
            user.status = 2;
            user.isSendV1Award = false;
            user.isSendV2Award = false;
            user.isSendV3Award = false;
            address inviter = getUserByInvitedCode(user.referrer);
            sendInviteReward(earningMoney, inviter);
            diggedTokenAmount = diggedTokenAmount + earningToken;
            return true;
        }
        return false;
    }

    function sendInviteReward(uint256 earningMoney, address inviter) private {
        User storage user = users[inviter];
        uint256 inviteEarning = 0;
        inviteEarning =
            (earningMoney *
                getUserLevelCoefficient(user.level) *
                getUserInviterBoostCoefficient(user.boostLevel)) /
            (100 * 100 * 2);
        if (inviteEarning > 0) {
            user.freeEth = user.freeEth + inviteEarning;
            user.inviteRewardEth = user.inviteRewardEth + inviteEarning;
        }
    }

    function getUserUnlockTime(uint256 startTime)
        public
        view
        returns (uint256)
    {
        return startTime + USERLOCKTIME;
    }

    function getUserTokenEarning(address userAddress, uint256 frozenToken)
        private
        view
        returns (uint256)
    {
        //500 /10000 = 5%
        return (frozenToken * getUserEarningRatio(userAddress, false)) / 10000;
    }

    function getUserEarningRatio(address userAddress, bool isEth)
        public
        view
        returns (uint256)
    {
        User memory user = users[userAddress];
        if (user.status == 1) {
            if (isEth) {
                //default 0.3% per day
                uint256 defaultCoefficient = ETHCoefficient;
                defaultCoefficient =
                    (defaultCoefficient *
                        getGameCoefficient() *
                        getUserLevelCoefficient(user.level) *
                        getUserBoostCoefficient(user.boostLevel) *
                        getUserReinvestCoefficient(user.reinvestCount)) /
                    (100 * 100 * 100);
                return defaultCoefficient;
            } else {
                //default 5% per round
                uint256 defaultCoefficient = BUBCoefficient;
                defaultCoefficient =
                    (defaultCoefficient *
                        getGameCoefficient() *
                        getUserLevelCoefficient(user.level) *
                        getUserReinvestCoefficient(user.reinvestCount)) /
                    (100 * 100);
                return defaultCoefficient;
            }
        }
        return 0;
    }

    function getUserEthEarning(address userAddress, uint256 frozenEth)
        private
        view
        returns (uint256)
    {
        // 30 / 10000 = 0.3%
        uint256 dailyProfit = (frozenEth *
            getUserEarningRatio(userAddress, true)) / 10000;

        return dailyProfit * 5;
    }

    function isEthBalanceEnough(uint256 sendMoney)
        private
        view
        returns (bool, uint256)
    {
        if (address(this).balance > 0) {
            if (sendMoney >= address(this).balance) {
                return (false, address(this).balance);
            } else {
                return (true, sendMoney);
            }
        } else {
            return (false, 0);
        }
    }

    function isTokenBalanceEnough(uint256 sendMoney)
        private
        view
        returns (bool, uint256)
    {
        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
            if (sendMoney >= tokenBalance) {
                return (false, tokenBalance);
            } else {
                return (true, sendMoney);
            }
        } else {
            return (false, 0);
        }
    }

    function calcInvitedAndSendAward(User storage user) private {
        uint256 currentLvel = getLevel(user.frozenEth);
        uint256 sendToken = 0;
        if (currentLvel >= 1 && !user.isSendV1Award) {
            sendToken += 20000;
            user.isSendV1Award = true;
        }

        if (currentLvel >= 2 && !user.isSendV2Award) {
            sendToken += 40000;
            user.isSendV2Award = true;
        }

        if (currentLvel >= 3 && !user.isSendV3Award) {
            sendToken += 40000;
            user.isSendV3Award = true;
        }

        address inviterAddress = getUserByInvitedCode(user.referrer);
        if (
            invitePoolTokenAmount >= sendToken &&
            balanceOf(address(this)) >= sendToken &&
            sendToken > 0
        ) {
            invitePoolTokenAmount -= sendToken;
            User storage inviter = users[inviterAddress];
            if (inviter.level > 0) {
                inviter.freeToken = inviter.freeToken + sendToken;
                inviter.inviteRewardToken =
                    inviter.inviteRewardToken +
                    sendToken;
            }
        }
    }

    function sendFeeToJackpot(uint256 amount) private {
        jackpotAddr.transfer(amount.mul(JackpotCoefficient).div(100));
    }

    function sendFeeToAdmin(uint256 amount) private {
        devAddr.transfer(amount.mul(5).div(100));
    }

    function sendTokenTo(address recipient, uint256 amount) private {
        _transfer(address(this), recipient, amount);
    }

    function isCodeUsed(string memory code) public view returns (bool) {
        address user = getUserByInvitedCode(code);
        return user != address(0);
    }

    function getUserInfo(address user)
        public
        view
        returns (
            uint256[18] memory ct,
            string memory inviteCode,
            string memory referrer
        )
    {
        User memory userInfo = users[user];
        ct[0] = userInfo.frozenToken;
        ct[1] = userInfo.frozenEth;
        ct[2] = userInfo.startTime;
        ct[3] = getUserUnlockTime(userInfo.startTime);
        ct[4] = userInfo.level;
        ct[5] = userInfo.status;
        ct[6] = userInfo.totalEthProfit;
        ct[7] = userInfo.totalTokenProfit;
        ct[8] = userInfo.reinvestCount;
        ct[9] = userInfo.inviteCount;
        ct[10] = userInfo.isSendV1Award ? 1 : 0;
        ct[11] = userInfo.isSendV2Award ? 1 : 0;
        ct[12] = userInfo.isSendV3Award ? 1 : 0;
        ct[13] = userInfo.boostLevel;
        ct[14] = userInfo.freeEth;
        ct[15] = userInfo.freeToken;
        ct[16] = userInfo.inviteRewardEth;
        ct[17] = userInfo.inviteRewardToken;

        inviteCode = userInfo.inviteCode;
        referrer = userInfo.referrer;

        return (ct, inviteCode, referrer);
    }

    function endRound() private {
        if (now > startTime + GROWTHPERIOD) {
            isGameOver = true;
        }
    }

    //Game Coefficient
    // vote to change
    function resetETHCoefficient(uint256 Coefficient) public onlyOwner() {
        require(Coefficient > 0);
        ETHCoefficient = Coefficient;
    }

    // vote to change
    function resetBUBCoefficient(uint256 Coefficient) public onlyOwner() {
        require(Coefficient > 0);
        BUBCoefficient = Coefficient;
    }

    //20 days to 3%; 30 days to 4%; 40 days to 5%
    function resetJackpotcCoefficient(uint256 Coefficient) public onlyOwner() {
        require(Coefficient > 0);
        JackpotCoefficient = Coefficient;
    }

    function drawAward() public onlyOwner() {
        //total 1.8%
        uint256 totalAmount = (INITIAL_SUPPLY * 9) / 500;
        uint256 eachAmount = totalAmount / 10;
        if (
            jackpotAddr.balance >= 100 * ethWei &&
            reservedTokenAmount == eachAmount * 10
        ) {
            reservedTokenAmount = reservedTokenAmount - eachAmount;
            sendTokenTo(msg.sender, eachAmount);
        } else if (
            jackpotAddr.balance >= 150 * ethWei &&
            reservedTokenAmount == eachAmount * 9
        ) {
            reservedTokenAmount = reservedTokenAmount - eachAmount;
            sendTokenTo(msg.sender, eachAmount);
        } else if (
            jackpotAddr.balance >= 200 * ethWei &&
            reservedTokenAmount == eachAmount * 8
        ) {
            reservedTokenAmount = reservedTokenAmount - eachAmount;
            sendTokenTo(msg.sender, eachAmount);
        } else if (
            jackpotAddr.balance >= 250 * ethWei &&
            reservedTokenAmount == eachAmount * 7
        ) {
            reservedTokenAmount = reservedTokenAmount - eachAmount;
            sendTokenTo(msg.sender, eachAmount);
        } else if (
            jackpotAddr.balance >= 300 * ethWei &&
            reservedTokenAmount == eachAmount * 6
        ) {
            reservedTokenAmount = reservedTokenAmount - eachAmount;
            sendTokenTo(msg.sender, eachAmount);
        } else if (
            jackpotAddr.balance >= 400 * ethWei &&
            reservedTokenAmount == eachAmount * 5
        ) {
            reservedTokenAmount = reservedTokenAmount - eachAmount;
            sendTokenTo(msg.sender, eachAmount);
        } else if (
            jackpotAddr.balance >= 500 * ethWei &&
            reservedTokenAmount == eachAmount * 4
        ) {
            reservedTokenAmount = reservedTokenAmount - eachAmount;
            sendTokenTo(msg.sender, eachAmount);
        } else if (
            jackpotAddr.balance >= 600 * ethWei &&
            reservedTokenAmount == eachAmount * 3
        ) {
            reservedTokenAmount = reservedTokenAmount - eachAmount;
            sendTokenTo(msg.sender, eachAmount);
        } else if (
            jackpotAddr.balance >= 700 * ethWei &&
            reservedTokenAmount == eachAmount * 2
        ) {
            reservedTokenAmount = reservedTokenAmount - eachAmount;
            sendTokenTo(msg.sender, eachAmount);
        } else if (
            jackpotAddr.balance >= 800 * ethWei &&
            reservedTokenAmount == eachAmount
        ) {
            reservedTokenAmount = reservedTokenAmount - eachAmount;
            sendTokenTo(msg.sender, eachAmount);
        }
    }

    //Jackpot call
    function getGameOverStatus() external view returns (bool) {
        return isGameOver;
    }

    function transferAllEthToJackPot() external {
        if (!isGameOver) {
            jackpotAddr.transfer(address(this).balance);
        }
    }

    function sendTokenToJackpot(address sender, uint256 amount) external {
        require(msg.sender == jackpotAddr, "call only by jackpot");
        _transfer(sender, jackpotAddr, amount);
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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
}