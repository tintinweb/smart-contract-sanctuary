/**
 *Submitted for verification at Etherscan.io on 2022-01-08
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
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
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

abstract contract Ownable{
    address private _owner;
    constructor() {
        _owner = msg.sender;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
}

contract ZhuanZhangZhuShou is Ownable {
    using SafeMath for uint256;

    function getSum(uint256[] memory arr) public returns(uint256){
        uint i;
        uint256 sum = 0;   
        for(i = 0; i < arr.length; i++){
            sum = sum + arr[i];
            }
        return sum;
    }

    function normal_ZhuanZhang(address _tokenIn, address[] calldata AimedWallet, uint256[] calldata amounts) external onlyOwner {   
        uint256 sum = getSum(amounts);
        require(IERC20(_tokenIn).balanceOf(msg.sender) >= sum , "Get some more money, dude");
        require(AimedWallet.length == amounts.length, "wallet and amount total number not match, dude");
        require(IERC20(_tokenIn).transferFrom(msg.sender, address(this), sum), "Unable to collect your money, maybe you forget approve first?");
        for(uint256 indx = 0; indx < AimedWallet.length; indx++) {
            require(IERC20(_tokenIn).transfer(AimedWallet[indx], amounts[indx]), "something wrong with transfer token to the account");
        }
    }

    function deposit_ETH() payable public {
    }

    function withdraw_ETH() external onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdraw_Token(address _tokenIn) external onlyOwner {
        IERC20(_tokenIn).transfer(msg.sender, IERC20(_tokenIn).balanceOf(address(this)));
    }

    function ETH_ZhuanZhang(address payable[] calldata AimedWallet, uint256[] calldata amounts) external payable onlyOwner {
        uint256 sum = getSum(amounts);
        require(AimedWallet.length == amounts.length, "wallet and amount total number not match, dude");
        for(uint256 indx = 0; indx < AimedWallet.length; indx++) {
            AimedWallet[indx].transfer(amounts[indx]);
        }

    }

    }