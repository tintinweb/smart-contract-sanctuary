/**
 *Submitted for verification at testnet.snowtrace.io on 2022-01-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, 'SafeMath: addition overflow');

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, 'SafeMath: subtraction overflow');
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {

        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, 'SafeMath: multiplication overflow');

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, 'SafeMath: division by zero');
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, 'SafeMath: modulo by zero');
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }

    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x < y ? x : y;
    }

    function sqrt(uint256 y) internal pure returns (uint256 z) {
        if (y > 3) {
            z = y;
            uint256 x = y / 2 + 1;
            while (x < z) {
                z = x;
                x = (y / x + x) / 2;
            }
        } else if (y != 0) {
            z = 1;
        }
    }
}

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    
    constructor()  {}

    function _msgSender() internal view returns (address ) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

abstract contract ReentrancyGuard {

    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;
    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}

contract Pausable is Context {
    
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

interface Ivesting{
  function intialize(uint256 teamshare, uint256 advisorShare, uint256 saleShare, address IGLXtoken ) external ;
}

contract IglooxVesting is Ownable, Pausable {
    using SafeMath for uint256;

    address public teamWallet;
    address public advisorWallet;
    address public AvalaunchSale;

    uint256 public teamShare;
    uint256 public currentTeamShare;
    uint256 public saleShare;
    uint256 public currentSaleShare;
    uint256 public advisorShare;
    uint256 public currentadvisorShare;
    uint256 public intializedTime;
    uint256 public launchTime;
    IERC20 public IGLX;
    uint256 public teamLastClaim;
    uint256 public advisorlastClaim;
    bool public intilialized;

    uint256 public teamMonthlyPercent = 50;
    uint256 public advisorMonthlyPercent = 200;
    uint256 public AvalaunchSalePercentage = 250;

    event ClaimTeamShare(address indexed owner, uint256 claimTokenAmount, uint256 claimTime);
    event ClaimAdvisorShare(address indexed owner, uint256 claimTokenAmount, uint256 claimTime);
    event Emergency(address indexed owner, address receiver,address tokenAddress, uint256 tokenAmount);

    constructor(address _teamWallet, address _advisorWallet, address _AvalaunchSale) { 
        teamWallet = _teamWallet;
        advisorWallet = _advisorWallet;
        AvalaunchSale = _AvalaunchSale;
    }

    function intialize(uint256 _teamUsed, uint256 _advisorUsed, uint256 _saleToken, address _iglooxToken) external {
        require(!intilialized,"already intilialized");
        teamShare = _teamUsed;
        currentTeamShare = teamShare;
        advisorShare = _advisorUsed;
        currentadvisorShare = advisorShare;
        saleShare = _saleToken;
        currentSaleShare = saleShare;
        intializedTime = block.timestamp;
        IGLX = IERC20(_iglooxToken);
        intilialized = true;
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unPause() external onlyOwner {
        _unpause();
    }

    function updateIGLX(address _newIGLX) external onlyOwner {
        IGLX = IERC20(_newIGLX);
    }

    function updateTeamPercentage(uint256 _newPercentage) external onlyOwner {
        teamMonthlyPercent = _newPercentage;
    }

    function updateAdvisorPercentage(uint256 _newPercentage) external onlyOwner {
        advisorMonthlyPercent = _newPercentage;
    }

    function updateAvalaunchPercentage(uint256 _newPercentage) external onlyOwner {
        AvalaunchSalePercentage = _newPercentage;
    }

    function updateAvalaunchsale(address _newAvalaunch) external onlyOwner {
        AvalaunchSale = _newAvalaunch;
    }

    function claimTeamShare() external returns(uint256){
        require(intializedTime.add(365 days) < block.timestamp,"Token is locked");
        require(_msgSender() == teamWallet,"caller is not a teamWallet");
        uint256 count;
        if(teamLastClaim == 0){
           teamLastClaim = intializedTime.add(365 days); 
           count = block.timestamp.sub(teamLastClaim).div(30 days);
           count = count + 1;
        } else{
            require(teamLastClaim.add(30 days) < block.timestamp,"");
            count = block.timestamp.sub(teamLastClaim).div(30 days);
            teamLastClaim = teamLastClaim.add(30 days * count);
        }
        
        uint256 currentPercentage = teamShare.mul(teamMonthlyPercent).div(1e3).mul(count);
        currentTeamShare = currentTeamShare.sub(currentPercentage);
        IGLX.transfer(msg.sender, currentPercentage);

        emit ClaimTeamShare(msg.sender, currentPercentage, block.timestamp);
        return currentPercentage;
    }

    function claimAdvisorShare() external returns(uint256){
        require(_msgSender() == advisorWallet,"caller is not a advisor wallet");
        require(intializedTime.add(365 days * 2) < block.timestamp,"Token is locked");
        uint256 count;
        if(advisorlastClaim == 0){
           advisorlastClaim = intializedTime.add(365 days * 2); 
           count = block.timestamp.sub(advisorlastClaim).div(30 days);
           count = count + 1;
        } else{
            require(advisorlastClaim.add(30 days) < block.timestamp,"");
            count = block.timestamp.sub(advisorlastClaim).div(30 days);
            advisorlastClaim = advisorlastClaim.add(30 days * count);
        }
        uint256 currentPercentage = advisorShare.mul(advisorMonthlyPercent).div(1e3).mul(count);
        currentadvisorShare = currentadvisorShare.sub(currentPercentage);
        IGLX.transfer(msg.sender, currentPercentage);

        emit ClaimTeamShare(msg.sender, currentPercentage, block.timestamp);
        return currentPercentage;
    }

    function launchAvalaunch() external onlyOwner {
        
        uint256 count;
        if(launchTime == 0){
           launchTime = block.timestamp; 
           count = block.timestamp.sub(launchTime).div(30 days);
           count = count + 1;
        } else{
            require(intializedTime.add(90 days) < block.timestamp,"Token is locked");
            count = block.timestamp.sub(launchTime).div(90 days);
            launchTime = launchTime.add(90 days * count);
        }
        uint256 tokens = saleShare.mul(AvalaunchSalePercentage).div(1e3).mul(count);
        currentSaleShare = currentSaleShare.sub(tokens,"sale share completed");
        IGLX.transfer(AvalaunchSale, tokens);
    }

    function emergencySafe(address _token,address _to, uint256 _tokenAmount) external onlyOwner {
        if(_token == address(0x0)){
            require(payable(_to).send(_tokenAmount),"AVAX transaction failed");
        } else {
            IERC20(_token).transfer(_to, _tokenAmount);
        }

        emit Emergency(msg.sender, _to, _token, _tokenAmount); 
    }

}