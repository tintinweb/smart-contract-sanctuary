/**
 *Submitted for verification at Etherscan.io on 2021-08-21
*/

// hevm: flattened sources of src/token.sol

pragma solidity >=0.4.23;

////// src/token.sol
/// token.sol -- Non-Fungible Token of ERC20 simulation

/* pragma solidity >=0.4.23; */

contract NFToken {
    address                                         public root;
    address                                         public owner;
    uint256 constant                                public totalSupply = 1;
    mapping(address => mapping(address => uint256)) public allowance;
    string                                          public symbol;
    uint8 constant                                  public decimals = 0;
    string                                          public name = "";
    string                                          public tokenURI = "";

    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory tokenURI_
    ) public {
        name = name_;
        owner = owner_;
        symbol = symbol_;
        root = msg.sender;
        tokenURI = tokenURI_;
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function balanceOf(address _owner) external view returns (uint256) {
        if (_owner == owner) {
            return totalSupply;
        }
        return 0;
    }

    function approve(address _spender, uint256 _value) external returns (bool) {
        allowance[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    function transfer(address _to, uint256 _value) external returns (bool) {
        return transferFrom(msg.sender, _to, _value);
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool) {
        require(_value == 1, "nf-token-invalid-amount");
        require(_from == owner, "nf-token-insufficient-balance");

        if (_from != msg.sender) {
            require(
                allowance[_from][msg.sender] >= _value,
                "nf-token-insufficient-approval"
            );
            allowance[_from][msg.sender] = allowance[_from][msg.sender] - _value;
        }

        owner = _to;
        emit Transfer(_from, _to, _value);

        return true;
    }

    function setTokenURI(string calldata tokenURI_) external {
        require(msg.sender == root, "auth-unauthorized");
        tokenURI = tokenURI_;
    }
}