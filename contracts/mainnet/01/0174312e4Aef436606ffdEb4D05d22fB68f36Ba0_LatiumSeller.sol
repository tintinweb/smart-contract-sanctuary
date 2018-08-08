pragma solidity ^0.4.13;

contract Latium {
    string public constant name = "Latium";
    string public constant symbol = "LAT";
    uint8 public constant decimals = 16;
    uint256 public constant totalSupply =
        30000000 * 10 ** uint256(decimals);

    // owner of this contract
    address public owner;

    // balances for each account
    mapping (address => uint256) public balanceOf;

    // triggered when tokens are transferred
    event Transfer(address indexed _from, address indexed _to, uint _value);

    // constructor
    function Latium() {
        owner = msg.sender;
        balanceOf[owner] = totalSupply;
    }

    // transfer the balance from sender&#39;s account to another one
    function transfer(address _to, uint256 _value) {
        // prevent transfer to 0x0 address
        require(_to != 0x0);
        // sender and recipient should be different
        require(msg.sender != _to);
        // check if the sender has enough coins
        require(_value > 0 && balanceOf[msg.sender] >= _value);
        // check for overflows
        require(balanceOf[_to] + _value > balanceOf[_to]);
        // subtract coins from sender&#39;s account
        balanceOf[msg.sender] -= _value;
        // add coins to recipient&#39;s account
        balanceOf[_to] += _value;
        // notify listeners about this transfer
        Transfer(msg.sender, _to, _value);
    }
}

contract LatiumSeller {
    address private constant _latiumAddress = 0xBb31037f997553BEc50510a635d231A35F8EC640;
    Latium private constant _latium = Latium(_latiumAddress);

    // amount of Ether collected from buyers and not withdrawn yet
    uint256 private _etherAmount = 0;

    // sale settings
    uint256 private constant _tokenPrice = 10 finney; // 0.01 Ether
    uint256 private _minimumPurchase =
        10 * 10 ** uint256(_latium.decimals()); // 10 Latium

    // owner of this contract
    address public owner;

    // constructor
    function LatiumSeller() {
        owner = msg.sender;
    }

    function tokenPrice() constant returns(uint256 tokenPrice) {
        return _tokenPrice;
    }

    function minimumPurchase() constant returns(uint256 minimumPurchase) {
        return _minimumPurchase;
    }

    // function to get current Latium balance of this contract
    function _tokensToSell() private returns (uint256 tokensToSell) {
        return _latium.balanceOf(address(this));
    }

    // function without name is the default function that is called
    // whenever anyone sends funds to a contract
    function () payable {
        // we shouldn&#39;t sell tokens to their owner
        require(msg.sender != owner && msg.sender != address(this));
        // check if we have tokens to sell
        uint256 tokensToSell = _tokensToSell();
        require(tokensToSell > 0);
        // calculate amount of tokens that can be bought
        // with this amount of Ether
        // NOTE: make multiplication first; otherwise we can lose
        // fractional part after division
        uint256 tokensToBuy =
            msg.value * 10 ** uint256(_latium.decimals()) / _tokenPrice;
        // check if user&#39;s purchase is above the minimum
        require(tokensToBuy >= _minimumPurchase);
        // check if we have enough tokens to sell
        require(tokensToBuy <= tokensToSell);
        _etherAmount += msg.value;
        _latium.transfer(msg.sender, tokensToBuy);
    }

    // functions with this modifier can only be executed by the owner
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // function to withdraw Ether to owner&#39;s account
    function withdrawEther(uint256 _amount) onlyOwner {
        if (_amount == 0) {
            // withdraw all available Ether
            _amount = _etherAmount;
        }
        require(_amount > 0 && _etherAmount >= _amount);
        _etherAmount -= _amount;
        msg.sender.transfer(_amount);
    }

    // function to withdraw Latium to owner&#39;s account
    function withdrawLatium(uint256 _amount) onlyOwner {
        uint256 availableLatium = _tokensToSell();
        require(availableLatium > 0);
        if (_amount == 0) {
            // withdraw all available Latium
            _amount = availableLatium;
        }
        require(availableLatium >= _amount);
        _latium.transfer(msg.sender, _amount);
    }
}