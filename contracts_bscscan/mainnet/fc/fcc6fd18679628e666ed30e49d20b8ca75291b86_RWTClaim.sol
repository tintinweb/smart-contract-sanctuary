/**
 *Submitted for verification at BscScan.com on 2021-09-12
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IBEP20 {
    function totalSupply() external view returns (uint256);
    function decimals() external view returns (uint8);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

library TransferHelper {
    function safeApprove(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x095ea7b3, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: APPROVE_FAILED');
    }

    function safeTransfer(address token, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
    }

    function safeTransferFrom(address token, address from, address to, uint value) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FROM_FAILED');
    }
    
    // sends BNB or an bep20 token
    function safeTransferBaseToken(address token, address payable to, uint value, bool isBNB) internal {
        if (isBNB) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(abi.encodeWithSelector(0xa9059cbb, to, value));
            require(success && (data.length == 0 || abi.decode(data, (bool))), 'TransferHelper: TRANSFER_FAILED');
        }
    }
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
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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

interface IWBNB {
    function deposit() external payable;
    function transfer(address to, uint value) external returns (bool);
    function withdraw(uint) external;
}


abstract contract ReentrancyGuard {
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor () {
        _status = _NOT_ENTERED;
    }

    modifier nonReentrant() {
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");
        _status = _ENTERED;
        _;
        _status = _NOT_ENTERED;
    }
}
contract RWTClaim is ReentrancyGuard {
    using SafeMath for uint256;
    address public creator;
    IBEP20 public tokenAddress;
    uint256 public totalclaimers;
    uint256 public tokensClaimed;
    uint256 public Tokendec;
    
    struct Claimer {
        bool claimed;  // if true, that person already voted
        uint totalClaimed;   // index of the voted proposal
    }
    
    mapping(address => Claimer) public claimers;
    
    constructor (IBEP20 token, uint256 tokenDec) {
        creator = msg.sender;
        tokenAddress = token;
        Tokendec = tokenDec;
    }
    
    function updateToken(IBEP20 newToken, uint256 tokenDecimal) public {
        tokenAddress = newToken;
        Tokendec = tokenDecimal;
    }
    
    function Claim (uint256 claimAmount) public {
        Claimer storage theClaimer = claimers[msg.sender];
        uint256 balance = tokenAddress.balanceOf(address(this));
        require(claimAmount > 0, 'YOU DO NOT HAVE ENOUGH TOKENS TO CLAIM');
        require(balance > claimAmount, 'INSUFFICIENT TOKENS TO CLAIM. AWAITING REFILL');
        require(theClaimer.claimed == false, 'YOU HAVE ALREADY CLAIMED YOUR TOKENS, YOU CANNOT CLAIM TWICE');
        uint256 claimable = claimAmount.mul(Tokendec);
        TransferHelper.safeTransfer(address(tokenAddress), msg.sender, claimable);
        theClaimer.totalClaimed += claimAmount;
        theClaimer.claimed = true;
        
    }
    
    function RemoveTokens(IBEP20 addToken, address collector) public {
        require (msg.sender == creator);
        uint256 remTokens = addToken.balanceOf(address(this));
        TransferHelper.safeTransfer(address(tokenAddress), collector, remTokens);
    }
}