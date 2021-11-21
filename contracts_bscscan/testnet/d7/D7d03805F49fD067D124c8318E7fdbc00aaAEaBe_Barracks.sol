// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "./token/BEP20/IBEP20.sol";
import "./access/Ownable.sol";
import "./interfaces/IRugZombieNft.sol";

/**
 * @title Barracks
 * @author Saad Sarwar
 */

interface ICatacombs {
    function isUnlocked(address) external view returns (bool);
}

contract Barracks is Ownable {
    uint256 public totalBarracks = 0;
    // Treasury address
    address payable treasury;
    // Catacombs address
    ICatacombs catacombs;

    constructor (address payable _treasury, address _catacombs) {
        //        zombie = _zombie;
        treasury = _treasury;
        catacombs = ICatacombs(_catacombs);
    }

    struct TokenInfo {
        bool isListed;
        bool isEnabled;
    }

    mapping(address => TokenInfo) tokenInfo;

    address [] allowedTokens;

    struct Deposit {
        uint amount; // amount deposited by the user.
        bool claimed; // if the user has claimed the nft.
    }

    // Info of each barrack.
    struct Barrack {
        bool bnb;
        address token;
        uint feePercentage;                     // percentage of fee for barrack
        uint maximum;                           // maximum amount to deposit.
        uint lockAmount;                        // threshold amount to lock barrack.
        uint totalDeposited;                    // total deposited so far.
        uint lockTime;                          // lock time after unlockAmount/threshold is reached. in "SECONDS"
        uint timeLocked;                        // time when deposit reached threshold and barrack is locked.
        address nftAddress;                     // the nft barrack holds.
        mapping(address => Deposit) deposits;   // deposit details.
        address [] addresses;                   // addresses of the depositors.
        uint numDeposits;                       // total number of deposits.
        bool active;
        bool locked;
    }

    struct BarrackInfo {
        bool bnb;
        address token;
        uint feePercentage;                     // percentage of fee for barrack
        uint maximum;                           // maximum amount to deposit.
        uint lockAmount;                        // threshold amount to lock barrack.
        uint totalDeposited;                    // total deposited so far.
        uint lockTime;                          // lock time after unlockAmount/threshold is reached. in "SECONDS"
        uint timeLocked;                        // time when deposit reached threshold and barrack is locked.
        address nftAddress;                     // the nft barrack holds.
        bool locked;
    }

    function barrackInfo(uint _barrackId) public view returns (BarrackInfo memory) {
        return BarrackInfo(
            {
                bnb : barracks[_barrackId].bnb,
                token : barracks[_barrackId].token,
                feePercentage : barracks[_barrackId].feePercentage,
                maximum : barracks[_barrackId].maximum,
                lockAmount : barracks[_barrackId].lockAmount,
                totalDeposited : barracks[_barrackId].totalDeposited,
                lockTime : barracks[_barrackId].lockTime,
                timeLocked : barracks[_barrackId].timeLocked,
                nftAddress : barracks[_barrackId].nftAddress,
                locked : barracks[_barrackId].locked
            }
        );
    }

    mapping(uint => Barrack) public barracks;

    event Deposited(uint barrackId, uint amount);

    function addToken(address _tokenAddress) public onlyOwner() {
        require(!tokenInfo[_tokenAddress].isEnabled, "Token is already enabled.");
        allowedTokens.push(_tokenAddress);
        tokenInfo[_tokenAddress] = TokenInfo(
            {
                isEnabled : true,
                isListed : true
            }
        );
    }

    function removeToken(address _tokenAddress) public onlyOwner() {
        require(tokenInfo[_tokenAddress].isEnabled, "Token is already disabled.");
        require(tokenInfo[_tokenAddress].isListed, "Token is already not listed.");
        tokenInfo[_tokenAddress].isEnabled = false;
    }

    function tokenIsActive(address _tokenAddress) public view returns (bool) {
        return tokenInfo[_tokenAddress].isEnabled;
    }

    function createBarrack(
        bool _isBNB,
        address _token,
        uint _feePercentage,
        uint _maximum,
        uint _lockTime,
        address _nftAddress,
        uint _lockAmount
    ) public onlyOwner() {
        require(_feePercentage > 0 && _feePercentage < 100, "Incorrect fee percentage.");
        totalBarracks += 1;
        if (_isBNB) {
            barracks[totalBarracks].bnb = true;
        } else {
            require(tokenInfo[_token].isListed, "Token is not listed.");
            require(tokenInfo[_token].isEnabled, "Token is disabled.");
            barracks[totalBarracks].bnb = false;
            barracks[totalBarracks].token = _token;
        }
        barracks[totalBarracks].feePercentage = _feePercentage;
        barracks[totalBarracks].maximum = _maximum;
        barracks[totalBarracks].lockTime = _lockTime;
        barracks[totalBarracks].lockAmount = _lockAmount;
        barracks[totalBarracks].nftAddress = _nftAddress;
        barracks[totalBarracks].active = true;
        barracks[totalBarracks].locked = false;
    }

    function lockBarrack(uint _barrackId) internal returns (bool) {
        barracks[_barrackId].timeLocked = block.timestamp;
        barracks[_barrackId].locked = true;
        return true;
    }

    function isLocked(uint _barrackId) public view returns (bool) {
        return barracks[_barrackId].locked;
    }

    function checkDeposited(uint _barrackId) public view returns (uint) {
        return barracks[_barrackId].deposits[msg.sender].amount;
    }

    function checkRemainingAmount(uint _barrackId) public view returns (uint) {
        return barracks[_barrackId].lockAmount - barracks[_barrackId].totalDeposited;
    }

    function deposit(address _token, uint _barrackID, uint _amount) public payable {
        require(catacombs.isUnlocked(msg.sender), "Catacombs are not unlocked.");
        require(!barracks[_barrackID].locked, "Barrack is locked.");
        require(barracks[_barrackID].active, "Barrack is not active.");
        require(barracks[_barrackID].totalDeposited <= barracks[_barrackID].lockAmount, "Lock amount exceeded.");
        // if the asset to deposit is BNB
        if (barracks[_barrackID].bnb) {
            require(msg.value <= checkRemainingAmount(_barrackID), "Lock amount exceeded.");
            // checks for min/max deposit value
            require(msg.value > 0, "Not enough balance.");
            require(msg.value <= barracks[_barrackID].maximum || barracks[_barrackID].maximum == 0, "woooaaaahhhh, calm down dude. it's too much.");
            // check if the lock amount doesn't exceed.
            require(msg.value + barracks[_barrackID].totalDeposited <= barracks[_barrackID].lockAmount, "Lock amount exceeded.");
            // check if already deposited.
            if (barracks[_barrackID].deposits[msg.sender].amount > 0) {
                require(msg.value + barracks[_barrackID].deposits[msg.sender].amount <= barracks[_barrackID].maximum, "Max deposit amount reached.");
            }
            uint fee = (msg.value / 100) * barracks[_barrackID].feePercentage;
            treasury.transfer(fee);
            uint depositedAmount = msg.value - fee;
            // if new deposit then adding the address to addressess list
            if (barracks[_barrackID].deposits[msg.sender].amount == 0) {
                barracks[_barrackID].addresses.push(msg.sender);
            }
            barracks[_barrackID].totalDeposited += msg.value;
            // total deposited including fee.
            barracks[_barrackID].deposits[msg.sender].amount += depositedAmount;
            // deposited by user minus the fee.
            emit Deposited(msg.value, _barrackID);
        } else {
            require(tokenInfo[_token].isEnabled, "Token is disabled.");
            require(barracks[_barrackID].token == _token, "Invalid token for this barrack.");
            require(_amount <= checkRemainingAmount(_barrackID), "Lock amount exceeded.");
            require(IBEP20(_token).balanceOf(msg.sender) >= _amount, "Not enough balance");
            require(_amount > 0, "Not enough balance.");
            require(_amount <= barracks[_barrackID].maximum || barracks[_barrackID].maximum == 0, "woooaaaahhhh, calm down dude. it's too much.");
            require(_amount + barracks[_barrackID].totalDeposited <= barracks[_barrackID].lockAmount, "Lock amount exceeded.");
            // check if already deposited.
            if (barracks[_barrackID].deposits[msg.sender].amount > 0) {
                require(_amount + barracks[_barrackID].deposits[msg.sender].amount <= barracks[_barrackID].maximum, "Max deposit amount reached.");
            }
            uint fee = (_amount / 100) * barracks[_barrackID].feePercentage;
            toTreasury(_token, fee);
            IBEP20(_token).transferFrom(msg.sender, address(this), _amount - fee);
            uint depositedAmount = _amount - fee;
            // if new deposit then adding the address to addressess list
            if (barracks[_barrackID].deposits[msg.sender].amount == 0) {
                barracks[_barrackID].addresses.push(msg.sender);
            }
            barracks[_barrackID].totalDeposited += _amount;
            // total deposited including fee.
            barracks[_barrackID].deposits[msg.sender].amount += depositedAmount;
            // deposited by user minus the fee
            emit Deposited(_amount, _barrackID);
        }
        // locking the barrack if lock amount is reached.
        if (barracks[_barrackID].totalDeposited >= barracks[_barrackID].lockAmount) {
            lockBarrack(_barrackID);
        }
        barracks[_barrackID].numDeposits += 1;
    }

    // function to claim nft and locked amount once a barrack is locked.
    function claimNftAndRefundLockedAmount(uint _barrackID) public returns (uint) {
        require(barracks[_barrackID].locked, "Barrack is not locked");
        require(barracks[_barrackID].active, "Barrack is not active");
        require(barracks[_barrackID].deposits[msg.sender].amount > 0, "Not deposited yet.");
        require(barracks[_barrackID].deposits[msg.sender].claimed == false, "Already claimed.");
        // check lock time has passed.
        require(block.timestamp > barracks[_barrackID].timeLocked + barracks[_barrackID].lockTime, "Please claim after lock time is over.");
        if (barracks[_barrackID].bnb) {
            payable(msg.sender).transfer(barracks[_barrackID].deposits[msg.sender].amount);
        } else {
            require(IBEP20(barracks[_barrackID].token).transfer(msg.sender, barracks[_barrackID].deposits[msg.sender].amount), "Token transfer failed.");
        }
        barracks[_barrackID].deposits[msg.sender].claimed = true;
        IRugZombieNft nft = IRugZombieNft(barracks[_barrackID].nftAddress);
        uint newItemId = nft.reviveRug(msg.sender);
        // if all have claimed then setting the barrack as inactive.
        if (allClaimed(_barrackID)) {
            barracks[_barrackID].active = false;
        }
        return newItemId;
    }

    // no nft in case of early refunding. also used to reduce staked amount.
    function refundEarlier(uint _barrackID, uint _amount) public {
        require(!barracks[_barrackID].locked, "Barrack is locked");
        require(barracks[_barrackID].active, "Barrack is not active");
        require(barracks[_barrackID].deposits[msg.sender].amount > 0, "Not deposited yet.");
        require(barracks[_barrackID].deposits[msg.sender].amount <= _amount, "Amount more than deposited amount.");
        if (barracks[_barrackID].bnb) {
            payable(msg.sender).transfer(_amount);
        } else {
            IBEP20(barracks[_barrackID].token).transfer(msg.sender, _amount);
        }
        // subtracting the amount from total deposited.
        barracks[_barrackID].totalDeposited -= _amount;
        // resetting the deposited amount of user
        barracks[_barrackID].deposits[msg.sender].amount -= _amount;
    }

    function allClaimed(uint _barrackID) internal view returns (bool) {
        for (uint index = 0; index < barracks[_barrackID].numDeposits; index++) {
            if (!barracks[_barrackID].deposits[barracks[_barrackID].addresses[index]].claimed) {
                return false;
            }
        }
        return true;
    }

    function toTreasury(address _token, uint256 _amount) private {
        IBEP20(_token).transferFrom(msg.sender, treasury, _amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns ( bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

interface IBEP20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the bep token owner.
     */
    function getOwner() external view returns (address);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

interface IRugZombieNft {
    function totalSupply() external view returns (uint256);
    function reviveRug(address _to) external returns(uint);
    function transferOwnership(address newOwner) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external returns (bool);
    function transferFrom(address from, address to, uint256 tokenId) external;
    function ownerOf(uint256 tokenId) external view returns (address);
    function approve(address to, uint256 tokenId) external;
    function balanceOf(address owner) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor()  {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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