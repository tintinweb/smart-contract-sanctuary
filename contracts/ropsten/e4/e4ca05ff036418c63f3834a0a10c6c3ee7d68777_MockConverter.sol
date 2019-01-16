pragma solidity ^0.4.24;

// File: contracts/interfaces/Token.sol

contract Token {
    function transfer(address _to, uint _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success);
    function balanceOf(address _owner) public view returns (uint256 balance);
}

// File: contracts/interfaces/TokenConverter.sol

contract TokenConverter {
    address public constant ETH_ADDRESS = 0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee;
    function getReturn(Token _fromToken, Token _toToken, uint256 _fromAmount) external view returns (uint256 amount);
    function convert(Token _fromToken, Token _toToken, uint256 _fromAmount, uint256 _minReturn) external payable returns (uint256 amount);
}

// File: contracts/interfaces/AvailableProvider.sol

interface AvailableProvider {
   function isAvailable(Token _from, Token _to, uint256 _amount) external view returns (bool);
}

// File: contracts/utils/Ownable.sol

contract Ownable {
    address public owner;

    event SetOwner(address _owner);

    modifier onlyOwner() {
        require(msg.sender == owner, "msg.sender is not the owner");
        _;
    }

    constructor() public {
        owner = msg.sender;
        emit SetOwner(msg.sender);
    }

    /**
        @dev Transfers the ownership of the contract.

        @param _to Address of the new owner
    */
    function transferTo(address _to) public onlyOwner returns (bool) {
        require(_to != address(0), "Can&#39;t transfer to address 0x0");
        emit SetOwner(_to);
        owner = _to;
        return true;
    }
}

// File: contracts/MockConverter.sol

contract MockConverter is TokenConverter, AvailableProvider, Ownable {
    Token constant internal ETH_TOKEN_ADDRESS = Token(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee);

    event Swap(address indexed sender, Token srcToken, Token destToken, uint amount);

    event WithdrawTokens(address _token, address _to, uint256 _amount);
    event WithdrawEth(address _to, uint256 _amount);
    event SetRate(address _a, address _b, uint256 _rate);

    mapping(address => mapping(address => uint256)) public rate;

    function setRate(
        address _a,
        address _b,
        uint256 _rate
    ) external onlyOwner {
        emit SetRate(_a, _b, _rate);
        rate[_a][_b] = _rate;
    }

    function isAvailable(Token a, Token b, uint256 amount) external view returns (bool) {
        return (
            rate[a][b] != 0 &&
            _balance(b, address(this)) >= (rate[a][b] * amount / 10 ** 18)
        );
    }
    
    function _balance(Token _token, address _target) internal view returns (uint256) {
        if (_token == ETH_TOKEN_ADDRESS) {
            return address(_target).balance;
        } else {
            return Token(_token).balanceOf(_target);
        }
    }

    function _transferFrom(
        Token _token,
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        if (_token == ETH_TOKEN_ADDRESS) {
            if (_from == address(this)) {
                _to.transfer(_amount);
            } else if (_to == address(this)) {
                require(msg.value >= _amount);
            } else {
                revert();
            }
        } else {
            if (_from == address(this)) {
                require(_token.transfer(_to, _amount));
            } else {
                require(_token.transferFrom(_from, _to, _amount));
            }
        }
    }

    function getReturn(
        Token from,
        Token to, 
        uint256 srcQty
    ) external view returns (uint256) {
        return _getReturn(from, to, srcQty);
    }

    function _getReturn(
        Token from,
        Token to, 
        uint256 srcQty
    ) internal view returns (uint256) {
        return rate[from][to] * srcQty / 10 ** 18;
    }

    function convert(
        Token from,
        Token to, 
        uint256 srcQty, 
        uint256 minReturn
    ) external payable returns (uint256 destAmount) {
        destAmount = _getReturn(from, to, srcQty);
        _transferFrom(from, msg.sender, address(this), srcQty);
        _transferFrom(to, address(this), msg.sender, destAmount);
        emit Swap(msg.sender, from, to, srcQty);
        require(destAmount >= minReturn);
    }

    function withdrawTokens(
        Token _token,
        address _to,
        uint256 _amount
    ) external onlyOwner returns (bool) {
        emit WithdrawTokens(_token, _to, _amount);
        return _token.transfer(_to, _amount);
    }

    function withdrawEther(
        address _to,
        uint256 _amount
    ) external onlyOwner {
        emit WithdrawEth(_to, _amount);
        _to.transfer(_amount);
    }

    function() external payable {}
}