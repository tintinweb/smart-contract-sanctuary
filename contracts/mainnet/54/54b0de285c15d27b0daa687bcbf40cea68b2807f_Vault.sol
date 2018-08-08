pragma solidity ^0.4.21;

interface VaultInterface {

    event Deposited(address indexed user, address token, uint amount);
    event Withdrawn(address indexed user, address token, uint amount);

    event Approved(address indexed user, address indexed spender);
    event Unapproved(address indexed user, address indexed spender);

    event AddedSpender(address indexed spender);
    event RemovedSpender(address indexed spender);

    function deposit(address token, uint amount) external payable;
    function withdraw(address token, uint amount) external;
    function transfer(address token, address from, address to, uint amount) external;
    function approve(address spender) external;
    function unapprove(address spender) external;
    function isApproved(address user, address spender) external view returns (bool);
    function addSpender(address spender) external;
    function removeSpender(address spender) external;
    function latestSpender() external view returns (address);
    function isSpender(address spender) external view returns (bool);
    function tokenFallback(address from, uint value, bytes data) public;
    function balanceOf(address token, address user) public view returns (uint);

}

interface ERC820 {

    function setInterfaceImplementer(address addr, bytes32 iHash, address implementer) public;

}

library SafeMath {

    function mul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function max64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a >= b ? a : b;
    }

    function min64(uint64 a, uint64 b) internal pure returns (uint64) {
        return a < b ? a : b;
    }

    function max256(uint a, uint b) internal pure returns (uint) {
        return a >= b ? a : b;
    }

    function min256(uint a, uint b) internal pure returns (uint) {
        return a < b ? a : b;
    }
}


contract Ownable {

    address public owner;

    modifier onlyOwner {
        require(isOwner(msg.sender));
        _;
    }

    function Ownable() public {
        owner = msg.sender;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        owner = _newOwner;
    }

    function isOwner(address _address) public view returns (bool) {
        return owner == _address;
    }
}

interface ERC20 {

    function totalSupply() public view returns (uint);
    function balanceOf(address owner) public view returns (uint);
    function allowance(address owner, address spender) public view returns (uint);
    function transfer(address to, uint value) public returns (bool);
    function transferFrom(address from, address to, uint value) public returns (bool);
    function approve(address spender, uint value) public returns (bool);

}

interface ERC777 {
    function name() public constant returns (string);
    function symbol() public constant returns (string);
    function totalSupply() public constant returns (uint256);
    function granularity() public constant returns (uint256);
    function balanceOf(address owner) public constant returns (uint256);

    function send(address to, uint256 amount) public;
    function send(address to, uint256 amount, bytes userData) public;

    function authorizeOperator(address operator) public;
    function revokeOperator(address operator) public;
    function isOperatorFor(address operator, address tokenHolder) public constant returns (bool);
    function operatorSend(address from, address to, uint256 amount, bytes userData, bytes operatorData) public;

}

