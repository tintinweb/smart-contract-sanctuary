/**
 *Submitted for verification at Etherscan.io on 2021-02-18
*/

pragma solidity ^0.5.16;

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint);

    function balanceOf(address account) external view returns (uint);

    function transfer(address recipient, uint amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint);

    function approve(address spender, uint amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

library SafeERC20 {
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(IERC20 token, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {// Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract APIRedeem {
    using Address for address;
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    address payable public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    modifier onlyOwner {
        require(msg.sender == owner, "OnlyOwner methods called by non-owner.");
        _;
    }
    function transferOwnership(address payable newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }


    function withdrawFunds(address payable beneficiary, uint withdrawAmount) public onlyOwner {
        require(withdrawAmount <= address(this).balance, "Withdraw amount larger than balance.");
        beneficiary.transfer(withdrawAmount);
    }

    function withdrawAPI(address payable beneficiary, uint withdrawAmount) public onlyOwner {
        API.safeTransfer(beneficiary, withdrawAmount);
    }

    function withdrawUSDT(address payable beneficiary, uint withdrawAmount) public onlyOwner {
        USDT.safeTransfer(beneficiary, withdrawAmount);
    }
    
    function() external payable {
        if (msg.sender == owner) {
        }
    }

    event Redeem(address indexed player, uint sentUSDT, uint getAPI);

    IERC20 public API = IERC20(0x97F302E3c6096b2dE1185315b4FfC1F7d57C960b);
    IERC20 public USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    mapping(address => uint) public redeemLimit;

    constructor () public {
        owner = msg.sender;
    }
    
    function setRedeemLimit(address _player, uint _limit) public onlyOwner {
        redeemLimit[_player] = _limit;
    }

    function redeem(address _referrer, uint _amount) public payable returns (bool) {
        require(_amount % 200e6 == 0, 'USDT value invalid');

        uint limit = redeemLimit[msg.sender].add(200e6);
        require(_amount <= limit, 'redeem value over limit');

        require(_referrer != msg.sender, "referrer is this address");
        require(_referrer != address(0), "referrer is the zero address");
        redeemLimit[_referrer] = redeemLimit[_referrer].add(200e6);


        uint sentUSDT = _amount;
        uint getAPI = sentUSDT.div(1e6).div(2).mul(1e18);
        USDT.safeTransferFrom(msg.sender, address(this), sentUSDT);
        API.safeTransfer(msg.sender, getAPI);
        emit Redeem(msg.sender, sentUSDT, getAPI);

        return true;
    }

}