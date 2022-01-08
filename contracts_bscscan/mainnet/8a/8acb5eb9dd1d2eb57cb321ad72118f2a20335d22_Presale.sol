/**
 *Submitted for verification at BscScan.com on 2022-01-08
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
        return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }
}


interface IERC20 {

    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


abstract contract Owned {

    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }
}


contract Presale is Owned {

    using SafeMath for uint256;

    uint256 public saleStartTimestamp;
    uint256 public saleEndTimestamp;
    uint256 public claimStartTimestamp;
    uint256 public claimEndTimestamp;

    address public mainCurrencyAddress;     //BUSD:decimal 18
    address public presaleTokenAddress;     //TSUKI: decimal 9
    
    uint256 public tokenPrice = 3000000000000000000;     //default 3 busd
    uint256 public tokenSold = 0;
    uint256 public totalDeposited = 0;

    mapping(address => bool) public whiteListed;
    mapping(address => uint256) public paidAmount;
    mapping(address => uint256) public claimAmount;

    event Purchase(uint256 amount);
    event Claimed(address indexed receiver, uint256 amount);

    constructor(address _mainCurrencyAddress, address _presaleTokenAddress) {
        mainCurrencyAddress = _mainCurrencyAddress; //busd
        presaleTokenAddress = _presaleTokenAddress; //TSUKI
    }

    function setTokenPrice(uint256 _tokenPrice) external onlyOwner {
        tokenPrice = _tokenPrice;
    }

    function setMainCurrencyAddress(address _mainCurrencyAddress) external onlyOwner {
        mainCurrencyAddress = _mainCurrencyAddress;
    }

    function setPresaleTokenAddress(address _presaleTokenAddress) external onlyOwner {
        presaleTokenAddress = _presaleTokenAddress;
    }

    function setSaleTimestamp(uint256 _saleStartTimestamp, uint256 _saleEndTimestamp) external onlyOwner {
        saleStartTimestamp = _saleStartTimestamp;
        saleEndTimestamp =  _saleEndTimestamp;
    }

    function setClaimTimestamp(uint _claimStartTimestamp, uint256 _claimEndTimestamp) external onlyOwner {
        claimStartTimestamp = _claimStartTimestamp;
        claimEndTimestamp = _claimEndTimestamp;
    }

    function setWhitelist(address[] memory addresses, bool value) public onlyOwner{
        for (uint i = 0; i < addresses.length; i++) {
            whiteListed[addresses[i]] = value;
        }
    }

    function buy(uint256 _paidAmount) public {
        require(saleStarted() == true, "Sale is not started");
        require(whiteListed[msg.sender] == true, "Not whitelisted");
        require(saleEnded() == false, "Sale over");
        
        IERC20(mainCurrencyAddress).transferFrom(msg.sender, address(this), _paidAmount);
        paidAmount[msg.sender] += _paidAmount;
        uint tokenAmount = _paidAmount.mul(10**9).div(tokenPrice);
        claimAmount[msg.sender] += tokenAmount;
        tokenSold += tokenAmount;
        totalDeposited += _paidAmount;

        emit Purchase(_paidAmount);
    }

    function claim() public {
        require( claimStarted() == true, "Claim is not started" );
        require( whiteListed[msg.sender] == true, "Not whitelisted" );
        require( claimEnded() == false, "Claim over" );

        IERC20(presaleTokenAddress).transfer(msg.sender, claimAmount[msg.sender]);

        emit Claimed(msg.sender, claimAmount[msg.sender]);
    }

    function saleStarted() public view returns (bool) {
        if (saleStartTimestamp != 0) {
            return block.timestamp > saleStartTimestamp;
        } else {
            return false;
        }
    }

    function saleEnded() public view returns (bool) {
        if (saleEndTimestamp != 0) {
            return block.timestamp > saleEndTimestamp;
        } else{
            return false;
        }
    }

    function claimStarted() public view returns (bool) {
        if (claimStartTimestamp != 0){
            return block.timestamp > claimStartTimestamp;
        } else{
            return false;
        }
    }

    function claimEnded() public view returns (bool) {
        if(claimEndTimestamp != 0) {
            return block.timestamp > claimEndTimestamp;
        } else {
            return false;
        }
    }
    
    function getUnsoldTokens(address to) external onlyOwner {
        require(saleEnded() == true, "Sale is not over");

        uint256 balance = IERC20(presaleTokenAddress).balanceOf(address(this));
        IERC20(presaleTokenAddress).transfer(to, balance);
    }

    function withdraw(address to) external onlyOwner {
        require(saleEnded() == true, "Sale is not over");

        uint256 balance = IERC20(mainCurrencyAddress).balanceOf(address(this));
        IERC20(mainCurrencyAddress).transfer(to, balance);
    }

}