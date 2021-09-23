//SourceUnit: Recycle.sol

pragma solidity 0.5.17;

contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


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

contract Recycle is Ownable {
    using SafeMath for uint256;
    IERC20 public target;
    IERC20 public newToken;
    bool private close;
    constructor(IERC20 _target, IERC20 _newToken) public {
        target = _target;
        newToken = _newToken;
    }

    function exchange() public returns (uint256){
        require(!close,"run error");
        uint256 amount = target.balanceOf(msg.sender);
        target.transferFrom(msg.sender, address(this), amount);
        amount = amount.mul(40);
        newToken.transfer(msg.sender, amount);
        return amount;
    }

    function updateClose(bool flag) public onlyOwner returns(bool){
        close = flag;
        return close;
    }

    function getClose() public view returns(bool){
        return close;
    }

    function recycle() public onlyOwner returns (bool){
        uint256 amount = target.balanceOf(address(this));
        if (amount > 0) {
            target.transfer(msg.sender, amount);
        }

        amount = newToken.balanceOf(address(this));
        if (amount > 0) {
            newToken.transfer(msg.sender, amount);
        }
        return true;
    }
}