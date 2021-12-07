/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

// SPDX-License-Identifier: Unlicensed

//bsc testnet wbnb 0xae13d989dac2f0debff460ac112a837c89baa7cd

pragma solidity >=0.8.2;

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
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function permit(address target, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
    function transferWithPermit(address target, address to, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
contract PreSale{

    using SafeMath for uint256;

    address public immutable token;
    address public immutable creator;
    uint256 public immutable end;
    uint256 public immutable softCap;
    uint256 public totalDeposits;
    mapping(address=>uint256) public deposits;//eth deposits
    uint256 private remainingDeposits;//unclaimed eth amount claimed
    uint8 public result;// 0=unfinished, 1=failed, 2=success
    mapping(address=>bool) public claimed;//users that have claimed their tokens already

    constructor(address _token, uint16 _softCap, uint256 _end){
        require(_end > block.timestamp,"end < block.timestamp");
        creator = msg.sender;
        token = _token;
        end = _end;
        softCap = _softCap*10**18;//MAKE 0 for testing 1 eth increments
    }

    function bid() external payable{
        require(block.timestamp <= end,"ended");
        require(msg.value > 0,"insufficient bid");
        totalDeposits = totalDeposits.add(msg.value);
        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
        remainingDeposits = totalDeposits;
    }
    function tokensToClaim(address addy) public view returns(uint256) {
        if(result==1 || remainingDeposits==0){
            return 0;
        }
        return IERC20(token).balanceOf(address(this)).mul(deposits[addy]).div(remainingDeposits);
    }
    function tokensToDistribute() external view returns (uint256){
      return IERC20(token).balanceOf(address(this));
    }
    function claim() external {
        if(result==0){
            if(totalDeposits <= softCap){
                result = 1;//fail
                IERC20(token).transfer(creator,IERC20(token).balanceOf(address(this)));
            }
            else{
                result = 2;
            }
            remainingDeposits = totalDeposits;
        }
        uint256 amount = tokensToClaim(msg.sender);
        uint256 deposit = deposits[msg.sender];
        if(amount > 0){
            IERC20(token).transfer(msg.sender,amount);
            payable(creator).transfer(deposit);
        }
        else{
            payable(msg.sender).transfer(deposit);
        }
        remainingDeposits -= deposit;
        claimed[msg.sender] = true;
    }
}