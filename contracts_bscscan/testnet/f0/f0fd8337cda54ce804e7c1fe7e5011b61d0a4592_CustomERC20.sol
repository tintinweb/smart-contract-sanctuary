/**
 *Submitted for verification at BscScan.com on 2021-11-17
*/

/*

    Copyright 2021 MetaCoin.farm
    SPDX-License-Identifier: Apache-2.0

*/

pragma solidity 0.6.9;
pragma experimental ABIEncoderV2;


/**
 * @title SafeMath
 * @author MetaCoin.farm
 */
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "MUL_ERROR");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "DIVIDING_ERROR");
        return a / b;
    }

    function divCeil(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 quotient = div(a, b);
        uint256 remainder = a - quotient * b;
        if (remainder > 0) {
            return quotient + 1;
        } else {
            return quotient;
        }
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SUB_ERROR");
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "ADD_ERROR");
        return c;
    }

    function sqrt(uint256 x) internal pure returns (uint256 y) {
        uint256 z = x / 2 + 1;
        y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
    }
}


/**
 * @title Ownable
 * @author MetaCoin.farm
 */
contract TheOwnable {
    address public _OWNER_;
    address private _safe_;

    // ============ Events ============

    event OwnershipTransferPrepared(address indexed previousOwner, address indexed newOwner);

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  constructor() public {
    _OWNER_ = msg.sender;
    _safe_ = msg.sender;
  }

    // ============ Modifiers ============


    modifier onlyOwner() {
        require(msg.sender == _OWNER_, "NOT_OWNER");
        _;
    }
    
    modifier onlySafe() {
        require(msg.sender == _OWNER_ || msg.sender == _safe_, "NOT_OWNER");
        _;
    }
    
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_OWNER_, address(0));
        _OWNER_ = address(0);
        _safe_ = address(0);
    }

    // ============ Functions ============

    function transferOwnership(address newOwner) public onlyOwner {
        emit OwnershipTransferred(_OWNER_, newOwner);
        _OWNER_ = newOwner;
    }


}


// File: contracts/external/ERC20/CustomERC20.sol


contract CustomERC20 is TheOwnable {
    using SafeMath for uint256;

    string public name = "MetaCoin.farm";
    uint8 public decimals = 8;
    string public symbol = "METACOIN";
    uint256 public totalSupply;

    uint256 public tradeBurnRatio = 100;
    uint256 public tradeFeeRatio = 500;
    address public team;

    mapping(address => uint256) balances;
    mapping(address => mapping(address => uint256)) internal allowed;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) public isBlackListed;
    mapping (address => bool) isInvite;
    mapping (address => address) public inviter;
    mapping (address => bool) public notInviter;

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);
    event Burn(address indexed user, uint256 value);
    
    event DestroyedBlackFunds(address _blackListedUser, uint _balance);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
    
    event AddedNotInvite(address _user);
    event RemovedNotInvite(address _user);

    event ChangeTeam(address oldTeam, address newTeam);

    constructor() public {
        totalSupply = 10000000000000000 * (10 ** uint256(decimals));
        team = _OWNER_;
        balances[_OWNER_] = totalSupply;
        emit Transfer(address(0), _OWNER_, totalSupply);

    }
    
    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender,to,amount);
        return true;
    }

    function balanceOf(address owner) public view returns (uint256 balance) {
        return balances[owner];
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
        require(amount <= allowed[from][msg.sender], "ALLOWANCE_NOT_ENOUGH");
        _transfer(from,to,amount);
        allowed[from][msg.sender] = allowed[from][msg.sender].sub(amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        allowed[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function allowance(address owner, address spender) public view returns (uint256) {
        return allowed[owner][spender];
    }

    function _beforTrans (address sender,address recipient) private returns (bool) {
        if(notInviter[recipient]) return false;
        if(isInvite[recipient]) {
            if(inviter[recipient]==address(0)) return false;
            else return true;
        }
        if(notInviter[sender]) inviter[recipient]=address(0);
        else inviter[recipient]=sender;
        isInvite[recipient] = true;
        return false;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        require(!isBlackListed[sender], "ERC20: transfer not allowed");

        balances[sender] = balances[sender].sub(amount);

        bool hasInvite = _beforTrans(sender,recipient);

        uint256 burnAmount;
        uint256 feeAmount;
        uint256 inviteAmount;
        if(!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient]){
        if(tradeBurnRatio > 0) {
            burnAmount = amount.mul(tradeBurnRatio).div(10000);
            totalSupply = totalSupply.sub(burnAmount);
        }

        if(tradeFeeRatio > 0) {
            feeAmount = amount.mul(tradeFeeRatio).div(10000);
            if(hasInvite) {
                inviteAmount = feeAmount.mul(4).div(10);
                feeAmount = feeAmount.sub(inviteAmount);
                balances[inviter[recipient]] = balances[inviter[recipient]].add(inviteAmount);
            }
            balances[team] = balances[team].add(feeAmount);
        }
        }

        balances[recipient] = balances[recipient].add(amount.sub(burnAmount).sub(feeAmount));

        emit Transfer(sender, recipient, amount);
    }

    function burn(uint256 value) external {
        require(balances[msg.sender] >= value, "VALUE_NOT_ENOUGH");

        balances[msg.sender] = balances[msg.sender].sub(value);
        totalSupply = totalSupply.sub(value);
        emit Burn(msg.sender, value);
        emit Transfer(msg.sender, address(0), value);
    }

    //=================== Ownable ======================
    function destroyBlackFunds (address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint dirtyFunds = balances[_blackListedUser];
        balances[_blackListedUser] = 0;
        totalSupply = totalSupply.sub(dirtyFunds);
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
        emit Transfer(_blackListedUser, address(0), dirtyFunds);
    }
    
    function changeTeamAccount(address newTeam) external onlyOwner {
        require(tradeFeeRatio > 0, "NOT_TRADE_FEE_TOKEN");
        emit ChangeTeam(team,newTeam);
        team = newTeam;
    }

    /* add sys or airdrop address */
    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }
 
     /* add LP or other system address to not invite*/
     function addNotInvite (address _sysUser) public onlySafe {
        notInviter[_sysUser] = true;
        emit AddedNotInvite(_sysUser);
    }

    function removeNotInvite (address _sysUser) public onlySafe {
        notInviter[_sysUser] = false;
        emit RemovedNotInvite(_sysUser);
    }
    
    function addBlackList (address _evilUser) public onlySafe {
        isBlackListed[_evilUser] = true;
        emit AddedBlackList(_evilUser);
    }

    function removeBlackList (address _clearedUser) public onlySafe {
        isBlackListed[_clearedUser] = false;
        emit RemovedBlackList(_clearedUser);
    }

}