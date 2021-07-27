/**
 *Submitted for verification at Etherscan.io on 2021-07-27
*/

// SPDX-License-Identifier: UNLICENSED

/*

 _   _   ___  __   _____________           _____  __  
| | | | / _ \ \ \ / /  _  | ___ \         |  _  |/  | 
| |_| |/ /_\ \ \ V /| | | | |_/ /   __   _| |/' |`| | 
|  _  ||  _  | /   \| | | |    /    \ \ / /  /| | | | 
| | | || | | |/ /^\ \ \_/ / |\ \     \ V /\ |_/ /_| |_
\_| |_/\_| |_/\/   \/\___/\_| \_|     \_/  \___(_)___/

Deflationary KuDOS token has a built in fee.
Dice Fee is 1%

+---------+--------+------------+
| Numbers | Chance | Multiplier |
+---------+--------+------------+
|       1 | 16.66% | x5.94      |
|       2 | 33.33% | x2.97      |
|       3 | 50%    | x1.98      |
|       4 | 66.66% | x1.47      |
|       5 | 83.33% | x1.18      |
+---------+--------+------------+

How it works in case of KuDOS Token deflationary model:

1. Player bet 1 KuDOS with 1 number and wins
2. Payout: x5.94 from the initial bet (1% fee = 0.06 KuDOS goes to Dice)
3. Contract transfer 5.94 KuDOS to the Player
4. Player receive 5.7618 KuDOS



*/


pragma solidity ^0.8.0;


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
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


interface KUToken {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    function increaseAllowance(address spender, uint256 addedValue) external returns (bool);

    function decreaseAllowance(address spender, uint256 subtractedValue) external returns (bool);

    function isExcluded(address account) external view returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

}

interface RNG {
    function random() external returns (uint8);
}

contract KUTDice is Ownable {
    using SafeMath for uint256;

    RNG public Random;
    KUToken public KUT;

    uint16[] payouts;

    uint256 minBet;
    uint256 maxBet;

    bool isStopped;
    uint8 lastNumber;


    event Winner(address _address, uint256 _bet_amount, uint256 _payout_amount, uint8[] userNumbers, uint8 winNumber);
    event TryAgain(address _address, uint256 _bet_amount, uint8[] userNumbers, uint8 winNumber);
    event Fund(uint256 amount);
    event Withdraw(uint256 amount);
    event Test(uint8[5] pNumbers, uint8[] numbers, uint __iterator);

    constructor(address _token, address _random) public {
        KUT = KUToken(_token);
        Random = RNG(_random);


        payouts = [0, 594, 297, 198, 148, 118];

        //Bet amounts are limited due the beta period
        //0.01 KUT
        minBet = 1000000;
        //0.3 KUT
        maxBet = 30000000;

        isStopped = false;
    }
    

    function roll(uint8[] memory _numbers, uint256 bet_amount) external {
        require(!isStopped, "Game is stopped, come back later");

        //  Allowance check
        uint256 allowance = KUT.allowance(msg.sender, address(this));
        require(allowance >= bet_amount, "Allowance is smaller than bet amount");


//  Standard checks
        require(_numbers.length > 0 && _numbers.length <= 5, "numbers count invalid");
        require(bet_amount >= minBet && bet_amount <= maxBet, "bet is out of range");

        //  Check numbers exist in range and unique
        uint8[5] memory _pNumbers;
        for (uint i = 0; i < _numbers.length; i++) {
            require(_numbers[i] > 0 && _numbers[i] <= 6, "number is out of range");
            require(!existsIn(_pNumbers, _numbers[i]), "numbers are not unique");
            _pNumbers[i] = _numbers[i];
        }


        //  Check amounts
        uint256 diceBalance = KUT.balanceOf(address(this));
        uint256 betMultiplier = payouts[_numbers.length];
        uint256 payout_amount = bet_amount.div(100).mul(betMultiplier).sub(bet_amount);
        require(diceBalance >= payout_amount, "Dice balance is smaller than possible payout");

        uint8 winningNumber = Random.random();
        lastNumber = winningNumber;

        //  As we pay 3% fee for every KUT tx we should run one tx instead of two (receive bet -> send profit + initial bet)
        //  That's why initial player bet doesn't transfers to the contract
        //  If player wins, he receives only profit in tokens (bet_amount * multiplier - bet_amount)
        //  If contract wins it transfers user bet to its balance

        if (existsIn(_pNumbers, winningNumber)) {
            KUT.transfer(msg.sender, payout_amount);
            emit Winner(msg.sender, bet_amount, payout_amount, _numbers, winningNumber);
        } else {
            KUT.transferFrom(msg.sender, address(this), bet_amount);
            emit TryAgain(msg.sender, bet_amount, _numbers, winningNumber);
        }

    }

    function existsIn(uint8[5] memory _arr, uint8 _val) internal returns (bool)  {
        require(_arr.length > 0, "existsIn: array is empty");
        require(_val > 0, "existsIn: value shouldn't be null");
        for (uint i = 0; i < _arr.length; i++) {
            if (_arr[i] == _val) {
                return true;
            }
        }
        return false;
    }

    //  Initial Funding by Owner
    function fundGameWithTokens(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount invalid");
        uint256 allowance = KUT.allowance(msg.sender, address(this));
        require(allowance >= amount, "Allowance is smaller then amount");
        KUT.transferFrom(msg.sender, address(this), amount);
        emit Fund(amount);
    }

    //  Emergency stop
    function stopGame(bool stop) external onlyOwner {
        isStopped = stop;
    }

    //  Withdraw initial balance from Dice
    function withdrawTokensFromGame(uint256 amount) external onlyOwner {
        require(amount > 0, "Amount invalid");
        require(amount <= KUT.balanceOf(address(this)), "Amount exceeds balance");
        KUT.transfer(msg.sender, amount);
        emit Withdraw(amount);
    }

    // Change randomness provider
    function updateRngProvider(address _contract) external onlyOwner {
        Random = RNG(_contract);
    }

    // Change max bet
    function updateMaxBet(uint256 _maxBet) external onlyOwner {
        maxBet = _maxBet;
    }

    function last() public view returns (uint8) {
        return lastNumber;
    }

    function _isStopped() public view returns (bool) {
        return isStopped;
    }

    function getTokenBalance(address _address) public view returns (uint256) {
        return KUT.balanceOf(_address);
    }
}