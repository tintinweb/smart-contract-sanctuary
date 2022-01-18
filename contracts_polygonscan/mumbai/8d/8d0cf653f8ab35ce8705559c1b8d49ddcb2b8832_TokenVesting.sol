/**
 *Submitted for verification at polygonscan.com on 2022-01-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

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

contract TokenVesting {
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




    /**
    * @param _receiver Address of the receiver of the vesting
    * @param _amount Amount of tokens to be locked up for vesting
    * @param _release Timestamp of the release time
    * @return _success Boolean value true if flow is successful
    * Creates a new vesting
    */
    function createVesting(
        address _receiver,
        uint256 _amount,
        uint256 _release
    ) public _hasAllowance(msg.sender, _amount) returns (bool _success) {
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
        // Adds the vesting id corresponding to the receiver
        receiverIDs[_receiver].push(totalVestings);
        ERC20Interface.safeTransferFrom(msg.sender, address(this), _amount);
        return true;
    }

    /**
    * @param _receivers Arrays of address of receiver of vesting amount
    * @param _amounts Array of amounts corresponding to each vesting
    * @param _releases Array of release timestamps corresponding to each vesting
    * @return _success Boolean value true if flow is successful
    * Creates multiple vesting, calls createVesting for each corresponding entry in {_receivers} {_amounts} {_releases}
    */
    function createMultipleVesting(
        address[] memory _receivers,
        uint256[] memory _amounts,
        uint256[] memory _releases
    ) external returns (bool _success) {
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
    

    /**
    * @param id Id of the vesting
    * @return Boolean value true if flow is successful
    * Returns the release timestamp of the the vesting
    */
    function getReleaseTime(uint256 id) public view returns(uint256){
        require(id > 0 && id <= totalVestings, "Id out of bounds");
        VestingDetails storage vestingDetail = vestingID[id];
        require(!vestingDetail.expired, "ID expired");
        return vestingDetail.release;
    }


    /**
    * @param id Id of the vesting
    * @return _success Boolean value true if flow is successful
    * The receiver of the vesting can claim their vesting if the vesting ID corresponds to their address 
    * and hasn't expired
    */
    function claim(uint256 id) external returns (bool _success) {
        require(id > 0 && id <= totalVestings, "Id out of bounds");
        VestingDetails storage vestingDetail = vestingID[id];
        require(msg.sender == vestingDetail.receiver, "Caller is not the receiver");
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


    /**
    * @param user Address of receiver of vesting amount
    * @return Array of IDs corresponding to vesting assigned to the user
    * Returns the IDs of the vestings , the user corresponds to
    */
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