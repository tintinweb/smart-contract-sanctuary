//SourceUnit: WTRX.sol

pragma solidity ^0.4.24;


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


contract ITokenDeposit is TRC20 {
    function deposit() public payable;
    function withdraw(uint) public;
}

contract WTRX is ITokenDeposit {
    string public name = "Wrapped TRX";
    string public symbol = "WTRX";
    uint8  public decimals = 6;

    event  Approval(address indexed src, address indexed guy, uint sad);
    event  Transfer(address indexed src, address indexed dst, uint sad);
    event  Deposit(address indexed dst, uint sad);
    event  Withdrawal(address indexed src, uint sad);

    uint256 private totalSupply_;
    mapping(address => uint)                       private  balanceOf_;
    mapping(address => mapping(address => uint))  private  allowance_;


    function() public payable {
        deposit();
    }

    function deposit() public payable {
        balanceOf_[msg.sender] += msg.value;
        totalSupply_ += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint sad) public {
        require(balanceOf_[msg.sender] >= sad, "not enough balance");
        require(totalSupply_ >= sad, "not enough totalSupply");
        balanceOf_[msg.sender] -= sad;
        msg.sender.transfer(sad);
        totalSupply_ -= sad;
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