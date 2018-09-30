pragma solidity ^0.4.24;

// File: contracts/SKMForeignBridge.sol

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
    return c;
  }

  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract ERC20 {
    function totalSupply() public view returns (uint);
    function balanceOf(address tokenOwner) public view returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract SKMForeignBridge {

    bool public isLocked = true;
    address public owner;
    address tokenStore;
    ERC20 tokenContract; // ContractA Address
    mapping ( address => uint256 ) public balances;

    event Deposit(address recipient, uint256 value, uint256 homeGasPrice);

    modifier onlyOwner () {
        require (msg.sender == owner);
        _;
    }

    function lockContract () public onlyOwner {
        isLocked = true;
    }
  
    function unlockContract () public onlyOwner {
        isLocked = false;
    }

    modifier onlyUnlocked () {
        require (!isLocked);
        _;
    }

    constructor (address _tokenContract, address _tokenstore) public {
        owner = msg.sender;
        tokenContract = ERC20(_tokenContract);
        tokenStore = _tokenstore;
    }

    function strConcat(string _a, string _b, string _c, string _d, string _e) internal returns (string){
        bytes memory _ba = bytes(_a);
        bytes memory _bb = bytes(_b);
        bytes memory _bc = bytes(_c);
        bytes memory _bd = bytes(_d);
        bytes memory _be = bytes(_e);
        string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
        bytes memory babcde = bytes(abcde);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
        for (i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
        for (i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
        for (i = 0; i < _be.length; i++) babcde[k++] = _be[i];
        return string(babcde);
    }

    function strConcat(string _a, string _b, string _c, string _d) internal returns (string) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string _a, string _b, string _c) internal returns (string) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string _a, string _b) internal returns (string) {
        return strConcat(_a, _b, "", "", "");
    }

    //https://gist.github.com/ageyev/779797061490f5be64fb02e978feb6ac
    function addressToAsciiString(address _address) public constant returns (string) {
        bytes memory s = new bytes(40);
        for (uint i = 0; i < 20; i++) {
            byte b = byte(uint8(uint(_address) / (2 ** (8 * (19 - i)))));
            byte hi = byte(uint8(b) / 16);
            byte lo = byte(uint8(b) - 16 * uint8(hi));
            s[2 * i] = char(hi);
            s[2 * i + 1] = char(lo);
        }
        return string(s);
    } //
    function char(byte b) returns (byte c) {
        if (b < 10) return byte(uint8(b) + 0x30);
        else return byte(uint8(b) + 0x57);
    }

    function deposit(uint _tokens) public onlyUnlocked {
        require (_tokens > 0);
        //Approve before calling this
        //tokenContract.approve(address(this), tokens);
        msg.sender.delegatecall(bytes4(keccak256(strConcat(addressToAsciiString(tokenContract),".approve(address _spender, uint256 _value)"))), _tokens);
        require (tokenContract.allowance(msg.sender, this) >= _tokens);
        require (tokenContract.transferFrom(msg.sender, tokenStore, _tokens));
        balances[msg.sender]+= _tokens;
        emit Deposit(msg.sender, _tokens, gasPriceForCompensationAtHomeSide());
    }

    function transferSKM () public onlyOwner {
        uint fullBalance = tokenContract.balanceOf(address(this));
        require (fullBalance > 0);
        require (tokenContract.transfer(tokenStore, tokenContract.balanceOf(address(this)) ));
    }

    function transferOtherTokens (address _tokenAddr) public onlyOwner {
        require (_tokenAddr != address(tokenContract));
        ERC20 _token = ERC20(_tokenAddr);
        require (_token.transfer(tokenStore, _token.balanceOf(address(this))));
    }

    function getTotalExchanged (address _user) view public returns (uint stakedBalance) {
        uint256 currentBalance = balances[_user];
        return currentBalance;
    }

    function gasPriceForCompensationAtHomeSide() public pure returns(uint256) {
        return 1000000000 wei;
    }
}