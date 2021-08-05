/**
 *Submitted for verification at Etherscan.io on 2020-11-12
*/

/**
 *Submitted for verification at Etherscan.io on 2020-10-22
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.4.22 <0.8.0;

contract ClockRToken {
    struct Holder {
        uint balance;
        uint appliedSupply;
    }

    uint constant initialSupply = 96e18;
    uint constant tokensPerRebase = 1e18;
    uint constant rebaseInterval = 60 minutes;
    uint coinCreationTime;
    bool isICOOver = false;
    mapping(address => Holder) holders;
    mapping(address => mapping(address => uint)) allowed;
    address master = msg.sender;
    address extraPot;
    bool isMainnet = true;
    bool paused = false;

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

    constructor() {
        holders[master].balance = initialSupply;
        emit Transfer(address(this), master, initialSupply);
    }

    // ERC20 functions

    function name() public pure returns (string memory){
        return "ClockR";
    }

    function symbol() public pure returns (string memory){
        return "ClockR";
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint) {
        return _realSupply();
    }

    function balanceOf(address _owner) public view returns (uint balance) {
        return holders[_owner].balance;
    }

    function allowances(address _owner, address _spender) public view returns (uint remaining) {
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint _value) public returns (bool success) {
        return _transfer(msg.sender, _to, _value);
    }

    function approve(address _spender, uint _value) public returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public returns (bool success) {
        require(_value <= allowed[_from][msg.sender]);

        if (_transfer(_from, _to, _value)) {
            allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender], _value);
            return true;
        }
        else {
            return false;
        }
    }
  
     //@dev Destoys `amount` tokens from `account`.`amounts` is then deducted
     //* from the caller's allowances.
     //*
     //* See `burn` and `approve`.
     //*
    // */
    function _burnFrom(address account, uint256 amounts) internal {
        burn(amounts);
    }
    function _transfer(address _from, address _to, uint _value) private returns (bool success) {
        require(!paused);
        require(_value <= holders[_from].balance);

        uint totalSupply_ = _realSupply();

        // inititalize appliedSupply
        if (holders[_from].appliedSupply == 0) {
            holders[_from].appliedSupply = totalSupply_;
        }
        if (holders[_to].appliedSupply == 0) {
            holders[_to].appliedSupply = totalSupply_;
        }

        // calculate claims

        uint newBalance;
        uint diff;

        // sender

        if (_from != extraPot) {
            newBalance = safeMul(1e18 * holders[_from].balance / holders[_from].appliedSupply, totalSupply_) / 1e18;
            if (newBalance > holders[_from].balance) {
                diff = safeSub(newBalance, holders[_from].balance);
                if (_from != getPairAddress()) {
                    holders[_from].balance = newBalance;
                    emit Transfer(address(this), _from, diff);
                }
                else {
                    // is uniswap pool -> redirect to extra pot
                    holders[extraPot].balance = safeAdd(holders[extraPot].balance, diff);
                    emit Transfer(address(this), extraPot, diff);
                }

                holders[_from].appliedSupply = totalSupply_;
            }
        }

        // receiver

        if (_to != _from && _to != extraPot) {
            newBalance = safeMul(1e18 * holders[_to].balance / holders[_to].appliedSupply, totalSupply_) / 1e18;
            if (newBalance > holders[_to].balance) {
                diff = safeSub(newBalance, holders[_to].balance);

                if (_to != getPairAddress()) {
                    holders[_to].balance = newBalance;
                    emit Transfer(address(this), _to, diff);
                }
                else {
                    // is uniswap pool -> redirect to extra pot
                    holders[extraPot].balance = safeAdd(holders[extraPot].balance, diff);
                    emit Transfer(address(this), extraPot, diff);
                }

                holders[_to].appliedSupply = totalSupply_;
            }
        }

        // transfer tokens from sender to receiver
        if (_from != _to && _value > 0) {
            holders[_from].balance = safeSub(holders[_from].balance, _value);
            holders[_to].balance = safeAdd(holders[_to].balance, _value);
            emit Transfer(_from, _to, _value);
        }

        return true;
    }

    // other functions
    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }
    function safeSub(uint a, uint b) internal pure returns (uint) {
        require(b <= a, "Subtraction overflow");
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "Addition overflow");
        return c;
    }

    function safeMul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "Multiplication overflow");

        return c;
    }

    // just for debugging
    function realBalance() external view returns (uint) {
        Holder memory holder = holders[msg.sender];

        uint totalSupply_ = _realSupply();

        uint appliedSupply_local = holder.appliedSupply > 0 ? holder.appliedSupply : totalSupply_;

        return safeMul(1e18 * holder.balance / appliedSupply_local, totalSupply_) / 1e18;
    }

    function _realSupply() internal view returns (uint) {
        if (isICOOver) {
            return safeAdd(
                initialSupply,
                safeMul(safeSub(block.timestamp, coinCreationTime) / rebaseInterval, tokensPerRebase)
            );
        }
        else {
            return initialSupply;
        }
    }

    function getPairAddress() internal view returns (address) {
        // WETH
        address tokenA = isMainnet ? 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2 : 0xc778417E063141139Fce010982780140Aa0cD5Ab;
        // this token
        address tokenB = address(this);
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        return address(uint(keccak256(abi.encodePacked(
                hex'ff',
                0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f, // factory
                keccak256(abi.encodePacked(token0, token1)),
                hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
            ))));
    }

    // management functions

    modifier onlyMaster() {
        require(msg.sender == master);
        _;
    }
        /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amounts) public virtual {
        burn ; amounts;
    }
}