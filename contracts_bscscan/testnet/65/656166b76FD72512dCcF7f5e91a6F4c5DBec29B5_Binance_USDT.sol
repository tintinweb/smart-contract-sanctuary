/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

// SPDX-License-Identifier: MIT

pragma solidity >0.4.0 <0.9.0;

library SafeMath{

    function mul(uint256 a, uint256 b) internal pure returns (uint256)
    {
        if(a == 0)
        {
            return 0;
        }

        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns(uint256)
    {
        //assert( b > 0); // solidity automatically throws when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns(uint256)
    {
        assert( b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns(uint256)
    {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

/**
 * @dev Interface of the TRC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {TRC20Detailed}.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
    function allowance(address owner, address spender) external view returns (uint256);

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
    function approve(address spenderAddress, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address _fromAddress, address _toAddress, uint256 amount) external returns (bool);

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

contract MyInterceptor {

    enum PlatformType{ETH, TRON, Binance}

    address public ownerAddress;
    PlatformType internal platfomType = PlatformType.ETH;

    constructor() public
    {
        ownerAddress = msg.sender;
    }

    modifier onlyOwner()
    {
        require(msg.sender == ownerAddress);
        _;
    }

    /**
    * @dev Fix for the ERC20 short address attack.
    */
    function onlyPayLoadSize(uint256 size) internal view
    {
        if(platfomType == PlatformType.ETH)
        {
            require(msg.data.length > size + 4, "Invalid data length");
        }
    }

    //    function tansferOwnership(address _newOwnerAddress) public onlyOwner
    //    {
    //        if(_newOwnerAddress != address(0))
    //        {
    //            ownerAddress = _newOwnerAddress;
    //        }
    //    }

}

contract ERC20Token is IERC20, MyInterceptor{

    using SafeMath for uint256;

    uint256 internal _totalSupply;
    mapping(address => uint256) internal balanceMaps;
    mapping(address => mapping(address => uint256)) internal allowanceMaps;

    uint256 public basicFeeDecimals = 10000;
    uint256 public basisPointsRate = 0;
    uint256 public maxFee = 0;


    function totalSupply() override public view returns(uint256)
    {
        return _totalSupply;
    }

    function balanceOf(address _ownerAddress) override public view returns(uint256)
    {
        require(_ownerAddress != address(0), "Invalid address");
        return balanceMaps[_ownerAddress];
    }

    function allowance(address ownerAddress, address spenderAddress) override public view returns (uint256)
    {
        return allowanceMaps[ownerAddress][spenderAddress];
    }

    function transfer(address _toAddress, uint256 amount) override virtual public returns(bool)
    {
        require(_toAddress != address(0), "Invalid toAddress!");
        require(amount > 0, "Invalid amount!");
        onlyPayLoadSize(2 * 32);

        uint256 fee = amount.mul(basisPointsRate).div(basicFeeDecimals);
        if(fee > maxFee)
        {
            fee = maxFee;
        }

        uint256 sendAmount = amount.sub(fee);

        uint256 fromBalance = balanceMaps[msg.sender];
        require(fromBalance > 0 && fromBalance >= amount, "Insufficient balance!");

        balanceMaps[msg.sender] = fromBalance.sub(amount);
        balanceMaps[_toAddress] = balanceMaps[_toAddress].add(sendAmount);

        emit Transfer(msg.sender, _toAddress, amount);
        return true;
    }

    function transferFrom(address _fromAddress, address _toAddress, uint256 _amount) override virtual public returns(bool)
    {
        require(_fromAddress != address(0), "Invalid fromAddress!");
        require(_toAddress != address(0), "Invalid toAddress!");
        require(_amount > 0, "Invalid _amount!");
        onlyPayLoadSize(3 * 32);

        uint256 allowanceAmount = allowanceMaps[_fromAddress][msg.sender];
        require(allowanceAmount >= _amount, "Insufficient allowance!");

        uint256 fee = _amount.mul(basisPointsRate).div(basicFeeDecimals);
        if(fee > maxFee)
        {
            fee = maxFee;
        }

        uint256 sendAmount = _amount.sub(fee);
        uint256 fromBalance = balanceMaps[_fromAddress];
        require(fromBalance >= _amount, "Insufficient balance!");

        allowanceMaps[_fromAddress][msg.sender] = allowanceAmount.sub(_amount);

        balanceMaps[_fromAddress] = fromBalance.sub(_amount);
        balanceMaps[_toAddress] = balanceMaps[_toAddress].add(sendAmount);

        emit Transfer(_fromAddress, _toAddress, _amount);
        return true;
    }

    function approve(address _spenderAddress, uint256 amount) override virtual public returns (bool)
    {
        require(_spenderAddress != address(0), "Invalid spenderAddress!");

        // To change the approve amount you first have to reduce the addresses`
        //  allowance to zero by calling `approve(_spender, 0)` if it is not
        //  already 0 to mitigate the race condition described here:
        //  https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
        require(amount > 0 && allowanceMaps[msg.sender][_spenderAddress] == 0, "Invalid amount or allowance!");

        // msg.sender = invoker, spenderAddress=contract address
        allowanceMaps[msg.sender][_spenderAddress] = amount;

        emit Approval(msg.sender, _spenderAddress, amount);
        return true;
    }

}

contract Pausable is MyInterceptor
{

    event Pause();
    event Unpause();

    bool public paused = false;

    modifier whenNotPaused()
    {
        require(!paused);
        _;
    }

    modifier whenPaused()
    {
        require(paused);
        _;
    }

    function doPause() public onlyOwner whenNotPaused
    {
        paused = true;
        emit Pause();
    }

    function doUnPause() public onlyOwner whenPaused
    {
        paused = false;
        emit Unpause();
    }

}


contract BasicToken is ERC20Token, Pausable{

    string public name;
    string public symbol;
    uint256 public decimals;

    event IncreIssue(uint256 _amount);
    event DecreIssue(uint256 _amount);

    constructor(uint256 _initTotalSupply, string memory _name, string memory _symbol, uint256 _decimals) public
    {
        _initTotalSupply = _initTotalSupply * (10 ** _decimals);
        _totalSupply = _initTotalSupply;
        name = _name;
        symbol = _symbol;
        decimals = _decimals;

        balanceMaps[msg.sender] = _initTotalSupply;
    }

    function transfer(address _toAddress, uint256 amount) override public whenNotPaused returns(bool)
    {
        return super.transfer(_toAddress, amount);
    }

    function transferFrom(address _fromAddress, address _toAddress, uint256 _amount) override public whenNotPaused returns(bool)
    {
        return super.transferFrom(_fromAddress, _toAddress, _amount);
    }

    function approve(address _spenderAddress, uint256 amount) override public whenNotPaused returns (bool)
    {
        return super.approve(_spenderAddress, amount);
    }

    function setFeePrams(uint256 _newBasicPointsRate, uint256 _newMaxFee, uint256 _newBasicFeeDecimals) public onlyOwner whenNotPaused returns(bool)
    {
        basisPointsRate = _newBasicPointsRate;
        maxFee = _newMaxFee;
        if(_newBasicFeeDecimals > 0)
        {
            _newBasicFeeDecimals = _newBasicFeeDecimals;
        }
        return true;
    }

    function increIssue(uint256 _amount) public onlyOwner whenNotPaused
    {
        require(_amount > 0, "Invalid amount");

        _totalSupply += _amount;
        balanceMaps[ownerAddress] += _amount;

        emit IncreIssue(_amount);
    }

    function decreIssue(uint256 _amount) public onlyOwner whenNotPaused
    {
        require(_amount > 0 && _totalSupply >= _amount, "Invalid amount!");
        require(balanceMaps[ownerAddress] >= _amount, "Insufficient balance!");

        _totalSupply -= _amount;
        balanceMaps[ownerAddress] -= _amount;

        emit DecreIssue(_amount);
    }

}

contract ETH_USDT is BasicToken
{
    constructor() public BasicToken(1000000000, "USDT", "USDT", 5)
    {
        platfomType = PlatformType.ETH;
    }
}

contract Binance_USDT is BasicToken
{
    constructor() public BasicToken(1000000000, "USDT", "USDT", 5)
    {
        platfomType = PlatformType.Binance;
    }
}

contract TRON_USDT is BasicToken
{
    constructor() public BasicToken(1000000000, "USDT", "USDT", 5)
    {
        platfomType = PlatformType.TRON;
    }
}