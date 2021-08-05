/**
 *Submitted for verification at Etherscan.io on 2021-08-05
*/

// hevm: flattened sources of src/token.sol

pragma solidity >=0.4.23;

////// src/token.sol
/// token.sol -- Non-Fungible Token of ERC20 simulation

/* pragma solidity >=0.4.23; */

contract NFToken {
    address                                         public owner;
    uint256 constant                                public totalSupply = 1;
    mapping(address => mapping(address => uint256)) public allowance;
    string                                          public symbol;
    uint8 constant                                  public decimals = 0;    // standard token precision. override to customize
    string                                          public name = "";       // Optional token name
    string                                          public tokenURI = "";

    constructor(
        address owner_,
        string memory name_,
        string memory symbol_,
        string memory tokenURI_
    ) public {
        owner = owner_;
        name = name_;
        symbol = symbol_;
        tokenURI = tokenURI_;

        emit LogSetOwner(owner);
    }

    event LogSetOwner(address indexed owner);
    event Approval(address indexed src, address indexed guy, uint256 amount);
    event Transfer(address indexed src, address indexed dst, uint256 amount);

    modifier auth() {
        require(msg.sender == owner, "nf-auth-unauthorized");
        _;
    }

    function balanceOf(address guy) public view returns (uint256) {
        if (guy == owner) {
            return totalSupply;
        }
        return 0;
    }

    function approve(address guy) external returns (bool) {
        return approve(guy, uint256(-1));
    }

    function approve(address guy, uint256 amount) public returns (bool) {
        allowance[msg.sender][guy] = amount;

        emit Approval(msg.sender, guy, amount);

        return true;
    }

    function transfer(address dst, uint256 amount) external returns (bool) {
        return transferFrom(msg.sender, dst, amount);
    }

    function transferFrom(
        address src,
        address dst,
        uint256 amount
    ) public returns (bool) {
        require(amount == 1, "nf-token-invalid-amount");
        require(src == owner, "nf-token-insufficient-balance");

        if (src != msg.sender && allowance[src][msg.sender] != uint256(-1)) {
            require(
                allowance[src][msg.sender] >= amount,
                "nf-token-insufficient-approval"
            );
            allowance[src][msg.sender] = allowance[src][msg.sender] - amount;
        }

        owner = dst;
        emit LogSetOwner(dst);
        emit Transfer(src, dst, amount);

        return true;
    }
}