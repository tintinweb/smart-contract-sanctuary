/**
 *Submitted for verification at Etherscan.io on 2021-02-05
*/

pragma solidity ^0.4.24;
// ----------------------------------------------------------------------------
// @Name SafeMath
// @Desc Math operations with safety checks that throw on error
// https://github.com/OpenZeppelin/zeppelin-solidity/blob/master/contracts/math/SafeMath.sol
// ----------------------------------------------------------------------------
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}
// ----------------------------------------------------------------------------
// @Name ERC20 interface
// @Desc https://eips.ethereum.org/EIPS/eip-20
// ----------------------------------------------------------------------------
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external  returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
// ----------------------------------------------------------------------------
// @Name Ownable
// ----------------------------------------------------------------------------
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() { require(msg.sender == owner); _; }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}
// ----------------------------------------------------------------------------
// @Name AmazonFinanceRewardPool
// @Desc Contract Of Reward For Writing
// ----------------------------------------------------------------------------
contract AmazonFinanceRewardPool is Ownable {
    event eventChangeOwnerAddress(address previousOwner, address newOwner);
    event eventChangeTokenCAEvent(address previousCA, address newCA);
    event eventChangeRewardAmountEvent(uint256 indexed previousAmount, uint256 indexed newAmount);
    event eventFundTransfer(address backer, uint256 amount);
    event eventTokenWithdrawEvent(address withdrawAddress, uint256 amount);
    
    using SafeMath for uint256;

    IERC20 private TOKEN_CONTRACT_ADDRESS;
    address public OWNER_ADDRESS;
    uint256 public REWARD_RATE;
    
    constructor() public {
        TOKEN_CONTRACT_ADDRESS = IERC20(0x0B5aC384a35d029cDa75b8675ACe96Dfe670f54c);
        REWARD_RATE = 5000000000000000000;
        OWNER_ADDRESS = 0x9D2b30FB5EE941Cb59AE71Bb7Ef1C6f06dfeB6c7;
    }
    
    function () payable public {
        uint256 amount = msg.value;
        amount = amount.mul(REWARD_RATE);
        
        require(amount <= TOKEN_CONTRACT_ADDRESS.balanceOf(this));
    
        address(OWNER_ADDRESS).transfer(msg.value);
        tokenTransfer(amount);
    }
    
    function withdrawToken(address _to, uint256 _amount) external onlyOwner {
        require(TOKEN_CONTRACT_ADDRESS.transfer(_to, _amount));        
        emit eventTokenWithdrawEvent(_to, _amount);
    }

    function changeTokenAddress(IERC20 _tokenCA) external onlyOwner {
        require(_tokenCA != address(0));
        emit eventChangeTokenCAEvent(TOKEN_CONTRACT_ADDRESS, _tokenCA);
        TOKEN_CONTRACT_ADDRESS = _tokenCA;
    }
    
    // 1 ETH : _amount Token
    function changeRewardRate(uint256 _rate) external onlyOwner {
        emit eventChangeRewardAmountEvent(REWARD_RATE, _rate);
        REWARD_RATE = _rate;
    }
    
    function changOwnerAddress(address _ownerAddress) external onlyOwner {
        emit eventChangeOwnerAddress(OWNER_ADDRESS, _ownerAddress);
        OWNER_ADDRESS = _ownerAddress;
    }

    function tokenTransfer(uint256 _amount) internal {
        require(TOKEN_CONTRACT_ADDRESS.transfer(msg.sender, _amount));
        emit eventFundTransfer(msg.sender, _amount);
    }
}