/**
 *Submitted for verification at Etherscan.io on 2021-08-16
*/

pragma solidity >=0.4.22 <0.9.0;

contract CHRToken {
    string public name = "CHR Token"; 
    string public symbol = "CHR";
    string public standard = "Version #1"; 
    uint256 public totalSupply;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);

    event Approval(
        address indexed _owner,
        address indexed _spender,
        uint256 _value
    );

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint256 _initialSupply) public {
        balanceOf[msg.sender] = _initialSupply;
        totalSupply = _initialSupply;
    }

    function transfer(address _to, uint256 _value)
        public
        returns (bool success)
    {
        require(balanceOf[msg.sender] >= _value, "Not enough balance");
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value)
        public
        returns (bool success)
    {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(
            balanceOf[_from] >= _value,
            "_from does not have enough tokens"
        );
        require(
            allowance[_from][msg.sender] >= _value,
            "Spender limit exceeded"
        );
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }
}

contract tokenSale {
    address payable owner;
    CHRToken public tokenContract;
    uint256 public tokenPrice;
    uint256 public tokensSold;

    event sell(address _buyer, uint256 _amount);

    constructor(CHRToken _tokenContract, uint256 _tokenPrice) public {
        owner = msg.sender;
        tokenContract = _tokenContract;
        tokenPrice = _tokenPrice;
    }

    function buyTokens(uint256 _numberOfTokens) public payable {
        require(
            msg.value == _numberOfTokens * tokenPrice,
            "Number of tokens does not match with the value"
        );
        require(
            tokenContract.balanceOf(address(this)) >= _numberOfTokens,
            "Contact does not have enough tokens"
        );
        require(
            tokenContract.transfer(msg.sender, _numberOfTokens),
            "Some problem with token transfer"
        );
        tokensSold += _numberOfTokens;
        emit sell(msg.sender, _numberOfTokens);
    }

    function endSale() public {
        require(msg.sender == owner, "Only the owner");
        require(
            tokenContract.transfer(
                msg.sender,
                tokenContract.balanceOf(address(this))
            ),
            "Unable to transfer tokens"
        );
        // destroy contract
        selfdestruct(owner);
    }
}