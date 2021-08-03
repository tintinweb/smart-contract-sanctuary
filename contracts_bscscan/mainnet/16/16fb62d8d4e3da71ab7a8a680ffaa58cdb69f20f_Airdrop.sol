/**
 *Submitted for verification at BscScan.com on 2021-08-03
*/

pragma solidity ^0.8.4;

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    
}

library SafeMath {

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

}

contract Airdrop {
    
    using SafeMath for uint256;
    
    mapping (address => bool) private _isAirdropped;
    
    IERC20 public bluntV1;
    IERC20 public bluntV2;
    
    address owner = 0x1d6bcb669acDB742C853Bf56019B7415a37bcC75;
    
    constructor () {
        IERC20 _bluntV1 = IERC20(0x5E86955fF08838744D9d53784435Bdde85E6193B);
        bluntV1 = _bluntV1;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Caller is not the owner");
        _;
    }
    
    function getClaimable(address user) external view returns (uint256) {
        
        uint256 airdropAmount = bluntV1.balanceOf(user).mul(3).div(10);
    
        return airdropAmount;
    }
    
    function claim() external {
        require(_isAirdropped[msg.sender] == false, 'Already airdropped');
        require(bluntV1.balanceOf(msg.sender) > 0 , 'No V1 tokens');
        
        uint256 airdropAmount = this.getClaimable(msg.sender);
        
        bluntV2.transfer(msg.sender, airdropAmount);
        
        _isAirdropped[msg.sender] = true;
    }
    
    
    function setV2Token(address newToken) external onlyOwner() {
        IERC20 _bluntV2 = IERC20(newToken);
        bluntV2 = _bluntV2;
    }
    
    function collectTokens() external onlyOwner() {
        bluntV2.transfer(msg.sender, bluntV2.balanceOf(address(this)));
    }
}