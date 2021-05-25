/**
 *Submitted for verification at Etherscan.io on 2021-05-25
*/

pragma solidity =0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), owner);
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Ownable: Caller is not the owner");
        _;
    }

    function transferOwnership(address transferOwner) external onlyOwner {
        require(transferOwner != newOwner);
        newOwner = transferOwner;
    }

    function acceptOwnership() virtual public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

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

contract ERC20ToBEP20Wrapper is Ownable {
    struct WrapInfo {
        address from;
        uint amount;
    }

    struct UnwrapInfo {
        address from;
        uint amount;
        uint fee;
        uint bscNonce;
    }

    IERC20 public immutable NBU;
    uint public minWrapAmount;

    mapping(address => uint) public userWrapNonces;
    mapping(address => uint) public userUnwrapNonces;
    mapping(address => mapping(uint => uint)) public bscToEthUserUnwrapNonces;
    mapping(address => mapping(uint => WrapInfo)) public wraps;
    mapping(address => mapping(uint => UnwrapInfo)) public unwraps;

    event Wrap(address indexed from, address indexed to, uint indexed wrapNonce, uint amount);
    event Unwrap(address indexed from, address indexed to, uint indexed unwrapNonce, uint bscNonce, uint amount, uint fee);
    event UpdateMinWrapAmount(uint indexed amount);
    event Rescue(address indexed to, uint amount);
    event RescueToken(address token, address indexed to, uint amount);

    constructor(address nbu) {
        NBU = IERC20(nbu);
    }
    
    function wrap(address to, uint amount) external {
        require(to != address(0), "ERC20ToBEP20Wrapper: Can't be zero address");
        require(amount >= minWrapAmount, "ERC20ToBEP20Wrapper: Value too small");
        
        NBU.transferFrom(msg.sender, address(this), amount);
        uint userWrapNonce = ++userWrapNonces[msg.sender];
        wraps[to][userWrapNonce].from = msg.sender;
        wraps[to][userWrapNonce].amount = amount;
        emit Wrap(msg.sender, to, userWrapNonce, amount);
    }

    function unwrap(address from, address to, uint amount, uint fee, uint bscNonce) external onlyOwner {
        require(to != address(0), "ERC20ToBEP20Wrapper: Can't be zero address");
        require(bscToEthUserUnwrapNonces[to][bscNonce] == 0, "ERC20ToBEP20Wrapper: Can't be zero address");
        
        NBU.transfer(to, amount - fee);
        uint unwrapNonce = ++userUnwrapNonces[to];
        bscToEthUserUnwrapNonces[to][bscNonce] = unwrapNonce;
        unwraps[to][unwrapNonce].from = from;
        unwraps[to][unwrapNonce].amount = amount;
        unwraps[to][unwrapNonce].fee = fee;
        unwraps[to][unwrapNonce].bscNonce = bscNonce;
        emit Unwrap(from, to, unwrapNonce, bscNonce, amount, fee);
    }

    //Admin functions
    function rescue(address payable to, uint256 amount) external onlyOwner {
        require(to != address(0), "ERC20ToBEP20Wrapper: Can't be zero address");
        require(amount > 0, "ERC20ToBEP20Wrapper: Should be greater than 0");
        TransferHelper.safeTransferETH(to, amount);
        emit Rescue(to, amount);
    }

    function rescue(address to, address token, uint256 amount) external onlyOwner {
        require(to != address(0), "ERC20ToBEP20Wrapper: Can't be zero address");
        require(amount > 0, "ERC20ToBEP20Wrapper: Should be greater than 0");
        TransferHelper.safeTransfer(token, to, amount);
        emit RescueToken(token, to, amount);
    }

    function updateMinWrapAmount(uint amount) external onlyOwner {
        require(amount > 0, "ERC20ToBEP20Wrapper: Should be greater than 0");
        minWrapAmount = amount;
        emit UpdateMinWrapAmount(amount);
    }
}