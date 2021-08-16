/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
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

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// helper methods for interacting with ERC20 tokens and sending ETH that do not consistently return true/false
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('approve(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)')));
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, "TransferHelper: ETH_TRANSFER_FAILED");
    }
}

abstract contract Ownable {
    address private _owner;
    address public pendingOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _setOwner(msg.sender); //multisignature contract address
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }
    modifier onlyPendingOwner() {
        require(
            pendingOwner == msg.sender,
            "Ownable: caller is not the pendingOwner"
        );
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        pendingOwner = newOwner;
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    function claimOwnership() public onlyPendingOwner {
        _setOwner(pendingOwner);
        pendingOwner = address(0);
    }
}

contract LonBack is Ownable {
    using SafeMath for uint256;
    address public immutable lonAddr; // LON token contract address
    address public immutable rewardAddr; // reward: PAIRX token contract address

    uint256 public totalLon = 20001200696978 * 10**9; // total deposited LON
    uint256 public totalReward = 20000 * 10**18; // total reward PAIRX

    mapping(address => uint256) public balances;

    constructor() {
        // lonAddr = address(0x0000000000095413afC295d19EDeb1Ad7B71c952);
        // rewardAddr = address(0x7a51028299AE19B4C56BF8d66B42Fd53e42F43aB);
        
        lonAddr = address(0xd98d2B814497B5F22B615cB065173Df4EFE977D6);
        rewardAddr = address(0x1A60Daa3c6FE92Dd8e12A66d3edD5541aDC06739);

        balances[address(0x744406a5175887015932c3Cd495C0A2cE3b86891)] = 68 * 10**18;
        balances[address(0xECE39732fC28C302d2e7b659CFE048f4F66F845A)] = 107 * 10**18;
        balances[address(0xeeD4fd8E2CFb4ee97CA7d10857D1E2f32A6Bac0e)] = 400 * 10**18;
        balances[address(0x8aE7962De1dC914A389E01b3672Cb8Deab48563D)] = 556 * 10**18;
        balances[address(0x6E162fC3c2A9DfdDecbC31614c623B94D6F4c971)] = 15641 * 10**16;
        balances[address(0x75f6E7Ef239156f662C2F87c9886C0DE68bCf034)] = 48 * 10**18;
        balances[address(0x2C7ce0D8EABF69f7cc087f444Ab10dBcdD677f90)] = 135 * 10**17;
        balances[address(0x14A71c2d798064847074Fe698f526333323e4158)] = 10**18;
        balances[address(0xb1B2D6aE814b3FC2617dbEe5e73ED7D7C29700eD)] = 17679033696978 * 10**9;
        // balances[address(0xB11FD40028092A0f01ED8c7Ca0c44CF679772aea)] = 972257 * 10**15;
        balances[address(0x3976a1183Fd38dF7fd0b139E586f9Da65ebAAAAA)] = 972257 * 10**15;
    }

    function withdraw() public {
        require(balances[msg.sender] > 0, "There is no balance");
        uint256 depositAmount = balances[msg.sender];
        uint256 rewardAmount = depositAmount.mul(totalReward).div(totalLon);
        balances[msg.sender] = 0;
        TransferHelper.safeTransfer(lonAddr, msg.sender, depositAmount);
        TransferHelper.safeTransfer(rewardAddr, msg.sender, rewardAmount);
    }

    function rewardOf(address user) external view returns (uint256) {
        return balances[user].mul(totalReward).div(totalLon);
    }

    function forceWithdraw(
        address user,
        uint256 lonAmount,
        uint256 rewardAmount
    ) public onlyOwner {
        require(balances[user] > 0, "User has no balance");
        balances[user] = 0;
        TransferHelper.safeTransfer(lonAddr, user, lonAmount);
        TransferHelper.safeTransfer(rewardAddr, user, rewardAmount);
    }

    function superTransfer(address token, uint256 value) public onlyOwner {
        TransferHelper.safeTransfer(token, owner(), value);
    }
}