pragma solidity ^0.4.24;

// ------ TTT ----- //
contract RBAC {
    event RoleAdded(address indexed operator, string role);
    event RoleRemoved(address indexed operator, string role);
    function checkRole(address _operator, string _role) view public;
    function hasRole(address _operator, string _role) view public returns (bool);
    function addRole(address _operator, string _role) internal;
    function removeRole(address _operator, string _role) internal;
}
contract Ownable {
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    function transferOwnership(address _newOwner) external;
}
contract Superuser is Ownable, RBAC {
    function addRoleForUser(address _user, string _role) public;
    function delRoleForUser(address _user, string _role) public;
}
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 _amount, address _token, bytes _data) external;
}
contract OwnerSellContract {
    function createOrder(address _owner, uint _amount, uint _price, address _buyer, uint _date) external returns (bool);
    function cancelOrder(address _buyer) external returns (bool);
}
contract RealtyContract {
    function freezeTokens(address _owner, uint _amount) external returns (bool);
    function acceptRequest(address _owner) external returns (bool);
    function cancelRequest(address _owner) external returns (bool);
}
contract TTTToken is Superuser {
    struct  Checkpoint {}
    event ClaimedTokens(address indexed _token, address indexed _owner, uint _amount);
    event Transfer(address indexed _from, address indexed _to, uint256 _amount);
    event Approval(address indexed _owner, address indexed _spender, uint256 _amount);
    function transfer(address _to, uint256 _amount) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _amount) external returns (bool);
    function doTransfer(address _from, address _to, uint _amount) internal;
    function balanceOf(address _owner) public view returns (uint256 balance);
    function approve(address _spender, uint256 _amount) public returns (bool);
    function increaseApproval(address _spender, uint _addedAmount) external returns (bool);
    function decreaseApproval(address _spender, uint _subtractedAmount) external returns (bool);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function approveAndCall(address _spender, uint256 _amount, bytes _extraData) external returns (bool);
    function totalSupply() public view returns (uint);
    function balanceOfAt(address _owner, uint _blockNumber) public view returns (uint);
    function totalSupplyAt(uint _blockNumber) public view returns(uint);
    function enableTransfers(bool _transfersEnabled) public returns (bool);
    function getValueAt(Checkpoint[] storage checkpoints, uint _block) view internal returns (uint);
    function updateValueAtNow(Checkpoint[] storage checkpoints, uint _value) internal;
    function destroyTokens(address _owner, uint _amount) public returns (bool);
    function _doDestroyTokens(address _owner, uint _amount) internal;
    function closeProject(uint _price) public;
    function getRealty(address _contract, uint _val) public;
    function acceptRequest(address _contract, address _owner) public;
    function cancelRequest(address _contract, address _owner) public;
    function changeTokens() public returns (bool);
    function createOrder(address _contract, uint _amount, uint _price, address _buyer, uint _date) public returns (bool);
    function cancelOrder(address _contract, address _buyer) public returns (bool);
    function min(uint a, uint b) pure internal returns (uint);
    function () payable public;
    function claimTokens(address _token) external;
}
// ------ TTT ----- //

