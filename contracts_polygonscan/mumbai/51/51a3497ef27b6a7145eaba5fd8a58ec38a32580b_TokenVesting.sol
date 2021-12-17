/**
 *Submitted for verification at polygonscan.com on 2021-12-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

pragma solidity 0.8.9;

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

library SafeERC20 {
    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        require(token.transfer(to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        require(token.transferFrom(from, to, value));
    }
}

pragma solidity ^0.8.0;

contract TokenVesting is Ownable {
    using SafeERC20 for IERC20;

    uint256 public totalVestings;
    IERC20 public ERC20Interface;

    struct VestingDetails {
        address receiver;
        uint256 amount;
        uint256 release;
        bool expired;
    }

    constructor(address _tokenAddress) {
        require(_tokenAddress != address(0), "Zero token address");
        ERC20Interface = IERC20(_tokenAddress);
    }

    mapping(uint256 => VestingDetails) public vestingID;
    mapping(address => uint256[]) receiverIDs;

    function createVesting(
        address _receiver,
        uint256 _amount,
        uint256 _release
    ) internal onlyOwner _hasAllowance(msg.sender, _amount) returns (bool) {
        require(_receiver != address(0), "Zero receiver address");
        require(_amount > 0, "Zero amount");
        require(_release > block.timestamp, "Incorrect release time");

        totalVestings++;
        vestingID[totalVestings] = VestingDetails(
            _receiver,
            _amount,
            _release,
            false
        );
        receiverIDs[_receiver].push(totalVestings);
        ERC20Interface.safeTransferFrom(msg.sender, address(this), _amount);
        return true;
    }

    function claim(uint256 id) external returns (bool) {
        require(id > 0 && id <= totalVestings, "Id out of bounds");
        VestingDetails storage vestingDetail = vestingID[id];
        require(!vestingDetail.expired, "ID expired");
        require(
            block.timestamp >= vestingDetail.release,
            "Release time not reached"
        );
        vestingID[id].expired = true;
        ERC20Interface.safeTransfer(
            vestingDetail.receiver,
            vestingDetail.amount
        );
        return true;
    }

    function suspendLock(uint256 id) external onlyOwner returns (bool) {
        require(id > 0 && id <= totalVestings, "Id out of bounds");
        VestingDetails storage vestingDetail = vestingID[id];
        require(
            block.timestamp < vestingDetail.release,
            "Release time already reached"
        );
        vestingID[id].expired = true;
        ERC20Interface.safeTransfer(
            vestingDetail.receiver,
            vestingDetail.amount
        );
        return true;
    }

    function changeReleaseTime(uint256 id, uint256 timestamp)
        external
        onlyOwner
        returns (bool)
    {
        require(id > 0 && id <= totalVestings, "Id out of bounds");
        VestingDetails storage vestingDetail = vestingID[id];
        require(
            block.timestamp < vestingDetail.release,
            "Release time already reached"
        );
        require(
            block.timestamp < timestamp,
            "Selected time is less than current"
        );
        vestingID[id].release = timestamp;
        return true;
    }

    function createMultipleVesting(
        address[] memory _receivers,
        uint256[] memory _amounts,
        uint256[] memory _releases
    ) external returns (bool) {
        require(
            _receivers.length == _amounts.length &&
                _amounts.length == _releases.length,
            "Invalid data"
        );
        for (uint256 i = 0; i < _receivers.length; i++) {
            bool success = createVesting(
                _receivers[i],
                _amounts[i],
                _releases[i]
            );
            require(success, "Creation of vesting failed");
        }
        return true;
    }

    function getReceiverIDs(address user)
        external
        view
        returns (uint256[] memory)
    {
        return receiverIDs[user];
    }

    modifier _hasAllowance(address allower, uint256 amount) {
        // Make sure the allower has provided the right allowance.
        uint256 ourAllowance = ERC20Interface.allowance(allower, address(this));
        require(amount <= ourAllowance, "Make sure to add enough allowance");
        _;
    }
}