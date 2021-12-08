/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-08
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

contract BCL_Minning is Ownable{
    event ClaimReward(address indexed sender, uint indexed reward);
    event Stake(address indexed sender, uint indexed amount);
    event UnStake(address indexed sender, uint indexed amount);

    using SafeERC20 for IERC20;
    IERC20 public BCL;
    IERC20 public LP;
    address bank;

    bool public status;
    uint public coe;
    uint public miners;
    uint public startTime;
    uint public totalOutput;
    uint public dailyOut;
    uint public rate;

    uint public constant Acc = 1e18;
    uint public TVL;
    uint public debt;
    uint public lastTime;

    struct UserInfo {
        uint stakeAmount;
        uint stakePower;
        uint stakeTime;
        uint toClaim;
        uint claimed;
        uint debt;
    }

    mapping(address => UserInfo) public userInfo;

    modifier checkMiners(){
        if (miners > 5000) {
            coe = 10;        
        }else if (miners > 2000 && miners <= 5000){
            coe = 7;
        }else if (miners > 500 && miners <= 2000){
            coe = 5;
        }else if (miners > 0 && miners <= 500){
            coe = 3;
        }
        _;
    }
    function initCon(bool com_, address bcl_, address LP_, address bank_ ) public onlyOwner{
        if (TVL == 0){
            startTime = block.timestamp;
        }
        status = com_;    
        BCL = IERC20(bcl_);
        LP = IERC20(LP_); 
        bank = bank_;    
    }

    function initOutput(uint total_, uint days_) public returns(bool){
        totalOutput = total_;
        dailyOut = total_ / days_;
        rate = dailyOut / 1 days;
        return true;
    }

    function setMiners(uint miners_) public onlyOwner{
        miners = miners_;
    }

    //-------------------------- check -------------------------------//

    function checkReward(address addr_) public view returns(uint _reward){
        uint x = calculateReward(addr_);
        _reward = ((x + userInfo[addr_].toClaim) * coe) / 10 ;
    }

    function coutingDebt() public view returns (uint _debt){
        _debt = TVL > 0 ? rate * (block.timestamp - lastTime) * Acc / TVL + debt : 0 + debt;
    }

    function calculateReward(address addr_) view public returns(uint){
        uint _debt = coutingDebt();
        uint _reward = (_debt - userInfo[addr_].debt) * userInfo[addr_].stakeAmount / Acc;
        return _reward;
    }

    //-------------------------- minning ------------------------------//

    function claimReward() public checkMiners returns(bool) {
        require(userInfo[msg.sender].stakeAmount > 0, "no amount");
        uint rew = calculateReward(msg.sender);
        uint _newRew = rew + userInfo[msg.sender].toClaim;
        uint de = coutingDebt();
        userInfo[msg.sender].debt = de;
        userInfo[msg.sender].claimed += _newRew;
        userInfo[msg.sender].toClaim = 0;

        uint brunCoe = (10 - coe);

        BCL.safeTransfer(msg.sender, (_newRew * coe) / 10);
        if (brunCoe > 0){
            BCL.transfer(address(0), (_newRew * brunCoe) / 10);
        }

        emit ClaimReward(msg.sender, rew);
        return true;
    }

    function stakeLp(uint amount_) public checkMiners returns(bool) {
        require(amount_ > 0, "wrong amount");
        require(status, 'not open');     
        UserInfo storage uu = userInfo[msg.sender];
        if (uu.stakeAmount == 0){
            miners +=1;
        }

        if (userInfo[msg.sender].stakeAmount > 0){
            uint rew = calculateReward(msg.sender); //_reward
            uu.toClaim += rew;
            uu.stakeAmount += amount_;
        } else {
            uu.stakeAmount = amount_;
        }

        LP.safeTransferFrom(msg.sender, address(this), amount_);
        uint de = coutingDebt();

        debt = de;
        TVL += amount_;
        lastTime = block.timestamp;

        uu.debt = de;
        uu.stakeTime = block.timestamp;

        emit Stake(msg.sender, amount_);
        return true;
    }

    function unStakeLp() external checkMiners returns(bool) {
        require(userInfo[msg.sender].stakeAmount > 0, 'no amount');
        UserInfo storage uu = userInfo[msg.sender];
        uint _temp = uu.stakeAmount;

        claimReward();
        uint de = coutingDebt();

        debt = de;
        TVL -= _temp;
        lastTime = block.timestamp;

        LP.safeTransfer(msg.sender, _temp);

        uu.stakeAmount = 0;
        uu.debt = 0;
        uu.stakeTime = 0;

        miners -= 1;

        emit UnStake(msg.sender, _temp);
        return true;
    }

    function safePull(address token_, address bank_, uint amount_) public onlyOwner {
        IERC20(token_).transfer(bank_, amount_);
    }


}