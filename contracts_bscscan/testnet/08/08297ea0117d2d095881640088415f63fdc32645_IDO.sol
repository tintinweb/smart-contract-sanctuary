/**
 *Submitted for verification at BscScan.com on 2021-12-05
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function mint(address account, uint amount) external;
}

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
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

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


library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != accountHash && codehash != 0x0);
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success,) = recipient.call{value : amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }


    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }


    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(address target, bytes memory data, uint256 weiValue, string memory errorMessage) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value : weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

contract IDO{
    using SafeMath for uint256;
    uint256 public nextId = 0;
    uint256 public currentId = 0;
    uint256 public MaxCurrentId = 2;
    IERC20 public sandddd = IERC20(0x09C18B20D78fEcb78f1Efc29dcCbd2041fb561fF);
    struct Raise{
        bool status;
        address receiver;
        uint256 minTokenOut;
        uint256 maxTokenOut;
        uint256 tokenOutHope;
        uint256 tokenOutRaised;
        uint256 tokenInRate;
        uint256 tokenOutRate;
        address tokenIn;
        //address tokenOut;
        uint256 rate;
    }
    mapping(uint256 => Raise) public raiseMap;

    struct UserInfo{
        uint256 reward;
        //uint256 inviteAmount;
        address leader;
        address[] invited;
        uint256[] reAmount;
    }
    mapping(address =>UserInfo) public userMap;
    mapping(address => bool) public manager;
    
    struct BathInfo{
        Raise raise;
        UserInfo user;
    }


    constructor() public {
        manager[msg.sender] = true;
        _setRaise(100000000000000000,20000000000000000000,1000000000000000000,3250,10,0x09C18B20D78fEcb78f1Efc29dcCbd2041fb561fF,10);
        _setRaise(100000000000000000,20000000000000000000,1000000000000000000,1625,10,0x09C18B20D78fEcb78f1Efc29dcCbd2041fb561fF,10);
        _setRaise(100000000000000000,20000000000000000000,1000000000000000000,8125,100,0x09C18B20D78fEcb78f1Efc29dcCbd2041fb561fF,10);
    }
    
    receive() external payable {
	}
    
    function plan(address _invite) payable external{
        require(raiseMap[currentId].status,"This order is not opened");
        require(raiseMap[currentId].tokenOutHope.sub(raiseMap[currentId].tokenOutRaised) > msg.value," No more quota");
        require(msg.value >= raiseMap[currentId].minTokenOut && msg.value <= raiseMap[currentId].maxTokenOut, "Quantity is not standard");
        //IERC20(raiseMap[currentId].tokenOut).transferFrom(msg.sender, raiseMap[currentId].receiver, _amount);
        uint256 tokenInAmount = msg.value.mul(raiseMap[currentId].tokenInRate).div(raiseMap[currentId].tokenOutRate);
        IERC20(raiseMap[currentId].tokenIn).transfer(msg.sender, tokenInAmount);
        raiseMap[currentId].tokenOutRaised = raiseMap[currentId].tokenOutRaised.add(msg.value);


        if(msg.sender != (_invite) && userMap[msg.sender].leader == address(0) && _invite != address(0)){
            userMap[msg.sender].leader = _invite;
        }

        if(userMap[msg.sender].leader != address(0)){
            userMap[userMap[msg.sender].leader].reward = tokenInAmount.mul(raiseMap[currentId].rate).div(100);
            userMap[userMap[msg.sender].leader].invited.push(msg.sender);
            userMap[userMap[msg.sender].leader].reAmount.push(msg.value);
        }     

        if(raiseMap[currentId].tokenOutHope.sub(raiseMap[currentId].tokenOutRaised) < raiseMap[currentId].minTokenOut){
            if(currentId < MaxCurrentId){
                currentId = currentId.add(1);
            }
        }
    }

    function withdrawal() public{
        uint256 bal = userMap[msg.sender].reward;
        userMap[msg.sender].reward = 0;
        sandddd.transfer(msg.sender,bal);
		//payable(msg.sender).transfer(address(this).balance);
	}

    
    function setRaise(uint256 _minTokenOut,uint256 _maxTokenOut,uint256 _tokenOutHope, uint256 _tokenInRate, uint256 _tokenOutRate, address _tokenIn, uint256 _rate) external onlyOwner{
        require(raiseMap[nextId].status != true,"Plan already exists");   

        //IERC20(_tokenIn).transferFrom(msg.sender, address(this), _tokenOutHope.mul(_tokenInRate).div(_tokenOutRate));
        raiseMap[nextId].status = true;
        raiseMap[nextId].receiver = msg.sender;
        raiseMap[nextId].minTokenOut = _minTokenOut;
        raiseMap[nextId].maxTokenOut = _maxTokenOut;
        raiseMap[nextId].tokenOutHope = _tokenOutHope;
        raiseMap[nextId].tokenInRate = _tokenInRate;
        raiseMap[nextId].tokenOutRate = _tokenOutRate;
        raiseMap[nextId].tokenIn = _tokenIn;
        raiseMap[nextId].rate = _rate;      

        //raiseMap[nextId].tokenOut = _tokenOut;
        nextId = nextId.add(1);
    }

    function _setRaise(uint256 _minTokenOut,uint256 _maxTokenOut,uint256 _tokenOutHope, uint256 _tokenInRate, uint256 _tokenOutRate, address _tokenIn, uint256 _rate)internal{
        require(raiseMap[nextId].status != true,"Plan already exists");   

        //IERC20(_tokenIn).transferFrom(msg.sender, address(this), _tokenOutHope.mul(_tokenInRate).div(_tokenOutRate));
        raiseMap[nextId].status = true;
        raiseMap[nextId].receiver = msg.sender;
        raiseMap[nextId].minTokenOut = _minTokenOut;
        raiseMap[nextId].maxTokenOut = _maxTokenOut;
        raiseMap[nextId].tokenOutHope = _tokenOutHope;
        raiseMap[nextId].tokenInRate = _tokenInRate;
        raiseMap[nextId].tokenOutRate = _tokenOutRate;
        raiseMap[nextId].tokenIn = _tokenIn;
        raiseMap[nextId].rate = _rate;      

        //raiseMap[nextId].tokenOut = _tokenOut;
        nextId = nextId.add(1);
    }
    
    function setNextId(uint256 _nextId) external onlyOwner{
        nextId = _nextId;
    }
    
    function setCurrentId(uint256 _currentId) external onlyOwner{
        currentId = _currentId;
    }

    function setMaxCurrentId(uint256 _maxCurrentId) external onlyOwner{
        MaxCurrentId = _maxCurrentId;
    }
    
    function withdrawStuckTokens(address _token, uint256 _amount) public onlyOwner {
        IERC20(_token).transfer(msg.sender, _amount);
    }
    
    function withdrawalETH() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    function bathcall(address _user) external view returns(BathInfo memory){
        BathInfo memory bathInfo;
        bathInfo.raise = raiseMap[currentId];
        bathInfo.user = userMap[_user];
        return bathInfo;
    }    
        
    modifier onlyOwner {
        require(manager[msg.sender] == true);
        _;
    }
}