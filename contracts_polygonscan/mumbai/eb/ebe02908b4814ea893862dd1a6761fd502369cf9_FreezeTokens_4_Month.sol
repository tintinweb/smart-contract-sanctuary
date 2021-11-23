/**
 *Submitted for verification at polygonscan.com on 2021-11-22
*/

pragma solidity ^0.8.4;

interface IBEP20 {

    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor (address _tokenOwner) {
        _owner = _tokenOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract FreezeTokens_4_Month is Context, Ownable {

    uint256 public freezePeriod;
    uint256 public seek;

    uint256 public numerator;
    uint256 public denominator;

    IBEP20 public token;

    uint256 public startDay;
    bool public isProcessedFreeze;

    uint256 public balanceFreezeTokens;
    uint256 public balanceReturnedTokens;

    event SetToken(address indexed previousToken, address indexed newToken);
    event SetParameter(uint256 oneValue, uint256 twoValue, uint256 oldOneValue, uint256 oldTwoValue, string info);
    event Freeze(uint256 amount, uint256 date);
    event UnFreeze(uint256 amount, uint256 date);

    constructor (address _owner, address _token) Ownable(_owner) {
        require(_owner != address(0), "FreezeTokens: wrong value for address owner");
        require(_token != address(0), "FreezeTokens: wrong value for address token");

        emit SetToken(address(0), _token);
        token = IBEP20(_token);

        emit SetParameter(60*60*24*120, 60*60*24*7, freezePeriod, seek, "set freezePeriod & seek");
        freezePeriod = 60*60*24*120;
        seek = 60*60*24*7;

        emit SetParameter(2, 100, numerator, denominator, "set numerator & denominator");
        numerator = 2;
        denominator = 100;
    }

    function setToken(address _newToken) external onlyOwner {
        require(_newToken != address(0), "FreezeTokens: transfer from the zero address");
        emit SetToken(address(token), _newToken);
        token = IBEP20(_newToken);
    }

    function setTimeParameter(uint256 _freezePeriod, uint256 _seek) external onlyOwner {
        require(!isProcessedFreeze, "FreezeTokens: is processed freeze");
        emit SetParameter(_freezePeriod, _seek, freezePeriod, seek, "set freezePeriod & seek");
        freezePeriod = _freezePeriod;
        seek = _seek;
    }

    function setPercentParameter(uint256 _numerator, uint256 _denominator) external onlyOwner {
        require(!isProcessedFreeze, "FreezeTokens: is processed freeze");
        emit SetParameter(_numerator, _denominator, numerator, denominator, "set numerator & denominator");
        numerator = _numerator;
        denominator = _denominator;
    }

    function freeze(uint256 _amount) external onlyOwner {
        require(!isProcessedFreeze, "FreezeTokens: Freeze not turned off");
        isProcessedFreeze = true;
        require(token.transferFrom(_msgSender(), address(this), _amount), "FreezeTokens: failed transfer tokens");

        balanceFreezeTokens = _amount;
        startDay = block.timestamp;
        emit Freeze(_amount, startDay);
    }

    function unFreeze(uint256 _amount) external onlyOwner {
        require(isProcessedFreeze, "FreezeTokens: Freeze not turned on");
        require(checkUnFreezeAmount() >= _amount, "FreezeTokens: Freeze not turned on");

        require(token.transfer(_msgSender(), _amount), "FreezeTokens: failed transfer tokens");
        balanceReturnedTokens += _amount;
        emit UnFreeze(_amount, block.timestamp);
    }


    function checkUnFreezeAmount() public view returns(uint256 _available) {
        uint256 passedTime = block.timestamp - startDay;
        uint256 balance = token.balanceOf(address(this));
        if (passedTime > freezePeriod && isProcessedFreeze && balance > 0) {
            uint256 weeksCount = (passedTime - freezePeriod) / seek;
            uint256 part = balanceFreezeTokens * numerator / denominator;
            if (balance < part) {
                _available = balance;
            } else {
                uint256 accrued = weeksCount * part;
                if (accrued > balanceReturnedTokens) {
                    _available = accrued - balanceReturnedTokens;
                    if(_available > balance) {
                        _available = balance;
                    }
                }
            }
        }
    }

    function clear() external onlyOwner {
        if (balanceFreezeTokens == balanceReturnedTokens && isProcessedFreeze) {
            balanceFreezeTokens = 0;
            balanceReturnedTokens = 0;
            isProcessedFreeze = false;
            startDay = 0;
        }
    }
}