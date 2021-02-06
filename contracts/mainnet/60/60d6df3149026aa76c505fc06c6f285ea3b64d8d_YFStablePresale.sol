/**
 *Submitted for verification at Etherscan.io on 2021-02-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

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
abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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

library Constants {
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _launchSupply = 60450 * 10**9;
    uint256 private constant _largeTotal = (MAX - (MAX % _launchSupply));

    uint256 private constant _baseExpansionFactor = 100;
    uint256 private constant _baseContractionFactor = 100;
    uint256 private constant _baseUtilityFee = 50;
    uint256 private constant _baseContractionCap = 1000;

    uint256 private constant _stabilizerFee = 250;
    uint256 private constant _stabilizationLowerBound = 50;
    uint256 private constant _stabilizationLowerReset = 75;
    uint256 private constant _stabilizationUpperBound = 150;
    uint256 private constant _stabilizationUpperReset = 125;
    uint256 private constant _stabilizePercent = 10;

    uint256 private constant _treasuryFee = 250;

    uint256 private constant _presaleMinIndividualCap = 1 ether;
    uint256 private constant _presaleMaxIndividualCap = 4 ether;
    uint256 private constant _presaleCap = 37200 * 10**9; 
    uint256 private constant _maxPresaleGas = 200000000000;

    uint256 private constant _epochLength = 4 hours;

    uint256 private constant _liquidityReward = 2 * 10**9;
    uint256 private constant _minForLiquidity = 10 * 10**9;
    uint256 private constant _minForCallerLiquidity = 10 * 10**9;

    address private constant _routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant _factoryAddress = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    address payable private constant _deployerAddress = 0xB4a43aEd87902A24cD66afBD3349Af812325Ca01;
    address private constant _treasuryAddress = 0xB4a43aEd87902A24cD66afBD3349Af812325Ca01;

    uint256 private constant _presaleRate = 31000;
    uint256 private constant _listingRate = 29063;

    string private constant _name = "YFStable";
    string private constant _symbol = "YFST";
    uint8 private constant _decimals = 9;

    /****** Getters *******/
    function getPresaleRate() internal pure returns (uint256) {
        return _presaleRate;
    }
     function getListingRate() internal pure returns (uint256) {
        return _listingRate;
    }
    function getLaunchSupply() internal pure returns (uint256) {
        return _launchSupply;
    }
    function getLargeTotal() internal pure returns (uint256) {
        return _largeTotal;
    }
    function getPresaleCap() internal pure returns (uint256) {
        return _presaleCap;
    }
    function getPresaleMinIndividualCap() internal pure returns (uint256) {
        return _presaleMinIndividualCap;
    }
    function getPresaleMaxIndividualCap() internal pure returns (uint256) {
        return _presaleMaxIndividualCap;
    }
    function getMaxPresaleGas() internal pure returns (uint256) {
        return _maxPresaleGas;
    }
    function getBaseExpansionFactor() internal pure returns (uint256) {
        return _baseExpansionFactor;
    }
    function getBaseContractionFactor() internal pure returns (uint256) {
        return _baseContractionFactor;
    }
    function getBaseContractionCap() internal pure returns (uint256) {
        return _baseContractionCap;
    }
    function getBaseUtilityFee() internal pure returns (uint256) {
        return _baseUtilityFee;
    }
    function getStabilizerFee() internal pure returns (uint256) {
        return _stabilizerFee;
    }
    function getStabilizationLowerBound() internal pure returns (uint256) {
        return _stabilizationLowerBound;
    }
    function getStabilizationLowerReset() internal pure returns (uint256) {
        return _stabilizationLowerReset;
    }
    function getStabilizationUpperBound() internal pure returns (uint256) {
        return _stabilizationUpperBound;
    }
    function getStabilizationUpperReset() internal pure returns (uint256) {
        return _stabilizationUpperReset;
    }
    function getStabilizePercent() internal pure returns (uint256) {
        return _stabilizePercent;
    }
    function getTreasuryFee() internal pure returns (uint256) {
        return _treasuryFee;
    }
    function getEpochLength() internal pure returns (uint256) {
        return _epochLength;
    }
    function getLiquidityReward() internal pure returns (uint256) {
        return _liquidityReward;
    }
    function getMinForLiquidity() internal pure returns (uint256) {
        return _minForLiquidity;
    }
    function getMinForCallerLiquidity() internal pure returns (uint256) {
        return _minForCallerLiquidity;
    }
    function getRouterAdd() internal pure returns (address) {
        return _routerAddress;
    }
    function getFactoryAdd() internal pure returns (address) {
        return _factoryAddress;
    }
    function getDeployerAdd() internal pure returns (address payable) {
        return _deployerAddress;
    }
    function getTreasuryAdd() internal pure returns (address) {
        return _treasuryAddress;
    }
    function getName() internal pure returns (string memory)  {
        return _name;
    }
    function getSymbol() internal pure returns (string memory) {
        return _symbol;
    }
    function getDecimals() internal pure returns (uint8) {
        return _decimals;
    }
}
interface IYFStable {
    function isPresaleDone() external view returns (bool);
    function mint(address to, uint256 amount) external;
    function setPresaleDone() external payable;
}
contract YFStablePresale is Context, Ownable {
    using SafeMath for uint256;
    using Address for address;
    IYFStable token;
    // Presale stuff below
    uint256 private _presaleMint;
    uint256 public presaleTime = now;
    uint256 public presalePrice;
    mapping (address => uint256) private _presaleParticipation;
    bool public presale = false;

    constructor (address tokenAdd) public {
        token = IYFStable(tokenAdd);
        presaleTime;
        presalePrice = Constants.getPresaleRate();
    }

    function setPresaleTime(uint256 time) external onlyOwner() {
        require(token.isPresaleDone() == false, "This cannot be modified after the presale is done");
        presaleTime = time;
    }

    function setPresaleFlag(bool flag) external onlyOwner() {
        require(!token.isPresaleDone(), "This cannot be modified after the presale is done");
        if (flag == true) {
            require(presalePrice > 0, "Sale price has to be greater than 0");
        }
        presale = flag;
    }
    

    function setPresalePrice(uint256 priceInWei) external onlyOwner() {
        require(!presale && !token.isPresaleDone(),"Can only be set before presale starts");
        presalePrice = priceInWei;
    }

    // Presale function
    receive() external payable {
        require(presale, "Presale is inactive");
        require(!token.isPresaleDone(), "Presale is already completed");
        require(presaleTime <= now, "Presale hasn't started yet");
        uint256 invest = _presaleParticipation[_msgSender()].add(msg.value);
        require(invest <= Constants.getPresaleMaxIndividualCap() && invest >= Constants.getPresaleMinIndividualCap(), "Crossed individual cap");
        require(presalePrice != 0, "Presale price is not set");
        require(msg.value > 1, "Cannot buy without sending at least 1 eth mate!");
        require(!Address.isContract(_msgSender()),"no contracts");
        require(tx.gasprice <= Constants.getMaxPresaleGas(),"gas price above limit");
        uint256 amountToMint = msg.value.div(10**11).mul(presalePrice);
        require(_presaleMint.add(amountToMint) <= Constants.getPresaleCap(), "Presale max cap already reached");
        token.mint(_msgSender(),amountToMint);
        _presaleParticipation[_msgSender()] = _presaleParticipation[_msgSender()].add(msg.value);
        _presaleMint = _presaleMint.add(amountToMint);
    }

    function presaleDone() external onlyOwner() {
        require(!token.isPresaleDone(), "Presale is already completed");
        token.setPresaleDone{value:address(this).balance}();
    }

    function emergencyWithdraw() external onlyOwner() {
        require(!token.isPresaleDone(), "Presale is already completed");
        _msgSender().transfer(address(this).balance);
    }
}