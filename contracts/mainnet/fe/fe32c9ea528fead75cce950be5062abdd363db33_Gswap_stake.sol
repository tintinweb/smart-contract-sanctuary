/**
 *Submitted for verification at Etherscan.io on 2021-06-10
*/

pragma solidity =0.6.6;

/**
 * Math operations with safety checks
 */
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }
    function mul(uint a, uint b) internal pure returns (uint) {
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint a, uint b, string memory errorMessage) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;

        return c;
    }
}

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    /**
     * @dev The Ownable constructor sets the original `owner` of the contract to the sender
     * account.
     */
    constructor() public {
        owner = msg.sender;
    }


    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }


    /**
     * @dev Allows the current owner to transfer control of the contract to a newOwner.
     * @param newOwner The address to transfer ownership to.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

interface INFT {
    function mintNft(address _to, string calldata _symbol, string calldata  _name, string calldata _icon, uint _goal) external returns (uint256);
    function addFile(uint _tokenId, string calldata _file) external;

}

interface ERC20 {
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address from, address to, uint256 value) external;
    function balanceOf(address who) external view returns (uint256);
    function transfer(address to, uint256 value) external;
}

contract Gswap_stake is Ownable{
    using SafeMath for uint;

    INFT public nft;
    ERC20 public usdg;
    uint public cost;

    mapping (uint => address) private tokenHolders;

    event GovWithdrawToken(address indexed token, address indexed to, uint256 value);

    constructor(address _usdg,address _nft, uint _cost)public {
        setParams(_usdg,_nft,_cost);
    }

    function ipo(string memory _symbol, string memory _name, string memory _icon,uint _goal) public {
        uint allowed = usdg.allowance(msg.sender,address(this));
        uint balanced = usdg.balanceOf(msg.sender);
        require(allowed >= cost, "!allowed");
        require(balanced >= cost, "!balanced");
        usdg.transferFrom( msg.sender,address(this), cost);

        uint tokenId = nft.mintNft(msg.sender,_symbol,_name,_icon,_goal);
        tokenHolders[tokenId] = msg.sender;
    }

    function addFile(uint _tokenId, string memory _file)public{
        require(tokenHolders[_tokenId] == msg.sender, "not authorized");
        nft.addFile(_tokenId,_file);
    }

    function govWithdraUsdg(uint256 _amount)onlyOwner public {
        require(_amount > 0, "!zero input");
        usdg.transfer( msg.sender, _amount);
        emit GovWithdrawToken(address(usdg), msg.sender, _amount);
    }

    function setParams(address _usdg,address _nft, uint _cost)onlyOwner public {
        usdg = ERC20(_usdg);
        nft = INFT(_nft);
        cost = _cost;
    }
}