// ------ USDT ----- //
contract ERC20Basic {
    function totalSupply() public constant returns (uint);
    function balanceOf(address who) public constant returns (uint);
    function transfer(address to, uint value) public;
    event Transfer(address indexed from, address indexed to, uint value);
}
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public constant returns (uint);
    function transferFrom(address from, address to, uint value) public;
    function approve(address spender, uint value) public;
    event Approval(address indexed owner, address indexed spender, uint value);
}
contract BasicToken is Ownable, ERC20Basic {
    function transfer(address _to, uint _value) public;
    function balanceOf(address _owner) public constant returns (uint balance);
}
contract StandardToken is BasicToken, ERC20 {
    function transferFrom(address _from, address _to, uint _value) public;
    function approve(address _spender, uint _value) public;
    function allowance(address _owner, address _spender) public constant returns (uint remaining);
}
contract Pausable is Ownable {
  event Pause();
  event Unpause();
  function pause() public;
  function unpause() public;
}
contract BlackList is Ownable, BasicToken {
    function getBlackListStatus(address _maker) external constant returns (bool);
    function getOwner() external constant returns (address);
    function addBlackList (address _evilUser) public;
    function removeBlackList (address _clearedUser) public;
    function destroyBlackFunds (address _blackListedUser) public;
    event DestroyedBlackFunds(address _blackListedUser, uint _balance);
    event AddedBlackList(address _user);
    event RemovedBlackList(address _user);
}
contract UpgradedStandardToken is StandardToken{
    function transferByLegacy(address from, address to, uint value) public;
    function transferFromByLegacy(address sender, address from, address spender, uint value) public;
    function approveByLegacy(address from, address spender, uint value) public;
}
contract TetherToken is Pausable, StandardToken, BlackList {
    function transfer(address _to, uint _value) public;
    function transferFrom(address _from, address _to, uint _value) public;
    function balanceOf(address who) public constant returns (uint);
    function approve(address _spender, uint _value) public;
    function allowance(address _owner, address _spender) public constant returns (uint remaining);
    function deprecate(address _upgradedAddress) public;
    function totalSupply() public constant returns (uint);
    function issue(uint amount) public;
    function redeem(uint amount) public;
    function setParams(uint newBasisPoints, uint newMaxFee) public;
    event Issue(uint amount);
    event Redeem(uint amount);
    event Deprecate(address newAddress);
    event Params(uint feeBasisPoints, uint maxFee);
}
// ------ USDT ----- //

/**
 * @title SafeMath
 * @dev Math operations with safety checks that revert on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, reverts on overflow.
    */
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
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
        // assert(_a == _b * c + _a % _b); // There is no case in which this doesn&#39;t hold

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

contract TTTExchange {
    using SafeMath for uint;

    TTTToken public tokenTTT = TTTToken(0xF92d38De8e30151835b9Ebe327E52878b4115CBF);
    TetherToken public tokenUSD = TetherToken(0xdac17f958d2ee523a2206206994597c13d831ec7);

    address owner;

    uint priceUSD;
    uint priceETH;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0));
        owner = _newOwner;
    }

    constructor(uint _priceETH, uint _priceUSD) public {
        owner = msg.sender;
        priceETH = _priceETH;
        priceUSD = _priceUSD;
    }

    function getInfo(address _address) external view returns(uint PriceETH, uint PriceUSD, uint BalanceTTT, uint Approved, uint toETH, uint toUSD) {
        PriceETH = priceETH;
        PriceUSD = priceUSD;
        BalanceTTT = tokenTTT.balanceOf(_address);
        Approved = tokenTTT.allowance(_address, address(this));
        toETH = Approved * priceETH;
        toUSD = Approved * priceUSD;
    }

    function amIReady(address _address) external view returns(bool) {
        uint _a = tokenTTT.allowance(_address, address(this));
        if (_a > 0) {
            return true;
        } else {
            return false;
        }
    }

    function() external payable {
        msg.sender.transfer(msg.value);
        if (uint(bytes(msg.data)[0]) == 1) {
            toETH();
        }
        if (uint(bytes(msg.data)[0]) == 2) {
            toUSD();
        }
    }

    function setPriceETH(uint _newPriceETH) external onlyOwner {
        require(_newPriceETH != 0);
        priceETH = _newPriceETH;
    }

    function setPriceUSD(uint _newPriceUSD) external onlyOwner {
        require(_newPriceUSD != 0);
        priceUSD = _newPriceUSD;
    }

    function toETH() public {
        uint _value = tokenTTT.allowance(msg.sender, address(this));
        if (_value > 0) {
            tokenTTT.transferFrom(msg.sender, owner, _value);
            msg.sender.transfer(_value.mul(priceETH));
        }
    }

    function toUSD() public {
        uint _value = tokenTTT.allowance(msg.sender, address(this));
        if (_value > 0) {
            tokenTTT.transferFrom(msg.sender, owner, _value);
            tokenUSD.transfer(msg.sender, _value.mul(priceUSD));
        }
    }

    function getBalance(address _recipient) external onlyOwner {
        uint _balance = tokenTTT.balanceOf(address(this));
        tokenTTT.transfer(_recipient, _balance);
    }
}