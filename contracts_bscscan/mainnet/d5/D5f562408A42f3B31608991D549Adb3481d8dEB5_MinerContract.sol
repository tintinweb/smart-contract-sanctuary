/**
 *Submitted for verification at BscScan.com on 2021-10-09
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
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
        (bool success, bytes memory returndata) = target.call{ value: weiValue }(data);
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
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {return 0;}
        c = a * b;
        assert(c / a == b);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        if (b > a) {return 0;} else {return a - b;}
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {return a / b;}
    function max(uint256 a, uint256 b) internal pure returns (uint256) {return a >= b ? a : b;}
    function min(uint256 a, uint256 b) internal pure returns (uint256) {return a < b ? a : b;}
}

// Standard token interface
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

contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract MinerContract is Ownable {
    using Address for address;
    using SafeMath for uint256;
    
    IERC20 public token;
    
    address public tokenAddress;
    address public deployer;
    
    uint256 public unitsPerMiner = 2592000;
    
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    
    bool public initialized=false;
    
    address public feeRecipient;
    
    uint256 internal uplineRewardPercent;
    uint256 internal buybackTokenPercent;
    
    mapping (address => uint256) internal unitsOf_;
    mapping (address => uint256) internal minersOf_;
    
    mapping (address => uint256) internal lastCompoundTimeOf_;
    mapping (address => address) internal uplineOf_;
    
    modifier ifStarted() {
        require(initialized);
        _;
    }
    
    uint256 public totalUnits;
    
    constructor(address _tokenAddress, address _feeRecipient, uint8 _forBuyback, uint8 _forUpline) Ownable() public {
        tokenAddress = _tokenAddress;
        feeRecipient = _feeRecipient;
        
        token = IERC20(_tokenAddress);
        
        uplineRewardPercent = _forUpline;
        buybackTokenPercent = _forBuyback;
        
        deployer = msg.sender;
    }
    
    ////////////////////
    // VIEW FUNCTIONS //
    ////////////////////
    
    function calculateTrade(uint256 rt,uint256 rs, uint256 bs) public view returns(uint256) {
        return SafeMath.div(SafeMath.mul(PSN,bs),SafeMath.add(PSNH,SafeMath.div(SafeMath.add(SafeMath.mul(PSN,rs),SafeMath.mul(PSNH,rt)),rt)));
    }
    
    function calculateBuy(uint256 _amount, uint256 contractBalance) public view returns(uint256) {
        return calculateTrade(_amount, contractBalance, totalUnits);
    }
    
    function calculateBuySimple(uint256 _amount) public view returns(uint256){
        return calculateBuy(_amount, token.balanceOf(address(this)));
    }
    
    function calculateSell(uint256 _amount) public view returns(uint256) {
        return calculateTrade(_amount, totalUnits, token.balanceOf(address(this)));
    }
    
    function getBalance() public view returns(uint256) {
        return token.balanceOf(address(this));
    }
    
    function getMyMiners() public view returns(uint256) {
        return minersOf_[msg.sender];
    }
    
    function getMyUnits() public view returns(uint256) {
        return SafeMath.add(unitsOf_[msg.sender], getUnitsSinceLastCompound(msg.sender));
    }
    
    function harvestedOf(address _user) public view returns (uint256) {
        return unitsOf_[_user];
    }
    
    function lastCompoundTimeOf(address _user) public view returns (uint256) {
        return lastCompoundTimeOf_[_user];
    }
    
    function getUnitsSinceLastCompound(address adr) public view returns(uint256) {
        uint256 secondsPassed=min(unitsPerMiner, SafeMath.sub(now, unitsOf_[adr]));
        return SafeMath.mul(secondsPassed, minersOf_[adr]);
    }
    
    /////////////////////
    // WRITE FUNCTIONS //
    /////////////////////
    
    function start(uint256 amount) public onlyOwner() {
        token.transferFrom(address(msg.sender), address(this), amount);
        
        require(totalUnits == 0);
        
        initialized=true;
        
        totalUnits = 259200000000;
    }
    
    function deposit(address _upline, uint256 _amount) ifStarted() public {
        if (_upline == msg.sender || _upline == address(0)) {
            _upline = deployer;
        }

        token.transferFrom(address(msg.sender), address(this), _amount);
        
        // Calculate upline reward and contract fee before calculating deposits...
        uint256 uplineReward = ((_amount.div(100)).mul(uplineRewardPercent));
        uint256 buybackTotal = ((_amount.div(100)).mul(buybackTokenPercent));
        uint256 _totalFees = (uplineReward.add(buybackTotal));
        
        // Now that's all done with, let's actually account for what's left...
        uint256 actualDeposit = (_amount.sub(_totalFees));
        
        // Measure the current token balance...
        uint256 contractBalance = token.balanceOf(address(this));
        
        // Since there's no fees to take from the resulting deposit, user gets the whole lot!
        uint256 unitsCreated = calculateBuy(actualDeposit, SafeMath.sub(contractBalance, actualDeposit));

        // Pay both the Distillery and the Referrer directly with tokens...
        token.transfer(feeRecipient, buybackTotal);
        token.transfer(_upline, uplineReward);
        
        // Update units of the depositor...
        unitsOf_[msg.sender] = SafeMath.add(unitsOf_[msg.sender], unitsCreated);
        
        // Compound any earnings, to make them active...
        compound();
    }
    
    function compound() ifStarted() public {
        
        // Find available units, then calculate total of new miners...
        uint256 unitsAvailable = getMyUnits();
        uint256 newMiners = SafeMath.div(unitsAvailable, unitsPerMiner);
        
        // Add those new miners to the user's balance...
        minersOf_[msg.sender] = SafeMath.add(minersOf_[msg.sender], newMiners);
        
        // Clear the current unit count for the user...
        unitsOf_[msg.sender] = 0;
        
        // Record the timestamp...
        lastCompoundTimeOf_[msg.sender] = now;
        
        //boost market to nerf miners hoarding
        totalUnits = SafeMath.add(totalUnits, SafeMath.div(unitsAvailable, 5));
    }
    
    function harvest() ifStarted() public {
        
        uint256 availableEarnings = getMyUnits();
        
        uint256 totalValue = calculateSell(availableEarnings);
        uint256 buybackTotal = ((totalValue.div(100)).mul(buybackTokenPercent));
        
        unitsOf_[msg.sender] = 0;
        
        lastCompoundTimeOf_[msg.sender]=now;
        
        totalUnits = SafeMath.add(totalUnits, availableEarnings);
        
        token.transfer(feeRecipient, buybackTotal);
        token.transfer(address(msg.sender), SafeMath.sub(totalValue, buybackTotal));
    }
    
    //////////////////////////
    // OWNER-ONLY FUNCTIONS //
    //////////////////////////
    
    function updateFees(uint8 _forUpline, uint8 _forBuyback) onlyOwner() public {
        require((_forUpline + _forBuyback) < 10, "CHILL_OUT_BROTHER");
        
        uplineRewardPercent = _forUpline;
        buybackTokenPercent = _forBuyback;
    }
    
    function updateFeeRecipient(address _newRecipient) onlyOwner() public {
        require(_newRecipient != address(0) && _newRecipient != msg.sender, "INVALID_RECIPIENT");
        
        feeRecipient = _newRecipient;
    }

    //////////////////////////////////
    // PRIVATE / INTERNAL FUNCTIONS //
    //////////////////////////////////
    
    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}