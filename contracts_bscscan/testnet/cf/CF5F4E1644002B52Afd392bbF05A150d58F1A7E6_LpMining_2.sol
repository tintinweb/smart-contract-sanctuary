/**
 *Submitted for verification at BscScan.com on 2021-11-26
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-25
*/

/**
 *Submitted for verification at BscScan.com on 2021-11-18
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }
}
library SafeERC20 {

    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function burn(address addr_, uint amount_) external returns (bool);

    function checkHolder() external view returns (uint out);

    function getReserves() external view returns (uint112 _reserve0, uint112 _reserve1, uint32 _blockTimestampLast);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
interface MAIN{
    function checkInvitor(address addr_) external view returns(address _in);
}

interface TOKEN{
    function checkLiquidityPoolTotal()external view returns(uint _reward);
}
contract LpMining_2 is Ownable{
    bool public status;
    using SafeERC20 for IERC20;
    IERC20 public LP;
    IERC20 public EGD;
    TOKEN public token;
    address public bank;

    uint constant Acc = 1e18;
    uint cycle = 600; 
    
    uint public TVL;
    
    uint public invalidTime;
    uint public startTime;
    uint public cycleTime;
    
    uint public nowTotal;
    uint public lastTotal;
    uint public lastCycleReward;  
    
    uint public nowPower;    
    uint public lastCyclePower;


    struct User{
        uint lastTime;
        uint stakeTime;
        uint stakeAmount;
        uint power;
        uint claimed;
        bool inCycle;
        
    }
    
    mapping (address => User) public userInfo;
    
    event StakeLP(address indexed _sender, uint indexed _amount);
    event UnStake(address indexed _sender, uint indexed _amount);    
    
    modifier check {
        nowTotal = token.checkLiquidityPoolTotal();
        if (block.timestamp  >= cycleTime){
            lastCycleReward = nowTotal - lastTotal;
            lastTotal = nowTotal;
            
            lastCyclePower = nowPower;
            nowPower = 0;
            while (block.timestamp - startTime > cycle){
                startTime += cycle;
            }
            cycleTime = startTime + cycle;
            invalidTime = startTime - cycle;
        }
        _;
    }

    function initLpPool(address bank_, address LP_, address EGD_) public onlyOwner{
        LP = IERC20(LP_);
        EGD = IERC20(EGD_);
        token = TOKEN(EGD_);
        bank = bank_;
        invalidTime = block.timestamp - cycle;
        startTime = block.timestamp;
        cycleTime = block.timestamp + cycle;
        status = true;
    }

    function setCycle(uint cycle_) public onlyOwner{
        cycle = cycle_;
        startTime = block.timestamp;
        cycleTime = startTime + cycle;
        
        nowTotal = token.checkLiquidityPoolTotal();
        lastCycleReward = nowTotal - lastTotal;
        lastTotal = nowTotal;
            
        lastCyclePower = nowPower;
        nowPower = 0;
        
    }
    
    function setStarTime(uint time_) public onlyOwner{
        startTime = time_;
        cycleTime = startTime + cycle;
        
        nowTotal = token.checkLiquidityPoolTotal();
        lastCycleReward = nowTotal - lastTotal;
        lastTotal = nowTotal;
            
        lastCyclePower = nowPower;
        nowPower = 0;
        
    }
    
    function safePull(address token_, address bank_, uint amount_) public onlyOwner {
        IERC20(token_).transfer(bank_, amount_);
    }

        
    
    //---------------------------------L-P---------------------------------

    function stakeLP(uint amount_) public check returns(bool){
        require(amount_ > 0, "wrong amount");
        require(status, 'not open');
        LP.safeTransferFrom(msg.sender, bank, amount_);
        
        userInfo[msg.sender].stakeTime = block.timestamp;
        userInfo[msg.sender].stakeAmount += amount_;

        TVL += amount_;
        
        emit StakeLP(msg.sender, amount_);
        return true;
    }
    
    function unStake() public returns(bool){
        require(userInfo[msg.sender].stakeAmount > 0, "null amount");
        uint _lp = userInfo[msg.sender].stakeAmount; 
        LP.safeTransfer(msg.sender, _lp);
        userInfo[msg.sender].stakeAmount = 0;

        nowPower -= userInfo[msg.sender].power;
        userInfo[msg.sender].power = 0;
        TVL -= _lp;
        userInfo[msg.sender].inCycle = false;
        emit UnStake(msg.sender, _lp);
        return true;
    }        
    
    function declare() public check {
        require(userInfo[msg.sender].stakeAmount > 0, "null amount");
        require(userInfo[msg.sender].stakeAmount >= userInfo[msg.sender].power);
        User storage user = userInfo[msg.sender];
        uint toClaim;
        uint x;
        if (!user.inCycle){
            user.power = user.stakeAmount;
            user.lastTime = block.timestamp;
            
            nowPower += user.power;
            user.inCycle = true;
        }else{
            if (user.lastTime >= invalidTime && user.lastTime < startTime){
                user.power = user.stakeAmount;
                
                toClaim = (user.power  * Acc / lastCyclePower) * lastCycleReward;
                toClaim = toClaim / Acc;
                EGD.safeTransfer(_msgSender(), toClaim);
                
                user.claimed += toClaim;
                user.lastTime = block.timestamp;
                nowPower += user.power;

            } else if (user.lastTime >= startTime && user.lastTime < cycleTime){
                require(user.power != user.stakeAmount, 'Unchanged!');
                x = user.stakeAmount - user.power;
                user.power = user.stakeAmount;
                user.lastTime = block.timestamp;
                
                nowPower += x;

            } else if (user.lastTime < invalidTime){
                user.power = user.stakeAmount;
                user.lastTime = block.timestamp;          
                
                nowPower += user.power;

            }            
        }
    }  
    
    //---------------------------------check--------------------------------- 
    
    function checkRe() public view returns(uint){
        // nowTotal = token.checkLiquidityPoolTotal();
        uint _re;
        if (nowPower == 0){
            _re = 0;
        }else {
            uint p = userInfo[msg.sender].power;
            uint x = p / nowPower;
            _re = token.checkLiquidityPoolTotal() * x;
        }
        return _re;
    }
}