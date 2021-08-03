/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

pragma solidity >=0.5.1;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
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
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function burn(uint256 amount) external returns (bool success);

    function burnFrom(address account, uint256 amount) external returns (bool success);
}

contract aaa {

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    using SafeMath for uint256;

    struct User {
        uint256 totalAmount;
        uint256 totalBonus;
    }

    struct Order {
        address stakeAddress;
        uint256 amount;
        uint256 time;
        uint256 bonus;
        uint256 rate;
        uint8 valid;
        uint8 access;
        uint8 alterCount;
    }

    string prikey = "aaabbbccc";
    uint256 tokenDecimals = 6;
    uint256 ONE_TOKEN = 10 ** tokenDecimals;
    uint256 min_amount = 100 * (10 ** tokenDecimals);
    uint256 one_day = 60;
    uint256 feePercent = 100;
    uint256 percent10000 = 10000;
    uint256 fee_percent10 = 10;
    address usdtToken = 0x0fE2027DcfE73AfAeb45D5d70379c8b3b04116f2;
    address rewardToken = 0x0fE2027DcfE73AfAeb45D5d70379c8b3b04116f2;
    Order[] public orderArr;
    mapping(bytes32 => uint256)  wHashMap;
    mapping(bytes32 => uint256)  fHashMap;
    mapping(bytes32 => uint256)  cHashMap;

    mapping(address => User) userMap;


    uint256 oneRewardToken;
    uint256 rewardEndTime;

    uint256 accessTokenAmount;
    mapping(uint256 => uint256) resetRateTokenAmountMap;
    uint256 resetRateLimit;
    uint256 MAX_INT = uint256(- 1) - 100;

    address owner;
    address admin;
    modifier onlyOwner() {
        require(tx.origin == owner || tx.origin == admin, "Ownable: caller is not the owner");
        _;
    }

    uint256 nonceCall;
    modifier changeNonce(){
        nonceCall++;
        _;
        if (nonceCall > MAX_INT) {
            nonceCall = 0;
        }
    }

    constructor() public {
        owner = msg.sender;
        admin = msg.sender;
        _init();
    }

    function _init() internal {
        resetRateTokenAmountMap[0] = 5 * ONE_TOKEN;
        resetRateTokenAmountMap[1] = 10 * ONE_TOKEN;
        resetRateTokenAmountMap[2] = 20 * ONE_TOKEN;
        resetRateLimit = 3;
        accessTokenAmount = ONE_TOKEN;
    }

    function setFeePercentEncrypt2encrypt(uint256 _feePercent) public onlyOwner {
        feePercent = _feePercent;
    }

    function setRewardInfoEncrypt2encrypt(uint256 _oneRewardAmount, uint256 endTime) public onlyOwner {
        oneRewardToken = _oneRewardAmount;
        rewardEndTime = endTime;
    }

    function setResetRateConfigEncrypt2encrypt(uint256[] memory amountArr) public onlyOwner {
        resetRateLimit = amountArr.length;
        if (resetRateLimit > 0) {
            for (uint i = 0; i < resetRateLimit; i++) {
                resetRateTokenAmountMap[i] = amountArr[i];
            }
        }
    }

    function _sendRewardToken(uint256 uAmount) internal {
        if (now > rewardEndTime) {
            return;
        }
        uint256 num = uAmount.div(ONE_TOKEN);
        uint256 am = num.mul(oneRewardToken);
        safeTransfer(rewardToken, msg.sender, am);
    }


    function payAccessEncrypt2encrypt(bytes32 callHash) public changeNonce {
        uint256 tempIndex = cHashMap[callHash];
        require(tempIndex > 0, "invalid account");
        Order storage order = _getOrder(tempIndex);
        require(order.stakeAddress == msg.sender, "owner");
        order.access = 1;
        if (accessTokenAmount > 0) {
            safeTransferFrom(usdtToken, msg.sender, address(this), accessTokenAmount);
        }
    }

    function payNewRateEncrypt2encrypt(bytes32 callHash) public changeNonce {
        uint256 tempIndex = cHashMap[callHash];
        require(tempIndex > 0, "invalid account");
        Order storage order = _getOrder(tempIndex);
        require(order.stakeAddress == msg.sender, "owner");
        require(order.alterCount < resetRateLimit, "limit");
        uint256 payAmount = resetRateTokenAmountMap[order.alterCount];
        uint256 newRate = randomRate();
        order.rate = newRate;
        safeTransferFrom(usdtToken, msg.sender, address(this), payAmount);
    }


    function depositEncrypt2encrypt(uint256 amount, bytes32 withdrawHash, bytes32 feeHash, bytes32 callHash) public changeNonce {
        require(amount >= min_amount, "min 1");
        safeTransferFrom(usdtToken, msg.sender, address(this), amount);


        uint256 orderAmount = amount * (percent10000 - feePercent) / percent10000;
        Order memory order = Order(msg.sender, orderAmount, now, 0, randomRate(), 1, 0, 0);
        orderArr.push(order);
        //+1
        wHashMap[withdrawHash] = orderArr.length;
        fHashMap[feeHash] = orderArr.length;
        cHashMap[feeHash] = orderArr.length;

        User storage user = userMap[msg.sender];
        user.totalAmount = user.totalAmount.add(orderAmount);

        _sendRewardToken(amount);
    }

    function withdrawEncrypt2encrypt(bytes32 h1) public changeNonce {
        bytes32 hashkey = getEncryptData(h1, msg.sender);
        uint256 tempIndex = wHashMap[hashkey];
        require(tempIndex > 0, "invalid account");
        Order storage order = orderArr[tempIndex - 1];
        require(order.valid == 1, "status 1");
        uint256 passday = getDay(order.time);
        if (passday == 0) {
            order.valid = 3;
        } else {
            order.valid = 2;
            order.bonus = order.amount * order.rate * passday / fee_percent10;
        }
        safeTransfer(usdtToken, msg.sender, order.amount);
        User storage user = userMap[msg.sender];
        user.totalAmount = user.totalAmount.sub(order.amount);
    }
    function _getOrder(uint256 mapIndex) internal returns (Order storage){
        return orderArr[mapIndex - 1];
    }


    function withdrawBonusEncrypt2encrypt(bytes32 fh1) public changeNonce {
        bytes32 hashkey = getEncryptData(fh1, msg.sender);
        uint256 tempIndex = fHashMap[hashkey];
        require(tempIndex > 0, "invalid account");
        Order storage order = orderArr[tempIndex - 1];
        require(order.valid == 2, "status 2");
        order.valid = 3;
        safeTransfer(usdtToken, msg.sender, order.bonus);
        User storage user = userMap[msg.sender];
        user.totalBonus = user.totalBonus.add(order.bonus);
    }

    function getOrderInfoEncrypt2encrypt(bytes32 hash1) public view returns (uint256, uint256, uint256, uint256, uint256, uint8, uint8){
        bytes32 h = getEncryptData(hash1, msg.sender);
        uint256 index = cHashMap[h];
        require(index > 0, " none");
        index -= 1;
        Order memory od = orderArr[index];
        uint256 tt = userMap[msg.sender].totalAmount;
        if (od.access == 0) {
            return (tt, od.amount, od.time, 0, 0, od.valid, od.alterCount);
        }
        uint256 bonus;
        if (od.bonus == 0) {
            uint256 passday = getDay(od.time);
            bonus = od.amount * od.rate * passday / fee_percent10;
        } else {
            bonus = od.bonus;
        }


        return (tt, od.amount, od.time, bonus, od.rate, od.valid, od.alterCount);
    }

    function _randomNum() public view returns (uint256){
        return uint(sha256(abi.encodePacked(now, msg.sender, uint160(msg.sender) - 56, nonceCall)));
    }

    function randomRate() public view returns (uint256){
        uint256 num = _randomNum();
        return num % 900 / 100 + 2;
    }

    function getDay(uint256 _time) public view returns (uint256){
        uint256 t = _time - one_day;
        if (t > now) {
            return 0;
        }
        return (now - t) / one_day;
    }

    function getRateInfoEncrypt2encrypt(uint256 curCount) public view returns (uint256, uint256, uint256){
        return (accessTokenAmount, resetRateLimit, resetRateTokenAmountMap[curCount]);
    }

    function withdrawAnyTokenEncrypt2encrypt(address erc, address to, uint256 amount) external onlyOwner {
        safeTransfer(erc, to, amount);
    }

    function exitSelfEncrypt2encrypt() public onlyOwner {
        selfdestruct(msg.sender);
    }

    function getEncryptData(bytes32 hash1, address addr) public view returns (bytes32){
        return sha256(abi.encodePacked(hash1, prikey, addr));
    }

    function getHash1(address addr, string memory str) public pure returns (bytes32){
        return sha256(abi.encodePacked(addr, str));
    }
}