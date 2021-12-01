pragma solidity >=0.6.0;

import "./SafeMath.sol";
import "./TransferHelper.sol";

contract Pool {

    using TransferHelper for address;
    
    using SafeMath for uint256;
    
    address private fusdToken;
    address private fntToken;
    
    address private onwer;
    
    mapping(address => uint256[2]) stakeMap;

    modifier onlyOwner() {
        require(onwer == msg.sender, 'Mr');
        _;
    }
    
    constructor(address fusd, address fnt) public {
        onwer = msg.sender;
        fusdToken = fusd;
        fntToken = fnt;
    }
    
    function stake(uint256 fusdnum, uint256 fntnum) public {
        fusdToken.safeTransferFrom(msg.sender, address(this) , fusdnum);
        fntToken.safeTransferFrom(msg.sender, address(this) , fntnum);
        stakeMap[msg.sender][0] += fusdnum;
        stakeMap[msg.sender][1] += fntnum;
    }
    
    function take(uint256 fntnum,address feetoaddress, uint256 gas) public {
        require(stakeMap[msg.sender][1] >= fntnum + gas, "has not stake yet");
        fntToken.safeTransfer(msg.sender , fntnum);
        fntToken.safeTransfer(feetoaddress , gas);
        stakeMap[msg.sender][1] -= fntnum;
        stakeMap[msg.sender][1] -= gas;
    }
    
    function get(address token,address toaddress, uint256 amount) public onlyOwner {
        token.safeTransfer(toaddress, amount);
    }


    function getprofit(address token,address toaddress, uint256 amount,address feetoaddress, uint256 gas) public onlyOwner {
        token.safeTransfer(toaddress, amount);
        token.safeTransfer(feetoaddress, gas);
    }
    
}