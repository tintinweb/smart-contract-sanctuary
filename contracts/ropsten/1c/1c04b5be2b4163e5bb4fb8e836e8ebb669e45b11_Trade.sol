pragma solidity 0.4.25;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address to, uint256 value) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function transferTrade(address from, address to, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library SafeMath {
    int256 constant private INT256_MIN = - 2 ** 255;

    /**
    * @dev Multiplies two unsigned integers, reverts on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Multiplies two signed integers, reverts on overflow.
    */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        require(!(a == - 1 && b == INT256_MIN));
        // This is the only case of overflow not detected by the check below

        int256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
    * @dev Integer division of two unsigned integers truncating the quotient, reverts on division by zero.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold

        return c;
    }

    /**
    * @dev Integer division of two signed integers truncating the quotient, reverts on division by zero.
    */
    function div(int256 a, int256 b) internal pure returns (int256) {
        require(b != 0);
        // Solidity only automatically asserts when dividing by 0
        require(!(b == - 1 && a == INT256_MIN));
        // This is the only case of overflow

        int256 c = a / b;

        return c;
    }

    /**
    * @dev Subtracts two unsigned integers, reverts on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
    * @dev Subtracts two signed integers, reverts on overflow.
    */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));

        return c;
    }

    /**
    * @dev Adds two unsigned integers, reverts on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
    * @dev Adds two signed integers, reverts on overflow.
    */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));

        return c;
    }

    /**
    * @dev Divides two unsigned integers and returns the remainder (unsigned integer modulo),
    * reverts when dividing by zero.
    */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    uint public ownersCount = 1;
    mapping(address => bool) public owner;
    mapping(uint => address) public ownerList;

    constructor () internal {
        owner[msg.sender] = true;
        ownerList[ownersCount] = msg.sender;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender));
        _;
    }

    function isOwner(address user) public view returns (bool) {
        return owner[user];
    }

    function addOwner(address _owner) public onlyOwner {
        require(!owner[_owner], "It&#39;s owner now");
        owner[_owner] = true;
        ownersCount++;
        ownerList[ownersCount] = _owner;
    }

    function removeOwner(address _owner) public onlyOwner {
        require(owner[_owner], "It&#39;s not owner now");
        require(ownersCount > 1);
        owner[_owner] = false;

        for (uint i = 1; i < ownersCount + 1; i++) {
            if (ownerList[i] == _owner) {
                delete ownerList[i];
                break;
            }
        }

        ownersCount--;
    }
}

contract Trade is Ownable {
    using SafeMath for uint;
    uint public cursETHtoUSD = 150;
    uint public costETH = 1 ether / 10000;
    uint public costUSD = costETH * cursETHtoUSD;
    uint private DEC = 10 ** 2;
    bool private buyOpen = true;
    bool private sellOpen = true;
    uint public buyTimeWorkFrom = 1545264000;
    uint public buyTimeWork = 24 hours;
    uint public sellTimeWorkFrom = 1545264000;
    uint public sellTimeWork = 24 hours;
    address public tokenAddress;

    event Buy(address user, uint valueETH, uint amount);
    event Sell(address user, uint valueETH, uint amount);
    event Deposit(address user, uint value);
    event DepositToken(address user, uint value);
    event Withdraw(address user, uint value);
    event WithdrawTokens(address user, uint value);

    modifier buyIsOpen() {
        require(buyOpen == true, "Buying are closed");
        require((now - buyTimeWorkFrom) % 24 hours <= buyTimeWork, "Now buying are closed");
        _;
    }

    modifier sellIsOpen() {
        require(sellOpen == true, "Selling are closed");
        require((now - sellTimeWorkFrom) % 24 hours <= sellTimeWork, "Now selling are closed");
        _;
    }

    function updateCursETHtoUSD(uint _value) onlyOwner public {
        cursETHtoUSD = _value;
        costUSD = costETH.mul(cursETHtoUSD);
    }

    function updateCostETH(uint _value) onlyOwner public {
        costETH = _value;
        costUSD = costETH.mul(cursETHtoUSD);
    }

    function updateCostUSD(uint _value) onlyOwner public {
        costUSD = _value;
        costETH = costUSD.div(cursETHtoUSD);
    }

    function closeBuy() onlyOwner public {
        buyOpen = false;
    }

    function openBuy() onlyOwner public {
        buyOpen = true;
    }

    function closeSell() onlyOwner public {
        sellOpen = false;
    }

    function openSell() onlyOwner public {
        sellOpen = true;
    }

    function setBuyingTime(uint _from, uint _time) onlyOwner public {
        buyTimeWorkFrom = _from;
        buyTimeWork = _time;
    }

    function setSellingTime(uint _from, uint _time) onlyOwner public {
        sellTimeWorkFrom = _from;
        sellTimeWork = _time;
    }

    function buyTokens() buyIsOpen payable public {
        require(msg.value > 0, "ETH amount must be greater than 0");

        uint amount = msg.value.div(costETH).mul(DEC);

        require(IERC20(tokenAddress).balanceOf(this) >= amount, "Not enough tokens");

        IERC20(tokenAddress).transfer(msg.sender, amount);

        emit Buy(msg.sender, msg.value, amount);
    }

    function() external payable {
        if (isOwner(msg.sender)) {
            depositEther();
        } else {
            buyTokens();
        }
    }

    function sellTokens(uint amount) sellIsOpen public {
        require(amount > 0, "Tokens amount must be greater than 0");
        require(IERC20(tokenAddress).balanceOf(msg.sender) >= amount, "Not enough tokens on balance");

        uint valueETH = amount.div(DEC).mul(costETH);
        require(valueETH <= address(this).balance, "Not enough balance on the contract");

        IERC20(tokenAddress).transferTrade(msg.sender, this, amount);
        msg.sender.transfer(valueETH);

        emit Sell(msg.sender, valueETH, amount);
    }

    function sellTokensFrom(address from, uint amount) sellIsOpen public {
        require(keccak256(msg.sender) == keccak256(tokenAddress), "Only for token");
        require(amount > 0, "Tokens amount must be greater than 0");
        require(IERC20(tokenAddress).balanceOf(from) >= amount, "Not enough tokens on balance");

        uint valueETH = amount.div(DEC).mul(costETH);
        require(valueETH <= address(this).balance, "Not enough balance on the contract");

        IERC20(tokenAddress).transferTrade(from, this, amount);
        from.transfer(valueETH);

        emit Sell(from, valueETH, amount);
    }

    function withdraw(address to, uint256 value) onlyOwner public {
        require(address(this).balance >= value, "Not enough balance on the contract");
        to.transfer(value);

        emit Withdraw(to, value);
    }

    function withdrawTokens(address to, uint256 value) onlyOwner public {
        require(IERC20(tokenAddress).balanceOf(this) >= value, "Not enough token balance on the contract");

        IERC20(tokenAddress).transferTrade(this, to, value);

        emit WithdrawTokens(to, value);
    }

    function depositEther() onlyOwner payable public {
        emit Deposit(msg.sender, msg.value);
    }

    function depositToken(uint _value) onlyOwner public {
        IERC20(tokenAddress).transferTrade(msg.sender, this, _value);
    }

    function changeTokenAddress(address newTokenAddress) onlyOwner public {
        tokenAddress = newTokenAddress;
    }
}