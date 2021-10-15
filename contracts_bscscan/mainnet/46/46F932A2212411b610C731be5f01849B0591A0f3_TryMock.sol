/**
 *Submitted for verification at BscScan.com on 2021-10-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.6;

interface IDEXFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IDEXRouter {
    function factory() external pure returns (IDEXFactory);
}

interface ITokenConverter {
    function convertViaWETH(
        address _tokenA,
        address _tokenB,
        uint256 _amount
    ) external view returns (uint256);
}

abstract contract Ownable {
    address public owner;

    event OwnershipTransferred(address owner);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "!OWNER");
        _;
    }

    function transferOwnership(address adr) external onlyOwner {
        owner = adr;
        emit OwnershipTransferred(adr);
    }
}

contract TryMock is Ownable {
    address public WBNB = 0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c;
    address public BUSD = 0xe9e7CEA3DedcA5984780Bafc599bD69ADd087D56;

    ITokenConverter public constant TOKEN_CONVERTER = ITokenConverter(0xe2bf8ef5E2b24441d5B2649A3Dc6D81afC1a9517);

    string public constant name = "TryMock";
    string public constant symbol = "TMCK";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 10_000_000_000 * 1e18;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    uint256 public buyLimitBUSD = 1e18;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public lastBuy;
    uint256 public launchedAt;

    address public pair;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Whitelisted(address indexed holder, bool value);

    constructor() {
        pair = IDEXRouter(0x10ED43C718714eb63d5aA57B78B54704E256024E).factory().createPair(WBNB, address(this));
        whitelisted[msg.sender] = true;
        emit Whitelisted(msg.sender, true);

        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        return approve(spender, allowance[msg.sender][spender] + addedValue);
    }

    function decreaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        return approve(spender, allowance[msg.sender][spender] - addedValue);
    }

    function transfer(address recipient, uint256 amount) external returns (bool) {
        return _transfer(msg.sender, recipient, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool) {
        allowance[sender][msg.sender] -= amount;
        return _transfer(sender, recipient, amount);
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal returns (bool) {
        if (launchedAt == 0) {
            require(whitelisted[sender] || whitelisted[recipient], "Token not launched yet");
        } else if (block.timestamp < (launchedAt + 5 minutes) && sender == pair) {
            require(block.timestamp > (lastBuy[recipient] + 20), "BUY delay not passed yet");
            require(TOKEN_CONVERTER.convertViaWETH(address(this), BUSD, amount) <= buyLimitBUSD, "BUY limit exceeded");
            lastBuy[recipient] = block.timestamp;
        }

        // Exchange balances
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function burn(uint256 amount) external onlyOwner returns (bool) {
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
        return true;
    }

    function _LAUNCH_() external onlyOwner {
        require(launchedAt == 0, "Already launched");
        launchedAt = block.timestamp;
    }

    function whitelist(address[] memory holders, bool value) external onlyOwner {
        for (uint256 i = 0; i < holders.length; i++) {
            whitelisted[holders[i]] = value;
            emit Whitelisted(holders[i], value);
        }
    }
}