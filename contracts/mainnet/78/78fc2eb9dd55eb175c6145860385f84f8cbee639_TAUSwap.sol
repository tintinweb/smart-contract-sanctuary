pragma solidity 0.6.12;

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

contract Ownable {
    address public _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () public {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract LamdenTau  {
    function transferFrom(address _from, address _to, uint256 _value) external virtual returns (bool);
    function transfer(address recipient, uint256 amount) external virtual returns (bool);
    function balanceOf(address account) external virtual view returns (uint256);

}

contract TAUSwap is Ownable {
    using SafeMath for uint256;

    LamdenTau tau = LamdenTau(0xc27A2F05fa577a83BA0fDb4c38443c0718356501);
    mapping(address => uint256) swappedBalances;

    event Swap(address sender, string receiver, uint256 value);

    function swap(string memory mainnetAddress, uint256 amount) public {
        tau.transferFrom(msg.sender, address(this), amount);

        swappedBalances[msg.sender] = swappedBalances[msg.sender].add(amount);

        emit Swap(msg.sender, mainnetAddress, amount);
    }

    function sweep(address owner, uint256 amount) public onlyOwner {
        if (amount == 0) {
            amount = swappedBalances[owner];
        }

        swappedBalances[owner] = swappedBalances[owner].sub(amount);
        tau.transfer(address(0x0), amount);
    }

    function tauRevert(address owner, uint256 amount) public onlyOwner {
        swappedBalances[owner] = swappedBalances[owner].sub(amount);
        tau.transfer(owner, amount);
    }
}