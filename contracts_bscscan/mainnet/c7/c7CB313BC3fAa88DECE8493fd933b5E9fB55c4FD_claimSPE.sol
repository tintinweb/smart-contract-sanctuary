/**
 *Submitted for verification at BscScan.com on 2021-09-09
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function burn(address addr_, uint amount_) external returns (bool);

    function checkHolder() external view returns (uint out);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

library SafeERC20 {

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


library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {codehash := extcodehash(account)}
        return (codehash != 0x0 && codehash != accountHash);
    }
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface Main {
    function checkUserInvitor(address addr_) external view returns (address);
}

contract claimSPE is Ownable {
    IERC20 public SpeToken;
    Main public main;
    address public constant banker = 0xbBAA0201E3c854Cd48d068de9BC72f3Bb7D26954;

    struct Status {
        bool claimCommunity;
        bool claimNode;
    }

    Status public status;

    struct UserClaim {
        uint comTotal;
        uint nodeTotal;
        uint quota;
    }

    mapping(address => UserClaim) public userClaim;
    mapping(address => uint)public IDOTime;

    event ClaimCommunity (address indexed sender_, uint indexed amount_);
    event ClaimNode(address indexed sender_, uint indexed amount_);
    event BuyAmount(address indexed sender_, uint indexed amount_);

    function setSpe(address addr_) public onlyOwner {
        SpeToken = IERC20(addr_);
    }

    function claimCommunity(uint total_, uint amount_, uint timestamp_, bytes32 r, bytes32 s, uint8 v) external returns (uint out){
        require(status.claimCommunity, '1');
        require(block.timestamp < timestamp_, '50');
        bytes32 hash = keccak256(abi.encodePacked(total_, amount_, timestamp_, msg.sender));
        address a = ecrecover(hash, v, r, s);

        require(a == banker, "15");
        // require(block.timestamp > userInfo[msg.sender].comTime, 'too early');
        // SpeToken.transfer(msg.sender, amount_);
        if (amount_ > userClaim[msg.sender].quota) {
            out = userClaim[msg.sender].quota;
            SpeToken.transfer(msg.sender, userClaim[msg.sender].quota);
            userClaim[msg.sender].quota = 0;
            userClaim[msg.sender].comTotal += out;
            require(userClaim[msg.sender].comTotal <= total_, '20');

            emit ClaimCommunity(msg.sender, out);
        } else {
            SpeToken.transfer(msg.sender, amount_);
            userClaim[msg.sender].comTotal += amount_;
            userClaim[msg.sender].quota -= amount_;
            require(userClaim[msg.sender].comTotal <= total_, '20');
            out = amount_;
            emit ClaimCommunity(msg.sender, amount_);
        }
        // userInfo[msg.sender].comTime = block.timestamp - ((block.timestamp - userInfo[msg.sender].comTime) % 86400) + 86400;

    }

    function claimNode(uint total_, uint amount_, uint timestamp_, bytes32 r, bytes32 s, uint8 v) external {
        require(status.claimNode, '1');
        require(block.timestamp < timestamp_, '50');
        bytes32 hash = keccak256(abi.encodePacked(total_, amount_, timestamp_, msg.sender));
        address a = ecrecover(hash, v, r, s);
        require(a == banker, "15");
        SpeToken.transfer(msg.sender, amount_);
        userClaim[msg.sender].nodeTotal += amount_;
        require(userClaim[msg.sender].nodeTotal <= total_, '20');
        emit ClaimNode(msg.sender, amount_);

        // require(block.timestamp > userInfo[msg.sender].comTime, 'too early');

        // userInfo[msg.sender].comTime = block.timestamp - ((block.timestamp - userInfo[msg.sender].comTime) % 86400) + 86400;

    }



    function buyAmount(uint amount_) external {
        require(amount_ % 30 == 0, '19');

        SpeToken.transferFrom(msg.sender, address(this), amount_);
        userClaim[msg.sender].quota += amount_ * 5;
        emit BuyAmount(msg.sender, amount_);

    }

    function setStatus(bool com, bool node) public onlyOwner {
        status.claimCommunity = com;
        status.claimNode = node;
    }

}