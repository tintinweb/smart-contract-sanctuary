//SourceUnit: token_get.sol

pragma solidity ^0.4.25;
import "./trc20.sol";

contract ITokenGet is TRC20 {
    function buy() public payable;
    function sell(uint) public;
}

//SourceUnit: tot.sol

pragma solidity ^0.4.25;

import "./token_get.sol";

contract TOT is ITokenGet {
    string public name = "TOT TOKEN";
    string public symbol = "TOT";
    uint8  public decimals = 6;
    uint deployer_fee_percent = 5;
    uint percent_divider = 100;
    address private deployer;

    event Approval(address indexed src, address indexed usr, uint tot);
    event Transfer(address indexed src, address indexed dst, uint tot);
    event Buy(address indexed dst, uint tot);
    event Sell(address indexed src, uint tot);

    uint256 private totalSupply_;
    mapping(address => uint)                      private balanceOf_;
    mapping(address => mapping(address => uint))  private allowance_;
    
    constructor() public {
        deployer = msg.sender;
    }

    function() public payable {
        buy();
    }

    function buy() public payable {
        balanceOf_[msg.sender] += msg.value;
        totalSupply_ += msg.value;
        pay_dep(msg.value);
        emit Buy(msg.sender, msg.value);
        emit Transfer(address(this), msg.sender, msg.value);
    }

    function sell(uint tot) public {
        require(balanceOf_[msg.sender] >= tot, "not enough balance");
        require(totalSupply_ >= tot, "not enough totalSupply");
        balanceOf_[msg.sender] -= tot;
        uint w_trx = tot * (100 - deployer_fee_percent) / percent_divider;
        msg.sender.transfer(w_trx);
        totalSupply_ -= tot;
        emit Sell(msg.sender, tot);
        emit Transfer(msg.sender, address(this), tot);
    }
    
    function pay_dep(uint tot) private {
        uint d_tot = tot * (deployer_fee_percent) / (100 - deployer_fee_percent);
        balanceOf_[deployer] += d_tot;
        totalSupply_ += d_tot;        
    }    

    function totalSupply() public view returns (uint) {
        return totalSupply_;
    }

    function balanceOf(address usr) public view returns (uint) {
        return balanceOf_[usr];
    }
    
    function balanceTRX(address usr) public view returns (uint) {
        return usr.balance;
    }    

    function allowance(address src, address usr) public view returns (uint) {
        return allowance_[src][usr];
    }

    function approve(address usr, uint tot) public returns (bool) {
        allowance_[msg.sender][usr] = tot;
        emit Approval(msg.sender, usr, tot);
        return true;
    }

    function approve(address usr) public returns (bool) {
        return approve(usr, uint(- 1));
    }

    function transfer(address dst, uint tot) public returns (bool) {
        return transferFrom(msg.sender, dst, tot);
    }

    function transferFrom(address src, address dst, uint tot) public returns (bool) {
        require(balanceOf_[src] >= tot, "src balance not enough");

        if (src != msg.sender && allowance_[src][msg.sender] != uint(- 1)) {
            require(allowance_[src][msg.sender] >= tot, "src allowance is not enough");
            allowance_[src][msg.sender] -= tot;
        }

        balanceOf_[src] -= tot;
        balanceOf_[dst] += tot;

        emit Transfer(src, dst, tot);

        return true;
    }
}



//SourceUnit: trc20.sol

/// TRC20.sol -- API for the TRC20 token standard
// See <https://github.com/tronprotocol/tips/blob/master/tip-20.md>.


pragma solidity >=0.4.25;

contract TRC20Events {
    event Approval(address indexed src, address indexed usr, uint tot);
    event Transfer(address indexed src, address indexed dst, uint tot);
}

contract TRC20 is TRC20Events {
    function totalSupply() public view returns (uint);
    function balanceOf(address usr) public view returns (uint);
    function allowance(address src, address usr) public view returns (uint);

    function approve(address usr, uint tot) public returns (bool);
    function transfer(address dst, uint tot) public returns (bool);
    function transferFrom(address src, address dst, uint tot) public returns (bool);
}