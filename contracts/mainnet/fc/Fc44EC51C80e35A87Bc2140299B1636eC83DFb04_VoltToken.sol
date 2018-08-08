/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
    /**
    * @dev Multiplies two numbers, throws on overflow.
    */
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
        return c;
    }

    /**
    * @dev Integer division of two numbers, truncating the quotient.
    */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        // uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn&#39;t hold
        return a / b;
    }

    /**
    * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
    */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    /**
    * @dev Adds two numbers, throws on overflow.
    */
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;   
    }
}

contract BasicToken {
    string private token_name;
    string private token_symbol;
    uint256 private token_decimals;

    uint256 private total_supply;
    uint256 private remaining_supply;

    mapping (address => uint256) private balance_of;
    mapping (address => mapping(address => uint256)) private allowance_of;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approve(address indexed target, address indexed spender, uint256 value);

    function BasicToken (
        string tokenName,
        string tokenSymbol,
        uint256 tokenDecimals,
        uint256 tokenSupply
    ) public {
        token_name = tokenName;
        token_symbol = tokenSymbol;
        token_decimals = tokenDecimals;
        total_supply = tokenSupply * (10 ** uint256(token_decimals));
        remaining_supply = total_supply;
    }

    function name() public view returns (string) {
        return token_name;
    }

    function symbol() public view returns (string) {
        return token_symbol;
    }

    function decimals() public view returns (uint256) {
        return token_decimals;
    }

    function totalSupply() public view returns (uint256) {
        return total_supply;
    }

    function remainingSupply() internal view returns (uint256) {
        return remaining_supply;
    }

    function balanceOf(
        address client_address
    ) public view returns (uint256) {
        return balance_of[client_address];
    }

    function setBalance(
        address client_address,
        uint256 value
    ) internal returns (bool) {
        require(client_address != address(0));
        balance_of[client_address] = value;
    }

    function allowance(
        address target_address,
        address spender_address
    ) public view returns (uint256) {
        return allowance_of[target_address][spender_address];
    }

    function approve(
        address spender_address,
        uint256 value
    ) public returns (bool) {
        require(value >= 0);
        require(msg.sender != address(0));
        require(spender_address != address(0));

        setApprove(msg.sender, spender_address, value);
        Approve(msg.sender, spender_address, value);
        return true;
    }
    
    function setApprove(
        address target_address,
        address spender_address,
        uint256 value
    ) internal returns (bool) {
        require(value >= 0);
        require(msg.sender != address(0));
        require(spender_address != address(0));

        allowance_of[target_address][spender_address] = value;
        return true;
    }

    function changeTokenName(
        string newTokenName
    ) internal returns (bool) {
        token_name = newTokenName;
        return true;
    }

    function changeTokenSymbol(
        string newTokenSymbol
    ) internal returns (bool) {
        token_symbol = newTokenSymbol;
        return true;
    }

    function changeTokenDecimals(
        uint256 newTokenDecimals
    ) internal returns (bool) {
        token_decimals = newTokenDecimals;
        return true;
    }

    function changeTotalSupply(
        uint256 newTotalSupply
    ) internal returns (bool) {
        total_supply = newTotalSupply;
        return true;
    }

    function changeRemainingSupply(
        uint256 newRemainingSupply
    ) internal returns (bool) {
        remaining_supply = newRemainingSupply;
        return true;
    }
}


contract VoltOwned {
    mapping (address => uint) private voltOwners;
    address[] private ownerList;

    mapping (address => uint256) private voltFreeze;

    modifier onlyOwner {
        require(voltOwners[msg.sender] == 99);
        _;
    }

    modifier noFreeze {
        require(now >= voltFreeze[msg.sender]);
        _;
    }

    function VoltOwned(address firstOwner) public {
        voltOwners[firstOwner] = 99;
        ownerList.push(firstOwner);
    }

    function isOwner(address who) internal view returns (bool) {
        if (voltOwners[who] == 99) {
            return true;
        } else {
            return false;
        }
    }

    function addOwner(address newVoltOwnerAddress) public onlyOwner noFreeze {
        require(newVoltOwnerAddress != address(0));
        voltOwners[newVoltOwnerAddress] = 99;
        ownerList.push(newVoltOwnerAddress);
    }

    function removeOwner(address removeVoltOwnerAddress) public onlyOwner noFreeze {
        require(removeVoltOwnerAddress != address(0));
        require(ownerList.length > 1);

        voltOwners[removeVoltOwnerAddress] = 0;
        for (uint256 i = 0; i != ownerList.length; i++) {
            if (removeVoltOwnerAddress == ownerList[i]) {
                delete ownerList[i];
                break;
            }
        }
    }

    function getOwners() public onlyOwner noFreeze returns (address[]) {
        return ownerList;
    }

    function isFreeze(address who) internal view returns (bool) {
        if (now >= voltFreeze[who]) {
            return false;
        } else {
            return true;
        }
    }

    function setFreeze(
        address freezeAddress,
        uint256 timestamp
    ) public onlyOwner noFreeze returns (bool) {
        require(freezeAddress != address(0));
        voltFreeze[freezeAddress] = timestamp;
    }

    function getFreezeTimestamp(
        address who
    ) public onlyOwner noFreeze returns (uint256) {
        return voltFreeze[who];
    }
}

