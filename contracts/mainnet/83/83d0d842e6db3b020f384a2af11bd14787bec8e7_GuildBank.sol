pragma solidity 0.5.16;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) 
            return 0;
        uint256 c = a * b;
        require(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0);
        uint256 c = a / b;
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;
        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "permission denied");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "invalid address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

contract ERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function burn(address from, uint256 amount) external;
}

contract ERC20NonStandard {
    function transfer(address to, uint256 value) public;
}

contract Burner {
    using SafeMath for uint256;

    address constant etherAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    ERC20 constant hakka = ERC20(0x0E29e5AbbB5FD88e28b2d355774e73BD47dE3bcd);

    GuildBank constant bank = GuildBank(0x83D0D842e6DB3B020f384a2af11bD14787BEC8E7);

    bool private lock;

    function ragequit(address[] calldata tokens, uint256 share) external returns (uint256[] memory amounts) {
        require(!lock);
        lock = true;

        uint256 totalShare = hakka.totalSupply();

        hakka.burn(msg.sender, share);

        amounts = new uint256[](tokens.length);

        for(uint256 i = 0; i < tokens.length; i++) {
            if(i > 0) require(uint256(tokens[i-1]) < uint256(tokens[i]), "bad order");

            uint256 tokenInBank;

            if(tokens[i] == etherAddr) {
                address payable _bank = address(bank);
                tokenInBank = _bank.balance;
            }
            else {
                tokenInBank = ERC20(tokens[i]).balanceOf(address(bank));
            }

            uint256 amount = share.mul(tokenInBank).div(totalShare);
            amounts[i] = amount;
            require(bank.withdraw(tokens[i], msg.sender, amount), "fail to withdraw");
        }
        lock = false;
    }
}

contract GuildBank is Ownable {

    address constant etherAddr = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    address constant burner = 0xde02313f8BF17f31380c63e41CDECeE98Bc2b16d;

    event Withdrawal(address indexed token, address indexed receiver, uint256 amount);

    constructor() public {
        new Burner();
    }

    function withdraw(address token, address receiver, uint256 amount) external returns (bool result) {
        require(msg.sender == owner || msg.sender == burner, "permission denied");

        if(token == etherAddr) {
            (result,) = receiver.call.value(amount)("");
        }
        else {
            result = doTransferOut(token, receiver, amount);
        }

        if(result) emit Withdrawal(token, receiver, amount);
    }

    function() external payable {}

    function doTransferOut(address tokenAddr, address to, uint amount) internal returns (bool result) {
        ERC20NonStandard token = ERC20NonStandard(tokenAddr);
        token.transfer(to, amount);

        assembly {
            switch returndatasize()
                case 0 {                      // This is a non-standard ERC-20
                    result := not(0)          // set result to true
                }
                case 32 {                     // This is a complaint ERC-20
                    returndatacopy(0, 0, 32)
                    result := mload(0)        // Set `result = returndata` of external call
                }
                default {                     // This is an excessively non-compliant ERC-20, revert.
                    revert(0, 0)
                }
        }
    }
}