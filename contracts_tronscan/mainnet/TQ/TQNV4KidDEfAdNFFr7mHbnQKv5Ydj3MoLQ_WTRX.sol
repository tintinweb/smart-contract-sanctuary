//SourceUnit: Wtrx.sol

pragma solidity ^0.4.24;

library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }

        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}

pragma solidity >=0.4.25;

contract TRC20Events {
    event Approval(address indexed src, address indexed guy, uint wad);
    event Transfer(address indexed src, address indexed dst, uint wad);
}

contract TRC20 is TRC20Events {
    function totalSupply() public view returns (uint);
    function balanceOf(address guy) public view returns (uint);
    function allowance(address src, address guy) public view returns (uint);


    function approve(address guy, uint wad) public returns (bool);
    function transfer(address dst, uint wad) public returns (bool);
    function transferFrom(
        address src, address dst, uint wad
    ) public returns (bool);
}

pragma solidity ^0.4.24;

contract ITokenDeposit is TRC20 {
    function deposit(address,uint) public;
    function withdraw(uint) public;
}

pragma solidity ^0.4.24;


contract WTRX is ITokenDeposit {
    using SafeMath for uint256;

    string public name = "Wrapped USD";
    string public symbol = "TUSD";
    uint8  public decimals = 8;
    address public usdtContract;

    event  Approval(address indexed src, address indexed guy, uint sad);
    event  Transfer(address indexed src, address indexed dst, uint sad);
    event  Deposit(address indexed dst, uint sad);
    event  Withdrawal(address indexed src, uint sad);

    uint256 private totalSupply_;
    mapping(address => uint)                       private  balanceOf_;
    mapping(address => mapping(address => uint))  private  allowance_;

    constructor(address _usdtContract) public {
        usdtContract = _usdtContract;
    }

    function deposit(address usdt,uint sad) public {
        require(usdt == usdtContract, "not usdt contract address");
        require(TRC20(usdtContract).balanceOf(msg.sender)>=sad, "usdt balance is insufficient");

        balanceOf_[msg.sender] += sad;
        totalSupply_ += sad;

        TRC20(usdtContract).transferFrom(msg.sender,address(this),sad);

        emit Deposit(msg.sender, sad);
    }

    function withdraw(uint sad) public {
        require(balanceOf_[msg.sender] >= sad, "not enough balance");
        require(totalSupply_ >= sad, "not enough totalSupply");
        balanceOf_[msg.sender] -= sad;
        totalSupply_ -= sad;

        TRC20(usdtContract).transfer(msg.sender,sad);

        emit Withdrawal(msg.sender, sad);
    }

     function totalSupply() public view returns (uint) {
        return totalSupply_;
    }

    function balanceOf(address guy) public view returns (uint){
        return balanceOf_[guy];
    }

    function allowance(address src, address guy) public view returns (uint){
        return allowance_[src][guy];
    }

    function approve(address guy, uint sad) public returns (bool) {
        allowance_[msg.sender][guy] = sad;
        emit Approval(msg.sender, guy, sad);
        return true;
    }

    function approve(address guy) public returns (bool) {
        return approve(guy, uint(- 1));
    }

    function transfer(address dst, uint sad) public returns (bool) {
        return transferFrom(msg.sender, dst, sad);
    }

    function transferFrom(address src, address dst, uint sad)
    public
    returns (bool)
    {
        require(balanceOf_[src] >= sad, "src balance not enough");

        if (src != msg.sender && allowance_[src][msg.sender] != uint(- 1)) {
            require(allowance_[src][msg.sender] >= sad, "src allowance is not enough");
            allowance_[src][msg.sender] -= sad;
        }

        balanceOf_[src] -= sad;
        balanceOf_[dst] += sad;

        emit Transfer(src, dst, sad);

        return true;
    }
}