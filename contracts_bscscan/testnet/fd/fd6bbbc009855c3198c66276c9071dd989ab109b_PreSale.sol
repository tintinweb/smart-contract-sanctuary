/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

// SPDX-License-Identifier: Unlicensed

//bsc testnet wbnb 0xae13d989dac2f0debff460ac112a837c89baa7cd
//bsc testnet router 0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3
//bsc testnet contract 0xFD6bBBC009855C3198c66276c9071Dd989aB109B

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

    address public immutable creator;
    address public immutable token;
    uint256 public immutable start;
    uint256 public immutable end;
    uint256 public totalDeposits;
    mapping(address=>uint256) public deposits;//eth deposits
    uint256 public totalClaimed;//tokens claimed
    uint256 private ethClaimed;//eth claimed
    mapping(address=>uint256) public claims;//tokens claimed
    uint256 public immutable softCap;
    uint256 public immutable maxBuy;
    uint8 public result;// 0=unfinished, 1=failed, 2=success

    mapping(address=>bool) private unprocessed;//unprocessed buyers
    address [] private buyers;
    uint256 public nextToProcess;

    constructor(address _token, uint16 _maxBuy, uint16 _softCap, uint256 _start, uint256 _end){
        require(_start < _end && _end > block.timestamp);
        creator = msg.sender;
        token = _token;
        start = _start;
        end = _end;
        softCap = _softCap*10**18;
        maxBuy = _maxBuy*10**17;// .1 Eth increments
    }

    function bid() external payable{
        require(block.timestamp >= start && block.timestamp <= end);
        require(msg.value > 0);
        totalDeposits = totalDeposits.add(msg.value);
        deposits[msg.sender] = deposits[msg.sender].add(msg.value);
        require(deposits[msg.sender] <= maxBuy,"exceeded max buy");
        if(unprocessed[msg.sender]==false){
            unprocessed[msg.sender]=true;
            buyers.push(msg.sender);
        }
    }
    function finalize() public{
        require(result==0,"already finalized");
        require(end < block.timestamp,"unfinished");
        if(totalDeposits < softCap){
            result = 1;//fail
            IERC20(token).transfer(creator,IERC20(token).balanceOf(address(this)));
        }
        else{
            result = 2;
        }
    }
    function tokensToClaim(address addy) public view returns(uint256) {
        if(result==1 || unprocessed[addy]==false){
            return 0;
        }
        return IERC20(token).balanceOf(address(this)).mul(deposits[addy]).div(totalDeposits.sub(ethClaimed));
    }
    function distribute() external{
        if(result==0){
            finalize();
        }
        require(gasleft() > 50000, "insufficient gas");
        require(nextToProcess < buyers.length);
        uint gasNeeded = 30000;
        while(gasleft() > gasNeeded){
            uint startingGas = gasleft();
            if(nextToProcess==buyers.length){
                break;
            }
            uint256 amount = tokensToClaim(buyers[nextToProcess]);
            if(amount>0){
                ethClaimed = ethClaimed.add(deposits[buyers[nextToProcess]]);
                IERC20(token).transfer(buyers[nextToProcess],amount);
                payable(creator).transfer(deposits[buyers[nextToProcess]]);
            }
            else{
                payable(buyers[nextToProcess]).transfer(deposits[buyers[nextToProcess]]);
            }
            unprocessed[buyers[nextToProcess]] = false;
            nextToProcess = nextToProcess++;

            gasNeeded = startingGas - gasleft();
        }
    }
}