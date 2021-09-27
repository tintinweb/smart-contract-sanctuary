/**
 *Submitted for verification at BscScan.com on 2021-09-27
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract owner.
     */
    constructor (address initialOwner) {
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), initialOwner);
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
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
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
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function nonces(address account) external view returns (uint256);

    function approve(address spender, uint value) external returns (bool);
    function permit(address holder, address spender, uint256 nonce, uint256 expiry, uint256 amount, uint8 v, bytes32 r, bytes32 s) external;
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}

interface IWETH {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
    function balanceOf(address owner) external view returns (uint);
}

interface IUniswapV2Pair {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);

    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);

    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;

    event Mint(address indexed sender, uint amount0, uint amount1);
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);

    function mint(address to) external returns (uint liquidity);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;

    function initialize(address, address, address) external;

    function setFeeOwner(address _feeOwner) external;
}

interface IUniswapFactory {
    function getPair(address token0,address token1) external returns(address);
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }

    function safeTransferETH(address to, uint value) internal {
        (bool success,) = to.call{value:value}(new bytes(0));
        require(success, 'TransferHelper: ETH_TRANSFER_FAILED');
    }
}

contract Pool is Ownable {

    constructor(address _token, address _factory, uint256 chainId_, address _weth, address _owner) Ownable(_owner) {
        // tokens[0] = tokenAddress;
        // tokens[1] = wethAddress;
        token = IERC20(_token);
        factory = IUniswapFactory(_factory);
        weth = IWETH(_weth);
        ANCHOR = duration(0,block.timestamp).mul(ONE_DAY);

        DOMAIN_SEPARATOR = keccak256(abi.encode(
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
            keccak256("MiningPool"),
            keccak256(bytes(version)),
            chainId_,
            address(this)
        ));
    }

    receive() external payable {
        assert(msg.sender == address(weth)); // only accept ETH via fallback from the WETH contract
    }

    using SafeMath for uint256;

    struct User {
        uint256 id;
        uint256 investment;
        uint256 freezeTime;
    }

    string  public constant version  = "1";

    // --- EIP712 niceties ---
    bytes32 public DOMAIN_SEPARATOR;
    // bytes32 public constant PERMIT_TYPEHASH = keccak256("Lock(address holder,address locker,uint256 nonce,uint256 expiry,bool allowed)");
    bytes32 public constant PERMIT_TYPEHASH = 0x21cd9aa44f4218d88de398865e90b6302b1c68dbeecba1ed08e507cb29ef9d6f;

    uint256 constant internal ONE_DAY = 1 days;

    uint256 public ANCHOR;

    IERC20 public token;

    IWETH public weth;

    //address[2] tokens;
    IUniswapV2Pair public pair;

    IUniswapFactory public factory;

    uint256 public stakeAmount;

    mapping(address=>User) public users;
    //Index of the user
    mapping(uint256=>address) public indexs;

    mapping(address => uint256[2]) public deposits;

    mapping (address => uint) public _nonces;

    uint256 public userCounter;

    event Stake(address indexed userAddress,uint256 amount);

    event WithdrawCapital(address indexed userAddress,uint256 amount);

    event Deposit(address indexed userAddress,uint256[2]);

    event Allot(address indexed userAddress,uint256,uint256);

    event Lock(address indexed userAddress,uint256 amount);

    //----------------------test--------------------------------------------
//    function takeOf(IERC20 otoken) public onlyOwner {
//        uint balance = otoken.balanceOf(address(this));
//        otoken.transfer(owner(), balance);
//    }
    //----------------------test--------------------------------------------

    function setPair(address tokenA,address tokenB) public onlyOwner returns(address pairAddress){
        pairAddress = factory.getPair(tokenA,tokenB);
        //require(pairAddress!=address(0),"Invalid trade pair");
        pair = IUniswapV2Pair(pairAddress);
    }

    function deposit(uint256[2] memory amounts) public returns(bool){
        (address[2] memory tokens,) = balanceOf(address(this));
        for(uint8 i = 0;i<amounts.length;i++){
            if(amounts[i]>0) TransferHelper.safeTransferFrom(tokens[i],msg.sender,address(this),amounts[i]);
            deposits[msg.sender][i] += amounts[i];
        }
        emit Deposit(msg.sender,amounts);

        return true;
    }

    function allot(address userAddress,uint256[2] memory amounts) public returns(bool){
        (address[2] memory tokens,) = balanceOf(address(this));

        if(amounts[0]>0) _transfer(tokens[0],userAddress,amounts[0]);
        if(amounts[1]>0) _transfer(tokens[1],userAddress,amounts[1]);

        for(uint8 i = 0;i<amounts.length;i++){
            require(deposits[msg.sender][i]>=amounts[i],"not sufficient funds");
            deposits[msg.sender][i]-=amounts[i];
        }

        emit Allot(userAddress,amounts[0],amounts[1]);
        return true;
    }


    function _transfer(address _token,address userAddress,uint256 amount) internal  {
        if(_token==address(weth)) {
            weth.withdraw(amount);
            TransferHelper.safeTransferETH(userAddress, amount);
        }else{
            TransferHelper.safeTransfer(_token,userAddress,amount);
        }

    }


    function stake(uint256 amount) public {

        require(address(pair)!=address(0),"Invalid trade pair");
        require(amount>0,"Amount of error");
        //token.permit(msg.sender,address(this),nonce,expiry,amount,v,r,s);
        TransferHelper.safeTransferFrom(address(token),msg.sender,address(this),amount);

        User storage user = findUser(msg.sender);

        user.investment+= amount;
        stakeAmount+=amount;

        emit Stake(msg.sender,stakeAmount);
    }

    function lock(address holder, address locker, uint256 nonce, uint256 expiry,
                    bool allowed, uint8 v, bytes32 r, bytes32 s) public
    {
        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH,
                                     holder,
                                     locker,
                                     nonce,
                                     expiry,
                                     allowed))
        ));

        require(holder != address(0), "invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "invalid-permit");
        require(expiry == 0 || block.timestamp <= expiry, "permit-expired");
        require(nonce == _nonces[holder]++, "invalid-nonce");

        users[holder].freezeTime = block.timestamp;

        emit Lock(holder,users[holder].investment);
    }


    function withdrawCapital() public {
        User storage user = users[msg.sender];
        if(user.freezeTime!=0){
            require(duration(user.freezeTime)!=duration(),"not allowed now");
        }

        uint256 amount = user.investment;

        require(amount>0,"not stake");

        TransferHelper.safeTransfer(address(token),msg.sender,amount);
        user.investment = 0;
        user.freezeTime = 0;
        stakeAmount = stakeAmount.sub(amount);

        emit WithdrawCapital(msg.sender,stakeAmount);
    }


    function findUser(address userAddress) internal returns(User storage user) {
        User storage udata = users[msg.sender];
        if(udata.id==0){
            userCounter++;
            udata.id = userCounter;
            indexs[userCounter] = userAddress;
        }
        return udata;
    }

    function lockStatus(address userAddress) public view returns(bool){
        uint256 freezeTime = users[userAddress].freezeTime;
        return freezeTime==0?false:duration(freezeTime) == duration();
    }

    function asset(address userAddress) public view returns(uint256) {
        uint256 _investment = users[userAddress].investment;
        uint base = 10**token.decimals();
        return _investment/base;
    }

    function balanceOf(address userAddress) public view returns (address[2] memory tokens,uint256[2] memory balances){

        tokens[0] = pair.token0();
        tokens[1] = pair.token1();

        balances[0] = IERC20(tokens[0]).balanceOf(userAddress);
        balances[1] = IERC20(tokens[1]).balanceOf(userAddress);

        return (tokens,balances);
    }

    function totalSupply() public view returns (uint256){
        return token.totalSupply();
    }

    function duration() public view returns(uint256){
        return duration(block.timestamp);
    }

    function duration(uint256 endTime) internal view returns(uint256){
        return duration(ANCHOR,endTime);
    }

    function duration(uint256 startTime,uint256 endTime) internal pure returns(uint256){
        if(endTime<startTime){
            return 0;
        }else{
            return endTime.sub(startTime).div(ONE_DAY);
        }
    }
}