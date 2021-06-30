/**
 *Submitted for verification at Etherscan.io on 2021-06-30
*/

pragma solidity ^0.5.7;

/**
 * @title SafeMath
 * @dev Unsigned math operations with safety checks that revert on error.
 */
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {

    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor(address initialOwner) internal {
        require(initialOwner != address(0));
        _owner = initialOwner;
        emit OwnershipTransferred(address(0), _owner);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(isOwner(), "Caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

}

/**
 * @title ERC20 interface
 * @dev see https://eips.ethereum.org/EIPS/eip-20
 */
 interface IERC20 {
     function transfer(address to, uint256 value) external returns (bool);
     function approve(address spender, uint256 value) external returns (bool);
     function transferFrom(address from, address to, uint256 value) external returns (bool);
     function totalSupply() external view returns (uint256);
     function balanceOf(address who) external view returns (uint256);
     function allowance(address owner, address spender) external view returns (uint256);
     function mint(address to, uint256 value) external returns (bool);
     function burnFrom(address from, uint256 value) external;
 }

 interface IUSDT {
     function totalSupply() external view returns (uint256);
     function balanceOf(address account) external view returns (uint256);
     function transfer(address recipient, uint256 amount) external;
     function allowance(address owner, address spender) external view returns (uint256);
     function approve(address spender, uint256 amount) external;
     function transferFrom(address sender, address recipient, uint256 amount) external;
     function decimals() external view returns(uint8);
 }

/**
 * @title Exchange contract
 * @author https://grox.solutions
 */
contract Exchange is Ownable {
    using SafeMath for uint256;

    IUSDT public USDT;
    IERC20 public CCO;

    struct User {
        uint256 rate;
        address[] referrals;
        address referrer;
        uint256 totalBonuses;
    }

    mapping (address => User) public users;

    address public wallet;

    constructor(address USDTAddr, address CCOAddr, address initialOwner, address initialWallet) public Ownable(initialOwner) {
        require(USDTAddr != address(0) && CCOAddr != address(0) && initialWallet != address(0));

        USDT = IUSDT(USDTAddr);
        CCO = IERC20(CCOAddr);

        wallet = initialWallet;
    }

    function setReferrer(address ref, uint256 rate) public onlyOwner {
        require(ref != address(0) && rate <= 250);
        users[ref].rate = rate;
    }

    function receiveApproval(address from, uint256 amount, address token, bytes calldata extraData) external {
        if (token == address(USDT)) {
            exchangeUSDTtoCCO(from, amount, _bytesToAddress(extraData));
        } else if (token == address(CCO)) {
            exchangeCCOtoUSDT(from, amount, _bytesToAddress(extraData));
        }
    }

    function exchangeUSDTtoCCO(address from, uint256 amount, address referrer) public {
        if (users[from].referrer == address(0) && referrer != address(0)) {
            users[from].referrer = referrer;
            users[referrer].referrals.push(from);
        }

        USDT.transferFrom(from, address(this), amount);

        uint256 refBonus;
        if (users[from].referrer != address(0)) {
            uint256 rate = users[users[from].referrer].rate > 0 ? users[users[from].referrer].rate : 50;
            refBonus = amount * rate / 10000;
            users[from].totalBonuses += refBonus;
            USDT.transfer(users[from].referrer, refBonus);
        }

        uint256 fee = amount * 250 / 10000;
        if (fee - refBonus > 0) {
            USDT.transfer(wallet, fee - refBonus);
        }

        CCO.mint(from, amount - fee);
    }

    function exchangeCCOtoUSDT(address from, uint256 amount, address referrer) public {
        if (users[from].referrer == address(0) && referrer != address(0)) {
            users[from].referrer = referrer;
            users[referrer].referrals.push(from);
        }

        uint256 refBonus;
        if (users[from].referrer != address(0)) {
            uint256 rate = users[users[from].referrer].rate > 0 ? users[users[from].referrer].rate : 50;
            refBonus = amount * rate / 10000;
            users[from].totalBonuses += refBonus;
            USDT.transfer(users[from].referrer, refBonus);
        }

        uint256 fee = amount * 250 / 10000;
        if (fee - refBonus > 0) {
            USDT.transfer(wallet, fee - refBonus);
        }

        CCO.burnFrom(from, amount);

        USDT.transfer(from, amount - fee);
    }

    function withdrawERC20(address ERC20Token, address recipient) external onlyOwner {

        uint256 amount = IERC20(ERC20Token).balanceOf(address(this));
        IERC20(ERC20Token).transfer(recipient, amount);

    }

    function getReferrerInfo(address account) public view returns(address referrer, uint256 rate, uint256 amountOfReferrals, uint256 totalBonuses) {
        referrer = users[account].referrer;
        rate = users[account].rate;
        amountOfReferrals = users[account].referrals.length;
        totalBonuses = users[account].totalBonuses;
    }

    function getReferralInfo(address account, uint256 from, uint256 to) public view returns(address[] memory referrals, uint256[] memory bonuses) {
        uint256 amountOfReferrals = users[account].referrals.length;

        if (to > amountOfReferrals) {
            to = amountOfReferrals;
        }

        require(to >= from);

        uint256 length = to - from;

        referrals = new address[](length);
        bonuses = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            referrals[i] = users[account].referrals[from + i];
            bonuses[i] = users[referrals[i]].totalBonuses;
        }
    }

    function _bytesToAddress(bytes memory source) internal pure returns(address parsedreferrer) {
        assembly {
            parsedreferrer := mload(add(source,0x14))
        }
    }

}