contract VoltToken is BasicToken, VoltOwned {
    using SafeMath for uint256;

    bool private mintStatus;

    event Deposit(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed target, uint256 value);

    function VoltToken () public BasicToken (
        "VOLT", "ACDC", 18, 4000000000
    ) VoltOwned(
        msg.sender
    ) {
        mintStatus = true;
    }

    modifier canMint {
        require(mintStatus == true);
        _;
    }

    function mint(
        address to,
        uint256 value,
        uint256 freezeTimestamp
    ) public onlyOwner noFreeze canMint {
        uint256 ts = totalSupply();
        uint256 rs = remainingSupply();
        require(ts >= rs);

        superMint(to, value);
        setFreeze(to, freezeTimestamp);
    }

    function superMint(address to, uint256 value) public onlyOwner noFreeze {
        uint256 rs = remainingSupply();
        require(rs >= value);

        uint256 currentBalance = balanceOf(to);
        setBalance(to, currentBalance.add(value));
        setRemainingSupply(rs.sub(value));
        Transfer(0x0, to, value);
        Mint(to, value);
    }

    function mintOpen() public onlyOwner noFreeze returns (bool) {
        require(mintStatus == false);
        mintStatus = true;
        return true;
    }

    function mintClose() public onlyOwner noFreeze returns (bool) {
        require(mintStatus == true);
        mintStatus = false;
        return true;
    }

    function transfer(
        address to,
        uint256 value
    ) public noFreeze returns (bool) {
        require(value > 0);
        require(msg.sender != address(0));
        require(to != address(0));

        require(balanceOf(msg.sender) >= value);
        require(balanceOf(to).add(value) >= balanceOf(to));

        voltTransfer(msg.sender, to, value);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) public noFreeze returns(bool) {
        require(value > 0);
        require(msg.sender != address(0));
        require(from != address(0));
        require(to != address(0));

        require(isFreeze(from) == false);
        require(allowance(from, msg.sender) >= value);
        require(balanceOf(from) >= value);
        require(balanceOf(to).add(value) >= balanceOf(to));

        voltTransfer(from, to, value);

        uint256 remaining = allowance(from, msg.sender).sub(value);
        setApprove(from, msg.sender, remaining);
        return true;
    }

    function voltTransfer(
        address from,
        address to,
        uint256 value
    ) private noFreeze returns (bool) {
        uint256 preBalance = balanceOf(from);
        setBalance(from, balanceOf(from).sub(value));
        setBalance(to, balanceOf(to).add(value));
        Transfer(from, to, value);
        assert(balanceOf(from).add(value) == preBalance);
        return true;
    }

    function setTokenName(
        string newTokenName
    ) public onlyOwner noFreeze returns (bool) {
        return changeTokenName(newTokenName);
    }

    function setTokenSymbol(
        string newTokenSymbol
    ) public onlyOwner noFreeze returns (bool) {
        return changeTokenSymbol(newTokenSymbol);
    }

    function setTotalSupply(
        uint256 newTotalSupply
    ) public onlyOwner noFreeze returns (bool) {
        return changeTotalSupply(newTotalSupply);
    }

    function setRemainingSupply(
        uint256 newRemainingSupply
    ) public onlyOwner noFreeze returns (bool) {
        return changeRemainingSupply(newRemainingSupply);
    }

    function getRemainingSupply() public onlyOwner noFreeze returns (uint256) {
        return remainingSupply();
    }
}