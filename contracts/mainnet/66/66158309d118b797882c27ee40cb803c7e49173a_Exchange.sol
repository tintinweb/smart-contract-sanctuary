pragma solidity ^0.4.24;

contract IBancorConverter {
    function getReturn(address _fromToken, address _toToken, uint256 _amount) public view returns (uint256);
}

contract IExchange {
    function ethToTokens(uint _ethAmount) public view returns(uint);
    function tokenToEth(uint _amountOfTokens) public view returns(uint);
    function tokenToEthRate() public view returns(uint);
    function ethToTokenRate() public view returns(uint);
}

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

contract Exchange is Owned, IExchange {
    using SafeMath for uint;

    IBancorConverter public bntConverter;
    IBancorConverter public tokenConverter;

    address public ethToken;
    address public bntToken;
    address public token;

    event Initialized(address _bntConverter, address _tokenConverter, address _ethToken, address _bntToken, address _token);

    constructor() public { 
    }

    function initialize(address _bntConverter, address _tokenConverter, address _ethToken, address _bntToken, address _token) external onlyOwner {
       bntConverter = IBancorConverter(_bntConverter);
       tokenConverter = IBancorConverter(_tokenConverter);

       ethToken = _ethToken;
       bntToken = _bntToken;
       token = _token;

       emit Initialized(_bntConverter, _tokenConverter, _ethToken, _bntToken, _token);
    }

    function ethToTokens(uint _ethAmount) public view returns(uint) {
        uint bnt = bntConverter.getReturn(ethToken, bntToken, _ethAmount);
        uint amountOfTokens = tokenConverter.getReturn(bntToken, token, bnt);
        return amountOfTokens;
    }

    function tokenToEth(uint _amountOfTokens) public view returns(uint) {
        uint bnt = tokenConverter.getReturn(token, bntToken, _amountOfTokens);
        uint eth = bntConverter.getReturn(bntToken, ethToken, bnt);
        return eth;
    }

    function tokenToEthRate() public view returns(uint) {
        uint eth = tokenToEth(1 ether);
        return eth;
    }

    function ethToTokenRate() public view returns(uint) {
        uint tkn = ethToTokens(1 ether);
        return tkn;
    }
}

library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}