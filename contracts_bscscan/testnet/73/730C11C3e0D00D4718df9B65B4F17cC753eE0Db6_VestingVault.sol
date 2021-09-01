/**
 *Submitted for verification at BscScan.com on 2021-09-01
*/

pragma solidity 0.5.4;

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    uint256 c = _a * _b;
    require(c / _a == _b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor () public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
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

/**
 * @title Contract that will hold vested tokens;
 * @notice Tokens for vested contributors will be hold in this contract and token holders
 * will claim their tokens according to their own vesting timelines.
 * Copyright 2021
 */
contract VestingVault is Ownable {
    using SafeMath for uint256;

    struct Grant {
        uint256 value;
        uint256 vestingStart;
        uint256 vestingCliff;
        uint256 vestingDuration;
        uint256[] scheduleTimes;
        uint256[] scheduleValues;
        uint256 level; // 1: frequency, 2: schedules
        uint256 transferred;
        uint256 grantedCount; // maximun count is 2
    }

    IERC20 public token;

    mapping(address => Grant) public grants;

    uint256 public totalVestedTokens;
    // array of vested users addresses
    address[] public vestedAddresses;
    bool public locked;

    event NewGrant(
        address _to,
        uint256 _amount,
        uint256 _start,
        uint256 _duration,
        uint256 _cliff,
        uint256[] _scheduleTimes,
        uint256[] _scheduleAmounts,
        uint256 _level
    );
    event AddGrant(
        address _to,
        uint256 _amount,
        uint256 _start,
        uint256 _duration,
        uint256 _cliff,
        uint256[] _scheduleTimes,
        uint256[] _scheduleAmounts,
        uint256 _level
    );
    event NewRelease(address _holder, uint256 _amount);
    event WithdrawAll(uint256 _amount);
    event LockedVault();

    modifier isOpen() {
        require(locked == false, "Vault is already locked");
        _;
    }

    constructor(address _token) public {
        require(
            address(_token) != address(0),
            "Token address should not be zero"
        );
        token = IERC20(_token);
        locked = false;
    }

    /**
     * @dev updateToken update base token
     * @notice this will be done by only owner any time
     */
    function updateToken(address _token) public onlyOwner {
        require(
            address(_token) != address(0),
            "Token address should not be zero"
        );
        token = IERC20(_token);
    }

    /**
     * @return address[] that represents vested addresses;
     */
    function returnVestedAddresses() public view returns (address[] memory) {
        return vestedAddresses;
    }

    /**
     * @return grant that represents vested info for specific user;
     */
    function returnGrantInfo(address _user)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256[] memory,
            uint256[] memory,
            uint256,
            uint256,
            uint256
        )
    {
        require(_user != address(0), "Address should not be zero");
        Grant storage grant = grants[_user];

        return (
            grant.value,
            grant.vestingStart,
            grant.vestingCliff,
            grant.vestingDuration,
            grant.scheduleTimes,
            grant.scheduleValues,
            grant.level,
            grant.transferred,
            grant.grantedCount
        );
    }

    /**
     * @dev Add vested contributor information
     * @param _to Withdraw address that tokens will be sent
     * @param _value Amount to hold during vesting period
     * @param _start Unix epoch time that vesting starts from
     * @param _duration Seconds amount of vesting duration
     * @param _cliff Seconds amount of vesting cliffHi
     * @param _scheduleTimes Array of Unix epoch times for vesting schedules
     * @param _scheduleValues Array of Amount for vesting schedules
     * @param _level Indicator that will represent types of vesting
     * @return Int value that represents granted token amount
     */
    function grant(
        address _to,
        uint256 _value,
        uint256 _start,
        uint256 _duration,
        uint256 _cliff,
        uint256[] memory _scheduleTimes,
        uint256[] memory _scheduleValues,
        uint256 _level
    ) public onlyOwner isOpen returns (uint256) {
        require(_to != address(0), "Address should not be zero");
        require(_level == 1 || _level == 2, "Invalid vesting level");
        // make sure a single address can be granted tokens only once.
        // require(grants[_to].value == 0, "Already added to vesting vault");
        // make sure a single address can be granted tokens only twice.
        // require(grants[_to].grantedCount < 2, "Already added to vesting vault");

        if (grants[_to].value == 0) {
            if (_level == 2) {
                require(
                    _scheduleTimes.length == _scheduleValues.length,
                    "Schedule Times and Values should be matched"
                );
                _value = 0;
                for (uint256 i = 0; i < _scheduleTimes.length; i++) {
                    require(
                        _scheduleTimes[i] > 0,
                        "Seconds Amount of ScheduleTime should be greater than zero"
                    );
                    require(
                        _scheduleValues[i] > 0,
                        "Amount of ScheduleValue should be greater than zero"
                    );
                    if (i > 0) {
                        require(
                            _scheduleTimes[i] > _scheduleTimes[i - 1],
                            "ScheduleTimes should be sorted by ASC"
                        );
                    }
                    _value = _value.add(_scheduleValues[i]);
                }
            }

            require(_value > 0, "Vested amount should be greater than zero");

            grants[_to] = Grant({
                value: _value,
                vestingStart: _start,
                vestingDuration: _duration,
                vestingCliff: _cliff,
                scheduleTimes: _scheduleTimes,
                scheduleValues: _scheduleValues,
                level: _level,
                transferred: 0,
                grantedCount: 1
            });

            vestedAddresses.push(_to);

            emit NewGrant(
                _to,
                _value,
                _start,
                _duration,
                _cliff,
                _scheduleTimes,
                _scheduleValues,
                _level
            );
        } else {
            require(
                grants[_to].level == _level,
                "The value of _level should be equal to the previous level."
            );

            if (grants[_to].level == 2) {
                // uint length = grants[_to].scheduleTimes.length;
                // require(_scheduleTimes[0] > grants[_to].scheduleTimes[length - 1], "Second starting time should be greater than the last schedule time.");
                require(
                    _scheduleTimes.length == _scheduleValues.length,
                    "Schedule Times and Values should be matched"
                );

                _value = 0;
                for (uint256 i = 0; i < _scheduleTimes.length; i++) {
                    // require(_scheduleTimes[i] > 0, "Seconds Amount of ScheduleTime should be greater than zero");
                    // require(_scheduleValues[i] > 0, "Amount of ScheduleValue should be greater than zero");

                    // if (i > 0) {
                    //     require(_scheduleTimes[i] > _scheduleTimes[i - 1], "ScheduleTimes should be sorted by ASC");
                    // }

                    grants[_to].scheduleTimes.push(_scheduleTimes[i]);
                    grants[_to].scheduleValues.push(_scheduleValues[i]);
                    _value = _value.add(_scheduleValues[i]);
                }
                sort(_to);
            }

            require(_value > 0, "Vested amount should be greater than zero");

            grants[_to].value = grants[_to].value + _value;
            grants[_to].vestingDuration =
                grants[_to].vestingDuration +
                _duration;
            grants[_to].vestingCliff = grants[_to].vestingCliff + _cliff;
            grants[_to].grantedCount = grants[_to].grantedCount + 1;

            emit AddGrant(
                _to,
                _value,
                _start,
                _duration,
                _cliff,
                _scheduleTimes,
                _scheduleValues,
                _level
            );
        }

        return _value;
    }

    /**
     * @dev Get token amount for a token holder available to transfer at specific time
     * @param _holder Address that represents holder's withdraw address
     * @param _time Unix epoch time at the moment
     * @return Int value that represents token amount that is available to release at the moment
     */
    function transferableTokens(address _holder, uint256 _time)
        public
        view
        returns (uint256)
    {
        Grant storage grantInfo = grants[_holder];

        if (grantInfo.value == 0) {
            return 0;
        }
        return calculateTransferableTokens(grantInfo, _time);
    }

    /**
     * @dev Internal function to calculate available amount at specific time
     * @param _grant Grant that represents holder's vesting info
     * @param _time Unix epoch time at the moment
     * @return Int value that represents available vested token amount
     */
    function calculateTransferableTokens(Grant memory _grant, uint256 _time)
        private
        pure
        returns (uint256)
    {
        uint256 totalVestedAmount = _grant.value;
        uint256 totalAvailableVestedAmount = 0;

        if (_grant.level == 1) {
            if (_time < _grant.vestingCliff.add(_grant.vestingStart)) {
                return 0;
            } else if (
                _time >= _grant.vestingStart.add(_grant.vestingDuration)
            ) {
                return _grant.value;
            } else {
                totalAvailableVestedAmount = totalVestedAmount
                    .mul(_time.sub(_grant.vestingStart))
                    .div(_grant.vestingDuration);
            }
        } else {
            if (_time < _grant.scheduleTimes[0]) {
                return 0;
            } else {
                for (uint256 i = 0; i < _grant.scheduleTimes.length; i++) {
                    if (_grant.scheduleTimes[i] <= _time) {
                        totalAvailableVestedAmount = totalAvailableVestedAmount
                            .add(_grant.scheduleValues[i]);
                    } else {
                        break;
                    }
                }
            }
        }

        return totalAvailableVestedAmount;
    }

    /**
     * @dev Claim vested token
     * @param _beneficiary address that should get the available token
     * @notice this will be eligible after vesting start + cliff or schedule times
     */
    function claim(address _beneficiary) public {
        address beneficiary = _beneficiary;
        Grant storage grantInfo = grants[beneficiary];
        require(grantInfo.value > 0, "Grant does not exist");

        uint256 vested = calculateTransferableTokens(grantInfo, now);
        require(vested > 0, "There is no vested tokens");

        uint256 transferable = vested.sub(grantInfo.transferred);
        require(
            transferable > 0,
            "There is no remaining balance for this address"
        );
        require(
            token.balanceOf(address(this)) >= transferable,
            "Contract Balance is insufficient"
        );

        grantInfo.transferred = grantInfo.transferred.add(transferable);
        grantInfo.value = grantInfo.value.sub(transferable);

        token.transfer(beneficiary, transferable);
        emit NewRelease(beneficiary, transferable);
    }

    /**
     * @dev Claim vested token
     * @notice this will be eligible after vesting start + cliff or schedule times
     */
    function claim() public {
        address beneficiary = msg.sender;
        Grant storage grantInfo = grants[beneficiary];
        require(grantInfo.value > 0, "Grant does not exist");

        uint256 vested = calculateTransferableTokens(grantInfo, now);
        require(vested > 0, "There is no vested tokens");

        uint256 transferable = vested.sub(grantInfo.transferred);
        require(
            transferable > 0,
            "There is no remaining balance for this address"
        );
        require(
            token.balanceOf(address(this)) >= transferable,
            "Contract Balance is insufficient"
        );

        grantInfo.transferred = grantInfo.transferred.add(transferable);
        grantInfo.value = grantInfo.value.sub(transferable);

        token.transfer(beneficiary, transferable);
        emit NewRelease(beneficiary, transferable);
    }

    /**
     * @dev Claim all vested tokens for all users by an owner
     * @notice this will be eligible after vesting start + cliff or schedule times
     */
    function claimAllByOwner(address[] memory _vestedAddresses)
        public
        onlyOwner
    {
        require(_vestedAddresses.length > 0, "Empty vested addresses");

        uint256 totalTransferable = 0;

        for (uint256 i = 0; i < _vestedAddresses.length; i++) {
            Grant storage grantInfo = grants[_vestedAddresses[i]];
            require(grantInfo.value > 0, "Grant does not exist");

            uint256 vested = calculateTransferableTokens(grantInfo, now);
            require(vested > 0, "There is no vested tokens");

            uint256 transferable = vested.sub(grantInfo.transferred);
            require(
                transferable > 0,
                "There is no remaining balance for this address"
            );
        }

        require(
            token.balanceOf(address(this)) >= totalTransferable,
            "Contract Balance is insufficient"
        );

        for (uint256 i = 0; i < _vestedAddresses.length; i++) {
            Grant storage grantInfo = grants[_vestedAddresses[i]];
            require(grantInfo.value > 0, "Grant does not exist");

            uint256 vested = calculateTransferableTokens(grantInfo, now);
            require(vested > 0, "There is no vested tokens");

            uint256 transferable = vested.sub(grantInfo.transferred);
            require(
                transferable > 0,
                "There is no remaining balance for this address"
            );

            grantInfo.transferred = grantInfo.transferred.add(transferable);
            grantInfo.value = grantInfo.value.sub(transferable);

            token.transfer(_vestedAddresses[i], transferable);
            emit NewRelease(_vestedAddresses[i], transferable);
        }
    }

    /**
     * @dev Function to withdraw remaining tokens;
     */
    function withdraw() public onlyOwner {
        // finally withdraw all remaining tokens to owner
        uint256 amount = token.balanceOf(address(this));
        token.transfer(owner, amount);

        emit WithdrawAll(amount);
    }

    /**
     * @dev Function to lock vault not to be able to alloc more
     */
    function lockVault() public onlyOwner {
        // finally lock vault
        require(!locked);
        locked = true;
        emit LockedVault();
    }

    function sort(address user) private {
        quickSort(
            grants[user].scheduleTimes,
            int256(0),
            int256(grants[user].scheduleTimes.length - 1),
            grants[user].scheduleValues
        );
    }

    function quickSort(
        uint256[] storage arr,
        int256 left,
        int256 right,
        uint256[] storage arrVal
    ) private {
        int256 i = left;
        int256 j = right;
        if (i == j) return;
        uint256 pivot = arr[uint256(left + (right - left) / 2)];
        while (i <= j) {
            while (arr[uint256(i)] < pivot) i++;
            while (pivot < arr[uint256(j)]) j--;
            if (i <= j) {
                (arr[uint256(i)], arr[uint256(j)]) = (
                    arr[uint256(j)],
                    arr[uint256(i)]
                );
                (arrVal[uint256(i)], arrVal[uint256(j)]) = (
                    arrVal[uint256(j)],
                    arrVal[uint256(i)]
                );
                i++;
                j--;
            }
        }
        if (left < j) quickSort(arr, left, j, arrVal);
        if (i < right) quickSort(arr, i, right, arrVal);
    }
}