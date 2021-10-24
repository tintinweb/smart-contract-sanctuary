/**
 *Submitted for verification at Etherscan.io on 2021-10-23
*/

// File: contracts/openzeppelin/IERC20.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.1;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function decimals() external returns (uint8);

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

// File: contracts/openzeppelin/Ownable.sol





contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/Behodler1Migration/ScarcityBridge.sol







abstract contract SCX {
    function burn(uint256 value) external virtual;

    function migrateMint(address recipient, uint256 value) public virtual;
}

contract ScarcityBridge is Ownable {
    struct ScarcityTotals {
        uint256 total_v1;
        uint256 total_v2;
        uint256 blockRecorded;
        address scarcity1;
        address scarcity2;
    }
    uint256 public exchangeRate; //also represents the minimum old SCX required to get 1 unit of new SCX
    ScarcityTotals public totals;

    constructor(address scarcity1, address scarcity2) {
        totals.scarcity1 = scarcity1;
        totals.scarcity2 = scarcity2;
    }

    function collectScarcity2BeforeBurning() public onlyOwner {
        uint balanceOfSender = IERC20(totals.scarcity2).balanceOf(msg.sender);
        IERC20(totals.scarcity2).transferFrom(msg.sender,address(this), balanceOfSender);
        totals.total_v2 += balanceOfSender;
    }

    function recordExchangeRate() public onlyOwner {
        totals.total_v1 = IERC20(totals.scarcity1).totalSupply();
        exchangeRate = totals.total_v1 / totals.total_v2;
        totals.blockRecorded = block.number;
    }

    function swap() public {
        uint256 v1Balance = IERC20(totals.scarcity1).balanceOf(msg.sender);
        require(
            IERC20(totals.scarcity1).transferFrom(
                msg.sender,
                address(this),
                v1Balance
            ),
            "SCX BRIDGE: transfer failed."
        );
        uint256 newSCX = v1Balance / exchangeRate;
        require(newSCX > 0, "SCX BRIDGE: insufficient SCX sent.");
        uint256 thisBalance = IERC20(totals.scarcity1).balanceOf(address(this));
        require(thisBalance == v1Balance, "Invariant fail");
        SCX(totals.scarcity1).burn(v1Balance);
        IERC20(totals.scarcity2).transfer(msg.sender, newSCX);
    }
}