contract Vault is Ownable, VaultInterface {

    using SafeMath for *;

    address constant public ETH = 0x0;

    mapping (address => bool) public isERC777;

    // user => spender => approved
    mapping (address => mapping (address => bool)) private approved;
    mapping (address => mapping (address => uint)) private balances;
    mapping (address => uint) private accounted;
    mapping (address => bool) private spenders;

    address private latest;

    modifier onlySpender {
        require(spenders[msg.sender]);
        _;
    }

    modifier onlyApproved(address user) {
        require(approved[user][msg.sender]);
        _;
    }

    function Vault(ERC820 registry) public {
        // required by ERC777 standard.
        registry.setInterfaceImplementer(address(this), keccak256("ERC777TokensRecipient"), address(this));
    }

    /// @dev Deposits a specific token.
    /// @param token Address of the token to deposit.
    /// @param amount Amount of tokens to deposit.
    function deposit(address token, uint amount) external payable {
        require(token == ETH || msg.value == 0);

        uint value = amount;
        if (token == ETH) {
            value = msg.value;
        } else {
            require(ERC20(token).transferFrom(msg.sender, address(this), value));
        }

        depositFor(msg.sender, token, value);
    }

    /// @dev Withdraws a specific token.
    /// @param token Address of the token to withdraw.
    /// @param amount Amount of tokens to withdraw.
    function withdraw(address token, uint amount) external {
        require(balanceOf(token, msg.sender) >= amount);

        balances[token][msg.sender] = balances[token][msg.sender].sub(amount);
        accounted[token] = accounted[token].sub(amount);

        withdrawTo(msg.sender, token, amount);

        emit Withdrawn(msg.sender, token, amount);
    }

    /// @dev Approves an spender to trade balances of the sender.
    /// @param spender Address of the spender to approve.
    function approve(address spender) external {
        require(spenders[spender]);
        approved[msg.sender][spender] = true;
        emit Approved(msg.sender, spender);
    }

    /// @dev Unapproves an spender to trade balances of the sender.
    /// @param spender Address of the spender to unapprove.
    function unapprove(address spender) external {
        approved[msg.sender][spender] = false;
        emit Unapproved(msg.sender, spender);
    }

    /// @dev Adds a spender.
    /// @param spender Address of the spender.
    function addSpender(address spender) external onlyOwner {
        require(spender != 0x0);
        spenders[spender] = true;
        latest = spender;
        emit AddedSpender(spender);
    }

    /// @dev Removes a spender.
    /// @param spender Address of the spender.
    function removeSpender(address spender) external onlyOwner {
        spenders[spender] = false;
        emit RemovedSpender(spender);
    }

    /// @dev Transfers balances of a token between users.
    /// @param token Address of the token to transfer.
    /// @param from Address of the user to transfer tokens from.
    /// @param to Address of the user to transfer tokens to.
    /// @param amount Amount of tokens to transfer.
    function transfer(address token, address from, address to, uint amount) external onlySpender onlyApproved(from) {
        // We do not check the balance here, as SafeMath will revert if sub / add fail. Due to over/underflows.
        require(amount > 0);
        balances[token][from] = balances[token][from].sub(amount);
        balances[token][to] = balances[token][to].add(amount);
    }

    /// @dev Returns if an spender has been approved by a user.
    /// @param user Address of the user.
    /// @param spender Address of the spender.
    /// @return Boolean whether spender has been approved.
    function isApproved(address user, address spender) external view returns (bool) {
        return approved[user][spender];
    }

    /// @dev Returns if an address has been approved as a spender.
    /// @param spender Address of the spender.
    /// @return Boolean whether spender has been approved.
    function isSpender(address spender) external view returns (bool) {
        return spenders[spender];
    }

    function latestSpender() external view returns (address) {
        return latest;
    }

    function tokenFallback(address from, uint value, bytes) public {
        depositFor(from, msg.sender, value);
    }

    function tokensReceived(address, address from, address, uint amount, bytes, bytes) public {
        if (!isERC777[msg.sender]) {
            isERC777[msg.sender] = true;
        }

        depositFor(from, msg.sender, amount);
    }

    /// @dev Marks a token as an ERC777 token.
    /// @param token Address of the token.
    function setERC777(address token) public onlyOwner {
        isERC777[token] = true;
    }

    /// @dev Unmarks a token as an ERC777 token.
    /// @param token Address of the token.
    function unsetERC777(address token) public onlyOwner {
        isERC777[token] = false;
    }

    /// @dev Allows owner to withdraw tokens accidentally sent to the contract.
    /// @param token Address of the token to withdraw.
    function withdrawOverflow(address token) public onlyOwner {
        withdrawTo(msg.sender, token, overflow(token));
    }

    /// @dev Returns the balance of a user for a specified token.
    /// @param token Address of the token.
    /// @param user Address of the user.
    /// @return Balance for the user.
    function balanceOf(address token, address user) public view returns (uint) {
        return balances[token][user];
    }

    /// @dev Calculates how many tokens were accidentally sent to the contract.
    /// @param token Address of the token to calculate for.
    /// @return Amount of tokens not accounted for.
    function overflow(address token) internal view returns (uint) {
        if (token == ETH) {
            return address(this).balance.sub(accounted[token]);
        }

        return ERC20(token).balanceOf(this).sub(accounted[token]);
    }

    /// @dev Accounts for token deposits.
    /// @param user Address of the user who deposited.
    /// @param token Address of the token deposited.
    /// @param amount Amount of tokens deposited.
    function depositFor(address user, address token, uint amount) private {
        balances[token][user] = balances[token][user].add(amount);
        accounted[token] = accounted[token].add(amount);
        emit Deposited(user, token, amount);
    }

    /// @dev Withdraws tokens to user.
    /// @param user Address of the target user.
    /// @param token Address of the token.
    /// @param amount Amount of tokens.
    function withdrawTo(address user, address token, uint amount) private {
        if (token == ETH) {
            user.transfer(amount);
            return;
        }

        if (isERC777[token]) {
            ERC777(token).send(user, amount);
            return;
        }

        require(ERC20(token).transfer(user, amount));
    }
}