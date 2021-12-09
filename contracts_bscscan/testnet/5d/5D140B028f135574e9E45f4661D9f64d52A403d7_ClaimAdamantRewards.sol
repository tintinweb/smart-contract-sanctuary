/**
 *Submitted for verification at BscScan.com on 2021-12-09
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-07
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

/**
 *Submitted for verification at BscScan.com on 2021-12-06
*/

pragma solidity ^0.8.0;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }
    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
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
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
contract ClaimAdamantRewards is Context, Ownable { 
 using SafeMath for uint256;
    IERC20 public useToken;
    address  public marketWalletAddress;
    // address private _adammat = 0xC262211A5F048eB8C5D9559D39df819263D6B3be;
    address private _adammatToken ;
    address BURN_ADDRESS = 0x000000000000000000000000000000000000dEaD;
    uint256 private _burnFee = 60; // Burn Fee    
    uint256 private _marketWalletFee = 20; // tranfered tokened
    uint256 public conversionReward;


    event ClaimReward(address to,uint256 amount);

    constructor(address _usetoken,address _marketWalletwAdress,uint256 conversionRate) public {
            useToken = IERC20(_usetoken);
            marketWalletAddress  = _marketWalletwAdress;
            _adammatToken = _usetoken;
            conversionReward = conversionRate;
    }
    //  60% of reward is sent to 0x0000dead address what is this 0x0000dead address ? 
    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_burnFee).div(
			10**2
		);
	}
    function calculateMarketWalletFee(uint256 _amount) private view returns (uint256) {
		return _amount.mul(_marketWalletFee).div(
			10**2
		);
	}
    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tMWalletFee = calculateMarketWalletFee(tAmount);
        uint256 tBurn = calculateBurnFee(tAmount);
        uint256 transferAmount = tAmount.sub(tMWalletFee).sub(tBurn);
        return (transferAmount, tMWalletFee , tBurn);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        (uint256 transferAmount, uint256 tMWalletFee, uint256 tBurn) = _getTValues(tAmount);
        return (transferAmount, tMWalletFee, tBurn);
    }
    // 4. 20% of reward is sent to marketing wallet (and pls add function change marketing wallet address)
    function addMarketAddress(address mwAddress) public onlyOwner {
        marketWalletAddress =  mwAddress;
    }

    // 5.  can add function to change token address of reward
    function changeToken(address _token) public onlyOwner {
        useToken =  IERC20(_token);
    }
    // recipient: player wallet
    function claimRewards(address recipient,uint256 amount) public onlyOwner() {
        require(amount > 0,"CANNOT_CLAIM_ZERO");

        (uint256 transferAmount, uint256 tMWalletFee, uint256 tBurn) = _getValues(amount);
        if(tBurn > 0){
            _transferBurn(_getConversionRateVal(tBurn));
        }
        if(tMWalletFee > 0){
            // if(conversionReward > 0){
            //     tMWalletFee = _getRate(tMWalletFee);
            // }
            _transfertMarketWallet(tMWalletFee);
        }
        require(useToken.balanceOf(msg.sender) >= amount || useToken.balanceOf(address(this)) >= amount,"NOT_ENOUGH_ADMC");
            //  if(conversionReward > 0){
            //     transferAmount = _getRate(transferAmount);
            // }
        useToken.transfer(recipient, transferAmount);
        emit ClaimReward( recipient, transferAmount);
    }
    function _transferBurn(uint256 tBurn) private {
         useToken.transfer(BURN_ADDRESS, tBurn);
	}  
     function _getConversionRateVal(uint256 _claimRewardAmount) private view returns (uint256) {
         if(conversionReward > 0){
    		return conversionReward.mul(_claimRewardAmount);
         }else{
    		return _claimRewardAmount.mul(1);
         }
	}
    function _transfertMarketWallet(uint256 tMWalletFee) private { 
        useToken.transfer(marketWalletAddress, tMWalletFee);
	} 
        // 1. function to set how much is conversion to rewards = ?
    function conversionRewardSet(uint256 _val) public onlyOwner() {
        conversionReward = _val;
    }
}