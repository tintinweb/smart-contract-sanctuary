/**
 *Submitted for verification at Etherscan.io on 2021-04-07
*/

pragma solidity ^0.5.0;

contract FilsToken {
    string public name = "Fils Token"; 
    string public symbol = "FILS"; 
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

contract FILSTokenSale {
    address payable admin;
    FilsToken public tokenContract;


    constructor(FilsToken _tokenContract) public {
        admin = msg.sender;
        tokenContract = _tokenContract;
    }

    function buyTokens() public payable{
        
        uint256   _numberOfTokens = msg.value / 10**14;

        require(
            tokenContract.balanceOf(address(this)) >= _numberOfTokens,
            "Contact does not have enough tokens"
        );
        require(
            tokenContract.transfer(msg.sender, _numberOfTokens),
            "Some problem with token transfer"
        );
    }

    function endSale() public {
        require(msg.sender == admin, "Only the admin can call this function");
        require(
            tokenContract.transfer(
                address(0),
                tokenContract.balanceOf(address(this))
            ),
            "Unable to transfer tokens to 0x0000"
        );
        // destroy contract
        selfdestruct(admin);
    }
}