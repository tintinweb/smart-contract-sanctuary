/**
 *Submitted for verification at Etherscan.io on 2021-04-28
*/

pragma solidity >=0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; 
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

library Address {
    
    function isContract(address account) internal view returns (bool) {
        
        
        

        uint256 size;
        
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    
    function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            
            if (returndata.length > 0) {
                

                
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
    
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            
            
            
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    
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

    
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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

enum Round {
  Strategic,
  Private,
  Team
}

struct Investor {
  uint256 boughtTokens;

  Round round;
  uint256 initialPercent;
  uint256 monthlyPercent;

  bool initialRewardReceived;
  uint256 monthlyRewardsReceived;
  uint256 totalPercentReceived;
  uint256 totalReceived;
}

contract BRingClaim is Ownable {

  using SafeMath for uint256;

  address public TOKEN_CONTRACT_ADDRESS = address(0x1E139E22B55D3189E79d8B8992361fC57cfd9daa); 

  uint256 public CLAIMING_PERIOD = 10 minutes;

  uint256 public STRATEGIC_ROUND_START_TIME;
  uint256 public PRIVATE_ROUND_START_TIME;
  uint256 public TEAM_ROUND_START_TIME;

  mapping(address => Investor) public investors;
  address[] public investorsList;
  mapping(address => uint256) public claimedTokens;

  constructor() {}

  function setStrategicRoundStartTime(uint256 _timestamp) external onlyOwner {
    require(STRATEGIC_ROUND_START_TIME == 0, "Time is already configured");
    require(_timestamp >= block.timestamp, "Trying to set time in the past");

    STRATEGIC_ROUND_START_TIME = _timestamp;
  }

  function setPrivateRoundStartTime(uint256 _timestamp) external onlyOwner {
    require(PRIVATE_ROUND_START_TIME == 0, "Time is already configured");
    require(_timestamp >= block.timestamp, "Trying to set time in the past");

    PRIVATE_ROUND_START_TIME = _timestamp;
  }

  function setTeamRoundStartTime(uint256 _timestamp) external onlyOwner {
    require(TEAM_ROUND_START_TIME == 0, "Time is already configured");
    require(_timestamp >= block.timestamp, "Trying to set time in the past");

    TEAM_ROUND_START_TIME = _timestamp;
  }

  function addAddress(address _address, uint256 _boughtTokens, Round _round, uint256 _initialPercent, uint256 _monthlyPercent) external onlyOwner {
    require(_address != address(0x0), "Invalid address provided");
    require(_boughtTokens > 0, "Invalid tokens amount");
    require(investors[_address].boughtTokens == 0, "Address already exists");

    investors[_address] = Investor({
      boughtTokens: _boughtTokens,
      round: _round,
      initialPercent: _initialPercent,
      monthlyPercent: _monthlyPercent,
      initialRewardReceived: false,
      monthlyRewardsReceived: 0,
      totalPercentReceived: 0,
      totalReceived: 0
    });

    investorsList.push(_address);
  }

  function getInvestors() external view returns (address[] memory) {
    return investorsList;
  }

  function claimInitialTokens() external {
    require(investors[msg.sender].boughtTokens > 0, "You aren't an investor");
    require(!investors[msg.sender].initialRewardReceived, "You have already received initial reward");
    require(investors[msg.sender].initialPercent > 0, "You are not qualified for this reward");

    uint256 tokensAmount = investors[msg.sender].boughtTokens.mul(investors[msg.sender].initialPercent).div(100);
    investors[msg.sender].initialRewardReceived = true;
    investors[msg.sender].totalPercentReceived = investors[msg.sender].totalPercentReceived.add(investors[msg.sender].initialPercent);
    investors[msg.sender].totalReceived = investors[msg.sender].totalReceived.add(tokensAmount);

    require(IERC20(TOKEN_CONTRACT_ADDRESS).transfer(msg.sender, tokensAmount), "Tokens transfer error");
  }

  function claimMonthlyTokens() external {
    require(investors[msg.sender].boughtTokens > 0, "You aren't an investor");
    require(investors[msg.sender].monthlyPercent > 0, "You are not qualified for this reward");
    require(investors[msg.sender].totalPercentReceived < 100, "You have received all possible reward already");

    uint256 roundStartTime;
    if (investors[msg.sender].round == Round.Strategic) {
      roundStartTime = STRATEGIC_ROUND_START_TIME;
    } else if (investors[msg.sender].round == Round.Private) {
      roundStartTime = PRIVATE_ROUND_START_TIME;
    } else if (investors[msg.sender].round == Round.Team) {
      roundStartTime = TEAM_ROUND_START_TIME;
    }
    require(roundStartTime > 0, "Round start time hasn't configured");

    uint256 months = block.timestamp.sub(roundStartTime).div(CLAIMING_PERIOD);
    if (months > investors[msg.sender].monthlyRewardsReceived) {
      uint256 rewardsNumber = months.sub(investors[msg.sender].monthlyRewardsReceived);

      uint256 percent = investors[msg.sender].monthlyPercent.mul(rewardsNumber);
      if (investors[msg.sender].totalPercentReceived.add(percent) > 100) {
        percent = uint256(100).sub(investors[msg.sender].totalPercentReceived);
      }
      uint256 tokensAmount = investors[msg.sender].boughtTokens.mul(percent).div(100);

      investors[msg.sender].monthlyRewardsReceived = investors[msg.sender].monthlyRewardsReceived.add(rewardsNumber);
      investors[msg.sender].totalPercentReceived = investors[msg.sender].totalPercentReceived.add(percent);
      investors[msg.sender].totalReceived = investors[msg.sender].totalReceived.add(tokensAmount);

      require(IERC20(TOKEN_CONTRACT_ADDRESS).transfer(msg.sender, tokensAmount), "Tokens transfer error");
    }
  }

  function retrieveTokens(address _tokenAddress, uint256 _amount) public onlyOwner {
    require(_amount > 0, "Invalid amount");

    require(
      IERC20(_tokenAddress).balanceOf(address(this)) >= _amount,
      "Insufficient Balance"
    );

    require(
      IERC20(_tokenAddress).transfer(owner(), _amount),
      "Transfer failed"
    );
  }

}