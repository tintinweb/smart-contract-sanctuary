//SourceUnit: ITRC20.sol

pragma solidity ^0.5.8;

/**
 * @title TRC20 interface
 */
interface ITRC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SourceUnit: ITokenDeposit.sol

pragma solidity ^0.5.8;

import "./ITRC20.sol";

contract ITokenDeposit is ITRC20 {
    function deposit() public payable;
    function withdraw(uint256) public;
    event  Deposit(address indexed dst, uint256 sad);
    event  Withdrawal(address indexed src, uint256 sad);
}


//SourceUnit: WTHERO.sol

pragma solidity ^0.5.8;
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

}
interface ITRC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}
contract WTHERO {
    using SafeMath for uint256;
    string public name = "Wrapped THERO";
    string public symbol = "WTHERO";
    uint8  public decimals = 6;
    address tokenAddress = 0x2eD341Bbd45120eEA9be429AdE86188715a00Bc1;

    uint256 private totalSupply_;
    mapping(address => uint256) private  balanceOf_;
    mapping(address => mapping(address => uint)) private  allowance_;

    event Deposit(address indexed dst, uint256 sad);
    event Withdrawal(address indexed src, uint256 sad);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    function deposit(uint256 amount) public payable {
        require(ITRC20(tokenAddress).transferFrom(msg.sender,address(this),amount),"Error: Approve First");
        uint256 receive = _getTF(amount).div(1E12);
        balanceOf_[msg.sender] += receive;
        totalSupply_ += receive;
        emit Transfer(address(0x00), msg.sender, receive);
        emit Deposit(msg.sender, receive);
    }

    function withdraw(uint256 sad) public {
        require(balanceOf_[msg.sender] >= sad, "Error: Not enough WTHERO balance");
        require(totalSupply_ >= sad, "Error: Not enough WTHERO totalSupply");
        balanceOf_[msg.sender] -= sad;
        totalSupply_ -= sad;
        require(ITRC20(tokenAddress).transfer(msg.sender,sad.mul(1E12)),"Withdraw Error");

        emit Transfer(msg.sender, address(0x00), sad);
        emit Withdrawal(msg.sender, sad);
    }
    
    function _getTF(uint256 amount) internal pure returns(uint256){
        uint256 fees = amount.mul(8).div(100000);
        uint256 receive = amount.sub(fees);
        return receive;
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address guy) public view returns (uint256){
        return balanceOf_[guy];
    }

    function allowance(address src, address guy) public view returns (uint256){
        return allowance_[src][guy];
    }

    function approve(address guy, uint256 sad) public returns (bool) {
        allowance_[msg.sender][guy] = sad;
        emit Approval(msg.sender, guy, sad);
        return true;
    }

    function approve(address guy) public returns (bool) {
        return approve(guy, uint256(- 1));
    }

    function transfer(address dst, uint256 sad) public returns (bool) {
        return transferFrom(msg.sender, dst, sad);
    }

    function transferFrom(address src, address dst, uint256 sad)
    public returns (bool)
    {
        require(balanceOf_[src] >= sad, "src balance not enough");

        if (src != msg.sender && allowance_[src][msg.sender] != uint256(- 1)) {
            require(allowance_[src][msg.sender] >= sad, "src allowance is not enough");
            allowance_[src][msg.sender] -= sad;
        }
        balanceOf_[src] -= sad;
        balanceOf_[dst] += sad;

        emit Transfer(src, dst, sad);
        return true;
    }
}