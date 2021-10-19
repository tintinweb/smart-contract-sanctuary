pragma solidity >=0.6.8;
pragma experimental ABIEncoderV2;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


import "./lib/BepLib.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";


contract TokenDistribution is
    Initializable,
    OwnableUpgradeable,
    ReentrancyGuardUpgradeable,
    PausableUpgradeable
{
    using SafeMath for uint256;

    struct Round {
        uint256 round;
        uint256 totalDeposit;
        uint256 totalWithdraw;
    }

    struct Order {
        uint256 id;
        address account;
        uint256 depositValue;
        bool claimed;
    }

    /* ========== VARIABLES ========== */

    uint256 public constant MIN_ROUND = 1;
    uint256 public constant MAX_ROUND = 96;
    uint256 public constant ROUND_TIME = 8 hours;
    uint256 public constant MIN_BUY = 2 * 10**16; // 0.02 BNB
    uint256 public constant BASE_MAX_BUY_PER_WALLET = 10**17; // 0.1 BNB
    uint256 public constant AMOUNT_TOKEN_SALE_PER_ROUND = 214816 ether; // 214816 token

    mapping(uint256 => mapping(address => Order)) private depositTable;
    mapping(uint256 => Round) private rounds;
    mapping(uint256 => uint256) private lastOrderIds;
    mapping(uint256 => mapping(uint256 => address)) indexes;

    uint256 public saleStartTime;
    uint256 bonusRate;
    uint256 private firstRoundPrice;
    uint256 private lastRoundPrice;

    uint256 private lastAddLiquidity;
    uint256 private liquidityThreshold;

    IERC20 public token;
    IPancakeRouter02 public pancakeRouter;

    uint256 public roundTime;
    string private message;

    IPancakeRouter02 public pancakeRouter1;
    IPancakeRouter02 public pancakeRouter2;


    /* ========== MODIFIERS ========== */

    modifier onlyNonContract() {
        require(tx.origin == msg.sender);
        _;
    }

    /* ========== EVENTS ========== */

    event Deposit(uint256 round, uint256 amount, address account);
    event Withdraw(uint256 round, uint256 amount, address account);

    /* ========== INITIALIZER ========== */

    function initialize(address _pancakeRouter, address _token)
        public
        initializer
    {
        OwnableUpgradeable.__Ownable_init();
        ReentrancyGuardUpgradeable.__ReentrancyGuard_init();
        __Pausable_init();

       // saleStartTime = block.timestamp;
        firstRoundPrice = 7 * 10**12; // 0.000007 BNB
        lastRoundPrice = 575 * 10**12; // 0.000575 BNB
        lastAddLiquidity = block.timestamp;
        liquidityThreshold = 15 minutes;
        pancakeRouter = IPancakeRouter02(_pancakeRouter);
        pancakeRouter1 = pancakeRouter;
        pancakeRouter2 =pancakeRouter;

        token = IERC20(_token);
        bonusRate = 10;
        roundTime = 8 hours;
        message = "DEFAULT_MSG";
    }

    function setPancakeRouters(address _pancakeRouter1, address _pancakeRouter2)
        public
        onlyOwner
        {
            pancakeRouter1 = IPancakeRouter02(_pancakeRouter1);
            pancakeRouter2 = IPancakeRouter02(_pancakeRouter2);
            pancakeRouter = IPancakeRouter02(_pancakeRouter1);

        }

    function setToken(address _token)
        public
        onlyOwner
        {
           token = IERC20(_token);

        }

    /* ========== VIEWS ========== */

    function currentRound() public view returns (uint256) {
        require(block.timestamp > saleStartTime, "Not started");
        return
            (block.timestamp.sub(saleStartTime)).div(roundTime).mul(100).div(
                100
            );
    }

    function endRoundTime(uint256 round) public view returns (uint256) {
        return saleStartTime.add(round.mul(roundTime));
    }

    function withdrawTimeLeft(uint256 round) public view returns (uint256) {
        uint256 withdrawTime = saleStartTime.add(round.mul(roundTime));
        if (block.timestamp > withdrawTime) {
            return 0;
        }
        return withdrawTime - block.timestamp;
    }

    function canWithdraw(uint256 round, address account)
        public
        view
        returns (bool)
    {
        return
            withdrawTimeLeft(round) == 0 &&
            !depositTable[round][account].claimed &&
            depositTable[round][account].depositValue > 0;
    }

    function getAmountTokenSalePerRound(uint round) public pure returns (uint256){
        uint max = AMOUNT_TOKEN_SALE_PER_ROUND/100 * (100 + round*10);

        // Completed rounds are ignore
        if (round > 15 || round < 4){
            return AMOUNT_TOKEN_SALE_PER_ROUND;
        }

        return max;
    }

    function getTokenAmountLeftInRound(uint256 round)
        public
        view
        returns (uint256)
    {
        return getAmountTokenSalePerRound(round).sub(rounds[round].totalWithdraw);
    }

    function canDeposit(uint256 round) public view returns (bool) {
        // Max vol BNB and default round time are reached
        if (
            rounds[round].totalDeposit > maxVolumeInRound(round) &&
            block.timestamp > endRoundTime(round)
        ) {
            return false;
        }
        return true;
    }

    function getOrderByRound(
        uint256 round,
        uint256 cursor,
        uint256 size
    ) public view returns (Order[] memory) {
        uint256 length = size;
        if (lastOrderIds[round] == 0) {
            return new Order[](0);
        }
        if (length > lastOrderIds[round] - cursor) {
            length = lastOrderIds[round] - cursor + 1; // First element is empty
        }
        Order[] memory values = new Order[](length);
        for (uint256 i = 0; i < length; i++) {
            address addressByIndex = indexes[round][cursor + i];
            values[i] = depositTable[round][addressByIndex];
        }
        return values;
    }

    function getLastedOrderIdByRound(uint256 round)
        public
        view
        returns (uint256)
    {
        return lastOrderIds[round];
    }

    function getAddressIndexes(uint256 round, uint256 index)
        public
        view
        returns (address)
    {
        return indexes[round][index];
    }

    function getOrderDetail(uint256 round, address account)
        public
        view
        returns (Order memory)
    {
        return depositTable[round][account];
    }

    function getRound(uint256 round) public view returns (Round memory) {
        return rounds[round];
    }

    function getMaxDepositByRound(uint256 round) public pure returns (uint256) {
        return BASE_MAX_BUY_PER_WALLET * round;
    }

    function getRounds(uint256 size, uint256 cursor)
        public
        view
        returns (Round[] memory)
    {
        uint256 length = size;
        if (length > MAX_ROUND - cursor) {
            length = MAX_ROUND - cursor;
        }

        Round[] memory values = new Round[](length);
        for (uint256 i = 0; i < length; i++) {
            values[i] = rounds[i + cursor];
            values[i].round = i + cursor;
        }
        return values;
    }

    function getClaimAt(uint256 round) public view returns (uint256) {
        return saleStartTime.add(round.mul(roundTime));
    }

    function getBuyableBnb(uint256 round) public view returns (uint256) {
        // return rounds[round].totalDeposit.div(lastOrderIds[round]);
        return maxVolumeInRound(round).div(lastOrderIds[round]);

    }

    /* ========== MUTATIVES FUNCTIONS ========== */

    function deposit(
        uint256 round,
        bytes memory _signature,
        string memory _message,
        string memory _messageWS
    ) public payable onlyNonContract whenNotPaused {
        require(
            verify(msg.sender, address(this), _message, _messageWS, _signature),
            "Tx not signed"
        );
        require(round >= MIN_ROUND && round <= MAX_ROUND, "Sale is end");
        require(canDeposit(round), "Round is end");
        require(
            depositTable[round][msg.sender].depositValue == 0,
            "Only buy once"
        );
        require(msg.value >= MIN_BUY, "Deposit BNB greater than MIN_BUY");
        require(
            msg.value <= BASE_MAX_BUY_PER_WALLET * round,
            "Only deposit BNB smaller than BASE_MAX_BUY_PER_WALLET"
        );
        // Increase order id
        increaseLastOrderIdByRound(round);

        uint256 amount = msg.value;
        Order storage order = depositTable[round][msg.sender];
        order.id = lastOrderIds[round];
        order.depositValue = amount;
        order.account = msg.sender;

        // Set lasted index
        indexes[round][lastOrderIds[round]] = msg.sender;

        Round storage roundInfo = rounds[round];
        roundInfo.totalDeposit = roundInfo.totalDeposit.add(msg.value);

        emit Deposit(round, msg.value, msg.sender);
    }

    function withdraw(uint256 round)
        public
        onlyNonContract
        whenNotPaused
        nonReentrant
    {
        require(canWithdraw(round, msg.sender), "Cannot withdraw");

        Order storage order = depositTable[round][msg.sender];

        // set here to avoid Reentrant
        order.claimed = true;

        uint256 withdrawTokenAmount = 0;
        uint256 buyableBnb = getBuyableBnb(round);

        uint256 depositValue = depositTable[round][msg.sender].depositValue;

        // calculate depositValue in case depositValue > buyableBnb and totalDeposit > maxVolumeInRound
        if (rounds[round].totalDeposit > maxVolumeInRound(round)) {
            if (depositValue > buyableBnb){

                uint256 refundAmount = depositValue.sub(buyableBnb);
                refund( msg.sender, refundAmount);
                depositValue = buyableBnb;

            }
        }

        withdrawTokenAmount = calculateExactTokenAmount(
                round,
                depositValue
        );

        if (round > 1){
            require(
                getTokenAmountLeftInRound(round) >= withdrawTokenAmount,
                "Not enough token to widthdraw"
            );
        }


        addLiquidity(depositValue);


        Round storage roundInfo = rounds[round];
        roundInfo.totalWithdraw = roundInfo.totalWithdraw.add(
            withdrawTokenAmount
        );

        token.transfer(msg.sender, withdrawTokenAmount);

        emit Withdraw(round, withdrawTokenAmount, msg.sender);
    }

    function refund(address account, uint256 amount) private {

        if (amount > 0) {
            (bool sent, ) = (account).call{value: amount}("");
            require(sent, "Error: Cannot refund");
        }

    }

    function increaseLastOrderIdByRound(uint256 round) internal {
        lastOrderIds[round] = lastOrderIds[round].add(1);
    }

    function setSaleStartTime(uint256 startTime) public onlyOwner {
        require(startTime > block.timestamp);
        saleStartTime = startTime;
    }

    function setFirstRoundPrice(uint256 price) public onlyOwner {
        require(price > 0);
        firstRoundPrice = price;
    }

    function setLastRoundPrice(uint256 price) public onlyOwner {
        require(price > 0);
        lastRoundPrice = price;
    }

    function getLastRoundPrice() public view returns (uint256) {

        return lastRoundPrice;
    }

    function setBonusRate(uint256 _bonusRate) public onlyOwner {
        bonusRate = _bonusRate;
    }

    function setRoundTime(uint256 _time) public onlyOwner {
        roundTime = _time;
    }

    function setMessage(string memory _message) public onlyOwner {
        message = _message;
    }

    function emergencyWithdraw() public onlyOwner {
        (bool sent, ) = (address(msg.sender)).call{
            value: address(this).balance
        }("");
        require(sent, "Error: Cannot withdraw");
        token.transfer(owner(), token.balanceOf(address(this)));
    }

    /* ========== INTERNAL ========== */

    function initialPriceInRound(uint256 round) public view returns (uint256) {
        if (round == MIN_ROUND) {
            return firstRoundPrice;
        }
        return lastRoundPrice.sub(firstRoundPrice).div(MAX_ROUND.sub(MIN_ROUND)) + initialPriceInRound(round - 1);
    }

    function oldInitialPriceInRound(uint256 round) public view returns (uint256) {
        require(round < 4, "Only old round");
        if (round == MIN_ROUND) {
            return firstRoundPrice;
        }

        uint256 _oldRoundPrice = (575 * 10**12);
        return _oldRoundPrice.sub(firstRoundPrice).div(MAX_ROUND.sub(MIN_ROUND)) + oldInitialPriceInRound(round - 1);
    }

    function maxVolumeInRound(uint256 round) public view returns (uint256) {
        uint256 initialPrice = 0;
        if (round < 4) {
            initialPrice = oldInitialPriceInRound(round);
        } else {
            initialPrice = initialPriceInRound(round);
        }
        return
            getAmountTokenSalePerRound(round).mul(initialPrice).div(
                10**18
            );
    }

    function calculateExactTokenAmount(uint256 round, uint256 amountBnb)
        public
        view
        returns (uint256)
    {
        uint256 initialPrice = 0;
        if (round < 4) {
            initialPrice = oldInitialPriceInRound(round);
        } else {
            initialPrice = initialPriceInRound(round);
        }
        return amountBnb.div(initialPrice).mul(10**18); //todo: check why .mul(10**18)
    }

    function addLiquidity(uint256 bnbAmount) internal {


        // rotate pancakeswap router vs latte rounter
        if (pancakeRouter1 == pancakeRouter){
            pancakeRouter = pancakeRouter2;
        } else {
            pancakeRouter = pancakeRouter1;
        }

        if (token.allowance(address(this), address(pancakeRouter)) == 0) {
            token.approve(address(pancakeRouter), ~uint256(0));
        }

        uint swapAmout = (bnbAmount/100)*45;
        uint addliquidAmount = bnbAmount - swapAmout;

        // buy xBlade from market using bnbAmount/4;
        swapBNBForToken(
            address(token),
            address(this),
            swapAmout
        );

        // add liquid using 55/100 bnbAmount + xBlade
        addLiquidityForTokens(

            address(token),
            address(this),
            addliquidAmount
        );
        // }
    }

    function random(uint256 from, uint256 to) private view returns (uint256) {
        uint256 seed = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp +
                        block.difficulty +
                        ((
                            uint256(keccak256(abi.encodePacked(block.coinbase)))
                        ) / (block.timestamp)) +
                        block.gaslimit +
                        ((uint256(keccak256(abi.encodePacked(msg.sender)))) /
                            (block.timestamp)) +
                        block.number
                )
            )
        );
        return seed.mod(to - from) + from;
    }

    fallback() external payable {
        // React to receiving ether, to avoid bug
    }

    receive() external payable {
        // custom function code
    }

    /* ========== VERIFY SIGNATURE ========== */

    function getMessageHash(address _to, string memory _message)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encodePacked(_to, _message));
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

    function verify(
        address _signer,
        address _to,
        string memory _message,
        string memory _messageWithSecret,
        bytes memory signature
    ) private view returns (bool) {
        bytes32 messageHash = getMessageHash(
            _to,
            string(abi.encodePacked(_message, message))
        );
        bytes32 messageWSHash = getMessageHash(_to, _messageWithSecret);
        require(messageHash == messageWSHash, "Not signed with secret");
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(messageWSHash);

        return recoverSigner(ethSignedMessageHash, signature) == _signer;
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

        // implicitly return (r, s, v)


    }

            // Library
    function swapTokensForEth( uint256 tokenAmount)
            public
    {


        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = pancakeRouter.WETH();

        // make the swap
        pancakeRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of BNB
            path,
            address(this),
            block.timestamp
        );
    }

    function swapBNBForToken(
        // address routerAddress,
        address tokenAddress,
        address recipient,
        uint256 bnbAmount
    ) public {


        // Generate the pancake pair path of token => WETH
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        // path[1] = address(0xd66c6B4F0be8CE5b39D52E0Fd1344c389929B378);
        path[1] = tokenAddress;

        // Swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: bnbAmount
        }(0, path, address(recipient), block.timestamp + 360);
    }

    function swapETHForTokens(
        // address routerAddress,
        address recipient,
        uint256 ethAmount
    ) public {

        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(this);

        // make the swap
        pancakeRouter.swapExactETHForTokensSupportingFeeOnTransferTokens{
            value: ethAmount
        }(
            0, // accept any amount of BNB
            path,
            address(recipient),
            block.timestamp + 360
        );
    }

    function addLiquidityForTokens(

        address _tokenAddress,
        address _to,
        uint256 _bnbAmount
    ) public {
        // IPancakeRouter02 pancakeRouter = IPancakeRouter02(_routerAddress);
        // generate the pancake pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(_tokenAddress);

        uint256 size1 = pancakeRouter.getAmountsOut(_bnbAmount, path)[1];

        pancakeRouter.addLiquidityETH{value: _bnbAmount}(
            _tokenAddress,
            size1,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            _to,
            block.timestamp + 360
        );
    }

    function addLiquidity(
        // address routerAddress,
        address owner,
        uint256 tokenAmount,
        uint256 ethAmount
    ) public {


        // add the liquidity
        pancakeRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner,
            block.timestamp + 360
        );
    }

    function getReturnAmount(

        uint256 _amount,
        address _token
    ) public view returns (uint256) {
        // IPancakeRouter02 pancakeRouter = IPancakeRouter02(_routerAddress);
        address[] memory path = new address[](2);
        path[0] = pancakeRouter.WETH();
        path[1] = address(_token);

        return pancakeRouter.getAmountsOut(_amount, path)[1];
    }
}

/**
 *Submitted for verification at BscScan.com on 2021-03-22
 */

//SPDX-License-Identifier: Unlicensed

pragma solidity >=0.6.8;


interface IPancakeFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
}

interface IPancakePair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

interface IPancakeRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IPancakeRouter02 is IPancakeRouter01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuardUpgradeable is Initializable {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    function __ReentrancyGuard_init() internal initializer {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal initializer {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and make it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "./ContextUpgradeable.sol";
import "../proxy/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal initializer {
        __Context_init_unchained();
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal initializer {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;
import "../proxy/Initializable.sol";

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/Initializable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    uint256[49] private __gap;
}