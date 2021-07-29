//SourceUnit: ITRC20.sol

pragma solidity ^0.5.8;

/**
 * @title TRC20 interface
 */
interface ITRC20 {
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

//SourceUnit: ITokenDeposit.sol

pragma solidity ^0.5.8;

import "./ITRC20.sol";

contract ITokenDeposit is ITRC20 {
    function deposit() public payable;
    function withdraw(uint256) public;
    event  Deposit(address indexed dst, uint256 sad);
    event  Withdrawal(address indexed src, uint256 sad);
}



//SourceUnit: WMRC.sol

pragma solidity ^0.5.8;

import "./ITokenDeposit.sol";

contract WMRC is ITokenDeposit {
    string public name = "Wrapped MeroeChain";
    string public symbol = "WMRC";
    uint8  public decimals = 0;
    trcToken  public mrcTokenId = trcToken(1003099);

    uint256 private totalSupply_;
    mapping(address => uint256) private  balanceOf_;
    mapping(address => mapping(address => uint)) private  allowance_;


    function() external payable {
        deposit();
    }

    function deposit() public payable {
        require(msg.tokenid == mrcTokenId, "deposit tokenId not MRC[1003099]");
        // tokenvalue is long value
        balanceOf_[msg.sender] += msg.tokenvalue;
        totalSupply_ += msg.tokenvalue;
        emit Transfer(address(0x00), msg.sender, msg.tokenvalue);
        emit Deposit(msg.sender, msg.tokenvalue);
    }

    function withdraw(uint256 sad) public {
        require(balanceOf_[msg.sender] >= sad, "not enough WMRC balance");
        require(totalSupply_ >= sad, "not enough WMRC totalSupply");
        balanceOf_[msg.sender] -= sad;
        totalSupply_ -= sad;
        msg.sender.transferToken(sad, mrcTokenId);

        emit Transfer(msg.sender, address(0x00), sad);
        emit Withdrawal(msg.sender, sad);
    }

    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function balanceOf(address guy) public view returns (uint256){
        return balanceOf_[guy];
    }

    function allowance(address src, address guy) public view returns (uint256){
        return allowance_[src][guy];
    }

    function approve(address guy, uint256 sad) public returns (bool) {
        allowance_[msg.sender][guy] = sad;
        emit Approval(msg.sender, guy, sad);
        return true;
    }

    function approve(address guy) public returns (bool) {
        return approve(guy, uint256(- 1));
    }

    function transfer(address dst, uint256 sad) public returns (bool) {
        return transferFrom(msg.sender, dst, sad);
    }

    function transferFrom(address src, address dst, uint256 sad)
    public returns (bool)
    {
        require(balanceOf_[src] >= sad, "src balance not enough");

        if (src != msg.sender && allowance_[src][msg.sender] != uint256(- 1)) {
            require(allowance_[src][msg.sender] >= sad, "src allowance is not enough");
            allowance_[src][msg.sender] -= sad;
        }
        balanceOf_[src] -= sad;
        balanceOf_[dst] += sad;

        emit Transfer(src, dst, sad);
        return true;
    }
}