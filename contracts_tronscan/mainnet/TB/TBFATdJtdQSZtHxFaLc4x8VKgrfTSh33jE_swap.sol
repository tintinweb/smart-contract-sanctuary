//SourceUnit: swap.sol

pragma solidity ^0.5.10;

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
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}


contract swap {

    address usdtAddr = 0xa614f803B6FD780986A42c78Ec9c7f77e6DeD13C;
    uint256 public one_usdt = 1e6;
    address outTokenAddr = 0x367541B5804390836Aa4930df70bD8cfD68Ec8e7;
    uint256 public one_token = 1e6;
    uint256 public usdtRate = 0.39e6;
    uint256 public buyMinAmount = 200e6;
    uint256 public buyMaxAmount = 1000e6;

    function safeTransfer(address token, address to, uint value) internal {
        //  bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        if (token == usdtAddr) {
            require(success, "transfer failed");
            return;
        }
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    using SafeMath for uint256;


    uint256 one_day = 60 * 60 * 24;
    uint256 dayCount = 150;
    uint256 day150 = one_day * dayCount;

    uint256 public startTime = 1630425600;
    uint256 public endTime = 1945958400;

    string EMPTY_BYTES = "";
    bytes32 emptyHash  =keccak256(abi.encodePacked(EMPTY_BYTES));


    address emptyAddr = 0x0000000000000000000000000000000000000000;

    struct Order {
        address addr;
        uint256 inAmount;
        uint256 outAmount;
        uint256 time;
        uint256 lastTime;
        uint256 receivedAmount;
    }

    mapping(address => Order[]) userOrderArrMap;
    mapping(string => address) codeMap;
    mapping(address => string) addrMap;
    mapping(address => string) referrerMap;

    mapping(address => address[]) teamMap;
    address owner = 0x804DB47c0E89C6Bd08770421680Bd3693EFb3A84;

    event Bind(address indexed from,string fromCode,string refCode);
    event BuyEvent(address indexed buyer, address indexed referrer, uint256 inAmount, uint256 outAmount, uint256 time, string code);
    event ReleaseAmount(address indexed sender, uint256 amount, uint256 orderId);
    constructor () public {
        //first
        address first = 0xD4a164c2800cd523335C59e9C368c2539316B404;
        string memory firstCode = "abc";
        codeMap[firstCode] = first;
        addrMap[first] = firstCode;
    }


    modifier onlyOwner() {
        require(tx.origin == owner, "Ownable: caller is not the owner");
        _;
    }
    modifier checkTime(){
        require(startTime != 0 && endTime != 0, "time0");
        require(now >= startTime && now <= endTime, "not started or ended");
        _;
    }

    function setTime(uint256 _start, uint256 _end) public onlyOwner {
        startTime = _start;
        endTime = _end;
    }

    function getTokenOut(uint256 uAmount) public view returns (uint256){
        //uamount/urate
        return uAmount.mul(1e18).mul(one_token).div(usdtRate).div(1e18);
    }

    function checkThisBalance(uint256 outAmount) internal {
        require(_getTokenBalance() >= outAmount, "swap: token not enough");
    }

    function _getTokenBalance() internal view returns (uint256){
        return IERC20(outTokenAddr).balanceOf(address(this));
    }

    function checkReferrer(string memory code, string memory referrerCode) internal returns (string memory, string memory, address){
        string memory uCode = code;
        string memory refCode;
        if (codeMap[code] != emptyAddr || !hashCompareEmpty(addrMap[msg.sender])) {
            uCode = addrMap[msg.sender];
            require(!hashCompareEmpty(uCode), "invalid code 111");
            refCode = referrerMap[msg.sender];
        } else {
            require(codeMap[referrerCode] != emptyAddr, "invalid code");
            require(!hashCompareInternal(code, referrerCode), "same code");
            refCode = referrerCode;
            codeMap[code] = msg.sender;
            addrMap[msg.sender] = code;
            referrerMap[msg.sender] = referrerCode;
            teamMap[codeMap[referrerCode]].push(msg.sender);
            emit Bind(msg.sender, code, referrerCode);
        }
        return (uCode, refCode, codeMap[refCode]);
    }

    function buy(uint256 uAmount, string memory code, string memory referrerCode) public checkTime {
        require(uAmount >= buyMinAmount && uAmount <= buyMaxAmount, "amount limit");
        uint256 outAmount = getTokenOut(uAmount);

        require(outAmount > 0, "out0");
        checkThisBalance(outAmount);
        (string memory uCode,string memory refCode,address ref) = checkReferrer(code, referrerCode);
        Order memory order = Order(msg.sender, uAmount, outAmount, now, now, 0);
        userOrderArrMap[msg.sender].push(order);

        safeTransferFrom(usdtAddr, msg.sender, owner, uAmount);
        safeTransfer(outTokenAddr, msg.sender, outAmount.div(2));

        emit BuyEvent(msg.sender, ref, uAmount, outAmount, now, uCode);
    }

    function withdraw(uint256 orderId) public {
        require(orderId < userOrderArrMap[msg.sender].length, "out range");
        Order storage order = userOrderArrMap[msg.sender][orderId];
        (uint amount,uint last) = getRecAmount(order.outAmount, order.time, order.lastTime);
        require(amount > 0, "out enough");
        order.lastTime = last;
        order.receivedAmount = order.receivedAmount.add(amount);
        safeTransfer(outTokenAddr, msg.sender, amount);
        emit ReleaseAmount(msg.sender, amount, orderId);
    }

    function getSysInfo() public view returns (uint256, uint256){
        return (IERC20(outTokenAddr).balanceOf(address(this)), usdtRate);
    }

    function getUser(address addr) public view returns (string memory, string memory, address, uint256, uint256){
        return (addrMap[addr], referrerMap[addr], codeMap[referrerMap[addr]], userOrderArrMap[addr].length, teamMap[addr].length);
    }

    function getTeam(address addr) public view returns (address[] memory){
        return teamMap[addr];
    }

    function getRecAmount(uint orderAmount, uint start, uint last) public view returns (uint256, uint256){
        require(start <= last, "s>l");
        if (now.sub(start) < one_day) {
            return (0, last);
        }
        uint end = start.add(day150);
        if (now < end) {
            end = now;
        }
        uint day = end.sub(last).div(one_day);
        uint amount = orderAmount.div(2).mul(day).div(dayCount);
        uint newTime = day.mul(one_day).add(last);
        return (amount, newTime);
    }

    function getOrder(address addr, uint256 startIndex, uint256 endIndex) public view returns (address[] memory addrList, uint256[] memory inAmountList, uint256[] memory outAmountList, uint256[]memory timeList, uint256[]memory lastTimeList, uint256[]memory releaseList, uint256[] memory recList){
        uint orderLen = userOrderArrMap[addr].length;
        require(endIndex < orderLen, "swap: out range");
        require(startIndex <= endIndex, "s <= e");
        uint256 len = endIndex.sub(startIndex).add(1);
        addrList = new address[](len);
        inAmountList = new uint256[](len);
        outAmountList = new uint256[](len);
        timeList = new uint256[](len);
        lastTimeList = new uint256[](len);
        releaseList = new uint256[](len);
        recList = new uint256[](len);
        uint index;
        for (; startIndex <= endIndex; startIndex++) {
            Order memory order = userOrderArrMap[addr][startIndex];
            addrList[index] = order.addr;
            inAmountList[index] = order.inAmount;
            outAmountList[index] = order.outAmount;
            timeList[index] = order.time;
            lastTimeList[index] = order.lastTime;
            releaseList[index] = order.receivedAmount;
            (uint256 am,) = getRecAmount(order.outAmount, order.time, order.lastTime);
            recList[index] = am;
            index++;
        }
    }

    function withdrawTokens(address erc, address to, uint256 amount) external onlyOwner {
        safeTransfer(erc, to, amount);
    }

    function hashCompareEmpty(string memory a) internal view returns (bool) {
        return keccak256(abi.encodePacked(a)) == emptyHash;
    }

    function hashCompareInternal(string memory a, string memory b) internal pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }
}