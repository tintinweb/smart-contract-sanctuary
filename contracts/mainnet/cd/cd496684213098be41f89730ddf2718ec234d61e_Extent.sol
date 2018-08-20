pragma solidity 0.4.24;

library SafeMath {

    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a && c >= b);
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

contract ERC20 {
    function totalSupply() public constant returns (uint);

    function balanceOf(address tokenOwner) public constant returns (uint balance);

    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract Extent {
    using SafeMath for uint;

    address public admin; //the admin address
    mapping(address => bool) private canClaimTokens;
    mapping(address => uint) public tokens; //mapping of token addresses to mapping of account balances (token=0 means Ether)
    mapping(address => uint) public claimableAmount; //mapping of token addresses to max amount to claim

    event Deposit(address token, address user, uint amount, uint balance);
    event Withdraw(address token, address user, uint amount, uint balance);

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier onlyWhitelisted(address address_) {
        require(canClaimTokens[address_]);
        _;
    }

    constructor(address admin_) public {
        admin = admin_;
    }

    function() public payable {
        revert("Cannot send ETH directly to the Contract");
    }

    function changeAdmin(address admin_) public onlyAdmin {
        admin = admin_;
    }

    function addToWhitelist(address address_) public onlyAdmin {
        canClaimTokens[address_] = true;
    }

    function addToWhitelistBulk(address[] addresses_) public onlyAdmin {
        for (uint i = 0; i < addresses_.length; i++) {
            canClaimTokens[addresses_[i]] = true;
        }
    }

    function setAmountToClaim(address token, uint amount) public onlyAdmin {
        claimableAmount[token] = amount;
    }

    function depositToken(address token, uint amount) public onlyAdmin {
        //remember to call ERC20Token(address).approve(this, amount) or this contract will not be able to do the transfer on your behalf.
        if (token == 0) revert("Cannot deposit ETH with depositToken method");
        if (!ERC20(token).transferFrom(msg.sender, this, amount)) revert("You didn&#39;t call approve method on Token contract");
        tokens[token] += amount;
        emit Deposit(token, msg.sender, amount, tokens[token]);
    }

    function claimTokens(address token) public onlyWhitelisted(msg.sender) {
        if (token == 0) revert("Cannot withdraw ETH with withdrawToken method");
        if (tokens[token] < claimableAmount[token]) revert("Not enough tokens to claim");
        tokens[token] -= claimableAmount[token];
        canClaimTokens[msg.sender] = false;
        if (!ERC20(token).transfer(msg.sender, claimableAmount[token])) revert("Error while transfering tokens");
        emit Withdraw(token, msg.sender, claimableAmount[token], tokens[token]);
    }
}