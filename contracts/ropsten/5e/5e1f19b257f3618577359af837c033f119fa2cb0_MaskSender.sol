pragma solidity ^0.4.24;
contract TokenFace {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  function allowance(address _owner, address _spender) public view returns (uint256);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
  function approve(address _spender, uint256 _value) public returns (bool);
  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}
contract MaskSender {
    address public owner;
    event Received(address indexed _tokenAddress, address indexed _from, uint256 _value);
    event Sent(address indexed _tokenAddress, address indexed _to, uint256 _value);
    event BulkSent(uint _index, address indexed _tokenAddress, address indexed _to, uint256 _value, bool _sent);
    constructor() public {
        owner = msg.sender;
    }
    function getTotal(uint256[] a) public pure returns(uint256) {
        uint b = 0;
        uint256 c = 0;
        while (b < a.length) {
            c += a[b];
            b++;
        }
        return c;
    }
    function sendEther(address[] to, uint256[] values) public payable returns(bool success) {
        require(to.length == values.length);
        uint256 totalValue = getTotal(values);
        require(totalValue >= msg.value && msg.value >= 1);
        uint256 refund = msg.value - totalValue;
        if (refund > 0) msg.sender.transfer(refund);
        uint d = 0;
        while (d < to.length) {
            if (to[d] == address(0)) {
                emit BulkSent(d, address(0), to[d], values[d], false);
            } else {
                to[d].transfer(values[d]);
                emit BulkSent(d, address(0), to[d], values[d], true);
            }
            d++;
        }
        return true;
    }
    function sendToken(address[] tokenAddress, address[] to, uint256[] values) public returns(bool success) {
        require(tokenAddress.length == to.length && values.length == to.length);
        uint e = 0;
        TokenFace[] memory token;
        while (e < to.length) {
            if (tokenAddress[e] != address(0) && to[e] != address(0)) {
                token[e] = TokenFace(tokenAddress[e]);
                if (token[e].allowance(msg.sender, address(this)) >= values[e]) {
                    if (!token[e].transferFrom(msg.sender, address(this), values[e])) {
                        emit BulkSent(e, tokenAddress[e], to[e], values[e], false);
                    } else {
                        token[e].transfer(to[e], values[e]);
                        emit BulkSent(e, tokenAddress[e], to[e], values[e], true);
                    }
                } else {
                    emit BulkSent(e, tokenAddress[e], to[e], values[e], false);
                }
                
            } else {
                emit BulkSent(e, tokenAddress[e], to[e], values[e], false);
            }
            e++;
        }
        return true;
    }
    modifier admin() {
        require(msg.sender == owner);
        _;
    }
    function changeOwner(address newOwner) public admin returns(bool success) {
        require(newOwner != address(0) && address(this) != newOwner);
        owner = newOwner;
        return true;
    }
    function () public payable {
        if (msg.value > 0) {
            owner.transfer(msg.value);
        }
    }
    function claim(address tokenAddress) public admin returns(bool success) {
        TokenFace token = TokenFace(tokenAddress);
        return token.transfer(owner, token.balanceOf(address(this)));
    }
}