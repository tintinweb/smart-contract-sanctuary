pragma solidity ^0.4.24;

// ////////////////////////////////////////////////////////////////////////////////////////////////////
//                     ___           ___           ___                    __      
//       ___          /  /\         /  /\         /  /\                  |  |\    
//      /__/\        /  /::\       /  /::\       /  /::|                 |  |:|   
//      \  \:\      /  /:/\:\     /  /:/\:\     /  /:|:|                 |  |:|   
//       \__\:\    /  /::\ \:\   /  /::\ \:\   /  /:/|:|__               |__|:|__ 
//       /  /::\  /__/:/\:\ \:\ /__/:/\:\_\:\ /__/:/_|::::\          ____/__/::::\
//      /  /:/\:\ \  \:\ \:\_\/ \__\/  \:\/:/ \__\/  /~~/:/          \__\::::/~~~~
//     /  /:/__\/  \  \:\ \:\        \__\::/        /  /:/              |~~|:|    
//    /__/:/        \  \:\_\/        /  /:/        /  /:/               |  |:|    
//    \__\/          \  \:\         /__/:/        /__/:/                |__|:|    
//                    \__\/         \__\/         \__\/                  \__\|    
//  ______   ______   ______   _____    _    _   ______  ______  _____ 
// | |  | \ | |  | \ / |  | \ | | \ \  | |  | | | |     | |     | | \ \ 
// | |__|_/ | |__| | | |  | | | |  | | | |  | | | |     | |---- | |  | |
// |_|      |_|  \_\ \_|__|_/ |_|_/_/  \_|__|_| |_|____ |_|____ |_|_/_/ 
// 
// TEAM X All Rights Received. http://teamx.club 
// This product is protected under license.  Any unauthorized copy, modification, or use without 
// express written consent from the creators is prohibited.
// Any cooperation Please email: <a href="/cdn-cgi/l/email-protection" class="__cf_email__" data-cfemail="f5869087839c9690b5819094988ddb96998097">[email&#160;protected]</a>
// ////////////////////////////////////////////////////////////////////////////////////////////////////

contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

//=========================================================...
// |\/| _ . _   /~` _  _ _|_ _ _  __|_  .
// |  |(_||| |  \_,(_)| | | | (_|(_ |   . Main Contract
//=========================================================    
contract XToken is Owned {
    using SafeMath for uint256;

    event Transfer(address indexed _from, address indexed _to, uint256 _value, bytes _data);
    mapping(address => uint256) balances;

    string public name = "XToken";
    string public symbol = "XT";
    uint8 public decimals = 18;
    uint256 private fee_ = 5; // 5% fee to buy and sell

    uint256 public totalSupply = 100000000 * (1 ether);
    uint256 public tokenMarketPool = 0; // no shares
    uint256 public poolPrice = 1 finney;


    //=========================================================...
    //  _ _  _  __|_ _   __|_ _  _
    // (_(_)| |_\ | ||_|(_ | (_)| 
    //=========================================================
    constructor () public {
        balances[msg.sender] = 30000000 * (1 ether); // keeps 30%
        tokenMarketPool = totalSupply.sub(balances[msg.sender]);
    }

    //=========================================================...
    //  _    |_ |. _   |`    _  __|_. _  _  _  .
    // |_)|_||_)||(_  ~|~|_|| |(_ | |(_)| |_\  . public functions
    //=|=======================================================
    function () public payable {
        if (!isContract(msg.sender)) {
            revert("Can not Send Eth directly to this token");
        }
    }

    function buy() public payable {
        uint256 ethAmount = msg.value;
        uint256 taxed = ethAmount.sub(ethAmount.mul(fee_).div(100));
        uint256 tokenAmount = taxed.mul(1 ether).div(poolPrice);

        require(tokenMarketPool >= tokenAmount, "No enough token in market pool");
        tokenMarketPool = tokenMarketPool.sub(tokenAmount);
        balances[msg.sender] = balanceOf(msg.sender).add(tokenAmount);
    }

    function sell(uint256 tokenAmount) public {
        require(balanceOf(msg.sender) >= tokenAmount, "No enough token");
        uint256 sellPrice = getSellPrice();
        uint256 soldEth = tokenAmount.mul(sellPrice).div(1 ether);

        balances[msg.sender] = balanceOf(msg.sender).sub(tokenAmount);
        tokenMarketPool = tokenMarketPool.add(tokenAmount);
        uint256 gotEth = soldEth.sub(soldEth.mul(fee_).div(100));
        msg.sender.transfer(gotEth);
    }

    function transfer(address _to, uint256 _value, bytes _data, string _custom_fallback) public returns (bool success) {
        if (isContract(_to)) {
            require(balanceOf(msg.sender) >= _value, "no enough token");
            balances[msg.sender] = balanceOf(msg.sender).sub(_value);
            balances[_to] = balanceOf(_to).add(_value);
            assert(_to.call.value(0)(bytes4(keccak256(_custom_fallback)), msg.sender, _value, _data));
            emit Transfer(msg.sender, _to, _value, _data);
            return true;
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    function transfer(address _to, uint256 _value, bytes _data) public returns (bool success) {
        if (isContract(_to)) {
            return transferToContract(_to, _value, _data);
        } else {
            return transferToAddress(_to, _value, _data);
        }
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

    //=========================================================...
    //   . _      |`    _  __|_. _  _  _  .
    // \/|(/_VV  ~|~|_|| |(_ | |(_)| |_\  . view functions
    //=========================================================
    function getShareToken() public view returns (uint256) {
        return totalSupply.sub(tokenMarketPool);
    }

    function getSellPrice() public view returns (uint256) {
        return address(this).balance.mul(1 ether).div(getShareToken());
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    //=========================================================...
    //  _  _.   _ _|_ _    |`    _  __|_. _  _  _  .
    // |_)| |\/(_| | (/_  ~|~|_|| |(_ | |(_)| |_\  . private functions
    //=|=======================================================
    function isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly { size := extcodesize(addr) }
        return size > 0;
    }

    function transferToAddress(address _to, uint256 _value, bytes _data) private returns (bool success) {
        require (balanceOf(msg.sender) >= _value, "No Enough Token");
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }

    function transferToContract(address _to, uint256 _value, bytes _data) private returns (bool success) {
        require (balanceOf(msg.sender) >= _value, "No Enough Token");
        balances[msg.sender] = balanceOf(msg.sender).sub(_value);
        balances[_to] = balanceOf(_to).add(_value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
        return true;
    }
}

//=========================================================...
// . _ _|_ _  _|` _  _ _ 
// || | | (/_|~|~(_|(_(/_
//=========================================================
interface ContractReceiver {
    function tokenFallback(address _from, uint256 _value, bytes _data) external;
}

interface ERC20Interface {
    function transfer(address _to, uint256 _value) external returns (bool);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        // Gas optimization: this is cheaper than asserting &#39;a&#39; not being zero, but the
        // benefit is lost if &#39;b&#39; is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
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
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
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