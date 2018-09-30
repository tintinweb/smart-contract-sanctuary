pragma solidity ^0.4.21;

contract Order {
    uint256 public constant MIN_SUPPLY = 1000 ether;

    address public contractor;
    address public purchaser;
    ERC20Basic public token;
    uint256 public rate;

    uint256 public amountOfTransactions;


    constructor(address _contractor, address _purchaser, ERC20Basic _token, uint256 _rate) public {
        contractor = _contractor;
        purchaser = _purchaser;
        token = _token;
        rate = _rate;
    }

    function tokenBalance() external view returns(uint256){
        return token.balanceOf(address(this));
    }

    function exchange(uint256 _ethValue) public {
        require(msg.sender == purchaser);
        internalExchange(_ethValue);
    }

    function internalExchange(uint256 _ethValue) internal {
        require(_ethValue <= address(this).balance);
        uint256 _tokenAmount = _ethValue*rate/ 1 ether;
        require(_tokenAmount >= token.balanceOf(address(this)));
        require(token.transfer(purchaser,_tokenAmount));
        contractor.transfer(_ethValue);
        amountOfTransactions += _ethValue;
    }

    function refundEth(uint256 _ethValue) external {
        require(msg.sender == purchaser);
        uint256 _val = _ethValue;
        uint256 _ethBalance = address(this).balance;
    _val = (_val > _ethBalance) ? _ethBalance : _val;
        purchaser.transfer(_val);
    }

    function refundToken(uint256 _tokenAmount) external {
        require(msg.sender == contractor);
        uint256 _val = _tokenAmount;
        uint256 _tokenBalance = token.balanceOf(address(this));
        _val = (_val > _tokenBalance) ? _tokenBalance : _val;
        require(token.transfer(contractor,_val));
    }

    function () external{
        if(amountOfTransactions >= MIN_SUPPLY) return;
        uint256 _value = (amountOfTransactions + address(this).balance > MIN_SUPPLY)? amountOfTransactions - MIN_SUPPLY : address(this).balance;
        uint256 _tokenAmount = token.balanceOf(address(this));
        _value = (_value * rate / 1 ether > _tokenAmount)? _tokenAmount * 1 ether / rate : _value;
        if (_value == 0) return;
        internalExchange(_value);
    }

}

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}