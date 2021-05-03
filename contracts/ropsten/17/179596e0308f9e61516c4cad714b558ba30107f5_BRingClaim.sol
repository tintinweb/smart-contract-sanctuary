/**
 *Submitted for verification at Etherscan.io on 2021-05-03
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

  uint256 initialPercent;
  uint256 monthlyPercent;

  bool initialRewardReceived;
  uint256 monthlyRewardsReceived;
  uint256 totalPercentReceived;
  uint256 totalReceived;
}

contract BRingClaim is Ownable {

  using SafeMath for uint256;

  address public TOKEN_CONTRACT_ADDRESS = address(0x8C8d7F3A1905154B603FC84bA301F57F1936a507); 

  uint256 public constant CLAIMING_PERIOD = 5 minutes;

  uint256 public STRATEGIC_ROUND_START_TIME;
  uint256 public PRIVATE_ROUND_START_TIME;
  uint256 public TEAM_ROUND_START_TIME;

  mapping(address => Investor)[3] public investors;
  mapping(address => uint256) public claimedTokens;

  event NewAddress(address indexed _address, uint256 _boughtTokens, Round indexed _round, uint256 _initialPercent, uint256 _monthlyPercent);
  event RoundTimeConfigured(Round _round, uint256 _time);
  event InitialClaimWithdrawn(address indexed _address, Round indexed _round, uint256 _tokensAmount);
  event MonthlyClaimWithdrawn(address indexed _address, Round indexed _round, uint256 _tokensAmount);

  constructor() {
    addAddress(address(0x1958662bF4b23B638cBa463C134D2Cf414027288), 500 ether, Round.Private, 15, 5);
    addAddress(address(0xa187dC724624877a97F5d02734E9871E2427C3B7), 2000 ether, Round.Private, 15, 5);
    addAddress(address(0x56373aec74a28117BA5bD85cca8bfCec515453f0), 1000 ether, Round.Private, 15, 5);
    addAddress(address(0x02fEC1e5e224Da14Dfe29237042D56a96523949E), 1000 ether, Round.Private, 15, 5);
    addAddress(address(0x98Ff7895075fE2978eCe7580F74f4025E396A732), 1000 ether, Round.Private, 15, 5);
    addAddress(address(0x5e4B9eE7Bc57D77e13b050e078885651B4D092cc), 800 ether, Round.Private, 15, 5);
    addAddress(address(0x380351fEfAAabcAFF0aBE9e5609c3f5089B59d52), 325 ether, Round.Private, 15, 5);
    addAddress(address(0xc557936e8D79aDc6b9dCA2C67D9a7b1A47391d87), 1000 ether, Round.Private, 15, 5);
    addAddress(address(0x121D26685013baf726e309F5762ecEe520Fcc702), 1000 ether, Round.Private, 15, 5);
    addAddress(address(0x8cEC27A195145143E0B6e75574e0ebCD0C0D4805), 1000 ether, Round.Private, 15, 5);
    addAddress(address(0xBba738A1A98a3F2E7312Ca71896416f69F9e7bf2), 1000 ether, Round.Private, 15, 5);
    addAddress(address(0xA4d3eA01e5205f349aFfa727632d6B8b6FC28Da9), 700 ether, Round.Private, 15, 5);
    addAddress(address(0xFB3018F1366219eD3fE8CE1B844860F9c4Fac5e7), 250 ether, Round.Private, 15, 5);
    addAddress(address(0xc7d23FE48F3DAE21b5B91568eDFF2a103b1E2E6A), 1000 ether, Round.Private, 15, 5);
    addAddress(address(0x0D1f7fd6DcccB4e9C00Fe1c0F869543813F342c0), 2000 ether, Round.Private, 15, 5);
    addAddress(address(0x7604100fc7d73FB2179dafd86A93a3215502ebae), 2000 ether, Round.Private, 15, 5);
    addAddress(address(0xF9c229512B62434eB5dE37823C9c899c100B9050), 300 ether, Round.Private, 15, 5);
    addAddress(address(0x68daaf91EaAA05f56Fb929441E646f4E190C8e9A), 1000 ether, Round.Private, 15, 5);
    addAddress(address(0xb74B327CC230fDa53E5b0262C2773fced1e8Ab2d), 1000 ether, Round.Private, 15, 5);
    addAddress(address(0xFf3D84eC5A84A71Db1ada84E66D90395c81d7ba2), 2000 ether, Round.Private, 15, 5);
    addAddress(address(0xb2AbB01a1896673Bf166830C5dC01fB35c0C9F67), 500 ether, Round.Private, 15, 5);
    addAddress(address(0x8fBAadd3a7ae19C66EA9f00502626988313ac96c), 1000 ether, Round.Private, 15, 5);
    addAddress(address(0xFC5374ABf90Bc9217fd88628E4847dD27950B92c), 1000 ether, Round.Private, 15, 5);
    addAddress(address(0xaADA0f64aA9e3Fa0461eF5efAcD1D879D5e66848), 3000 ether, Round.Private, 15, 5);
    addAddress(address(0xB15d2ABeC2CDB7d41b30C4537203EF15a509fBB5), 600 ether, Round.Private, 15, 5);
    addAddress(address(0xa31978A297a8e78E7c8AeF86eEC055786d65804D), 500 ether, Round.Private, 15, 5);
    addAddress(address(0xAe3E0020b64bc91C373012aa3B01ec4ff85ef581), 1000 ether, Round.Private, 15, 5);
    addAddress(address(0x691B48454D5E2aCc7bb8aCB4a7a992a983Af2872), 500 ether, Round.Private, 15, 5);
    addAddress(address(0xd40f0D8f08Eb702Ce5b4Aa039a7B004043433098), 400 ether, Round.Private, 15, 5);
    addAddress(address(0x202be7E4F66ab72Fe6Cf042938c7A19eA332f112), 300 ether, Round.Private, 15, 5);
    addAddress(address(0x8084d3FB905F31663153898FE034Dce72B7D2297), 450 ether, Round.Private, 15, 5);
    addAddress(address(0x3e8204402560493824e5D75fF2333128D7e9F109), 1000 ether, Round.Private, 15, 5);
    addAddress(address(0x1dC122dB61D53A8E088d63Af743F4D4c713e8A20), 500 ether, Round.Private, 15, 5);
    addAddress(address(0x0269ACB6DC3f5672A2295e018896Eb75095D790A), 500 ether, Round.Private, 15, 5);
    addAddress(address(0xDDF33967Ff57A679E3B65f8f70eE393e075Bfa59), 1000 ether, Round.Private, 15, 5);
    addAddress(address(0x9C5366709CA3889c4E4E27693301B456d5213a13), 500 ether, Round.Private, 15, 5);
    addAddress(address(0xB234A630062161F8376507e773e23bC4cBa49676), 1000 ether, Round.Private, 15, 5);
    addAddress(address(0xD1A7Ed463BbeE05a6BFb6e2e8912677214A30d19), 2000 ether, Round.Private, 15, 5);
    addAddress(address(0x7E2FF036697A7D4614E549B8e6E0AaF123B5F8Bf), 1000 ether, Round.Private, 15, 5);
    addAddress(address(0xCbB74E8eAbCD36B160D1fC3BEd7bc6E52D327632), 3000 ether, Round.Private, 15, 5);
    addAddress(address(0xd90dF6D33d457e87949dd5288B923f71F90f38ba), 1000 ether, Round.Private, 15, 5);
  }

  function init() external onlyOwner {
    
  }

  function batchAddAddresses(address[] memory _addresses, uint256[] memory _boughtTokensAmounts, Round _round) external onlyOwner {
    require(_addresses.length == _boughtTokensAmounts.length, "Invalid input data");

    uint256 initialPercent;
    uint256 monthlyPercent;
    if (_round == Round.Strategic) {
      initialPercent = 10;
      monthlyPercent = 5;
    } else if (_round == Round.Private) {
      initialPercent = 15;
      monthlyPercent = 5;
    } else if (_round == Round.Team) {
      initialPercent = 0;
      monthlyPercent = 2;
    }

    for (uint8 i = 0; i < _addresses.length; i++) {
      addAddress(_addresses[i], _boughtTokensAmounts[i], _round, initialPercent, monthlyPercent);
    }
  }

  function setStrategicRoundStartTime(uint256 _timestamp) external onlyOwner {
    require(STRATEGIC_ROUND_START_TIME == 0, "Time is already configured");
    require(_timestamp >= block.timestamp, "Trying to set time in the past");

    STRATEGIC_ROUND_START_TIME = _timestamp;

    emit RoundTimeConfigured(Round.Strategic, _timestamp);
  }

  function setPrivateRoundStartTime(uint256 _timestamp) external onlyOwner {
    require(PRIVATE_ROUND_START_TIME == 0, "Time is already configured");
    require(_timestamp >= block.timestamp, "Trying to set time in the past");

    PRIVATE_ROUND_START_TIME = _timestamp;

    emit RoundTimeConfigured(Round.Private, _timestamp);
  }

  function setTeamRoundStartTime(uint256 _timestamp) external onlyOwner {
    require(TEAM_ROUND_START_TIME == 0, "Time is already configured");
    require(_timestamp >= block.timestamp, "Trying to set time in the past");

    TEAM_ROUND_START_TIME = _timestamp;

    emit RoundTimeConfigured(Round.Team, _timestamp);
  }

  function addAddress(address _address, uint256 _boughtTokens, Round _round, uint256 _initialPercent, uint256 _monthlyPercent) public onlyOwner {
    require(_address != address(0x0), "Invalid address provided");
    require(_boughtTokens >= 10**9, "Invalid tokens amount");
    require(_initialPercent.add(_monthlyPercent) <= 100, "Invalid percents amount");
    require(investors[uint256(_round)][_address].boughtTokens == 0, "Address already exists");

    investors[uint256(_round)][_address] = Investor({
      boughtTokens: _boughtTokens,
      initialPercent: _initialPercent,
      monthlyPercent: _monthlyPercent,
      initialRewardReceived: false,
      monthlyRewardsReceived: 0,
      totalPercentReceived: 0,
      totalReceived: 0
    });

    emit NewAddress(_address, _boughtTokens, _round, _initialPercent, _monthlyPercent);
  }

  function claimInitialTokens() external {
    uint256 totalTokens;

    for (uint8 round = 0; round < 3; round++) {
      if (investors[round][msg.sender].boughtTokens <= 0) { 
        continue;
      }
      if (investors[round][msg.sender].initialRewardReceived) { 
        continue;
      }
      if (investors[round][msg.sender].initialPercent <= 0) { 
        continue;
      }

      uint256 tokensAmount = investors[round][msg.sender].boughtTokens.mul(investors[round][msg.sender].initialPercent).div(100);
      investors[round][msg.sender].initialRewardReceived = true;
      investors[round][msg.sender].totalPercentReceived = investors[round][msg.sender].totalPercentReceived.add(investors[round][msg.sender].initialPercent);
      investors[round][msg.sender].totalReceived = investors[round][msg.sender].totalReceived.add(tokensAmount);

      totalTokens = totalTokens.add(tokensAmount);

      emit InitialClaimWithdrawn(msg.sender, Round(round), tokensAmount);
    }

    if (totalTokens > 0) {
      require(IERC20(TOKEN_CONTRACT_ADDRESS).transfer(msg.sender, totalTokens), "Tokens transfer error");
    }
  }

  function claimMonthlyTokens() external {
    uint256 totalTokens;

    for (uint8 round = 0; round < 3; round++) {
      if (investors[round][msg.sender].boughtTokens <= 0) { 
        continue;
      }
      if (investors[round][msg.sender].monthlyPercent <= 0) { 
        continue;
      }
      if (investors[round][msg.sender].totalPercentReceived >= 100) { 
        continue;
      }

      uint256 roundStartTime;
      if (round == uint8(Round.Strategic)) {
        roundStartTime = STRATEGIC_ROUND_START_TIME;
      } else if (round == uint8(Round.Private)) {
        roundStartTime = PRIVATE_ROUND_START_TIME;
      } else if (round == uint8(Round.Team)) {
        roundStartTime = TEAM_ROUND_START_TIME;
      }
      if (roundStartTime <= 0) { 
        continue;
      }

      uint256 months = block.timestamp.sub(roundStartTime).div(CLAIMING_PERIOD);
      if (months > investors[round][msg.sender].monthlyRewardsReceived) {
        uint256 rewardsNumber = months.sub(investors[round][msg.sender].monthlyRewardsReceived);

        uint256 percent = investors[round][msg.sender].monthlyPercent.mul(rewardsNumber);
        if (investors[round][msg.sender].totalPercentReceived.add(percent) > 100) {
          percent = uint256(100).sub(investors[round][msg.sender].totalPercentReceived);
        }
        uint256 tokensAmount = investors[round][msg.sender].boughtTokens.mul(percent).div(100);

        investors[round][msg.sender].monthlyRewardsReceived = investors[round][msg.sender].monthlyRewardsReceived.add(rewardsNumber);
        investors[round][msg.sender].totalPercentReceived = investors[round][msg.sender].totalPercentReceived.add(percent);
        investors[round][msg.sender].totalReceived = investors[round][msg.sender].totalReceived.add(tokensAmount);

        totalTokens = totalTokens.add(tokensAmount);

        emit MonthlyClaimWithdrawn(msg.sender, Round(round), tokensAmount);
      }
    }

    if (totalTokens > 0) {
      require(IERC20(TOKEN_CONTRACT_ADDRESS).transfer(msg.sender, totalTokens), "Tokens transfer error");
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