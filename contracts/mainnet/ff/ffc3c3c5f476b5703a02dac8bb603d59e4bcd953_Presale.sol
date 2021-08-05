/**
 *Submitted for verification at Etherscan.io on 2020-12-22
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.6.2;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

contract Ownable is Context {
    address _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// import ierc20 & safemath & non-standard
interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }
}

contract Presale is Ownable {
    using SafeMath for uint256;

    uint256 public rate;
    bool public presale;
    IERC20 public token;
    mapping(address => uint256) public claimable;

    event IsPresaleOverEvent(bool over);
    event ClaimTokenEvent(address user, uint256 amount);
    event RateEvent(uint256 rate);

    constructor(uint256 _rate, address _token) public {
        rate = _rate;
        token = IERC20(_token);
        presale = false;
    }

    modifier isPresaleOver() {
        require(presale == true, "The presale is not over");
        _;
    }

    function endPresale() external onlyOwner returns (bool) {
        presale = true;
        emit IsPresaleOverEvent(true);
        return presale;
    }

    function startPresale() external onlyOwner returns (bool) {
        presale = false;
        emit IsPresaleOverEvent(false);
        return presale;
    }

    function buyToken() external payable {
        // user enter amount of ether which is then transfered into the smart contract and tokens to be given is saved in the mapping
        require(presale == false, "presale is over you cannot buy now");
        require(msg.value > 0);
        
        require(msg.value.add(claimable[msg.sender].mul(1e18).div(rate)) <= 15e18,'the amount should be less than 15 ethers');
        uint256 tokensToBuy = msg.value.mul(rate).div(1e18);
        claimable[msg.sender] = claimable[msg.sender].add(tokensToBuy);
        emit ClaimTokenEvent(msg.sender, tokensToBuy);
    }

    function claimToken() external isPresaleOver {
        // check uint in claimable mapping for msg.sender and transfer erc20 to msg.sender
        require(
            claimable[msg.sender] > 0,
            "You need to buy at least some token"
        );
        claimable[msg.sender] = 0;
        token.transfer(msg.sender, claimable[msg.sender]);
        emit ClaimTokenEvent(msg.sender, 0);
    }

    function setTokenRate(uint256 _rate) external onlyOwner {
        rate = _rate;
        emit RateEvent(_rate);
    }

    function getEthBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getTokenBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }
    
    function adminTokenTrans() external onlyOwner{
        require(getTokenBalance() > 0,'the contract has no pry tokens');
        token.transfer(msg.sender,token.balanceOf(address(this)));
    }

    function adminTransferFund(uint256 value) external onlyOwner {
        msg.sender.call{value: value}("");
    }
}