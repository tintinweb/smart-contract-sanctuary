/**
 *Submitted for verification at Etherscan.io on 2021-08-19
*/

pragma solidity 0.5.6;

contract UsdtToken {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public supply;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    //Events
    event Transfer(address sender, address receiver, uint256 tokens);
    event Approval(address sender, address delegate, uint256 tokens);

    //constructor
    constructor() public {
        name = "Tether";
        symbol = "USDT";
        decimals = 18;
        supply = 100000000 * 10**18;
        balances[msg.sender] = supply;
    }

    //Functions

    function totalSupply() external view returns (uint256) {
        return supply;
    }

    //How many tokens does this person have
    function balanceOf(address tokenOwner) external view returns (uint256) {
        return balances[tokenOwner];
    }

    //helps in transferring from your account to another person
    function transfer(address receiver, uint256 numTokens)
        external
        returns (bool)
    {
        require(
            msg.sender != receiver,
            "Sender and receiver can't be the same"
        );
        require(balances[msg.sender] >= numTokens, "Not enough balance");
        balances[msg.sender] -= numTokens;
        balances[receiver] += numTokens;
        emit Transfer(msg.sender, receiver, numTokens);
        return true;
    }

    // Used to delegate authority to send tokens without my approval
    function approve(address delegate, uint256 numTokens)
        external
        returns (bool)
    {
        require(
            msg.sender != delegate,
            "Sender and delegate can't be the same"
        );
        allowed[msg.sender][delegate] = numTokens;
        emit Approval(msg.sender, delegate, numTokens);
        return true;
    }

    // How much has the owner delegated/approved to the delegate
    function allowance(address owner, address delegate)
        external
        view
        returns (uint256)
    {
        return allowed[owner][delegate];
    }

    // Used by exchanges to send money from owner to buyer
    function transferFrom(
        address owner,
        address buyer,
        uint256 numTokens
    ) external returns (bool) {
        require(owner != buyer, "Owner and Buyer can't be the same");
        require(balances[owner] >= numTokens, "Not enough balance");
        require(
            allowed[owner][msg.sender] >= numTokens,
            "Not enough allowance"
        );
        balances[owner] -= numTokens;
        balances[buyer] += numTokens;
        allowed[owner][msg.sender] -= numTokens;
        emit Transfer(owner, buyer, numTokens);
        return true;
    }
}