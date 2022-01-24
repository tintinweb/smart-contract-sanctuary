//SourceUnit: CTTSwap.sol

pragma solidity >=0.5.4 <0.8.0;
import "./IERC20.sol";

contract CTTSwap {
    address private owner;
    IERC20 private usdt = IERC20(0x41a614f803b6fd780986a42c78ec9c7f77e6ded13c);
    IERC20 private ctt = IERC20(0x4175097f5a2773f77d03bdd0fad55eff48a56001a2);
    
    event SwapedToUSDT(address indexed user, uint256 indexed amount);
    event SwapedToCTT(address indexed user, uint256 indexed amount);

    constructor () public {
        owner = msg.sender;
    }
    
    function swapCTT2USDT(uint256 amount) public returns (bool) {
        uint256 checkAmount = ctt.allowance(msg.sender, address(this));
        require(checkAmount >= amount, "Allowance not enough");
        checkAmount = ctt.balanceOf(msg.sender);
        require(checkAmount >= amount, "User CTT balance not enough");

        ctt.transferFrom(msg.sender, address(this), amount);
        ctt.transfer(owner, amount);
        
        // Calculate
        uint256 cttBalance = ctt.balanceOf(owner);
        uint256 usdtAmount = 0;
        if(cttBalance <= 20000000000000) {
            usdtAmount = amount * 8/100;
        } else if(cttBalance > 20000000000000 && cttBalance < 40000000000000) {
            usdtAmount = amount * 5/100;
        } else if(cttBalance > 40000001000000 && cttBalance < 60000000000000) {
            usdtAmount = amount * 3/100;
        } else if(cttBalance > 60000001000000) {
            usdtAmount = amount * 1/100;
        }

        checkAmount = usdt.allowance(owner, address(this));
        require(checkAmount >= usdtAmount, "System allowance not enough");

        usdt.transferFrom(owner, address(this), usdtAmount);
        usdt.transfer(msg.sender, usdtAmount);

        emit SwapedToUSDT(msg.sender, usdtAmount);
        return true;
    }

    function swapUSDT2CTT(uint256 amount) public returns (bool) {
        uint256 checkAmount = usdt.allowance(msg.sender, address(this));
        require(checkAmount >= amount, "Allowance not enough");
        checkAmount = usdt.balanceOf(msg.sender);
        require(checkAmount >= amount, "User USDT balance not enough");

        usdt.transferFrom(msg.sender, address(this), amount);
        usdt.transfer(owner, amount);
        
        // Calculate
        uint256 cttBalance = ctt.balanceOf(owner);
        uint256 cttAmount = 0;
        if(cttBalance <= 20000000000000) {
            cttAmount = amount * 25/2;
        } else if(cttBalance > 20000000000000 && cttBalance < 40000000000000) {
            cttAmount = amount * (1/(5/100));
        } else if(cttBalance > 40000001000000 && cttBalance < 60000000000000) {
            cttAmount = amount * 100/3;
        } else if(cttBalance > 60000001000000) {
            cttAmount = amount * (1/(1/100));
        }

        checkAmount = ctt.allowance(owner, address(this));
        require(checkAmount >= cttAmount, "System allowance not enough");

        ctt.transferFrom(owner, address(this), cttAmount);
        ctt.transfer(msg.sender, cttAmount);
        
        emit SwapedToCTT(msg.sender, cttAmount);
        return true;
    }
    
    function removeUnusedToken(address tokenAddress) public {
        require(msg.sender == owner, "Caller is not owner");
        IERC20 token = IERC20(tokenAddress);
        uint256 amount = token.balanceOf(address(this));
        token.transfer(msg.sender, amount);
    }
}

//SourceUnit: IERC20.sol

pragma solidity >=0.5.4 <0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}